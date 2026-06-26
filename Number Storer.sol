// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

contract NumberStorer {
    // State variable to store our number
    uint256 private storedNumber;

    // Event emitted whenever the number changes (good practice for tracking)
    event NumberChanged(uint256 newValue);

    // Function to update the stored number
    function setNumber(uint256 _newNumber) public {
        storedNumber = _newNumber;
        emit NumberChanged(_newNumber);
    }

    // Function to retrieve the stored number
    function getNumber() public view returns (uint256) {
        return storedNumber;
    }
}




// Key Details:
// uint256: This specifies an unsigned integer (positive numbers and zero) of 256 bits, which is the standard size used in Solidity.

// private: By making the variable private, other contracts cannot read it directly. They must use the getNumber() function.

// view: The getNumber function is marked as view because it only reads from the blockchain but doesn't modify any state (meaning it costs zero gas to call externally).