// SPDX-License-Identifier: MIT

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