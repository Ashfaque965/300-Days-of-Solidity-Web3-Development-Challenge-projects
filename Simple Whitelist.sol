// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

contract SimpleWhitelist {
    address public owner;

    // A mapping where the key is the address and the value is a boolean (true if whitelisted)
    mapping(address => bool) public whitelist;

    // Modifier to restrict function access to whitelisted addresses only
    modifier onlyWhitelisted() {
        require(whitelist[msg.sender], "Access denied: Address is not whitelisted");
        _;
    }

    modifier onlyOwner() {
        require(msg.sender == owner, "Only the owner can call this");
        _;
    }

    constructor() {
        owner = msg.sender;
        // Automatically whitelist the contract deployer
        whitelist[msg.sender] = true;
    }

    // Function for the owner to add an address to the whitelist
    function addToWhitelist(address _addressToWhitelist) public onlyOwner {
        whitelist[_addressToWhitelist] = true;
    }

    // Function for the owner to remove an address from the whitelist
    function removeFromWhitelist(address _addressToRemove) public onlyOwner {
        whitelist[_addressToRemove] = false;
    }

    // A restricted function that can only be executed by whitelisted addresses
    function protectedMethod() public onlyWhitelisted returns (string memory) {
        return "Success: You triggered the whitelisted method!";
    }
}




// Key Details:
// mapping(address => bool): Think of this as a highly efficient lookup table or hash map on the blockchain. By default, every possible address points to false. When an address is added, its value is updated to true.

// whitelist[msg.sender]: The onlyWhitelisted modifier directly checks the mapping using the caller's address. If the boolean returned is false, the transaction is immediately reverted.

// Administrative Control: The addToWhitelist and removeFromWhitelist functions are protected by an onlyOwner modifier, ensuring that only the contract creator can modify who is on the list.