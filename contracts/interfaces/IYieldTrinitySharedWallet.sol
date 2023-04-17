// SPDX-License-Identifier: MIT

pragma solidity 0.8.0;

interface IYieldTrinitySharedWallet {
    function deposit() external payable;
    function withdraw(uint256 amount) external;
    function borrow(uint256 amount) external;
    function borrowall() external;
    function repay() external payable;
    function ban(address user) external;
    function unban(address user) external;
    function transferOwnership(address payable newOwner) external;
    
    function balanceOf(address _owner) external view returns (uint256);
    function transfer(address _to, uint256 _value) external returns (bool);
    
    // function owner() external view returns (address payable);
    // function totalFunds() external view returns (uint256);
    // function users(uint256) external view returns (address);
    // function usersBeforeBorrow(uint256) external view returns (address);
    // function contribute(address) external view returns (uint256);
    // function ownershipPercentage(address) external view returns (uint256);
    // function bannedUsers(address) external view returns (bool);
    // function whitelistedUsers(address) external view returns (bool);
    // function borrowedAmounts(address) external view returns (uint256);
    // function repaidAmounts(address) external view returns (uint256);
    // function potentialEarn(address) external view returns (uint256);
    // function dilutedEarning(address) external view returns (uint256);
    // function conspectus(address) external view returns (uint256);
    // function epochHistory(uint256) external view returns (uint256);
    // function withdrawalFee() external view returns (uint256);
}