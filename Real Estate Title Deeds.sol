// Real Estate Title Deeds: Use unique token identities to handle property titles transfer.



// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC721/extensions/ERC721URIStorage.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract RealEstateTitleRegistry is ERC721URIStorage, Ownable {

    struct PropertyMetadata {
        string parcelID;        // Official assessor/government parcel identification string
        string legalDescription;// Detailed legal text describing boundaries and jurisdiction
        uint256 squareFeet;     // Documented size of the property land/structure
        bool isLiableForLien;   // Flag indicating if there are unresolved financial encumbrances
    }

    // Token ID => Specialized Property Details
    mapping(uint256 => PropertyMetadata) private _properties;
    
    // Internal counter for issuing unique sequential Title IDs
    uint256 private _nextTitleId;

    // Events to ensure a completely transparent public audit trail
    event TitleDeedMinted(uint256 indexed titleId, string parcelID, address indexed initialOwner);
    event TitleTransferred(uint256 indexed titleId, address indexed from, address indexed to);
    event LienStatusUpdated(uint256 indexed titleId, bool status);

    // Custom Errors
    error PropertyHasLien();
    error TitleDoesNotExist();

    /**
     * @dev Set the deployment address as the governing registry authority.
     */
    constructor(address initialAuthority) 
        ERC721("DeedRegistry", "TITLE") 
        Ownable(initialAuthority) 
    {}

    /**
     * @dev Government authority registers a new property and issues the digital deed.
     * @param initialOwner The wallet address receiving the initial title.
     * @param parcelID Government assessor reference number.
     * @param legalDescription Formal boundary texts.
     * @param sqFeet Total recorded square footage.
     * @param metadataURI IPFS/decentralized link pointing to physical legal surveys and documents.
     */
    function registerProperty(
        address initialOwner,
        string calldata parcelID,
        string calldata legalDescription,
        uint256 sqFeet,
        string calldata metadataURI
    ) external onlyOwner returns (uint256) {
        require(initialOwner != address(0), "Invalid owner address");
        
        uint256 titleId = _nextTitleId;
        _nextTitleId++;

        // Initialize property records in persistent storage
        _properties[titleId] = PropertyMetadata({
            parcelID: parcelID,
            legalDescription: legalDescription,
            squareFeet: sqFeet,
            isLiableForLien: false
        });

        _safeMint(initialOwner, titleId);
        _setTokenURI(titleId, metadataURI);

        emit TitleDeedMinted(titleId, parcelID, initialOwner);
        return titleId;
    }

    /**
     * @dev Restricts standard token transfers if the property has an active lien or financial dispute.
     * Overrides OpenZeppelin's internal update hook to inject real estate specific enforcement logic.
     */
    function _update(
        address to, 
        uint256 tokenId, 
        address auth
    ) internal override returns (address) {
        // Only enforce check if the token has already been minted (exists)
        if (_properties[tokenId].squareFeet > 0) {
            if (_properties[tokenId].isLiableForLien) {
                revert PropertyHasLien();
            }
        }
        
        address from = super._update(to, tokenId, auth);
        emit TitleTransferred(tokenId, from, to);
        return from;
    }

    /**
     * @dev Authority can toggle a lien flag on a property (e.g., unpaid taxes, mortgage defaults).
     * Prevents any market transfer or sale until resolved.
     */
    function updateLienStatus(uint256 titleId, bool hasLien) external onlyOwner {
        if (titleId >= _nextTitleId) revert TitleDoesNotExist();
        _properties[titleId].isLiableForLien = hasLien;
        emit LienStatusUpdated(titleId, hasLien);
    }

    /**
     * @dev Read function to fetch comprehensive legal data for a property parcel.
     */
    function getPropertyDetails(uint256 titleId) external view returns (
        string memory parcelID,
        string memory legalDescription,
        uint256 squareFeet,
        bool isLiableForLien
    ) {
        if (titleId >= _nextTitleId) revert TitleDoesNotExist();
        PropertyMetadata memory prop = _properties[titleId];
        return (prop.parcelID, prop.legalDescription, prop.squareFeet, prop.isLiableForLien);
    }
}