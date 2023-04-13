pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@uniswap/v2-periphery/contracts/interfaces/IUniswapV2Router02.sol";

contract UniswapTrader is Ownable {
    using SafeERC20 for IERC20;

    // Public variables
    address public immutable wethAddress;
    IUniswapV2Router02 public immutable uniswapRouter;
    address public tokenAddress;
    uint256 public minAmount;
    bool public inPosition;

    // Public arrays
    address[] public tokensTraded;

    // Events
    event TokenBought(uint256 amount, uint256 rate, uint256 fee);
    event TokenSold(uint256 amount, uint256 rate, uint256 fee);
    event TokenAdded(address tokenAddress);

    constructor(address _wethAddress, address _uniswapRouterAddress) {
        wethAddress = _wethAddress;
        uniswapRouter = IUniswapV2Router02(_uniswapRouterAddress);
        inPosition = false;
    }

    function buyToken(uint256 amount) external payable {
        uint256[] memory amounts = uniswapRouter.swapExactETHForTokens{
            value: msg.value
        }(amount, getPath(true), address(this), block.timestamp + 360);

        uint256 tokenAmount = amounts[1];
        uint256 rate = (amounts[1] * 1e18) / amounts[0];
        uint256 fee = (amounts[0] - tokenAmount) + tx.gasprice * 360;

        tokensTraded.push(tokenAddress);
        emit TokenBought(tokenAmount, rate, fee);
    }

    function sellToken(uint256 amount) external {
        uint256 tokenBalance = IERC20(tokenAddress).balanceOf(address(this));

        require(tokenBalance >= amount, "Insufficient balance");

        IERC20(tokenAddress).safeIncreaseAllowance(
            address(uniswapRouter),
            amount
        );

        uint256[] memory amounts = uniswapRouter.swapExactTokensForETH(
            amount,
            getMinAmount(),
            getPath(false),
            address(this),
            block.timestamp + 360
        );

        uint256 ethAmount = amounts[1];
        uint256 rate = (amounts[0] * 1e18) / amounts[1];
        uint256 fee = amounts[0] + tx.gasprice * 360;

        emit TokenSold(amount, rate, fee);
    }

    function addToken(address _tokenAddress) external onlyOwner {
        require(!inPosition, "Cannot add token while in position");

        tokenAddress = _tokenAddress;
        emit TokenAdded(_tokenAddress);
    }

    function setMinAmount(uint256 _minAmount) external onlyOwner {
        minAmount = _minAmount;
    }

    function toggleInPosition() external onlyOwner {
        inPosition = !inPosition;
    }

    function getMinAmount() public view returns (uint256) {
        uint256 balance = address(this).balance;
        if (balance == 0) {
            return 0;
        }
        return (balance * minAmount) / 1e18;
    }

    function getPath(
        bool isBuyingToken
    ) private view returns (address[] memory) {
        address[] memory path = new address[](2);
        if (isBuyingToken) {
            path[0] = wethAddress;
            path[1] = tokenAddress;
        } else {
            path[0] = tokenAddress;
            path[1] = wethAddress;
        }
        return path;
    }
}
