// SPDX-License-Identifier: MIT
pragma solidity ^0.8.27;

import {Test, console} from "forge-std/Test.sol";
import {TokenVesting} from "../src/TokenVesting.sol";
import {MockERC20} from "../src/MockERC20.sol";

contract TokenVestingTest is Test {
    TokenVesting public vesting;
    MockERC20 public token;
    
    address public owner = address(0x1);
    address public beneficiary = address(0x2);
    address public other = address(0x3);
    
    uint256 public constant TOTAL_AMOUNT = 1_000_000 * 1e18; // 100万代币
    uint256 public constant CLIFF_DURATION = 365 days; // 12个月
    uint256 public constant VESTING_DURATION = 730 days; // 24个月
    uint256 public constant TOTAL_DURATION = CLIFF_DURATION + VESTING_DURATION; // 36个月

    event TokensReleased(address indexed beneficiary, uint256 amount);
    event VestingRevoked(address indexed beneficiary, uint256 unreleased, uint256 refund);

    function setUp() public {
        // Deploy token contract
        token = new MockERC20("Test Token", "TEST", TOTAL_AMOUNT * 10);
        
        // Set owner and mint tokens to owner
        vm.startPrank(owner);
        token.mint(owner, TOTAL_AMOUNT * 10);
        
        // Deploy vesting contract
        vesting = new TokenVesting(token, beneficiary, TOTAL_AMOUNT);
        
        // Transfer tokens to vesting contract
        token.transfer(address(vesting), TOTAL_AMOUNT);
        
        vm.stopPrank();
    }

    function testInitialState() public view {
        assertEq(address(vesting.token()), address(token));
        assertEq(vesting.beneficiary(), beneficiary);
        assertEq(vesting.totalAmount(), TOTAL_AMOUNT);
        assertEq(vesting.released(), 0);
        assertFalse(vesting.revoked());
        assertTrue(vesting.isCliffPeriod());
        assertFalse(vesting.isVestingComplete());
        assertEq(vesting.getVestingProgress(), 0);
    }

    function testCannotReleaseBeforeCliff() public {
        // 在 cliff 期间尝试释放代币应该失败
        vm.expectRevert("TokenVesting: no tokens are due");
        vesting.release();
        
        // 时间前进到 cliff 期间的任意时间点
        vm.warp(block.timestamp + 180 days); // 6个月后
        assertTrue(vesting.isCliffPeriod());
        
        vm.expectRevert("TokenVesting: no tokens are due");
        vesting.release();
    }

    function testReleaseAfterCliff() public {
        // 时间前进到 cliff 结束后 1 个月
        vm.warp(block.timestamp + CLIFF_DURATION + 30 days);
        
        assertFalse(vesting.isCliffPeriod());
        
        uint256 expectedAmount = TOTAL_AMOUNT * 30 days / VESTING_DURATION;
        uint256 releasableAmount = vesting.releasableAmount();
        
        assertEq(releasableAmount, expectedAmount);
        
        // 释放代币
        vm.expectEmit(true, false, false, true);
        emit TokensReleased(beneficiary, expectedAmount);
        
        vesting.release();
        
        assertEq(vesting.released(), expectedAmount);
        assertEq(token.balanceOf(beneficiary), expectedAmount);
    }

    function testLinearVesting() public {
        // 测试线性释放的不同时间点
        uint256[] memory timePoints = new uint256[](5);
        timePoints[0] = CLIFF_DURATION + 30 days;  // 1个月
        timePoints[1] = CLIFF_DURATION + 180 days; // 6个月
        timePoints[2] = CLIFF_DURATION + 365 days; // 12个月
        timePoints[3] = CLIFF_DURATION + 547 days; // 18个月
        timePoints[4] = CLIFF_DURATION + 730 days; // 24个月（完全释放）
        
        uint256 lastReleased = 0;
        
        for (uint256 i = 0; i < timePoints.length; i++) {
            vm.warp(block.timestamp + timePoints[i] - (i == 0 ? 0 : timePoints[i-1]));
            
            uint256 expectedVested = i == 4 ? TOTAL_AMOUNT : 
                TOTAL_AMOUNT * (timePoints[i] - CLIFF_DURATION) / VESTING_DURATION;
            uint256 expectedReleasable = expectedVested - lastReleased;
            
            assertEq(vesting.vestedAmount(), expectedVested);
            assertEq(vesting.releasableAmount(), expectedReleasable);
            
            if (expectedReleasable > 0) {
                vesting.release();
                lastReleased = expectedVested;
                assertEq(vesting.released(), lastReleased);
            }
        }
        
        // 验证最终状态
        assertTrue(vesting.isVestingComplete());
        assertEq(vesting.getVestingProgress(), 10000); // 100%
        assertEq(vesting.remainingAmount(), 0);
    }

    function testVestingProgress() public {
        // Test vesting progress calculation
        uint256 contractStartTime = vesting.start();
        
        // Progress is 0 during cliff period
        vm.warp(contractStartTime + 180 days);
        assertEq(vesting.getVestingProgress(), 0);
        
        // Progress starts growing after cliff ends
        // Move to cliff end + 365 days (50% of 730 days vesting period)
        vm.warp(contractStartTime + CLIFF_DURATION + 365 days);
        uint256 progress50 = vesting.getVestingProgress();
        assertEq(progress50, 5000); // Should be exactly 50%
        
        // Move to cliff end + 547 days (75% of 730 days vesting period)
        vm.warp(contractStartTime + CLIFF_DURATION + 547 days);
        uint256 progress75 = vesting.getVestingProgress();
        // 547/730 * 10000 = 7493.15... ≈ 7493
        assertTrue(progress75 >= 7490 && progress75 <= 7500);
        
        // 100% progress
        vm.warp(contractStartTime + TOTAL_DURATION);
        assertEq(vesting.getVestingProgress(), 10000); // 100%
    }

    function testRevoke() public {
        // 时间前进到线性释放期的中间
        vm.warp(block.timestamp + CLIFF_DURATION + 365 days); // 12个月线性释放
        
        uint256 vestedAmount = vesting.vestedAmount();
        uint256 expectedVested = TOTAL_AMOUNT / 2; // 50% 应该已归属
        assertEq(vestedAmount, expectedVested);
        
        // 只有所有者可以撤销
        vm.expectRevert();
        vm.prank(other);
        vesting.revoke();
        
        // 所有者撤销归属
        vm.startPrank(owner);
        
        uint256 ownerBalanceBefore = token.balanceOf(owner);
        uint256 beneficiaryBalanceBefore = token.balanceOf(beneficiary);
        
        vm.expectEmit(true, false, false, true);
        emit VestingRevoked(beneficiary, expectedVested, TOTAL_AMOUNT - expectedVested);
        
        vesting.revoke();
        
        // 验证撤销后的状态
        assertTrue(vesting.revoked());
        assertEq(vesting.released(), expectedVested);
        assertEq(token.balanceOf(beneficiary), beneficiaryBalanceBefore + expectedVested);
        assertEq(token.balanceOf(owner), ownerBalanceBefore + (TOTAL_AMOUNT - expectedVested));
        
        vm.stopPrank();
    }

    function testCannotReleaseAfterRevoke() public {
        // 撤销归属
        vm.prank(owner);
        vesting.revoke();
        
        // 尝试释放应该失败
        vm.expectRevert("TokenVesting: vesting revoked");
        vesting.release();
    }

    function testCannotRevokeAlreadyRevoked() public {
        // 撤销归属
        vm.prank(owner);
        vesting.revoke();
        
        // 再次撤销应该失败
        vm.expectRevert("TokenVesting: already revoked");
        vm.prank(owner);
        vesting.revoke();
    }

    function testMultipleReleases() public {
        // 测试多次释放
        vm.warp(block.timestamp + CLIFF_DURATION + 90 days); // 3个月
        
        uint256 firstRelease = vesting.releasableAmount();
        vesting.release();
        
        // 再过 3 个月
        vm.warp(block.timestamp + 90 days);
        
        uint256 secondRelease = vesting.releasableAmount();
        vesting.release();
        
        assertEq(vesting.released(), firstRelease + secondRelease);
        assertEq(token.balanceOf(beneficiary), firstRelease + secondRelease);
    }

    function testEdgeCases() public {
        // 测试边界情况
        
        // 恰好在 cliff 结束时
        vm.warp(block.timestamp + CLIFF_DURATION);
        assertEq(vesting.releasableAmount(), 0);
        assertFalse(vesting.isCliffPeriod());
        
        // cliff 结束后 1 秒
        vm.warp(block.timestamp + 1);
        uint256 expectedAmount = TOTAL_AMOUNT * 1 / VESTING_DURATION;
        assertEq(vesting.releasableAmount(), expectedAmount);
        
        // 恰好在归属结束时
        vm.warp(block.timestamp + TOTAL_DURATION - 1);
        assertTrue(vesting.isVestingComplete());
        assertEq(vesting.vestedAmount(), TOTAL_AMOUNT);
    }

    function testConstructorValidation() public {
        // 测试构造函数参数验证
        vm.startPrank(owner);
        
        // 零地址代币
        vm.expectRevert("TokenVesting: token is zero address");
        new TokenVesting(MockERC20(address(0)), beneficiary, TOTAL_AMOUNT);
        
        // 零地址受益人
        vm.expectRevert("TokenVesting: beneficiary is zero address");
        new TokenVesting(token, address(0), TOTAL_AMOUNT);
        
        // 零数量
        vm.expectRevert("TokenVesting: total amount is zero");
        new TokenVesting(token, beneficiary, 0);
        
        vm.stopPrank();
    }

    function testTimeSimulation() public {
        console.log("=== Time Simulation Test ===");
        console.log("Initial time:", block.timestamp);
        console.log("Total tokens:", TOTAL_AMOUNT / 1e18, "tokens");
        
        // Simulate entire vesting period
        uint256[] memory months = new uint256[](37); // 0-36 months
        for (uint256 i = 0; i <= 36; i++) {
            months[i] = i * 30 days; // 30 days per month
        }
        
        for (uint256 i = 0; i < months.length; i++) {
            vm.warp(block.timestamp + months[i] - (i == 0 ? 0 : months[i-1]));
            
            uint256 vestedAmount = vesting.vestedAmount();
            uint256 releasableAmount = vesting.releasableAmount();
            uint256 progress = vesting.getVestingProgress();
            
            console.log("Month:", i);
            console.log("  Vested:", vestedAmount / 1e18, "tokens");
            console.log("  Releasable:", releasableAmount / 1e18, "tokens");
            console.log("  Progress:", progress / 100, "%");
            console.log("  In cliff period:", vesting.isCliffPeriod());
            console.log("  Vesting complete:", vesting.isVestingComplete());
            console.log("---");
        }
    }
}