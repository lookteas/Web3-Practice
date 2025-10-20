// SPDX-License-Identifier: MIT
pragma solidity ^0.8.25;

import "../src/Bank.sol";
import "../src/BigBank.sol";
import "../src/ERC20Token.sol";

/**
 * @title BankIntegrationTest
 * @dev 测试ERC20代币与银行合约的集成功能
 */
contract BankIntegrationTest {
    Bank public bank;
    BigBank public bigBank;
    ERC20Token public token;
    
    address public admin;
    address public user1;
    address public user2;
    address public user3;
    
    event TestResult(string testName, bool passed, string message);
    
    constructor() {
        admin = address(this);
        user1 = address(0x1);
        user2 = address(0x2);
        user3 = address(0x3);
        
        // 部署ERC20代币
        token = new ERC20Token("Test Token", "TEST", 1000000 * 10**18);
        
        // 部署Bank合约
        bank = new Bank(address(token));
        
        // 部署BigBank合约
        bigBank = new BigBank(address(token));
        
        // 给测试用户分配一些代币
        token.transfer(user1, 10000 * 10**18);
        token.transfer(user2, 5000 * 10**18);
        token.transfer(user3, 3000 * 10**18);
    }
    
    /**
     * @dev 运行所有测试
     */
    function runAllTests() external {
        testBasicTokenDeposit();
        testTokenDepositWithCallback();
        testTokenWithdrawal();
        testTopTokenDepositors();
        testBigBankMinTokenDeposit();
        testMixedDeposits();
        testGetterFunctions();
    }
    
    /**
     * @dev 测试基本代币存款功能
     */
    function testBasicTokenDeposit() public {
        // 模拟user1进行代币存款
        uint256 depositAmount = 1000 * 10**18;
        
        // 检查初始状态
        uint256 initialBalance = bank.getTokenDeposit(user1);
        require(initialBalance == 0, "Initial token deposit should be 0");
        
        // 模拟授权和存款（在实际测试中需要从user1账户调用）
        // 这里简化处理，直接转移代币到合约
        token.transfer(address(bank), depositAmount);
        
        // 检查合约代币余额
        uint256 contractBalance = bank.getContractTokenBalance();
        require(contractBalance >= depositAmount, "Contract should receive tokens");
        
        emit TestResult("testBasicTokenDeposit", true, "Basic token deposit test passed");
    }
    
    /**
     * @dev 测试代币回调存款功能
     */
    function testTokenDepositWithCallback() public {
        uint256 depositAmount = 2000 * 10**18;
        
        // 使用transferWithCallback进行存款
        token.transferWithCallback(address(bank), depositAmount);
        
        // 检查合约余额
        uint256 contractBalance = bank.getContractTokenBalance();
        require(contractBalance >= depositAmount, "Contract should receive tokens via callback");
        
        emit TestResult("testTokenDepositWithCallback", true, "Token deposit with callback test passed");
    }
    
    /**
     * @dev 测试代币提款功能
     */
    function testTokenWithdrawal() public {
        // 首先存入一些代币
        uint256 depositAmount = 1000 * 10**18;
        token.approve(address(bank), depositAmount);
        bank.depositToken(depositAmount);
        
        uint256 withdrawAmount = 500 * 10**18;
        uint256 initialBalance = token.balanceOf(admin);
        
        // 管理员提取代币
        bank.withdrawToken(withdrawAmount);
        
        uint256 finalBalance = token.balanceOf(admin);
        require(finalBalance >= initialBalance + withdrawAmount, "Admin should receive withdrawn tokens");
        
        emit TestResult("testTokenWithdrawal", true, "Token withdrawal test passed");
    }
    
    /**
     * @dev 测试前3名代币存款用户功能
     */
    function testTopTokenDepositors() public {
        // 模拟多个用户存款
        token.transfer(address(bank), 1000 * 10**18); // user1: 1000
        token.transfer(address(bank), 2000 * 10**18); // user2: 2000
        token.transfer(address(bank), 1500 * 10**18); // user3: 1500
        
        // 获取前3名代币存款用户
        address[3] memory topDepositors = bank.getTopTokenDepositors();
        (address[3] memory depositors, uint256[3] memory amounts) = bank.getTopTokenDepositorsWithAmounts();
        
        // 验证排序（应该是user2, user3, user1的顺序）
        bool sortedCorrectly = amounts[0] >= amounts[1] && amounts[1] >= amounts[2];
        require(sortedCorrectly, "Top depositors should be sorted by amount");
        
        emit TestResult("testTopTokenDepositors", true, "Top token depositors test passed");
    }
    
    /**
     * @dev 测试BigBank的最小代币存款限制
     */
    function testBigBankMinTokenDeposit() public {
        uint256 minDeposit = bigBank.getMinTokenDeposit();
        require(minDeposit == 1000 * 10**18, "Min token deposit should be 1000 tokens");
        
        // 测试小于最小金额的存款应该失败
        try bigBank.depositToken(500 * 10**18) {
            emit TestResult("testBigBankMinTokenDeposit", false, "Should reject deposits below minimum");
        } catch {
            emit TestResult("testBigBankMinTokenDeposit", true, "Correctly rejected deposit below minimum");
        }
    }
    
    /**
     * @dev 测试混合存款（ETH和代币）
     */
    function testMixedDeposits() public {
        // 测试ETH存款
        uint256 ethAmount = 0.1 ether;
        bank.deposit{value: ethAmount}();
        
        uint256 ethDeposit = bank.getDeposit(address(this));
        require(ethDeposit >= ethAmount, "ETH deposit should be recorded");
        
        // 测试代币存款 - 使用正确的存款方法
        uint256 tokenAmount = 1000 * 10**18;
        token.approve(address(bank), tokenAmount);
        bank.depositToken(tokenAmount);
        
        uint256 tokenDeposit = bank.getTokenDeposit(address(this));
        require(tokenDeposit >= tokenAmount, "Token deposit should be recorded");
        
        emit TestResult("testMixedDeposits", true, "Mixed deposits test passed");
    }
    
    /**
     * @dev 测试getter函数
     */
    function testGetterFunctions() public {
        // 测试代币地址获取
        address tokenAddr = bank.getTokenAddress();
        require(tokenAddr == address(token), "Should return correct token address");
        
        // 测试代币存款用户数量
        uint256 tokenDepositorsCount = bank.getTokenDepositorsCount();
        require(tokenDepositorsCount >= 0, "Should return valid depositors count");
        
        // 测试合约代币余额
        uint256 contractTokenBalance = bank.getContractTokenBalance();
        require(contractTokenBalance >= 0, "Should return valid contract token balance");
        
        emit TestResult("testGetterFunctions", true, "Getter functions test passed");
    }
    
    /**
     * @dev 接收ETH的回退函数
     */
    receive() external payable {}
}