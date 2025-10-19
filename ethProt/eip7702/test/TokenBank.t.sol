// SPDX-License-Identifier: MIT
pragma solidity 0.8.25;

import {Test, console2} from "forge-std/Test.sol";
import {TokenBank} from "../src/TokenBank.sol";

contract TokenBankTest is Test {
    TokenBank public tokenBank;
    
    address public user1;
    address public user2;
    
    event Deposit(address indexed user, uint256 amount, uint256 newBalance);
    event Withdraw(address indexed user, uint256 amount, uint256 newBalance);
    
    function setUp() public {
        tokenBank = new TokenBank();
        
        user1 = makeAddr("user1");
        user2 = makeAddr("user2");
        
        vm.deal(user1, 10 ether);
        vm.deal(user2, 10 ether);
    }
    
    function test_InitialState() public {
        assertEq(tokenBank.getBalance(user1), 0);
        assertEq(tokenBank.totalDeposits(), 0);
        assertEq(tokenBank.getContractBalance(), 0);
    }
    
    function test_Deposit() public {
        vm.startPrank(user1);
        
        // 期望事件
        vm.expectEmit(true, false, false, true);
        emit Deposit(user1, 1 ether, 1 ether);
        
        // 存款
        tokenBank.deposit{value: 1 ether}();
        
        // 验证状态
        assertEq(tokenBank.getBalance(user1), 1 ether);
        assertEq(tokenBank.totalDeposits(), 1 ether);
        assertEq(tokenBank.getContractBalance(), 1 ether);
        
        vm.stopPrank();
    }
    
    function test_Deposit_ZeroAmount() public {
        vm.startPrank(user1);
        
        // 零金额存款应该失败
        vm.expectRevert(TokenBank.ZeroAmount.selector);
        tokenBank.deposit{value: 0}();
        
        vm.stopPrank();
    }
    
    function test_MultipleDeposits() public {
        vm.startPrank(user1);
        
        // 第一次存款
        tokenBank.deposit{value: 1 ether}();
        assertEq(tokenBank.getBalance(user1), 1 ether);
        
        // 第二次存款
        tokenBank.deposit{value: 2 ether}();
        assertEq(tokenBank.getBalance(user1), 3 ether);
        assertEq(tokenBank.totalDeposits(), 3 ether);
        
        vm.stopPrank();
    }
    
    function test_Withdraw() public {
        vm.startPrank(user1);
        
        // 先存款
        tokenBank.deposit{value: 2 ether}();
        
        uint256 initialBalance = user1.balance;
        
        // 期望事件
        vm.expectEmit(true, false, false, true);
        emit Withdraw(user1, 1 ether, 1 ether);
        
        // 取款
        tokenBank.withdraw(1 ether);
        
        // 验证状态
        assertEq(tokenBank.getBalance(user1), 1 ether);
        assertEq(tokenBank.totalDeposits(), 1 ether);
        assertEq(user1.balance, initialBalance + 1 ether);
        
        vm.stopPrank();
    }
    
    function test_Withdraw_ZeroAmount() public {
        vm.startPrank(user1);
        
        tokenBank.deposit{value: 1 ether}();
        
        // 零金额取款应该失败
        vm.expectRevert(TokenBank.ZeroAmount.selector);
        tokenBank.withdraw(0);
        
        vm.stopPrank();
    }
    
    function test_Withdraw_InsufficientBalance() public {
        vm.startPrank(user1);
        
        tokenBank.deposit{value: 1 ether}();
        
        // 余额不足应该失败
        vm.expectRevert(TokenBank.InsufficientBalance.selector);
        tokenBank.withdraw(2 ether);
        
        vm.stopPrank();
    }
    
    function test_BatchDeposit() public {
        address[] memory users = new address[](2);
        uint256[] memory amounts = new uint256[](2);
        
        users[0] = user1;
        users[1] = user2;
        amounts[0] = 1 ether;
        amounts[1] = 2 ether;
        
        // 期望事件
        vm.expectEmit(true, false, false, true);
        emit Deposit(user1, 1 ether, 1 ether);
        vm.expectEmit(true, false, false, true);
        emit Deposit(user2, 2 ether, 2 ether);
        
        // 批量存款
        tokenBank.batchDeposit{value: 3 ether}(users, amounts);
        
        // 验证状态
        assertEq(tokenBank.getBalance(user1), 1 ether);
        assertEq(tokenBank.getBalance(user2), 2 ether);
        assertEq(tokenBank.totalDeposits(), 3 ether);
    }
    
    function test_BatchDeposit_ArrayLengthMismatch() public {
        address[] memory users = new address[](2);
        uint256[] memory amounts = new uint256[](1); // 长度不匹配
        
        users[0] = user1;
        users[1] = user2;
        amounts[0] = 1 ether;
        
        vm.expectRevert("Array length mismatch");
        tokenBank.batchDeposit{value: 1 ether}(users, amounts);
    }
    
    function test_BatchDeposit_InsufficientETH() public {
        address[] memory users = new address[](2);
        uint256[] memory amounts = new uint256[](2);
        
        users[0] = user1;
        users[1] = user2;
        amounts[0] = 1 ether;
        amounts[1] = 2 ether;
        
        // 发送的ETH不足
        vm.expectRevert("Insufficient ETH sent");
        tokenBank.batchDeposit{value: 2 ether}(users, amounts);
    }
    
    function test_ReceiveEther() public {
        vm.startPrank(user1);
        
        uint256 initialBalance = tokenBank.getBalance(user1);
        
        // 期望事件
        vm.expectEmit(true, false, false, true);
        emit Deposit(user1, 1 ether, initialBalance + 1 ether);
        
        // 直接发送ETH
        (bool success,) = address(tokenBank).call{value: 1 ether}("");
        assertTrue(success);
        
        // 验证状态
        assertEq(tokenBank.getBalance(user1), 1 ether);
        assertEq(tokenBank.totalDeposits(), 1 ether);
        
        vm.stopPrank();
    }
    
    function test_MultipleUsersDeposits() public {
        // user1存款
        vm.startPrank(user1);
        tokenBank.deposit{value: 1 ether}();
        vm.stopPrank();
        
        // user2存款
        vm.startPrank(user2);
        tokenBank.deposit{value: 2 ether}();
        vm.stopPrank();
        
        // 验证各自余额
        assertEq(tokenBank.getBalance(user1), 1 ether);
        assertEq(tokenBank.getBalance(user2), 2 ether);
        assertEq(tokenBank.totalDeposits(), 3 ether);
        assertEq(tokenBank.getContractBalance(), 3 ether);
    }
    
    function test_WithdrawAll() public {
        vm.startPrank(user1);
        
        // 存款
        tokenBank.deposit{value: 5 ether}();
        
        uint256 initialBalance = user1.balance;
        
        // 全部取出
        tokenBank.withdraw(5 ether);
        
        // 验证状态
        assertEq(tokenBank.getBalance(user1), 0);
        assertEq(tokenBank.totalDeposits(), 0);
        assertEq(user1.balance, initialBalance + 5 ether);
        
        vm.stopPrank();
    }
    
    function test_BatchDeposit_WithZeroAmounts() public {
        address[] memory users = new address[](3);
        uint256[] memory amounts = new uint256[](3);
        
        users[0] = user1;
        users[1] = user2;
        users[2] = user1;
        amounts[0] = 1 ether;
        amounts[1] = 0; // 零金额
        amounts[2] = 2 ether;
        
        // 批量存款（跳过零金额）
        tokenBank.batchDeposit{value: 3 ether}(users, amounts);
        
        // 验证状态
        assertEq(tokenBank.getBalance(user1), 3 ether); // 1 + 2
        assertEq(tokenBank.getBalance(user2), 0); // 跳过零金额
        assertEq(tokenBank.totalDeposits(), 3 ether);
    }
}