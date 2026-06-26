// Yield Aggregator Re-balancer: Route funds to whichever target address contract offers a higher return rate variable.


// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/ReentrancyGuard.sol";

// Minimal interface representing a DeFi lending yield strategy destination
interface ILendingStrategy {
    function getSupplyRatePerBlock() external view returns (uint256);
    function deposit(uint256 amount) external returns (bool);
    function withdraw(uint256 amount) external returns (bool);
    function balanceOfUnderlying() external view returns (uint256);
}

contract YieldAggregatorRebalancer is Ownable, ReentrancyGuard {

    IERC20 public immutable underlyingToken;
    
    // The two target protocols under optimization review
    address public strategyA;
    address public strategyB;
    
    // Address variable currently holding the pooled capital
    address public activeStrategy;

    // Events
    event FundsDeposited(address indexed user, uint256 amount);
    event FundsWithdrawn(address indexed user, uint256 amount);
    event Rebalanced(address indexed oldStrategy, address indexed newStrategy, uint256 amountMoved);

    // Custom Errors
    error InvalidStrategyAddress();
    error TransferFailed();
    error NoCapitalToRebalance();

    constructor(
        address _token, 
        address _strategyA, 
        address _strategyB, 
        address initialOwner
    ) 
        Ownable(initialOwner) 
    {
        underlyingToken = IERC20(_token);
        strategyA = _strategyA;
        strategyB = _strategyB;
        
        // Default initial routing selection
        activeStrategy = _strategyA;
    }

    /**
     * @dev Core Optimization Engine: Compares rates and shifts funds if an alternative path pays more.
     * Anyone can trigger this to maintain decentralization, or it can be automated via crons/keepers.
     */
    function rebalance() external nonReentrant {
        uint256 rateA = ILendingStrategy(strategyA).getSupplyRatePerBlock();
        uint256 rateB = ILendingStrategy(strategyB).getSupplyRatePerBlock();

        address targetStrategy = (rateB > rateA) ? strategyB : strategyA;

        // If the active strategy is already optimal, skip execution to save gas
        if (targetStrategy == activeStrategy) {
            return;
        }

        uint256 currentAllocation = ILendingStrategy(activeStrategy).balanceOfUnderlying();
        if (currentAllocation == 0) revert NoCapitalToRebalance();

        // 1. Withdraw all assets out of the underperforming strategy contract
        address oldStrategy = activeStrategy;
        bool withdrawSuccess = ILendingStrategy(oldStrategy).withdraw(currentAllocation);
        if (!withdrawSuccess) revert TransferFailed();

        // 2. State update: Re-assign the active target address variable
        activeStrategy = targetStrategy;

        // 3. Deposit the entire pulled capital pool into the superior strategy
        uint256 balanceToMove = underlyingToken.balanceOf(address(this));
        require(underlyingToken.approve(targetStrategy, balanceToMove), "Approve failed");
        
        bool depositSuccess = ILendingStrategy(targetStrategy).deposit(balanceToMove);
        if (!depositSuccess) revert TransferFailed();

        emit Rebalanced(oldStrategy, targetStrategy, balanceToMove);
    }

    /**
     * @dev Users deposit capital into the aggregator vault, which routes directly to the active pool.
     */
    function vaultDeposit(uint256 amount) external nonReentrant {
        require(amount > 0, "Amount must be greater than zero");

        // Pull tokens from user wallet
        bool success = underlyingToken.transferFrom(msg.sender, address(this), amount);
        if (!success) revert TransferFailed();

        // Forward immediately to whichever contract address variable is currently flagged active
        require(underlyingToken.approve(activeStrategy, amount), "Approve failed");
        bool targetSuccess = ILendingStrategy(activeStrategy).deposit(amount);
        if (!targetSuccess) revert TransferFailed();

        emit FundsDeposited(msg.sender, amount);
    }

    /**
     * @dev Emergency or administrative update function to change a destination route strategy.
     */
    function updateStrategyAddresses(address _strategyA, address _strategyB) external onlyOwner {
        if (_strategyA == address(0) || _strategyB == address(0)) revert InvalidStrategyAddress();
        strategyA = _strategyA;
        strategyB = _strategyB;
    }
}