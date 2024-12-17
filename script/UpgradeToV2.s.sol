// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "forge-std/Script.sol";
import "../src/Basemo.sol";
import "../src/BasemoV2.sol";

contract UpgradeToV2 is Script {
    function run() external {
        address proxyAddress = vm.envAddress("PROXY_CONTRACT_ADDRESS");

        vm.startBroadcast();

        // 1. Deploy new implementation
        BasemoV2 implementationV2 = new BasemoV2();

        // 2. Upgrade proxy to V2
        Basemo proxy = Basemo(proxyAddress);
        proxy.upgradeTo(address(implementationV2));

        console.log(
            "V2 Implementation deployed to:",
            address(implementationV2)
        );
        console.log("Proxy upgraded to V2");

        vm.stopBroadcast();
    }
}
