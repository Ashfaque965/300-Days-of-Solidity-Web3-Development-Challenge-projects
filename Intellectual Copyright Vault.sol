// Intellectual Copyright Vault: Timestamp your creative proof concepts to establish legal temporal priority.

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

contract CopyrightVault {

    struct ProofRecord {
        address author;         // The wallet address that registered the proof
        uint256 timestamp;      // The exact block timestamp of registration
        uint256 blockNumber;    // The block number containing the transaction
        string ipfsMetadataURI; // Optional link to encrypted metadata/context details
        bool isRegistered;      // Verification flag
    }

    // Mapping: File Hash (SHA-256 / Keccak256) => Registration Proof Data
    mapping(bytes32 => ProofRecord) private _vault;

    // Events for public indexing and verification
    event ProofAnchored(
        bytes32 indexed fileHash, 
        address indexed author, 
        uint256 timestamp, 
        string ipfsMetadataURI
    );

    // Custom Errors
    error ProofAlreadyExists(address existingAuthor, uint256 registeredTime);
    error ProofDoesNotExist();

    /**
     * @dev Anchor a unique digital asset fingerprint into the blockchain ledger.
     * @param fileHash The cryptographic hash of your digital file (e.g., generated via SHA-256).
     * @param ipfsMetadataURI Optional decentralized link detailing title, descriptions, or licensing tags.
     */
    function anchorProof(bytes32 fileHash, string calldata ipfsMetadataURI) external {
        if (_vault[fileHash].isRegistered) {
            revert ProofAlreadyExists({
                existingAuthor: _vault[fileHash].author,
                registeredTime: _vault[fileHash].timestamp
            });
        }

        // Effect: Record the proof parameters in persistent storage
        _vault[fileHash] = ProofRecord({
            author: msg.sender,
            timestamp: block.timestamp,
            blockNumber: block.number,
            ipfsMetadataURI: ipfsMetadataURI,
            isRegistered: true
        });

        emit ProofAnchored(fileHash, msg.sender, block.timestamp, ipfsMetadataURI);
    }

    /**
     * @dev Verification tool: Anyone can check the registration status of an asset hash.
     * Simply input the file's hash to see if, when, and by whom it was logged.
     */
    function verifyProof(bytes32 fileHash) external view returns (
        address author,
        uint256 timestamp,
        uint256 blockNumber,
        string memory ipfsMetadataURI,
        bool exists
    ) {
        ProofRecord memory record = _vault[fileHash];
        if (!record.isRegistered) revert ProofDoesNotExist();

        return (
            record.author,
            record.timestamp,
            record.blockNumber,
            record.ipfsMetadataURI,
            true
        );
    }
}