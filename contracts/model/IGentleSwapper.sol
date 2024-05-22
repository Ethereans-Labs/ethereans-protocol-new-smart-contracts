// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "https://github.com/EthereansOS/ethereansos-swissknife/contracts/generic/model/ILazyInitCapableElement.sol";
import "../model/IRefundableComponent.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "../model/IOracle.sol";

interface IGentleSwapper is ILazyInitCapableElement {
    function submit(address location, bytes calldata payload, address restReceiver) external payable returns(bytes memory response);
    function gentleSwap() external payable;
    function setSwapSettings(address _tokenToSwap, address _tokenToReceive, address _swapLocation, bytes calldata _swapPayload) external;
    function setGentleTolerance(uint256 _gentleTolerance) external;
    function setRefoundableThreshold(uint256 _refoundableThreshold) external;
}