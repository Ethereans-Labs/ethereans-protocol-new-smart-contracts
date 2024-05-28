// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface IQuoterComponent{
    function calculatePrice() external view returns(uint256 currentPrice); // Should return a 18
    function getPath() external view returns(address[] memory path);
    function getDecimals() external view returns(uint256 decimals);
}