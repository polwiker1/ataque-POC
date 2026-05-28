// SPDX-License-Identifier: MIT
pragma solidity 0.8.24;

import {Test} from "forge-std/Test.sol";
import {WalletTxOriginVulnerable} from "../src/WalletTxOriginVulnerable.sol";
import {TxOriginAttacker} from "../src/TxOriginAttacker.sol";

contract TxOriginTest is Test {
    address internal owner = makeAddr("owner");
    address internal badGuy = makeAddr("badGuy");

    function test_TxOrigin_PhishingDrainsWallet() public {
        vm.deal(owner, 10 ether);

        vm.startPrank(owner);
        WalletTxOriginVulnerable wallet = new WalletTxOriginVulnerable();
        wallet.deposit{value: 10 ether}();
        vm.stopPrank();

        assertEq(address(wallet).balance, 10 ether, "wallet should be funded");

        TxOriginAttacker attacker = new TxOriginAttacker(address(wallet), payable(badGuy));

        // Simulate phishing: owner calls attacker contract
        // msg.sender = owner and tx.origin = owner
        vm.startPrank(owner, owner);
        attacker.phishing();
        vm.stopPrank();

        assertEq(address(wallet).balance, 0, "wallet should be drained");
        assertEq(address(badGuy).balance, 10 ether, "attacker should receive funds");
    }

    function test_TxOrigin_DirectCallByNonOwnerReverts() public {
        vm.deal(owner, 1 ether);

        vm.startPrank(owner);
        WalletTxOriginVulnerable wallet = new WalletTxOriginVulnerable();
        wallet.deposit{value: 1 ether}();
        vm.stopPrank();

        vm.expectRevert("Not owner via tx.origin");
        vm.prank(badGuy);
        wallet.transferAll(payable(badGuy));
    }
}
