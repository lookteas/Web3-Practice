// SPDX-License-Identifier: MIT
pragma solidity ^0.8.25;

import {Test, console, vm} from "forge-std/Test.sol";
import {Bank} from "../src/Bank.sol";
import {BigBank} from "../src/BigBank.sol";
import {ERC20Token} from "../src/ERC20Token.sol";

/**
 * @title BankTest
 * @dev Foundry test suite for Bank and BigBank contracts with ERC20 integration
 */
contract BankTest is Test {
    Bank public bank;
    BigBank public bigBank;
    ERC20Token public token;
    
    address public admin;
    address public user1;
    address public user2;
    address public user3;
    
    // Test constants
    uint256 constant INITIAL_TOKEN_SUPPLY = 1_000_000 * 10**18;
    uint256 constant USER_TOKEN_AMOUNT = 10_000 * 10**18;
    uint256 constant DEPOSIT_AMOUNT = 1000 * 10**18;
    uint256 constant ETH_DEPOSIT_AMOUNT = 1 ether;
    
    function setUp() public {
        // Set up test accounts
        admin = address(this);
        user1 = makeAddr("user1");
        user2 = makeAddr("user2");
        user3 = makeAddr("user3");
        
        // Deploy ERC20 token
        token = new ERC20Token("Test Bank Token", "TBANK", INITIAL_TOKEN_SUPPLY);
        
        // Deploy Bank contract
        bank = new Bank(address(token));
        
        // Deploy BigBank contract
        bigBank = new BigBank(address(token));
        
        // Distribute tokens to test users
        token.transfer(user1, USER_TOKEN_AMOUNT);
        token.transfer(user2, USER_TOKEN_AMOUNT);
        token.transfer(user3, USER_TOKEN_AMOUNT);
        
        // Give test users some ETH
        vm.deal(user1, 10 ether);
        vm.deal(user2, 10 ether);
        vm.deal(user3, 10 ether);
    }
    
    // Add receive function to accept ETH
    receive() external payable {}
    
    // ============ Bank Contract Tests ============
    
    function test_BankDeployment() public {
        assertEq(bank.admin(), admin);
        assertEq(bank.getTokenAddress(), address(token));
        assertEq(bank.getContractBalance(), 0);
        assertEq(bank.getContractTokenBalance(), 0);
    }
    
    function test_EthDeposit() public {
        vm.prank(user1);
        bank.deposit{value: ETH_DEPOSIT_AMOUNT}();
        
        assertEq(bank.getDeposit(user1), ETH_DEPOSIT_AMOUNT);
        assertEq(bank.getContractBalance(), ETH_DEPOSIT_AMOUNT);
        assertEq(bank.getDepositorsCount(), 1);
    }
    
    function test_TokenDeposit() public {
        vm.startPrank(user1);
        token.approve(address(bank), DEPOSIT_AMOUNT);
        bank.depositToken(DEPOSIT_AMOUNT);
        vm.stopPrank();
        
        assertEq(bank.getTokenDeposit(user1), DEPOSIT_AMOUNT);
        assertEq(bank.getContractTokenBalance(), DEPOSIT_AMOUNT);
        assertEq(bank.getTokenDepositorsCount(), 1);
    }
    
    function test_TokenDepositWithCallback() public {
        vm.startPrank(user1);
        token.transferWithCallback(address(bank), DEPOSIT_AMOUNT);
        vm.stopPrank();
        
        assertEq(bank.getTokenDeposit(user1), DEPOSIT_AMOUNT);
        assertEq(bank.getContractTokenBalance(), DEPOSIT_AMOUNT);
    }
    
    function test_MultipleDeposits() public {
        // User1 deposits ETH and tokens
        vm.startPrank(user1);
        bank.deposit{value: ETH_DEPOSIT_AMOUNT}();
        token.approve(address(bank), DEPOSIT_AMOUNT);
        bank.depositToken(DEPOSIT_AMOUNT);
        vm.stopPrank();
        
        // User2 deposits ETH and tokens
        vm.startPrank(user2);
        bank.deposit{value: ETH_DEPOSIT_AMOUNT * 2}();
        token.approve(address(bank), DEPOSIT_AMOUNT * 2);
        bank.depositToken(DEPOSIT_AMOUNT * 2);
        vm.stopPrank();
        
        assertEq(bank.getDeposit(user1), ETH_DEPOSIT_AMOUNT);
        assertEq(bank.getDeposit(user2), ETH_DEPOSIT_AMOUNT * 2);
        assertEq(bank.getTokenDeposit(user1), DEPOSIT_AMOUNT);
        assertEq(bank.getTokenDeposit(user2), DEPOSIT_AMOUNT * 2);
        assertEq(bank.getDepositorsCount(), 2);
        assertEq(bank.getTokenDepositorsCount(), 2);
    }
    
    function test_TopDepositors() public {
        // Create deposits with different amounts
        vm.prank(user1);
        bank.deposit{value: 1 ether}();
        
        vm.prank(user2);
        bank.deposit{value: 3 ether}();
        
        vm.prank(user3);
        bank.deposit{value: 2 ether}();
        
        address[3] memory topDepositors = bank.getTopDepositors();
        assertEq(topDepositors[0], user2); // 3 ether
        assertEq(topDepositors[1], user3); // 2 ether
        assertEq(topDepositors[2], user1); // 1 ether
    }
    
    function test_TopTokenDepositors() public {
        // Create token deposits with different amounts
        vm.startPrank(user1);
        token.approve(address(bank), 1000 * 10**18);
        bank.depositToken(1000 * 10**18);
        vm.stopPrank();
        
        vm.startPrank(user2);
        token.approve(address(bank), 3000 * 10**18);
        bank.depositToken(3000 * 10**18);
        vm.stopPrank();
        
        vm.startPrank(user3);
        token.approve(address(bank), 2000 * 10**18);
        bank.depositToken(2000 * 10**18);
        vm.stopPrank();
        
        address[3] memory topTokenDepositors = bank.getTopTokenDepositors();
        assertEq(topTokenDepositors[0], user2); // 3000 tokens
        assertEq(topTokenDepositors[1], user3); // 2000 tokens
        assertEq(topTokenDepositors[2], user1); // 1000 tokens
    }
    
    function test_AdminWithdraw() public {
        // Deposit some ETH
        vm.prank(user1);
        bank.deposit{value: ETH_DEPOSIT_AMOUNT}();
        
        uint256 initialBalance = admin.balance;
        bank.withdraw(ETH_DEPOSIT_AMOUNT / 2);
        
        assertEq(admin.balance, initialBalance + ETH_DEPOSIT_AMOUNT / 2);
        assertEq(bank.getContractBalance(), ETH_DEPOSIT_AMOUNT / 2);
    }
    
    function test_AdminTokenWithdraw() public {
        // Deposit some tokens
        vm.startPrank(user1);
        token.approve(address(bank), DEPOSIT_AMOUNT);
        bank.depositToken(DEPOSIT_AMOUNT);
        vm.stopPrank();
        
        uint256 initialBalance = token.balanceOf(admin);
        bank.withdrawToken(DEPOSIT_AMOUNT / 2);
        
        assertEq(token.balanceOf(admin), initialBalance + DEPOSIT_AMOUNT / 2);
        assertEq(bank.getContractTokenBalance(), DEPOSIT_AMOUNT / 2);
    }
    
    function test_ReentrancyProtection() public {
        // This test ensures the reentrancy protection works
        vm.prank(user1);
        bank.deposit{value: ETH_DEPOSIT_AMOUNT}();
        
        // For this simple test, we just verify the deposit worked
        // Real reentrancy tests are in ReentrancyTest.t.sol
        assertEq(bank.getDeposit(user1), ETH_DEPOSIT_AMOUNT);
    }
    
    // ============ BigBank Contract Tests ============
    
    function test_BigBankDeployment() public {
        assertEq(bigBank.admin(), admin);
        assertEq(bigBank.getTokenAddress(), address(token));
        assertEq(bigBank.getMinEthDeposit(), 0.001 ether);
        assertEq(bigBank.getMinTokenDeposit(), 1000 * 10**18);
    }
    
    function test_BigBankMinEthDeposit() public {
        // Should fail with amount below minimum
        vm.prank(user1);
        vm.expectRevert("deposit amount must be at least 0.001 ether");
        bigBank.deposit{value: 0.0005 ether}();
        
        // Should succeed with amount above minimum
        vm.prank(user1);
        bigBank.deposit{value: 0.002 ether}();
        assertEq(bigBank.getDeposit(user1), 0.002 ether);
    }
    
    function test_BigBankMinTokenDeposit() public {
        // Should fail with amount below minimum
        vm.startPrank(user1);
        token.approve(address(bigBank), 5 * 10**18);
        vm.expectRevert("token deposit amount must be at least 1000 tokens");
        bigBank.depositToken(5 * 10**18);
        vm.stopPrank();
        
        // Should succeed with amount above minimum
        vm.startPrank(user1);
        token.approve(address(bigBank), 2000 * 10**18);
        bigBank.depositToken(2000 * 10**18);
        vm.stopPrank();
        
        assertEq(bigBank.getTokenDeposit(user1), 2000 * 10**18);
    }
    
    // ============ Edge Cases and Error Tests ============
    
    function test_OnlyAdminModifier() public {
        vm.prank(user1);
        vm.expectRevert("only admin can call");
        bank.withdraw(1 ether);
        
        vm.prank(user1);
        vm.expectRevert("only admin can call");
        bank.withdrawToken(1000 * 10**18);
    }
    
    function test_InsufficientBalance() public {
        vm.expectRevert("no balance to withdraw");
        bank.withdraw(1 ether);
        
        vm.expectRevert("no token balance to withdraw");
        bank.withdrawToken(1000 * 10**18);
    }
    
    function test_ZeroDeposit() public {
        vm.prank(user1);
        vm.expectRevert("deposit amount must be greater than 0");
        bank.deposit{value: 0}();
        
        vm.startPrank(user1);
        token.approve(address(bank), 0);
        vm.expectRevert("deposit amount must be greater than 0");
        bank.depositToken(0);
        vm.stopPrank();
    }
    
    function test_UnauthorizedTokenCallback() public {
        // Deploy a fake token to test unauthorized callback
        ERC20Token fakeToken = new ERC20Token("Fake", "FAKE", 1000 * 10**18);
        
        vm.expectRevert("Only supported token can call");
        bank.tokensReceived(user1, address(bank), 100 * 10**18);
    }
    
    // ============ Fuzz Tests ============
    
    function testFuzz_EthDeposit(uint256 amount) public {
        vm.assume(amount > 0 && amount <= 100 ether);
        
        vm.deal(user1, amount);
        vm.prank(user1);
        bank.deposit{value: amount}();
        
        assertEq(bank.getDeposit(user1), amount);
        assertEq(bank.getContractBalance(), amount);
    }
    
    function testFuzz_TokenDeposit(uint256 amount) public {
        vm.assume(amount > 0 && amount <= USER_TOKEN_AMOUNT);
        
        vm.startPrank(user1);
        token.approve(address(bank), amount);
        bank.depositToken(amount);
        vm.stopPrank();
        
        assertEq(bank.getTokenDeposit(user1), amount);
        assertEq(bank.getContractTokenBalance(), amount);
    }
}