// SPDX-License-Identifier: MIT
pragma solidity 0.8.24;

import {Script, console2} from "forge-std/Script.sol";
import {Math} from "openzeppelin-contracts/contracts/utils/math/Math.sol";

interface IUniswapV3PoolLike {
    function token0() external view returns (address);
    function token1() external view returns (address);
    function fee() external view returns (uint24);
    function liquidity() external view returns (uint128);
    function slot0()
        external
        view
        returns (
            uint160 sqrtPriceX96,
            int24 tick,
            uint16 observationIndex,
            uint16 observationCardinality,
            uint16 observationCardinalityNext,
            uint8 feeProtocol,
            bool unlocked
        );
}

contract TestnetUniswapV3RiskScan is Script {
    function run() external view {
        address pool = vm.envAddress("POOL_ADDRESS");
        IUniswapV3PoolLike p = IUniswapV3PoolLike(pool);

        address token0 = p.token0();
        address token1 = p.token1();
        uint24 feeTier = p.fee();
        uint128 liq = p.liquidity();

        (
            uint160 sqrtPriceX96,
            int24 tick,
            uint16 observationIndex,
            uint16 observationCardinality,
            uint16 observationCardinalityNext,
            uint8 feeProtocol,
            bool unlocked
        ) = p.slot0();

        uint256 spotPrice1e18 = _spotPriceToken1PerToken0(sqrtPriceX96);

        console2.log("=== Uniswap V3 Testnet Risk Scan ===");
        console2.log("Pool:", pool);
        console2.log("token0:", token0);
        console2.log("token1:", token1);
        console2.log("fee tier:", uint256(feeTier));
        console2.log("active liquidity:", uint256(liq));
        console2.log("tick:", int256(tick));
        console2.log("sqrtPriceX96:", uint256(sqrtPriceX96));
        console2.log("spot price token1/token0 (1e18):", spotPrice1e18);
        console2.log("observationIndex:", uint256(observationIndex));
        console2.log("observationCardinality:", uint256(observationCardinality));
        console2.log("observationCardinalityNext:", uint256(observationCardinalityNext));
        console2.log("feeProtocol:", uint256(feeProtocol));
        console2.log("unlocked:", unlocked);

        // Heuristica simple: cardinality muy baja = TWAP potencialmente mas debil
        if (observationCardinality < 10) {
            console2.log("[ALERT] Low observation cardinality (<10): TWAP window may be weak");
        }

        // Heuristica simple: liquidez activa muy baja
        if (liq < 1e15) {
            console2.log("[ALERT] Very low active liquidity: spot price likely easier to move");
        }
    }

    function _spotPriceToken1PerToken0(uint160 sqrtPriceX96) internal pure returns (uint256) {
        // price = (sqrtPriceX96^2) / 2^192, escalado a 1e18.
        // Use 512-bit mulDiv to avoid overflow on deep-liquidity pools.
        uint256 sp = uint256(sqrtPriceX96);
        uint256 ratioX192 = Math.mulDiv(sp, sp, 1);
        return Math.mulDiv(ratioX192, 1e18, 2 ** 192);
    }
}
