// SPDX-License-Identifier: MIT
pragma solidity ^0.8.25;

import "forge-std/Script.sol";
import "../contracts/ERC20.sol";
import "../contracts/Permit2.sol";
import "../contracts/Bank.sol";

contract DeployScript is Script {
    function run() external {
        // 使用命令行传入的私钥或默认私钥
        uint256 deployerPrivateKey = 0xac0974bec39a17e36ba4a6b4d238ff944bacb478cbed5efcae784d7bf4f2ff80;
        vm.startBroadcast(deployerPrivateKey);

        // 部署 ERC20 代币合约
        ERC20Token token = new ERC20Token();
        console.log("ERC20Token deployed at:", address(token));

        // 部署 Permit2 合约
        Permit2 permit2 = new Permit2();
        console.log("Permit2 deployed at:", address(permit2));

        // 部署 Bank 合约
        Bank bank = new Bank(address(permit2));
        console.log("Bank deployed at:", address(bank));

        // 输出合约信息
        console.log("=== Deployment Summary ===");
        console.log("Token Name:", token.name());
        console.log("Token Symbol:", token.symbol());
        console.log("Token Total Supply:", token.totalSupply());
        console.log("Deployer Balance:", token.balanceOf(msg.sender));
        console.log("Permit2 Domain Separator:", vm.toString(permit2.DOMAIN_SEPARATOR()));

        vm.stopBroadcast();
    }
}