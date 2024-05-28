// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface ISwapperComponent{
    function swap(uint256 amount, bytes calldata extraPayload) external view returns(uint256 swappedAmount);
}