// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "forge-std/Script.sol";
import "../src/Basedmo.sol";

contract DeployBasedmo is Script {
    function run() external {
        vm.startBroadcast();

        address usdcTokenAddress = vm.envAddress(
            "BASE_SEPOLIA_USDC_CONTRACT_ADDRESS"
        );

        // Deploy the Basedmo contract
        new Basedmo(usdcTokenAddress);

        vm.stopBroadcast();
    }
}
