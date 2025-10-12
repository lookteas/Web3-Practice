// SPDX-License-Identifier: MIT
pragma solidity ^0.8.25;

import "forge-std/Test.sol";
import "../src/NFTMarket.sol";
import "../src/MyNFT.sol";

contract IntegrationTest is Test {
    NFTMarket public market;
    MyNFT public nft;
    
    address public owner;
    address public feeRecipient;
    address public royaltyReceiver;
    address public seller;
    address public buyer;
    address public bidder1;
    address public bidder2;
    
    uint256 constant PLATFORM_FEE = 250; // 2.5%
    uint256 constant ROYALTY_FEE = 250; // 2.5%
    uint256 constant NFT_PRICE = 1 ether;
    uint256 constant MINT_PRICE = 0.01 ether;
    
    string constant TOKEN_URI_BASE = "https://example.com/token/";
    
    function setUp() public {
        owner = address(this);
        feeRecipient = makeAddr("feeRecipient");
        royaltyReceiver = makeAddr("royaltyReceiver");
        seller = makeAddr("seller");
        buyer = makeAddr("buyer");
        bidder1 = makeAddr("bidder1");
        bidder2 = makeAddr("bidder2");
        
        // 部署合约
        market = new NFTMarket(feeRecipient);
        nft = new MyNFT("IntegrationNFT", "INFT", royaltyReceiver);
        
        // 给用户分配ETH
        vm.deal(seller, 100 ether);
        vm.deal(buyer, 100 ether);
        vm.deal(bidder1, 100 ether);
        vm.deal(bidder2, 100 ether);
        
        // 铸造NFT给seller
        vm.startPrank(seller);
        for (uint256 i = 1; i <= 5; i++) {
            nft.mint{value: MINT_PRICE}(seller, string(abi.encodePacked(TOKEN_URI_BASE, vm.toString(i))));
        }
        
        // 授权市场合约
        nft.setApprovalForAll(address(market), true);
        vm.stopPrank();
    }
    
    // ========== 完整的买卖流程测试 ==========
    function testCompleteListingAndSaleFlow() public {
        uint256 tokenId = 1;
        
        // 1. 卖家上架NFT
        vm.startPrank(seller);
        market.listNFT(address(nft), tokenId, NFT_PRICE);
        vm.stopPrank();
        
        // 验证上架状态
        assertEq(market.nftToListingId(address(nft), tokenId), 1);
        (,,,, uint256 price, bool active,,) = market.listings(1);
        assertEq(price, NFT_PRICE);
        assertTrue(active);
        
        // 2. 买家购买NFT
        uint256 sellerBalanceBefore = seller.balance;
        uint256 feeRecipientBalanceBefore = feeRecipient.balance;
        uint256 buyerBalanceBefore = buyer.balance;
        
        vm.startPrank(buyer);
        market.buyNFT{value: NFT_PRICE}(1);
        vm.stopPrank();
        
        // 3. 验证结果
        // NFT所有权转移
        assertEq(nft.ownerOf(tokenId), buyer);
        
        // 上架状态更新
        (,,,, , bool activeAfter,,) = market.listings(1);
        assertFalse(activeAfter);
        assertEq(market.nftToListingId(address(nft), tokenId), 0);
        
        // 资金分配
        uint256 platformFee = (NFT_PRICE * PLATFORM_FEE) / 10000;
        uint256 sellerAmount = NFT_PRICE - platformFee;
        
        assertEq(seller.balance, sellerBalanceBefore + sellerAmount);
        assertEq(feeRecipient.balance, feeRecipientBalanceBefore + platformFee);
        assertEq(buyer.balance, buyerBalanceBefore - NFT_PRICE);
    }
    
    // ========== 完整的拍卖流程测试 ==========
    function testCompleteAuctionFlow() public {
        uint256 tokenId = 2;
        uint256 startingPrice = 0.5 ether;
        uint256 duration = 1 days;
        uint256 bid1 = 0.8 ether;
        uint256 bid2 = 1.2 ether;
        
        // 1. 卖家创建拍卖
        vm.startPrank(seller);
        market.createAuction(address(nft), tokenId, startingPrice, duration);
        vm.stopPrank();
        
        // 验证拍卖创建
        (,,,, uint256 auctionStartingPrice,,,, bool active,) = market.auctions(1);
        assertEq(auctionStartingPrice, startingPrice);
        assertTrue(active);
        
        // 2. 第一个竞拍者出价
        vm.startPrank(bidder1);
        market.placeBid{value: bid1}(1);
        vm.stopPrank();
        
        // 验证出价
        (,,,, , uint256 currentBid, address currentBidder,,,) = market.auctions(1);
        assertEq(currentBid, bid1);
        assertEq(currentBidder, bidder1);
        
        // 3. 第二个竞拍者出价更高
        uint256 bidder1BalanceBefore = bidder1.balance;
        
        vm.startPrank(bidder2);
        market.placeBid{value: bid2}(1);
        vm.stopPrank();
        
        // 验证出价更新和退款
        (,,,, , uint256 newCurrentBid, address newCurrentBidder,,,) = market.auctions(1);
        assertEq(newCurrentBid, bid2);
        assertEq(newCurrentBidder, bidder2);
        assertEq(bidder1.balance, bidder1BalanceBefore + bid1); // 第一个竞拍者收到退款
        
        // 4. 时间推进到拍卖结束
        vm.warp(block.timestamp + duration + 1);
        
        // 5. 结束拍卖
        uint256 sellerBalanceBefore = seller.balance;
        uint256 feeRecipientBalanceBefore = feeRecipient.balance;
        
        market.endAuction(1);
        
        // 6. 验证结果
        // NFT转移给获胜者
        assertEq(nft.ownerOf(tokenId), bidder2);
        
        // 拍卖状态更新
        (,,,,,,,, bool activeAfter,) = market.auctions(1);
        assertFalse(activeAfter);
        
        // 资金分配
        uint256 platformFee = (bid2 * PLATFORM_FEE) / 10000;
        uint256 sellerAmount = bid2 - platformFee;
        
        assertEq(seller.balance, sellerBalanceBefore + sellerAmount);
        assertEq(feeRecipient.balance, feeRecipientBalanceBefore + platformFee);
    }
    
    // ========== 报价流程测试 ==========
    function testCompleteOfferFlow() public {
        uint256 tokenId = 3;
        uint256 offerPrice = 0.8 ether;
        uint256 expiration = block.timestamp + 1 days;
        
        // 1. 买家提出报价
        vm.startPrank(buyer);
        market.makeOffer{value: offerPrice}(address(nft), tokenId, expiration);
        vm.stopPrank();
        
        // 验证报价创建
        (,, uint256 offerTokenId, address offerBuyer, uint256 price,, bool active,) = market.offers(1);
        assertEq(offerTokenId, tokenId);
        assertEq(offerBuyer, buyer);
        assertEq(price, offerPrice);
        assertTrue(active);
        
        // 2. 卖家接受报价
        uint256 sellerBalanceBefore = seller.balance;
        uint256 feeRecipientBalanceBefore = feeRecipient.balance;
        
        vm.startPrank(seller);
        market.acceptOffer(1);
        vm.stopPrank();
        
        // 3. 验证结果
        // NFT转移
        assertEq(nft.ownerOf(tokenId), buyer);
        
        // 报价状态更新
        (,,,,,, bool activeAfter,) = market.offers(1);
        assertFalse(activeAfter);
        
        // 资金分配
        uint256 platformFee = (offerPrice * PLATFORM_FEE) / 10000;
        uint256 sellerAmount = offerPrice - platformFee;
        
        assertEq(seller.balance, sellerBalanceBefore + sellerAmount);
        assertEq(feeRecipient.balance, feeRecipientBalanceBefore + platformFee);
    }
    
    // ========== 多重交互测试 ==========
    function testMultipleListingsAndSales() public {
        uint256[] memory tokenIds = new uint256[](3);
        tokenIds[0] = 1;
        tokenIds[1] = 2;
        tokenIds[2] = 3;
        
        uint256[] memory prices = new uint256[](3);
        prices[0] = 1 ether;
        prices[1] = 1.5 ether;
        prices[2] = 2 ether;
        
        // 1. 卖家上架多个NFT
        vm.startPrank(seller);
        for (uint256 i = 0; i < tokenIds.length; i++) {
            market.listNFT(address(nft), tokenIds[i], prices[i]);
        }
        vm.stopPrank();
        
        // 2. 验证所有上架
        for (uint256 i = 0; i < tokenIds.length; i++) {
            assertEq(market.nftToListingId(address(nft), tokenIds[i]), i + 1);
            (,,,, uint256 price, bool active,,) = market.listings(i + 1);
            assertEq(price, prices[i]);
            assertTrue(active);
        }
        
        // 3. 买家购买第二个NFT
        vm.startPrank(buyer);
        market.buyNFT{value: prices[1]}(2);
        vm.stopPrank();
        
        // 4. 验证购买结果
        assertEq(nft.ownerOf(tokenIds[1]), buyer);
        (,,,, , bool active2,,) = market.listings(2);
        assertFalse(active2);
        
        // 5. 验证其他上架仍然活跃
        (,,,, , bool active1,,) = market.listings(1);
        (,,,, , bool active3,,) = market.listings(3);
        assertTrue(active1);
        assertTrue(active3);
        
        // 6. 获取活跃上架列表
        NFTMarket.Listing[] memory activeListings = market.getActiveListings(0, 10);
        assertEq(activeListings.length, 2);
    }
    
    // ========== 权限和安全测试 ==========
    function testUnauthorizedActions() public {
        uint256 tokenId = 1;
        
        // 非所有者尝试上架NFT
        vm.startPrank(buyer);
        
        vm.expectRevert("Not the owner of this NFT");
        market.listNFT(address(nft), tokenId, NFT_PRICE);
        
        vm.stopPrank();
        
        // 上架NFT
        vm.startPrank(seller);
        market.listNFT(address(nft), tokenId, NFT_PRICE);
        vm.stopPrank();
        
        // 非授权用户尝试取消上架
        vm.startPrank(buyer);
        
        vm.expectRevert("Not authorized to cancel");
        market.cancelListing(1);
        
        vm.stopPrank();
        
        // 卖家尝试购买自己的NFT
        vm.startPrank(seller);
        
        vm.expectRevert("Cannot buy your own NFT");
        market.buyNFT{value: NFT_PRICE}(1);
        
        vm.stopPrank();
    }
    
    // ========== 边界条件测试 ==========
    function testEdgeCases() public {
        uint256 tokenId = 1;
        
        // 测试最小价格边界
        vm.startPrank(seller);
        
        // 刚好等于最小价格应该成功
        market.listNFT(address(nft), tokenId, market.minimumPrice());
        market.cancelListing(1);
        
        // 低于最小价格应该失败
        uint256 belowMinimumPrice = market.minimumPrice() - 1;
        vm.expectRevert("Price below minimum");
        market.listNFT(address(nft), tokenId, belowMinimumPrice);
        
        vm.stopPrank();
        
        // 测试拍卖时间边界
        vm.startPrank(seller);
        
        // 刚好1小时应该成功
        market.createAuction(address(nft), tokenId, 0.5 ether, 3600);
        
        // 取消拍卖以便重新测试
        vm.warp(block.timestamp + 3601);
        market.endAuction(1);
        
        // 刚好30天应该成功
        market.createAuction(address(nft), tokenId, 0.5 ether, 30 days);
        
        vm.stopPrank();
    }
    
    // ========== 状态一致性测试 ==========
    function testStateConsistency() public {
        uint256 tokenId = 1;
        
        // 1. 上架NFT
        vm.startPrank(seller);
        market.listNFT(address(nft), tokenId, NFT_PRICE);
        vm.stopPrank();
        
        // 2. 验证映射一致性
        assertEq(market.nftToListingId(address(nft), tokenId), 1);
        
        // 3. 购买NFT
        vm.startPrank(buyer);
        market.buyNFT{value: NFT_PRICE}(1);
        vm.stopPrank();
        
        // 4. 验证映射清理
        assertEq(market.nftToListingId(address(nft), tokenId), 0);
        
        // 5. 尝试再次上架同一个NFT（现在属于buyer）
        vm.startPrank(buyer);
        nft.setApprovalForAll(address(market), true);
        market.listNFT(address(nft), tokenId, NFT_PRICE);
        vm.stopPrank();
        
        // 6. 验证新的映射
        assertEq(market.nftToListingId(address(nft), tokenId), 2);
    }
    
    // ========== 复杂场景测试 ==========
    function testComplexScenario() public {
        // 场景：卖家同时进行上架和拍卖，买家同时参与购买、竞拍和报价
        
        // 1. 卖家上架NFT #1
        vm.startPrank(seller);
        market.listNFT(address(nft), 1, 1 ether);
        vm.stopPrank();
        
        // 2. 卖家创建NFT #2的拍卖
        vm.startPrank(seller);
        market.createAuction(address(nft), 2, 0.5 ether, 1 days);
        vm.stopPrank();
        
        // 3. 买家对NFT #3提出报价
        vm.startPrank(buyer);
        market.makeOffer{value: 0.8 ether}(address(nft), 3, block.timestamp + 1 days);
        vm.stopPrank();
        
        // 4. 竞拍者参与NFT #2的拍卖
        vm.startPrank(bidder1);
        market.placeBid{value: 0.8 ether}(1);
        vm.stopPrank();
        
        // 5. 买家购买NFT #1
        vm.startPrank(buyer);
        market.buyNFT{value: 1 ether}(1);
        vm.stopPrank();
        
        // 6. 卖家接受NFT #3的报价
        vm.startPrank(seller);
        market.acceptOffer(1);
        vm.stopPrank();
        
        // 7. 验证最终状态
        assertEq(nft.ownerOf(1), buyer);  // NFT #1被买家购买
        assertEq(nft.ownerOf(3), buyer);  // NFT #3通过报价给了买家
        assertEq(nft.ownerOf(2), seller); // NFT #2仍在拍卖中，属于卖家
        
        // 8. 结束拍卖
        vm.warp(block.timestamp + 1 days + 1);
        market.endAuction(1);
        
        // 9. 验证拍卖结果
        assertEq(nft.ownerOf(2), bidder1); // NFT #2被竞拍者获得
    }
    
    // ========== Gas优化测试 ==========
    function testGasOptimization() public {
        uint256 tokenId = 1;
        
        // 测试上架的gas消耗
        vm.startPrank(seller);
        uint256 gasStart = gasleft();
        market.listNFT(address(nft), tokenId, NFT_PRICE);
        uint256 gasUsed = gasStart - gasleft();
        vm.stopPrank();
        
        // 记录gas使用情况（用于优化参考）
        emit log_named_uint("Gas used for listing", gasUsed);
        
        // 测试购买的gas消耗
        vm.startPrank(buyer);
        gasStart = gasleft();
        market.buyNFT{value: NFT_PRICE}(1);
        gasUsed = gasStart - gasleft();
        vm.stopPrank();
        
        emit log_named_uint("Gas used for buying", gasUsed);
    }
    
    // ========== 辅助函数 ==========
    receive() external payable {}
}