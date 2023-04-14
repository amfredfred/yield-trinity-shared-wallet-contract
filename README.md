
THE YieldTrinityDicoverer Solidity Contract
This is a contract for a price oracle that retrieves the price of tokens using the Uniswap decentralized exchange. It has several functions that allow you to retrieve the price of a token in terms of WETH or USDT, get the last price of a token pair, and check if a token pair has liquidity.

The contract imports the SafeMath library from OpenZeppelin and several interfaces from the Uniswap contracts, including IUniswapV2Router02, IUniswapV2Pair, IUniswapV2Factory, and IERC20.

The PriceOracle contract constructor takes three parameters: the address of the Uniswap factory contract, the address of the Uniswap router contract, and the address of the USDT token contract.

The getLastPrice function takes two parameters: the addresses of two tokens and returns the last price of the token pair. If the pair does not have liquidity, the function returns 0.

The getTokenPriceInWETH function takes the address of a token and returns the price of the token in terms of WETH. If the pair does not have liquidity, the function returns 0.

The getTokenPriceInUSDT function takes the address of a token and returns the price of the token in terms of USDT. It first retrieves the price of WETH in USDT and then multiplies the price of the token in WETH by the price of WETH in USDT. If the pair does not have liquidity, the function returns 0.

The getTokenDecimals function takes the address of a token and returns the number of decimals for the token.

The getLastPair function returns the address of the last pair created in the Uniswap factory.

The hasLiquidity function takes the addresses of two tokens and returns whether the pair has liquidity.

The getTokensLiquidity function takes the addresses of two tokens and returns the amount of liquidity for each token in the pair.

The getTokenFromPair function takes the address of a pair and returns the address of the token that is not WETH and a boolean indicating whether the pair is valid.