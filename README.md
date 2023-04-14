
THE YieldTrinityDicoverer Solidity Contract
This is a contract for a price oracle that retrieves the price of tokens using the Uniswap decentralized exchange. 
It has several functions that allow you to retrieve the price of a token in terms of WETH or USDT, get the last price of a token pair, and check if a token pair has liquidity.

THE YieldTrinityDicoverer INTERFACE
==================================== 
pragma solidity >=0.6.0 <0.9.0;
interface IYieldTrinityDicoverer {
    struct TokenInfo {
        string name;
        string symbol;
        uint256 decimals;
        uint256 totalSupply;
    }

    function getCurrentQuoteByInput(address _token1, address _token2, uint256 _amount) external view returns (uint256);
    function getCurrentQuote(address _token1, address _token2) external view returns (uint256);
    function getLastPrice(address _token1, address _token2) external view returns (uint256);
    function getTokenPriceInWETH(address _token) external view returns (uint256);
    function getTokenPriceInUSDT(address _token) external view returns (uint256);
    function getLastPair() external view returns (address); 
    function hasLiquidity(address _token1, address _token2) external view returns (bool);
    function getTokensLiquidity(address _token1, address _token2) external view returns (uint256, uint256);
    function getTokenFromPair(address pair) external view returns (address, bool);
    function getTokenInfo(address _token) external view returns (TokenInfo memory);
    function getPairAddress(address token1, address token2) external view returns (address);
}
====================================

constructor: The contract constructor takes three arguments - the address of the UniswapV2Factory contract, the address of the UniswapV2Router02 contract, and the address of the USDT token. These addresses are used to set the uniswapFactory, uniswapRouter, and usdtAddress variables.

getCurrentQuoteByInput: This function takes in the addresses of two tokens and an amount of the first token, and returns the current price of the second token in terms of the first token.

getCurrentQuote: This function takes in the addresses of two tokens and returns the current price of the second token in terms of the first token, using a default input amount of 10 to the power of the first token's decimals.

getLastPrice: This function takes in the addresses of two tokens and returns the last known price of the second token in terms of the first token, as obtained from the UniswapV2Router02 contract.

getTokenPriceInWETH: This function takes in the address of a token and returns its current price in terms of Wrapped Ether (WETH).

getTokenPriceInUSDT: This function takes in the address of a token and returns its current price in terms of USDT.

getLastPair: This function returns the address of the last UniswapV2Pair contract created by the UniswapV2Factory contract.

hasLiquidity: This function takes in the addresses of two tokens and returns a boolean value indicating whether or not there is liquidity available for trading between the two tokens.

getTokensLiquidity: This function takes in the addresses of two tokens and returns the amount of each token that is currently locked in a liquidity pool for trading with the other token.

getTokenFromPair: This function takes in the address of a UniswapV2Pair contract and returns the address of the token that is not Wrapped Ether, along with a boolean value indicating whether or not the pair is valid.

getTokenInfo: This function takes in the address of a token and returns a TokenInfo struct containing its name, symbol, decimals, and total supply.

getPairAddress: This function takes in the addresses of two tokens and returns the address of the UniswapV2Pair contract that allows for trading between them.