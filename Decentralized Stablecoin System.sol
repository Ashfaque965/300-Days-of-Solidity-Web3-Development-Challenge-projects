// Decentralized Stablecoin System: Mint structural tokens pegged to currency values using over-collateralized designs.

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

/**
 * @dev Simplified ERC20 interface for the Stablecoin.
 */
interface IERC20 {
    function totalSupply() external view returns (uint256);
    function balanceOf(address account) external view returns (uint256);
    function transfer(address to, uint256 value) external returns (bool);
    function allowance(address owner, address spender) external view returns (uint256);
    function approve(address spender, uint256 value) external returns (bool);
    function transferFrom(address from, address to, uint256 value) external returns (bool);
    
    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);
}

/**
 * @dev Decentralized Stablecoin Token contract.
 * ERC20-compliant, owned by the Engine which governs minting and burning.
 */
contract Stablecoin is IERC20 {
    string public const name = "Decentralized Stablecoin";
    string public const symbol = "DSTBL";
    uint8 public const decimals = 18;

    uint256 private _totalSupply;
    address public immutable engine;

    mapping(address => uint256) private _balances;
    mapping(address => mapping(address => uint256)) private _allowances;

    modifier onlyEngine() {
        require(msg.sender == engine, "Only engine can call");
        _;
    }

    constructor() {
        engine = msg.sender;
    }

    function totalSupply() external view override returns (uint256) {
        return _totalSupply;
    }

    function balanceOf(address account) external view override returns (uint256) {
        return _balances[account];
    }

    function transfer(address to, uint256 value) external override returns (bool) {
        _transfer(msg.sender, to, value);
        return true;
    }

    function allowance(address owner, address spender) external view override returns (uint256) {
        return _allowances[owner][spender];
    }

    function approve(address spender, uint256 value) external override returns (bool) {
        _approve(msg.sender, spender, value);
        return true;
    }

    function transferFrom(address from, address to, uint256 value) external override returns (bool) {
        _spendAllowance(from, msg.sender, value);
        _transfer(from, to, value);
        return true;
    }

    function mint(address to, uint256 amount) external onlyEngine {
        _totalSupply += amount;
        _balances[to] += amount;
        emit Transfer(address(0), to, amount);
    }

    function burn(address from, uint256 amount) external onlyEngine {
        require(_balances[from] >= amount, "Burn amount exceeds balance");
        _totalSupply -= amount;
        _balances[from] -= amount;
        emit Transfer(from, address(0), amount);
    }

    function _transfer(address from, address to, uint256 value) internal {
        require(from != address(0), "Transfer from zero address");
        require(to != address(0), "Transfer to zero address");
        require(_balances[from] >= value, "Transfer amount exceeds balance");

        _balances[from] -= value;
        _balances[to] += value;
        emit Transfer(from, to, value);
    }

    function _approve(address owner, address spender, uint256 value) internal {
        _allowances[owner][spender] = value;
        emit Approval(owner, spender, value);
    }

    function _spendAllowance(address owner, address spender, uint256 value) internal {
        uint256 currentAllowance = _allowances[owner][spender];
        if (currentAllowance != type(uint256).max) {
            require(currentAllowance >= value, "Insufficient allowance");
            _approve(owner, spender, currentAllowance - value);
        }
    }
}

/**
 * @dev Mock Chainlink Aggregator Interface for fetching prices.
 */
interface AggregatorV3Interface {
    function latestRoundData()
        external
        view
        returns (
            uint80 roundId,
            int256 answer,
            uint256 startedAt,
            uint256 updatedAt,
            uint80 answeredInRound
        );
}

/**
 * @title StablecoinEngine
 * @notice Core logic for managing Collateralized Debt Positions (CDPs).
 * Enforces a 150% over-collateralization rule using ETH.
 */
