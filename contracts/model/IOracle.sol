// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "https://github.com/EthereansOS/ethereansos-swissknife/contracts/generic/model/ILazyInitCapableElement.sol";
import "../model/IRefundableComponent.sol";
import "@uniswap/v2-core/contracts/interfaces/IUniswapV2Pair.sol";

interface IOracle is ILazyInitCapableElement {
    function submit(address location, bytes calldata payload, address restReceiver) external payable returns(bytes memory response);
    
    function readSafePrice() external view returns(uint256);
    
    function setPrice() external;
    
    function setMinSetInterval(uint256 _minSetInterval) external;
    
    function setRefundableInterval(uint256 _refundableInterval) external;
    
    function setLimitPercDiff(uint256 _limitPercDiff) external;
    
    function setPriceContract(address _compPriceContract, address _referenceToken0, address _referenceToken1, bytes calldata _compPriceFunctionPayload) external;
}