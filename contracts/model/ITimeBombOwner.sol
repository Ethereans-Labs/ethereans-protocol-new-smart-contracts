// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@ethereans-labs/swissknife/contracts/generic/model/ILazyInitCapableElement.sol";

interface ITimeBombOwner is ILazyInitCapableElement {
    
    event TimeBombOwnershipTransferred(address indexed oldTimeBombOwner, address indexed newTimeBombOwner);
    event TimeBombOwnershipExtended(uint256 indexed extendedSeconds,uint256 indexed extentionNumber, uint256 indexed newEndTime);

    function timeBombOwner() external view returns (address);
    function setTimeBombOwner(address _timeBombOwner) external returns(address oldTimeBombOwner);
    function submit(address location, bytes calldata payload, address restReceiver) external payable returns(bytes memory response);
    function disableComponent() external;
    function disableComponentOwner() external;
}