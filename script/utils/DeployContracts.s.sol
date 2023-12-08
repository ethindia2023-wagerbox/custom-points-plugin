// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import "forge-std/Script.sol";
import {SafeProtocolRegistry} from "@safe/SafeProtocolRegistry.sol";
import {SafeProtocolManager} from "@safe/SafeProtocolManager.sol";
import {PointCardPlugin} from "../../src/PointCardPlugin.sol";

contract DeployContracts is Script {
    function run(address owner) public returns (PointCardPlugin, SafeProtocolManager, SafeProtocolRegistry) {
        SafeProtocolRegistry registry = new SafeProtocolRegistry(owner);
        SafeProtocolManager manager = new SafeProtocolManager(owner, address(registry));
        PointCardPlugin plugin = new PointCardPlugin(address(0)); // dummy address
        return (plugin, manager, registry);
    }
}
