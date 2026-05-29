// SPDX-License-Identifier: MIT
pragma solidity 0.8.24;

contract DelegatecallProxyVulnerable {
    // Slot 0
    address public owner;
    // Slot 1
    address public implementation;
    // Slot 2
    uint256 public value;

    constructor(address _implementation) {
        owner = msg.sender;
        implementation = _implementation;
    }

    // Vulnerable: anyone can change implementation
    function setImplementation(address _implementation) external {
        implementation = _implementation;
    }

    // Vulnerable: delegatecall to user-controlled implementation
    function executeSetValue(uint256 _value) external {
        (bool ok,) = implementation.delegatecall(
            abi.encodeWithSignature("setValue(uint256)", _value)
        );
        require(ok, "delegatecall failed");
    }
}
