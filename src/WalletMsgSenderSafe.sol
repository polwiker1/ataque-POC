// SPDX-License-Identifier: MIT
pragma solidity 0.8.24;

contract WalletMsgSenderSafe {
    address public owner;

    constructor() payable {
        owner = msg.sender;
    }

    function deposit() external payable {}

    // *CAMBIO CLAVE*: autenticamos con msg.sender (NO con tx.origin)
    function transferAll(address payable to) external {
        require(msg.sender == owner, "Not owner via msg.sender");
        (bool ok, ) = to.call{value: address(this).balance}("");
        require(ok, "Transfer failed");
    }

    function getBalance() external view returns (uint256) {
        return address(this).balance;
    }
}
