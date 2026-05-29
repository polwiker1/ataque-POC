// SPDX-License-Identifier: MIT
pragma solidity 0.8.24;

import {Script, console2} from "forge-std/Script.sol";

interface IERC20MetadataLike {
    function decimals() external view returns (uint8);
}

interface IUniswapV3PoolLike {
    function token0() external view returns (address);
    function token1() external view returns (address);
    function fee() external view returns (uint24);
    function slot0()
        external
        view
        returns (
            uint160 sqrtPriceX96,
            int24 tick,
            uint16,
            uint16,
            uint16,
            uint8,
            bool
        );
}

interface IQuoterV2Like {
    struct QuoteExactInputSingleParams {
        address tokenIn;
        address tokenOut;
        uint256 amountIn;
        uint24 fee;
        uint160 sqrtPriceLimitX96;
    }

    function quoteExactInputSingle(QuoteExactInputSingleParams memory params)
        external
        returns (uint256 amountOut, uint160 sqrtPriceX96After, uint32 initializedTicksCrossed, uint256 gasEstimate);
}

contract ReadOnlyPriceImpactScan is Script {
    function run() external {
        address poolAddr = vm.envAddress("POOL_ADDRESS");
        address quoterAddr = vm.envAddress("QUOTER_ADDRESS");

        IUniswapV3PoolLike pool = IUniswapV3PoolLike(poolAddr);
        IQuoterV2Like quoter = IQuoterV2Like(quoterAddr);

        address token0 = pool.token0();
        address token1 = pool.token1();
        uint24 fee = pool.fee();
        (uint160 sqrtPriceX96, int24 tick,,,,,) = pool.slot0();

        uint8 d0 = IERC20MetadataLike(token0).decimals();
        uint8 d1 = IERC20MetadataLike(token1).decimals();

        uint256 spotPrice1e18 = _priceToken1PerToken0_1e18(sqrtPriceX96, d0, d1);

        console2.log("=== Read-Only Price Impact Scan ===");
        console2.log("Pool:", poolAddr);
        console2.log("Quoter:", quoterAddr);
        console2.log("token0:", token0);
        console2.log("token1:", token1);
        console2.log("fee:", uint256(fee));
        console2.log("tick:", int256(tick));
        console2.log("spot token1/token0 (1e18):", spotPrice1e18);

        uint256[5] memory notionalsUsd1e6 = [uint256(10_000_000), 50_000_000, 100_000_000, 500_000_000, 1_000_000_000];

        for (uint256 i = 0; i < notionalsUsd1e6.length; i++) {
            uint256 amountInToken1 = notionalsUsd1e6[i] * (10 ** d1) / 1e6;

            IQuoterV2Like.QuoteExactInputSingleParams memory p = IQuoterV2Like.QuoteExactInputSingleParams({
                tokenIn: token1,
                tokenOut: token0,
                amountIn: amountInToken1,
                fee: fee,
                sqrtPriceLimitX96: 0
            });

            (uint256 amountOutToken0,, uint32 ticksCrossed,) = quoter.quoteExactInputSingle(p);

            uint256 impliedPrice1e18 = (amountInToken1 * 1e18 * (10 ** d0)) / (amountOutToken0 * (10 ** d1));
            uint256 deviationBps = _absDiffBps(impliedPrice1e18, spotPrice1e18);

            console2.log("---");
            console2.log("notional token1 (1e6 units):", notionalsUsd1e6[i]);
            console2.log("quoted token0 out:", amountOutToken0);
            console2.log("implied execution price token1/token0 (1e18):", impliedPrice1e18);
            console2.log("deviation vs spot (bps):", deviationBps);
            console2.log("initialized ticks crossed:", uint256(ticksCrossed));

            if (deviationBps > 1000) {
                console2.log("[ALERT] >10% execution deviation at this notional");
            }
        }

        console2.log("NOTE: scan is read-only; no swaps or fund movements were executed.");
    }

    function _priceToken1PerToken0_1e18(uint160 sqrtPriceX96, uint8 d0, uint8 d1) internal pure returns (uint256) {
        uint256 sp = uint256(sqrtPriceX96);
        uint256 ratioX192 = sp * sp;
        uint256 raw = (ratioX192 * 1e18) / (2 ** 192);

        if (d0 > d1) {
            return raw * (10 ** (d0 - d1));
        }
        if (d1 > d0) {
            return raw / (10 ** (d1 - d0));
        }
        return raw;
    }

    function _absDiffBps(uint256 a, uint256 b) internal pure returns (uint256) {
        if (a == b) return 0;
        uint256 diff = a > b ? a - b : b - a;
        return (diff * 10_000) / b;
    }
}
