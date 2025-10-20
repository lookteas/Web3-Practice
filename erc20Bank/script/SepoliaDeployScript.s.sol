// SPDX-License-Identifier: MIT
pragma solidity ^0.8.25;

import {Script, console} from "forge-std/Script.sol";
import {ERC20Token} from "../src/ERC20Token.sol";
import {Bank} from "../src/Bank.sol";
import {BigBank} from "../src/BigBank.sol";

/**
 * @title Sepolia Testnet Deploy Script
 * @dev Deployment script specifically for Sepolia testnet
 */
contract SepoliaDeployScript is Script {
    // Token configuration
    string constant TOKEN_NAME = "Hai Token";
    string constant TOKEN_SYMBOL = "HAI";
    uint256 constant INITIAL_SUPPLY = 100_000_000 * 10**18; // 100 million tokens
    
    // Deployed contracts
    ERC20Token public token;
    Bank public bank;
    BigBank public bigBank;
    
    function run() external {
        // For Sepolia deployment, we'll use the private key from environment
        uint256 deployerPrivateKey;
        
        // Try to get private key from environment
        try vm().envUint("PRIVATE_KEY") returns (uint256 key) {
            deployerPrivateKey = key;
        } catch {
            revert("PRIVATE_KEY environment variable not found. Please set it in .env file");
        }
        
        address deployer = vm().addr(deployerPrivateKey);
        
        console.log("=== Sepolia Testnet Deployment ===");
        console.log("Deploying with account:", deployer);
        console.log("Account balance:", deployer.balance);
        
        // Check if we have enough ETH for deployment
        require(deployer.balance > 0.01 ether, "Insufficient ETH for deployment");
        
        vm().startBroadcast(deployerPrivateKey);
        
        // 1. Deploy ERC20 Token
        console.log("\n1. Deploying ERC20Token...");
        token = new ERC20Token(TOKEN_NAME, TOKEN_SYMBOL, INITIAL_SUPPLY);
        console.log("ERC20Token deployed at:", address(token));
        console.log("Token name:", token.name());
        console.log("Token symbol:", token.symbol());
        console.log("Total supply:", token.totalSupply());
        
        // 2. Deploy Bank
        console.log("\n2. Deploying Bank...");
        bank = new Bank(address(token));
        console.log("Bank deployed at:", address(bank));
        console.log("Bank admin:", bank.admin());
        console.log("Bank token address:", bank.getTokenAddress());
        
        // 3. Deploy BigBank
        console.log("\n3. Deploying BigBank...");
        bigBank = new BigBank(address(token));
        console.log("BigBank deployed at:", address(bigBank));
        console.log("BigBank admin:", bigBank.admin());
        console.log("BigBank token address:", bigBank.getTokenAddress());
        console.log("BigBank min ETH deposit:", bigBank.getMinEthDeposit());
        console.log("BigBank min token deposit:", bigBank.getMinTokenDeposit());
        
        // 4. Initial setup - approve tokens for contracts
        console.log("\n4. Setting up initial approvals...");
        token.approve(address(bank), type(uint256).max);
        token.approve(address(bigBank), type(uint256).max);
        console.log("Token approvals set for both Bank contracts");
        
        vm().stopBroadcast();
        
        // 5. Verify deployment
        console.log("\n5. Verifying deployment...");
        verifyDeployment();
        
        // 6. Display deployment summary
        console.log("\n=== Deployment Summary ===");
        console.log("ERC20Token:", address(token));
        console.log("Bank:", address(bank));
        console.log("BigBank:", address(bigBank));
        console.log("Deployer:", deployer);
        console.log("Network: Sepolia Testnet");
        console.log("Deployment completed successfully!");
    }
    
    /**
     * @dev Verify that all contracts are deployed correctly
     */
    function verifyDeployment() internal view {
        // Verify Token
        require(address(token) != address(0), "Token not deployed");
        require(keccak256(bytes(token.name())) == keccak256(bytes(TOKEN_NAME)), "Token name mismatch");
        require(keccak256(bytes(token.symbol())) == keccak256(bytes(TOKEN_SYMBOL)), "Token symbol mismatch");
        require(token.totalSupply() == INITIAL_SUPPLY, "Token supply mismatch");
        console.log("Token verification passed");
        
        // Verify Bank
        require(address(bank) != address(0), "Bank not deployed");
        require(bank.getTokenAddress() == address(token), "Bank token address mismatch");
        require(bank.admin() != address(0), "Bank admin not set");
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