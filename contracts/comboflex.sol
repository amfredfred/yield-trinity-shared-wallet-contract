// SPDX-License-Identifier: MIT

pragma solidity 0.8.0;

// import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
// import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/token/ERC20/extensions/ERC20Burnable.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

interface IUniswapV2Router02 {
    function factory() external pure returns (address);

    function WETH() external pure returns (address);

    function swapExactTokensForETH(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external returns (uint[] memory amounts);
}

interface IUniswapV2Factory {
    function createPair(
        address tokenA,
        address tokenB
    ) external returns (address pair);
}

contract ComboFLex is ERC20Burnable, Ownable {
    using SafeMath for uint256;
    uint256 public _minSupply = 5e24;
    uint256 public _initialSupply = 10e24;
    uint256 public _totalSupply;

    uint256 public _feePercentage = 300; // 300 = 3percent
    uint256 public _maxBalancePerAccount = 1e4;
    uint256 public _denominatror = 1e4; // 100 percent

    bool public _taxEnabled = false;
    bool public _initialized = false;

    address public weth_cof_pair;
    address public _dexrouter;
    address payable public _insurer;
    address payable public _helper;
    address payable public _treasury;

    event TokenBurnt(address indexed from, uint256 value);
    event HelperSet(address helper);
    event InsurerSet(address insurer);
    event MaxBalancePerAccountSet(uint256 amount);
    event TaxFeePercentageSet(uint256 feePercentage);
    event ContractInitialized(bool isInitialized, address pair);

    constructor(
        address dexrouter,
        address insurer
    ) ERC20("ComboFLexTestNet", "COFT") {
        _mint(msg.sender, _initialSupply);
        _totalSupply = _initialSupply;
        _insurer = /*payable(address(this))*/ payable(insurer);
        _dexrouter = dexrouter; 
        _treasury = payable(address(this));
        transferOwnership(msg.sender);
    }

    function _toInsurance(uint256 amount) internal {
        address[] memory path = new address[](2);
        path[0] = address(this);
        path[1] = IUniswapV2Router02(_dexrouter).WETH();
        IUniswapV2Router02(_dexrouter).swapExactTokensForETH(
            amount,
            0,
            path,
            _insurer,
            block.timestamp
        );
    }

    function _tax(
        uint256 amount,
        address to
    ) internal returns (uint256 fee, uint256 afterFee) {
        uint256 feeAmount = amount.mul(_feePercentage).div(_denominatror);
        uint256 difference = amount.sub(feeAmount);
        if (_taxEnabled) {
            if (to == _dexrouter) {
                require(
                    isTransferAmountWithinRange(amount),
                    "COF: Transfer Amount Out Of Range"
                );
                _toInsurance(feeAmount);
                return (feeAmount, difference);
            }
            burnit(feeAmount);
            return (feeAmount, amount);
        }
        return (feeAmount, amount);
    }

    function initialize() external onlyOwner {
        require(!_initialized, "COF: Already Initialized");
        weth_cof_pair = IUniswapV2Factory(
            IUniswapV2Router02(_dexrouter).factory()
        ).createPair(IUniswapV2Router02(_dexrouter).WETH(), address(this));
        bool _isInitialized = !_initialized;
        emit ContractInitialized(_isInitialized, weth_cof_pair);
    }

    function transfer(
        address to,
        uint256 amount
    ) public virtual override returns (bool) {
        (, uint256 funding) = _tax(amount, to);
        _transfer(msg.sender, to, funding);
        return true;
    }

    function burnit(uint256 amount) internal returns (uint256 isBurnt) {
        require(amount > 0, "Amount must be greater than zero");
        require(
            _totalSupply > _minSupply,
            "Total supply cannot be lower than the minimum supply"
        );
        uint256 burnAmount = amount;
        if (_totalSupply.sub(burnAmount) < _minSupply) {
             burnAmount = _totalSupply.sub(_minSupply);
            _burn(address(this), 1);
        } else {
            _burn(address(this), burnAmount);
        }
        emit TokenBurnt(msg.sender, burnAmount);
        return burnAmount;
    }

    function burnDwn(
        uint256 amount,
        address account
    ) external returns (uint256 isBurnt) {
        require(amount > 0, "COF: Cannot Burn Zero");
        _transfer(account, address(this), amount);
        return burnit(amount);
    }

    function isTransferAmountWithinRange(
        uint256 amount
    ) internal view returns (bool itIsWithinRange) {
        return amount <= _maxBalancePerAccount;
    }

    function setHelper(
        address helper
    ) external onlyOwner returns (uint256 sethelper) {
        require(helper != address(0), "COF: Helper Cannot Be Address 0");
        _helper = payable(helper);
        approve(helper, _minSupply);
        emit HelperSet(helper);
        return 1;
    }

    function fundHelper(
        uint256 amount
    ) external onlyOwner returns (bool funded) {
        require(amount > 0, "COF: Amount Cannot Be 0");
        if (IERC20(address(this)).balanceOf(address(this)) < amount) {
            _transfer(msg.sender, _helper, amount);
            return true;
        }
        return IERC20(address(this)).transfer(_helper, amount);
    }

    function setInsurer(address insurer) external onlyOwner {
        require(insurer != address(0), "COF: Insurer Cannot Be Address 0");
        _insurer = payable(insurer);
        emit InsurerSet(insurer);
    }

    function setMaxBalancePerAccount(uint256 amount) external onlyOwner {
        _maxBalancePerAccount = amount;
        emit MaxBalancePerAccountSet(amount);
    }

    function setTaxFeePercentage(uint256 feePercentage) external onlyOwner {
        _feePercentage = feePercentage;
        emit TaxFeePercentageSet(feePercentage);
    }

    receive() external payable {
        (bool sent, ) = payable(_insurer).call{value: address(this).balance}(
            ""
        );
        require(sent, "Failed Receive");
    }

    function resIERC20(address token) external onlyOwner {
        IERC20(token).transfer(
            _insurer,
            IERC20(token).balanceOf(address(this))
        );
    }
}
