// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

contract BooleanToggler {
    // State variable initialized to false by default
    bool public isSwitchedOn;

    // Event to log the status change
    event ToggleFlipped(bool newState);

    // Function to flip the boolean state
    function toggleSwitch() public {
        // The NOT operator (!) inverts the current boolean value
        isSwitchedOn = !isSwitchedOn;
        
        emit ToggleFlipped(isSwitchedOn);
    }
}




// Key Details:
// ! (Logical NOT Operator): This is the cleanest way to flip a boolean. If isSwitchedOn is true, !isSwitchedOn becomes false, and vice versa.

// Gas Efficiency: Because this function modifies the state of the blockchain (changing a variable from true to false or back), it will require a small amount of gas to execute.