// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@ethereans-labs/swissknife/contracts/generic/model/ILazyInitCapableElement.sol";

interface IPriceOracle is ILazyInitCapableElement {

    function price() external view returns(uint256);

    function setPrice() external;

    function quoter() external view returns (address quoterAddress, bytes memory quoterPayload);

    function setQuoter(address quoterAddress, bytes calldata quoterPayload) external;

    function lastSetBlock() external view returns (uint256);

    function lastSet() external view returns (uint256);

    function nextSet() external view returns (uint256);
    
    function setInterval() external view returns (uint256);
    function setSetInterval(uint256 _setInterval) external;

    function minTimeIntervalTolerance() external view returns (uint256);
    function setMinTimeIntervalTolerance(uint256 _minTimeIntervalTolerance) external;

    function limitPercDiff() external view returns (uint256);
    function setLimitPercDiff(uint256 _limitPercDiff) external;
}