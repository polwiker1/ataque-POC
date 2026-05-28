// SPDX-License-Identifier: MIT
pragma solidity 0.8.24;

import {Test} from "forge-std/Test.sol";
import {WalletMsgSenderSafe} from "../src/WalletMsgSenderSafe.sol";
import {TxOriginAttacker} from "../src/TxOriginAttacker.sol";

contract TxOriginSafeTest is Test {
    address internal owner = makeAddr("owner");
    address internal badGuy = makeAddr("badGuy");

    function test_SafeWallet_BlocksPhishingAttack() public {
        vm.deal(owner, 10 ether);

        vm.startPrank(owner);
        WalletMsgSenderSafe wallet = new WalletMsgSenderSafe();
        wallet.deposit{value: 10 ether}();
        vm.stopPrank();

        assertEq(address(wallet).balance, 10 ether, "wallet should be funded");

        TxOriginAttacker attacker = new TxOriginAttacker(address(wallet), payable(badGuy));

        // Owner cae en phishing y llama al atacante
        // *CAMBIO CLAVE DEMOSTRADO*: ahora falla porque msg.sender != owner
        vm.startPrank(owner, owner);
        vm.expectRevert("Not owner via msg.sender");
        attacker.phishing();
        vm.stopPrank();

        assertEq(address(wallet).balance, 10 ether, "safe wallet keeps funds");
        assertEq(address(badGuy).balance, 0, "attacker gets nothing");
    }
}
