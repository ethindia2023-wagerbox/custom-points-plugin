// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import "forge-std/Script.sol";
import {SafeProtocolRegistry} from "@safe/SafeProtocolRegistry.sol";
import {SafeProtocolManager} from "@safe/SafeProtocolManager.sol";
import {PointCardPlugin} from "../../src/PointCardPlugin.sol";

import {Wagerbox} from "../../src/ERC20/Wagerbox.sol";

import {MockPointProtocol} from "../../src/protocol/MockPointProtocol.sol";

contract DeployContracts is Script {
    function run(address owner) public returns (PointCardPlugin, SafeProtocolManager, SafeProtocolRegistry) {
        SafeProtocolRegistry registry = new SafeProtocolRegistry(owner);
        SafeProtocolManager manager = new SafeProtocolManager(owner, address(registry));
        Wagerbox token = new Wagerbox();
        MockPointProtocol protocol = new MockPointProtocol(token);
        token.mint(address(protocol), 1000000);
        PointCardPlugin plugin = new PointCardPlugin(address(protocol));
        return (plugin, manager, registry);
    }
}
