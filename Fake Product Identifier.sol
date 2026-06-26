// Fake Product Identifier: Let brands tag verified manufacturer registry IDs for consumers to check.


// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/access/Ownable.sol";

contract FakeProductIdentifier is Ownable {

    struct ProductRecord {
        string batchId;          // Production batch reference number
        uint256 registrationTime;// Timestamp of when the item was logged
        bool isVerified;         // Flips to true once recorded by the brand
        bool isClaimed;          // Flips to true once a consumer verifies it for the first time
    }

    // Mapping: Product Hash (keccak256 of unique serial) => Product Record
    mapping(bytes32 => ProductRecord) private _registry;

    // Track authorized manufacturer nodes/brands
    mapping(address => bool) public authorizedBrands;

    // Events
    event ProductRegistered(bytes32 indexed productHash, string batchId);
    event ProductVerifiedByConsumer(bytes32 indexed productHash, address indexed consumer);

    // Custom Errors
    error UnauthorizedBrand();
    error ProductNotAuthentic();
    error ProductAlreadyClaimed();

    modifier onlyAuthorized() {
        if (!authorizedBrands[msg.sender] && msg.sender != owner()) {
            revert UnauthorizedBrand();
        }
        _;
    }

    constructor(address initialOwner) Ownable(initialOwner) {}

    /**
     * @dev Grant or revoke registration capabilities to a factory line or sub-brand.
     */
    function setBrandAuthorization(address brandAddress, bool status) external onlyOwner {
        authorizedBrands[brandAddress] = status;
    }

    /**
     * @dev Step 1: Factory registers a batch of authentic product hashes.
     * @param productHashes Array of cryptographic hashes corresponding to individual unique serials.
     * @param batchId The manufacturing batch identification string.
     */
    function registerProducts(bytes32[] calldata productHashes, string calldata batchId) external onlyAuthorized {
        for (uint256 i = 0; i < productHashes.length; i++) {
            bytes32 pHash = productHashes[i];
            
            // Avoid overwriting existing authentic registry logs
            if (!_registry[pHash].isVerified) {
                _registry[pHash] = ProductRecord({
                    batchId: batchId,
                    registrationTime: block.timestamp,
                    isVerified: true,
                    isClaimed: false
                });
                
                emit ProductRegistered(pHash, batchId);
            }
        }
    }

    /**
     * @dev Step 2: Consumer scans the product QR/NFC code and claims it.
     * This permanently flags the unique code as "used", neutralizing copycat clones.
     * @param productRawSerial The plaintext unique serial code revealed under a scratch card or read by an NFC reader.
     */
    function verifyAndClaimProduct(string calldata productRawSerial) external returns (string memory batchId) {
        // Generate the matching storage lookup hash from the user's input
        bytes32 verificationHash = keccak256(abi.encodePacked(productRawSerial));
        
        ProductRecord storage record = _registry[verificationHash];
        
        // 1. Check authenticity
        if (!record.isVerified) revert ProductNotAuthentic();
        
        // 2. Check if a counterfeiter duplicated this exact serial number onto fake items
        if (record.isClaimed) revert ProductAlreadyClaimed();

        // 3. Effect: Permanently flag as claimed
        record.isClaimed = true;

        emit ProductVerifiedByConsumer(verificationHash, msg.sender);

        return record.batchId;
    }

    /**
     * @dev Public read function allowing anyone to inspect a product's current authenticity state.
     */
    function checkProductState(bytes32 productHash) external view returns (
        string memory batchId,
        uint256 registrationTime,
        bool isAuthentic,
        bool isAlreadyClaimed
    ) {
        ProductRecord memory record = _registry[productHash];
        return (record.batchId, record.registrationTime, record.isVerified, record.isClaimed);
    }
}