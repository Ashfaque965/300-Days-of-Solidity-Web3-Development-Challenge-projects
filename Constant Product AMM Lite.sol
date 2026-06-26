


// Oracle-Driven Weather Insurance: Instantly pay out policyholders if an oracle reports rainfall values over a threshold.


// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/ReentrancyGuard.sol";

contract WeatherInsurance is Ownable, ReentrancyGuard {

    struct Policy {
        uint256 premiumPaid;    // Amount deposited to secure the insurance
        uint256 payoutAmount;   // Guaranteed claim payout value
        uint256 targetDate;     // Specific day index or epoch timestamp covered
        bool isActive;          // Coverage state flag
        bool isClaimed;         // Prevent double-payouts
    }

    // Policyholder Address => Policy Details
    mapping(address => Policy) private _policies;

    // Authorized Oracle/Relay network address
    address public weatherOracle;

    // Rainfall threshold in millimeters (e.g., 50 means 50mm of rain)
    uint256 public immutable RAINFALL_THRESHOLD_MM;

    // Events
    event PolicyPurchased(address indexed policyholder, uint256 premium, uint256 payoutAmount);
    event OracleDataReceived(uint256 reportedRainfall, uint256 timestamp);
    event InsurancePaidOut(address indexed policyholder, uint256 payoutAmount);

    // Custom Errors
    error UnauthorizedOracle();
    error PolicyNotActive();
    error ThresholdNotMet();
    error InsufficientContractBalance();
    error TransferFailed();

    modifier onlyOracle() {
        if (msg.sender != weatherOracle) revert UnauthorizedOracle();
        _;
    }

    constructor(
        address initialOwner, 
        address initialOracle, 
        uint256 rainfallThreshold
    ) 
        Ownable(initialOwner) 
    {
        weatherOracle = initialOracle;
        RAINFALL_THRESHOLD_MM = rainfallThreshold;
    }

    /**
     * @dev Admin updates the trusted oracle node address if infrastructure changes.
     */
    function updateOracleAddress(address newOracle) external onlyOwner {
        require(newOracle != address(0), "Invalid oracle address");
        weatherOracle = newOracle;
    }

    /**
     * @dev Step 1: Underwriter pools native liquidity into the contract to cover potential claims.
     */
    function fundInsurancePool() external payable onlyOwner {}

    /**
     * @dev Step 2: A user buys an insurance policy by paying a set premium.
     * For production, pricing matrices are typically computed off-chain based on historical risk.
     * @param targetDate The specific future timestamp window being insured.
     * @param guaranteedPayout The agreed-upon payout amount if the weather threshold is crossed.
     */
    function purchasePolicy(uint256 targetDate, uint256 guaranteedPayout) external payable {
        require(msg.value > 0, "Premium must be greater than zero");
        require(guaranteedPayout > msg.value, "Payout must exceed premium");
        require(targetDate > block.timestamp, "Target date must be in the future");
        require(!_policies[msg.sender].isActive, "Active policy already exists");

        _policies[msg.sender] = Policy({
            premiumPaid: msg.value,
            payoutAmount: guaranteedPayout,
            targetDate: targetDate,
            isActive: true,
            isClaimed: false
        });

        emit PolicyPurchased(msg.sender, msg.value, guaranteedPayout);
    }

    /**
     * @dev Step 3: The automated Oracle network executes this callback when the weather window closes,
     * delivering data and instantly routing payouts if parameters match.
     * @param policyholder The customer wallet address under evaluation.
     * @param actualRainfallMM The true documented rainfall reported by local meteorological stations.
     */
    function processWeatherReport(
        address policyholder, 
        uint256 actualRainfallMM
    ) 
        external 
        onlyOracle 
        nonReentrant 
    {
        Policy storage policy = _policies[policyholder];
        
        if (!policy.isActive) revert PolicyNotActive();
        if (policy.isClaimed) revert PolicyNotActive();
        require(block.timestamp >= policy.targetDate, "Coverage period has not concluded yet");

        emit OracleDataReceived(actualRainfallMM, block.timestamp);

        // Deactivate policy state immediately to avoid re-evaluation loops
        policy.isActive = false;

        // Evaluation: Did the natural event cross our threshold barrier?
        if (actualRainfallMM >= RAINFALL_THRESHOLD_MM) {
            policy.isClaimed = true;
            uint256 payout = policy.payoutAmount;

            if (address(this).balance < payout) revert InsufficientContractBalance();

            emit InsurancePaidOut(policyholder, payout);

            // Interaction: Instantly route funds to the policyholder's address variable
            (bool success, ) = payable(policyholder).call{value: payout}("");
            if (!success) revert TransferFailed();
        }
    }

    /**
     * @dev View function to check policy status.
     */
    function getPolicyDetails(address policyholder) external view returns (
        uint256 premiumPaid,
        uint256 payoutAmount,
        uint256 targetDate,
        bool isActive,
        bool isClaimed
    ) {
        Policy memory p = _policies[policyholder];
        return (p.premiumPaid, p.payoutAmount, p.targetDate, p.isActive, p.isClaimed);
    }
}