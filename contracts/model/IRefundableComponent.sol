// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface IRefundableComponent{
    function isRefundable(address subject, address location, bytes4 selector, bytes calldata, uint256) external view returns(bool);
}