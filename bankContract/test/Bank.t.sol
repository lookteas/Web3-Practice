// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

import "forge-std/Test.sol";
import "../Bank.sol";

contract BankTest is Test {
    Bank bank;
    address alice;
    address bob;
    address carol;
    address dave;

    // 允许测试合约接收 ETH，便于验证 withdraw 行为
    receive() external payable {}

    function setUp() public {
        bank = new Bank();
        alice = address(0xA1);
        bob = address(0xB2);
        carol = address(0xC3);
        dave = address(0xD4);
    }

    // 断言检查存款前后用户在 Bank 合约中的存款额更新是否正确
    function test_DepositUpdates() public {
        vm.deal(alice, 10 ether);

        vm.prank(alice);
        bank.deposit{value: 1 ether}();
        assertEq(bank.getDeposit(alice), 1 ether);

        vm.prank(alice);
        bank.deposit{value: 2 ether}();
        assertEq(bank.getDeposit(alice), 3 ether);
    }

    // 检查有 1 个用户时的前 3 名
    function test_TopDepositors_OneUser() public {
        vm.deal(alice, 2 ether);
        vm.prank(alice);
        bank.deposit{value: 1 ether}();

        address[3] memory top = bank.getTopDepositors();
        assertEq(top[0], alice);
        assertEq(top[1], address(0));
        assertEq(top[2], address(0));

        (address[3] memory addrs, uint256[3] memory amounts) = bank.getTopDepositorsWithAmounts();
        assertEq(addrs[0], alice);
        assertEq(amounts[0], 1 ether);
        assertEq(amounts[1], 0);
        assertEq(amounts[2], 0);
    }

    // 检查有 2 个用户时的前 3 名（按金额降序）
    function test_TopDepositors_TwoUsersOrder() public {
        vm.deal(alice, 3 ether);
        vm.prank(alice);
        bank.deposit{value: 1 ether}();

        vm.deal(bob, 3 ether);
        vm.prank(bob);
        bank.deposit{value: 2 ether}();

        address[3] memory top = bank.getTopDepositors();
        assertEq(top[0], bob);
        assertEq(top[1], alice);
        assertEq(top[2], address(0));
    }

    // 检查有 3 个用户时的前 3 名（按金额降序）
    function test_TopDepositors_ThreeUsersOrder() public {
        vm.deal(bob, 2 ether);
        vm.prank(bob);
        bank.deposit{value: 2 ether}();

        vm.deal(alice, 2 ether);
        vm.prank(alice);
        bank.deposit{value: 1 ether}();

        vm.deal(carol, 2 ether);
        vm.prank(carol);
        bank.deposit{value: 1 ether}();

        address[3] memory top = bank.getTopDepositors();
        assertEq(top[0], bob);
        assertEq(top[1], alice);
        assertEq(top[2], carol);
    }

    // 检查有 4 个用户时依然只保留前 3 名
    function test_TopDepositors_FourUsersKeepsTopThree() public {
        vm.deal(alice, 3 ether);
        vm.prank(alice);
        bank.deposit{value: 1 ether}();

        vm.deal(bob, 3 ether);
        vm.prank(bob);
        bank.deposit{value: 2 ether}();

        vm.deal(carol, 1 ether);
        vm.prank(carol);
        bank.deposit{value: 0.5 ether}();

        vm.deal(dave, 5 ether);
        vm.prank(dave);
        bank.deposit{value: 3 ether}();

        address[3] memory top = bank.getTopDepositors();
        assertEq(top[0], dave);
        assertEq(top[1], bob);
        assertEq(top[2], alice);
    }

    // 检查同一个用户多次存款的累计效果与排行榜更新
    function test_TopDepositors_SameUserMultipleDeposits() public {
        vm.deal(alice, 10 ether);
        vm.prank(alice);
        bank.deposit{value: 1 ether}();

        vm.deal(bob, 10 ether);
        vm.prank(bob);
        bank.deposit{value: 2 ether}();

        // Alice 再次存款，超过 Bob
        vm.prank(alice);
        bank.deposit{value: 5 ether}();

        address[3] memory top = bank.getTopDepositors();
        assertEq(top[0], alice);
        assertEq(top[1], bob);
        assertEq(top[2], address(0));

        (address[3] memory addrs, uint256[3] memory amounts) = bank.getTopDepositorsWithAmounts();
        assertEq(addrs[0], alice);
        assertEq(addrs[1], bob);
        assertEq(addrs[2], address(0));
        assertEq(amounts[0], 6 ether);
        assertEq(amounts[1], 2 ether);
        assertEq(amounts[2], 0);
    }

    // 检查只有管理员可取款，其他人不可以取款
    function test_Withdraw_AdminOnly() public {
        // 先向合约存入资金
        vm.deal(alice, 2 ether);
        vm.prank(alice);
        bank.deposit{value: 2 ether}();

        // 非管理员提款应当 revert
        vm.prank(bob);
        vm.expectRevert(bytes("only admin can call"));
        bank.withdraw(1 ether);

        // 管理员（测试合约本身为 Bank 构造时的管理员）提款成功
        uint256 beforeBal = address(this).balance;
        bank.withdraw(1 ether);
        assertEq(address(this).balance, beforeBal + 1 ether);
    }

    // 额外：检查余额不足时的错误信息
    function test_Withdraw_RevertWhenInsufficientBalance() public {
        vm.expectRevert(bytes("no balance to withdraw"));
        bank.withdraw(1 ether);
    }
}