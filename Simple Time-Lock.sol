// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

contract SimpleTimeLock {
    address public owner;
    uint256 public unlockTime;

    // Event to log successful withdrawals
    event Withdrawn(address indexed to, uint256 amount);

    constructor(uint256 _lockDurationInSeconds) payable {
        owner = msg.sender;
        
        // block.timestamp is the current time in Unix seconds
        unlockTime = block.timestamp + _lockDurationInSeconds;
    }

    // Function to withdraw funds after the time-lock expires
    function withdraw() public {
        // 1. Ensure the caller is the owner
        require(msg.sender == owner, "Only the owner can withdraw");

        // 2. Ensure the lock duration has passed
        require(block.timestamp >= unlockTime, "Tokens are still locked; try again later");

        // 3. Clear contract balance and transfer to the owner
        uint256 amount = address(this).balance;
        require(amount > 0, "No funds available to withdraw");

        (bool success, ) = owner.call{value: amount}("");
        require(success, "Transfer failed");

        emit Withdrawn(owner, amount);
    }

    // Helper function to check how much time is left (in seconds)
    function getTimeLeft() public view returns (uint256) {
        if (block.timestamp >= unlockTime) {
            return 0;
        }
        return unlockTime - block.timestamp;
    }
}





// Key Details:
// payable Constructor: The payable keyword on the constructor allows you to send Ether to the contract at the exact moment you deploy it.

// block.timestamp: This is a global variable in Solidity that returns the current block's timestamp in Unix time (the number of seconds since January 1, 1970).

// owner.call{value: amount}(""): This is the recommended, secure pattern for sending Ether in modern Solidity. It forwards all remaining gas and returns a boolean indicating whether the transfer succeeded.