// SPDX-License-Identifier: MIT
pragma solidity ^0.8.25;

import "forge-std/Script.sol";
import "../src/RebaseToken.sol";

contract DeployRebaseToken is Script {
    function run() external {
        // Use the private key passed via command line or default to first anvil account
        uint256 deployerPrivateKey = vm.envOr("PRIVATE_KEY", uint256(0xac0974bec39a17e36ba4a6b4d238ff944bacb478cbed5efcae784d7bf4f2ff80));
        address deployer = vm.addr(deployerPrivateKey);
        
        console.log("Deploying RebaseToken with deployer:", deployer);
        console.log("Deployer balance:", deployer.balance);
        
        vm.startBroadcast(deployerPrivateKey);
        
        // Deploy RebaseToken with 100 million initial supply
        RebaseToken token = new RebaseToken(
            "Rebase Deflation Token",
            "RDT",
            100_000_000 * 1e18, // 100 million tokens
            deployer // Initial owner
        );
        
        vm.stopBroadcast();
        
        console.log("RebaseToken deployed at:", address(token));
        console.log("Token name:", token.name());
        console.log("Token symbol:", token.symbol());
        console.log("Initial supply:", token.totalSupply());
        console.log("Owner:", token.owner());
        console.log("Deployer balance:", token.balanceOf(deployer));
        
        // Log deployment info
        console.log("\n=== Deployment Summary ===");
        console.log("Contract: RebaseToken");
        console.log("Address:", address(token));
        console.log("Network: Use --rpc-url to specify");
        console.log("Verify command:");
        console.log("forge verify-contract", address(token), "src/RebaseToken.sol:RebaseToken --chain-id <CHAIN_ID>");
    }
}