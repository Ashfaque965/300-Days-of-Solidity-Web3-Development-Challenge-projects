// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

contract MultiOwnerAuth {

    // Immutable variables are highly gas-efficient and set only once at deployment
    address public immutable owner1;
    address public immutable owner2;
    address public immutable owner3;

    // Custom error for gas efficiency (cheaper than require strings)
    error NotAnOwner();

    // Event emitted for critical administrative actions
    event ProtectedActionExecuted(address indexed operator, string action);

    /**
     * @dev Set the three static authorized addresses during deployment.
     */
    constructor(address _owner1, address _owner2, address _owner3) {
        require(_owner1 != address(0) && _owner2 != address(0) && _owner3 != address(0), "Zero address not allowed");
        owner1 = _owner1;
        owner2 = _owner2;
        owner3 = _owner3;
    }

    /**
     * @dev Modifier that checks if the caller is one of the three static owners.
     */
    modifier onlyMultiOwner() {
        if (msg.sender != owner1 && msg.sender != owner2 && msg.sender != owner3) {
            revert NotAnOwner();
        }
        _;
    }

    /**
     * @dev Example of a function protected by the multi-owner modifier.
     */
    function executeCriticalAction(string calldata actionDescription) external onlyMultiOwner {
        // Business logic for authorized owners goes here
        
        emit ProtectedActionExecuted(msg.sender, actionDescription);
    }
}