// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface IRefundableComponent{
    //TODO Do we need to set up generic parameters through a payload?
    function isRefundable(bytes4 selector) external view returns(bool);
}