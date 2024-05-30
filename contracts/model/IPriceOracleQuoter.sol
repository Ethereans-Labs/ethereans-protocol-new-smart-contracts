// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface IPriceOracleQuoter {
    function quote(bytes calldata quoterPayload) external view returns(uint256 inputAmount, uint256 outputAmount);
    function data(bytes calldata quoterPayload) external view returns(address inputAddress, address outputAddress);
}