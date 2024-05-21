// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "../model/IOracle.sol";
import "https://github.com/EthereansOS/ethereansos-swissknife/contracts/generic/impl/LazyInitCapableElement.sol";
import { ReflectionUtilities } from "https://github.com/EthereansOS/ethereansos-swissknife/contracts/lib/GeneralUtilities.sol";

contract Oracle is IOracle, LazyInitCapableElement {
    using ReflectionUtilities for address;

    address public compPriceContract;
    address public referenceToken0;
    address public referenceToken1;

    bytes private compPriceFunctionPayload;

    uint256[2] private lastSafePrices;
    uint256 public lastSetBlock;

    uint256 public minSetInterval;
    uint256 public refundableInterval;
    uint256 public limitPercDiff; //Basis points
    
    constructor(bytes memory lazyInitData) LazyInitCapableElement(lazyInitData) {
    }

    function _lazyInit(bytes memory lazyInitData) internal override returns (bytes memory) {
        (minSetInterval, refundableInterval, limitPercDiff, compPriceContract, referenceToken0, referenceToken1, compPriceFunctionPayload) = abi.decode(lazyInitData, (uint256, uint256, uint256, address, address, address, bytes));

        lastSetBlock = block.number;
        uint256 price = calculatePrice();

        lastSafePrices[0] = price;
        lastSafePrices[1] = price;

        return "";
    }

    function _supportsInterface(bytes4 interfaceId) internal override pure returns(bool) {
        return
            interfaceId == type(IOracle).interfaceId ||
            interfaceId == type(IRefundableComponent).interfaceId ||
            interfaceId == this.readSafePrice.selector||
            interfaceId == this.setPrice.selector ||
            interfaceId == this.setMinSetInterval.selector ||
            interfaceId == this.setRefundableInterval.selector ||
            interfaceId == this.setLimitPercDiff.selector ||
            interfaceId == this.setPriceContract.selector;
    }
    
    function submit(address location, bytes calldata payload, address restReceiver) override external payable returns(bytes memory response) {
        uint256 oldBalance = address(this).balance - msg.value;
        response = location.submit(msg.value, payload);
        uint256 actualBalance = address(this).balance;
        if(actualBalance > oldBalance) {
            (restReceiver != address(0) ? restReceiver : msg.sender).submit(address(this).balance - oldBalance, "");
        }
    }

    function calculatePrice() internal view returns (uint256){

        (bool success, bytes memory returnData) = compPriceContract.staticcall(compPriceFunctionPayload);

        require(success, "Price read from reference contract FAILED.");

        return abi.decode(returnData, (uint256));
    }

    function readSafePrice() public view returns(uint256){
        require(lastSetBlock < block.number, "Price not safe, wait at least a block."); 
        require(block.number < lastSetBlock + refundableInterval, "Price not safe, too old.");
        
        uint256 pricePercDiff = ((lastSafePrices[0] > lastSafePrices[1]) ? (lastSafePrices[0] - lastSafePrices[1]) : (lastSafePrices[1] - lastSafePrices[0]))/lastSafePrices[1]*10000;  //Basis points
        require(pricePercDiff > limitPercDiff, "Price not safe, too different from the previous one."); 
        
        return lastSafePrices[1];
    }

    function setPrice() external{
        require(block.number >= lastSetBlock + minSetInterval, "Too early to set a new safePrice.");

        lastSafePrices[0] = lastSafePrices[1];
        lastSafePrices[1] = calculatePrice();

        lastSetBlock = block.number;
    }

    function isRefundable(bytes4 selector) external view returns(bool){
        if(selector == this.setPrice.selector)
            return block.number >= lastSetBlock + refundableInterval;
        return false;
    }

    function setMinSetInterval(uint256 _minSetInterval) external authorizedOnly{
        minSetInterval = _minSetInterval;
    }

    function setRefundableInterval(uint256 _refundableInterval) external authorizedOnly{
        refundableInterval = _refundableInterval;
    }

    function setLimitPercDiff(uint256 _limitPercDiff) external authorizedOnly{
        limitPercDiff = _limitPercDiff;
    }

    function setPriceContract(address _compPriceContract, address _referenceToken0, address _referenceToken1, bytes calldata _compPriceFunctionPayload) external authorizedOnly{
        if(_compPriceContract != address(0) && _referenceToken0 != address(0) && _referenceToken1 != address(0)){
            compPriceContract = _compPriceContract;
            referenceToken0 = _referenceToken0;
            referenceToken1 = _referenceToken1;
        }

        if(_compPriceFunctionPayload.length > 0)
            compPriceFunctionPayload = _compPriceFunctionPayload;
    }

}