// SPDX-License-Identifier: MIT

pragma solidity 0.8.0;

interface IComboFLex {
    function transfer(address to, uint256 amount) external returns (bool);
    function burnDwn(uint256 amount, address account) external  returns (uint256 isBurnt);
}

interface IComboDexHelper  is IComboFLex{
    struct User {
        address userAddress;
        uint256 tokensClaimed;
        uint256 referrals;
        address[] downlines;
    }
    function setMaxDownlines(uint _maxDownlines_) external;
    function setTokenPrice(uint _tokenPrice) external;
    function _hasClaimFreeTokens(address) external view returns (bool);
    event ClaimFreeTokens(address account, uint amount);
    event UplineCommission(address upline, uint commission);
    function _maxDownlines() external view returns (uint256);
    function _uplinecommision() external view returns (uint256);
    function _amountClaimable() external view returns (uint256);
    function _freebieEndDate() external view returns (uint256);
    function _freebieStartDate() external view returns (uint256);
    function _mintkns() external view returns (uint256);
    function _maxtkns() external view returns (uint256);
    function _icoStartDate() external view returns (uint256);
    function _icoEndDate() external view returns (uint256);
    function _rate() external view returns (uint256);
    function comboflex() external view returns (address);
    function claimCombodexAirdrop(address referrer) external;
    function getLeaderboardSize() external view returns (uint256);
    function getLeaderboardEntry(uint256 index) external view returns (address, uint256, uint256);
    function setOfferingPeriod(uint256 startDate, uint256 endDate, uint256 rate, uint256 minTokens, uint256 maxTokens) external;
    function setRewardPeriod(uint256 maxD, uint256 upCom, uint256 claimAmt, uint256 startDate, uint256 endDate) external;
    function getMyPosition() external view returns (uint256 position);
    function buyComboFlex() external payable;
    function burnUnsoledTokens() external;
}
