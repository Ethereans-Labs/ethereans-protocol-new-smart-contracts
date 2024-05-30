// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@ethereans-labs/swissknife/contracts/generic/model/ILazyInitCapableElement.sol";

interface IReFunder is ILazyInitCapableElement {

    function callWithBenefit(address componentAddr, bytes calldata payload, address restReceiver, address recipient, uint256 extraValue) external payable returns(bytes memory response);
    function setRefundPercentage(uint256 _refundPercentage) external;
}