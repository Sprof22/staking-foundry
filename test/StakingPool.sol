// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.24;

import {StakingPool} from "../src/StakingPool.sol";
import {IERC20} from "lib/openzeppelin-contracts/contracts/token/ERC20/IERC20.sol";
import {Test} from "forge-std/Test.sol";
import {console} from "forge-std/console.sol";

contract StakingPoolTest is Test {
    StakingPool public stakingPool;
    IERC20 public token;

    address deployer = address(0xf02D8F51FcaB2cB0DEE31712c11D01C7fcE25B3D);
    address staker = address(0x302D7467f5086e4D2962B0dBa2DF15d1B375AFe5);

    address constant TOKEN_ADDRESS = 0x824CB77980410424c1dF447B4E709bC276650c12; 

    uint256 rewardPercentage = 10;
    uint256 lockTime = 5 minutes;

    function setUp() public {
        vm.startPrank(deployer);
        stakingPool = new StakingPool();
        stakingPool.createPool(TOKEN_ADDRESS, rewardPercentage, lockTime);
        token = IERC20(TOKEN_ADDRESS);
        vm.stopPrank();

        deal(TOKEN_ADDRESS, staker, 10_000 * 10**18);
    }

    function testPoolCreation() public view {
        (IERC20 poolToken, uint256 reward, uint256 lock, uint256 totalStaked) = stakingPool.pools(0);
        
        assertEq(address(poolToken), TOKEN_ADDRESS);
        assertEq(reward, rewardPercentage);
        assertEq(lock, lockTime);
        assertEq(totalStaked, 0);
    }

    function testStake() public {
        uint256 stakeAmount = 1000 * 10**18;

        vm.startPrank(staker);
        token.approve(address(stakingPool), stakeAmount);
        stakingPool.stake(0, stakeAmount);

        (uint256 amount,, bool claimed) = stakingPool.getStake(0, staker);
        assertEq(amount, stakeAmount);
        assertEq(claimed, false);
        vm.stopPrank();
    }

    function testCannotStakeZero() public {
        vm.startPrank(staker);
        token.approve(address(stakingPool), 0);
        vm.expectRevert("Stake amount must be greater than zero");
        stakingPool.stake(0, 0);
        vm.stopPrank();
    }

    function testWithdraw() public {
        uint256 stakeAmount = 1000 * 10**18;

        vm.startPrank(staker);
        token.approve(address(stakingPool), stakeAmount);
        stakingPool.stake(0, stakeAmount);
        vm.stopPrank();

        vm.warp(block.timestamp + lockTime + 1);

        vm.startPrank(staker);
        stakingPool.withdraw(0);

        (uint256 amount,, bool claimed) = stakingPool.getStake(0, staker);
        assertEq(amount, stakeAmount);
        assertEq(claimed, true);
        vm.stopPrank();
    }

    function testCannotWithdrawBeforeLockTime() public {
        uint256 stakeAmount = 1000 * 10**18;

        vm.startPrank(staker);
        token.approve(address(stakingPool), stakeAmount);
        stakingPool.stake(0, stakeAmount);
        vm.stopPrank();

        vm.startPrank(staker);
        vm.expectRevert("Lock period not over");
        stakingPool.withdraw(0);
        vm.stopPrank();
    }

    function testCannotWithdrawTwice() public {
        uint256 stakeAmount = 1000 * 10**18;

        vm.startPrank(staker);
        token.approve(address(stakingPool), stakeAmount);
        stakingPool.stake(0, stakeAmount);
        vm.stopPrank();

        vm.warp(block.timestamp + lockTime + 1);

        vm.startPrank(staker);
        stakingPool.withdraw(0);
        vm.expectRevert("Already withdrawn");
        stakingPool.withdraw(0);
        vm.stopPrank();
    }
}
