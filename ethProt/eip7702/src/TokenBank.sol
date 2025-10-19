// SPDX-License-Identifier: MIT
pragma solidity 0.8.25;

/**
 * @title TokenBank
 * @dev 简单的存款银行合约，支持ETH存取款
 * @notice 用作EIP-7702批量操作的目标合约
 */
contract TokenBank {
    // 用户余额映射
    mapping(address => uint256) public balances;
    
    // 总存款金额
    uint256 public totalDeposits;
    
    // 事件定义
    event Deposit(address indexed user, uint256 amount, uint256 newBalance);
    event Withdraw(address indexed user, uint256 amount, uint256 newBalance);
    
    // 错误定义
    error InsufficientBalance();
    error ZeroAmount();
    error WithdrawFailed();
    
    /**
     * @dev 存款函数
     */
    function deposit() external payable {
        if (msg.value == 0) {
            revert ZeroAmount();
        }
        
        balances[msg.sender] += msg.value;
        totalDeposits += msg.value;
        
        emit Deposit(msg.sender, msg.value, balances[msg.sender]);
    }
    
    /**
     * @dev 取款函数
     * @param amount 取款金额
     */
    function withdraw(uint256 amount) external {
        if (amount == 0) {
            revert ZeroAmount();
        }
        
        if (balances[msg.sender] < amount) {
            revert InsufficientBalance();
        }
        
        balances[msg.sender] -= amount;
        totalDeposits -= amount;
        
        (bool success, ) = payable(msg.sender).call{value: amount}("");
        if (!success) {
            // 回滚状态
            balances[msg.sender] += amount;
            totalDeposits += amount;
            revert WithdrawFailed();
        }
        
        emit Withdraw(msg.sender, amount, balances[msg.sender]);
    }
    
    /**
     * @dev 获取用户余额
     * @param user 用户地址
     * @return 用户在银行的余额
     */
    function getBalance(address user) external view returns (uint256) {
        return balances[user];
    }
    
    /**
     * @dev 获取合约总余额
     * @return 合约中的总ETH数量
     */
    function getContractBalance() external view returns (uint256) {
        return address(this).balance;
    }
    
    /**
     * @dev 批量存款函数（用于测试批量操作）
     * @param users 用户地址数组
     * @param amounts 对应的存款金额数组
     */
    function batchDeposit(address[] calldata users, uint256[] calldata amounts) external payable {
        require(users.length == amounts.length, "Array length mismatch");
        
        uint256 totalAmount = 0;
        for (uint256 i = 0; i < amounts.length; i++) {
            totalAmount += amounts[i];
        }
        
        require(msg.value == totalAmount, "Insufficient ETH sent");
        
        for (uint256 i = 0; i < users.length; i++) {
            if (amounts[i] > 0) {
                balances[users[i]] += amounts[i];
                totalDeposits += amounts[i];
                emit Deposit(users[i], amounts[i], balances[users[i]]);
            }
        }
    }
    
    /**
     * @dev 紧急提取函数（仅限合约所有者，用于测试）
     */
    function emergencyWithdraw() external {
        require(msg.sender == address(this), "Only contract can call");
        payable(msg.sender).transfer(address(this).balance);
    }
    
    /**
     * @dev 接收ETH的fallback函数
     */
    receive() external payable {
        // 直接调用deposit函数
        if (msg.value > 0) {
            balances[msg.sender] += msg.value;
            totalDeposits += msg.value;
            emit Deposit(msg.sender, msg.value, balances[msg.sender]);
        }
    }
}