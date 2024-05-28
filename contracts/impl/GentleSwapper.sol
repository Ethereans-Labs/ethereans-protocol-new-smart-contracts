// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "../model/IGentleSwapper.sol";
import "../model/IQuoterComponent.sol";
import "../model/ISwapperComponent.sol";
import ".deps/github/EthereansOS/ETHComputationalOrgs/contracts/core/model/IOrganization.sol";
import "../impl/Oracle.sol";
import "https://github.com/EthereansOS/ethereansos-swissknife/contracts/generic/impl/LazyInitCapableElement.sol";
import { ReflectionUtilities } from "https://github.com/EthereansOS/ethereansos-swissknife/contracts/lib/GeneralUtilities.sol";
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";


contract GentleSwapper is IGentleSwapper, LazyInitCapableElement {
    using ReflectionUtilities for address;

    uint256 public gentleTolerance; //18 decimals
    uint256 public refundableThreshold;

    address public gentleSwapReceiver;

    address public swapper; 

    address public tokenToWETHOracle;

    constructor(bytes memory lazyInitData) LazyInitCapableElement(lazyInitData) {
    }

    function _lazyInit(bytes memory lazyInitData) internal override returns (bytes memory) {
        (
         gentleTolerance,
         refundableThreshold,
         gentleSwapReceiver,
         swapper,
         tokenToWETHOracle
        ) = abi.decode(lazyInitData, (uint256, uint256, address, address, address));
        return "";
    }

    function _supportsInterface(bytes4 interfaceId) internal override pure returns(bool) {
        return
            interfaceId == type(IGentleSwapper).interfaceId ||
            interfaceId == type(IRefundableComponent).interfaceId ||
            interfaceId == this.submit.selector ||
            interfaceId == this.gentleSwap.selector ||
            interfaceId == this.setSwapSettings.selector ||
            interfaceId == this.setGentleTolerance.selector ||
            interfaceId == this.setRefundableThreshold.selector;
    }
    
    function submit(address location, bytes calldata payload, address restReceiver) override external payable returns(bytes memory response) {
        uint256 oldBalance = address(this).balance - msg.value;
        response = location.submit(msg.value, payload);
        uint256 actualBalance = address(this).balance;
        if(actualBalance > oldBalance) {
            (restReceiver != address(0) ? restReceiver : msg.sender).submit(address(this).balance - oldBalance, "");
        }
    }

    function gentleSwap(uint256 gentleSwapValue, bytes32 stableToTokenOracleKey, bytes calldata extraPayload) external returns(uint256){ 
        
        address stableToTokenOracle = IOrganization(this.owner()).get(stableToTokenOracleKey);
        uint256 stableToTokenSafePrice = Oracle(stableToTokenOracle).readSafePrice();
        uint256 valueToSwap =  stableToTokenSafePrice * gentleSwapValue;

        address[] memory path = IQuoterComponent(Oracle(tokenToWETHOracle).compPriceContract()).getPath();
        address tokenToSwap = path[0];
        address tokenToReceive = path[path.length-1];

        uint256 swapPrice;
        uint256 tokenToSwapSwapped;
        {
            uint256 oldTokenToSwapBalance = ERC20(tokenToSwap).balanceOf(address(this));
            uint256 oldTokenToReceiveBalance = ERC20(tokenToReceive).balanceOf(gentleSwapReceiver);

            //The approve method will be executed in the SwapperComponent
            //require(ERC20(tokenToSwap).approve(address(swapper), valueToSwap), "approve failed.");
            ISwapperComponent(swapper).swap(valueToSwap, extraPayload);

            uint256 newTokenToSwapBalance = ERC20(tokenToSwap).balanceOf(address(this));
            uint256 newTokenToReceiveBalance = ERC20(tokenToReceive).balanceOf(gentleSwapReceiver);

            tokenToSwapSwapped = (newTokenToSwapBalance > oldTokenToSwapBalance) ? (newTokenToSwapBalance - oldTokenToSwapBalance) :  (oldTokenToSwapBalance - newTokenToSwapBalance);
            uint256 tokenToReceiveSwapped = (newTokenToReceiveBalance > oldTokenToReceiveBalance) ? (newTokenToReceiveBalance - oldTokenToReceiveBalance) :  (oldTokenToReceiveBalance - newTokenToReceiveBalance);

            uint256 tokenToSwapDecimals = ERC20(tokenToSwap).decimals();
            uint256 tokenToReceiveDecimals = ERC20(tokenToReceive).decimals();

            if(tokenToSwapDecimals >= tokenToReceiveDecimals)
                tokenToReceiveSwapped *= 10**(tokenToSwapDecimals-tokenToReceiveDecimals);
            else
                tokenToSwapSwapped *= 10**(tokenToReceiveDecimals-tokenToSwapDecimals);
            
            swapPrice = (tokenToReceiveSwapped * (1e18)) / tokenToSwapSwapped;
        }

        uint256 safePrice = Oracle(tokenToWETHOracle).readSafePrice(); 

        uint256 pricePercDiff = ((safePrice > swapPrice) ? (safePrice - swapPrice) : (swapPrice - safePrice)) * 1e18 / safePrice; // 18 decimals
        require(pricePercDiff < gentleTolerance, "Not gentle swap, price impact too high.");

        return (1e18 * tokenToSwapSwapped) / stableToTokenSafePrice;
    }

    function isRefundable(address subject, address location, bytes4 selector, bytes calldata payload, uint256) external view override returns(bool){
        if(selector == this.gentleSwap.selector){
            bytes32 stableToTokenOracleKey = abi.decode(payload, (bytes32));
            return ERC20(IQuoterComponent(Oracle(IOrganization(this.owner()).get(stableToTokenOracleKey)).compPriceContract()).getPath()[0]).balanceOf(address(this)) >= refundableThreshold;
        }
        return false;
    }

    function setSwapSettings( address _gentleSwapReceiver, address _tokenToWETHOracle, address _swapper) external authorizedOnly{
        gentleSwapReceiver = _gentleSwapReceiver;
        tokenToWETHOracle = _tokenToWETHOracle;
        swapper = _swapper;
    }

    function setGentleTolerance(uint256 _gentleTolerance) external authorizedOnly{
        gentleTolerance = _gentleTolerance;
    }

    function setRefundableThreshold(uint256 _refundableThreshold) external authorizedOnly{
        refundableThreshold = _refundableThreshold;
    }

}