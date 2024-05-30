// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface IRefundableComponent {
    function isRefundable(address subject, address location, bytes4 selector, bytes calldata payload, uint256 value) external view returns(bool);
}