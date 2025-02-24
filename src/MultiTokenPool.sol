// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.24;

import {IERC20} from "lib/openzeppelin-contracts/contracts/token/ERC20/IERC20.sol";
import {Ownable} from "lib/openzeppelin-contracts/contracts/access/Ownable.sol";

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

    constructor() Ownable(msg.sender) {
        // Initialize the contract with the deployer as the owner
    }

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

        poolCount++;
    }

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
    }

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
    }

    function getStake(uint256 _poolId, address _user) external view returns (uint256, uint256, bool) {
        Stake memory stakeInfo = stakes[_poolId][_user];
        return (stakeInfo.amount, stakeInfo.startTime, stakeInfo.claimed);
    }
}
