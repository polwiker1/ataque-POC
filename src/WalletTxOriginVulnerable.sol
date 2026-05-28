// SPDX-License-Identifier: MIT
pragma solidity 0.8.24;

contract WalletTxOriginVulnerable {
    address public owner;

    constructor() payable {
        owner = msg.sender;
    }

    function deposit() external payable {}

    // Vulnerable: auth with tx.origin instead of msg.sender
    function transferAll(address payable to) external {
        require(tx.origin == owner, "Not owner via tx.origin");
        (bool ok, ) = to.call{value: address(this).balance}("");
        require(ok, "Transfer failed");
    }

    function getBalance() external view returns (uint256) {
        return address(this).balance;
    }
}
