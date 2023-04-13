pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";

interface IUniswapRouter {
    function getAmountsOut(
        uint amountIn,
        address[] memory path
    ) external view returns (uint[] memory amounts);

    function swapExactTokensForTokens(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external returns (uint[] memory amounts);
}

interface ISushiswapRouter {
    function getAmountsOut(
        uint amountIn,
        address[] memory path
    ) external view returns (uint[] memory amounts);

    function swapExactTokensForTokens(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external returns (uint[] memory amounts);
}

interface IPancakeRouter {
    function getAmountsOut(
        uint amountIn,
        address[] memory path
    ) external view returns (uint[] memory amounts);

    function swapExactTokensForTokens(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external returns (uint[] memory amounts);
}

contract DexArbitrage {
    using SafeERC20 for IERC20;

    address public owner;
    address public constant WETH_ADDRESS =
        0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2;
    address public constant UNISWAP_ROUTER_ADDRESS =
        0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D;
    address public constant SUSHISWAP_ROUTER_ADDRESS =
        0xd9e1cE17f2641f24aE83637ab66a2cca9C378B9F;
    address public constant PANCAKESWAP_ROUTER_ADDRESS =
        0x10ED43C718714eb63d5aA57B78B54704E256024E;

    constructor() {
        owner = msg.sender;
    }

    function executeArbitrage(
        address token0,
        address token1,
        uint amount
    ) external {
        require(msg.sender == owner, "Unauthorized");

        // Get exchange rates for Uniswap, Sushiswap and Pancakeswap
        uint[] memory uniswapAmountsOut = IUniswapRouter(UNISWAP_ROUTER_ADDRESS)
            .getAmountsOut(amount, getUniswapPath(token0, token1));
        uint uniswapAmountOut = uniswapAmountsOut[uniswapAmountsOut.length - 1];

        uint[] memory sushiswapAmountsOut = ISushiswapRouter(
            SUSHISWAP_ROUTER_ADDRESS
        ).getAmountsOut(amount, getSushiswapPath(token0, token1));
        uint sushiswapAmountOut = sushiswapAmountsOut[
            sushiswapAmountsOut.length - 1
        ];

        uint[] memory pancakeswapAmountsOut = IPancakeRouter(
            PANCAKESWAP_ROUTER_ADDRESS
        ).getAmountsOut(amount, getPancakeswapPath(token0, token1));
        uint pancakeswapAmountOut = pancakeswapAmountsOut[
            pancakeswapAmountsOut.length - 1
        ];

        // Check that token0 is part of Uniswap pair and token1 is part of Sushiswap
        require(
            getUniswapPath(token0, token1)[
                getUniswapPath(token0, token1).length - 1
            ] == token1,
            "Invalid Uniswap pair"
        );
        require(
            getSushiswapPath(token0, token1)[
                getSushiswapPath(token0, token1).length - 1
            ] == token1,
            "Invalid Sushiswap pair"
        );
        require(
            getPancakeswapPath(token0, token1)[
                getPancakeswapPath(token0, token1).length - 1
            ] == token1,
            "Invalid Pancakeswap pair"
        );

        // Check if there is an arbitrage opportunity
        if (
            uniswapAmountOut > amount &&
            uniswapAmountOut > sushiswapAmountOut &&
            uniswapAmountOut > pancakeswapAmountOut
        ) {
            // Perform Uniswap arbitrage
            IERC20(token0).safeApprove(UNISWAP_ROUTER_ADDRESS, amount);
            IUniswapRouter(UNISWAP_ROUTER_ADDRESS).swapExactTokensForTokens(
                amount,
                0,
                getUniswapPath(token0, token1),
                address(this),
                block.timestamp + 1800
            );
            uint token1Balance = IERC20(token1).balanceOf(address(this));
            IERC20(token1).safeTransfer(msg.sender, token1Balance);
        } else if (
            sushiswapAmountOut > amount &&
            sushiswapAmountOut > uniswapAmountOut &&
            sushiswapAmountOut > pancakeswapAmountOut
        ) {
            // Perform Sushiswap arbitrage
            IERC20(token0).safeApprove(SUSHISWAP_ROUTER_ADDRESS, amount);
            ISushiswapRouter(SUSHISWAP_ROUTER_ADDRESS).swapExactTokensForTokens(
                amount,
                0,
                getSushiswapPath(token0, token1),
                address(this),
                block.timestamp + 1800
            );
            uint token1Balance = IERC20(token1).balanceOf(address(this));
            IERC20(token1).safeTransfer(msg.sender, token1Balance);
        } else if (
            pancakeswapAmountOut > amount &&
            pancakeswapAmountOut > uniswapAmountOut &&
            pancakeswapAmountOut > sushiswapAmountOut
        ) {
            // Perform Pancakeswap arbitrage
            IERC20(token0).safeApprove(PANCAKESWAP_ROUTER_ADDRESS, amount);
            IPancakeRouter(PANCAKESWAP_ROUTER_ADDRESS).swapExactTokensForTokens(
                amount,
                0,
                getPancakeswapPath(token0, token1),
                address(this),
                block.timestamp + 1800
            );
            uint token1Balance = IERC20(token1).balanceOf(address(this));
            IERC20(token1).safeTransfer(msg.sender, token1Balance);
        } else {
            revert("No arbitrage opportunity");
        }
    }

    function getUniswapPath(
        address token0,
        address token1
    ) internal pure returns (address[] memory) {
        address[] memory path = new address[](2);
        path[0] = token0;
        path[1] = token1;
        return path;
    }

    function getSushiswapPath(
        address token0,
        address token1
    ) internal pure returns (address[] memory) {
        address[] memory path = new address[](2);
        path[0] = token0;
        path[1] = token1;
        return path;
    }

    function getPancakeswapPath(
        address token0,
        address token1
    ) internal pure returns (address[] memory) {
        address[] memory path = new address[](2);
        path[0] = token0;
        path[1] = token1;
        return path;
    }

    function getAmountOut(
        address dexRouter,
        uint amountIn,
        address[] memory path
    ) internal view returns (uint) {
        uint[] memory amounts = IUniswapRouter(dexRouter).getAmountsOut(
            amountIn,
            path
        );
        return amounts[amounts.length - 1];
    }

    function uniswapAmountOut(
        address token0,
        address token1,
        uint amount
    ) internal view returns (uint) {
        address[] memory path = getUniswapPath(token0, token1);
        return getAmountOut(UNISWAP_ROUTER_ADDRESS, amount, path);
    }

    function sushiswapAmountOut(
        address token0,
        address token1,
        uint amount
    ) internal view returns (uint) {
        address[] memory path = getSushiswapPath(token0, token1);
        return getAmountOut(SUSHISWAP_ROUTER_ADDRESS, amount, path);
    }

    function pancakeswapAmountOut(
        address token0,
        address token1,
        uint amount
    ) internal view returns (uint) {
        address[] memory path = getPancakeswapPath(token0, token1);
        return getAmountOut(PANCAKESWAP_ROUTER_ADDRESS, amount, path);
    }
}
