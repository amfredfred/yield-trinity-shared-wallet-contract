// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

interface IUniswapV2Router02 {
    function getAmountsOut(
        uint256 amountIn,
        address[] calldata path
    ) external view returns (uint256[] memory amounts);

    function WETH() external pure returns (address);

    function getReserves()
        external
        view
        returns (uint112 reserve0, uint112 reserve1, uint32 blockTimestampLast);
}

interface IUniswapV2Pair {
    function token0() external view returns (address);

    function token1() external view returns (address);

    function getReserves()
        external
        view
        returns (uint112 reserve0, uint112 reserve1, uint32 blockTimestampLast);
}

interface IUniswapV2Factory {
    function getPair(
        address tokenA,
        address tokenB
    ) external view returns (address pair);

    function allPairs(uint256) external view returns (address pair);
    function allPairsLength() external view returns (uint256);
}

interface IERC20 {
    function decimals() external view returns (uint8);
    function totalSupply() external view returns (uint8);
    function name() external view returns (string memory);
    function symbol() external view returns (string memory);
}

contract YieldTrinityDicoverer {
    IUniswapV2Factory uniswapFactory;
    IUniswapV2Router02 uniswapRouter;
    address public usdtAddress;

    struct TokenInfo {
        string name;
        string symbol;
        uint8 decimals;
        uint256 totalSupply;
    }

    constructor(
        address _uniswapFactory,
        address _uniswapRouter,
        address _usdtAddress
    ) {
        uniswapFactory = IUniswapV2Factory(_uniswapFactory);
        uniswapRouter = IUniswapV2Router02(_uniswapRouter);
        usdtAddress = _usdtAddress;
    }

    function getLastPrice(  address _token1,   address _token2  ) public view returns (uint256 lastRate) {
        address[] memory path = new address[](2);
        path[0] = _token1;
        path[1] = _token2;
        if(!hasLiquidity(_token1, _token2)) return 0;
        uint256[] memory amounts = uniswapRouter.getAmountsOut(   10 ** getTokenDecimals(_token1),  path  );
        return amounts[1];
    }

    function getPriceInWETH( address _token  ) public view returns (uint256 priceInWETH) {
        address wethAddress = uniswapRouter.WETH();
        address[] memory path = new address[](2);
        path[0] = _token;
        path[1] = wethAddress;
        address pair = uniswapFactory.getPair(_token, wethAddress);
        if(pair == address(0)) return 0;
        uint256[] memory amounts = uniswapRouter.getAmountsOut(1e18, path);
        return amounts[1];
    }

    function getPriceInUSDT(  address _token  ) public view returns (uint256 priceInUSDT) {
        address pair = uniswapFactory.getPair(_token, usdtAddress);
        if(pair == address(0)) return 0;
        uint256 tokenPriceInWETH = getPriceInWETH(_token);
        uint256 wethPriceInUSDT = getLastPrice(   uniswapRouter.WETH(),  usdtAddress );
        return (tokenPriceInWETH * wethPriceInUSDT) / 1e18;
    }

    function getTokenDecimals(   address tokenAddress  ) public view returns (uint8 decimals) {
        IERC20 token = IERC20(tokenAddress);
        return token.decimals();
    }

    function getLastPair() public view returns (address) {
        uint256 numPairs = uniswapFactory.allPairsLength();
        address lastPair = uniswapFactory.allPairs(numPairs - 1);
        return lastPair;
    }

    function hasLiquidity( address _token1,   address _token2  ) public view returns (bool hasliquidity) {
        address pair = IUniswapV2Factory(uniswapFactory).getPair( _token1, _token2  );
        if (pair == address(0))   return false;
        (uint112 reserve1, uint112 reserve2, ) = IUniswapV2Pair(pair).getReserves();
        if (reserve1 == 0 || reserve2 == 0)  return false;
        return true;
    }

    function getTokenLiquidity( address _token1,  address _token2 ) public view returns (uint256 token1, uint256 token2) {
        address pair = uniswapFactory.getPair(_token1, _token2);
        if (pair == address(0)) return (0, 0);
        (uint256 reserve1, uint256 reserve2, ) = IUniswapV2Pair(pair)
            .getReserves();
        if (!hasLiquidity(_token1, _token2)) return (0, 0);
        return (reserve1, reserve2);
    }

    function getTokenFromPair( address pair  ) public view returns (address tokenAddress, bool isValid) {
        address token0 = IUniswapV2Pair(pair).token0();
        address token1 = IUniswapV2Pair(pair).token1();
        address wethAddress = uniswapRouter.WETH();
        if (token0 != wethAddress) return (token0, true);
        else if (token1 != wethAddress) return (token1, true);
        else return (address(0), false);
    }

   function getTokenInfo(address _token) public view returns (TokenInfo memory) {
        IERC20 token = IERC20(_token);
        return TokenInfo({
            name: token.name(),
            symbol: token.symbol(),
            decimals: token.decimals(),
            totalSupply: token.totalSupply()
        });
    }
}
