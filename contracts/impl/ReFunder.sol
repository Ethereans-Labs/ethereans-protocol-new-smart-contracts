// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "../model/IReFunder.sol";
import "../model/IRefundableComponent.sol";
import "https://github.com/EthereansOS/ethereansos-swissknife/contracts/generic/impl/LazyInitCapableElement.sol";
import { ReflectionUtilities } from "https://github.com/EthereansOS/ethereansos-swissknife/contracts/lib/GeneralUtilities.sol";
import "@openzeppelin/contracts/utils/introspection/IERC165.sol";

contract ReFunder is IReFunder, LazyInitCapableElement {
    using ReflectionUtilities for address;

    uint256 public refundValue; //wei   

    constructor(bytes memory lazyInitData) LazyInitCapableElement(lazyInitData) {
    }

    function _lazyInit(bytes memory lazyInitData) internal override returns (bytes memory) {
        (refundValue) = abi.decode(lazyInitData, (uint256));
        return "";
    }

    function _supportsInterface(bytes4 interfaceId) internal override pure returns(bool) {
        return
            interfaceId == type(IReFunder).interfaceId ||
            interfaceId == this.callWithBenefit.selector ||
            interfaceId == this.isRefundable.selector ||
            interfaceId == this.refundValue.selector ||
            interfaceId == this.setRefundValue.selector;
    }

    function callWithBenefit(address componentAddr, bytes calldata payload, address restReceiver) external payable returns(bytes memory response) {
        require(componentAddr != address(0),"Specify a valid address!");
        require(this.isRefundable(componentAddr, bytes4(payload[:4])), "Not refundable component");
        
        uint256 oldBalance = address(this).balance - msg.value;
        response = componentAddr.submit(msg.value, payload);
        uint256 actualBalance = address(this).balance;
        if(actualBalance > oldBalance) {
            (restReceiver != address(0) ? restReceiver : msg.sender).submit(address(this).balance - oldBalance, "");
        }

        //Refund
        (msg.sender).submit(refundValue, "");
    }
    
    function isRefundable(address componentAddr, bytes4 selector) public view returns(bool){
        require(IERC165(componentAddr).supportsInterface(IRefundableComponent.isRefundable.selector), "Refund not supported");
        return IRefundableComponent(componentAddr).isRefundable(selector);
    }

    function setRefundValue(uint256 _refundValue) external authorizedOnly{
        refundValue = _refundValue;
    }

    //Default behaviour to receive initial funds
    receive() external payable {}
    fallback() external payable {}

}