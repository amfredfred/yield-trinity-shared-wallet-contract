// SPDX-License-Identifier: MIT
 
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "@uniswap/v2-core/";

contract IYieldTrinityDicoverer {
    IUniswapV2Factory uniswapFactory;
    IUniswapV2Router02 uniswapRouter;
    address public usdtAddress;

    using SafeMath for uint256;

    struct TokenInfo {
        string name;
        string symbol;
        uint256 decimals;
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

    function getCurrentQuoteByInput( address _token1,   address _token2, uint256 _amount) public  view returns (uint256  currentPrice) {
        if(!(hasLiquidity(_token1, _token2))) return 0; 
        (uint256 reserve0, uint256 reserve1) = getTokensLiquidity(_token1, _token2);
        uint256 _cp = uniswapRouter.quote(_amount, reserve0, reserve1); 
        return _cp;
    }

    function getCurrentQuote( address _token1,   address _token2) public  view returns (uint256  currentPrice) {
        if(!(hasLiquidity(_token1, _token2))) return 0; 
        (uint256 reserve0, uint256 reserve1) = getTokensLiquidity(_token1, _token2);
        uint256 _cp = uniswapRouter.quote(10 ** IERC20(_token1).decimals(), reserve0, reserve1); 
        return _cp;
    }

    function getLastPrice(  address _token1,   address _token2  ) public view returns (uint256 lastRate) {
        address[] memory path = new address[](2);
        path[0] = _token1;
        path[1] = _token2;
        if(!hasLiquidity(_token1, _token2)) return 0;
        uint256[] memory amounts = uniswapRouter.getAmountsOut(   10 ** IERC20(_token1).decimals(),  path  );
        return amounts[1];
    }

    function getTokenPriceInWETH( address _token  ) public view returns (uint256 priceInWETH) {
        address wethAddress = uniswapRouter.WETH();
        uint256 _cp = getCurrentQuote(_token, wethAddress);
        return _cp;
    }

    function getTokenPriceInUSDT(  address _token  ) public view returns (uint256 priceInUSDT) {
        address pair = getPairAddress(_token, usdtAddress);
        if(pair == address(0)) return 0;
        uint256 tokenPriceInWETH = getTokenPriceInWETH(_token);
        uint256 wethPriceInUSDT = getCurrentQuote(   uniswapRouter.WETH(),  usdtAddress );
        return (tokenPriceInWETH * wethPriceInUSDT) / 1e18;
    }

    function getLastPair() public view returns (address pair) {
        uint256 numPairs = uniswapFactory.allPairsLength();
        address lastPair = uniswapFactory.allPairs(numPairs - 1);
        return lastPair;
    }

    function hasLiquidity( address _token1,   address _token2  ) public view returns (bool hasliquidity) {
        address pair = getPairAddress( _token1, _token2  );
        if (pair == address(0))   return false;
        (uint112 reserve1, uint112 reserve2, ) = IUniswapV2Pair(pair).getReserves();
        if (reserve1 == 0 || reserve2 == 0)  return false;
        return true;
    }

    function getTokensLiquidity( address _token1,  address _token2 ) public view returns (uint256 token1, uint256 token2) {
        address pair = getPairAddress( _token1, _token2 );
        if (pair == address(0)) return (0, 0);
        (uint256 reserve1, uint256 reserve2, ) = IUniswapV2Pair(pair).getReserves();
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

    function getPairAddress(address token1, address token2) public view returns (address) {
        address pair = uniswapFactory.getPair(token1, token2);
        return pair;
    }

    function getTokenPairReserves(address pairAddress) public  view returns (uint256 token0Reserve, uint256 reserve1Reserve) {
        (address token0, address token1) = getTokensFromPair(pairAddress);
        (uint256 reserve0, uint256 reserve1, ) = IUniswapV2Pair(pairAddress).getReserves();
        IERC20 tokenOne = IERC20(token0);
        IERC20 tokenTwo = IERC20(token1);

        if (tokenOne.decimals() < tokenTwo.decimals()) {
            reserve0 = reserve0.mul(10**(tokenTwo.decimals() - tokenOne.decimals()));
        } else if (tokenTwo.decimals() < tokenOne.decimals()) {
            reserve1 = reserve1.mul(10**(tokenOne.decimals() - tokenTwo.decimals()));
        }
        return (reserve0, reserve1);
    }

    function getTokensFromPair(address pairAddress) public  view returns (address token0, address token1) {
        IUniswapV2Pair pair = IUniswapV2Pair(pairAddress);
        return (pair.token0(), pair.token1());
    }
}
