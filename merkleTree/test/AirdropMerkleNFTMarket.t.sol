// SPDX-License-Identifier: MIT
pragma solidity ^0.8.25;

import "forge-std/Test.sol";
import "forge-std/console.sol";
import "../src/AirdropToken.sol";
import "../src/AirdropNFT.sol";
import "../src/AirdropMerkleNFTMarket.sol";

contract AirdropMerkleNFTMarketTest is Test {
    AirdropToken public token;
    AirdropNFT public nft;
    AirdropMerkleNFTMarket public market;
    
    address public owner = address(0x1);
    address public user1;
    address public user2;
    address public user3;
    address public nonWhitelisted;
    
    uint256 public user1PrivateKey;
    uint256 public user2PrivateKey;
    uint256 public user3PrivateKey;
    uint256 public nonWhitelistedPrivateKey;
    
    // Merkle tree data
    bytes32 public merkleRoot;
    bytes32[] public user1Proof;
    bytes32[] public user2Proof;
    bytes32[] public user3Proof;
    
    uint256 public constant INITIAL_SUPPLY = 1000000 * 10**18;
    uint256 public constant NFT_PRICE = 1000 * 10**18;
    uint256 public constant DISCOUNTED_PRICE = 500 * 10**18; // 50% discount
    
    function setUp() public {
        vm.startPrank(owner);
        
        // Deploy contracts
        token = new AirdropToken("AirdropToken", "ADT", 18, INITIAL_SUPPLY, owner);
        nft = new AirdropNFT("AirdropNFT", "ANFT", "https://api.example.com/metadata/", owner);
        
        // Create test users using makeAddrAndKey
        (user1, user1PrivateKey) = makeAddrAndKey("user1");
        (user2, user2PrivateKey) = makeAddrAndKey("user2");
        (user3, user3PrivateKey) = makeAddrAndKey("user3");
        (nonWhitelisted, nonWhitelistedPrivateKey) = makeAddrAndKey("nonWhitelisted");
        
        // Generate Merkle tree for whitelist
        generateMerkleTree();
        
        market = new AirdropMerkleNFTMarket(
            address(token),
            address(nft),
            merkleRoot,
            owner
        );
        
        // Mint some NFTs and list them
        uint256 tokenId1 = nft.mint(owner, "token1.json");
        uint256 tokenId2 = nft.mint(owner, "token2.json");
        uint256 tokenId3 = nft.mint(owner, "token3.json");
        
        nft.listToken(tokenId1, NFT_PRICE);
        nft.listToken(tokenId2, NFT_PRICE);
        nft.listToken(tokenId3, NFT_PRICE);
        
        // Approve market to transfer NFTs
        nft.setApprovalForAll(address(market), true);
        
        vm.stopPrank();
        
        // Distribute tokens to users
        vm.startPrank(owner);
        token.transfer(user1, 10000 * 10**18);
        token.transfer(user2, 10000 * 10**18);
        token.transfer(user3, 10000 * 10**18);
        token.transfer(nonWhitelisted, 10000 * 10**18);
        vm.stopPrank();
    }
    
    function generateMerkleTree() internal {
        // Create leaves for Merkle tree
        bytes32 leaf1 = keccak256(abi.encodePacked(user1));
        bytes32 leaf2 = keccak256(abi.encodePacked(user2));
        bytes32 leaf3 = keccak256(abi.encodePacked(user3));
        
        // Build tree manually for testing
        // Level 1: Hash pairs
        bytes32 hash1_2 = keccak256(abi.encodePacked(leaf1 < leaf2 ? leaf1 : leaf2, leaf1 < leaf2 ? leaf2 : leaf1));
        bytes32 hash3 = leaf3;
        
        // Level 2: Root
        merkleRoot = keccak256(abi.encodePacked(hash1_2 < hash3 ? hash1_2 : hash3, hash1_2 < hash3 ? hash3 : hash1_2));
        
        // Generate proofs
        user1Proof = new bytes32[](2);
        user1Proof[0] = leaf2;
        user1Proof[1] = leaf3;
        
        user2Proof = new bytes32[](2);
        user2Proof[0] = leaf1;
        user2Proof[1] = leaf3;
        
        user3Proof = new bytes32[](1);
        user3Proof[0] = hash1_2;
    }
    
    function testVerifyWhitelist() public {
        assertTrue(market.verifyWhitelist(user1, user1Proof));
        assertTrue(market.verifyWhitelist(user2, user2Proof));
        assertTrue(market.verifyWhitelist(user3, user3Proof));
        
        // Test non-whitelisted user
        bytes32[] memory emptyProof = new bytes32[](0);
        assertFalse(market.verifyWhitelist(nonWhitelisted, emptyProof));
    }
    
    function testPermitPrePay() public {
        vm.startPrank(user1);
        
        uint256 value = DISCOUNTED_PRICE;
        uint256 deadline = block.timestamp + 1 hours;
        
        // Create permit signature
        (uint8 v, bytes32 r, bytes32 s) = createPermitSignature(
            user1,
            address(market),
            value,
            deadline
        );
        
        // Execute permit
        market.permitPrePay(value, deadline, v, r, s);
        
        // Check allowance
        assertEq(token.allowance(user1, address(market)), value);
        
        vm.stopPrank();
    }
    
    function testClaimNFT() public {
        vm.startPrank(user1);
        
        uint256 tokenId = 0;
        uint256 value = DISCOUNTED_PRICE;
        uint256 deadline = block.timestamp + 1 hours;
        
        // Create permit signature
        (uint8 v, bytes32 r, bytes32 s) = createPermitSignature(
            user1,
            address(market),
            value,
            deadline
        );
        
        // Execute permit first
        market.permitPrePay(value, deadline, v, r, s);
        
        // Check initial balances
        uint256 initialTokenBalance = token.balanceOf(user1);
        uint256 initialOwnerBalance = token.balanceOf(owner);
        
        // Claim NFT
        market.claimNFT(tokenId, user1Proof);
        
        // Verify NFT ownership transfer
        assertEq(nft.ownerOf(tokenId), user1);
        
        // Verify token transfer
        assertEq(token.balanceOf(user1), initialTokenBalance - DISCOUNTED_PRICE);
        assertEq(token.balanceOf(owner), initialOwnerBalance + DISCOUNTED_PRICE);
        
        // Verify claim status
        assertTrue(market.hasUserClaimed(user1));
        
        vm.stopPrank();
    }
    
    function testMulticall() public {
        vm.startPrank(user2);
        
        uint256 tokenId = 1;
        uint256 value = DISCOUNTED_PRICE;
        uint256 deadline = block.timestamp + 1 hours;
        
        // Create permit signature
        (uint8 v, bytes32 r, bytes32 s) = createPermitSignature(
            user2,
            address(market),
            value,
            deadline
        );
        
        // Prepare multicall data
        bytes[] memory calls = new bytes[](2);
        calls[0] = market.encodePermitPrePay(value, deadline, v, r, s);
        calls[1] = market.encodeClaimNFT(tokenId, user2Proof);
        
        // Check initial balances
        uint256 initialTokenBalance = token.balanceOf(user2);
        uint256 initialOwnerBalance = token.balanceOf(owner);
        
        // Execute multicall
        market.multicall(calls);
        
        // Verify results
        assertEq(nft.ownerOf(tokenId), user2);
        assertEq(token.balanceOf(user2), initialTokenBalance - DISCOUNTED_PRICE);
        assertEq(token.balanceOf(owner), initialOwnerBalance + DISCOUNTED_PRICE);
        assertTrue(market.hasUserClaimed(user2));
        
        vm.stopPrank();
    }
    
    function test_RevertWhen_ClaimWithInvalidProof() public {
        vm.startPrank(nonWhitelisted);
        
        uint256 value = DISCOUNTED_PRICE;
        uint256 deadline = block.timestamp + 1 hours;
        
        // Create permit signature
        (uint8 v, bytes32 r, bytes32 s) = createPermitSignature(
            nonWhitelisted,
            address(market),
            value,
            deadline
        );
        
        market.permitPrePay(value, deadline, v, r, s);
        
        // This should fail with invalid proof
        bytes32[] memory emptyProof = new bytes32[](0);
        
        vm.expectRevert(AirdropMerkleNFTMarket.InvalidProof.selector);
        market.claimNFT(0, emptyProof);
        
        vm.stopPrank();
    }
    
    function test_RevertWhen_DoubleClaimSameUser() public {
        vm.startPrank(user3);
        
        uint256 value = DISCOUNTED_PRICE * 2; // Enough for two claims
        uint256 deadline = block.timestamp + 1 hours;
        
        // Create permit signature
        (uint8 v, bytes32 r, bytes32 s) = createPermitSignature(
            user3,
            address(market),
            value,
            deadline
        );
        
        market.permitPrePay(value, deadline, v, r, s);
        
        // First claim should succeed
        market.claimNFT(2, user3Proof);
        
        // Second claim should fail
        vm.expectRevert(AirdropMerkleNFTMarket.AlreadyClaimed.selector);
        market.claimNFT(1, user3Proof);
        
        vm.stopPrank();
    }
    
    function testGetDiscountedPrice() public {
        uint256 discountedPrice = market.getDiscountedPrice(0);
        assertEq(discountedPrice, DISCOUNTED_PRICE);
    }
    
    function testUpdateMerkleRoot() public {
        vm.startPrank(owner);
        
        bytes32 newRoot = keccak256("new root");
        market.updateMerkleRoot(newRoot);
        
        // Verify old proofs no longer work
        assertFalse(market.verifyWhitelist(user1, user1Proof));
        
        vm.stopPrank();
    }
    
    function testEmergencyWithdraw() public {
        // Transfer some tokens to the market contract
        vm.startPrank(owner);
        token.transfer(address(market), 1000 * 10**18);
        
        uint256 initialBalance = token.balanceOf(owner);
        uint256 withdrawAmount = 500 * 10**18;
        
        market.emergencyWithdraw(withdrawAmount);
        
        assertEq(token.balanceOf(owner), initialBalance + withdrawAmount);
        
        vm.stopPrank();
    }
    
    function test_RevertWhen_NonOwnerEmergencyWithdraw() public {
        vm.startPrank(user1);
        
        vm.expectRevert();
        market.emergencyWithdraw(100 * 10**18);
        
        vm.stopPrank();
    }
    
    // Helper function to create permit signatures
    function createPermitSignature(
        address owner_,
        address spender,
        uint256 value,
        uint256 deadline
    ) internal view returns (uint8 v, bytes32 r, bytes32 s) {
        // Get the private key for the address
        uint256 privateKey;
        if (owner_ == user1) {
            privateKey = user1PrivateKey;
        } else if (owner_ == user2) {
            privateKey = user2PrivateKey;
        } else if (owner_ == user3) {
            privateKey = user3PrivateKey;
        } else if (owner_ == nonWhitelisted) {
            privateKey = nonWhitelistedPrivateKey;
        }
        
        bytes32 structHash = keccak256(
            abi.encode(
                keccak256("Permit(address owner,address spender,uint256 value,uint256 nonce,uint256 deadline)"),
                owner_,
                spender,
                value,
                token.nonces(owner_),
                deadline
            )
        );
        
        bytes32 hash = keccak256(
            abi.encodePacked(
                "\x19\x01",
                token.DOMAIN_SEPARATOR(),
                structHash
            )
        );
        
        (v, r, s) = vm.sign(privateKey, hash);
    }
}