// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "../model/ITimeBombOwner.sol";
import "@ethereans-labs/swissknife/contracts/generic/impl/LazyInitCapableElement.sol";
import { ReflectionUtilities } from "@ethereans-labs/swissknife/contracts/lib/GeneralUtilities.sol";

contract TimeBombOwner is ITimeBombOwner, LazyInitCapableElement {
    using ReflectionUtilities for address;

    address public override timeBombOwner;

    constructor(bytes memory lazyInitData) LazyInitCapableElement(lazyInitData) {
    }

    function _lazyInit(bytes memory lazyInitData) internal override returns (bytes memory) {
        timeBombOwner = abi.decode(lazyInitData, (address));
        return "";
    }

    function _supportsInterface(bytes4 interfaceId) internal override pure returns(bool) {
    }

    modifier onlyTimeBombOwner {
        require(msg.sender == timeBombOwner, "unauthorized");
        _;
    }

    function setTimeBombOwner(address newValue) override onlyTimeBombOwner external returns(address oldValue) {
        oldValue = timeBombOwner;
        timeBombOwner = newValue;
    }

    function submit(address location, bytes calldata payload, address restReceiver) override onlyTimeBombOwner external payable returns(bytes memory response) {
        uint256 oldBalance = address(this).balance - msg.value;
        response = location.submit(msg.value, payload);
        uint256 actualBalance = address(this).balance;
        if(actualBalance > oldBalance) {
            (restReceiver != address(0) ? restReceiver : msg.sender).submit(address(this).balance - oldBalance, "");
        }
    }
}