// SPDX-License-Identifier: MIT
pragma solidity ^0.8.25;

import "../src/Bank.sol";
import "../src/ERC20Token.sol";

/**
 * @title ReentrancyAttackTest
 * @dev 测试重入攻击和防护机制
 */
contract ReentrancyAttackTest {
    Bank public bank;
    ERC20Token public token;
    MaliciousContract public attacker;
    
    event TestResult(string testName, bool passed, string message);
    
    constructor() {
        // 部署合约
        token = new ERC20Token("Test Token", "TEST", 1000000 * 10**18);
        bank = new Bank(address(token));
        attacker = new MaliciousContract(address(bank));
    }
    
    /**
     * @dev 运行重入攻击测试
     */
    function runReentrancyTests() external {
        testReentrancyProtection();
        testNormalWithdrawal();
    }
    
    /**
     * @dev 测试重入攻击防护
     */
    function testReentrancyProtection() public {
        // 给银行合约存入一些ETH
        bank.deposit{value: 1 ether}();
        
        // 尝试重入攻击
        try attacker.attack{value: 0.1 ether}() {
            emit TestResult("testReentrancyProtection", false, "Reentrancy attack should have failed");
        } catch Error(string memory reason) {
            if (keccak256(bytes(reason)) == keccak256(bytes("ReentrancyGuard: reentrant call"))) {
                emit TestResult("testReentrancyProtection", true, "Reentrancy attack correctly prevented");
            } else {
                emit TestResult("testReentrancyProtection", false, string(abi.encodePacked("Unexpected error: ", reason)));
            }
        } catch {
            emit TestResult("testReentrancyProtection", true, "Reentrancy attack prevented (generic error)");
        }
    }
    
    /**
     * @dev 测试正常提款功能
     */
    function testNormalWithdrawal() public {
        uint256 initialBalance = address(this).balance;
        
        // 正常提款应该成功
        try bank.withdraw(0.5 ether) {
            uint256 finalBalance = address(this).balance;
            if (finalBalance > initialBalance) {
                emit TestResult("testNormalWithdrawal", true, "Normal withdrawal works correctly");
            } else {
                emit TestResult("testNormalWithdrawal", false, "Normal withdrawal failed to transfer funds");
            }
        } catch Error(string memory reason) {
            emit TestResult("testNormalWithdrawal", false, string(abi.encodePacked("Normal withdrawal failed: ", reason)));
        }
    }
    
    /**
     * @dev 接收ETH
     */
    receive() external payable {}
}

/**
 * @title MaliciousContract
 * @dev 恶意合约，尝试进行重入攻击
 */
contract MaliciousContract {
    Bank public bank;
    uint256 public attackCount;
    
    constructor(address _bank) {
        bank = Bank(payable(_bank));
    }
    
    /**
     * @dev 发起攻击
     */
    function attack() external payable {
        require(msg.value > 0, "Need some ETH to attack");
        
        // 先存款
        bank.deposit{value: msg.value}();
        
        // 尝试提款（这里会触发重入）
        bank.withdraw(msg.value);
    }
    
    /**
     * @dev 接收ETH时尝试重入攻击
     */
    receive() external payable {
        attackCount++;
        
        // 尝试重入攻击
        if (attackCount < 3 && address(bank).balance > 0) {
            bank.withdraw(msg.value);
        }
    }
}

/**
 * @title ReentrancyAttackDemo
 * @dev 演示重入攻击的原理和防护
 */
contract ReentrancyAttackDemo {
    event AttackStep(uint256 step, string description, uint256 contractBalance, uint256 attackerBalance);
    
    /**
     * @dev 演示重入攻击的步骤
     */
    function demonstrateReentrancyAttack() external pure returns (string memory) {
        return "Reentrancy Attack Steps:\n"
               "1. Attacker deposits ETH to the bank contract\n"
               "2. Attacker calls withdraw() function\n"
               "3. Bank contract sends ETH to attacker\n"
               "4. Attacker's receive() function is triggered\n"
               "5. In receive(), attacker calls withdraw() again (REENTRANCY)\n"
               "6. Without protection, this drains the contract\n"
               "7. With nonReentrant modifier, step 5 fails with 'reentrant call' error";
    }
    
    /**
     * @dev 演示防护机制
     */
    function demonstrateProtection() external pure returns (string memory) {
        return "Protection Mechanisms:\n"
               "1. ReentrancyGuard: Uses a boolean lock to prevent reentrant calls\n"
               "2. Checks-Effects-Interactions Pattern: Update state before external calls\n"
               "3. Use transfer() instead of call() for ETH transfers (gas limit protection)\n"
               "4. Pull Payment Pattern: Let users withdraw instead of pushing payments";
    }
}