// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "forge-std/Script.sol";
import "../src/Basemo.sol";
import "@openzeppelin/contracts/proxy/ERC1967/ERC1967Proxy.sol";

contract DeployBasemo is Script {
    function run() external {
        address usdcAddress = vm.envAddress(
            "BASE_SEPOLIA_USDC_CONTRACT_ADDRESS"
        );

        vm.startBroadcast();

        // 1. Deploy implementation
        Basemo implementation = new Basemo();

        // 2. Prepare initialization data
        bytes memory initData = abi.encodeWithSelector(
            Basemo.initialize.selector,
            usdcAddress
        );

        // 3. Deploy proxy
        ERC1967Proxy proxy = new ERC1967Proxy(
            address(implementation),
            initData
        );

        console.log("Implementation deployed to:", address(implementation));
        console.log("Proxy deployed to:", address(proxy));

        vm.stopBroadcast();
    }
}
