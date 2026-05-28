// SPDX-License-Identifier: MIT
pragma solidity 0.8.24;

import {Test} from "forge-std/Test.sol";
import {SimpleBank} from "../src/SimpleBanck.sol";
import {Attacker} from "../src/Atacante.sol";
import {SimpleBankSafe} from "../src/SimpleBankSafe.sol";

contract ReentrancyTest is Test {
    address internal victim = makeAddr("victim");

    function test_Reentrancy_Exploit_DrainsVulnerableBank() public {
        SimpleBank bank = new SimpleBank();
        Attacker attacker = new Attacker(address(bank));

        vm.deal(victim, 10 ether);
        vm.prank(victim);
        bank.deposit{value: 10 ether}();

        assertEq(address(bank).balance, 10 ether, "bank should start with victim funds");

        vm.deal(address(attacker), 1 ether);
        attacker.attack{value: 1 ether}();

        assertEq(address(bank).balance, 0, "bank should be drained");
        assertEq(address(attacker).balance, 12 ether, "attacker should steal victim funds");
    }

    function test_Reentrancy_FailsAgainstSafeBank() public {
        SimpleBankSafe bankSafe = new SimpleBankSafe();
        Attacker attacker = new Attacker(address(bankSafe));

        vm.deal(victim, 10 ether);
        vm.prank(victim);
        bankSafe.deposit{value: 10 ether}();

        assertEq(address(bankSafe).balance, 10 ether, "safe bank should start funded");

        vm.deal(address(attacker), 1 ether);

        vm.expectRevert();
        attacker.attack{value: 1 ether}();

        assertEq(address(bankSafe).balance, 10 ether, "safe bank must keep victim funds");
        assertEq(address(attacker).balance, 1 ether, "attacker contract should keep its initial ether");
    }
}
