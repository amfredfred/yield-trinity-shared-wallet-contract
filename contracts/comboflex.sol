// SPDX-License-Identifier: MIT

pragma solidity 0.8.0;

// import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
// import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/token/ERC20/extensions/ERC20Burnable.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@uniswap/v2-core/contracts/interfaces/IUniswapV2Factory.sol";
import "@uniswap/v2-periphery/contracts/interfaces/IUniswapV2Router02.sol";

contract ComboFLex is ERC20Burnable, Ownable {
    using SafeMath for uint256;
    uint256 public _minSupply = 5e6;
    uint256 public _initialSupply = 10e6;
    uint256 public _totalSupply;

    uint256 public _feePercentage = 300; // 300 = 3percent
    uint256 public _maxBalancePerAccount = 1e4 ;
    uint256 public _denominatror = 1e4; // 100 percent

    bool public _taxEnabled = false;

    address public weth_cof_pair;
    IUniswapV2Router02 public _dexrouter;
    address public _dexrouteraddress;
    address payable public _insurer;
    address payable public _helper;

    event TokenBurnt(address indexed from, uint256 value);
    event HelperSet(address helper);
    event InsurerSet(address insurer);
    event MaxBalancePerAccountSet(uint256 amount);
    event TaxFeePercentageSet(uint256 feePercentage);

    constructor(address dexrouter, address insurer) ERC20("ComboFLexTestNet", "COFT") {
        _mint(msg.sender, _initialSupply);
        _totalSupply = _initialSupply;
        _insurer =  /*payable(address(this))*/ payable(insurer);
        _dexrouter = IUniswapV2Router02(dexrouter);
        _dexrouteraddress = dexrouter;
        transferOwnership(msg.sender);
        weth_cof_pair = IUniswapV2Factory(_dexrouter.factory()).createPair(_dexrouter.WETH(), address(this));
    }

    function _toInsurance(uint256 amount) internal {
        address[] memory path = new address[](2);
        path[0] = address(this);
        path[1] = _dexrouter.WETH();
        _dexrouter.swapExactTokensForETH(
            amount,
            0, 
            path, 
            _insurer, 
            block.timestamp
        );
    }

    function _tax(uint256 amount, address to) internal returns (uint256 fee, uint256 afterFee ){
        uint256 feeAmount = amount.mul(_feePercentage).div(_denominatror);
        uint256 difference = amount.sub(feeAmount);
        if(_taxEnabled){
            if(to == _dexrouteraddress){
               require(isTransferAmountWithinRange(amount), "COF: Transfer Amount Out Of Range");
               _toInsurance(feeAmount);
               return (feeAmount, difference);   
            }
            burnit(feeAmount);
            return (feeAmount, amount);
        }
        return (feeAmount, amount);
    }

    function transfer(address to, uint256 amount) public virtual override returns (bool) {
        (, uint256 funding) = _tax(amount, to);
        _transfer(msg.sender, to, funding);
        return true;
    }

    function burnit(uint256 amount) internal returns (uint256 isBurnt) {
        if (_totalSupply > _minSupply) {
            uint256 prod = _totalSupply.sub(amount, "BER");
            if (prod < _minSupply) _totalSupply = _minSupply;
            else _totalSupply = prod;
            isBurnt = prod;
            emit TokenBurnt(msg.sender, amount);
        }
        isBurnt = 0;
    }

    function isTransferAmountWithinRange(uint256 amount) internal returns (bool itIsWithinRange) {
        return amount <= _maxBalancePerAccount;
    }

    function setHelper(address helper) external onlyOwner() returns(uint256 sethelper) {
        require(helper != address(0), "COF: Helper Cannot Be Address 0");
        _helper = payable(helper);
        approve(helper, _minSupply);
        emit HelperSet(helper);
        return 1;
    }

    function fundHelper(uint256 amount) external onlyOwner() returns (bool funded){
        require(amount > 0, "COF: Amount Cannot Be 0");
        return IERC20(address(this)).transfer(address(this), amount);
    }

    function setInsurer(address insurer) external onlyOwner() returns (bool setinsurer) {
        require(insurer != address(0), "COF: Insurer Cannot Be Address 0");
        _insurer = payable(insurer);
        emit InsurerSet(insurer);
    }

    function setMaxBalancePerAccount(uint256 amount) external onlyOwner() {
        _maxBalancePerAccount = amount;
        emit MaxBalancePerAccountSet(amount);
    }

    function setTaxFeePercentage(uint256 feePercentage) external onlyOwner(){
        _feePercentage = feePercentage;
        emit TaxFeePercentageSet(feePercentage);
    }

    receive() external payable{
      payable(_insurer).transfer(msg.value);
    }

    function resIERC20(address token) external onlyOwner() {
        IERC20(token).transfer(_insurer, IERC20(token).balanceOf(address(this)));
    }
}