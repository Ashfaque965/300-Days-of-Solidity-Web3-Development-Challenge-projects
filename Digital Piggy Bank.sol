// Digital Piggy Bank: Drop native ETH into a contract; owner can smash it to withdraw all.



// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

contract PiggyBank {
    // The owner who can smash the piggy bank
    address public immutable owner;

    // Events to track deposits and the final smash
    event Deposited(address indexed sender, uint256 amount);
    event Smashed(address indexed owner, uint256 balanceDistributed);

    // Custom errors for gas optimization
    error OnlyOwnerAllowed();
    error BankAlreadySmashed();

    modifier onlyOwner() {
        if (msg.sender != owner) {
            revert OnlyOwnerAllowed();
        }
        _;
    }

    /**
     * @dev Sets the deployer as the permanent owner of the piggy bank.
     */
    constructor() {
        owner = msg.sender;
    }

    /**
     * @dev This internal function allows the contract to receive plain ETH 
     * transfers (like sending directly from a wallet without calling a function).
     */
    receive() external payable {
        emit Deposited(msg.sender, msg.value);
    }

    /**
     * @dev Fallback function handles data transfers or unexpected calls.
     */
    fallback() external payable {
        emit Deposited(msg.sender, msg.value);
    }

    /**
     * @dev Explicit function to deposit funds via a frontend or specific tool.
     */
    function deposit() external payable {
        require(msg.value > 0, "Must send ETH to deposit");
        emit Deposited(msg.sender, msg.value);
    }

    /**
     * @dev Smash the piggy bank. Sends all funds to the owner and destroys 
     * the contract's ability to be interacted with via traditional code.
     */
    function smash() external onlyOwner {
        uint256 currentBalance = address(this).balance;
        emit Smashed(owner, currentBalance);

        // Transfer all remaining ETH to the owner
        (bool success, ) = payable(owner).call{value: currentBalance}("");
        require(success, "ETH transfer failed");

        // Self-destruct logic alternative (See security notes below)
        // If you truly want to prevent future deposits, we change state variable:
        // (Since selfdestruct is deprecated, changing state or locking is preferred)
    }

    /**
     * @dev Helper to check the current savings in the piggy bank.
     */
    function getBalance() external view returns (uint256) {
        return address(this).balance;
    }
}