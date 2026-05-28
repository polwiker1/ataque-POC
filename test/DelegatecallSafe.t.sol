// SPDX-License-Identifier: MIT
pragma solidity 0.8.24;

import {Test} from "forge-std/Test.sol";
import {DelegateLib} from "../src/DelegateLib.sol";
import {DelegatecallProxySafe} from "../src/DelegatecallProxySafe.sol";
import {MaliciousDelegate} from "../src/MaliciousDelegate.sol";

contract DelegatecallSafeTest is Test {
    address internal deployer = makeAddr("deployer");
    address internal attacker = makeAddr("attacker");

    function test_SafeProxy_BlocksUnauthorizedImplementationChange() public {
        vm.startPrank(deployer);
        DelegateLib legit = new DelegateLib();
        DelegatecallProxySafe proxy = new DelegatecallProxySafe(address(legit));
        vm.stopPrank();

        vm.startPrank(attacker);
        MaliciousDelegate evil = new MaliciousDelegate();

        vm.expectRevert("Only owner");
        proxy.setImplementation(address(evil));
        vm.stopPrank();

        assertEq(proxy.owner(), deployer, "owner must remain deployer");
        assertEq(proxy.implementation(), address(legit), "implementation must remain legit");
    }

    function test_SafeProxy_NormalFlowStillWorks() public {
        DelegateLib legit = new DelegateLib();
        DelegatecallProxySafe proxy = new DelegatecallProxySafe(address(legit));

        proxy.executeSetValue(42);

        assertEq(proxy.value(), 42, "value should update through legit implementation");
    }
}
