// Collateralized Loan: Lock native ETH to borrow custom synthetic stable tokens safely.


// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/utils/ReentrancyGuard.sol";

// Minimal Chainlink Price Feed Interface
interface AggregatorV3Interface {
    function latestRoundData() external view returns (
        uint80 roundId, int256 answer, uint256 startedAt, uint256 updatedAt, uint80 answeredInRound
    );
}

// The Custom Synthetic Stable Token Contract
contract SyntheticStableToken is ERC20 {
    address public immutable minterEngine;

    constructor(address _engine) ERC20("Synthetic USD", "sUSD") {
        minterEngine = _engine;
    }

    function mint(address to, uint256 amount) external {
        require(msg.sender == minterEngine, "Only lending engine can mint");
        _mint(to, amount);
    }

    function burn(address from, uint256 amount) external {
        require(msg.sender == minterEngine, "Only lending engine can burn");
        _burn(from, amount);
    }
}

// The Core CDP Collateral Engine
contract CollateralLendingEngine is ReentrancyGuard {

    AggregatorV3Interface public immutable priceFeed;
    SyntheticStableToken public immutable stableToken;

    struct Vault {
        uint256 collateral; // Deposited ETH in wei
        uint256 debt;       // Borrowed sUSD tokens in base units (18 decimals)
    }

    // Minimum collateralization ratio threshold (e.g., 15000 = 150%)
    uint256 public constant MIN_COLLATERAL_RATIO = 15000; 
    uint256 public constant RATIO_PRECISION = 10000;

    mapping(address => Vault) private _vaults;

    // Events
    event CollateralDeposited(address indexed user, uint256 amount);
    event StableTokensBorrowed(address indexed user, uint256 amount);
    event DebtRepaid(address indexed user, uint256 amount);
    event VaultLiquidated(address indexed user, address indexed liquidator, uint256 collateralSeized, uint256 debtCovered);

    // Custom Errors
    error IntolerableCollateralRatio();
    error VaultIsSafe();
    error TransferFailed();

    constructor(address _priceFeed) {
        priceFeed = AggregatorV3Interface(_priceFeed);
        stableToken = new SyntheticStableToken(address(this));
    }

    /**
     * @dev Step 1: Deposit ETH collateral and instantly mint synthetic stable tokens.
     * @param borrowAmount The amount of sUSD tokens the user wishes to borrow.
     */
    function depositAndBorrow(uint256 borrowAmount) external payable nonReentrant {
        Vault storage vault = _vaults[msg.sender];
        
        vault.collateral += msg.value;
        if (borrowAmount > 0) {
            vault.debt += borrowAmount;
        }

        // Validate that the user's position meets the minimum safety ratio
        if (!_isPositionSafe(msg.sender)) revert IntolerableCollateralRatio();

        if (borrowAmount > 0) {
            stableToken.mint(msg.sender, borrowAmount);
            emit StableTokensBorrowed(msg.sender, borrowAmount);
        }
        emit CollateralDeposited(msg.sender, msg.value);
    }

    /**
     * @dev Step 2: Repay debt to release locked ETH collateral.
     */
    function repayAndWithdraw(uint256 repayAmount, uint256 withdrawAmount) external nonReentrant {
        Vault storage vault = _vaults[msg.sender];
        require(vault.debt >= repayAmount, "Repaying more debt than owed");
        require(vault.collateral >= withdrawAmount, "Withdrawing more than deposited");

        if (repayAmount > 0) {
            vault.debt -= repayAmount;
            stableToken.burn(msg.sender, repayAmount);
            emit DebtRepaid(msg.sender, repayAmount);
        }

        if (withdrawAmount > 0) {
            vault.collateral -= withdrawAmount;
        }

        // Ensure the vault remains adequately collateralized after structural changes
        if (vault.debt > 0 && !_isPositionSafe(msg.sender)) revert IntolerableCollateralRatio();

        if (withdrawAmount > 0) {
            (bool success, ) = payable(msg.sender).call{value: withdrawAmount}("");
            if (!success) revert TransferFailed();
        }
    }

    /**
     * @dev Step 3: Liquidation Circuit Breaker.
     * If a user's collateral ratio drops below 150%, anyone can pay off the debt
     * and seize the user's ETH collateral at a discount to keep the system solvent.
     */
    function liquidate(address user) external nonReentrant {
        if (_isPositionSafe(user)) revert VaultIsSafe();

        Vault storage vault = _vaults[user];
        uint256 debtToCover = vault.debt;
        uint256 collateralToSeize = vault.collateral;

        // Reset the unhealthy vault to clear bad debt from the ecosystem
        delete _vaults[user];

        // Liquidator pays the sUSD debt token balance
        stableToken.burn(msg.sender, debtToCover);

        // Liquidator claims all underlying locked ETH collateral
        (bool success, ) = payable(msg.sender).call{value: collateralToSeize}("");
        if (!success) revert TransferFailed();

        emit VaultLiquidated(user, msg.sender, collateralToSeize, debtToCover);
    }

    /**
     * @dev Helper logic checking if a position conforms to MIN_COLLATERAL_RATIO.
     */
    function _isPositionSafe(address user) internal view returns (bool) {
        Vault memory vault = _vaults[user];
        if (vault.debt == 0) return true;

        // Fetch live conversion pricing from the decentralized oracle network
        (, int256 ethPriceInUsd, , , ) = priceFeed.latestRoundData();
        uint256 normalizedPrice = uint256(ethPriceInUsd) * 1e10; // Scale 8-decimal oracle up to 18 decimals

        // Calculate USD value of the user's collateral
        uint256 collateralValueInUsd = (vault.collateral * normalizedPrice) / 1e18;

        // Derived Ratio = (Collateral USD Value * Precision) / Debt Value
        uint256 currentRatio = (collateralValueInUsd * RATIO_PRECISION) / vault.debt;

        return currentRatio >= MIN_COLLATERAL_RATIO;
    }

    /**
     * @dev Public read access to view vault details.
     */
    function getVaultDetails(address user) external view returns (uint256 collateral, uint256 debt) {
        Vault memory v = _vaults[user];
        return (v.collateral, v.debt);
    }
}