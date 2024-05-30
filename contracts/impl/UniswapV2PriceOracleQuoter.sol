// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "../model/IPriceOracleQuoter.sol";

interface IERC20 {
    function decimals() external view returns (uint256);
}

interface IUniswapV2Router01 {
    function getAmountsOut(uint256 inputAmount, address[] calldata path) external view returns (uint256[] memory amounts);
    function getAmountsIn(uint256 outputAmount, address[] calldata path) external view returns (uint256[] memory amounts);
}


contract UniswapV2PriceOracleQuoter is IPriceOracleQuoter {

    address public immutable uniswapV2SwapRouterAddress;

    constructor(address _uniswapV2SwapRouterAddress) {
        uniswapV2SwapRouterAddress = _uniswapV2SwapRouterAddress;
    }

    function quote(bytes calldata quoterPayload) external override view returns(uint256 inputAmount, uint256 outputAmount) {
        address[] memory path = abi.decode(quoterPayload, (address[]));

        try IUniswapV2Router01(uniswapV2SwapRouterAddress).getAmountsOut(10**IERC20(path[0]).decimals(), path) returns(uint256[] memory amounts) {
            outputAmount = amounts[amounts.length - 1];
        } catch {}
        if(outputAmount == 0) {
            try IUniswapV2Router01(uniswapV2SwapRouterAddress).getAmountsIn(10**IERC20(path[path.length - 1]).decimals(), path) returns(uint256[] memory amounts) {
                inputAmount = amounts[0];
            } catch {}
        }
    }

    function data(bytes calldata quoterPayload) public override pure returns(address inputAddress, address outputAddress) {
        address[] memory path = abi.decode(quoterPayload, (address[]));
        inputAddress = path[0];
        outputAddress = path[path.length - 1];
    }
}