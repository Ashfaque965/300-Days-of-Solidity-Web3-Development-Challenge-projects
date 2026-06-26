// Prediction Market Pool: Let users stake tokens on a simple binary outcome (e.g., Team A vs Team B).

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

/**
 * @dev Minimal ERC20 token interface required for pool interactions.
 */
interface IERC20 {
    function transfer(address to, uint256 value) external returns (bool);
    function transferFrom(address from, address to, uint256 value) external returns (bool);
    function balanceOf(address account) external view returns (uint256);
}

/**
 * @title PredictionMarketPool
 * @notice Allows users to stake tokens on binary outcomes and claim proportional rewards.
 */
contract PredictionMarketPool {
    
    enum Outcome { NONE, TEAM_A, TEAM_B }

    // --- State Variables ---
    IERC20 public immutable bettingToken;
    address public immutable operator;
    string public marketDescription;

    // Pool Tracking
    uint256 public totalTeamAPool;
    uint256 public totalTeamBPool;
    
    // User Share Accounting
    mapping(address => uint256) public teamAShares;
    mapping(address => uint256) public teamBShares;
    mapping(address => bool) public hasClaimed;

    // Market Status
    bool public isResolved;
    bool public isClosed;
    Outcome public winningOutcome;

    // --- Events ---
    event BetPlaced(address indexed user, Outcome indexed choice, uint256 amount);
    event MarketClosed();
    event MarketResolved(Outcome indexed winner);
    event RewardsClaimed(address indexed user, uint256 amount);

    modifier onlyOperator() {
        require(msg.sender == operator, "Only operator permitted");
        _;
    }

    modifier marketActive() {
        require(!isClosed && !isResolved, "Market is closed or resolved");
        _;
    }

    constructor(address _bettingToken, string memory _description) {
        require(_bettingToken != address(0), "Invalid token address");
        bettingToken = IERC20(_bettingToken);
        operator = msg.sender;
        marketDescription = _description;
    }

    // --- External Functions ---

    /**
     * @notice Place a bet on Team A or Team B by staking tokens.
     * @param choice The side you are betting on (Outcome.TEAM_A or Outcome.TEAM_B).
     * @param amount The amount of ERC20 betting tokens to stake.
     */
    function placeBet(Outcome choice, uint256 amount) external marketActive {
        require(amount > 0, "Bet amount must be greater than 0");
        require(choice == Outcome.TEAM_A || choice == Outcome.TEAM_B, "Invalid outcome choice");

        // Transfer betting tokens from user to this pool contract
        bool success = bettingToken.transferFrom(msg.sender, address(address(this)), amount);
        require(success, "Token transfer failed");

        if (choice == Outcome.TEAM_A) {
            teamAShares[msg.sender] += amount;
            totalTeamAPool += amount;
        } else {
            teamBShares[msg.sender] += amount;
            totalTeamBPool += amount;
        }

        emit BetPlaced(msg.sender, choice, amount);
    }

    /**
     * @notice Stop users from placing any more bets (e.g., when the game/event begins).
     */
    function closeMarket() external onlyOperator {
        require(!isClosed, "Market already closed");
        isClosed = true;
        emit MarketClosed();
    }

    /**
     * @notice Finalize the winning side. This locks the contract configuration and opens claims.
     * @param _winner The final winning outcome.
     */
    function resolveMarket(Outcome _winner) external onlyOperator {
        require(!isResolved, "Market already resolved");
        require(_winner == Outcome.TEAM_A || _winner == Outcome.TEAM_B, "Can only resolve to A or B");
        
        isClosed = true; 
        isResolved = true;
        winningOutcome = _winner;

        emit MarketResolved(_winner);
    }

    /**
     * @notice Withdraw your payout if you held shares of the winning outcome.
     */
    function claimRewards() external {
        require(isResolved, "Market not yet resolved");
        require(!hasClaimed[msg.sender], "Rewards already claimed");

        uint256 rewardAmount = getPendingReward(msg.sender);
        require(rewardAmount > 0, "No winning shares or zero payout balance");

        hasClaimed[msg.sender] = true;
        
        bool success = bettingToken.transfer(msg.sender, rewardAmount);
        require(success, "Payout transfer failed");

        emit RewardsClaimed(msg.sender, rewardAmount);
    }

    // --- Public View Functions ---

    /**
     * @notice Calculates the exact reward payout for a specific user based on pool mechanics.
     */
    function getPendingReward(address user) public view returns (uint256) {
        if (!isResolved || hasClaimed[user]) {
            return 0;
        }

        uint256 totalPool = totalTeamAPool + totalTeamBPool;

        if (winningOutcome == Outcome.TEAM_A) {
            if (totalTeamAPool == 0) return 0;
            // Reward formula: (User Shares * Total Combined Pool) / Total Winning Pool
            return (teamAShares[user] * totalPool) / totalTeamAPool;
        } else if (winningOutcome == Outcome.TEAM_B) {
            if (totalTeamBPool == 0) return 0;
            return (teamBShares[user] * totalPool) / totalTeamBPool;
        }

        return 0;
    }
}