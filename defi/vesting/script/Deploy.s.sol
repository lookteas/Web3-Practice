// SPDX-License-Identifier: MIT
pragma solidity ^0.8.27;

import {Script, console} from "forge-std/Script.sol";
import {TokenVesting} from "../src/TokenVesting.sol";
import {MockERC20} from "../src/MockERC20.sol";

contract DeployScript is Script {
    function run() external {
        uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");
        address deployer = vm.addr(deployerPrivateKey);
        address beneficiary = vm.envAddress("BENEFICIARY_ADDRESS");
        
        console.log("Deployer:", deployer);
        console.log("Beneficiary:", beneficiary);
        
        vm.startBroadcast(deployerPrivateKey);
        
        // 部署测试代币（总供应量 1000万）
        MockERC20 token = new MockERC20(
            "Keep Token",
            "KEEP",
            10_000_000 * 1e18
        );
        console.log("Token deployed at:", address(token));
        
        // 部署 Vesting 合约（归属 100万代币）
        uint256 vestingAmount = 1_000_000 * 1e18;
        TokenVesting vesting = new TokenVesting(
            token,
            beneficiary,
            vestingAmount
        );
        console.log("Vesting contract deployed at:", address(vesting));
        
        // 向 Vesting 合约转入代币
        token.transfer(address(vesting), vestingAmount);
        console.log("Transferred", vestingAmount / 1e18, "tokens to vesting contract");
        
        // 输出合约信息
        console.log("=== Deployment Summary ===");
        console.log("Token Address:", address(token));
        console.log("Vesting Address:", address(vesting));
        console.log("Beneficiary:", beneficiary);
        console.log("Vesting Amount:", vestingAmount / 1e18, "tokens");
        console.log("Cliff Duration:", vesting.CLIFF_DURATION() / 86400, "days");
        console.log("Vesting Duration:", vesting.VESTING_DURATION() / 86400, "days");
        console.log("Total Duration:", vesting.TOTAL_DURATION() / 86400, "days");
        
        vm.stopBroadcast();
    }
}