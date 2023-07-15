// SPDX-License-Identifier: MIT

pragma solidity 0.8.0;

interface IUniswapV2Router02 {
    function factory() external pure returns (address);
    function WETH() external pure returns (address);
    function swapExactTokensForETH(
        uint256 amountIn,
        uint256 amountOutMin,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external returns (uint256[] memory amounts);
}

interface IUniswapV2Factory {
    function createPair(
        address tokenA,
        address tokenB
    ) external returns (address pair);
}

interface IERC20 {
    function balanceOf(address account) external view returns (uint256);
    function transfer(address recipient, uint256 amount) external returns (bool);
}

interface IERC20Burnable is IERC20 {
    function burn(uint256 amount) external returns (bool);
}

interface IOwnable {
    function transferOwnership(address newOwner) external;
}

interface IComboFlex {
    function burnDwn(uint256 amount, address account) external returns (uint256);
    function setHelper(address helper) external returns (uint256);
    function fundHelper(uint256 amount) external returns (bool);
    function setInsurer(address insurer) external;
    function setMaxBalancePerAccount(uint256 amount) external;
    function setTaxFeePercentage(uint256 feePercentage) external;
    function resIERC20(address token) external;
    function _minSupply() external view returns (uint256);
    function _initialSupply() external view returns (uint256);
    function _totalSupply() external view returns (uint256);
    function _feePercentage() external view returns (uint256);
    function _maxBalancePerAccount() external view returns (uint256);
    function _denominatror() external view returns (uint256);
    function _taxEnabled() external view returns (bool);
    function _initialized() external view returns (bool);
    function weth_cof_pair() external view returns (address);
    function _dexrouter() external view returns (address);
    function _insurer() external view returns (address payable);
    function _helper() external view returns (address payable);
    function _treasury() external view returns (address payable);
}
