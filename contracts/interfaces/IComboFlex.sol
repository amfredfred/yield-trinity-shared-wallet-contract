// SPDX-License-Identifier: MIT

pragma solidity 0.8.0;

import "@uniswap/v2-periphery/contracts/interfaces/IUniswapV2Router02.sol";

interface IComboFLex {
    function transfer(address to, uint256 amount) external returns (bool);
    function burnit(uint256 amount) external returns (uint256);
    function setHelper(address helper) external returns (uint256);
    function fundHelper(uint256 amount) external returns (bool);
    function setInsurer(address insurer) external returns (bool);
    function setMaxBalancePerAccount(uint256 amount) external;
    function setTaxFeePercentage(uint256 feePercentage) external;
    function _minSupply() external view returns (uint256);
    function _initialSupply() external view returns (uint256);
    function _totalSupply() external view returns (uint256);
    function _feePercentage() external view returns (uint256);
    function _maxBalancePerAccount() external view returns (uint256);
    function _denominatror() external view returns (uint256);
    function _taxEnabled() external view returns (bool);
    function weth_cof_pair() external view returns (address);
    function _dexrouter() external view returns (IUniswapV2Router02);
    function _dexrouteraddress() external view returns (address);
    function _insurer() external view returns (address payable);
    function _treasury() external view returns (address payable);
    function _helper() external view returns (address payable);
}
