// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

contract AgeGate {
    
    // Constant for the age limit to save gas
    uint256 public constant MINIMUM_AGE = 18;

    // Mapping to keep track of users who have successfully verified their age
    mapping(address => uint256) public verifiedUsersAge;

    // Event emitted when a user successfully passes the age gate
    event AccessGranted(address indexed user, uint256 age);

    // Function to verify age and grant access
    function verifyAndRegister(uint256 _age) public {
        // The require statement checks if the input age meets the condition
        // If false, it rolls back the transaction and throws the error message
        require(_age >= MINIMUM_AGE, "Access Denied: You must be at least 18 years old.");

        // If the requirement is met, the code continues executing
        verifiedUsersAge[msg.sender] = _age;

        emit AccessGranted(msg.sender, _age);
    }

    // Helper function to check if an address has already registered
    function isRegistered(address _user) public view returns (bool) {
        return verifiedUsersAge[_user] >= MINIMUM_AGE;
    }
}