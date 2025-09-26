// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

import "./IBank.sol";

/**
 * @title Admin 合约
 * @dev 管理员合约，可以从 IBank 合约中提取资金
 */
contract Admin {
    // 合约拥有者
    address public owner;
    
    // 事件
    event AdminWithdraw(address indexed bank, uint256 amount);
    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);
    
    // 修饰符：仅拥有者可调用
    modifier onlyOwner() {
        require(msg.sender == owner, "Only owner can call this function");
        _;
    }
    
    /**
     * @dev 构造函数，设置合约部署者为拥有者
     */
    constructor() {
        owner = msg.sender;
    }
    
    /**
     * @dev 从指定的 IBank 合约中提取所有资金到本合约
     * @param bank IBank 合约实例
     */
    function adminWithdraw(IBank bank) external onlyOwner {
        // 检查 bank 合约地址是否有效
        require(address(bank) != address(0), "Invalid bank contract address");
        
        // 获取 bank 合约的余额
        uint256 bankBalance = bank.getContractBalance();
        require(bankBalance > 0, "Bank contract has no balance");
        
        // 检查当前合约是否是 bank 合约的管理员
        require(bank.admin() == address(this), "This contract is not the admin of the bank");
        
        // 调用 bank 合约的 withdrawAll 函数，将资金转移到本合约
        bank.withdrawAll();
        
        emit AdminWithdraw(address(bank), bankBalance);
    }
    
    /**
     * @dev 从指定的 IBank 合约中提取指定金额到本合约
     * @param bank IBank 合约实例
     * @param amount 提取金额
     */
    function adminWithdrawAmount(IBank bank, uint256 amount) external onlyOwner {
        // 检查 bank 合约地址是否有效
        require(address(bank) != address(0), "Invalid bank contract address");
        require(amount > 0, "Amount must be greater than 0");
        
        // 获取 bank 合约的余额
        uint256 bankBalance = bank.getContractBalance();
        require(bankBalance >= amount, "Bank contract has insufficient balance");
        
        // 检查当前合约是否是 bank 合约的管理员
        require(bank.admin() == address(this), "This contract is not the admin of the bank");
        
        // 调用 bank 合约的 withdraw 函数，将指定金额转移到本合约
        bank.withdraw(amount);
        
        emit AdminWithdraw(address(bank), amount);
    }
    
    /**
     * @dev 获取本合约的余额
     */
    function getContractBalance() external view returns (uint256) {
        return address(this).balance;
    }
    
    /**
     * @dev 从本合约提取资金到拥有者地址
     * @param amount 提取金额
     */
    function withdrawToOwner(uint256 amount) external onlyOwner {
        require(amount > 0, "Amount must be greater than 0");
        require(address(this).balance >= amount, "Insufficient contract balance");
        
        payable(owner).transfer(amount);
    }
    
    /**
     * @dev 从本合约提取所有资金到拥有者地址
     */
    function withdrawAllToOwner() external onlyOwner {
        uint256 balance = address(this).balance;
        require(balance > 0, "No balance to withdraw");
        
        payable(owner).transfer(balance);
    }
    
    /**
     * @dev 转移合约拥有权
     * @param newOwner 新拥有者地址
     */
    function transferOwnership(address newOwner) external onlyOwner {
        require(newOwner != address(0), "New owner cannot be zero address");
        require(newOwner != owner, "New owner must be different from current owner");
        
        address previousOwner = owner;
        owner = newOwner;
        
        emit OwnershipTransferred(previousOwner, newOwner);
    }
    
    /**
     * @dev 接收以太币的函数
     */
    receive() external payable {
        // 允许合约接收以太币
    }
    
    /**
     * @dev 回退函数
     */
    fallback() external payable {
        // 允许合约接收以太币
    }
}