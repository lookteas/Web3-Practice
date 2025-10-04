// SPDX-License-Identifier: MIT
pragma solidity ^0.8.25;

import "forge-std/Script.sol";
import "../src/MyToken.sol";

contract DeployMyToken is Script {
    function run() external {
        // 从环境变量或默认私钥加载部署者私钥
        uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY_SEPOLIA");
        
        // 开始广播交易（使用部署者账户）
        vm.startBroadcast(deployerPrivateKey);
        
        // 部署 MyToken 合约，传入名称和符号
        MyToken myToken = new MyToken("MyToken", "MTK", 10000000000000000000000000000);
        
        // 停止广播
        vm.stopBroadcast();
        
        // 将部署地址打印到控制台（可用于后续脚本或验证）
        console.log("MyToken deployed to:", address(myToken));
    }
}
