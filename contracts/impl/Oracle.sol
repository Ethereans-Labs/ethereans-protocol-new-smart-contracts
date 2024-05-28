// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "../model/IOracle.sol";
import "../model/IQuoterComponent.sol";
import "https://github.com/EthereansOS/ethereansos-swissknife/contracts/generic/impl/LazyInitCapableElement.sol";
import { ReflectionUtilities } from "https://github.com/EthereansOS/ethereansos-swissknife/contracts/lib/GeneralUtilities.sol";

contract Oracle is IOracle, LazyInitCapableElement {
    using ReflectionUtilities for address;

    address public compPriceContract;

    uint256 public activationTimestamp;

    uint256 private lastSafePrice;
    uint256 public lastSetBlock;
    uint256 public lastSetTimestamp;

    uint256 public minSetInterval;
    uint256 public refundableInterval;
    uint256 public minTimeIntervalTollerance;
    uint256 public limitPercDiff; // 18 Decimals
    
    constructor(bytes memory lazyInitData) LazyInitCapableElement(lazyInitData) {
    }

    function _lazyInit(bytes memory lazyInitData) internal override returns (bytes memory) {
        (
            minSetInterval,
            refundableInterval,
            minTimeIntervalTollerance, 
            limitPercDiff,
            compPriceContract,
            activationTimestamp
        ) = abi.decode(lazyInitData, (uint256, uint256, uint256, uint256, address, uint256));

        lastSetBlock = block.number;
        lastSetTimestamp = block.timestamp;

        lastSafePrice = IQuoterComponent(compPriceContract).calculatePrice();

        return "";
    }

    function _supportsInterface(bytes4 interfaceId) internal override pure returns(bool) {
        return
            interfaceId == type(IOracle).interfaceId ||
            interfaceId == type(IRefundableComponent).interfaceId ||
            interfaceId == this.submit.selector ||
            interfaceId == this.readSafePrice.selector||
            interfaceId == this.setPrice.selector ||
            interfaceId == this.getNextRefundableBlock.selector ||
            interfaceId == this.getNextSetBlock.selector ||
            interfaceId == this.setMinSetInterval.selector ||
            interfaceId == this.setRefundableInterval.selector ||
            interfaceId == this.setMinTimeIntervalTollerance.selector ||
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

    function readSafePrice() public view returns(uint256){
        require(lastSetBlock < block.number, "Price not safe, wait at least a block."); 
        require(block.number < lastSetBlock + refundableInterval, "Price not safe, too old.");
        
        return lastSafePrice;
    }

    function setPrice() external{
        require(block.number >= lastSetBlock + minSetInterval, "Too early to set a new safePrice.");

        uint256 currentPrice = IQuoterComponent(compPriceContract).calculatePrice();

        uint256 pricePercDiff = ((lastSafePrice > currentPrice) ? (lastSafePrice - currentPrice) : (currentPrice - lastSafePrice))*1e18/lastSafePrice;
        require((pricePercDiff < limitPercDiff) || (block.timestamp > lastSetTimestamp + minTimeIntervalTollerance), "Price not safe, too different from the previous one."); 
       
        lastSafePrice = currentPrice;

        lastSetBlock = block.number;
        lastSetTimestamp = block.timestamp;
    }

    function isRefundable(address subject, address location, bytes4 selector, bytes calldata, uint256) external view override returns(bool){
        if(selector == this.setPrice.selector)
            return block.number >= lastSetBlock + refundableInterval;
        return false;
    }

    function getNextRefundableBlock() external view returns (uint256){
        return lastSetBlock + refundableInterval;
    }

    function getNextSetBlock() external view returns (uint256){
        return lastSetBlock + minSetInterval;
    }

    function setMinSetInterval(uint256 _minSetInterval) external authorizedOnly{
        minSetInterval = _minSetInterval;
    }

    function setRefundableInterval(uint256 _refundableInterval) external authorizedOnly{
        refundableInterval = _refundableInterval;
    }

    function setMinTimeIntervalTollerance(uint256 _minTimeIntervalTollerance) external authorizedOnly{
        minTimeIntervalTollerance = _minTimeIntervalTollerance;
    }

    function setLimitPercDiff(uint256 _limitPercDiff) external authorizedOnly{
        limitPercDiff = _limitPercDiff;
    }

    function setPriceContract(address _compPriceContract) external authorizedOnly{
        compPriceContract = _compPriceContract;
    }

    modifier active {
        require(block.timestamp > activationTimestamp, "The Oracle is not active yet.");
        _;
    }

}