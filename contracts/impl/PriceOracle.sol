// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "../model/IPriceOracle.sol";
import "@ethereans-labs/swissknife/contracts/generic/impl/LazyInitCapableElement.sol";
import "../model/IPriceOracleQuoter.sol";

interface IERC20 {
    function decimals() external view returns (uint256);
}

contract PriceOracle is IPriceOracle, LazyInitCapableElement {

    address private _quoterAddress;
    bytes private _quoterPayload;

    uint256 public setInterval;
    uint256 public minTimeIntervalTolerance;
    uint256 public limitPercDiff;

    uint256 public override lastSetBlock;
    uint256 public override lastSet;

    uint256 private _inputDecimals;
    uint256 private _outputDecimals;
    uint256 private _price;

    constructor(bytes memory lazyInitData) LazyInitCapableElement(lazyInitData) {
    }

    function _lazyInit(bytes memory lazyInitData) internal override returns (bytes memory) {
        uint256 delayedTimestamp;
        uint256 _setInterval;
        address quoterAddress;
        bytes memory quoterPayload;
        (
            quoterAddress,
            quoterPayload,
            _setInterval,
            minTimeIntervalTolerance,
            limitPercDiff,
            delayedTimestamp
        ) = abi.decode(lazyInitData, (address, bytes, uint256, uint256, uint256, uint256));

        setInterval = _setInterval;

        _setQuoter(quoterAddress, quoterPayload);

        if(delayedTimestamp != 0 && delayedTimestamp > _setInterval) {
            lastSet = delayedTimestamp - _setInterval;
        }

        return "";
    }

    function _supportsInterface(bytes4 interfaceId) internal override pure returns(bool) {
        return
            interfaceId == type(IPriceOracle).interfaceId ||
            interfaceId == this.price.selector||
            interfaceId == this.setPrice.selector ||
            interfaceId == this.quoter.selector||
            interfaceId == this.setQuoter.selector ||
            interfaceId == this.lastSetBlock.selector ||
            interfaceId == this.lastSet.selector ||
            interfaceId == this.nextSet.selector ||
            interfaceId == this.setInterval.selector ||
            interfaceId == this.setSetInterval.selector ||
            interfaceId == this.minTimeIntervalTolerance.selector ||
            interfaceId == this.setMinTimeIntervalTolerance.selector ||
            interfaceId == this.limitPercDiff.selector ||
            interfaceId == this.setLimitPercDiff.selector;
    }

    function price() external override view returns(uint256) {
        require(lastSetBlock != 0 && lastSetBlock < block.number, "Price not safe, wait at least a block."); 
        return _price;
    }

    function setPrice() external override {
        require(block.number > lastSetBlock && block.timestamp > nextSet(), "Too early to set a new safePrice.");

        uint256 oldLastSet = lastSet;

        lastSet = block.timestamp;
        lastSetBlock = block.number;

        (uint256 inputAmount, uint256 newPrice) = IPriceOracleQuoter(_quoterAddress).quote(_quoterPayload);

        newPrice = newPrice != 0 ? (newPrice * (10**(18-_outputDecimals))) : ((1e18*(10**_inputDecimals)) / inputAmount);

        uint256 oldPrice = _price;
        _price = newPrice;

        uint256 pricePercDiff = ((oldPrice > newPrice) ? (oldPrice - newPrice) : (newPrice - oldPrice)) * 1e18 / oldPrice;
        require((pricePercDiff < limitPercDiff) || (block.timestamp > oldLastSet + minTimeIntervalTolerance), "Price not safe, too different from the previous one."); 
    }

    function quoter() external override view returns (address quoterAddress, bytes memory quoterPayload) {
        return (_quoterAddress, _quoterPayload);
    }

    function setQuoter(address quoterAddress, bytes calldata quoterPayload) external override authorizedOnly {
        _setQuoter(quoterAddress, quoterPayload);
    }

    function nextSet() public override view returns (uint256) {
        return lastSet == 0 ? 0 : lastSet + setInterval;
    }

    function setSetInterval(uint256 _setInterval) external override authorizedOnly {
        setInterval = _setInterval;
    }

    function setMinTimeIntervalTolerance(uint256 _minTimeIntervalTolerance) external override authorizedOnly {
        minTimeIntervalTolerance = _minTimeIntervalTolerance;
    }

    function setLimitPercDiff(uint256 _limitPercDiff) external override authorizedOnly {
        limitPercDiff = _limitPercDiff;
    }

    function _setQuoter(address quoterAddress, bytes memory quoterPayload) private {
        _quoterAddress = quoterAddress;
        _quoterPayload = quoterPayload;
        _price = 0;
        lastSet = 0;
        lastSetBlock = 0;
        if(quoterAddress != address(0)) {
            (address inputAddress, address outputAddress) = IPriceOracleQuoter(quoterAddress).data(quoterPayload);
            _inputDecimals = IERC20(inputAddress).decimals();
            _outputDecimals = IERC20(outputAddress).decimals();
        }
    }}