// Supply Chain Tracker: Record physical shipping location updates at every step of a product's journey.

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/access/Ownable.sol";

contract SupplyChainTracker is Ownable {

    struct TrackingCheckpoint {
        string physicalLocation;  // City, Country, or Facility ID (e.g., "Rotterdam Port, NL")
        string statusDetails;     // Custom note (e.g., "Cleared Customs", "Packaged")
        uint256 timestamp;        // Precise time of logging
        address custodian;        // Wallet address processing the item at this step
    }

    struct Item {
        string name;              // Name of the batch or product
        string manufacturer;      // Origin company identifier
        bool isCompleted;         // Flag indicating if the product has reached its destination
        uint256 checkpointCount;  // Internal counter to track checkpoint logs
    }

    // Item ID => Core Product Details
    mapping(uint256 => Item) private _items;

    // Item ID => Map of Checkpoint Indexes => Checkpoint Logs
    mapping(uint256 => mapping(uint256 => TrackingCheckpoint)) private _history;

    // Mapping to authorize specific logistical workers/nodes to write updates
    mapping(address => bool) public authorizedHandlers;

    uint256 public totalItemCount;

    // Events for real-time off-chain indexing
    event ItemRegistered(uint256 indexed itemId, string name, string manufacturer);
    event CheckpointAdded(uint256 indexed itemId, string physicalLocation, string statusDetails, address indexed custodian);
    event ItemDelivered(uint256 indexed itemId);

    // Custom Errors
    error UnauthorizedHandler();
    error ItemAlreadyDelivered();
    error ItemDoesNotExist();

    modifier onlyAuthorized() {
        if (!authorizedHandlers[msg.sender] && msg.sender != owner()) {
            revert UnauthorizedHandler();
        }
        _;
    }

    constructor(address initialOwner) Ownable(initialOwner) {}

    /**
     * @dev Grant or revoke log-writing permissions for a logistics company or IoT node.
     */
    function setHandlerAuthorization(address handler, bool status) external onlyOwner {
        authorizedHandlers[handler] = status;
    }

    /**
     * @dev Step 1: Register a new batch or unique physical product into the tracking registry.
     */
    function registerProduct(string calldata name, string calldata manufacturer) external onlyAuthorized returns (uint256) {
        uint256 itemId = totalItemCount;
        
        _items[itemId] = Item({
            name: name,
            manufacturer: manufacturer,
            isCompleted: false,
            checkpointCount: 0
        });

        totalItemCount++;
        emit ItemRegistered(itemId, name, manufacturer);
        return itemId;
    }

    /**
     * @dev Step 2: Record a new physical location update as the product changes hands.
     * @param itemId The unique ID of the tracked asset.
     * @param location The geographic or facility name string.
     * @param status Descriptive condition note.
     */
    function addCheckpoint(
        uint256 itemId, 
        string calldata location, 
        string calldata status
    ) external onlyAuthorized {
        if (itemId >= totalItemCount) revert ItemDoesNotExist();
        
        Item storage item = _items[itemId];
        if (item.isCompleted) revert ItemAlreadyDelivered();

        uint256 currentIdx = item.checkpointCount;
        
        // Log the new checkpoint data into history
        _history[itemId][currentIdx] = TrackingCheckpoint({
            physicalLocation: location,
            statusDetails: status,
            timestamp: block.timestamp,
            custodian: msg.sender
        });

        item.checkpointCount++;
        
        emit CheckpointAdded(itemId, location, status, msg.sender);
    }

    /**
     * @dev Step 3: Permanently lock tracking once the cargo reaches its final destination.
     */
    function finalizeDelivery(uint256 itemId) external onlyAuthorized {
        if (itemId >= totalItemCount) revert ItemDoesNotExist();
        Item storage item = _items[itemId];
        if (item.isCompleted) revert ItemAlreadyDelivered();

        item.isCompleted = true;
        emit ItemDelivered(itemId);
    }

    /**
     * @dev Fetch a specific historical log for an item.
     */
    function getCheckpoint(uint256 itemId, uint256 checkpointIndex) external view returns (
        string memory physicalLocation,
        string memory statusDetails,
        uint256 timestamp,
        address custodian
    ) {
        if (itemId >= totalItemCount) revert ItemDoesNotExist();
        TrackingCheckpoint memory cp = _history[itemId][checkpointIndex];
        return (cp.physicalLocation, cp.statusDetails, cp.timestamp, cp.custodian);
    }

    /**
     * @dev Helper to fetch general product state metrics.
     */
    function getItemDetails(uint256 itemId) external view returns (
        string memory name,
        string memory manufacturer,
        bool isCompleted,
        uint256 totalCheckpoints
    ) {
        if (itemId >= totalItemCount) revert ItemDoesNotExist();
        Item memory item = _items[itemId];
        return (item.name, item.manufacturer, item.isCompleted, item.checkpointCount);
    }
}