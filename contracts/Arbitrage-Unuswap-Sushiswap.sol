pragma solidity ^0.8.0;

import "@uniswap/v2-periphery/contracts/interfaces/IUniswapV2Router02.sol";
import "@sushiswap/core/contracts/uniswapv2/interfaces/IUniswapV2Pair.sol";
import "@sushiswap/core/contracts/uniswapv2/interfaces/IUniswapV2Factory.sol";

contract DexArbitrage {
    address private constant UNISWAP_ROUTER_ADDRESS =
        0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D;
    address private constant SUSHISWAP_FACTORY_ADDRESS =
        0xc35DADB65012eC5796536bD9864eD8773aBc74C4;

    IUniswapV2Router02 private uniswapRouter;
    IUniswapV2Factory private sushiswapFactory;

    constructor() {
        uniswapRouter = IUniswapV2Router02(UNISWAP_ROUTER_ADDRESS);
        sushiswapFactory = IUniswapV2Factory(SUSHISWAP_FACTORY_ADDRESS);
    }

    function executeArbitrage(
        address token0,
        address token1,
        uint amount
    ) external {
        address[] memory uniswapPath = new address[](2);
        address[] memory sushiswapPath = new address[](2);
        uint[] memory uniswapAmounts = uniswapRouter.getAmountsOut(
            amount,
            uniswapPath
        );
        uint[] memory sushiswapAmounts = new uint[](2);
        sushiswapAmounts[0] = amount;
        sushiswapAmounts[1] = 0;

        IUniswapV2Pair uniswapPair = IUniswapV2Pair(uniswapPath[1]);
        IUniswapV2Pair sushiswapPair = IUniswapV2Pair(sushiswapPath[1]);
        address token0Uniswap = uniswapPair.token0();
        address token1Uniswap = uniswapPair.token1();
        address token0Sushiswap = sushiswapPair.token0();
        address token1Sushiswap = sushiswapPair.token1();

        // Ensure tokens are different
        require(token0 != token1, "Tokens must be different");
        require(
            token0 == token0Uniswap || token0 == token1Uniswap,
            "Token0 not in Uniswap pair"
        );
        require(
            token1 == token0Sushiswap || token1 == token1Sushiswap,
            "Token1 not in Sushiswap pair"
        );

        // Ensure profitable trade
        uint uniswapAmountOut = uniswapAmounts[1];
        uint sushiswapAmountOut = sushiswapAmounts[1];
        require(uniswapAmountOut > sushiswapAmountOut, "Trade not profitable");

        // Perform trade
        uniswapPath[0] = token0;
        uniswapPath[1] = token1;
        sushiswapPath[0] = token1;
        sushiswapPath[1] = token0;

        uniswapRouter.swapExactTokensForTokens(
            amount,
            uniswapAmountOut,
            uniswapPath,
            address(this),
            block.timestamp
        );
        sushiswapPair.swap(
            sushiswapAmountOut,
            0,
            address(this),
            sushiswapPath,
            block.timestamp
        );
        // Send profits to caller
        uint profit = address(this).balance;
        payable(msg.sender).transfer(profit);
    }

    receive() external payable {}
}
