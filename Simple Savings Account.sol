// Simple Savings Account: Track individual user deposit balances using a mapping.


// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

contract SimpleSavingsAccount {

    // Mapping to track individual user balances: User Address => Balance in Wei
    mapping(address => uint256) private _balances;

    // Events to track financial activity
    event Deposited(address indexed user, uint256 amount);
    event Withdrawn(address indexed user, uint256 amount);

    // Custom errors for gas efficiency
    error InsufficientSavingsBalance();
    error TransferFailed();

    /**
     * @dev Deposit native ETH into the caller's savings account.
     */
    function deposit() external payable {
        require(msg.value > 0, "Deposit must be greater than 0");

        // Add the incoming ETH value to the sender's recorded balance
        _balances[msg.sender] += msg.value;

        emit Deposited(msg.sender, msg.value);
    }

    /**
     * @dev Withdraw a specific amount of ETH from the caller's savings account.
     * @param amount The volume of ETH (in wei) to withdraw.
     */
    function withdraw(uint256 amount) external {
        if (_balances[msg.sender] < amount) {
            revert InsufficientSavingsBalance();
        }

        // Checks-Effects-Interactions pattern: Update state *before* external transfer
        _balances[msg.sender] -= amount;

        emit Withdrawn(msg.sender, amount);

        // Perform the low-level external ETH transfer
        (bool success, ) = payable(msg.sender).call{value: amount}("");
        if (!success) {
            revert TransferFailed();
        }
    }

    /**
     * @dev Read function to look up the balance of a specific account.
     */
    function getBalance(address user) external view returns (uint256) {
        return _balances[user];
    }
}




// 🔐 Crucial Security Pattern: CEIIn the withdraw function, notice the ordering of steps:Checks: We verify the user has enough money (_balances[msg.sender] < amount).Effects: We deduct the balance from our contract's state (_balances[msg.sender] -= amount) first.Interactions: We execute the external call to send the native $ETH$ (payable(msg.sender).call(...)).This architectural order is known as the Checks-Effects-Interactions (CEI) pattern. By altering the user's mapping balance before initiating the external transfer, we completely neutralize Reentrancy attacks, preventing malicious contracts from calling withdraw repeatedly before the state updates.