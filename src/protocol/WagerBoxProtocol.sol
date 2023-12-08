// SPDX-License-Identifier: MIT
pragma solidity 0.8.20;

interface IWagerBoxProtocol {

    function subscribe(address wallet) external;

    function isSupportingPaymentAddress(address to) external returns (bool);

    function issuePoint(address wallet, address token, uint256 paidValue) external returns (bool);


}