// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "./ExpendERC20.sol"; // 引入 BaseERC20 合约

contract TokenBank {
    BaseERC20 public token; // 引用 BaseERC20 合约实例
    
    // 每个地址的存款余额
    mapping(address => uint256) public deposits;

    // 构造函数，需要传入 BaseERC20 合约地址
    constructor(address _tokenAddress) {
        require(_tokenAddress != address(0), "Token address cannot be zero");
        token = BaseERC20(_tokenAddress);
    }

    /**
     * 存款函数
     * 用户需要先 TokenBank 合约，然后调用此函数
     */
    function deposit(uint256 amount) external {
        require(amount > 0, "Deposit amount must be greater than 0");
        
        // 从用户账户转移 token 到 TokenBank 合约，请求token合约的transferFrom 成功返回true
        require(
            token.transferFrom(msg.sender, address(this), amount),
            "Transfer failed"
        );
        
        // 记录用户的存款余额
        deposits[msg.sender] += amount;
    }

    /**
     * 提款函数
     * 用户可以提取自己之前存入的 token
     */
    function withdraw(uint256 amount) external {
        require(amount > 0, "Withdraw amount must be greater than 0");
        require(
            deposits[msg.sender] >= amount,
            "Insufficient deposit balance"
        );
        
        // 更新用户的存款金额
        deposits[msg.sender] -= amount;
        
        // 将 token 转回给用户
        require(
            token.transfer(msg.sender, amount),
            "Transfer failed"
        );
    }
}