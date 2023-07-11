// SPDX-License-Identifier: MIT

pragma solidity 0.8.0;
import "@openzeppelin/contracts/access/Ownable.sol";


contract ComboDexHelper  is Ownable{
    uint public maxDownlines;
    uint public tokenPrice;
    mapping(address => uint) public airdrops;

    constructor(uint _maxDownlines, uint _tokenPrice) {
        transferOwnership(msg.sender);
        maxDownlines = _maxDownlines;
        tokenPrice = _tokenPrice;
    }


    function setMaxDownlines(uint _maxDownlines) public onlyOwner {
        maxDownlines = _maxDownlines;
    }

    function setTokenPrice(uint _tokenPrice) public onlyOwner {
        tokenPrice = _tokenPrice;
    }

    function buyTokens() public payable {
        uint tokenAmount = msg.value / tokenPrice;
        require(tokenAmount > 0, "Insufficient funds to purchase tokens.");
        airdrops[msg.sender] += tokenAmount;
    }
}
