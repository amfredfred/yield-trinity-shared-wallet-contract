// SPDX-License-Identifier: MIT

pragma solidity >=0.8.0;

import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "@uniswap/v2-core/contracts/interfaces/IUniswapV2Factory.sol";
import "@uniswap/v2-core/contracts/interfaces/IUniswapV2Pair.sol";
import "@uniswap/v2-periphery/contracts/interfaces/IUniswapV2Router02.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

contract IYieldTrinityDicoverer {
    IUniswapV2Pair IPairV2;
    // IYieldTrinitySharedWallet SharedWallet;

    address public usdt;
    address public weth;

    using SafeMath for uint256;

    struct TokenInfo {
        string name;
        string symbol;
        uint256 decimals;
        uint256 totalSupply;
    }

    constructor(address _usdt, address _weth) {
        usdt = _usdt;
        weth = _weth;
    }

    function quotes(
        address _router,
        address _token1,
        address _token2,
        address _factory,
        uint256 _amount
    ) public view returns (uint256 currentPrice) {
        if (!(hasLiquidity(_token1, _token2, _factory))) return 0;
        (uint256 reserve0, uint256 reserve1) = tokensLiquidity(
            _token1,
            _token2,
            _factory
        );
        return IUniswapV2Router02(_router).quote(_amount, reserve0, reserve1);
    }

    function quoteByPair(
        address _router,
        address _pair,
        uint256 _amount,
        address _factory
    ) public view returns (uint256 currentQuote) {
        (address _token1, address _token2) = getTokensFromPair(_pair);
        if (!(hasLiquidity(_token1, _token2, _factory))) return 0;
        address _fm = _token1;
        address _to = _token2;
        if (_token1 == weth) {
            _fm = _token2;
            _to = _token1;
        }
        return quotes(_router, _fm, _to, _factory, _amount);
    }

    function getPathForToken(
        address tokenIn,
        address tokenOut
    ) internal pure returns (address[] memory) {
        address[] memory path = new address[](2);
        path[0] = tokenIn;
        path[1] = tokenOut;
        return path;
    }

    function getLastPrice(
        address _token1,
        address _token2,
        address _route,
        address _factory
    ) public view returns (uint256 lastRate) {
        address[] memory path = new address[](2);
        path[0] = _token1;
        path[1] = _token2;
        if (!hasLiquidity(_token1, _token2, _factory)) return 0;
        uint256[] memory amounts = IUniswapV2Router02(_route).getAmountsOut(
            10 ** IERC20(_token1).decimals(),
            path
        );
        return amounts[1];
    }

    function priceInToken(
        address _token0,
        address _token1,
        address _router,
        address _factory
    ) public view returns (uint256 price) {
        return
            quotes(
                _router,
                _token0,
                _token1,
                _factory,
                10 ** IERC20(_token0).decimals()
            );
    }

    function priceInWETH(
        address _token,
        address _router,
        address _factory
    ) public view returns (uint256 price) {
        return
            quotes(
                _router,
                _token,
                weth,
                _factory,
                10 ** IERC20(_token).decimals()
            );
    }

    function priceInUSDT(
        address _token,
        address _router,
        address _factory
    ) public view returns (uint256 price) {
        address pair = getPairAddress(_token, usdt, _factory);
        if (pair == address(0)) return 0;
        uint256 tokenPriceInWETH = priceInWETH(_token, _router, _factory);
        uint256 wethPriceInUSDT = quotes(
            _router,
            weth,
            usdt,
            _factory,
            uint256(10 ** 18)
        );
        return (tokenPriceInWETH * wethPriceInUSDT) / 1e18;
    }

    function getLastPair(address _factory) public view returns (address pair) {
        uint256 numPairs = IUniswapV2Factory(_factory).allPairsLength();
        address lastPair = IUniswapV2Factory(_factory).allPairs(numPairs - 1);
        return lastPair;
    }

    function predictFuturePrices(
        address[] calldata routes,
        address[] calldata path,
        uint256 amountIn
    ) external view returns (uint256[] memory prices) {
        uint256[] memory _outputs = new uint256[](routes.length);
        for (uint256 r = 0; r < routes.length; r++) {
            _outputs[r] = _predictPrice(routes[r], path, amountIn);
        }
        return _outputs;
    }

    function _predictPrice(
        address _route,
        address[] memory path,
        uint256 _amount
    ) public view returns (uint256 price) {
        uint256[] memory amountsOut = IUniswapV2Router02(_route).getAmountsOut(
            _amount,
            path
        );
        uint256 efAmtOut = (amountsOut[1] * 997) / 1000;
        uint256[] memory amountsIn = IUniswapV2Router02(_route).getAmountsIn(
            efAmtOut,
            path
        );
        uint256 efAmtIn = (amountsIn[0] * 997) / 1000;
        // Calculate the price increase
        uint256 priceIncrease = (efAmtOut * 1e18) / efAmtIn - 1;
        return priceIncrease;
    }

    function hasLiquidity(
        address _token1,
        address _token2,
        address _factory
    ) public view returns (bool hasliquidity) {
        address pair = getPairAddress(_token1, _token2, _factory);
        if (pair == address(0)) return false;
        (uint112 reserve1, uint112 reserve2, ) = IUniswapV2Pair(pair)
            .getReserves();
        if (reserve1 == 0 || reserve2 == 0) return false;
        return true;
    }

    function tokensLiquidity(
        address _token1,
        address _token2,
        address _factory
    ) public view returns (uint256 base, uint256 token) {
        if (!hasLiquidity(_token1, _token2, _factory)) return (0, 0);
        address pair = getPairAddress(_token1, _token2, _factory);
        (uint256 reserve1, uint256 reserve2, ) = IUniswapV2Pair(pair)
            .getReserves();
        uint256 Base = reserve1;
        uint256 Token = reserve2;
        if (
            keccak256(
                abi.encodePacked(IERC20(IUniswapV2Pair(pair).token0()).symbol())
            ) != keccak256(abi.encodePacked(IERC20(_token1).symbol()))
        ) {
            Base = reserve2;
            Token = reserve1;
        }
        return (Base, Token);
    }

    function getTokenFromPair(
        address _pair
    ) public view returns (address tokenAddress, bool isValid) {
        address token0 = IUniswapV2Pair(_pair).token0();
        address token1 = IUniswapV2Pair(_pair).token1();
        if (token0 != weth) return (token0, true);
        else if (token1 != weth) return (token1, true);
        else return (address(0), false);
    }

    function getTokenInfoFromPair(
        address pair
    ) public view returns (TokenInfo memory tokenInfo) {
        address token0 = IUniswapV2Pair(pair).token0();
        address token1 = IUniswapV2Pair(pair).token1();
        if (token0 != weth) return getTokenInfo(token1);
        else if (token1 != weth) return getTokenInfo(token1);
        else return getTokenInfo(address(0));
    }

    function getTokenInfo(
        address _token
    ) public view returns (TokenInfo memory) {
        IERC20 token = IERC20(_token);
        return
            TokenInfo({
                name: token.name(),
                symbol: token.symbol(),
                decimals: token.decimals(),
                totalSupply: token.totalSupply()
            });
    }

    function getPairAddress(
        address _token1,
        address _token2,
        address _factory
    ) public view returns (address) {
        return IUniswapV2Factory(_factory).getPair(_token1, _token2);
    }

    function getTokenPairReserves(
        address _pair,
        address _factory
    ) public view returns (uint256 token0Reserve, uint256 reserve1Reserve) {
        (address token0, address token1) = getTokensFromPair(_pair);
        if (!hasLiquidity(token0, token1, _factory)) return (0, 0);
        (uint256 reserve0, uint256 reserve1, ) = IUniswapV2Pair(_pair)
            .getReserves();
        IERC20 tokenOne = IERC20(token0);
        IERC20 tokenTwo = IERC20(token1);

        if (tokenOne.decimals() < tokenTwo.decimals()) {
            reserve0 = reserve0.mul(
                10 ** (tokenTwo.decimals() - tokenOne.decimals())
            );
        } else if (tokenTwo.decimals() < tokenOne.decimals()) {
            reserve1 = reserve1.mul(
                10 ** (tokenOne.decimals() - tokenTwo.decimals())
            );
        }
        return (reserve0, reserve1);
    }

    function getTokensFromPair(
        address _pair
    ) public view returns (address token0, address token1) {
        IUniswapV2Pair pair = IUniswapV2Pair(_pair);
        return (pair.token0(), pair.token1());
    }

    function getRouteOutputs(
        address[] calldata routes,
        address[] calldata path,
        uint256 amountIn
    ) public view returns (uint256[] memory outputs) {
        uint256[] memory _outputs = new uint256[](routes.length);
        for (uint256 r = 0; r < routes.length; r++) {
            _outputs[r] = _getRouteOutput(routes[r], path, amountIn);
        }
        return (_outputs);
    }

    function _getRouteOutput(
        address route,
        address[] calldata path,
        uint256 amountIn
    ) public view returns (uint256) {
        uint256[] memory dex1 = IUniswapV2Router02(route).getAmountsOut(
            amountIn,
            path
        );
        uint256 dexOneOut = dex1[path.length - 1];
        return (dexOneOut);
    }

    function priceImpacts(
        address _token0,
        address _token1,
        address[] memory _fatories,
        uint256 amount
    ) public view returns (uint256[] memory impacts) {
        uint256[] memory _outputs = new uint256[](_fatories.length);
        for (uint256 r = 0; r < _fatories.length; r++) {
            _outputs[r] = _priceImpact(_token0, _token1, _fatories[r], amount);
        }
        return (_outputs);
    }

    function _priceImpact(
        address _token0,
        address _token1,
        address _factory,
        uint256 amount
    ) public view returns (uint256 impact) {
        uint256 decimals = IERC20(_token0).decimals();
        (uint256 reserveA, uint256 reserveB) = tokensLiquidity(
            _token0,
            _token1,
            _factory
        );
        uint256 amountWithDecimals = (amount * 10 ** decimals);
        uint256 numerator = (amountWithDecimals * 100);
        uint256 denominator = (reserveA + amountWithDecimals);
        uint256 _impact = (numerator / denominator);
        return _impact;
    }

    function swap(
        address[] calldata _path,
        uint256 _amountIn,
        uint256 _minAmountOut,
        address _router
    ) public payable {
        uint256[] memory amounts = IUniswapV2Router02(_router)
            .swapExactTokensForTokens(
                _amountIn,
                _minAmountOut,
                _path,
                address(this),
                block.timestamp
            );
        uint256 outputAmount = amounts[amounts.length - 1];
        require(outputAmount >= _minAmountOut, "Minoutput Insufficient");
        // Transfer the tokens to the initiator
        IERC20(_path[_path.length - 1]).transfer(msg.sender, outputAmount);
    }
}
