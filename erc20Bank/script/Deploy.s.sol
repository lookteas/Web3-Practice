// SPDX-License-Identifier: MIT
pragma solidity ^0.8.25;

import {Script, console} from "forge-std/Script.sol";
import {ERC20Token} from "../src/ERC20Token.sol";
import {Bank} from "../src/Bank.sol";
import {BigBank} from "../src/BigBank.sol";

/**
 * @title Deploy Script for ERC20 Bank System
 * @dev Foundry deployment script for ERC20Token, Bank, and BigBank contracts
 * 
 * Usage:
 * - Local deployment: forge script script/Deploy.s.sol --fork-url http://localhost:8545 --broadcast
 * - Testnet deployment: forge script script/Deploy.s.sol --rpc-url $SEPOLIA_RPC_URL --broadcast --verify
 * - Mainnet deployment: forge script script/Deploy.s.sol --rpc-url $MAINNET_RPC_URL --broadcast --verify
 */
contract DeployScript is Script {
    // Deployment addresses (will be set during deployment)
    ERC20Token public token;
    Bank public bank;
    BigBank public bigBank;
    
    // Configuration constants
    string constant TOKEN_NAME = "Bank Token";
    string constant TOKEN_SYMBOL = "BANK";
    uint256 constant INITIAL_SUPPLY = 1_000_000 * 10**18; // 1M tokens
    
    function run() external {
        // For local deployment, use a default address (Anvil account #0)
        address deployer = 0xf39Fd6e51aad88F6F4ce6aB8827279cffFb92266;
        uint256 deployerPrivateKey = 0xac0974bec39a17e36ba4a6b4d238ff944bacb478cbed5efcae784d7bf4f2ff80;
        
        console.log("Deploying contracts with account:", deployer);
        console.log("Account balance:", deployer.balance);
        
        vm().startBroadcast(deployerPrivateKey);
        
        // Step 1: Deploy ERC20 Token
        console.log("\n=== Deploying ERC20 Token ===");
        token = new ERC20Token(TOKEN_NAME, TOKEN_SYMBOL, INITIAL_SUPPLY);
        console.log("ERC20Token deployed at:", address(token));
        console.log("Token name:", token.name());
        console.log("Token symbol:", token.symbol());
        console.log("Total supply:", token.totalSupply());
        
        // Step 2: Deploy Bank contract
        console.log("\n=== Deploying Bank Contract ===");
        bank = new Bank(address(token));
        console.log("Bank deployed at:", address(bank));
        console.log("Bank admin:", bank.admin());
        console.log("Bank token address:", bank.getTokenAddress());
        
        // Step 3: Deploy BigBank contract
        console.log("\n=== Deploying BigBank Contract ===");
        bigBank = new BigBank(address(token));
        console.log("BigBank deployed at:", address(bigBank));
        console.log("BigBank admin:", bigBank.admin());
        console.log("BigBank token address:", bigBank.getTokenAddress());
        console.log("BigBank min ETH deposit:", bigBank.getMinEthDeposit());
        console.log("BigBank min token deposit:", bigBank.getMinTokenDeposit());
        
        // Step 4: Setup initial configuration
        console.log("\n=== Initial Configuration ===");
        
        // Approve tokens for testing (optional)
        uint256 approvalAmount = 100_000 * 10**18; // 100k tokens
        token.approve(address(bank), approvalAmount);
        token.approve(address(bigBank), approvalAmount);
        console.log("Approved", approvalAmount, "tokens for Bank contract");
        console.log("Approved", approvalAmount, "tokens for BigBank contract");
        
        vm().stopBroadcast();
        
        // Step 5: Verification and summary
        console.log("\n=== Deployment Summary ===");
        console.log("ERC20Token:", address(token));
        console.log("Bank:", address(bank));
        console.log("BigBank:", address(bigBank));
        console.log("Deployer:", deployer);
        
        // Verify deployment
        verifyDeployment();
    }
    
    /**
     * @dev Verify that all contracts are deployed correctly
     */
    function verifyDeployment() internal view {
        console.log("\n=== Deployment Verification ===");
        
        // Verify ERC20Token
        require(address(token) != address(0), "ERC20Token not deployed");
        require(token.totalSupply() == INITIAL_SUPPLY, "Incorrect token supply");
        console.log("ERC20Token verification passed");
        
        // Verify Bank
        require(address(bank) != address(0), "Bank not deployed");
        require(bank.getTokenAddress() == address(token), "Bank token address mismatch");
        console.log("Bank verification passed");
        
        // Verify BigBank
        require(address(bigBank) != address(0), "BigBank not deployed");
        require(bigBank.getTokenAddress() == address(token), "BigBank token address mismatch");
        require(bigBank.getMinEthDeposit() > 0, "BigBank min ETH deposit not set");
        require(bigBank.getMinTokenDeposit() > 0, "BigBank min token deposit not set");
        console.log("BigBank verification passed");
        
        console.log("All contracts deployed and verified successfully!");
    }
    
    /**
     * @dev Get deployment information for external use
     */
    function getDeploymentInfo() external view returns (
        address tokenAddress,
        address bankAddress,
        address bigBankAddress
    ) {
        return (address(token), address(bank), address(bigBank));
    }
}

/**
 * @title Local Development Deploy Script
 * @dev Simplified deployment script for local development with additional setup
 */
contract LocalDeployScript is Script {
    function run() external {
        uint256 deployerPrivateKey = 0xac0974bec39a17e36ba4a6b4d238ff944bacb478cbed5efcae784d7bf4f2ff80; // Anvil default key
        address deployer = vm().addr(deployerPrivateKey);
        
        console.log("Local deployment with account:", deployer);
        
        vm().startBroadcast(deployerPrivateKey);
        
        // Deploy contracts
        ERC20Token token = new ERC20Token("Test Bank Token", "TBANK", 10_000_000 * 10**18);
        Bank bank = new Bank(address(token));
        BigBank bigBank = new BigBank(address(token));
        
        // Setup for testing
        token.approve(address(bank), type(uint256).max);
        token.approve(address(bigBank), type(uint256).max);
        
        // Transfer some tokens to different addresses for testing
        address testUser1 = 0x70997970C51812dc3A010C7d01b50e0d17dc79C8;
        address testUser2 = 0x3C44CdDdB6a900fa2b585dd299e03d12FA4293BC;
        
        token.transfer(testUser1, 50_000 * 10**18);
        token.transfer(testUser2, 50_000 * 10**18);
        
        vm().stopBroadcast();
        
        console.log("Local deployment completed:");
        console.log("Token:", address(token));
        console.log("Bank:", address(bank));
        console.log("BigBank:", address(bigBank));
    }
}