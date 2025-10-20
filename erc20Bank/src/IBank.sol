// SPDX-License-Identifier: MIT
pragma solidity ^0.8.25;

/**
 * @title IBank 接口
 * @dev 定义银行合约的核心功能接口
 */
interface IBank {
    // 事件
    event Deposit(address indexed depositor, uint256 amount);
    event Withdrawal(address indexed admin, uint256 amount);
    event TopDepositorsUpdated(address[3] topDepositors);
    
    /**
     * @dev 存款函数
     */
    function deposit() external payable;
    
    /**
     * @dev 提款函数，仅管理员可调用
     * @param amount 提款金额
     */
    function withdraw(uint256 amount) external;
    
    /**
     * @dev 提取合约中的所有资金，仅管理员可调用
     */
    function withdrawAll() external;
    
    /**
     * @dev 获取合约余额
     */
    function getContractBalance() external view returns (uint256);
    
    /**
     * @dev 获取指定地址的存款金额
     */
    function getDeposit(address depositor) external view returns (uint256);
    
    /**
     * @dev 获取前3名存款用户
     */
    function getTopDepositors() external view returns (address[3] memory);
    
    /**
     * @dev 获取前3名存款用户及其存款金额
     */
    function getTopDepositorsWithAmounts() external view returns (address[3] memory, uint256[3] memory);
    
    /**
     * @dev 获取所有存款用户数量
     */
    function getDepositorsCount() external view returns (uint256);
    
    /**
     * @dev 转移管理员权限
     */
    function transferAdmin(address newAdmin) external;
    
    /**
     * @dev 获取管理员地址
     */
    function admin() external view returns (address);
}