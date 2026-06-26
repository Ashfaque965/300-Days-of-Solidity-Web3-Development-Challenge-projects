// Decentralized Freelance Board: Escrow job funds; client and worker match milestones.


// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

contract FreelanceEscrow {

    enum JobState { Dynamic, Active, Completed, Disputed }
    enum MilestoneState { Locked, Funded, Approved }

    struct Milestone {
        string description;
        uint256 budget;
        MilestoneState state;
    }

    address public immutable client;
    address public immutable freelancer;
    
    Milestone[] private _milestones;
    JobState public currentJobState;
    uint256 public currentMilestoneIndex;

    // Events
    event MilestoneFunded(uint256 indexed milestoneIndex, uint256 amount);
    event MilestoneApproved(uint256 indexed milestoneIndex, uint256 amountReleased);
    event JobDisputed(uint256 indexed milestoneIndex);

    // Custom Errors
    error OnlyClient();
    error OnlyFreelancer();
    error InvalidState();
    error IncorrectFunds();
    error TransferFailed();

    modifier onlyClient() {
        if (msg.sender != client) revert OnlyClient();
        _;
    }

    modifier onlyFreelancer() {
        if (msg.sender != freelancer) revert OnlyFreelancer();
        _;
    }

    /**
     * @dev Deploys the contract, binding the client, freelancer, and the breakdown of milestones.
     * @param _freelancer The wallet address of the worker.
     * @param descriptions The array of text descriptions for each phase.
     * @param budgets The array of budgets (in wei) mapping to each description step.
     */
    constructor(
        address _freelancer, 
        string[] memory descriptions, 
        uint256[] memory budgets
    ) {
        require(_freelancer != address(0), "Invalid freelancer address");
        require(descriptions.length == budgets.length, "Mismatched milestone parameters");
        require(descriptions.length > 0, "Must include at least one milestone");

        client = msg.sender;
        freelancer = _freelancer;
        currentJobState = JobState.Active;

        for (uint256 i = 0; i < descriptions.length; i++) {
            _milestones.push(Milestone({
                description: descriptions[i],
                budget: budgets[i],
                state: MilestoneState.Locked
            }));
        }
    }

    /**
     * @dev Step 1: Client funds the *current* active milestone.
     */
    function fundCurrentMilestone() external payable onlyClient {
        if (currentJobState != JobState.Active) revert InvalidState();
        
        Milestone storage milestone = _milestones[currentMilestoneIndex];
        if (milestone.state != MilestoneState.Locked) revert InvalidState();
        if (msg.value != milestone.budget) revert IncorrectFunds();

        milestone.state = MilestoneState.Funded;
        emit MilestoneFunded(currentMilestoneIndex, msg.value);
    }

    /**
     * @dev Step 2: Client approves the work done for the milestone and releases escrowed funds to the freelancer.
     */
    function approveMilestone() external onlyClient {
        if (currentJobState != JobState.Active) revert InvalidState();
        
        Milestone storage milestone = _milestones[currentMilestoneIndex];
        if (milestone.state != MilestoneState.Funded) revert InvalidState();

        // Effect: Mark approved and increment index BEFORE transferring funds (CEI Pattern)
        milestone.state = MilestoneState.Approved;
        uint256 payout = milestone.budget;
        
        emit MilestoneApproved(currentMilestoneIndex, payout);

        // Advance to next milestone if available, otherwise finalize contract
        if (currentMilestoneIndex < _milestones.length - 1) {
            currentMilestoneIndex++;
        } else {
            currentJobState = JobState.Completed;
        }

        // Interaction: Send locked native ETH to the freelancer
        (bool success, ) = payable(freelancer).call{value: payout}("");
        if (!success) revert TransferFailed();
    }

    /**
     * @dev Dispute Mechanism: Either party can freeze the contract if a stalemate occurs.
     */
    function triggerDispute() external {
        if (msg.sender != client && msg.sender != freelancer) revert InvalidState();
        if (currentJobState != JobState.Active) revert InvalidState();
        if (_milestones[currentMilestoneIndex].state != MilestoneState.Funded) revert InvalidState();

        currentJobState = JobState.Disputed;
        emit JobDisputed(currentMilestoneIndex);
    }

    /**
     * @dev Read function to check milestone status details.
     */
    function getMilestoneDetails(uint256 index) external view returns (
        string memory description,
        uint256 budget,
        MilestoneState state
    ) {
        Milestone memory m = _milestones[index];
        return (m.description, m.budget, m.state);
    }

    /**
     * @dev Helper to get the total number of milestones.
     */
    function totalMilestones() external view returns (uint256) {
        return _milestones.length;
    }
}