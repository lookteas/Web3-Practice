// SPDX-License-Identifier: MIT
pragma solidity ^0.8.25;

import "./IPermit2.sol";

/**
 * @title Bank
 * @dev 一个简单的银行合约，支持存款、取款和查询功能，以及 Permit2 签名授权存款
 */
contract Bank {
    address public admin;
    mapping(address => uint256) public deposits;
    address[] public depositors;
    address[3] public topDepositors;
    
    // Permit2 合约接口
    IPermit2 public immutable permit2;

    event Deposit(address indexed depositor, uint256 amount);
    event DepositWithPermit2(address indexed depositor, address indexed token, uint256 amount);
    event Withdrawal(address indexed admin, uint256 amount);
    event TopDepositorsUpdated(address[3] topDepositors);

    constructor(address _permit2) {
        admin = msg.sender;
        permit2 = IPermit2(_permit2);
    }

    modifier onlyAdmin() {
        require(msg.sender == admin, "Only admin can call this function");
        _;
    }

    /**
     * @dev 存款函数
     */
    function deposit() external payable {
        require(msg.value > 0, "Deposit amount must be greater than 0");
        
        if (deposits[msg.sender] == 0) {
            depositors.push(msg.sender);
        }
        
        deposits[msg.sender] += msg.value;
        updateTopDepositors(msg.sender);
        
        emit Deposit(msg.sender, msg.value);
    }

    /**
     * @dev 使用 Permit2 进行签名授权存款
     * @param token 代币合约地址
     * @param amount 存款金额
     * @param permitSingle Permit2 签名数据
     * @param signature 用户签名
     */
    function depositWithPermit2(
        address token,
        uint256 amount,
        IPermit2.PermitSingle calldata permitSingle,
        bytes calldata signature
    ) external {
        require(amount > 0, "Deposit amount must be greater than 0");
        require(token != address(0), "Invalid token address");
        
        // 验证 permit 并执行转账
        permit2.permit(msg.sender, permitSingle, signature);
        permit2.transferFrom(msg.sender, address(this), uint160(amount), token);
        
        // 更新存款记录
        if (deposits[msg.sender] == 0) {
            depositors.push(msg.sender);
        }
        
        deposits[msg.sender] += amount;
        updateTopDepositors(msg.sender);
        
        emit DepositWithPermit2(msg.sender, token, amount);
    }

    /**
     * @dev 取款函数（仅管理员）
     */
    function withdraw(uint256 amount) external onlyAdmin {
        require(amount <= address(this).balance, "Insufficient contract balance");
        payable(admin).transfer(amount);
        emit Withdrawal(admin, amount);
    }

    /**
     * @dev 取出所有资金（仅管理员）
     */
    function withdrawAll() external onlyAdmin {
        uint256 balance = address(this).balance;
        require(balance > 0, "No funds to withdraw");
        payable(admin).transfer(balance);
        emit Withdrawal(admin, balance);
    }

    /**
     * @dev 转移管理员权限
     */
    function transferAdmin(address newAdmin) external onlyAdmin {
        require(newAdmin != address(0), "New admin cannot be zero address");
        admin = newAdmin;
    }

    /**
     * @dev 获取指定地址的存款金额
     */
    function getDeposit(address depositor) external view returns (uint256) {
        return deposits[depositor];
    }

    /**
     * @dev 获取合约余额
     */
    function getContractBalance() external view returns (uint256) {
        return address(this).balance;
    }

    /**
     * @dev 获取存款人数量
     */
    function getDepositorsCount() external view returns (uint256) {
        return depositors.length;
    }

    /**
     * @dev 获取前三名存款人
     */
    function getTopDepositors() external view returns (address[3] memory) {
        return topDepositors;
    }

    /**
     * @dev 获取前三名存款人及其存款金额
     */
    function getTopDepositorsWithAmounts() external view returns (address[3] memory, uint256[3] memory) {
        uint256[3] memory amounts;
        for (uint i = 0; i < 3; i++) {
            amounts[i] = deposits[topDepositors[i]];
        }
        return (topDepositors, amounts);
    }

    /**
     * @dev 更新前三名存款人
     */
    function updateTopDepositors(address depositor) internal {
        uint256 depositorAmount = deposits[depositor];
        
        // 检查是否已经在前三名中
        for (uint i = 0; i < 3; i++) {
            if (topDepositors[i] == depositor) {
                // 重新排序
                sortTopDepositors();
                emit TopDepositorsUpdated(topDepositors);
                return;
            }
        }
        
        // 检查是否能进入前三名
        for (uint i = 0; i < 3; i++) {
            if (topDepositors[i] == address(0) || deposits[topDepositors[i]] < depositorAmount) {
                topDepositors[i] = depositor;
                sortTopDepositors();
                emit TopDepositorsUpdated(topDepositors);
                return;
            }
        }
    }

    /**
     * @dev 对前三名存款人进行排序（降序）
     */
    function sortTopDepositors() internal {
        for (uint i = 0; i < 2; i++) {
            for (uint j = i + 1; j < 3; j++) {
                if (deposits[topDepositors[i]] < deposits[topDepositors[j]]) {
                    address temp = topDepositors[i];
                    topDepositors[i] = topDepositors[j];
                    topDepositors[j] = temp;
                }
            }
        }
    }

    /**
     * @dev 接收以太币
     */
    receive() external payable {
        if (deposits[msg.sender] == 0) {
            depositors.push(msg.sender);
        }
        deposits[msg.sender] += msg.value;
        updateTopDepositors(msg.sender);
        emit Deposit(msg.sender, msg.value);
    }
}