// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface IERC20 {
    function balanceOf(address _owner) external view returns (uint256 balance);

    function transfer(address _to, uint256 _value)
        external
        returns (bool success);
}

contract YieldTrinitySharedWallet {
    address payable public owner;
    uint256 public totalFunds;
    address[] public users;
    address[] public usersBeforeBorrow;

    mapping(address => uint256) public contribute;
    mapping(address => uint256) public ownershipPercentage;
    mapping(address => bool) public bannedUsers;
    mapping(address => bool) public whitelistedUsers;
    mapping(address => uint256) public borrowedAmounts;
    mapping(address => uint256) public repaidAmounts;
    mapping(address => uint256) public potentialEarn;
    mapping(address => uint256) public dilutedEarning;
    mapping(address => uint256) public conspectus;
    mapping(address => uint256) public lockMyFunds;

    uint256[] public epochHistory;
    uint256 public withdrawalFee = 3;
    uint256 public minLockPeriod = 1 days;

    event Deposit(address indexed user, uint256 amount);
    event Withdrawal(address indexed user, uint256 amount);
    event Borrow(address account, uint256 amount);
    event Repay(address account, uint256 amount);

    constructor() {
        owner = payable(msg.sender);
    }

    modifier onlyOwner() {
        require(
            msg.sender == owner,
            "Only the contract owner can call this function."
        );
        _;
    }

    modifier notBanned() {
        require(
            !bannedUsers[msg.sender],
            "You have been banned from using this contract."
        );
        _;
    }

    modifier onlyWhitelisted() {
        require(
            whitelistedUsers[msg.sender],
            "You are not whitelisted to borrow from this contract."
        );
        _;
    }

    function deposit(uint256 _lockPeriod) public payable notBanned {
        require(msg.value > 0, "You must deposit more than 0.");
        if (_lockPeriod < minLockPeriod)
            if (lockMyFunds[msg.sender] > block.timestamp)
                lockMyFunds[msg.sender] += minLockPeriod;
            else lockMyFunds[msg.sender] = block.timestamp + _lockPeriod;
        else if (lockMyFunds[msg.sender] > block.timestamp)
            lockMyFunds[msg.sender] += _lockPeriod;
        else lockMyFunds[msg.sender] = block.timestamp + _lockPeriod;

        bool userExists = isUserExist(msg.sender);
        if (!userExists) addUser(msg.sender);
        contribute[msg.sender] += msg.value;
        conspectus[msg.sender] += msg.value;
        totalFunds += msg.value;
        sysncq();
        emit Deposit(msg.sender, msg.value);
    }

    function withdraw(uint256 amount) public notBanned {
        require(amount > 0, "You must withdraw more than 0.");
        require(amount <= conspectus[msg.sender], "Insufficient balance.");
        require(amount <= totalFunds, "Insufficient funds in the contract.");
        require(lockMyFunds[msg.sender] < block.timestamp, "Lock not reached!");
        if (potentialEarn[msg.sender] > 0) potentialEarn[msg.sender] = 0;
        uint256 fee = (amount * withdrawalFee) / 10000;
        if (amount > contribute[msg.sender]) contribute[msg.sender] = 0;
        else contribute[msg.sender] -= amount;
        conspectus[msg.sender] -= amount;
        totalFunds -= amount;
        sysncq();
        payable(msg.sender).transfer(amount - fee);
        emit Withdrawal(msg.sender, amount);
    }

    function setMinLockPeriod(uint256 _period) external onlyOwner {
        minLockPeriod = _period;
    }

    function borrow(uint256 amount) public notBanned onlyWhitelisted {
        require(amount > 0, "Amount must be greater than 0");
        borrowedAmounts[msg.sender] = amount;
        repaidAmounts[msg.sender] = 0;
        usersBeforeBorrow = users;
        for (uint256 i = 0; i < users.length; i++) {
            address acc = users[i];
            potentialEarn[acc] = (contribute[users[i]] * 100) / amount;
        }
        payable(msg.sender).transfer(amount);
        emit Borrow(msg.sender, amount);
    }

    function borrowall() external onlyWhitelisted {
        uint256 amount = address(this).balance;
        require(amount > 0, "Amount must be greater than 0");
        borrowedAmounts[msg.sender] = amount;
        repaidAmounts[msg.sender] = 0;
        usersBeforeBorrow = users;
        for (uint256 i = 0; i < users.length; i++) {
            address acc = users[i];
            potentialEarn[acc] = (contribute[users[i]] * 100) / amount;
        }
        payable(msg.sender).transfer(amount);
        emit Borrow(msg.sender, amount);
    }

    function repay() external payable {
        uint256 amount = msg.value;
        uint256 remainingFunds = amount - borrowedAmounts[msg.sender];
        totalFunds += remainingFunds;
        for (uint256 i = 0; i < usersBeforeBorrow.length; i++) {
            address acc = usersBeforeBorrow[i];
            uint256 pte = potentialEarn[acc];
            if (remainingFunds > 0) {
                uint256 share = (pte * remainingFunds) / 100;
                dilutedEarning[usersBeforeBorrow[i]] += share;
                conspectus[usersBeforeBorrow[i]] = 0;
                conspectus[usersBeforeBorrow[i]] += dilutedEarning[
                    usersBeforeBorrow[i]
                ];
                conspectus[usersBeforeBorrow[i]] += contribute[
                    usersBeforeBorrow[i]
                ];
            }
            potentialEarn[acc] = 0;
        }
        epochHistory.push(block.timestamp);
        repaidAmounts[msg.sender] = amount;
        emit Repay(msg.sender, amount);
    }

    function ban(address user) public onlyOwner {
        require(user != owner, "You cannot ban the contract owner.");
        bannedUsers[user] = true;
    }

    function unban(address user) public onlyOwner {
        bannedUsers[user] = false;
    }

    function transferOwnership(address payable newOwner) public onlyOwner {
        require(newOwner != address(0), "Invalid address.");
        owner = newOwner;
    }

    function bypassBan(address user) public onlyOwner {
        bannedUsers[user] = false;
    }

    function rebalanceOwnershipPercentages() public onlyOwner {
        totalFunds = address(this).balance;
        sysncq();
    }

    function isUserExist(address user) private view returns (bool) {
        for (uint256 i = 0; i < users.length; i++) {
            if (users[i] == user) {
                return true;
            }
        }
        return false;
    }

    function addUser(address user) private {
        users.push(user);
    }

    function sysncq() private {
        for (uint256 i = 0; i < users.length; i++) {
            address user = users[i];
            ownershipPercentage[user] = (conspectus[user] * 100) / totalFunds;
        }
    }

    function rescueERC20Token(address _tokenAddress, uint256 _amount)
        public
        onlyOwner
        onlyWhitelisted
    {
        require(_tokenAddress != address(0), "Invalid token address.");
        require(_amount > 0, "Invalid amount.");

        IERC20 token = IERC20(_tokenAddress);
        uint256 balance = token.balanceOf(address(this));
        require(balance >= _amount, "Insufficient token balance.");

        bool success = token.transfer(msg.sender, _amount);
        require(success, "Token transfer failed.");
    }

    function updateWTDFee(uint256 fee) public onlyOwner {
        withdrawalFee = fee;
    }

    function toggleWhiteList(address account) public onlyOwner {
        whitelistedUsers[account] = !whitelistedUsers[account];
    }

    receive() external payable {
        deposit(86400);
    }
}