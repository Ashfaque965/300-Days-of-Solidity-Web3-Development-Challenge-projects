// Digital Wills & Inheritance: A "dead-man's switch" that sends your holdings to heirs if you don't ping the contract once a year.



// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

contract DeadMansSwitch {

    struct Heir {
        uint256 allocationPercentage; // Percentage of the total pool (e.g., 50 = 50%)
        bool hasClaimed;              // Tracking to prevent double-claiming
    }

    address public immutable testator;
    uint256 public constant INACTIVITY_LIMIT = 365 days;
    
    uint256 public lastPingTimestamp;
    address[] private _heirAddresses;
    
    // Heir Address => Heir Details
    mapping(address => Heir) private _heirs;

    // Events
    event ContractPinged(uint256 timestamp);
    event InheritanceClaimed(address indexed heir, uint256 amount);
    event FundsDeposited(address indexed sender, uint256 amount);

    // Custom Errors
    error OnlyTestator();
    error TestatorIsStillAlive();
    error NotAnAuthorizedHeir();
    error AlreadyClaimed();
    error InvalidAllocationTotals();
    error TransferFailed();

    modifier onlyTestator() {
        if (msg.sender != testator) revert OnlyTestator();
        _;
    }

    /**
     * @dev Deploys the switch, establishes the testator, and sets up heirs.
     * @param heirs An array of target beneficiary addresses.
     * @param percentages An array of matching payout percentages (must sum to exactly 100).
     */
    constructor(address[] memory heirs, uint256[] memory percentages) payable {
        require(heirs.length == percentages.length, "Mismatched heir configuration arrays");
        require(heirs.length > 0, "Must specify at least one heir");

        testator = msg.sender;
        lastPingTimestamp = block.timestamp;

        uint256 totalPercentage = 0;
        for (uint256 i = 0; i < heirs.length; i++) {
            address heirAddr = heirs[i];
            require(heirAddr != address(0), "Invalid heir address");
            require(_heirs[heirAddr].allocationPercentage == 0, "Duplicate heir address");

            _heirs[heirAddr] = Heir({
                allocationPercentage: percentages[i],
                hasClaimed: false
            });
            _heirAddresses.push(heirAddr);
            totalPercentage += percentages[i];
        }

        if (totalPercentage != 100) revert InvalidAllocationTotals();
    }

    /**
     * @dev Allows the contract to accept additional ETH top-ups over time.
     */
    receive() external payable {
        emit FundsDeposited(msg.sender, msg.value);
    }

    /**
     * @dev The owner must call this regularly to prove they are still active.
     * Resets the 1-year countdown clock.
     */
    function ping() external onlyTestator {
        lastPingTimestamp = block.timestamp;
        emit ContractPinged(block.timestamp);
    }

    /**
     * @dev Heirs can call this to pull their allocated assets if the testator goes dark.
     */
    function claimInheritance() external {
        // 1. Check: Has a full year passed since the last ping?
        if (block.timestamp < lastPingTimestamp + INACTIVITY_LIMIT) {
            revert TestatorIsStillAlive();
        }

        Heir storage heirInfo = _heirs[msg.sender];
        if (heirInfo.allocationPercentage == 0) revert NotAnAuthorizedHeir();
        if (heirInfo.hasClaimed) revert AlreadyClaimed();

        // 2. Effect: Calculate payout relative to current total balance and flag as claimed
        // We use a snapshot of the balance at the moment the first claims start.
        uint256 currentBalance = address(this).balance;
        uint256 payout = (currentBalance * heirInfo.allocationPercentage) / 100;

        heirInfo.hasClaimed = true;

        emit InheritanceClaimed(msg.sender, payout);

        // 3. Interaction: Transfer the native ETH
        (bool success, ) = payable(msg.sender).call{value: payout}("");
        if (!success) revert TransferFailed();
    }

    /**
     * @dev View helper to check details about a specific heir.
     */
    function getHeirDetails(address heirAddr) external view returns (uint256 allocation, bool claimed) {
        Heir memory h = _heirs[heirAddr];
        return (h.allocationPercentage, h.hasClaimed);
    }

    /**
     * @dev Calculate exactly how many seconds remain before the switch is triggerable.
     */
    function timeUntilRelease() external view returns (uint256) {
        if (block.timestamp >= lastPingTimestamp + INACTIVITY_LIMIT) {
            return 0;
        }
        return (lastPingTimestamp + INACTIVITY_LIMIT) - block.timestamp;
    }
}