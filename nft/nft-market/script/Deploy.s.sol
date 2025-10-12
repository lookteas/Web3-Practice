// SPDX-License-Identifier: MIT
pragma solidity ^0.8.25;

import "forge-std/Script.sol";
import "../src/MyNFT.sol";
import "../src/NFTMarket.sol";

contract Deploy is Script {
    function run() external {
        uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");
        address deployer = vm.addr(deployerPrivateKey);
        
        console.log("Deploying contracts with the account:", deployer);
        console.log("Account balance:", deployer.balance);
        
        vm.startBroadcast(deployerPrivateKey);
        
        // 部署MyNFT合约
        MyNFT nft = new MyNFT(
            "MyNFT Collection",
            "MNC",
            deployer    // royaltyReceiver
        );
        
        console.log("MyNFT deployed to:", address(nft));
        
        // 部署NFTMarket合约
        NFTMarket market = new NFTMarket(deployer); // feeRecipient
        
        console.log("NFTMarket deployed to:", address(market));
        
        vm.stopBroadcast();
        
        // 输出部署信息
        console.log("\n=== Deployment Summary ===");
        console.log("MyNFT Address:", address(nft));
        console.log("NFTMarket Address:", address(market));
        console.log("Deployer Address:", deployer);
        console.log("Platform Fee:", market.platformFeePercentage(), "basis points");
        console.log("Minimum Price:", market.minimumPrice(), "wei");
    }
}