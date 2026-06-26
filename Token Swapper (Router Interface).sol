// Token Swapper (Router Interface): Wrap calls to interface cleanly with Uniswap protocol pairs.



// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";

// Minimal Uniswap V2 Router Interface
interface IUniswapV2Router02 {
    function swapExactTokensForTokens(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external returns (uint[] memory amounts);

    function swapTokensForExactTokens(
        uint amountOut,
        uint amountInMax,
        address[] calldata path,
        address to,
        uint deadline
    ) external returns (uint[] memory amounts);
}

/**
 * @title TokenSwapper
 * @dev Wraps calls to interface cleanly with Uniswap V2 protocol pairs.
 */
contract TokenSwapper {
    using SafeERC20 for IERC20;

    IUniswapV2Router02 public immutable uniswapRouter;

    // Events
    event SwapExecuted(
        address indexed user,
        address indexed tokenIn,
        address indexed tokenOut,
        uint256 amountIn,
        uint256 amountOut
    );

    /**
     * @param _router Address of the UniswapV2Router02 (e.g., Mainnet: 0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D)
     */
    constructor(address _router) {
        require(_router != address(0), "Invalid router address");
        uniswapRouter = IUniswapV2Router02(_router);
    }

    /**
     * @notice Swap an exact amount of input tokens for as many output tokens as possible
     * @param tokenIn Address of the token being sold
     * @param tokenOut Address of the token being bought
     * @param amountIn Exact amount of tokenIn to swap
     * @param amountOutMin Minimum amount of tokenOut expected (slippage control)
     * @param to Recipient of the swapped tokens
     */
    function swapExactInput(
        address tokenIn,
        address tokenOut,
        uint256 amountIn,
        uint256 amountOutMin,
        address to
    ) external returns (uint256 amountOut) {
        require(amountIn > 0, "Amount In must be > 0");
        
        // Transfer tokens from user to this contract
        IERC20(tokenIn).safeTransferFrom(msg.sender, address(this), amountIn);

        // Approve router to spend tokenIn
        IERC20(tokenIn).safeApprove(address(uniswapRouter), amountIn);

        // Setup the route path (Direct pair setup)
        address[] memory path = new address[](2);
        path[0] = tokenIn;
        path[1] = tokenOut;

        // Execute the swap
        uint[] memory amounts = uniswapRouter.swapExactTokensForTokens(
            amountIn,
            amountOutMin,
            path,
            to,
            block.timestamp + 15 minutes // Generous deadline
        );

        // amounts[1] contains the actual amount of tokenOut received
        amountOut = amounts[1];

        emit SwapExecuted(msg.sender, tokenIn, tokenOut, amountIn, amountOut);
    }

    /**
     * @notice Swap tokens for an exact amount of output tokens
     * @param tokenIn Address of the token being sold
     * @param tokenOut Address of the token being bought
     * @param amountOut Exact amount of tokenOut desired
     * @param amountInMax Maximum amount of tokenIn allowed to be spent (slippage control)
     * @param to Recipient of the swapped tokens
     */
    function swapExactOutput(
        address tokenIn,
        address tokenOut,
        uint256 amountOut,
        uint256 amountInMax,
        address to
    ) external returns (uint256 amountIn) {
        require(amountOut > 0, "Amount Out must be > 0");

        // Setup path
        address[] memory path = new address[](2);
        path[0] = tokenIn;
        path[1] = tokenOut;

        // Note: For exact output, we pull amountInMax first, then refund the remainder.
        IERC20(tokenIn).safeTransferFrom(msg.sender, address(this), amountInMax);
        IERC20(tokenIn).safeApprove(address(uniswapRouter), amountInMax);

        // Execute the swap
        uint[] memory amounts = uniswapRouter.swapTokensForExactTokens(
            amountOut,
            amountInMax,
            path,
            to,
            block.timestamp + 15 minutes
        );

        amountIn = amounts[0];

        // Refund any unused tokenIn back to the user
        if (amountIn < amountInMax) {
            uint256 refundAmount = amountInMax - amountIn;
            // Reset approval
            IERC20(tokenIn).safeApprove(address(uniswapRouter), 0);
            IERC20(tokenIn).safeTransfer(msg.sender, refundAmount);
        }

        emit SwapExecuted(msg.sender, tokenIn, tokenOut, amountIn, amountOut);
    }
}