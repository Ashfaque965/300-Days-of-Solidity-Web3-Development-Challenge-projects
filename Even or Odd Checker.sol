// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

contract EvenOrOddChecker {

    // Function to check if a number is even
    // It is marked as 'pure' because it doesn't read or modify contract state
    function isEven(uint256 _number) public pure returns (bool) {
        // The modulo operator (%) returns the remainder of a division
        return (_number % 2 == 0);
    }
}



// Key Details:
// pure: This keyword is used because the function neither reads from nor modifies the blockchain state. It solely relies on the _number passed into it, making it incredibly gas-efficient.

// % (Modulo Operator): This divides the number by 2 and returns the remainder. If the remainder is 0, the number is even (returning true). Otherwise, it returns false.