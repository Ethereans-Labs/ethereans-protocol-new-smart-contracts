// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "https://github.com/EthereansOS/ethereansos-swissknife/contracts/generic/model/ILazyInitCapableElement.sol";

interface IReFunder is ILazyInitCapableElement {
    function callWithBenefit(address componentAddr, bytes calldata payload, address restReceiver) external payable returns(bytes memory response);
    
    function isRefundable(address componentAddr, bytes4 selector) external view returns(bool);
    
    function setRefundValue(uint256 _refundValue) external;
}