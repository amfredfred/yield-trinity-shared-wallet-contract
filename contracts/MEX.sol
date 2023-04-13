pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@uniswap/v2-periphery/contracts/interfaces/IUniswapV2Router02.sol";

contract MEVBot {
    IUniswapV2Router02 public immutable uniswapRouter;
    address payable public beneficiary;

    constructor(
        IUniswapV2Router02 _uniswapRouter,
        address payable _beneficiary
    ) {
        uniswapRouter = _uniswapRouter;
        beneficiary = _beneficiary;
    }

    function extract() external {
        uint256 existingGasPrice = getExistingTransactionGasPrice();
        if (existingGasPrice > 0 && tx.gasprice <= existingGasPrice) {
            return;
        }

        // Swap ETH for WETH
        uint256 balanceBeforeSwap = address(this).balance;
        uniswapRouter.swapExactETHForTokens{value: balanceBeforeSwap}(
            0, // amountOutMin: 0 to allow for any output amount
            getPathForETHtoWETH(),
            address(this),
            block.timestamp + 300 // deadline: 5 minutes from now
        );

        // Perform arbitrage trade
        uint256 wethBalance = IERC20(getWETHAddress()).balanceOf(address(this));
        if (wethBalance == 0) {
            return;
        }

        address[] memory path = new address[](3);
        path[0] = getWETHAddress();
        path[1] = getAddressOfTokenToTrade();
        path[2] = getWETHAddress();

        uint256[] memory amounts = uniswapRouter.getAmountsOut(
            wethBalance,
            path
        );

        // Check that trade is profitable
        require(amounts[2] > wethBalance, "MEVBot: trade not profitable");

        uniswapRouter.swapExactTokensForTokens(
            wethBalance,
            0, // amountOutMin: 0 to allow for any output amount
            path,
            address(this),
            block.timestamp + 60 // deadline: 1 minute from now
        );

        // Send profits to beneficiary
        uint256 profit = IERC20(getWETHAddress()).balanceOf(address(this));
        if (profit > 0) {
            beneficiary.transfer(profit);
        }
    }

    function getPathForETHtoWETH() internal view returns (address[] memory) {
        address[] memory path = new address[](2);
        path[0] = uniswapRouter.WETH();
        path[1] = getWETHAddress();
        return path;
    }

    function getWETHAddress() internal view returns (address) {
        return uniswapRouter.WETH();
    }

    function getAddressOfTokenToTrade() internal view returns (address) {
        return address(0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D); // Uniswap v2 DEX
    }

    function getExistingTransactionGasPrice() internal view returns (uint256) {
        uint256 minGasPrice = 0;
        uint256 count = web3.eth.getPendingTransactions().length;
        for (uint256 i = 0; i < count; i++) {
            uint256 gasPrice = web3.eth.getPendingTransactions()[i].gasPrice;
            if (gasPrice < tx.gasprice && gasPrice > minGasPrice) {
                minGasPrice = gasPrice;
            }
        }
        return minGasPrice;
    }
}
