// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

contract AddressTracker {
    // Variable to store the deployer's address
    address public deployer;

    // The constructor runs exactly once when the contract is deployed
    constructor() {
        // msg.sender here is the account deploying the contract
        deployer = msg.sender;
    }
}



// How it works:
// address public deployer;: This declares a state variable of type address. Making it public automatically generates a getter function, allowing anyone to see who the deployer is.

// msg.sender: This is a global variable in Solidity that represents the address of the account currently calling the function (or in this case, deploying the contract).