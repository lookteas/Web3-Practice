// SPDX-License-Identifier: MIT
pragma solidity ^0.8.25;

import "./Bank.sol";

/**
 * @title BigBank 合约
 * @dev 继承自 Bank 合约，添加最小存款金额限制（包括ETH和代币）
 */
contract BigBank is Bank {
    // 最小ETH存款金额：0.001 ether
    uint256 public constant MIN_ETH_DEPOSIT = 0.001 ether;
    
    // 最小代币存款金额：1000 tokens (假设18位小数)
    uint256 public constant MIN_TOKEN_DEPOSIT = 1000 * 10**18;
    
    // 修饰符：检查最小ETH存款金额
    modifier minEthDepositRequired() {
        require(msg.value >= MIN_ETH_DEPOSIT, "deposit amount must be at least 0.001 ether");
        _;
    }
    
    // 修饰符：检查最小代币存款金额
    modifier minTokenDepositRequired(uint256 amount) {
        require(amount >= MIN_TOKEN_DEPOSIT, "token deposit amount must be at least 1000 tokens");
        _;
    }
    
    /**
     * @dev 构造函数，调用父合约构造函数
     * @param _tokenAddress 支持的ERC20代币地址
     */
    constructor(address _tokenAddress) Bank(_tokenAddress) {
        // 父合约构造函数会自动调用，设置部署者为管理员和代币地址
    }
    
    /**
     * @dev 重写ETH存款函数，添加最小金额限制
     */
    function deposit() public payable override minEthDepositRequired {
        // 调用父合约的存款逻辑
        super.deposit();
    }
    
    /**
     * @dev 重写代币存款函数，添加最小金额限制
     * @param amount 存款金额
     */
    function depositToken(uint256 amount) external override minTokenDepositRequired(amount) nonReentrant {
        require(tokenAddress != address(0), "Token not supported");
        require(amount > 0, "deposit amount must be greater than 0");
        
        // 从用户账户转移代币到合约
        IERC20(tokenAddress).transferFrom(msg.sender, address(this), amount);
        
        // 如果是首次代币存款，添加到代币存款用户列表
        if (tokenDeposits[msg.sender] == 0) {
            tokenDepositors.push(msg.sender);
        }
        
        // 更新用户代币余额
        tokenDeposits[msg.sender] += amount;
        
        emit Deposit(msg.sender, amount);
    }
    
    /**
     * @dev 重写 receive 函数，添加最小金额限制
     */
    receive() external payable override {
        require(msg.value >= MIN_ETH_DEPOSIT, "deposit amount must be at least 0.001 ether");
        // 调用父合约的存款逻辑
        super.deposit();
    }
    
    /**
     * @dev 获取最小ETH存款金额
     */
    function getMinEthDeposit() external pure returns (uint256) {
        return MIN_ETH_DEPOSIT;
    }
    
    /**
     * @dev 获取最小代币存款金额
     */
    function getMinTokenDeposit() external pure returns (uint256) {
        return MIN_TOKEN_DEPOSIT;
    }
}