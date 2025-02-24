// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.24;

import {StakingPool} from "../../src/StakingPool.sol";
import {Script} from "forge-std/Script.sol";
import {console} from "forge-std/console.sol";

contract DeployStakingPool is Script {
    function run() external {
        uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");
        vm.startBroadcast(deployerPrivateKey);

        StakingPool stakingPool = new StakingPool();

        vm.stopBroadcast();

        console.log("StakingPool deployed at:", address(stakingPool));
    }
}