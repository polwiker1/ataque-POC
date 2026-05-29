// SPDX-License-Identifier: MIT
pragma solidity 0.8.24;

import {ReentrancyGuard} from "openzeppelin-contracts/contracts/utils/ReentrancyGuard.sol";

contract SimpleBankSafe is ReentrancyGuard {
    mapping(address => uint256) public userBalance;

    function deposit() external payable {
        require(msg.value >= 1 ether, "Minimum deposit is 1 ETH");
        userBalance[msg.sender] += msg.value;
    }

    function withdraw() external nonReentrant {
        uint256 amount = userBalance[msg.sender];
        require(amount >= 1 ether, "User has not enough balance");
        require(address(this).balance >= amount, "Bank has not enough ETH");

        // Effects before interactions (CEI)
        userBalance[msg.sender] = 0;

        (bool success,) = msg.sender.call{value: amount}("");
        require(success, "ETH transfer failed");
    }

    function totalBalance() external view returns (uint256) {
        return address(this).balance;
    }
}
