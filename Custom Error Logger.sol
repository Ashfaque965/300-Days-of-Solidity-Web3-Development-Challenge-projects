// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

contract CustomErrorLogger {
    address public owner;
    uint256 public constant MINIMUM_DEPOSIT = 1 ether;

    // 1. Define custom errors outside or inside the contract
    // Passing arguments allows you to provide context on WHY it failed
    error NotTheOwner(address caller);
    error DepositTooLow(uint256 sent, uint256 required);
    error WithdrawalFailed();

    constructor() {
        owner = msg.sender;
    }

    // Example 1: Custom error with arguments for validation
    function deposit() public payable {
        if (msg.value < MINIMUM_DEPOSIT) {
            // 2. Trigger the custom error using the 'revert' keyword
            revert DepositTooLow(msg.value, MINIMUM_DEPOSIT);
        }
    }

    // Example 2: Custom error with arguments for access control
    function restrictedWithdraw() public {
        if (msg.sender != owner) {
            // Log exactly who tried to call the unauthorized function
            revert NotTheOwner(msg.sender);
        }

        uint256 amount = address(this).balance;
        
        // Low-level call to transfer funds
        (bool success, ) = owner.call{value: amount}("");
        if (!success) {
            revert WithdrawalFailed(); // Custom error without arguments
        }
    }
}