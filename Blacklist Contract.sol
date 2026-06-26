// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/access/Ownable.sol";

contract Blacklistable is Ownable {

    // Mapping to store the blacklist status of each wallet
    mapping(address => bool) private _isBlacklisted;

    // Events emitted when the blacklist is updated
    event AddressBlacklisted(address indexed account);
    event AddressUnblacklisted(address indexed account);

    // Error definitions for gas efficiency
    error CallerIsBlacklisted();
    error TargetIsBlacklisted();

    constructor(address initialOwner) Ownable(initialOwner) {}

    /**
     * @dev Modifier to prevent blacklisted wallets from interacting.
     */
    modifier whenNotBlacklisted() {
        if (_isBlacklisted[msg.sender]) {
            revert CallerIsBlacklisted();
        }
        _;
    }

    /**
     * @dev Check if an address is blacklisted.
     */
    function isBlacklisted(address account) public view returns (bool) {
        return _isBlacklisted[account];
    }

    /**
     * @dev Adds a specific wallet to the blacklist.
     */
    function blacklistAddress(address account) external onlyOwner {
        require(!_isBlacklisted[account], "Address already blacklisted");
        _isBlacklisted[account] = true;
        emit AddressBlacklisted(account);
    }

    /**
     * @dev Removes a specific wallet from the blacklist.
     */
    function unblacklistAddress(address account) external onlyOwner {
        require(_isBlacklisted[account], "Address not blacklisted");
        _isBlacklisted[account] = false;
        emit AddressUnblacklisted(account);
    }

    /**
     * @dev Example of a protected function.
     */
    function sensitiveAction() external whenNotBlacklisted {
        // Business logic here
    }
}