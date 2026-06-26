// // Collectible NFT Minting Cap: An NFT collection capping production completely at 10,000 units.


// To create an NFT collection with a strict production cap of 10,000 units, we use the ERC-721 standard. Similar to the capped ERC-20 token, we enforce a strict rule: if a mint request pushes the current token count past 10,000, the transaction reverts.

// Using an immutable variable for the max supply ensures maximum trust and gas efficiency.

// 🛠️ Solidity Implementation
// This contract leverages OpenZeppelin’s ERC-721 implementation. It uses a simple tracking counter to monitor the current total supply as minting occurs.

// Solidity



// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract LimitedCollection is ERC721, Ownable {
    
    // Hard ceiling for the NFT collection supply
    uint256 public immutable MAX_SUPPLY = 10000;
    
    // Internal counter for tracking total minted items
    uint256 private _currentTokenId;

    // Custom errors for gas efficiency
    error CollectionSoldOut();
    error MintAmountMustBeGreaterThanZero();

    /**
     * @dev Initializes the NFT collection name and symbol.
     */
    constructor(
        string memory name_, 
        string memory symbol_, 
        address initialOwner
    ) 
        ERC721(name_, symbol_) 
        Ownable(initialOwner) 
    {}

    /**
     * @dev Public minting function. Anyone can mint an NFT by paying the transaction fee.
     * Enforces the 10,000 unit ceiling.
     */
    function mint() external {
        // Enforce the hard cap constraint before processing
        if (_currentTokenId >= MAX_SUPPLY) {
            revert CollectionSoldOut();
        }

        // Increment first (Token IDs will run from 1 to 10,000)
        _currentTokenId++;
        uint256 newId = _currentTokenId;

        _safeMint(msg.sender, newId);
    }

    /**
     * @dev Total number of tokens minted so far.
     */
    function totalSupply() external view returns (uint256) {
        return _currentTokenId;
    }
}





// 🧠 Architectural Insights
// 1. Gas Optimization: Avoid Enumerable If Possible
// OpenZeppelin offers an extension called ERC721Enumerable which tracks all token IDs automatically and exposes a native totalSupply() function. However, ERC721Enumerable adds heavy overhead, making every single mint and transfer cost significantly more gas because it constantly updates internal lookup arrays.

// The Better Approach: For a collection capped at 10,000 where token IDs are sequential, tracking supply with a primitive uint256 counter (like _currentTokenId above) saves your users vast amounts of gas during the minting phase.

// 2. Token ID Indexing (0 vs. 1)
// In the implementation above, the counter increments before minting:

// Solidity
// _currentTokenId++;
// uint256 newId = _currentTokenId;
// This means the very first NFT minted will be Token ID #1, and the final absolute NFT will be Token ID #10,000. If you prefer starting from Token ID #0 through 9,999, you simply change the order: store the current ID first, execute _safeMint, and then increment the counter.

// 3. Metadata and Provenance
// When capping a collection at 10,000, projects usually point the contract to a base URI housing the artwork metadata (hosted on IPFS or Arweave). To append metadata to this contract, you can add a simple string override:

// Solidity
// string private _baseTokenURI;

// function _baseURI() internal view override returns (string memory) {
//     return "ipfs://CID_GOES_HERE/";
// }