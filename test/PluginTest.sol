// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import "forge-std/Test.sol";
import {SafeProtocolManager} from "@safe/SafeProtocolManager.sol";
import {ISafe} from "@safe/interfaces/Accounts.sol";
import {SafeProtocolRegistry} from "@safe/SafeProtocolRegistry.sol";
import {SafeTransaction, SafeProtocolAction} from "@safe/DataTypes.sol";
import {Safe} from "@safe/Safe.sol";
import {SafeProxy} from "@safe/proxies/SafeProxy.sol";
import {TokenCallbackHandler} from "@safe/handler/TokenCallbackHandler.sol";
import {PointCardPlugin} from "../src/PointCardPlugin.sol";
import {Enum} from "@safe/common/Enum.sol";
import {Strings} from "@openzeppelin/contracts/utils/Strings.sol";
import {Deploy} from "../script/Deploy.s.sol";
import {SafeTxConfig} from "../script/utils/SafeTxConfig.s.sol";

import {Wagerbox} from "../src/ERC20/Wagerbox.sol";
import {MockToken} from "../src/ERC20/MockToken.sol";
import {MockPointProtocol} from "../src/protocol/MockPointProtocol.sol";

/**
 * @title Foundry Test Setup for Safe Plugin
 * @author @willschiller
 * @notice This Test contract sets up an entirely fresh Safe{Core} Protocol instance with plugin and handles all the regitration.
 * (Deploys Safe, Manager, Registery & Plugin). This allows you to test locally without forking or sending testnet transaction.
 * @dev set the following environment variables in .env:
 *  SAFE_ADDRESS (The address of your safe),
 *  SAFE_OWNER_ADDRESS (An EOA that is an owner of your safe),
 *  SAFE_OWNER_PRIVATE_KEY (The EOA key) In production, you should not keep your private key in the env.
 * @dev One test is included to check that the plugin is enabled for the safe correctly.
 * @dev Extend with your own tests.
 */

