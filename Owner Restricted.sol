// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

contract OwnerRestricted {
    // Variable to store the owner's address
    address public owner;

    // Define the custom modifier
    modifier onlyOwner() {
        // require checks a condition; if false, it reverts the transaction with an error message
        require(msg.sender == owner, "Error: Only the owner can call this function");
        _; // The underscore tells Solidity to execute the rest of the function code here
    }

    constructor() {
        // Set the deployer as the initial owner
        owner = msg.sender;
    }

    // A restricted function that only the owner can successfully run
    function restrictedAction() public onlyOwner {
        // Core logic for the restricted action goes here
    }
}





// How it works:
// modifier onlyOwner(): Modifiers are reusable pieces of code used to change or guard the behavior of functions.

// require(...): This statement evaluates a condition. If msg.sender == owner is true, execution continues. If it's false, the transaction immediately stops, reverts all changes, and refunds any remaining gas to the user.

// _; (The Merge Point): This special symbol represents the body of the function that the modifier is attached to. It tells the compiler to run the require check before entering the actual function logic.