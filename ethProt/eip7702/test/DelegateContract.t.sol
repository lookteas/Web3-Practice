// SPDX-License-Identifier: MIT
pragma solidity 0.8.25;

import {Test, console2} from "forge-std/Test.sol";
import {DelegateContract} from "../src/DelegateContract.sol";
import {TokenBank} from "../src/TokenBank.sol";

contract DelegateContractTest is Test {
    DelegateContract public delegateContract;
    TokenBank public tokenBank;
    
    address public user1;
    address public user2;
    
    event BatchExecuted(address indexed user, uint256 nonce, uint256 executedCount);
    event ExecutionFailed(address indexed target, bytes data, string reason);
    
    function setUp() public {
        // 部署合约
        delegateContract = new DelegateContract();
        tokenBank = new TokenBank();
        
        // 设置测试用户
        user1 = makeAddr("user1");
        user2 = makeAddr("user2");
        
        // 给测试用户一些ETH
        vm.deal(user1, 10 ether);
        vm.deal(user2, 10 ether);
    }
    
    function test_InitialState() public {
        // 测试初始状态
        assertEq(delegateContract.getNonce(user1), 0);
        assertEq(delegateContract.getNonce(user2), 0);
    }
    
    function test_BatchExecute_SingleDeposit() public {
        // 准备批量执行数据
        address[] memory targets = new address[](1);
        uint256[] memory values = new uint256[](1);
        bytes[] memory calldatas = new bytes[](1);
        
        targets[0] = address(tokenBank);
        values[0] = 1 ether;
        calldatas[0] = abi.encodeWithSignature("deposit()");
        
        // 切换到user1
        vm.startPrank(user1);
        
        // 期望事件
        vm.expectEmit(true, false, false, true);
        emit BatchExecuted(user1, 0, 1);
        
        // 执行批量操作
        delegateContract.batchExecute{value: 1 ether}(targets, values, calldatas, 0);
        
        // 验证结果 - 存款应该记录在DelegateContract地址下，因为它是实际的调用者
        assertEq(delegateContract.getNonce(user1), 1);
        assertEq(tokenBank.getBalance(address(delegateContract)), 1 ether);
        
        vm.stopPrank();
    }
    
    function test_BatchExecute_MultipleDeposits() public {
        // 准备多个存款操作
        address[] memory targets = new address[](3);
        uint256[] memory values = new uint256[](3);
        bytes[] memory calldatas = new bytes[](3);
        
        for (uint256 i = 0; i < 3; i++) {
            targets[i] = address(tokenBank);
            values[i] = 0.5 ether;
            calldatas[i] = abi.encodeWithSignature("deposit()");
        }
        
        vm.startPrank(user1);
        
        // 执行批量操作
        delegateContract.batchExecute{value: 1.5 ether}(targets, values, calldatas, 0);
        
        // 验证结果 - 存款应该记录在DelegateContract地址下
        assertEq(delegateContract.getNonce(user1), 1);
        assertEq(tokenBank.getBalance(address(delegateContract)), 1.5 ether);
        
        vm.stopPrank();
    }
    
    function test_BatchExecute_InvalidNonce() public {
        address[] memory targets = new address[](1);
        uint256[] memory values = new uint256[](1);
        bytes[] memory calldatas = new bytes[](1);
        
        targets[0] = address(tokenBank);
        values[0] = 1 ether;
        calldatas[0] = abi.encodeWithSignature("deposit()");
        
        vm.startPrank(user1);
        
        // 使用错误的nonce应该失败
        vm.expectRevert(DelegateContract.InvalidNonce.selector);
        delegateContract.batchExecute{value: 1 ether}(targets, values, calldatas, 1);
        
        vm.stopPrank();
    }
    
    function test_BatchExecute_ArrayLengthMismatch() public {
        address[] memory targets = new address[](2);
        uint256[] memory values = new uint256[](1); // 长度不匹配
        bytes[] memory calldatas = new bytes[](2);
        
        targets[0] = address(tokenBank);
        targets[1] = address(tokenBank);
        values[0] = 1 ether;
        calldatas[0] = abi.encodeWithSignature("deposit()");
        calldatas[1] = abi.encodeWithSignature("deposit()");
        
        vm.startPrank(user1);
        
        // 数组长度不匹配应该失败
        vm.expectRevert("Array length mismatch");
        delegateContract.batchExecute{value: 1 ether}(targets, values, calldatas, 0);
        
        vm.stopPrank();
    }
    
    function test_BatchExecute_EmptyTargets() public {
        address[] memory targets = new address[](0);
        uint256[] memory values = new uint256[](0);
        bytes[] memory calldatas = new bytes[](0);
        
        vm.startPrank(user1);
        
        // 空数组应该失败
        vm.expectRevert("Empty targets array");
        delegateContract.batchExecute(targets, values, calldatas, 0);
        
        vm.stopPrank();
    }
    
    function test_BatchExecute_WithFailedCall() public {
        // 准备一个会失败的调用
        address[] memory targets = new address[](2);
        uint256[] memory values = new uint256[](2);
        bytes[] memory calldatas = new bytes[](2);
        
        targets[0] = address(tokenBank);
        values[0] = 1 ether;
        calldatas[0] = abi.encodeWithSignature("deposit()");
        
        // 第二个调用会失败（调用不存在的函数）
        targets[1] = address(tokenBank);
        values[1] = 0;
        calldatas[1] = abi.encodeWithSignature("nonExistentFunction()");
        
        vm.startPrank(user1);
        
        // 期望ExecutionFailed事件
        vm.expectEmit(true, false, false, false);
        emit ExecutionFailed(address(tokenBank), calldatas[1], "");
        
        // 执行批量操作（部分成功）
        delegateContract.batchExecute{value: 1 ether}(targets, values, calldatas, 0);
        
        // 验证第一个调用成功 - 存款记录在DelegateContract地址下
        assertEq(tokenBank.getBalance(address(delegateContract)), 1 ether);
        assertEq(delegateContract.getNonce(user1), 1);
        
        vm.stopPrank();
    }
    
    function test_NonceIncrement() public {
        address[] memory targets = new address[](1);
        uint256[] memory values = new uint256[](1);
        bytes[] memory calldatas = new bytes[](1);
        
        targets[0] = address(tokenBank);
        values[0] = 1 ether;
        calldatas[0] = abi.encodeWithSignature("deposit()");
        
        vm.startPrank(user1);
        
        // 第一次执行
        delegateContract.batchExecute{value: 1 ether}(targets, values, calldatas, 0);
        assertEq(delegateContract.getNonce(user1), 1);
        
        // 第二次执行
        delegateContract.batchExecute{value: 1 ether}(targets, values, calldatas, 1);
        assertEq(delegateContract.getNonce(user1), 2);
        
        vm.stopPrank();
    }
    
    function test_IsValidSignature() public {
        bytes32 hash = keccak256("test message");
        bytes memory signature = "dummy signature";
        
        bytes4 result = delegateContract.isValidSignature(hash, signature);
        assertEq(uint32(result), uint32(0x1626ba7e)); // ERC-1271 magic value
    }
    
    function test_ReceiveEther() public {
        uint256 initialBalance = address(delegateContract).balance;
        
        // 发送ETH到合约
        vm.deal(address(this), 1 ether);
        (bool success,) = address(delegateContract).call{value: 1 ether}("");
        assertTrue(success);
        
        assertEq(address(delegateContract).balance, initialBalance + 1 ether);
    }
    
    function test_FallbackFunction() public {
        uint256 initialBalance = address(delegateContract).balance;
        
        // 调用不存在的函数
        vm.deal(address(this), 1 ether);
        (bool success,) = address(delegateContract).call{value: 1 ether}("nonExistentFunction()");
        assertTrue(success);
        
        assertEq(address(delegateContract).balance, initialBalance + 1 ether);
    }
}