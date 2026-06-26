// // Allowance Wallet: Parent wallet allows child addresses to spend up to $X$ amount per week.


// 🛠️ Solidity Implementation
// This contract allows the parent (owner) to configure weekly limits. When a child address attempts to spend or withdraw ETH, the contract checks if a week has passed since their last reset. If so, it automatically refreshes their available limit.

// Solidity
// SPDX-License-Identifier: MIT



pragma solidity ^0.8.20;

import "@openzeppelin/contracts/access/Ownable.sol";

contract AllowanceWallet is Ownable {

    // Time constant for resetting allowances
    uint256 public constant WEEK_DURATION = 7 days;

    struct AllowanceLimit {
        uint256 weeklyLimit;      // Maximum wei spendable per week
        uint256 spentThisWeek;     // Wei spent in the current window
        uint256 currentWeekStart;  // Timestamp marking the start of the child's current week
    }

    // Mapping: Child Address => Allowance configurations
    mapping(address => AllowanceLimit) private _allowances;

    // Events
    event AllowanceConfigured(address indexed child, uint256 weeklyLimit);
    event FundsWithdrawn(address indexed child, uint256 amount, uint256 remainingAllowance);

    // Custom Errors
    error ExceededWeeklyAllowance(uint256 allowedRemaining, uint256 requested);
    error TransferFailed();

    /**
     * @dev Pass the parent wallet address as the initial owner.
     */
    constructor(address initialParent) Ownable(initialParent) {}

    /**
     * @dev Allows the contract to accept native ETH funding.
     */
    receive() external payable {}

    /**
     * @dev Parent sets or modifies a weekly spending limit for a child address.
     * @param child The address allowed to withdraw funds.
     * @param weeklyLimitInWei The max amount of Wei they can take every 7 days.
     */
    function setChildAllowance(address child, uint256 weeklyLimitInWei) external onlyOwner {
        require(child != address(0), "Invalid child address");
        
        AllowanceLimit storage allowance = _allowances[child];
        allowance.weeklyLimit = weeklyLimitInWei;
        
        // If it's their first time being configured, initialize their weekly epoch timer
        if (allowance.currentWeekStart == 0) {
            allowance.currentWeekStart = block.timestamp;
        }

        emit AllowanceConfigured(child, weeklyLimitInWei);
    }

    /**
     * @dev Child calls this function to withdraw native ETH up to their remaining weekly limit.
     * @param amount The volume of ETH (in wei) requested.
     */
    function withdrawAllowance(uint256 amount) external {
        AllowanceLimit storage allowance = _allowances[msg.sender];
        require(allowance.weeklyLimit > 0, "No allowance assigned to this caller");
        require(address(this).balance >= amount, "Contract has insufficient funds");

        // 1. Time Check: Has a new week rolled over since the last epoch start?
        if (block.timestamp >= allowance.currentWeekStart + WEEK_DURATION) {
            // Reset their spending cycle
            allowance.spentThisWeek = 0;
            // Advance the cycle anchor to the current period frame
            allowance.currentWeekStart = block.timestamp;
        }

        // 2. Limit Check: Evaluate spending headroom
        uint256 alreadySpent = allowance.spentThisWeek;
        uint256 limit = allowance.weeklyLimit;
        
        if (alreadySpent + amount > limit) {
            revert ExceededWeeklyAllowance(limit - alreadySpent, amount);
        }

        // 3. Effects: Log the spending *before* external interaction
        allowance.spentThisWeek += amount;

        emit FundsWithdrawn(msg.sender, amount, limit - allowance.spentThisWeek);

        // 4. Interaction: Secure transfer
        (bool success, ) = payable(msg.sender).call{value: amount}("");
        if (!success) {
            revert TransferFailed();
        }
    }

    /**
     * @dev View function to inspect a child's remaining allowance and reset timeline.
     */
    function getRemainingAllowance(address child) external view returns (
        uint256 weeklyLimit,
        uint256 remainingThisWeek,
        uint256 secondsUntilReset
    ) {
        AllowanceLimit memory allowance = _allowances[child];
        
        // If the timeline rolled over but they haven't called a state transaction yet
        if (block.timestamp >= allowance.currentWeekStart + WEEK_DURATION) {
            return (allowance.weeklyLimit, allowance.weeklyLimit, 0);
        }

        uint256 remaining = allowance.weeklyLimit - allowance.spentThisWeek;
        uint256 timeDelta = (allowance.currentWeekStart + WEEK_DURATION) - block.timestamp;

        return (allowance.weeklyLimit, remaining, timeDelta);
    }
}




// 🧠 Architectural Insights
// ⏰ Lazy-Evaluation Time Windows
// Smart contracts cannot execute operations on their own without an outside trigger; they lack internal "cron jobs" or background interval timers. Therefore, we cannot magically clear out a child's spentThisWeek tracker exactly at midnight on day seven.

// The Fix: We employ Lazy Evaluation. The contract defers checking the calendar until the moment the child calls withdrawAllowance(). It evaluates block.timestamp compared to the stored currentWeekStart. If it crosses the 7 days boundary, it handles the reset retroactively on-the-fly.

// 💰 Handling Fiat Equivalents (X)
// Because the blockchain cannot natively process fiat or understand standard financial exchange rates, $X$ amount per week should be evaluated in one of two formats:

// Wei (Native Layer 1 Currency): The code provided tracks purely in raw native ETH / Wei denomination.

// Stablecoins (ERC-20 Alternative): For production stability against volatility, you can swap the internal transfers for standard Stablecoins like USDC or USDT by updating the withdrawal logic to use IERC20(USDC_ADDRESS).transfer(msg.sender, amount).