// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.24;

import {StakingPool} from "../../src/MultiTokenPool.sol"; // Adjust the path as needed
import {Script} from "forge-std/Script.sol";
import {console} from "forge-std/console.sol";

contract DeployStakingPool is Script {
    function run() external {
        uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY"); // Load private key from .env file
        vm.startBroadcast(deployerPrivateKey);

        StakingPool stakingPool = new StakingPool();

        vm.stopBroadcast();

        console.log("StakingPool deployed at:", address(stakingPool));
    }
}