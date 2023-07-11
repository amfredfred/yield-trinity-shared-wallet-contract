// SPDX-License-Identifier: MIT

pragma solidity 0.8.0;
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";

interface IComboFLex {
    function transfer(address to, uint256 amount) external returns (bool);
}


contract ComboDexHelper  is Ownable{
    using SafeMath for uint256;
    uint public maxDownlines = 5e3;
    uint public tokenPrice;
    uint256 public _mintkns = 1e18;
    uint256 public _amountClaimable = 12; 
    uint256 public _uplinecommision = 7;
    uint256 public _aidropEndDate = 3 weeks;

    mapping(address => bool) public _hasClaimFreeTokens;
    mapping(address => uint) public _downlines;
    mapping(address => uint) public _position;
    mapping(address => uint) public _amountClaimed;

    struct User {
        address userAddress;
        uint256 tokensClaimed;
        uint256 referrals;
        address[] downlines;
    }
    mapping(address => User) public leaderboard;
    address[] public leaderboardAddresses;

    IComboFLex public comboflex;

    constructor(address _conboflex) {
        transferOwnership(msg.sender);
        comboflex = IComboFLex(_conboflex);
    }

    event ClaimFreeTokens(address account, uint amount);
    event UplineCommission(address upline, uint commission);

    function _trans(uint256 eth_amount) internal view returns(uint256 tokens, uint256) {
        require(eth_amount >= _mintkns, "Combo Helper: Amount Too Low");

        return (eth_amount.div(tokenPrice), 0);
    }

    function setMaxDownlines(uint _maxDownlines) public onlyOwner {
        maxDownlines = _maxDownlines;
    }

    function setTokenPrice(uint _tokenPrice) public onlyOwner {
        tokenPrice = _tokenPrice;
    }

    function claimCombodexAirdrop(address referrer) external {
        address account = msg.sender;
        require(!_hasClaimFreeTokens[account], "Combo Helper: Acount Has Already Claim");
        require(_aidropEndDate >= block.timestamp, "Combo Helper: Airdrop Has Ended, Wait For Next Badge");
        _hasClaimFreeTokens[account] = true;
        leaderboard[account].tokensClaimed = _amountClaimable;
        if (referrer != address(0)) {
            if(leaderboard[referrer].referrals < maxDownlines){
                leaderboard[referrer].referrals += 1;
                uint256 referrerIndex = getUserIndex(referrer);
                leaderboard[referrer].downlines.push(account);
                if (referrerIndex > 0) {
                    uint256 previousReferrerIndex = referrerIndex - 1;
                    address previousReferrer = leaderboardAddresses[previousReferrerIndex];
                    if (leaderboard[referrer].referrals > leaderboard[previousReferrer].referrals) {
                        (leaderboardAddresses[previousReferrerIndex], leaderboardAddresses[referrerIndex]) = (referrer, previousReferrer);
                    }
                }
                comboflex.transfer(referrer, _uplinecommision);
                emit UplineCommission(referrer, _uplinecommision);
            }
        }
        
        // If the user is not already in the leaderboard, add them
        if (leaderboard[account].userAddress == address(0)) {
            leaderboardAddresses.push(account);
            leaderboard[account].userAddress = account;
        }

        comboflex.transfer(account, _amountClaimable);
        emit ClaimFreeTokens(account, _amountClaimable);
    }

    function getLeaderboardSize() external view returns (uint256) {
        return leaderboardAddresses.length;
    }

    function getLeaderboardEntry(uint256 index) external view returns (address, uint256, uint256) {
        require(index < leaderboardAddresses.length, "Invalid leaderboard index");
        address userAddress = leaderboardAddresses[index];
        uint256 tokensClaimed = leaderboard[userAddress].tokensClaimed;
        uint256 referrals = leaderboard[userAddress].referrals;
        return (userAddress, tokensClaimed, referrals);
    }

    function getUserIndex(address userAddress) internal view returns (uint256) {
        for (uint256 i = 0; i < leaderboardAddresses.length; i++) {
            if (leaderboardAddresses[i] == userAddress) {
                return i;
            }
        }
        return leaderboardAddresses.length;
    }

}
