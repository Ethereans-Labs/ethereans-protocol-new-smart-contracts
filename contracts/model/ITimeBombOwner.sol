// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@ethereans-labs/swissknife/contracts/generic/model/ILazyInitCapableElement.sol";

interface ITimeBombOwner is ILazyInitCapableElement {

    function timeBombOwner() external view returns (address);

    function setTimeBombOwner(address newValue) external returns(address oldValue);

    function submit(address location, bytes calldata payload, address restReceiver) external payable returns(bytes memory response);
}