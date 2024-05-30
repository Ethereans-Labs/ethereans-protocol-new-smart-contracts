// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "../model/IReFunder.sol";
import "../model/IRefundableComponent.sol";
import "@ethereans-labs/swissknife/contracts/generic/impl/LazyInitCapableElement.sol";
import { ReflectionUtilities } from "@ethereans-labs/swissknife/contracts/lib/GeneralUtilities.sol";
import "@openzeppelin/contracts/utils/introspection/IERC165.sol";

contract ReFunder is IReFunder, LazyInitCapableElement {
    using ReflectionUtilities for address;

    uint256 public refundPercentage; //18 decimals percentage
    uint256 public constant FULL_PRECISION = 1e18;

    constructor(bytes memory lazyInitData) LazyInitCapableElement(lazyInitData) {
    }

    function _lazyInit(bytes memory lazyInitData) internal override returns (bytes memory) {
        (refundPercentage) = abi.decode(lazyInitData, (uint256));
        return "";
    }

    function _supportsInterface(bytes4 interfaceId) internal override pure returns(bool) {
        return
            interfaceId == type(IReFunder).interfaceId ||
            interfaceId == this.callWithBenefit.selector ||
            interfaceId == this.refundPercentage.selector ||
            interfaceId == this.setRefundPercentage.selector;
    }

    function callWithBenefit(address componentAddr, bytes calldata payload, address restReceiver, address refundRecipient, uint256 extraValue) external payable returns(bytes memory response) {
        uint256 usedGas = gasleft();
        
        require(componentAddr != address(0),"Specify a valid address!");
        require(IRefundableComponent(componentAddr).isRefundable(msg.sender, componentAddr, bytes4(payload[:4]), payload, extraValue), "Not refundable component.");  
        
        //Call to the refunding method
        uint256 oldBalance = address(this).balance - msg.value;
        response = componentAddr.submit(msg.value, payload);
        uint256 actualBalance = address(this).balance;
        if(actualBalance > oldBalance) {
            (restReceiver != address(0) ? restReceiver : msg.sender).submit(address(this).balance - oldBalance, "");
        }

        //Calculate gas used and refund value
        usedGas -= gasleft();
        uint256 refundValue = _calculatePercentage(usedGas * tx.gasprice, refundPercentage + 1e18);

        //Refund
        (refundRecipient).submit(refundValue, "");
    }

    function setRefundPercentage(uint256 _refundPercentage) external authorizedOnly{
        refundPercentage = _refundPercentage;
    }

    function _calculatePercentage(uint256 total, uint256 percentage) internal pure returns (uint256) {
        return (total * ((percentage * 1e18) / FULL_PRECISION)) / 1e18;
    }

    //Default behaviour to receive initial funds
    receive() external payable {}

}