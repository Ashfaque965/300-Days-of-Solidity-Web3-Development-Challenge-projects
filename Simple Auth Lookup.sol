// Simple Auth Lookup: Compare hashes using keccak256 for basic passcode checking.

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

contract SimpleAuth {
    
    // The keccak256 hash of the correct passcode (Stored securely, original text is hidden)
    bytes32 private immutable _passcodeHash;

    // Custom error for gas efficiency
    error AccessDenied();

    // Event emitted upon successful authentication
    event AccessGranted(address indexed user);

    /**
     * @dev Pass the raw passcode string *only once* during deployment.
     * The constructor hashes it and stores only the 32-byte result.
     */
    constructor(string memory initialPasscode) {
        _passcodeHash = keccak256(abi.encodePacked(initialPasscode));
    }

    /**
     * @dev Checks the provided passcode against the stored hash.
     * @param providedPasscode The plaintext string provided by the user.
     */
    function verifyPasscode(string calldata providedPasscode) external view returns (bool) {
        // Hash the input and compare it to the stored hash
        return keccak256(abi.encodePacked(providedPasscode)) == _passcodeHash;
    }

    /**
     * @dev Example of a gatekeeping function requiring the passcode.
     */
    function accessSecureVault(string calldata passcode) external {
        if (keccak256(abi.encodePacked(passcode)) != _passcodeHash) {
            revert AccessDenied();
        }
        
        emit AccessGranted(msg.sender);
        // Execute secure logic here...
    }
}
