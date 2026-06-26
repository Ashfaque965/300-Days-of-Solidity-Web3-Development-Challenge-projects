// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

contract FallbackTracker {
    // State variables to track contract balance and event counts
    uint256 public receiveCount;
    uint256 public fallbackCount;

    // Triggered when Ether is sent with NO data (e.g., a direct wallet transfer)
    receive() external payable {
        receiveCount++;
    }

    // Triggered when Ether is sent WITH data, or if no other function matches
    fallback() external payable {
        fallbackCount++;
    }

    // Helper function to check the contract's total balance
    function getBalance() public view returns (uint256) {
        return address(this).balance;
    }
}