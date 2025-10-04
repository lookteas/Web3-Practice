// SPDX-License-Identifier: MIT
pragma solidity ^0.8.25;

import "forge-std/Test.sol";
import "../src/MyToken.sol";

/**
 * @title MyToken Foundry测试套件
 * @dev 全面测试MyToken合约的功能，包括ERC20标准功能和边界情况
 */
contract MyTokenFoundryTest is Test {
    MyToken public token;
    
    // 测试账户
    address public owner;
    address public alice = address(0x1);
    address public bob = address(0x2);
    address public charlie = address(0x3);
    
    // 常量
    string constant TOKEN_NAME = "MyToken";
    string constant TOKEN_SYMBOL = "MTK";
    uint256 constant INITIAL_SUPPLY = 10_000_000_000 * 1e18; // 10,000,000,000 tokens
    uint256 constant DECIMALS = 18;
    
    // 事件声明（用于测试事件发射）
    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);
    
    /**
     * @dev 测试环境初始化
     * 在每个测试用例执行前设置测试环境
     */
    function setUp() public {
        owner = address(this);
        token = new MyToken(TOKEN_NAME, TOKEN_SYMBOL, INITIAL_SUPPLY);
        
        // 为测试账户分配一些ETH
        vm.deal(alice, 1 ether);
        vm.deal(bob, 1 ether);
        vm.deal(charlie, 1 ether);
    }
    
    // ============ 构造函数测试 ============
    
    /**
     * @dev 测试构造函数正确设置代币名称    
     */
    function test_ConstructorSetsName() public {
        assertEq(token.name(), TOKEN_NAME);
    }
    
    /**
     * @dev 测试构造函数正确设置代币符号
     */
    function test_ConstructorSetsSymbol() public {
        assertEq(token.symbol(), TOKEN_SYMBOL);
    }
    
    /**
     * @dev 测试构造函数正确设置小数位数
     */
    function test_ConstructorSetsDecimals() public {
        assertEq(token.decimals(), DECIMALS);
    }
    
    /**
     * @dev 测试构造函数正确铸造初始供应量
     */
    function test_ConstructorMintsInitialSupply() public {
        assertEq(token.totalSupply(), INITIAL_SUPPLY);
        assertEq(token.balanceOf(owner), INITIAL_SUPPLY);
    }
    
    /**
     * @dev 测试构造函数发射Transfer事件
     */
    function test_ConstructorEmitsTransferEvent() public {
        vm.expectEmit(true, true, false, true);
        emit Transfer(address(0), owner, INITIAL_SUPPLY);
        
        new MyToken(TOKEN_NAME, TOKEN_SYMBOL, INITIAL_SUPPLY);
    }
    
    // ============ 基础ERC20功能测试 ============
    
    /**
     * @dev 测试基本转账功能
     */
    function test_Transfer() public {
        uint256 transferAmount = 1000 * 1e18;
        
        // 执行转账
        bool success = token.transfer(alice, transferAmount);
        
        // 验证转账结果
        assertTrue(success);
        assertEq(token.balanceOf(owner), INITIAL_SUPPLY - transferAmount);
        assertEq(token.balanceOf(alice), transferAmount);
    }
    
    /**
     * @dev 测试转账事件发射
     */
    function test_TransferEmitsEvent() public {
        uint256 transferAmount = 1000 * 1e18;
        
        vm.expectEmit(true, true, false, true);
        emit Transfer(owner, alice, transferAmount);
        
        token.transfer(alice, transferAmount);
    }
    
    /**
     * @dev 测试授权功能
     */
    function test_Approve() public {
        uint256 approveAmount = 2000 * 1e18;
        
        // 执行授权
        bool success = token.approve(alice, approveAmount);
        
        // 验证授权结果
        assertTrue(success);
        assertEq(token.allowance(owner, alice), approveAmount);
    }
    
    /**
     * @dev 测试授权事件发射
     */
    function test_ApproveEmitsEvent() public {
        uint256 approveAmount = 2000 * 1e18;
        
        vm.expectEmit(true, true, false, true);
        emit Approval(owner, alice, approveAmount);
        
        token.approve(alice, approveAmount);
    }
    
    /**
     * @dev 测试授权转账功能
     */
    function test_TransferFrom() public {
        uint256 approveAmount = 3000 * 1e18;
        uint256 transferAmount = 1500 * 1e18;
        
        // 先给owner一些余额
        token.transfer(owner, approveAmount);
        
        // 先给alice一些余额
        token.transfer(alice, approveAmount);
        
        // alice授权owner转账approveAmount
        vm.prank(alice);
        token.approve(owner, approveAmount);
        
        // 使用alice账户执行授权转账
        vm.prank(owner);
        bool success = token.transferFrom(alice, bob, transferAmount);
        
        // 验证转账结果
        assertTrue(success);
        assertEq(token.balanceOf(alice), approveAmount - transferAmount);
        assertEq(token.balanceOf(bob), transferAmount);
        assertEq(token.allowance(alice, owner), approveAmount - transferAmount);
    }
    
    /**
     * @dev 测试授权转账事件发射
     */
    function test_TransferFromEmitsEvent() public {
        uint256 approveAmount = 3000 * 1e18;
        uint256 transferAmount = 1500 * 1e18;
        
        token.approve(alice, approveAmount);
        
        vm.expectEmit(true, true, false, true);
        emit Transfer(owner, bob, transferAmount);
        
        vm.prank(alice);
        token.transferFrom(owner, bob, transferAmount);
    }
    
    // ============ 边界条件和错误情况测试 ============
    
    /**
     * @dev 测试转账金额为0是否成功
     */
    function test_TransferZeroAmount() public {
        bool success = token.transfer(alice, 0);
        assertTrue(success);
        assertEq(token.balanceOf(alice), 0);
    }
    
    /**
     * @dev 测试转账给自地址是否成功
     */
    function test_TransferToSelf() public {
        uint256 initialBalance = token.balanceOf(owner);
        uint256 transferAmount = 1000 * 1e18;
        
        bool success = token.transfer(owner, transferAmount);
        
        assertTrue(success);
        assertEq(token.balanceOf(owner), initialBalance);
    }
    
    /**
     * @dev 测试转账超过余额应该失败
     */
    function test_TransferExceedsBalance() public {
        uint256 excessiveAmount = INITIAL_SUPPLY + 1;
        
        vm.expectRevert();
        token.transfer(alice, excessiveAmount);
    }
    
    /**
     * @dev 测试向零地址转账应该失败
     */
    function test_TransferToZeroAddress() public {
        uint256 transferAmount = 1000 * 1e18;
        
        vm.expectRevert();
        token.transfer(address(0), transferAmount);
    }
    
    /**
     * @dev 测试授权转账超过授权额度应该失败
     */
    function test_TransferFromExceedsAllowance() public {
        uint256 approveAmount = 1000 * 1e18;
        uint256 transferAmount = 1500 * 1e18;
        
        token.approve(alice, approveAmount);
        
        vm.prank(alice);
        vm.expectRevert();
        token.transferFrom(owner, bob, transferAmount);
    }
    
    /**
     * @dev 测试未授权的转账应该失败
     */
    function test_TransferFromWithoutApproval() public {
        uint256 transferAmount = 1000 * 1e18;
        
        vm.prank(alice);
        vm.expectRevert();
        token.transferFrom(owner, bob, transferAmount);
    }
    
    /**
     * @dev 测试授权转账超过余额应该失败
     */
    function test_TransferFromExceedsBalance() public {
        // 先给alice一些余额
        token.transfer(alice, 1000 * 1e18);
        
        // alice授权bob转账超过她的余额
        vm.prank(alice);
        token.approve(bob, 2000 * 1e18);
        
        vm.prank(bob);
        vm.expectRevert();
        token.transferFrom(alice, charlie, 1500 * 1e18);
    }
    
    // ============ Fuzz测试 ============
    
    /**
     * @dev Fuzz测试：随机金额转账是否成功
     */
    function testFuzz_Transfer(uint256 amount) public {
        // 限制金额在合理范围内
        vm.assume(amount <= INITIAL_SUPPLY);
        
        bool success = token.transfer(alice, amount);
        
        assertTrue(success);
        assertEq(token.balanceOf(alice), amount);
        assertEq(token.balanceOf(owner), INITIAL_SUPPLY - amount);
    }
    
    /**
     * @dev Fuzz测试：随机金额授权是否成功
     */
    function testFuzz_Approve(uint256 amount) public {
        bool success = token.approve(alice, amount);
        
        assertTrue(success);
        assertEq(token.allowance(owner, alice), amount);
    }
    
    /**
     * @dev Fuzz测试：随机金额授权转账是否成功
     */
    function testFuzz_TransferFrom(uint256 approveAmount, uint256 transferAmount) public {
        // 限制approveAmount在合理范围内，避免溢出
        vm.assume(approveAmount <= type(uint256).max / 2);
        // 限制transferAmount在合理范围内
        vm.assume(transferAmount <= INITIAL_SUPPLY);
        // 确保approveAmount大于等于transferAmount  
        vm.assume(transferAmount <= approveAmount);
        // 确保approveAmount大于等于transferAmount  
        vm.assume(approveAmount >= transferAmount);

        token.approve(alice, approveAmount);

        vm.prank(alice);
        bool success = token.transferFrom(owner, bob, transferAmount);

        assertTrue(success);
        assertEq(token.balanceOf(bob), transferAmount);
        assertEq(token.balanceOf(owner), INITIAL_SUPPLY - transferAmount);
        assertEq(token.allowance(owner, alice), approveAmount - transferAmount);
    }
    function invariant_TotalSupplyConstant() public {
        assertEq(token.totalSupply(), INITIAL_SUPPLY);
    }
    
    /**
     * @dev 测试所有余额之和等于总供应量
     */
    function test_BalanceSumEqualsTotalSupply() public {
        // 进行一些转账操作
        token.transfer(alice, 1000 * 1e18);
        token.transfer(bob, 2000 * 1e18);
        
        vm.prank(alice);
        token.transfer(charlie, 500 * 1e18);
        
        // 验证所有余额之和等于总供应量
        uint256 totalBalance = token.balanceOf(owner) + 
                              token.balanceOf(alice) + 
                              token.balanceOf(bob) + 
                              token.balanceOf(charlie);
        
        assertEq(totalBalance, INITIAL_SUPPLY);
    }
    
    // ============ 集成测试 ============
    
    /**
     * @dev 测试复杂的转账场景：owner -> alice -> bob -> charlie
     */
    function test_ComplexTransferScenario() public {
        // 场景：owner -> alice -> bob -> charlie
        uint256 step1Amount = 5000 * 1e18;
        uint256 step2Amount = 3000 * 1e18;
        uint256 step3Amount = 1000 * 1e18;
        
        // Step 1: owner转给alice
        token.transfer(alice, step1Amount);
        
        // Step 2: alice转给bob
        vm.prank(alice);
        token.transfer(bob, step2Amount);
        
        // Step 3: bob转给charlie
        vm.prank(bob);
        token.transfer(charlie, step3Amount);
        
        // 验证最终余额分布
        assertEq(token.balanceOf(owner), INITIAL_SUPPLY - step1Amount);
        assertEq(token.balanceOf(alice), step1Amount - step2Amount);
        assertEq(token.balanceOf(bob), step2Amount - step3Amount);
        assertEq(token.balanceOf(charlie), step3Amount);
    }
    
    /**
     * @dev 测试复杂的授权转账场景：owner -> alice -> bob -> charlie
     */
    function test_ComplexApprovalScenario() public {
        uint256 approveAmount = 10000 * 1e18;
        uint256 transfer1 = 3000 * 1e18;
        uint256 transfer2 = 2000 * 1e18;
        
        // owner授权alice
        token.approve(alice, approveAmount);
        
        // alice代表owner转账给bob
        vm.prank(alice);
        token.transferFrom(owner, bob, transfer1);
        
        // alice代表owner转账给charlie
        vm.prank(alice);
        token.transferFrom(owner, charlie, transfer2);
        
        // 验证结果
        assertEq(token.balanceOf(bob), transfer1);
        assertEq(token.balanceOf(charlie), transfer2);
        assertEq(token.balanceOf(owner), INITIAL_SUPPLY - transfer1 - transfer2);
        assertEq(token.allowance(owner, alice), approveAmount - transfer1 - transfer2);
    }

}
