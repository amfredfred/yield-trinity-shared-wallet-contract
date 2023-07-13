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
    function setMaxDownlines(uint _maxDownlines) external;
    function setTokenPrice(uint _tokenPrice) external;
    function claimCombodexAirdrop(address referrer) external;
    function getLeaderboardSize() external view returns (uint256);
    function getLeaderboardEntry(uint256 index) external view returns (address, uint256, uint256);
    function _hasClaimFreeTokens(address) external view returns (bool);
    event ClaimFreeTokens(address account, uint amount);
    event UplineCommission(address upline, uint commission);
}
