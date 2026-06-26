// Liquid Staking Derivative: Issue a wrapped claim token (like stETH) back to users when they lock up raw assets.

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/ReentrancyGuard.sol";

/**
 * @title LiquidStakingDerivative (stETH / rETH style)
 * @dev Users deposit ETH and receive wrapped stETH (Liquid Staking Tokens).
 */
contract LiquidStakingDerivative is ERC20, Ownable, ReentrancyGuard {
    
    // Event emitted when a user deposits ETH and mints wrapped tokens
    event Deposited(address indexed user, uint256 ethAmount, uint256 tokensMinted);
    
    // Event emitted when a user requests a withdrawal
    event WithdrawalRequested(address indexed user, uint256 tokenAmount, uint256 ethAmount);
    
    // Event emitted when rewards are deposited from the staking infrastructure
    event RewardsDeposited(uint256 amount);

    constructor() ERC20("Liquid Staked ETH", "stETH") Ownable(msg.sender) {}

    /**
     * @notice Deposit ETH to receive wrapped stETH tokens.
     * @dev Calculates tokens to mint based on the current pool exchange rate.
     */
    function deposit() external payable nonReentrant {
        uint256 ethAmount = msg.value;
        require(ethAmount > 0, "Cannot deposit 0 ETH");

        uint256 totalETH = totalAssets();
        uint256 totalShares = totalSupply();
        uint256 tokensToMint;

        // If this is the first deposit, mint tokens 1:1 with ETH
        if (totalShares == 0) {
            tokensToMint = ethAmount;
        } else {
            // Formula: tokensToMint = ethAmount * (totalShares / totalETHBeforeDeposit)
            // We subtract msg.value because totalAssets() already includes the newly sent ETH
            tokensToMint = (ethAmount * totalShares) / (totalETH - ethAmount);
        }

        require(tokensToMint > 0, "Mint amount too low");
        _mint(msg.sender, tokensToMint);

        emit Deposited(msg.sender, ethAmount, tokensToMint);
    }

    /**
     * @notice Burn wrapped tokens to claim the underlying ETH.
     * @param _tokenAmount The amount of wrapped tokens to burn.
     */
    function withdraw(uint256 _tokenAmount) external nonReentrant {
        require(_tokenAmount > 0, "Cannot withdraw 0 tokens");
        require(balanceOf(msg.sender) >= _tokenAmount, "Insufficient token balance");

        uint256 totalETH = totalAssets();
        uint256 totalShares = totalSupply();

        // Formula: ethToReturn = tokenAmount * (totalETH / totalShares)
        uint256 ethToReturn = (_tokenAmount * totalETH) / totalShares;
        require(address(this).balance >= ethToReturn, "Insufficient contract liquidity");

        _burn(msg.sender, _tokenAmount);
        
        (bool success, ) = payable(msg.sender).call{value: ethToReturn}("");
        require(success, "ETH transfer failed");

        emit WithdrawalRequested(msg.sender, _tokenAmount, ethToReturn);
    }

    /**
     * @notice Returns the total amount of ETH managed by this contract.
     * @dev In a production environment, this would also include ETH locked on the Beacon Chain.
     */
    function totalAssets() public view returns (uint256) {
        return address(this).balance;
    }

    /**
     * @notice Allows the contract owner (or a designated Oracle/Node Operator) to inject staking rewards.
     * @dev This increases the totalAssets without increasing totalSupply, raising the value of everyone's tokens.
     */
    function receiveRewards() external payable onlyOwner {
        require(msg.value > 0, "Rewards must be greater than 0");
        emit RewardsDeposited(msg.value);
    }

    // Required to receive raw ETH payments (e.g., if node operators send rewards back directly)
    receive() external payable {
        // If external ETH is sent directly without calling receiveRewards(), 
        // it naturally increases totalAssets(), thus distributing rewards to token holders.
    }
}