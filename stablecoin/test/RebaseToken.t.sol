// SPDX-License-Identifier: MIT
pragma solidity ^0.8.25;

import "forge-std/Test.sol";
import "../src/RebaseToken.sol";

contract RebaseTokenTest is Test {
    RebaseToken public token;
    address public owner;
    address public alice;
    address public bob;
    
    uint256 public constant INITIAL_SUPPLY = 100_000_000 * 1e18; // 1 billion tokens
    uint256 public constant REBASE_INTERVAL = 365 days;
    
    event Rebase(uint256 newTotalSupply, uint256 supplyDelta);
    event SharesTransfer(address indexed from, address indexed to, uint256 shares);
    
    function setUp() public {
        owner = address(this);
        alice = makeAddr("alice");
        bob = makeAddr("bob");
        
        token = new RebaseToken(
            "Rebase Deflation Token",
            "RDT",
            INITIAL_SUPPLY,
            owner
        );
    }
    
    // ============ Basic Functionality Tests ============
    
    function testInitialState() public {
        assertEq(token.name(), "Rebase Deflation Token");
        assertEq(token.symbol(), "RDT");
        assertEq(token.decimals(), 18);
        assertEq(token.totalSupply(), INITIAL_SUPPLY);
        assertEq(token.balanceOf(owner), INITIAL_SUPPLY);
        assertEq(token.sharesOf(owner), INITIAL_SUPPLY);
        assertEq(token.totalShares(), INITIAL_SUPPLY);
    }
    
    function testOwnership() public {
        assertEq(token.owner(), owner);
    }
    
    // ============ Share Conversion Tests ============
    
    function testShareConversion() public {
        uint256 amount = 1000 * 1e18;
        uint256 shares = token.getSharesByAmount(amount);
        uint256 convertedAmount = token.getAmountByShares(shares);
        
        assertEq(shares, amount); // Initially 1:1 ratio
        assertEq(convertedAmount, amount);
    }
    
    function testShareConversionAfterRebase() public {
        // Fast forward 1 year
        vm.warp(block.timestamp + REBASE_INTERVAL);
        
        // Perform rebase
        token.rebase();
        
        uint256 newTotalSupply = token.totalSupply();
        uint256 expectedSupply = (INITIAL_SUPPLY * 99) / 100; // 1% deflation
        assertEq(newTotalSupply, expectedSupply);
        
        // Test share conversion after rebase
        uint256 shares = 1000 * 1e18;
        uint256 amount = token.getAmountByShares(shares);
        uint256 expectedAmount = (shares * newTotalSupply) / token.totalShares();
        assertEq(amount, expectedAmount);
    }
    
    // ============ Transfer Tests ============
    
    function testTransfer() public {
        uint256 transferAmount = 1000 * 1e18;
        
        token.transfer(alice, transferAmount);
        
        assertEq(token.balanceOf(alice), transferAmount);
        assertEq(token.balanceOf(owner), INITIAL_SUPPLY - transferAmount);
        
        // Check shares
        uint256 expectedShares = token.getSharesByAmount(transferAmount);
        assertEq(token.sharesOf(alice), expectedShares);
    }
    
    function testTransferAfterRebase() public {
        uint256 transferAmount = 1000 * 1e18;
        
        // Transfer before rebase
        token.transfer(alice, transferAmount);
        
        // Fast forward and rebase
        vm.warp(block.timestamp + REBASE_INTERVAL);
        token.rebase();
        
        uint256 aliceBalanceBefore = token.balanceOf(alice);
        uint256 ownerBalanceBefore = token.balanceOf(owner);
        
        // Transfer after rebase
        vm.prank(alice);
        token.transfer(bob, aliceBalanceBefore / 2);
        
        // Check balances maintain proportions
        assertEq(token.balanceOf(bob), aliceBalanceBefore / 2);
        assertEq(token.balanceOf(alice), aliceBalanceBefore / 2);
        assertEq(token.balanceOf(owner), ownerBalanceBefore);
    }
    
    function testTransferFrom() public {
        uint256 transferAmount = 1000 * 1e18;
        
        // Approve alice to spend owner's tokens
        token.approve(alice, transferAmount);
        
        // Alice transfers from owner to bob
        vm.prank(alice);
        token.transferFrom(owner, bob, transferAmount);
        
        assertEq(token.balanceOf(bob), transferAmount);
        assertEq(token.balanceOf(owner), INITIAL_SUPPLY - transferAmount);
        assertEq(token.allowance(owner, alice), 0);
    }
    
    // ============ Rebase Tests ============
    
    function testCannotRebaseBeforeInterval() public {
        assertFalse(token.canRebase());
        
        vm.expectRevert("RebaseToken: Rebase not available yet");
        token.rebase();
    }
    
    function testRebaseAfterInterval() public {
        // Fast forward 1 year
        vm.warp(block.timestamp + REBASE_INTERVAL);
        
        assertTrue(token.canRebase());
        
        uint256 oldSupply = token.totalSupply();
        uint256 expectedNewSupply = (oldSupply * 99) / 100;
        
        vm.expectEmit(true, true, true, true);
        emit Rebase(expectedNewSupply, oldSupply - expectedNewSupply);
        
        uint256 newSupply = token.rebase();
        
        assertEq(newSupply, expectedNewSupply);
        assertEq(token.totalSupply(), expectedNewSupply);
        assertEq(token.lastRebaseTime(), block.timestamp);
        assertFalse(token.canRebase()); // Cannot rebase again immediately
    }
    
    function testMultipleRebases() public {
        uint256 currentSupply = INITIAL_SUPPLY;
        
        for (uint256 i = 0; i < 5; i++) {
            // Fast forward 1 year
            vm.warp(block.timestamp + REBASE_INTERVAL);
            
            uint256 expectedSupply = (currentSupply * 99) / 100;
            uint256 newSupply = token.rebase();
            
            assertEq(newSupply, expectedSupply);
            currentSupply = newSupply; // Update currentSupply to the actual new supply
        }
        
        // After 5 years of 1% deflation
        uint256 finalSupply = token.totalSupply();
        
        // Calculate expected supply manually for verification
        uint256 expectedFinalSupply = INITIAL_SUPPLY;
        for (uint256 i = 0; i < 5; i++) {
            expectedFinalSupply = (expectedFinalSupply * 99) / 100;
        }
        
        assertEq(finalSupply, expectedFinalSupply);
    }
    
    function testUserBalanceAfterRebase() public {
        uint256 transferAmount = 1000 * 1e18;
        
        // Transfer to alice
        token.transfer(alice, transferAmount);
        
        uint256 aliceSharesBefore = token.sharesOf(alice);
        uint256 ownerSharesBefore = token.sharesOf(owner);
        
        // Fast forward and rebase
        vm.warp(block.timestamp + REBASE_INTERVAL);
        token.rebase();
        
        // Shares should remain the same
        assertEq(token.sharesOf(alice), aliceSharesBefore);
        assertEq(token.sharesOf(owner), ownerSharesBefore);
        
        // But balances should reflect deflation
        uint256 aliceBalanceAfter = token.balanceOf(alice);
        uint256 ownerBalanceAfter = token.balanceOf(owner);
        
        // Alice should have 99% of her original balance
        assertEq(aliceBalanceAfter, (transferAmount * 99) / 100);
        
        // Owner should have 99% of his original balance
        assertEq(ownerBalanceAfter, ((INITIAL_SUPPLY - transferAmount) * 99) / 100);
        
        // Total should equal new total supply
        assertEq(aliceBalanceAfter + ownerBalanceAfter, token.totalSupply());
    }
    
    // ============ Mint and Burn Tests ============
    
    function testMint() public {
        uint256 mintAmount = 1000 * 1e18;
        uint256 totalSupplyBefore = token.totalSupply();
        uint256 totalSharesBefore = token.totalShares();
        
        token.mint(alice, mintAmount);
        
        assertEq(token.balanceOf(alice), mintAmount);
        assertEq(token.totalSupply(), totalSupplyBefore + mintAmount);
        
        // Shares should increase proportionally
        uint256 expectedShares = (mintAmount * totalSharesBefore) / totalSupplyBefore;
        assertEq(token.sharesOf(alice), expectedShares);
    }
    
    function testBurn() public {
        uint256 burnAmount = 1000 * 1e18;
        
        // First transfer some tokens to alice
        token.transfer(alice, burnAmount * 2);
        
        uint256 aliceBalanceBefore = token.balanceOf(alice);
        uint256 totalSupplyBefore = token.totalSupply();
        
        token.burn(alice, burnAmount);
        
        assertEq(token.balanceOf(alice), aliceBalanceBefore - burnAmount);
        assertEq(token.totalSupply(), totalSupplyBefore - burnAmount);
    }
    
    function testBurnSelf() public {
        uint256 burnAmount = 1000 * 1e18;
        
        // Transfer to alice first
        token.transfer(alice, burnAmount * 2);
        
        uint256 aliceBalanceBefore = token.balanceOf(alice);
        uint256 totalSupplyBefore = token.totalSupply();
        
        vm.prank(alice);
        token.burnSelf(burnAmount);
        
        assertEq(token.balanceOf(alice), aliceBalanceBefore - burnAmount);
        assertEq(token.totalSupply(), totalSupplyBefore - burnAmount);
    }
    
    // ============ Access Control Tests ============
    
    function testOnlyOwnerCanMint() public {
        vm.prank(alice);
        vm.expectRevert();
        token.mint(bob, 1000 * 1e18);
    }
    
    function testOnlyOwnerCanBurn() public {
        vm.prank(alice);
        vm.expectRevert();
        token.burn(bob, 1000 * 1e18);
    }
    
    // ============ Utility Function Tests ============
    
    function testGetProjectedSupplyAfterRebases() public {
        uint256 projected1 = token.getProjectedSupplyAfterRebases(1);
        uint256 projected5 = token.getProjectedSupplyAfterRebases(5);
        uint256 projected10 = token.getProjectedSupplyAfterRebases(10);
        
        assertEq(projected1, (INITIAL_SUPPLY * 99) / 100);
        
        // Verify compound deflation
        uint256 expected5 = INITIAL_SUPPLY;
        for (uint256 i = 0; i < 5; i++) {
            expected5 = (expected5 * 99) / 100;
        }
        assertEq(projected5, expected5);
        
        uint256 expected10 = INITIAL_SUPPLY;
        for (uint256 i = 0; i < 10; i++) {
            expected10 = (expected10 * 99) / 100;
        }
        assertEq(projected10, expected10);
    }
    
    function testGetTimeUntilNextRebase() public {
        uint256 timeUntilNext = token.getTimeUntilNextRebase();
        assertEq(timeUntilNext, REBASE_INTERVAL);
        
        // Fast forward half a year
        vm.warp(block.timestamp + REBASE_INTERVAL / 2);
        timeUntilNext = token.getTimeUntilNextRebase();
        assertEq(timeUntilNext, REBASE_INTERVAL / 2);
        
        // Fast forward past rebase time
        vm.warp(block.timestamp + REBASE_INTERVAL);
        timeUntilNext = token.getTimeUntilNextRebase();
        assertEq(timeUntilNext, 0);
    }
    
    // ============ Edge Cases and Error Tests ============
    
    function testTransferZeroAmount() public {
        token.transfer(alice, 0);
        assertEq(token.balanceOf(alice), 0);
    }
    
    function testTransferInsufficientBalance() public {
        vm.prank(alice);
        vm.expectRevert();
        token.transfer(bob, 1);
    }
    
    function testBurnInsufficientBalance() public {
        vm.expectRevert();
        token.burn(alice, 1);
    }
    
    function testMintToZeroAddress() public {
        vm.expectRevert();
        token.mint(address(0), 1000 * 1e18);
    }
    
    function testBurnFromZeroAddress() public {
        vm.expectRevert();
        token.burn(address(0), 1000 * 1e18);
    }
    
    // ============ Fuzz Tests ============
    
    function testFuzzTransfer(uint256 amount) public {
        amount = bound(amount, 0, INITIAL_SUPPLY);
        
        token.transfer(alice, amount);
        
        assertEq(token.balanceOf(alice), amount);
        assertEq(token.balanceOf(owner), INITIAL_SUPPLY - amount);
        assertEq(token.totalSupply(), INITIAL_SUPPLY);
    }
    
    function testFuzzRebasePreservesRatios(uint256 aliceAmount, uint256 bobAmount) public {
        aliceAmount = bound(aliceAmount, 1000, INITIAL_SUPPLY / 3); // Increase minimum to avoid precision issues
        bobAmount = bound(bobAmount, 1000, INITIAL_SUPPLY / 3);
        
        // Ensure we don't exceed total supply
        vm.assume(aliceAmount + bobAmount <= INITIAL_SUPPLY);
        
        // Transfer tokens
        token.transfer(alice, aliceAmount);
        token.transfer(bob, bobAmount);
        
        uint256 ownerBalanceBefore = token.balanceOf(owner);
        
        // Calculate shares before rebase (shares don't change)
        uint256 aliceShares = token.sharesOf(alice);
        uint256 bobShares = token.sharesOf(bob);
        uint256 ownerShares = token.sharesOf(owner);
        uint256 totalShares = token.totalShares();
        
        // Perform rebase
        vm.warp(block.timestamp + REBASE_INTERVAL);
        token.rebase();
        
        uint256 newTotalSupply = token.totalSupply();
        
        // Check that shares remain the same
        assertEq(token.sharesOf(alice), aliceShares);
        assertEq(token.sharesOf(bob), bobShares);
        assertEq(token.sharesOf(owner), ownerShares);
        assertEq(token.totalShares(), totalShares);
        
        // Check that balances are proportional to shares
        uint256 aliceBalanceAfter = token.balanceOf(alice);
        uint256 bobBalanceAfter = token.balanceOf(bob);
        uint256 ownerBalanceAfter = token.balanceOf(owner);
        
        // Calculate expected balances
        uint256 expectedAliceBalance = (aliceShares * newTotalSupply) / totalShares;
        uint256 expectedBobBalance = (bobShares * newTotalSupply) / totalShares;
        uint256 expectedOwnerBalance = (ownerShares * newTotalSupply) / totalShares;
        
        // Use approximate equality to handle rounding errors
        assertApproxEqAbs(aliceBalanceAfter, expectedAliceBalance, 1);
        assertApproxEqAbs(bobBalanceAfter, expectedBobBalance, 1);
        assertApproxEqAbs(ownerBalanceAfter, expectedOwnerBalance, 1);
        
        // Verify total balance is close to total supply (within rounding error)
        uint256 totalBalance = aliceBalanceAfter + bobBalanceAfter + ownerBalanceAfter;
        assertApproxEqAbs(totalBalance, newTotalSupply, 3); // Allow for up to 3 wei difference due to rounding
    }
}