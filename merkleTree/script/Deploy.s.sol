// SPDX-License-Identifier: MIT
pragma solidity ^0.8.25;

import "forge-std/Script.sol";
import "../src/AirdropToken.sol";
import "../src/AirdropNFT.sol";
import "../src/AirdropMerkleNFTMarket.sol";

contract DeployScript is Script {
    function run() external {
        // Use default anvil private key for testing
        uint256 deployerPrivateKey = 0xac0974bec39a17e36ba4a6b4d238ff944bacb478cbed5efcae784d7bf4f2ff80;
        address deployer = vm.addr(deployerPrivateKey);
        
        vm.startBroadcast(deployerPrivateKey);
        
        // Deploy AirdropToken
        AirdropToken token = new AirdropToken(
            "Airdrop Token",
            "ADT",
            18,
            1000000 * 10**18, // 1M tokens
            deployer
        );
        console.log("AirdropToken deployed at:", address(token));
        
        // Deploy AirdropNFT
        AirdropNFT nft = new AirdropNFT(
            "Airdrop NFT",
            "ANFT",
            "https://api.example.com/metadata/",
            deployer
        );
        console.log("AirdropNFT deployed at:", address(nft));
        
        // Example Merkle root (replace with actual root)
        bytes32 merkleRoot = 0x1234567890abcdef1234567890abcdef1234567890abcdef1234567890abcdef;
        
        // Deploy AirdropMerkleNFTMarket
        AirdropMerkleNFTMarket market = new AirdropMerkleNFTMarket(
            address(token),
            address(nft),
            merkleRoot,
            deployer
        );
        console.log("AirdropMerkleNFTMarket deployed at:", address(market));
        
        vm.stopBroadcast();
        
        console.log("Deployment completed successfully!");
        console.log("Token:", address(token));
        console.log("NFT:", address(nft));
        console.log("Market:", address(market));
    }
}