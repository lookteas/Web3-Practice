// SPDX-License-Identifier: MIT
pragma solidity ^0.8.25;

import "forge-std/Test.sol";
import "../contracts/ERC20.sol";
import "../contracts/Permit2.sol";
import "../contracts/Bank.sol";

contract Permit2Test is Test {
    ERC20Token public token;
    Permit2 public permit2;
    Bank public bank;
    
    address public user = address(0x123);
    
    // 添加 receive 函数以接收 ETH
    receive() external payable {}
    
    function setUp() public {
        // 部署合约
        token = new ERC20Token();
        permit2 = new Permit2();
        bank = new Bank(address(permit2));
        
        // 给用户一些代币
        token.transfer(user, 1000 * 10**18);
    }
    
    function testERC20BasicFunctions() public view {
        // 检查代币名称和符号
        assertEq(token.name(), "SuiToken");
        assertEq(token.symbol(), "SUI");
        assertEq(token.decimals(), 18);
        
        // 检查总供应量
        assertEq(token.totalSupply(), 100000000 * 10**18);
        
        // 检查初始余额
        assertEq(token.balanceOf(address(this)), 99999000 * 10**18);
        assertEq(token.balanceOf(user), 1000 * 10**18);
    }
    
    function testERC20Transfer() public {
        uint256 amount = 100 * 10**18;
        
        // 转账给用户
        token.transfer(user, amount);
        
        // 验证余额
        assertEq(token.balanceOf(user), 1100 * 10**18);
    }
    
    function testPermit2BasicFunctions() public view {
        // 检查 Permit2 合约的基本功能
        bytes32 domainSeparator = permit2.DOMAIN_SEPARATOR();
        assertTrue(domainSeparator != bytes32(0));
    }
    
    function testBankDeposit() public {
        uint256 amount = 100 * 10**18;
        
        // 存款 ETH
        vm.deal(user, amount);
        vm.prank(user);
        bank.deposit{value: amount}();
        
        // 验证存款
        assertEq(bank.getDeposit(user), amount);
        assertEq(address(bank).balance, amount);
    }
    
    function testBankWithdraw() public {
        uint256 amount = 100 * 10**18;
        
        // 先存款
        vm.deal(user, amount);
        vm.prank(user);
        bank.deposit{value: amount}();
        
        // 提款 - 使用合约部署者作为 admin
        bank.withdraw(amount);
        
        // 验证提款
        assertEq(address(bank).balance, 0);
    }
}