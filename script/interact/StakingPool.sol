// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.24;

import {StakingPool} from "../../src/StakingPool.sol"; // Adjust path as needed
import {IERC20} from "lib/openzeppelin-contracts/contracts/token/ERC20/IERC20.sol";
import {Script} from "forge-std/Script.sol";
import {console} from "forge-std/console.sol";

contract StakingPoolUserActions is Script {
    address constant DEPLOYER = 0xf584F8728B874a6a5c7A8d4d387C9aae9172D621; // Replace with deployer address
    address constant STAKER = 0xf02D8F51FcaB2cB0DEE31712c11D01C7fcE25B3D; 
    address constant TEST_TOKEN = 0xf02D8F51FcaB2cB0DEE31712c11D01C7fcE25B3D; 

    function run() external {
        vm.startPrank(DEPLOYER); 

        StakingPool stakingPool = new StakingPool();
        console.log("StakingPool deployed at:", address(stakingPool));

        // Step 2: Create a staking pool
        uint256 rewardPercentage = 10; 
        uint256 lockTime = 5 minutes; 
        stakingPool.createPool(TEST_TOKEN, rewardPercentage, lockTime);
        console.log("Pool created with token:", TEST_TOKEN);

        vm.stopPrank(); 

       
        vm.startPrank(STAKER);
        IERC20 token = IERC20(TEST_TOKEN);

        uint256 stakeAmount = 1000 * 10**18; 
        token.approve(address(stakingPool), stakeAmount);
        
        stakingPool.stake(0, stakeAmount); 
        console.log("User staked:", stakeAmount);

        vm.stopPrank();

        // Step 4: Fast-forward time beyond lock period
        vm.warp(block.timestamp + lockTime + 1); 

        // Step 5: Impersonate STAKER again and withdraw
        vm.startPrank(STAKER);
        stakingPool.withdraw(0); 
        console.log("User withdrew their stake and rewards");

        vm.stopPrank(); 
    }
}