contract StablecoinEngine {
    // --- Constants ---
    uint256 public constant ADDITIONAL_FEED_PRECISION = 1e10; // Converts 8-decimal oracle price to 18 decimals
    uint256 public constant PRECISION = 1e18;
    uint256 public constant LIQUIDATION_THRESHOLD = 50; // 150% Collateralized required (100 + 50)
    uint256 public constant LIQUIDATION_PRECISION = 100;
    uint256 public constant LIQUIDATION_BONUS = 10; // 10% bonus for liquidators to incentivize cleanup

    // --- State Variables ---
    Stablecoin public immutable stablecoin;
    AggregatorV3Interface public immutable priceFeed;

    // User => deposited collateral amount (ETH)
    mapping(address => uint256) public userCollateral;
    // User => minted stablecoin amount (Debt)
    mapping(address => uint256) public userMintedDebt;

    // --- Events ---
    event CollateralDeposited(address indexed user, uint256 amount);
    event CollateralWithdrawn(address indexed user, uint256 amount);
    event StablecoinMinted(address indexed user, uint256 amount);
    event StablecoinBurned(address indexed user, uint256 amount);
    event PositionLiquidated(address indexed user, address indexed liquidator, uint256 debtRepaid, uint256 collateralSeized);

    constructor(address _priceFeedAddress) {
        stablecoin = new Stablecoin();
        priceFeed = AggregatorV3Interface(_priceFeedAddress);
    }

    // --- External Functions ---

    /**
     * @notice Deposit ETH as collateral into the system.
     */
    function depositCollateral() external payable {
        require(msg.value > 0, "Must deposit more than 0");
        userCollateral[msg.sender] += msg.value;
        emit CollateralDeposited(msg.sender, msg.value);
    }

    /**
     * @notice Mint stablecoins against your collateral.
     * @param amountToMint The amount of stablecoin tokens (18 decimals) to create.
     */
    function mintStablecoin(uint256 amountToMint) external {
        require(amountToMint > 0, "Must mint more than 0");
        userMintedDebt[msg.sender] += amountToMint;
        
        // Revert if this operation pushes user below the required 150% collateral ratio
        _revertIfHealthFactorIsBroken(msg.sender);
        
        stablecoin.mint(msg.sender, amountToMint);
        emit StablecoinMinted(msg.sender, amountToMint);
    }

    /**
     * @notice Repay your debt and withdraw your collateral in a single call.
     * @param amountCollateralToWithdraw ETH amount to pull back.
     * @param amountDebtToBurn Stablecoin amount to return/burn.
     */
    function redeemCollateralForStablecoin(uint256 amountCollateralToWithdraw, uint256 amountDebtToBurn) external {
        if (amountDebtToBurn > 0) {
            _burnStablecoin(msg.sender, msg.sender, amountDebtToBurn);
        }
        if (amountCollateralToWithdraw > 0) {
            _withdrawCollateral(msg.sender, msg.sender, amountCollateralToWithdraw);
        }
        _revertIfHealthFactorIsBroken(msg.sender);
    }

    /**
     * @notice Liquidate an under-collateralized user position to protect the system peg.
     * @param user The address whose health factor has fallen below 1 ether (under-collateralized).
     * @param debtToCover The amount of stablecoin debt you want to pay off on their behalf.
     */
    function liquidate(address user, uint256 debtToCover) external {
        uint256 startingUserHealthFactor = getHealthFactor(user);
        require(startingUserHealthFactor < PRECISION, "Health factor is stable");

        // Calculate the value of the debt being covered in ETH worth, plus liquidator bonus
        uint256 collateralFromDebtCovered = getCollateralValueFromDebt(debtToCover);
        uint256 bonusCollateral = (collateralFromDebtCovered * LIQUIDATION_BONUS) / LIQUIDATION_PRECISION;
        uint256 totalCollateralToSeize = collateralFromDebtCovered + bonusCollateral;

        // Ensure liquidator doesn't try to seize more than the user possesses
        if (totalCollateralToSeize > userCollateral[user]) {
            totalCollateralToSeize = userCollateral[user];
        }

        // Execute internal burning of debt and shifting of collateral
        _burnStablecoin(user, msg.sender, debtToCover);
        _withdrawCollateral(user, msg.sender, totalCollateralToSeize);

        uint256 endingUserHealthFactor = getHealthFactor(user);
        require(endingUserHealthFactor > startingUserHealthFactor, "Health factor didn't improve");
        
        emit PositionLiquidated(user, msg.sender, debtToCover, totalCollateralToSeize);
    }

    // --- Public View Functions ---

    /**
     * @notice Returns the user's current health standing. Below 1.0 ($1e18$) means liquidation ready.
     */
    function getHealthFactor(address user) public view returns (uint256) {
        (uint256 totalMintedDebt, uint256 collateralValueInUsd) = getUserAccountData(user);
        if (totalMintedDebt == 0) return type(uint256).max;
        
        // Adjust collateral value to find maximum safe mintable threshold
        uint256 collateralAdjustedForThreshold = (collateralValueInUsd * LIQUIDATION_PRECISION) / LIQUIDATION_THRESHOLD;
        return (collateralAdjustedForThreshold * PRECISION) / totalMintedDebt;
    }

    /**
     * @notice Fetches user parameters: Debt and total Collateral value translated to USD decimals.
     */
    function getUserAccountData(address user) public view returns (uint256 totalMintedDebt, uint256 collateralValueInUsd) {
        totalMintedDebt = userMintedDebt[user];
        collateralValueInUsd = getUsdValue(userCollateral[user]);
    }

    /**
     * @notice Converts an ETH amount to its equivalent USD value (scaled to 18 decimals).
     */
    function getUsdValue(uint256 ethAmount) public view returns (uint256) {
        (, int256 price, , , ) = priceFeed.latestRoundData();
        // Price feed returns 8 decimals; convert to 18 decimals alongside ETH value
        return ((uint256(price) * ADDITIONAL_FEED_PRECISION) * ethAmount) / PRECISION;
    }

    /**
     * @notice Converts a stablecoin debt size into the equivalent asset amount of collateral ETH.
     */
    function getCollateralValueFromDebt(uint256 debtValueInUsd) public view returns (uint256) {
        (, int256 price, , , ) = priceFeed.latestRoundData();
        return (debtValueInUsd * PRECISION) / (uint256(price) * ADDITIONAL_FEED_PRECISION);
    }

    // --- Internal/Private Functions ---

    function _withdrawCollateral(address from, address to, uint256 amount) internal {
        require(userCollateral[from] >= amount, "Withdraw amount exceeds collateral balance");
        userCollateral[from] -= amount;
        emit CollateralWithdrawn(from, amount);
        
        (bool success, ) = payable(to).call{value: amount}("");
        require(success, "Transfer failed");
    }

    function _burnStablecoin(address onBehalfOf, address debtFrom, uint256 amountToBurn) internal {
        require(userMintedDebt[onBehalfOf] >= amountToBurn, "Burn amount exceeds debt balance");
        userMintedDebt[onBehalfOf] -= amountToBurn;
        stablecoin.burn(debtFrom, amountToBurn);
        emit StablecoinBurned(onBehalfOf, amountToBurn);
    }

    function _revertIfHealthFactorIsBroken(address user) internal view {
        uint256 userHealthFactor = getHealthFactor(user);
        require(userHealthFactor >= PRECISION, "Breaches collateralization threshold! Health factor too low.");
    }
}
