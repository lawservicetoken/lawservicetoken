// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

/**
 * @title LAW SERVICE TOKEN (LST) - GitHub Public Version
 * @notice This is a combined contract including LST token and its presale logic.
 * All sensitive wallet addresses have been removed. Use constructor arguments during deployment.
 */

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

// ------------------------------
// LSTToken Contract
// ------------------------------
contract LSTToken is ERC20, Ownable {
    uint8 private constant DECIMALS = 8;
    uint256 private constant INITIAL_SUPPLY = 1_000_000_000 * (10 ** DECIMALS);

    address public teamWallet;
    address public investorWallet;
    address public rewardWallet;
    address public liquidityWallet;

    constructor(
        address _teamWallet,
        address _investorWallet,
        address _rewardWallet,
        address _liquidityWallet
    ) ERC20("Law Service Token", "LST") {
        require(_teamWallet != address(0), "Invalid team wallet");
        require(_investorWallet != address(0), "Invalid investor wallet");
        require(_rewardWallet != address(0), "Invalid reward wallet");
        require(_liquidityWallet != address(0), "Invalid liquidity wallet");

        teamWallet = _teamWallet;
        investorWallet = _investorWallet;
        rewardWallet = _rewardWallet;
        liquidityWallet = _liquidityWallet;

        uint256 unit = INITIAL_SUPPLY / 100;

        _mint(teamWallet, unit * 40);       // 40%
        _mint(investorWallet, unit * 10);   // 10%
        _mint(rewardWallet, unit * 5);      // 5%
        _mint(liquidityWallet, unit * 45);  // 45%
    }

    function decimals() public view virtual override returns (uint8) {
        return DECIMALS;
    }
}

// ------------------------------
// LSTPresale Contract
// ------------------------------
interface IERC20 {
    function transferFrom(address from, address to, uint256 value) external returns (bool);
    function transfer(address to, uint256 value) external returns (bool);
    function decimals() external view returns (uint8);
}

contract LSTPresale is Ownable {
    IERC20 public usdt;
    LSTToken public lst;
    address public wallet;
    uint256 public rate; // e.g., 4 = 1 USDT = 4 LST

    event TokensPurchased(address indexed purchaser, uint256 usdtAmount, uint256 lstAmount);

    constructor(
        address _usdt,
        address _lst,
        address _wallet,
        uint256 _rate
    ) {
        require(_usdt != address(0), "Invalid USDT address");
        require(_lst != address(0), "Invalid LST address");
        require(_wallet != address(0), "Invalid wallet address");
        require(_rate > 0, "Rate must be positive");

        usdt = IERC20(_usdt);
        lst = LSTToken(_lst);
        wallet = _wallet;
        rate = _rate;
    }

    function buyTokens(uint256 lstAmountGwei) external {
        require(lstAmountGwei > 0, "Amount must be > 0");

        uint256 lstDecimals = lst.decimals();
        uint256 usdtDecimals = usdt.decimals();

        // lstAmountGwei is in gwei (1e8), convert to base
        uint256 usdtAmount = (lstAmountGwei * (10 ** usdtDecimals)) / rate / (10 ** lstDecimals);

        require(usdt.transferFrom(msg.sender, wallet, usdtAmount), "USDT transfer failed");
        require(lst.transfer(msg.sender, lstAmountGwei), "LST transfer failed");

        emit TokensPurchased(msg.sender, usdtAmount, lstAmountGwei);
    }
