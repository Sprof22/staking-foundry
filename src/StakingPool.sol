// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.24;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract StakingPool is Ownable {
    struct Pool {
        IERC20 stakingToken;
        IERC20 rewardToken;
        uint256 rewardPercentage; // Percentage reward per staking period
        uint256 lockTime; // Lock period in seconds
        uint256 totalStaked;
    }

    struct Stake {
        uint256 amount;
        uint256 startTime;
        bool claimed;
    }

    uint256 public poolCount;
    mapping(uint256 => Pool) public pools;
    mapping(uint256 => mapping(address => Stake)) public stakes; // poolId -> user -> stake details

    event PoolCreated(uint256 poolId, address stakingToken, address rewardToken, uint256 rewardPercentage, uint256 lockTime);
    event Staked(uint256 poolId, address user, uint256 amount);
    event Withdrawn(uint256 poolId, address user, uint256 amount, uint256 reward);

    function createPool(
        address _stakingToken,
        address _rewardToken,
        uint256 _rewardPercentage,
        uint256 _lockTime
    ) external onlyOwner {
        require(_stakingToken != address(0) && _rewardToken != address(0), "Invalid token addresses");
        require(_rewardPercentage > 0, "Reward percentage must be greater than 0");
        require(_lockTime > 0, "Lock time must be greater than 0");

        pools[poolCount] = Pool({
            stakingToken: IERC20(_stakingToken),
            rewardToken: IERC20(_rewardToken),
            rewardPercentage: _rewardPercentage,
            lockTime: _lockTime,
            totalStaked: 0
        });

        emit PoolCreated(poolCount, _stakingToken, _rewardToken, _rewardPercentage, _lockTime);
        poolCount++;
    }

    /**
     * @dev Allows a user to stake tokens into a specific pool
     * @param _poolId The pool ID to stake in
     * @param _amount Amount of tokens to stake
     */
    function stake(uint256 _poolId, uint256 _amount) external {
        Pool storage pool = pools[_poolId];
        require(address(pool.stakingToken) != address(0), "Pool does not exist");
        require(_amount > 0, "Stake amount must be greater than zero");

        pool.stakingToken.transferFrom(msg.sender, address(this), _amount);

        stakes[_poolId][msg.sender] = Stake({
            amount: _amount,
            startTime: block.timestamp,
            claimed: false
        });

        pool.totalStaked += _amount;

        emit Staked(_poolId, msg.sender, _amount);
    }

    /**
     * @dev Allows a user to withdraw their stake and rewards after lock time
     * @param _poolId The pool ID to withdraw from
     */
    function withdraw(uint256 _poolId) external {
        Stake storage stakeInfo = stakes[_poolId][msg.sender];
        Pool storage pool = pools[_poolId];

        require(stakeInfo.amount > 0, "No active stake found");
        require(block.timestamp >= stakeInfo.startTime + pool.lockTime, "Lock period not over");
        require(!stakeInfo.claimed, "Already withdrawn");

        uint256 reward = (stakeInfo.amount * pool.rewardPercentage) / 100;
        stakeInfo.claimed = true;

        pool.stakingToken.transfer(msg.sender, stakeInfo.amount);
        pool.rewardToken.transfer(msg.sender, reward);

        emit Withdrawn(_poolId, msg.sender, stakeInfo.amount, reward);
    }

    /**
     * @dev Returns the current stake info for a user in a pool
     * @param _poolId Pool ID
     * @param _user User address
     * @return amount, startTime, claimed status
     */
    function getStake(uint256 _poolId, address _user) external view returns (uint256, uint256, bool) {
        Stake memory stakeInfo = stakes[_poolId][_user];
        return (stakeInfo.amount, stakeInfo.startTime, stakeInfo.claimed);
    }
}
