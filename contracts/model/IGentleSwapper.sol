// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@ethereans-labs/swissknife/contracts/generic/model/ILazyInitCapableElement.sol";
import "../model/IRefundableComponent.sol";

interface IGentleSwapper is ILazyInitCapableElement, IRefundableComponent {
    function submit(address location, bytes calldata payload, address restReceiver) external payable returns(bytes memory response);
    function gentleSwap(uint256 gentleSwapValue, bytes32 stableToTokenOracleKey, bytes calldata extraPayload) external returns(uint256);
    function setSwapSettings( address _gentleSwapReceiver, address _tokenToWETHOracle, address _swapLocation) external;
    function setGentleTolerance(uint256 _gentleTolerance) external; 
    function setRefundableThreshold(uint256 _refundableThreshold) external;
}