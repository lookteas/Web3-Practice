// SPDX-License-Identifier: MIT
pragma solidity ^0.8.25;

import {Script, console} from "forge-std/Script.sol";
import {DelegateContract} from "../src/DelegateContract.sol";
import {TokenBank} from "../src/TokenBank.sol";

contract DeployScript is Script {
    function run() external {
        uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");
        
        vm.startBroadcast(deployerPrivateKey);
        
        // 部署DelegateContract
        DelegateContract delegateContract = new DelegateContract();
        console.log("DelegateContract deployed at:", address(delegateContract));
        
        // 部署TokenBank
        TokenBank tokenBank = new TokenBank();
        console.log("TokenBank deployed at:", address(tokenBank));
        
        vm.stopBroadcast();
        
        // 输出部署信息
        console.log("=== Deployment Summary ===");
        console.log("DelegateContract:", address(delegateContract));
        console.log("TokenBank:", address(tokenBank));
        console.log("Deployer:", vm.addr(deployerPrivateKey));
    }
}