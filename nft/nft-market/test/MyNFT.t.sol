// SPDX-License-Identifier: MIT
pragma solidity ^0.8.25;

import "forge-std/Test.sol";
import "../src/MyNFT.sol";

contract MyNFTTest is Test {
    MyNFT public nft;
    address public owner;
    address public user1;
    address public user2;
    address public royaltyReceiver;
    
    string constant NAME = "MyNFT";
    string constant SYMBOL = "MNFT";
    string constant TOKEN_URI = "https://example.com/token/1";
    uint256 constant MINT_PRICE = 0.01 ether;
    
    event NFTMinted(address indexed to, uint256 indexed tokenId, string tokenURI);
    event MintPriceUpdated(uint256 oldPrice, uint256 newPrice);
    event MintingStatusChanged(bool enabled);
    event RoyaltyUpdated(address receiver, uint256 percentage);
    
    function setUp() public {
        owner = address(this);
        user1 = makeAddr("user1");
        user2 = makeAddr("user2");
        royaltyReceiver = makeAddr("royaltyReceiver");
        
        nft = new MyNFT(NAME, SYMBOL, royaltyReceiver);
        
        // 给用户一些ETH用于测试
        vm.deal(user1, 10 ether);
        vm.deal(user2, 10 ether);
    }
    
    // ========== 部署测试 ==========
    function testDeployment() public {
        assertEq(nft.name(), NAME);
        assertEq(nft.symbol(), SYMBOL);
        assertEq(nft.owner(), owner);
        assertEq(nft.royaltyReceiver(), royaltyReceiver);
        assertEq(nft.mintPrice(), MINT_PRICE);
        assertEq(nft.maxSupply(), 10000);
        assertEq(nft.maxMintPerAddress(), 10);
        assertTrue(nft.mintingEnabled());
        assertEq(nft.royaltyPercentage(), 250); // 2.5%
        assertEq(nft.getCurrentTokenId(), 1);
        assertEq(nft.totalSupply(), 0);
    }
    
    // ========== 铸造功能测试 ==========
    function testMintSuccess() public {
        vm.startPrank(user1);
        
        vm.expectEmit(true, true, false, true);
        emit NFTMinted(user1, 1, TOKEN_URI);
        
        nft.mint{value: MINT_PRICE}(user1, TOKEN_URI);
        
        assertEq(nft.ownerOf(1), user1);
        assertEq(nft.tokenURI(1), TOKEN_URI);
        assertEq(nft.balanceOf(user1), 1);
        assertEq(nft.mintedCount(user1), 1);
        assertEq(nft.totalSupply(), 1);
        assertEq(nft.getCurrentTokenId(), 2);
        
        vm.stopPrank();
    }
    
    function testMintWithExcessPayment() public {
        uint256 initialBalance = user1.balance;
        
        vm.startPrank(user1);
        nft.mint{value: MINT_PRICE + 1 ether}(user1, TOKEN_URI);
        vm.stopPrank();
        
        // 应该退还多余的ETH
        assertEq(user1.balance, initialBalance - MINT_PRICE);
        assertEq(nft.ownerOf(1), user1);
    }
    
    function testOwnerMintFree() public {
        uint256 initialBalance = address(this).balance;
        
        nft.mint(user1, TOKEN_URI);
        
        // Owner铸造不需要支付费用
        assertEq(address(this).balance, initialBalance);
        assertEq(nft.ownerOf(1), user1);
    }
    
    function testMintFailInsufficientPayment() public {
        vm.startPrank(user1);
        
        vm.expectRevert("Insufficient payment");
        nft.mint{value: MINT_PRICE - 1}(user1, TOKEN_URI);
        
        vm.stopPrank();
    }
    
    function testMintFailZeroAddress() public {
        vm.expectRevert("Cannot mint to zero address");
        nft.mint{value: MINT_PRICE}(address(0), TOKEN_URI);
    }
    
    function testMintFailEmptyTokenURI() public {
        vm.startPrank(user1);
        
        vm.expectRevert("Token URI cannot be empty");
        nft.mint{value: MINT_PRICE}(user1, "");
        
        vm.stopPrank();
    }
    
    function testMintFailMintingDisabled() public {
        nft.setMintingEnabled(false);
        
        vm.startPrank(user1);
        
        vm.expectRevert("Minting is currently disabled");
        nft.mint{value: MINT_PRICE}(user1, TOKEN_URI);
        
        vm.stopPrank();
    }
    
    function testMintFailMaxSupplyReached() public {
        nft.setMaxSupply(1);
        
        vm.startPrank(user1);
        nft.mint{value: MINT_PRICE}(user1, TOKEN_URI);
        
        vm.expectRevert("Max supply reached");
        nft.mint{value: MINT_PRICE}(user1, "https://example.com/token/2");
        
        vm.stopPrank();
    }
    
    function testMintFailMaxMintPerAddressReached() public {
        nft.setMaxMintPerAddress(1);
        
        vm.startPrank(user1);
        nft.mint{value: MINT_PRICE}(user1, TOKEN_URI);
        
        vm.expectRevert("Max mint per address reached");
        nft.mint{value: MINT_PRICE}(user1, "https://example.com/token/2");
        
        vm.stopPrank();
    }
    
    // ========== 批量铸造测试 ==========
    function testBatchMintSuccess() public {
        string[] memory tokenURIs = new string[](3);
        tokenURIs[0] = "https://example.com/token/1";
        tokenURIs[1] = "https://example.com/token/2";
        tokenURIs[2] = "https://example.com/token/3";
        
        nft.batchMint(user1, tokenURIs);
        
        assertEq(nft.balanceOf(user1), 3);
        assertEq(nft.mintedCount(user1), 3);
        assertEq(nft.totalSupply(), 3);
        assertEq(nft.ownerOf(1), user1);
        assertEq(nft.ownerOf(2), user1);
        assertEq(nft.ownerOf(3), user1);
        assertEq(nft.tokenURI(1), tokenURIs[0]);
        assertEq(nft.tokenURI(2), tokenURIs[1]);
        assertEq(nft.tokenURI(3), tokenURIs[2]);
    }
    
    function testBatchMintFailNotOwner() public {
        string[] memory tokenURIs = new string[](1);
        tokenURIs[0] = TOKEN_URI;
        
        vm.startPrank(user1);
        
        vm.expectRevert(abi.encodeWithSelector(Ownable.OwnableUnauthorizedAccount.selector, user1));
        nft.batchMint(user1, tokenURIs);
        
        vm.stopPrank();
    }
    
    function testBatchMintFailZeroAddress() public {
        string[] memory tokenURIs = new string[](1);
        tokenURIs[0] = TOKEN_URI;
        
        vm.expectRevert("Cannot mint to zero address");
        nft.batchMint(address(0), tokenURIs);
    }
    
    function testBatchMintFailEmptyArray() public {
        string[] memory tokenURIs = new string[](0);
        
        vm.expectRevert("Token URIs array cannot be empty");
        nft.batchMint(user1, tokenURIs);
    }
    
    function testBatchMintFailExceedMaxSupply() public {
        nft.setMaxSupply(2);
        
        string[] memory tokenURIs = new string[](3);
        tokenURIs[0] = "https://example.com/token/1";
        tokenURIs[1] = "https://example.com/token/2";
        tokenURIs[2] = "https://example.com/token/3";
        
        vm.expectRevert("Would exceed max supply");
        nft.batchMint(user1, tokenURIs);
    }
    
    // ========== 设置函数测试 ==========
    function testSetMintPrice() public {
        uint256 newPrice = 0.02 ether;
        
        vm.expectEmit(false, false, false, true);
        emit MintPriceUpdated(MINT_PRICE, newPrice);
        
        nft.setMintPrice(newPrice);
        assertEq(nft.mintPrice(), newPrice);
    }
    
    function testSetMintPriceFailNotOwner() public {
        vm.startPrank(user1);
        
        vm.expectRevert(abi.encodeWithSelector(Ownable.OwnableUnauthorizedAccount.selector, user1));
        nft.setMintPrice(0.02 ether);
        
        vm.stopPrank();
    }
    
    function testSetMintingEnabled() public {
        vm.expectEmit(false, false, false, true);
        emit MintingStatusChanged(false);
        
        nft.setMintingEnabled(false);
        assertFalse(nft.mintingEnabled());
        
        vm.expectEmit(false, false, false, true);
        emit MintingStatusChanged(true);
        
        nft.setMintingEnabled(true);
        assertTrue(nft.mintingEnabled());
    }
    
    function testSetMaxSupply() public {
        uint256 newMaxSupply = 5000;
        nft.setMaxSupply(newMaxSupply);
        assertEq(nft.maxSupply(), newMaxSupply);
    }
    
    function testSetMaxSupplyFailTooLow() public {
        // 先铸造一个NFT
        nft.mint(user1, TOKEN_URI);
        
        vm.expectRevert("Max supply cannot be less than current supply");
        nft.setMaxSupply(0);
    }
    
    function testSetMaxMintPerAddress() public {
        uint256 newMax = 5;
        nft.setMaxMintPerAddress(newMax);
        assertEq(nft.maxMintPerAddress(), newMax);
    }
    
    function testSetRoyalty() public {
        address newReceiver = makeAddr("newReceiver");
        uint256 newPercentage = 500; // 5%
        
        vm.expectEmit(false, false, false, true);
        emit RoyaltyUpdated(newReceiver, newPercentage);
        
        nft.setRoyalty(newReceiver, newPercentage);
        assertEq(nft.royaltyReceiver(), newReceiver);
        assertEq(nft.royaltyPercentage(), newPercentage);
    }
    
    function testSetRoyaltyFailZeroAddress() public {
        vm.expectRevert("Royalty receiver cannot be zero address");
        nft.setRoyalty(address(0), 250);
    }
    
    function testSetRoyaltyFailTooHigh() public {
        vm.expectRevert("Royalty percentage cannot exceed 10%");
        nft.setRoyalty(royaltyReceiver, 1001);
    }
    
    // ========== 查询函数测试 ==========
    function testTokensOfOwner() public {
        // 铸造多个NFT给user1
        nft.mint(user1, "https://example.com/token/1");
        nft.mint(user1, "https://example.com/token/2");
        nft.mint(user2, "https://example.com/token/3");
        nft.mint(user1, "https://example.com/token/4");
        
        uint256[] memory tokens = nft.tokensOfOwner(user1);
        assertEq(tokens.length, 3);
        assertEq(tokens[0], 1);
        assertEq(tokens[1], 2);
        assertEq(tokens[2], 4);
        
        uint256[] memory tokensUser2 = nft.tokensOfOwner(user2);
        assertEq(tokensUser2.length, 1);
        assertEq(tokensUser2[0], 3);
        
        // 测试空地址
        uint256[] memory emptyTokens = nft.tokensOfOwner(makeAddr("empty"));
        assertEq(emptyTokens.length, 0);
    }
    
    function testExists() public {
        assertFalse(nft.exists(1));
        
        nft.mint(user1, TOKEN_URI);
        assertTrue(nft.exists(1));
        assertFalse(nft.exists(2));
    }
    
    function testRoyaltyInfo() public {
        nft.mint(user1, TOKEN_URI);
        
        uint256 salePrice = 1 ether;
        (address receiver, uint256 royaltyAmount) = nft.royaltyInfo(1, salePrice);
        
        assertEq(receiver, royaltyReceiver);
        assertEq(royaltyAmount, (salePrice * 250) / 10000); // 2.5%
    }
    
    function testRoyaltyInfoFailNonExistentToken() public {
        vm.expectRevert("Token does not exist");
        nft.royaltyInfo(1, 1 ether);
    }
    
    // ========== 资金管理测试 ==========
    function testWithdraw() public {
        // 用户铸造NFT，合约收到ETH
        vm.startPrank(user1);
        nft.mint{value: MINT_PRICE}(user1, TOKEN_URI);
        vm.stopPrank();
        
        uint256 contractBalance = address(nft).balance;
        uint256 ownerBalanceBefore = address(this).balance;
        
        nft.withdraw();
        
        assertEq(address(nft).balance, 0);
        assertEq(address(this).balance, ownerBalanceBefore + contractBalance);
    }
    
    function testWithdrawFailNoFunds() public {
        vm.expectRevert("No funds to withdraw");
        nft.withdraw();
    }
    
    function testWithdrawFailNotOwner() public {
        vm.startPrank(user1);
        
        vm.expectRevert(abi.encodeWithSelector(Ownable.OwnableUnauthorizedAccount.selector, user1));
        nft.withdraw();
        
        vm.stopPrank();
    }
    
    // ========== 接口支持测试 ==========
    function testSupportsInterface() public {
        // ERC721
        assertTrue(nft.supportsInterface(0x80ac58cd));
        // ERC721Metadata
        assertTrue(nft.supportsInterface(0x5b5e139f));
        // ERC721Enumerable
        assertTrue(nft.supportsInterface(0x780e9d63));
        // ERC2981 (Royalty)
        assertTrue(nft.supportsInterface(0x2a55205a));
        // ERC165
        assertTrue(nft.supportsInterface(0x01ffc9a7));
    }
    
    // ========== 边界条件测试 ==========
    function testMintMaxSupply() public {
        nft.setMaxSupply(2);
        
        vm.startPrank(user1);
        nft.mint{value: MINT_PRICE}(user1, "https://example.com/token/1");
        nft.mint{value: MINT_PRICE}(user1, "https://example.com/token/2");
        vm.stopPrank();
        
        assertEq(nft.totalSupply(), 2);
        assertEq(nft.getCurrentTokenId(), 3);
    }
    
    function testMintMaxPerAddress() public {
        nft.setMaxMintPerAddress(2);
        
        vm.startPrank(user1);
        nft.mint{value: MINT_PRICE}(user1, "https://example.com/token/1");
        nft.mint{value: MINT_PRICE}(user1, "https://example.com/token/2");
        vm.stopPrank();
        
        assertEq(nft.mintedCount(user1), 2);
        assertEq(nft.balanceOf(user1), 2);
    }
    
    // ========== 辅助函数 ==========
    receive() external payable {}
}