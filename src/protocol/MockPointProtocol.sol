// SPDX-License-Identifier: MIT
pragma solidity 0.8.20;

import {IWagerBoxProtocol} from "./WagerBoxProtocol.sol";

import { console2 } from "lib/forge-std/src/console2.sol";

contract MockPointProtocol is IWagerBoxProtocol {

    mapping(address => uint256) public pointBalance;        // replace this point with ERC721

    mapping(address => address) public executors;
    mapping(address => bool) public subscribedWallets;
    mapping(address => bool) public supportingPaymentAddresses;

    uint256 internal pointParcentage = 90;

    function subscribe(address wallet) public {
        executors[wallet] = msg.sender;
        pointBalance[wallet] = 0;
        subscribedWallets[wallet] = true;
        console2.log("subscribed wallet: %s", wallet);
        console2.log("executor: %s", msg.sender);
    }

    function isSupportingPaymentAddress(address to) public view returns (bool) {
        return supportingPaymentAddresses[to];
    }

    function issuePoint(
        address wallet,
        address token,
        uint256 paidValue
    ) public returns (bool) {
        // some logics - based on token/paidValue, etc
        require(executors[msg.sender] != wallet, "executor is not set");
        require(subscribedWallets[wallet], "wallet has not subscribed");

        uint256 earnedPoint = (paidValue * (100 - pointParcentage)) / 100; 
        pointBalance[wallet] += earnedPoint;
    }

    function addSupportingPaymentAddress(address to) public {
       supportingPaymentAddresses[to] = true;
    }

    ///---- debug functions

    function getExecutor(address wallet) public view returns (address) {
        return executors[wallet];
    }

    function getIssuedPoint(address wallet) public view returns (uint256) {
        return pointBalance[wallet];
    }

}
