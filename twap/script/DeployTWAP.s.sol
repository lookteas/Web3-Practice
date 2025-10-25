// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import "forge-std/Script.sol";
import "../src/MemeTWAP.sol";

contract DeployTWAP is Script {
    function run() external {
        uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");
        address memeFactory = vm.envAddress("MEME_FACTORY_ADDRESS");
        
        vm.startBroadcast(deployerPrivateKey);
        
        // Deploy MemeTWAP contract
        MemeTWAP memeTWAP = new MemeTWAP(memeFactory);
        
        vm.stopBroadcast();
        
        console.log("MemeTWAP deployed to:", address(memeTWAP));
        console.log("MemeFactory address:", memeFactory);
        
        // Save deployment info to JSON file
        string memory json = string(
            abi.encodePacked(
                '{\n',
                '  "memeTWAP": "', vm.toString(address(memeTWAP)), '",\n',
                '  "memeFactory": "', vm.toString(memeFactory), '",\n',
                '  "deployer": "', vm.toString(vm.addr(deployerPrivateKey)), '",\n',
                '  "timestamp": ', vm.toString(block.timestamp), ',\n',
                '  "blockNumber": ', vm.toString(block.number), '\n',
                '}'
            )
        );
        
        vm.writeFile("./deployments/twap-deployment.json", json);
        console.log("Deployment info saved to ./deployments/twap-deployment.json");
    }
}