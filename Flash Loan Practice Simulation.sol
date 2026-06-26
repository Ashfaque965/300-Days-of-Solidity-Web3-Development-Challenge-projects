// Flash Loan Practice Simulation: Borrow imaginary liquidity and pay it back within a single mock block execution run.


// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/utils/ReentrancyGuard.sol";

contract SimpleStakingPool is ReentrancyGuard {
    
    IERC20 public immutable stakingToken;
    IERC20 public immutable rewardToken;

    // Flat reward rate: number of reward units earned per staked unit per second
    // E.g., 100000000000000 = 10^-4 reward tokens per staked token per second
    uint256 public immutable rewardRatePerSecond;

    struct Staker {
        uint256 stakedBalance;     // Amount of tokens currently locked
        uint256 rewardsAccumulated;// Claimable rewards updated during interactions
        uint256 lastUpdateTime;    // Last timestamp where rewards were accounted for
    }

    // Mapping: User Address => Staker Profile Details
    mapping(address => Staker) private _stakers;

    uint256 private _totalStaked;

    // Events
    event Staked(address indexed user, uint256 amount);
    event Withdrawn(address indexed user, uint256 amount);
    event RewardClaimed(address indexed user, uint256 reward);

    /**
     * @dev Initialize token links and flat interest parameters.
     */
    constructor(
        address _stakingToken, 
        address _rewardToken, 
        uint256 _rewardRate
    ) {
        stakingToken = IERC20(_stakingToken);
        rewardToken = IERC20(_rewardToken);
        rewardRatePerSecond = _rewardRate;
    }

    /**
     * @dev Internal modifier to update accumulated metrics *before* changing balances.
     */
    modifier updateReward(address account) {
        Staker storage staker = _stakers[account];
        
        if (staker.stakedBalance > 0) {
            uint256 timeElapsed = block.timestamp - staker.lastUpdateTime;
            // Reward math: balance * time elapsed * rate
            uint256 earned = (staker.stakedBalance * timeElapsed * rewardRatePerSecond) / 1e18;
            staker.rewardsAccumulated += earned;
        }
        
        staker.lastUpdateTime = block.timestamp;
        _;
    }

    /**
     * @dev Deposit staking tokens into the pool to begin earning yield.
     */
    function stake(uint256 amount) external nonReentrant updateReward(msg.sender) {
        require(amount > 0, "Cannot stake 0 tokens");

        _totalStaked += amount;
        _stakers[msg.sender].stakedBalance += amount;

        // Interaction: Pull tokens from user wallet (Requires prior approval)
        bool success = stakingToken.transferFrom(msg.sender, address(this), amount);
        require(success, "Staking transfer failed");

        emit Staked(msg.sender, amount);
    }

    /**
     * @dev Withdraw staked tokens back out of the pool.
     */
    function withdraw(uint256 amount) external nonReentrant updateReward(msg.sender) {
        Staker storage staker = _stakers[msg.sender];
        require(amount > 0, "Cannot withdraw 0 tokens");
        require(staker.stakedBalance >= amount, "Insufficient staked balance");

        _totalStaked -= amount;
        staker.stakedBalance -= amount;

        // Interaction: Return tokens safely
        bool success = stakingToken.transfer(msg.sender, amount);
        require(success, "Withdraw transfer failed");

        emit Withdrawn(msg.sender, amount);
    }

    /**
     * @dev Claim all accrued rewards generated over time.
     */
    function claimReward() external nonReentrant updateReward(msg.sender) {
        Staker storage staker = _stakers[msg.sender];
        uint256 reward = staker.rewardsAccumulated;
        
        if (reward > 0) {
            staker.rewardsAccumulated = 0;
            
            // Interaction: Send reward tokens from the contract pool
            bool success = rewardToken.transfer(msg.sender, reward);
            require(success, "Reward payout failed");
            
            emit RewardClaimed(msg.sender, reward);
        }
    }

    /**
     * @dev View function to calculate real-time earned rewards on frontends.
     */
    function earnedRewards(address account) external view returns (uint256) {
        Staker memory staker = _stakers[account];
        uint256 additionalReward = 0;

        if (staker.stakedBalance > 0) {
            uint256 timeElapsed = block.timestamp - staker.lastUpdateTime;
            additionalReward = (staker.stakedBalance * timeElapsed * rewardRatePerSecond) / 1e18;
        }

        return staker.rewardsAccumulated + additionalReward;
    }

    /**
     * @dev Helper to see details about a staker profile.
     */
    function getStakerDetails(address account) external view returns (uint256 stakedBalance, uint256 rewardsAccumulated) {
        return (_stakers[account].stakedBalance, _stakers[account].rewardsAccumulated);
    }
}