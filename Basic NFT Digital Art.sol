// Basic NFT Digital Art: Code a clean ERC-721 token that track ownership of individual IDs.

// To track ownership of unique individual digital art assets, we use the ERC-721 standard. Unlike ERC-20 tokens (where every token is identical and interchangeable), ERC-721 maps every unique tokenId to a specific owner address.

// The standard also supports a tokenURI function, which links each ID to an external metadata file (usually hosted on IPFS or Arweave) containing the name, description, and raw image URL of your digital art.

// 🛠️ Solidity Implementation
// This implementation utilizes the industry-standard OpenZeppelin ERC-721 and Ownable modules to build a clean, production-ready art contract.

// Solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC721/extensions/ERC721URIStorage.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract DigitalArtNFT is ERC721URIStorage, Ownable {
    
    // Internal counter to track the next unique token ID
    uint256 private _nextTokenId;

    // Events
    event ArtMinted(address indexed artist, address indexed recipient, uint256 indexed tokenId, string tokenURI);

    /**
     * @dev Pass the collection name, symbol, and the initial admin owner.
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
     * @dev Mint a new piece of digital art. Only the contract owner (artist/admin) can execute.
     * @param recipient The wallet address that will receive the NFT.
     * @param _tokenURI The decentralized storage link (IPFS/Arweave) containing the artwork metadata.
     */
    function mintArt(address recipient, string calldata _tokenURI) external onlyOwner returns (uint256) {
        require(recipient != address(0), "Cannot mint to zero address");
        
        // Grab the current ID and increment the counter for the next mint
        uint256 currentId = _nextTokenId;
        _nextTokenId++;

        // Mint the token to the recipient
        _safeMint(recipient, currentId);

        // Explicitly map the metadata URI to this specific token ID
        _setTokenURI(currentId, _tokenURI);

        emit ArtMinted(msg.sender, recipient, currentId, _tokenURI);

        return currentId;
    }

    /**
     * @dev Helper function to check total items minted through this contract.
     */
    function totalMinted() external view returns (uint256) {
        return _nextTokenId;
    }
}





// 🧠 Architectural Insights
// 1. Underlying Storage Structure
// Under the hood of the OpenZeppelin base contract, ownership is tracked using a simple primitive mapping:

// Solidity
// mapping(uint256 tokenId => address owner) private _owners;
// When a marketplace like OpenSea queries who owns Art piece #5, it executes ownerOf(5), which looks up the owner directly from this internal mapping.

// 2. Why ERC721URIStorage?
// There are two main ways to handle metadata in ERC-721 contracts:

// Base URI Pattern: Good for collections where everything is generated sequentially (e.g., ipfs://CID/1, ipfs://CID/2). It saves gas by concatenating the base link with the token ID dynamically.

// Explicit URI Storage (ERC721URIStorage): Ideal for unique digital art pieces minted at different times. It stores a unique, dedicated string per token ID, allowing you to easily mix IPFS hashes, Arweave hashes, or individual centralized links across your collection.

// 3. Structuring Your Metadata JSON
// The _tokenURI string passed into mintArt should point directly to a JSON file format standardized by major NFT ecosystems. It typically looks like this:

// JSON
// {
//   "name": "Ethereal Sunset #1",
//   "description": "A beautiful 1-of-1 digital painting capturing the essence of web3.",
//   "image": "ipfs://QmXoypizjW3WknFiJnKLwHCnL72vedxjQkDDP1mXWo6uco",
//   "attributes": [
//     { "trait_type": "Style", "value": "Impressionism" },
//     { "trait_type": "Rarity", "value": "Mythic" }
//   ]
// }



