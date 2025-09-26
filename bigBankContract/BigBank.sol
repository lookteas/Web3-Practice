// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

import "./Bank.sol";

/**
 * @title BigBank 合约
 * @dev 继承自 Bank 合约，添加最小存款金额限制
 */
contract BigBank is Bank {
    // 最小存款金额：0.001 ether
    uint256 public constant MIN_DEPOSIT = 0.001 ether;
    
    // 修饰符：检查最小存款金额
    modifier minDepositRequired() {
        require(msg.value >= MIN_DEPOSIT, "Deposit amount must be at least 0.001 ether");
        _;
    }
    
    /**
     * @dev 构造函数，调用父合约构造函数
     */
    constructor() Bank() {
        // 父合约构造函数会自动调用，设置部署者为管理员
    }
    
    /**
     * @dev 重写存款函数，添加最小金额限制
     */
    function deposit() public payable override minDepositRequired {
        // 调用父合约的存款逻辑
        super.deposit();
    }
    
    /**
     * @dev 重写 receive 函数，添加最小金额限制
     */
    receive() external payable override {
        require(msg.value >= MIN_DEPOSIT, "Deposit amount must be at least 0.001 ether");
        // 调用父合约的存款逻辑
        super.deposit();
    }
    
    /**
     * @dev 获取最小存款金额
     */
    function getMinDeposit() external pure returns (uint256) {
        return MIN_DEPOSIT;
    }
}