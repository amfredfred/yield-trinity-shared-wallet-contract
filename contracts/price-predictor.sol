// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "@uniswap/v2-periphery/contracts/interfaces/IUniswapV2Router02.sol";
import "@uniswap/v2-core/contracts/interfaces/IUniswapV2Pair.sol";
import "@uniswap/v2-core/contracts/interfaces/IUniswapV2Factory.sol";
import "@openzeppelin/contracts/interfaces/IERC20.sol";

contract PricePredictor {
    IUniswapV2Router02 uniswapRouter;
    IUniswapV2Factory public uniswapFactory;

    constructor(address routerAddress, address _uniswapFactory) {
        uniswapRouter = IUniswapV2Router02(routerAddress);
        uniswapFactory = IUniswapV2Factory(_uniswapFactory);
    }
 
    function predictFuturePrice(
        address tokenFrom,
        address tokenTo,
        uint256 amount
    ) external view returns (uint256) {  
        // Get the path array for the input token -> output token swap
        address[] memory path = new address[](2);
        path[0] = tokenFrom;
        path[1] = tokenTo;
        // Calculate the expected output amount for the input token -> output token swap
        uint256[] memory amountsOut = uniswapRouter.getAmountsOut(amount, path);
        uint256 effectiveAmountOut = (amountsOut[1] * 997) / 1000;
        // Calculate the required input amount for the output token -> input token swap
        uint256[] memory amountsIn = uniswapRouter.getAmountsIn( effectiveAmountOut,    path );
        uint256 effectiveAmountIn = (amountsIn[0] * 997) / 1000;
        // Calculate the price increase
        uint256 priceIncrease = (effectiveAmountOut * 1e18) /   effectiveAmountIn -    1;
        return priceIncrease;
    }

    function getPriceImpact(
        address tokenIn,
        address tokenOut,
        uint256 amountIn
    ) public view returns (uint256) {
        uint256[] memory amounts = uniswapRouter.getAmountsOut(
            amountIn,
            getPathForToken(tokenIn, tokenOut)
        );
        uint256 amountOut = amounts[amounts.length - 1];
        uint256 spotPriceBefore = (amountOut * 1e18) /
            getReserve(tokenOut, tokenIn);

        uint256 reserveIn = getReserve(tokenIn, tokenOut);
        uint256 reserveOut = getReserve(tokenOut, tokenIn);
        uint256 amountInWithFee = amountIn * 997; // 0.3% fee
        uint256 numerator = amountInWithFee * reserveOut * 1000;
        uint256 denominator = (reserveIn * 997) + amountInWithFee;
        uint256 amountOutWithSlippage = numerator / denominator;
        uint256 spotPriceAfter = (amountOutWithSlippage * 1e18) /
            (reserveIn + amountIn);

        return ((spotPriceBefore - spotPriceAfter) * 1e18) / spotPriceBefore;
    }

    function getPathForToken(address tokenIn, address tokenOut)
        internal
        pure
        returns (address[] memory)
    {
        address[] memory path = new address[](2);
        path[0] = tokenIn;
        path[1] = tokenOut;
        return path;
    }

    function getReserve(address tokenA, address tokenB)
        internal
        view
        returns (uint256)
    {
        (uint256 reserveA, uint256 reserveB, ) = IUniswapV2Pair(
            getPair(tokenA, tokenB)
        ).getReserves();
        return
            tokenA == IUniswapV2Pair(getPair(tokenA, tokenB)).token0()
                ? reserveA
                : reserveB;
    }

    function getPair(address tokenA, address tokenB)
        internal
        view
        returns (address)
    {
        return uniswapFactory.getPair(tokenA, tokenB);
    }
}
