pragma solidity ^0.8.0;

import './Arbitrage-Unuswap-Sushiswap.sol';



contract LatestDexArbitrage is DexArbitrage {
    
    function buyLatestToken(address dexRouter, address token0, address token1, uint amountIn) external {
        address[] memory path = getPath(token0, token1);
        uint[] memory amounts = IUniswapRouter(dexRouter).getAmountsOut(amountIn, path);
        uint amountOut = amounts[amounts.length - 1];
        require(IERC20(token1).approve(dexRouter, amountIn), 'approval failed');
        uint[] memory tradeResult = IUniswapRouter(dexRouter).swapExactTokensForTokens(amountIn, amountOut, path, address(this), block.timestamp);
        emit BoughtLatestToken(token1, tradeResult[0]);
    }
    
    function findArbitrageOpportunity(address token0, address token1) external {
        uint uniswapAmount = uniswapAmountOut(token0, token1, IERC20(token0).balanceOf(address(this)));
        uint sushiswapAmount = sushiswapAmountOut(token0, token1, IERC20(token0).balanceOf(address(this)));
        uint pancakeswapAmount = pancakeswapAmountOut(token0, token1, IERC20(token0).balanceOf(address(this)));
        address dexRouter;
        if (uniswapAmount > sushiswapAmount && uniswapAmount > pancakeswapAmount) {
            dexRouter = UNISWAP_ROUTER_ADDRESS;
        } else if (sushiswapAmount > uniswapAmount && sushiswapAmount > pancakeswapAmount) {
            dexRouter = SUSHISWAP_ROUTER_ADDRESS;
        } else {
            dexRouter = PANCAKESWAP_ROUTER_ADDRESS;
        }
        uint[] memory amounts = IUniswapRouter(dexRouter).getAmountsOut(IERC20(token0).balanceOf(address(this)), getPath(token0, token1));
        uint amountOut = amounts[amounts.length - 1];
        uint profit = amountOut - uniswapAmount - sushiswapAmount - pancakeswapAmount;
        if (profit > 0) {
            uint[] memory tradeResult = IUniswapRouter(dexRouter).swapExactTokensForTokens(IERC20(token0).balanceOf(address(this)), amountOut, getPath(token0, token1), address(this), block.timestamp);
            emit ArbitrageOpportunity(token0, token1, profit, dexRouter, tradeResult[0]);
        }
    }
    
    function sellTokenForProfit(address dexRouter, address token0, address token1) external {
        uint[] memory amounts = IUniswapRouter(dexRouter).getAmountsOut(IERC20(token0).balanceOf(address(this)), getPath(token0, token1));
        uint amountOut = amounts[amounts.length - 1];
        uint profit = amountOut - uniswapAmountOut(token0, token1, IERC20(token0).balanceOf(address(this))) - sushiswapAmountOut(token0, token1, IERC20(token0).balanceOf(address(this))) - pancakeswapAmountOut(token0, token1, IERC20(token0).balanceOf(address(this)));
        require(profit > 0, 'no arbitrage opportunity found');
        require(IERC20(token0).approve(dexRouter, IERC20(token0).balanceOf(address(this))), 'approval failed');
        uint[] memory tradeResult = IUniswapRouter(dexRouter).swapExactTokensForTokens(
    IERC20(token0).balanceOf(address(this)), amountOut, getPath(token0, token1), address(this), block.timestamp);
    emit SoldTokenForProfit(token0, token1, profit, dexRouter, tradeResult[0]);
    require(IERC20(token0).approve(UNISWAP_ROUTER_ADDRESS, 0), 'approval reset failed');
    require(IERC20(token0).approve(SUSHISWAP_ROUTER_ADDRESS, 0), 'approval reset failed');
    require(IERC20(token0).approve(PANCAKESWAP_ROUTER_ADDRESS, 0), 'approval reset failed');
}

function getETHBalance() external view returns(uint) {
    return address(this).balance;
}

function getWETHBalance() external view returns(uint) {
    return IERC20(WETH_ADDRESS).balanceOf(address(this));
}

function withdrawETH() external {
    uint balance = address(this).balance;
    require(balance > 0, 'insufficient balance');
    payable(msg.sender).transfer(balance);
}

function withdrawWETH() external {
    uint balance = IERC20(WETH_ADDRESS).balanceOf(address(this));
    require(balance > 0, 'insufficient balance');
    require(IERC20(WETH_ADDRESS).approve(UNISWAP_ROUTER_ADDRESS, balance), 'approval failed');
    IUniswapRouter(UNISWAP_ROUTER_ADDRESS).swapExactTokensForETH(balance, 0, getPath(WETH_ADDRESS, address(0)), msg.sender, block.timestamp);
}
}