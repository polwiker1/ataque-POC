// SPDX-License-Identifier: MIT
pragma solidity 0.8.24;

contract DelegateLib {
    // Keep slot alignment with proxy
    address public owner;
    address public implementation;
    uint256 public value;

    function setValue(uint256 _value) external {
        value = _value;
    }
}
