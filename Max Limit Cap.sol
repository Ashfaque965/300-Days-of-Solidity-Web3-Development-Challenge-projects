// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

contract MaxLimitCap {
    // Array to store the list of member addresses
    address[] public members;

    // Hard cap for the maximum size of the list
    uint256 public constant MAX_LIMIT = 5;

    // Event emitted when a new member is added successfully
    event MemberAdded(address newMember, uint256 currentSize);

    // Function to add an item, capped by the threshold
    function addMember(address _member) public {
        // Enforce the size constraint BEFORE pushing the new item
        // members.length + 1 ensures the upcoming total stays within bounds
        require(members.length < MAX_LIMIT, "Limit Exceeded: Member list is full");

        members.push(_member);

        emit MemberAdded(_member, members.length);
    }

    // Helper function to easily read the current total size
    function getMemberCount() public view returns (uint256) {
        return members.length;
    }
}