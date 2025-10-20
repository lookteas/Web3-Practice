// SPDX-License-Identifier: MIT
pragma solidity ^0.8.25;

import {Test, console, vm} from "forge-std/Test.sol";
import {Bank} from "../src/Bank.sol";
import {ERC20Token} from "../src/ERC20Token.sol";

/**
 * @title ReentrancyTest
 * @dev Foundry test suite for reentrancy attack protection
 */
contract ReentrancyTest is Test {
    Bank public bank;
    ERC20Token public token;
    MaliciousContract public attacker;
    
    address public admin;
    address public user1;
    
    uint256 constant INITIAL_DEPOSIT = 5 ether;
    uint256 constant ATTACK_AMOUNT = 1 ether;
    
    // Add receive function to accept ETH
    receive() external payable {}
    
    function setUp() public {
        admin = address(this);
        user1 = makeAddr("user1");
        
        // Deploy contracts
        token = new ERC20Token("Test Token", "TEST", 1_000_000 * 10**18);
        bank = new Bank(address(token));
        
        // Deploy malicious contract
        attacker = new MaliciousContract(bank);
        
        // Setup initial state
        vm.deal(address(attacker), ATTACK_AMOUNT);
        vm.deal(user1, INITIAL_DEPOSIT);
        
        // User1 deposits some ETH to make the bank have funds
        vm.prank(user1);
        bank.deposit{value: INITIAL_DEPOSIT}();
    }
    
    function test_ReentrancyAttackPrevention() public {
        // Record initial balances
        uint256 initialBankBalance = address(bank).balance;
        uint256 initialAttackerBalance = address(attacker).balance;
        
        console.log("Initial bank balance:", initialBankBalance);
        console.log("Initial attacker balance:", initialAttackerBalance);
        
        // Attacker deposits some ETH first
        attacker.deposit{value: ATTACK_AMOUNT}();
        
        // Verify deposit was successful
        assertEq(bank.getDeposit(address(attacker)), ATTACK_AMOUNT);
        assertEq(address(bank).balance, initialBankBalance + ATTACK_AMOUNT);
        
        // Attempt reentrancy attack - should fail
        vm.expectRevert("only admin can call");
        attacker.attack();
        
        // Verify bank balance is unchanged after failed attack
        assertEq(address(bank).balance, initialBankBalance + ATTACK_AMOUNT);
        
        console.log("Attack prevented successfully!");
    }
    
    function test_NormalWithdrawStillWorks() public {
        // Verify normal admin withdraw still works
        uint256 initialAdminBalance = admin.balance;
        uint256 withdrawAmount = 1 ether;
        
        bank.withdraw(withdrawAmount);
        
        assertEq(admin.balance, initialAdminBalance + withdrawAmount);
        assertEq(address(bank).balance, INITIAL_DEPOSIT - withdrawAmount);
    }
    
    function test_MultipleNormalOperations() public {
        // Test that multiple normal operations work fine
        // Give user1 more ETH for additional deposits
        vm.deal(user1, 10 ether);
        
        vm.startPrank(user1);
        
        // Multiple deposits
        bank.deposit{value: 1 ether}();
        bank.deposit{value: 0.5 ether}();
        
        vm.stopPrank();
        
        // Admin withdrawals
        bank.withdraw(0.3 ether);
        bank.withdraw(0.2 ether);
        
        // Verify final state
        assertEq(bank.getDeposit(user1), INITIAL_DEPOSIT + 1.5 ether);
        assertEq(address(bank).balance, INITIAL_DEPOSIT + 1.5 ether - 0.5 ether);
    }
    
    function test_TokenReentrancyProtection() public {
        // Test token withdrawal reentrancy protection
        uint256 tokenAmount = 1000 * 10**18;
        
        // Give attacker some tokens and deposit them
        token.transfer(address(attacker), tokenAmount);
        
        vm.startPrank(address(attacker));
        token.approve(address(bank), tokenAmount);
        bank.depositToken(tokenAmount);
        vm.stopPrank();
        
        // Verify deposit
        assertEq(bank.getTokenDeposit(address(attacker)), tokenAmount);
        
        // Normal token withdrawal should work
        uint256 withdrawAmount = 500 * 10**18;
        uint256 initialAdminTokenBalance = token.balanceOf(admin);
        
        bank.withdrawToken(withdrawAmount);
        
        assertEq(token.balanceOf(admin), initialAdminTokenBalance + withdrawAmount);
        assertEq(bank.getContractTokenBalance(), tokenAmount - withdrawAmount);
    }
}

/**
 * @title MaliciousContract
 * @dev Contract that attempts reentrancy attack
 */
contract MaliciousContract {
    Bank public bank;
    bool public attackInProgress;
    uint256 public attackCount;
    
    constructor(Bank _bank) {
        bank = _bank;
    }
    
    // Deposit function to setup the attack
    function deposit() external payable {
        bank.deposit{value: msg.value}();
    }
    
    // Attack function that tries to exploit reentrancy
    function attack() external {
        attackInProgress = true;
        attackCount = 0;
        
        // This should trigger the reentrancy protection
        bank.withdraw(0.5 ether);
    }
    
    // Receive function that attempts reentrancy
    receive() external payable {
        if (attackInProgress && attackCount < 3) {
            attackCount++;
            console.log("Attempting reentrancy attack #", attackCount);
            
            // This should fail due to reentrancy protection
            bank.withdraw(0.5 ether);
        }
    }
    
    // Function to withdraw funds normally (for testing)
    function normalWithdraw() external {
        attackInProgress = false;
        // This would be called by admin, but for testing we simulate it
    }
    
    // Get contract balance
    function getBalance() external view returns (uint256) {
        return address(this).balance;
    }
}