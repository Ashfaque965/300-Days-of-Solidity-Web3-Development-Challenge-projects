// DeFi Crypto Index Fund: Pool money to buy a basket of three distinct stablecoins.


// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/ReentrancyGuard.sol";

interface IUniswapV2Router02 {
    function swapExactETHForTokens(
        uint amountOutMin, 
        address[] calldata path, 
        address to, 
        uint deadline
    ) external payable returns (uint[] memory amounts);

    function WETH() external pure returns (address);
}

contract StablecoinIndexFund is ERC20, Ownable, ReentrancyGuard {

    IUniswapV2Router02 public immutable uniswapRouter;

    // The asset basket components
    address public stablecoinA;
    address public stablecoinB;
    address public stablecoinC;

    // Events
    event IndexDeposited(address indexed investor, uint256 ethAmount, uint256 sharesMinted);
    event IndexRedeemed(address indexed investor, uint256 sharesBurned);

    // Custom Errors
    error DepositMustBeGreaterThanZero();
    error TransferFailed();

    /**
     * @dev Pass the addresses of the 3 underlying stablecoins and the exchange router.
     */
    constructor(
        address _router,
        address _stableA,
        address _stableB,
        address _stableC,
        address initialOwner
    ) 
        ERC20("StableBasketIndex", "SBIX") 
        Ownable(initialOwner) 
    {
        uniswapRouter = IUniswapV2Router02(_router);
        stablecoinA = _stableA;
        stablecoinB = _stableB;
        stablecoinC = _stableC;
    }

    /**
     * @dev Step 1: Deposit ETH, split it 3 ways, swap for stablecoins, and mint shares.
     */
    function deposit() external payable nonReentrant {
        if (msg.value == 0) revert DepositMustBeGreaterThanZero();

        // Split incoming ETH into 3 equal portions
        uint256 ethPerAsset = msg.value / 3;
        
        // Track underlying balances before executing swaps to calculate exact yield delta
        uint256 balA = IERC20(stablecoinA).balanceOf(address(this));
        uint256 balB = IERC20(stablecoinB).balanceOf(address(this));
        uint256 balC = IERC20(stablecoinC).balanceOf(address(this));

        // Swap ETH for Stablecoin A, B, and C respectively
        _swapETHForToken(stablecoinA, ethPerAsset);
        _swapETHForToken(stablecoinB, ethPerAsset);
        _swapETHForToken(stablecoinC, ethPerAsset);

        // Determine how many tokens were actually purchased via the delta change
        uint256 deltaA = IERC20(stablecoinA).balanceOf(address(this)) - balA;
        uint256 deltaB = IERC20(stablecoinB).balanceOf(address(this)) - balB;
        uint256 deltaC = IERC20(stablecoinC).balanceOf(address(this)) - balC;

        // In a flat index, shares issued can scale proportionally to cumulative bought tokens
        uint256 totalStableTokensBought = deltaA + deltaB + deltaC;
        
        // Mint index shares (SBIX) directly back to the investor's address variable
        _mint(msg.sender, totalStableTokensBought);

        emit IndexDeposited(msg.sender, msg.value, totalStableTokensBought);
    }

    /**
     * @dev Step 2: Redeem fund shares to withdraw a pro-rata share of all underlying assets.
     * @param shareAmount The number of SBIX index tokens the user wishes to burn.
     */
    function redeem(uint256 shareAmount) external nonReentrant {
        require(shareAmount > 0, "Amount must be greater than zero");
        require(balanceOf(msg.sender) >= shareAmount, "Insufficient index share balance");

        uint256 totalShares = totalSupply();

        // Calculate pro-rata entitlement for each underlying stablecoin
        uint256 claimA = (IERC20(stablecoinA).balanceOf(address(this)) * shareAmount) / totalShares;
        uint256 claimB = (IERC20(stablecoinB).balanceOf(address(this)) * shareAmount) / totalShares;
        uint256 claimC = (IERC20(stablecoinC).balanceOf(address(this)) * shareAmount) / totalShares;

        // Effect: Burn the fund tracking shares first (CEI Pattern)
        _burn(msg.sender, shareAmount);

        // Interaction: Deliver the basket items to the investor
        if (claimA > 0) require(IERC20(stablecoinA).transfer(msg.sender, claimA), "Transfer A failed");
        if (claimB > 0) require(IERC20(stablecoinB).transfer(msg.sender, claimB), "Transfer B failed");
        if (claimC > 0) require(IERC20(stablecoinC).transfer(msg.sender, claimC), "Transfer C failed");

        emit IndexRedeemed(msg.sender, shareAmount);
    }

    /**
     * @dev Internal helper execution engine to process a Uniswap swap routing.
     */
    function _swapETHForToken(address token, uint256 ethAmount) private {
        address[] memory path = new address[](2);
        path[0] = uniswapRouter.WETH();
        path[1] = token;

        uniswapRouter.swapExactETHForTokens{value: ethAmount}(
            0, // amountOutMin: Slippage should be handled in a production configuration via price oracles
            path,
            address(this),
            block.timestamp + 15 minutes
        );
    }
}