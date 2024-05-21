// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "../model/ITimeBombOwner.sol";
import "https://github.com/EthereansOS/ethereansos-swissknife/contracts/generic/impl/LazyInitCapableElement.sol";
import { ReflectionUtilities } from "https://github.com/EthereansOS/ethereansos-swissknife/contracts/lib/GeneralUtilities.sol";
import "https://github.com/EthereansOS/ETHComputationalOrgs/blob/main/contracts/core/model/IOrganization.sol";


contract TimeBombOwner is ITimeBombOwner, LazyInitCapableElement {
    using ReflectionUtilities for address;

    bytes32 public componentKey;

    address public timeBombOwner;
    uint256 public initialTime;
    uint256 public ownershipDuration;

    uint256 public extensions = 0;

    uint256 public maxExtensions;
    uint256 public maxExtensionTime;

    constructor(bytes memory lazyInitData) LazyInitCapableElement(lazyInitData) {
    }

    function _lazyInit(bytes memory lazyInitData) internal override returns (bytes memory) {
        (componentKey, timeBombOwner, ownershipDuration, maxExtensions, maxExtensionTime) = abi.decode(lazyInitData, (bytes32, address, uint256, uint256, uint256));
        
        initialTime = block.timestamp;
        return "";
    }

    function _supportsInterface(bytes4 interfaceId) internal override pure returns(bool) {
        return
            interfaceId == type(ITimeBombOwner).interfaceId ||
            interfaceId == this.setTimeBombOwner.selector ||
            interfaceId == this.extendTimeBombOwnership.selector ||
            interfaceId == this.submit.selector ||
            interfaceId == this.disableComponent.selector ||
            interfaceId == this.disableComponentOwner.selector ||
            interfaceId == this.endTime.selector ||
            interfaceId == this.componentKey.selector ||
            interfaceId == this.timeBombOwner.selector ||
            interfaceId == this.initialTime.selector ||
            interfaceId == this.ownershipDuration.selector||
            interfaceId == this.extensions.selector ||
            interfaceId == this.maxExtensions.selector ||
            interfaceId == this.maxExtensionTime.selector;
    }

    function setTimeBombOwner(address _timeBombOwner) override onlyTimeBombOwner withinEndTime public returns(address oldTimeBombOwner) {
        oldTimeBombOwner = timeBombOwner;
        timeBombOwner = _timeBombOwner;

        emit TimeBombOwnershipTransferred(oldTimeBombOwner, _timeBombOwner);
    }

    function extendTimeBombOwnership(uint256 extendSeconds) onlyTimeBombOwner withinEndTime public returns(uint256){
        require(extensions<maxExtensions, "You have run out of available extensions");
        require(extendSeconds<=maxExtensionTime, "You want to extend the deadline too much");

        extensions ++;
        ownershipDuration+=extendSeconds;

        uint256 end = endTime();

        emit TimeBombOwnershipExtended(extendSeconds, extensions, end);

        return end;
    }

    function disableComponent() external endTimeExpired{
        _disableComponent();
    }

    function disableComponentOwner() external onlyOwner withinEndTime{
        _disableComponent();
    }

    function _disableComponent() internal{
        IOrganization(owner).set(IOrganization.Component(componentKey, address(0), false, true));
    }
    
    function submit(address location, bytes calldata payload, address restReceiver) override onlyTimeBombOwner withinEndTime external payable returns(bytes memory response) {
        uint256 oldBalance = address(this).balance - msg.value;
        response = location.submit(msg.value, payload);
        uint256 actualBalance = address(this).balance;
        if(actualBalance > oldBalance) {
            (restReceiver != address(0) ? restReceiver : msg.sender).submit(address(this).balance - oldBalance, "");
        }
    }

    function endTime() public view returns(uint256){
        return initialTime + ownershipDuration;
    }

    modifier onlyTimeBombOwner {
        require(msg.sender == timeBombOwner, "You are not the TimeBombOwner");
        _;
    }

    modifier withinEndTime {
        require(block.timestamp < endTime(), "Time expired");
        _;
    }

    modifier endTimeExpired {
        require(block.timestamp > endTime(), "Too early");
        _;
    }
}