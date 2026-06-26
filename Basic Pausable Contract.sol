// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

contract BasicPausable {
    address public owner;
    // Tracks whether the contract features are frozen
    bool public isPaused;

    // Events to log when the contract status changes
    event ContractPaused(address account);
    event ContractUnpaused(address account);

    // Modifier to ensure a function can only run when NOT paused
    modifier whenNotPaused() {
        require(!isPaused, "Contract is currently frozen");
        _;
    }

    // Modifier to restrict access to the contract owner
    modifier onlyOwner() {
        require(msg.sender == owner, "Only the owner can call this");
        _;
    }

    constructor() {
        owner = msg.sender;
        isPaused = false; // Starts in an active state
    }

    // Owner function to freeze features
    function pause() public onlyOwner {
        require(!isPaused, "Contract is already paused");
        isPaused = true;
        emit ContractPaused(msg.sender);
    }

    // Owner function to unfreeze features
    function unpause() public onlyOwner {
        require(isPaused, "Contract is not paused");
        isPaused = false;
        emit ContractUnpaused(msg.sender);
    }

    // An example feature that can be frozen by the owner
    function sensitiveFeature() public whenNotPaused returns (string memory) {
        return "Feature executed successfully!";
    }
}







// Key Details:
// whenNotPaused Modifier: This modifier checks if isPaused is false before letting the function execute (require(!isPaused)). If the owner freezes the contract, any call to sensitiveFeature() will immediately fail and revert.

// Emergency Stop Pattern: This is a fundamental security pattern in smart contract development. If a bug or vulnerability is discovered in a deployed contract, the owner can quickly call pause() to freeze operations and protect user assets while a fix is prepared.