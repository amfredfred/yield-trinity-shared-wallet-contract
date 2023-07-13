// SPDX-License-Identifier: MIT

pragma solidity 0.8.0;
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";

interface IComboFLex {
    function transfer(address to, uint256 amount) external returns (bool);

    function _treasury() external view returns (address payable);

    function burnit(uint256 amount) external returns (uint256);

    function balanceOf(address account) external view returns (uint256);

    function burnDwn(uint256 amount, address account) external  returns (uint256 isBurnt);
}

contract ComboDexHelper is Ownable {
    using SafeMath for uint256;

    uint256 public _maxDownlines = 5e3;
    uint256 public _uplinecommision = 7e18;
    uint256 public _amountClaimable = 12e18;
    uint256 public _freebieEndDate;
    uint256 public _freebieStartDate;

    uint256 public _mintkns = 1e18;
    uint256 public _maxtkns = 5e4;
    uint256 public _icoStartDate;
    uint256 public _icoEndDate;
    uint256 public _rate;

    struct User {
        address userAddress;
        uint256 tokensClaimed;
        uint256 referrals;
        address[] downlines;
        uint256 claimTIme;
        uint256[] entryTimes;
        uint256 tokensBought;
        uint256 ethContribution;
    }

    mapping(address => User) public leaderboard;
    address[] public leaderboardAddresses;

    address public comboflex;

    constructor(address _conboflex) {
        transferOwnership(msg.sender);
        comboflex = _conboflex;
        _freebieEndDate = block.timestamp + 3 weeks;
    }

    event ClaimFreeTokens(address account, uint amount);
    event UplineCommission(address upline, uint commission);
    event BoughtComboFlex(address account, uint amount);

    function _trans(
        uint256 eth_amount
    ) public view returns (uint256 tokens, uint256) {
        uint256 buyableAmount = eth_amount.div(_rate);
        require(buyableAmount >= _mintkns, "Combo Helper: Amount Too Low");

        return (buyableAmount, 0);
    }

    function claimCombodexAirdrop(address referrer) external {
        address account = msg.sender;
        require(
            leaderboard[account].userAddress == address(0),
            "You Claim The Free Tokens"
        );
        require(
            _freebieEndDate >= _freebieStartDate,
            "Combo Helper: Airdrop Has Ended, Wait For Next Badge"
        );
        leaderboard[account].tokensClaimed = _amountClaimable;
        if (referrer != address(0)) {
            if (leaderboard[referrer].userAddress != address(0))
                if (leaderboard[referrer].referrals < _maxDownlines) {
                    leaderboard[referrer].referrals += 1;
                    uint256 referrerIndex = getUserIndex(referrer);
                    leaderboard[referrer].downlines.push(account);
                    if (referrerIndex > 0) {
                        uint256 previousReferrerIndex = referrerIndex - 1;
                        address previousReferrer = leaderboardAddresses[
                            previousReferrerIndex
                        ];
                        if (
                            leaderboard[referrer].referrals >
                            leaderboard[previousReferrer].referrals
                        ) {
                            (
                                leaderboardAddresses[previousReferrerIndex],
                                leaderboardAddresses[referrerIndex]
                            ) = (referrer, previousReferrer);
                        }
                    }
                    IComboFLex(comboflex).transfer(referrer, _uplinecommision);
                    emit UplineCommission(referrer, _uplinecommision);
                }
        }

        // If the user is not already in the leaderboard, add them
        if (leaderboard[account].userAddress == address(0)) {
            leaderboardAddresses.push(account);
            leaderboard[account].userAddress = account;
            leaderboard[account].claimTIme = block.timestamp;
        }

        IComboFLex(comboflex).transfer(account, _amountClaimable);
        emit ClaimFreeTokens(account, _amountClaimable);
    }

    function getLeaderboardSize() external view returns (uint256) {
        return leaderboardAddresses.length;
    }

    function getLeaderboardEntry(
        uint256 index
    ) external view returns (address, uint256, uint256) {
        require(
            index < leaderboardAddresses.length,
            "Invalid leaderboard index"
        );
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

    function setOfferingPeriod(
        uint256 startDate,
        uint256 endDate,
        uint256 rate,
        uint256 minTokens,
        uint256 maxTokens
    ) external onlyOwner {
        _rate = rate > 0 ? rate : _rate;
        _icoEndDate = endDate > 0 ? endDate : _icoEndDate;
        _icoStartDate = startDate > 0 ? startDate : _icoStartDate;
        _mintkns = minTokens > 0 ? minTokens : _mintkns;
        _maxtkns = maxTokens > 0 ? maxTokens : _maxtkns;
    }

    function setRewardPeriod(
        uint256 maxD,
        uint256 upCom,
        uint256 claimAmt,
        uint256 startDate,
        uint256 endDate
    ) external onlyOwner {
        _maxDownlines = maxD > 0 ? maxD : _maxDownlines;
        _uplinecommision = upCom > 0 ? upCom : _uplinecommision;
        _amountClaimable = claimAmt > 0 ? claimAmt : _amountClaimable;
        _freebieEndDate = endDate > 0 ? endDate : _freebieEndDate;
        _freebieStartDate = startDate > 0 ? startDate : _freebieStartDate;
    }

    function buyComboFlex() external payable {
        address account = msg.sender;
        uint256 eth_value = msg.value;
        require(
            leaderboard[account].tokensBought < _maxtkns,
            "You Have Reach Your Buy Limit"
        );
        (uint256 purchased, ) = _trans(eth_value);
        IComboFLex(comboflex).transfer(account, purchased); 
        emit BoughtComboFlex(account, purchased);
    }

    function burnUnsoledTokens() external onlyOwner {
        IComboFLex(comboflex).burnDwn(IComboFLex(comboflex).balanceOf(address(this)), address(this));
    }

    receive() external payable   {
         (bool sent,) = payable(comboflex).call{value: address(this).balance}("");
         require(sent, "Failed Receive");
    }

    fallback () external payable {
        (bool sent,) = payable(comboflex).call{value: address(this).balance}("");
        require(sent, "Failed Fallback");
    }
}
