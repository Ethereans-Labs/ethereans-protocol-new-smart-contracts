// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "../model/IGentleSwapper.sol";
import "../impl/Oracle.sol";
import "https://github.com/EthereansOS/ethereansos-swissknife/contracts/generic/impl/LazyInitCapableElement.sol";
import { ReflectionUtilities } from "https://github.com/EthereansOS/ethereansos-swissknife/contracts/lib/GeneralUtilities.sol";
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";


contract GentleSwapper is IGentleSwapper, LazyInitCapableElement {
    using ReflectionUtilities for address;

    address public tokenToSwap;
    address public tokenToReceive;

    address public oracle;

    address public swapLocation;
    bytes public swapPayload;

    uint256 public gentleTolerance; //Basis points

    uint256 public refoundableThreshold;

    constructor(bytes memory lazyInitData) LazyInitCapableElement(lazyInitData) {
    }

    function _lazyInit(bytes memory lazyInitData) internal override returns (bytes memory) {
        (gentleTolerance, refoundableThreshold, tokenToSwap, tokenToReceive, oracle, swapLocation, swapPayload) = abi.decode(lazyInitData, (uint256, uint256, address, address, address, address, bytes));
        return "";
    }

    function _supportsInterface(bytes4 interfaceId) internal override pure returns(bool) {
        return
            interfaceId == type(IGentleSwapper).interfaceId ||
            interfaceId == type(IRefundableComponent).interfaceId ||
            interfaceId == this.gentleSwap.selector ||
            interfaceId == this.setSwapSettings.selector ||
            interfaceId == this.setGentleTolerance.selector ||
            interfaceId == this.setRefoundableThreshold.selector;
    }
    
    function submit(address location, bytes calldata payload, address restReceiver) override external payable returns(bytes memory response) {
        uint256 oldBalance = address(this).balance - msg.value;
        response = location.submit(msg.value, payload);
        uint256 actualBalance = address(this).balance;
        if(actualBalance > oldBalance) {
            (restReceiver != address(0) ? restReceiver : msg.sender).submit(address(this).balance - oldBalance, "");
        }
    }

    function gentleSwap() external payable{
        
        uint256 oldTokenToSwapBalance = IERC20(tokenToSwap).balanceOf(address(this));
        uint256 oldTokenToReceiveBalance = IERC20(tokenToReceive).balanceOf(address(this));

        uint256 safePrice = IOracle(oracle).readSafePrice();

        require(IERC20(tokenToSwap).approve(address(swapLocation), 4*(10**6)), "approve failed.");
        
        (bool success, bytes memory returnData) = swapLocation.call{value:msg.value}(swapPayload);
        require(success, "Swap FAILED.");

        uint256 newTokenToSwapBalance = IERC20(tokenToSwap).balanceOf(address(this));
        uint256 newTokenToReceiveBalance = IERC20(tokenToReceive).balanceOf(address(this));

        uint256 tokenToSwapSwapped = (newTokenToSwapBalance > oldTokenToSwapBalance) ? (newTokenToSwapBalance - oldTokenToSwapBalance) :  (oldTokenToSwapBalance - newTokenToSwapBalance);
        uint256 tokenToReceiveSwapped = (newTokenToReceiveBalance > oldTokenToReceiveBalance) ? (newTokenToReceiveBalance - oldTokenToReceiveBalance) :  (oldTokenToReceiveBalance - newTokenToReceiveBalance);

        uint256 tokenToSwapDecimals = ERC20(tokenToSwap).decimals();
        uint256 tokenToReceiveDecimals = ERC20(tokenToReceive).decimals();

        if(tokenToSwapDecimals>=tokenToReceiveDecimals)
            tokenToReceiveSwapped *= 10**(tokenToSwapDecimals-tokenToReceiveDecimals);
        else
            tokenToSwapSwapped *= 10**(tokenToReceiveDecimals-tokenToSwapDecimals);
        

        uint256 swapPrice;
        if(Oracle(oracle).referenceToken0() == tokenToSwap)
            swapPrice = (tokenToReceiveSwapped * (10**18)) / tokenToSwapSwapped;
        else
            swapPrice = (tokenToSwapSwapped * (10**18)) / tokenToReceiveSwapped;

        uint256 pricePercDiff = ((safePrice>swapPrice) ? (safePrice-swapPrice) : (swapPrice-safePrice))*10000/safePrice; //Basis points
        require(pricePercDiff<gentleTolerance, "Not gentle swap, price impact too high.");

    }

    function isRefundable(bytes4 selector) external view returns(bool){
        if(selector == this.gentleSwap.selector)
            return IERC20(tokenToSwap).balanceOf(address(this)) >= refoundableThreshold;
        return false;
    }

    function setSwapSettings(address _tokenToSwap, address _tokenToReceive, address _swapLocation, bytes calldata _swapPayload) external authorizedOnly{
        tokenToSwap = _tokenToSwap;
        tokenToReceive = _tokenToReceive;
        swapLocation = _swapLocation;
        swapPayload = _swapPayload;
    }

    function setGentleTolerance(uint256 _gentleTolerance) external authorizedOnly{
        gentleTolerance = _gentleTolerance;
    }

    function setRefoundableThreshold(uint256 _refoundableThreshold) external authorizedOnly{
        refoundableThreshold = _refoundableThreshold;
    }

}