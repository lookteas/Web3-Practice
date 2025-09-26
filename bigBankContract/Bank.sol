// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

import "./IBank.sol";

/**
 * @title Bank 合约
 * @dev 实现存款、提款和记录前3名存款用户功能，实现 IBank 接口
 */
contract Bank is IBank {
    // 合约管理员
    address public override admin;
    
    // 记录每个地址的存款金额
    mapping(address => uint256) public deposits;
    
    // 存款金额前3名用户
    address[3] public topDepositors;
    
    // 所有存款用户地址列表
    address[] public depositors;
    
    // 修饰：仅管理员可调用
    modifier onlyAdmin() {
        require(msg.sender == admin, "only admin can call");
        _;
    }
    
    /**
     * @dev 构造函数，设置合约部署者为管理员
     */
    constructor() {
        admin = msg.sender;
    }
    
    /**
     * @dev 存款函数，接收以太币存款
     * 用户可以通过 Metamask 等钱包直接向合约地址发送以太币
     */
    receive() external payable {
        deposit();
    }
    
    /**
     * @dev 存款函数
     */
    function deposit() public payable override {
        require(msg.value > 0, "deposit amount must be greater than 0");
        
        // 如果是首次存款，添加到存款用户列表
        if (deposits[msg.sender] == 0) {
            depositors.push(msg.sender);
        }
        
        // 更新存款金额
        deposits[msg.sender] += msg.value;
        
        // 更新前3名存款用户
        updateTopDepositors();
        
        emit Deposit(msg.sender, msg.value);
    }
    
    /**
     * @dev 提款函数，仅管理员可调用
     * @param amount 提款金额
     */
    function withdraw(uint256 amount) external override onlyAdmin {
        require(amount > 0, "withdraw amount must be greater than 0");
        require(address(this).balance >= amount, "no balance to withdraw");
        
        // 将以太币发送给管理员
        payable(admin).transfer(amount);
        
        emit Withdrawal(admin, amount);
    }
    
    /**
     * @dev 提取合约中的所有资金，仅管理员可调用
     */
    function withdrawAll() external override onlyAdmin {
        uint256 balance = address(this).balance;
        require(balance > 0, "no balance to withdraw");
        
        payable(admin).transfer(balance);
        
        emit Withdrawal(admin, balance);
    }
    
    /**
     * @dev 更新前3名存款用户
     */
    function updateTopDepositors() internal {
        address tempAddr;
        uint256 tempAmount;
        
        // 将当前用户加入临时数组进行排序
        address[4] memory candidates;
        uint256[4] memory amounts;
        
        // 复制现有的前3名
        for (uint i = 0; i < 3; i++) {
            candidates[i] = topDepositors[i];
            if (candidates[i] != address(0)) {
                amounts[i] = deposits[candidates[i]];
            }
        }
        
        // 添加当前存款用户
        candidates[3] = msg.sender;
        amounts[3] = deposits[msg.sender];
        
        // 冒泡排序，按存款金额降序排列
        for (uint i = 0; i < 4; i++) {
            for (uint j = 0; j < 3 - i; j++) {
                if (amounts[j] < amounts[j + 1]) {
                    // 交换金额
                    tempAmount = amounts[j];
                    amounts[j] = amounts[j + 1];
                    amounts[j + 1] = tempAmount;
                    
                    // 交换地址
                    tempAddr = candidates[j];
                    candidates[j] = candidates[j + 1];
                    candidates[j + 1] = tempAddr;
                }
            }
        }
        
        // 更新前3名，去除重复地址
        uint256 count = 0;
        address[3] memory newTopDepositors;
        
        for (uint i = 0; i < 4 && count < 3; i++) {
            if (candidates[i] != address(0) && amounts[i] > 0) {
                bool isDuplicate = false;
                for (uint j = 0; j < count; j++) {
                    if (newTopDepositors[j] == candidates[i]) {
                        isDuplicate = true;
                        break;
                    }
                }
                if (!isDuplicate) {
                    newTopDepositors[count] = candidates[i];
                    count++;
                }
            }
        }
        
        topDepositors = newTopDepositors;
        emit TopDepositorsUpdated(topDepositors);
    }
    
    /**
     * @dev 获取合约余额
     */
    function getContractBalance() external view override returns (uint256) {
        return address(this).balance;
    }
    
    /**
     * @dev 获取指定地址的存款金额
     */
    function getDeposit(address depositor) external view override returns (uint256) {
        return deposits[depositor];
    }
    
    /**
     * @dev 获取前3名存款用户
     */
    function getTopDepositors() external view override returns (address[3] memory) {
        return topDepositors;
    }
    
    /**
     * @dev 获取前3名存款用户及其存款金额
     */
    function getTopDepositorsWithAmounts() external view override returns (address[3] memory, uint256[3] memory) {
        uint256[3] memory amounts;
        for (uint i = 0; i < 3; i++) {
            if (topDepositors[i] != address(0)) {
                amounts[i] = deposits[topDepositors[i]];
            }
        }
        return (topDepositors, amounts);
    }
    
    /**
     * @dev 获取所有存款用户数量
     */
    function getDepositorsCount() external view override returns (uint256) {
        return depositors.length;
    }
    
    /**
     * @dev 转移管理员权限
     */
    function transferAdmin(address newAdmin) external override onlyAdmin {
        require(newAdmin != address(0), "only admin can transfer");
        admin = newAdmin;
    }
}