contract PluginTest is Test {
    error SafeTxFailure(bytes reason);

    address owner = vm.envAddress("SAFE_OWNER_ADDRESS");
    Safe singleton;
    SafeProxy proxy;
    Safe safe;
    MockPointProtocol protocol;
    TokenCallbackHandler handler;
    PointCardPlugin plugin;
    SafeProtocolManager manager;
    SafeProtocolRegistry registry;
    SafeTxConfig safeTxConfig = new SafeTxConfig();
    SafeTxConfig.Config config = safeTxConfig.run();

    Wagerbox token;
    MockToken mt;

    function getTransactionHash(
        address _to,
        bytes memory _data
    ) public view returns (bytes32) {
        return
            safe.getTransactionHash(
                _to,
                config.value,
                _data,
                config.operation,
                config.safeTxGas,
                config.baseGas,
                config.gasPrice,
                config.gasToken,
                config.refundReceiver,
                safe.nonce()
            );
    }

    function sendSafeTx(
        address _to,
        bytes memory _data,
        bytes memory sig
    ) public {
        try
            safe.execTransaction(
                _to,
                config.value,
                _data,
                config.operation,
                config.safeTxGas,
                config.baseGas,
                config.gasPrice,
                config.gasToken,
                config.refundReceiver,
                sig //sig
            )
        {} catch (bytes memory reason) {
            revert SafeTxFailure(reason);
        }
    }

    function setUp() public {
        vm.startPrank(owner);
        vm.selectFork(vm.createFork(vm.envString("GOERLI_RPC_URL")));
        token = new Wagerbox();
        protocol = new MockPointProtocol(token);
        plugin = new PointCardPlugin(address(protocol));
        registry = new SafeProtocolRegistry(owner);
        manager = new SafeProtocolManager(owner, address(registry));
        singleton = new Safe();
        proxy = new SafeProxy(address(singleton));
        handler = new TokenCallbackHandler();

        mt = new MockToken();

        token.mint(address(protocol), 1000000);

        safe = Safe(payable(address(proxy)));
        address[] memory owners = new address[](1);
        owners[0] = owner;
        safe.setup(
            owners,
            1,
            address(0),
            bytes(""),
            address(handler),
            address(0),
            0,
            payable(address(owner))
        );
        registry.addIntegration(address(plugin), Enum.IntegrationType.Plugin);

        bytes32 txHash = getTransactionHash(
            address(safe),
            abi.encodeWithSignature("enableModule(address)", address(manager))
        );
        (uint8 v, bytes32 r, bytes32 s) = vm.sign(
            vm.envUint("SAFE_OWNER_PRIVATE_KEY"),
            txHash
        );
        sendSafeTx(
            address(safe),
            abi.encodeWithSignature("enableModule(address)", address(manager)),
            abi.encodePacked(r, s, v)
        );

        txHash = getTransactionHash(
            address(manager),
            abi.encodeWithSignature(
                "enablePlugin(address,bool)",
                address(plugin),
                false
            )
        );
        (v, r, s) = vm.sign(vm.envUint("SAFE_OWNER_PRIVATE_KEY"), txHash);
        sendSafeTx(
            address(manager),
            abi.encodeWithSignature(
                "enablePlugin(address,bool)",
                address(plugin),
                false
            ),
            abi.encodePacked(r, s, v)
        );
        vm.stopPrank();
    }

    function testisPluginEnabled() public {
        bool enabled = manager.isPluginEnabled(address(safe), address(plugin));
        assertEq(enabled, true);
    }

    function testExecETH() public {
        // subscribe wallet first
        bytes32 txHash = getTransactionHash(
            address(plugin),
            abi.encodeWithSignature(
                "subscribe(address)",
                address(safe)
            )
        );
        (uint8 v, bytes32 r, bytes32 s) = vm.sign(
            vm.envUint("SAFE_OWNER_PRIVATE_KEY"),
            txHash
        );
        sendSafeTx(
            address(plugin),
            abi.encodeWithSignature("subscribe(address)", address(safe)),
            abi.encodePacked(r, s, v)
        );

        assertEq(protocol.getExecutor(address(safe)), address(plugin));

        address dealer = makeAddr("ticket_dealier");
        emit log_named_address("ticket_dealier", dealer);

        vm.deal(address(safe), 1000);

        // add dealer
        protocol.addSupportingPaymentAddress(dealer);

        SafeProtocolAction[] memory actions = new SafeProtocolAction[](1);
        actions[0].value = 10;
        actions[0].to = payable(dealer);

        SafeTransaction memory tx = SafeTransaction({
            actions: actions,
            nonce: safe.nonce(),
            metadataHash: bytes32(0)
        });

        assertEq(protocol.getIssuedPoint(address(safe)), 0);

        ISafe addressSafe = ISafe(address(safe));
        vm.startPrank(owner);
        plugin.executeFromPlugin(manager, addressSafe, tx); 
        assertEq(protocol.getIssuedPoint(address(safe)), 1);

    }

    function testExecERC20() public {
        // subscribe wallet first
        bytes32 txHash = getTransactionHash(
            address(plugin),
            abi.encodeWithSignature(
                "subscribe(address)",
                address(safe)
            )
        );
        (uint8 v, bytes32 r, bytes32 s) = vm.sign(
            vm.envUint("SAFE_OWNER_PRIVATE_KEY"),
            txHash
        );
        sendSafeTx(
            address(plugin),
            abi.encodeWithSignature("subscribe(address)", address(safe)),
            abi.encodePacked(r, s, v)
        );

        assertEq(protocol.getExecutor(address(safe)), address(plugin));

        address dealer = makeAddr("ticket_dealier");
        emit log_named_address("ticket_dealier", dealer);

        mt.mint(address(safe), 100);

        // add dealer
        protocol.addSupportingPaymentAddress(dealer);

        SafeProtocolAction[] memory actions = new SafeProtocolAction[](1);
        actions[0].to = payable(address(mt));
        actions[0].data = abi.encodeWithSignature("transfer(address,uint256)", dealer, 10);

        SafeTransaction memory tx = SafeTransaction({
            actions: actions,
            nonce: safe.nonce(),
            metadataHash: bytes32(0)
        });

        assertEq(protocol.getIssuedPoint(address(safe)), 0);

        ISafe addressSafe = ISafe(address(safe));
        vm.startPrank(owner);
        plugin.executeFromPlugin(manager, addressSafe, tx); 
        assertEq(protocol.getIssuedPoint(address(safe)), 1);

    }
}
