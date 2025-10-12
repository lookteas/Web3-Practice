// SPDX-License-Identifier: MIT
pragma solidity ^0.8.25;

import "forge-std/Test.sol";
import "../src/NFTMarket.sol";
import "../src/MyNFT.sol";

contract NFTMarketTest is Test {
    NFTMarket public market;
    MyNFT public nft;
    
    address public owner;
    address public feeRecipient;
    address public seller;
    address public buyer;
    address public bidder1;
    address public bidder2;
    
    uint256 constant PLATFORM_FEE = 250; // 2.5%
    uint256 constant MINIMUM_PRICE = 0.001 ether;
    uint256 constant NFT_PRICE = 1 ether;
    uint256 constant MINT_PRICE = 0.01 ether;
    
    string constant TOKEN_URI = "https://example.com/token/";
    
    // Events
    event NFTListed(
        uint256 indexed listingId,
        address indexed nftContract,
        uint256 indexed tokenId,
        address seller,
        uint256 price
    );
    
    event NFTSold(
        uint256 indexed listingId,
        address indexed nftContract,
        uint256 indexed tokenId,
        address seller,
        address buyer,
        uint256 price
    );
    
    event ListingCancelled(
        uint256 indexed listingId,
        address indexed nftContract,
        uint256 indexed tokenId,
        address seller
    );
    
    event AuctionCreated(
        uint256 indexed auctionId,
        address indexed nftContract,
        uint256 indexed tokenId,
        address seller,
        uint256 startingPrice,
        uint256 endTime
    );
    
    event BidPlaced(
        uint256 indexed auctionId,
        address indexed bidder,
        uint256 bidAmount
    );
    
    event OfferMade(
        uint256 indexed offerId,
        address indexed nftContract,
        uint256 indexed tokenId,
        address buyer,
        uint256 price,
        uint256 expiration
    );
    
    function setUp() public {
        owner = address(this);
        feeRecipient = makeAddr("feeRecipient");
        seller = makeAddr("seller");
        buyer = makeAddr("buyer");
        bidder1 = makeAddr("bidder1");
        bidder2 = makeAddr("bidder2");
        
        // 部署合约
        market = new NFTMarket(feeRecipient);
        nft = new MyNFT("TestNFT", "TNFT", seller);
        
        // 给用户分配ETH
        vm.deal(seller, 100 ether);
        vm.deal(buyer, 100 ether);
        vm.deal(bidder1, 100 ether);
        vm.deal(bidder2, 100 ether);
        
        // 铸造NFT给seller
        vm.startPrank(seller);
        nft.mint{value: MINT_PRICE}(seller, string(abi.encodePacked(TOKEN_URI, "1")));
        nft.mint{value: MINT_PRICE}(seller, string(abi.encodePacked(TOKEN_URI, "2")));
        nft.mint{value: MINT_PRICE}(seller, string(abi.encodePacked(TOKEN_URI, "3")));
        
        // 授权市场合约
        nft.setApprovalForAll(address(market), true);
        vm.stopPrank();
    }
    
    // ========== 部署测试 ==========
    function testDeployment() public {
        assertEq(market.owner(), owner);
        assertEq(market.feeRecipient(), feeRecipient);
        assertEq(market.platformFeePercentage(), PLATFORM_FEE);
        assertEq(market.minimumPrice(), MINIMUM_PRICE);
        assertFalse(market.paused());
    }
    
    function testDeploymentFailZeroAddress() public {
        vm.expectRevert("Fee recipient cannot be zero address");
        new NFTMarket(address(0));
    }
    
    // ========== 上架功能测试 ==========
    function testListNFTSuccess() public {
        vm.startPrank(seller);
        
        vm.expectEmit(true, true, true, true);
        emit NFTListed(1, address(nft), 1, seller, NFT_PRICE);
        
        market.listNFT(address(nft), 1, NFT_PRICE);
        
        (
            uint256 listingId,
            address nftContract,
            uint256 tokenId,
            address listingSeller,
            uint256 price,
            bool active,
            uint256 createdAt,
            uint256 updatedAt
        ) = market.listings(1);
        
        assertEq(listingId, 1);
        assertEq(nftContract, address(nft));
        assertEq(tokenId, 1);
        assertEq(listingSeller, seller);
        assertEq(price, NFT_PRICE);
        assertTrue(active);
        assertEq(createdAt, block.timestamp);
        assertEq(updatedAt, block.timestamp);
        assertEq(market.nftToListingId(address(nft), 1), 1);
        
        vm.stopPrank();
    }
    
    function testListNFTFailZeroAddress() public {
        vm.startPrank(seller);
        
        vm.expectRevert("NFT contract cannot be zero address");
        market.listNFT(address(0), 1, NFT_PRICE);
        
        vm.stopPrank();
    }
    
    function testListNFTFailBelowMinimum() public {
        vm.startPrank(seller);
        
        vm.expectRevert("Price below minimum");
        market.listNFT(address(nft), 1, MINIMUM_PRICE - 1);
        
        vm.stopPrank();
    }
    
    function testListNFTFailNotOwner() public {
        vm.startPrank(buyer);
        
        vm.expectRevert("Not the owner of this NFT");
        market.listNFT(address(nft), 1, NFT_PRICE);
        
        vm.stopPrank();
    }
    
    function testListNFTFailNotApproved() public {
        vm.startPrank(seller);
        nft.setApprovalForAll(address(market), false);
        
        vm.expectRevert("Market not approved to transfer NFT");
        market.listNFT(address(nft), 1, NFT_PRICE);
        
        vm.stopPrank();
    }
    
    function testListNFTFailAlreadyListed() public {
        vm.startPrank(seller);
        market.listNFT(address(nft), 1, NFT_PRICE);
        
        vm.expectRevert("NFT already listed");
        market.listNFT(address(nft), 1, NFT_PRICE);
        
        vm.stopPrank();
    }
    
    // ========== 购买功能测试 ==========
    function testBuyNFTSuccess() public {
        // 先上架
        vm.startPrank(seller);
        market.listNFT(address(nft), 1, NFT_PRICE);
        vm.stopPrank();
        
        uint256 sellerBalanceBefore = seller.balance;
        uint256 feeRecipientBalanceBefore = feeRecipient.balance;
        uint256 buyerBalanceBefore = buyer.balance;
        
        vm.startPrank(buyer);
        
        vm.expectEmit(true, true, true, true);
        emit NFTSold(1, address(nft), 1, seller, buyer, NFT_PRICE);
        
        market.buyNFT{value: NFT_PRICE}(1);
        vm.stopPrank();
        
        // 检查NFT所有权转移
        assertEq(nft.ownerOf(1), buyer);
        
        // 检查上架状态
        (, , , , , bool active, ,) = market.listings(1);
        assertFalse(active);
        assertEq(market.nftToListingId(address(nft), 1), 0);
        
        // 检查资金分配
        uint256 platformFee = (NFT_PRICE * PLATFORM_FEE) / 10000;
        uint256 sellerAmount = NFT_PRICE - platformFee;
        
        assertEq(seller.balance, sellerBalanceBefore + sellerAmount);
        assertEq(feeRecipient.balance, feeRecipientBalanceBefore + platformFee);
        assertEq(buyer.balance, buyerBalanceBefore - NFT_PRICE);
    }
    
    function testBuyNFTWithExcessPayment() public {
        vm.startPrank(seller);
        market.listNFT(address(nft), 1, NFT_PRICE);
        vm.stopPrank();
        
        uint256 buyerBalanceBefore = buyer.balance;
        uint256 excessAmount = 0.5 ether;
        
        vm.startPrank(buyer);
        market.buyNFT{value: NFT_PRICE + excessAmount}(1);
        vm.stopPrank();
        
        // 应该退还多余的ETH
        assertEq(buyer.balance, buyerBalanceBefore - NFT_PRICE);
        assertEq(nft.ownerOf(1), buyer);
    }
    
    function testBuyNFTFailInactive() public {
        vm.startPrank(buyer);
        
        vm.expectRevert("Listing not active");
        market.buyNFT{value: NFT_PRICE}(1);
        
        vm.stopPrank();
    }
    
    function testBuyNFTFailInsufficientPayment() public {
        vm.startPrank(seller);
        market.listNFT(address(nft), 1, NFT_PRICE);
        vm.stopPrank();
        
        vm.startPrank(buyer);
        
        vm.expectRevert("Insufficient payment");
        market.buyNFT{value: NFT_PRICE - 1}(1);
        
        vm.stopPrank();
    }
    
    function testBuyNFTFailOwnNFT() public {
        vm.startPrank(seller);
        market.listNFT(address(nft), 1, NFT_PRICE);
        
        vm.expectRevert("Cannot buy your own NFT");
        market.buyNFT{value: NFT_PRICE}(1);
        
        vm.stopPrank();
    }
    
    // ========== 取消上架测试 ==========
    function testCancelListingBySeller() public {
        vm.startPrank(seller);
        market.listNFT(address(nft), 1, NFT_PRICE);
        
        vm.expectEmit(true, true, true, true);
        emit ListingCancelled(1, address(nft), 1, seller);
        
        market.cancelListing(1);
        
        (, , , , , bool active, ,) = market.listings(1);
        assertFalse(active);
        assertEq(market.nftToListingId(address(nft), 1), 0);
        
        vm.stopPrank();
    }
    
    function testCancelListingByOwner() public {
        vm.startPrank(seller);
        market.listNFT(address(nft), 1, NFT_PRICE);
        vm.stopPrank();
        
        // Owner可以取消任何上架
        market.cancelListing(1);
        
        (, , , , , bool active, ,) = market.listings(1);
        assertFalse(active);
    }
    
    function testCancelListingFailNotAuthorized() public {
        vm.startPrank(seller);
        market.listNFT(address(nft), 1, NFT_PRICE);
        vm.stopPrank();
        
        vm.startPrank(buyer);
        
        vm.expectRevert("Not authorized to cancel");
        market.cancelListing(1);
        
        vm.stopPrank();
    }
    
    // ========== 更新价格测试 ==========
    function testUpdateListingPrice() public {
        vm.startPrank(seller);
        market.listNFT(address(nft), 1, NFT_PRICE);
        
        uint256 newPrice = 2 ether;
        market.updateListingPrice(1, newPrice);
        
        (, , , , uint256 price, , , uint256 updatedAt) = market.listings(1);
        assertEq(price, newPrice);
        assertEq(updatedAt, block.timestamp);
        
        vm.stopPrank();
    }
    
    function testUpdateListingPriceFailNotSeller() public {
        vm.startPrank(seller);
        market.listNFT(address(nft), 1, NFT_PRICE);
        vm.stopPrank();
        
        vm.startPrank(buyer);
        
        vm.expectRevert("Not the seller");
        market.updateListingPrice(1, 2 ether);
        
        vm.stopPrank();
    }
    
    function testUpdateListingPriceFailSamePrice() public {
        vm.startPrank(seller);
        market.listNFT(address(nft), 1, NFT_PRICE);
        
        vm.expectRevert("Same price");
        market.updateListingPrice(1, NFT_PRICE);
        
        vm.stopPrank();
    }
    
    // ========== 拍卖功能测试 ==========
    function testCreateAuctionSuccess() public {
        uint256 startingPrice = 0.5 ether;
        uint256 duration = 1 days;
        
        vm.startPrank(seller);
        
        vm.expectEmit(true, true, true, true);
        emit AuctionCreated(1, address(nft), 1, seller, startingPrice, block.timestamp + duration);
        
        market.createAuction(address(nft), 1, startingPrice, duration);
        
        (
            uint256 auctionId,
            address nftContract,
            uint256 tokenId,
            address auctionSeller,
            uint256 auctionStartingPrice,
            uint256 currentBid,
            address currentBidder,
            uint256 endTime,
            bool active,
            uint256 createdAt
        ) = market.auctions(1);
        
        assertEq(auctionId, 1);
        assertEq(nftContract, address(nft));
        assertEq(tokenId, 1);
        assertEq(auctionSeller, seller);
        assertEq(auctionStartingPrice, startingPrice);
        assertEq(currentBid, 0);
        assertEq(currentBidder, address(0));
        assertEq(endTime, block.timestamp + duration);
        assertTrue(active);
        assertEq(createdAt, block.timestamp);
        
        vm.stopPrank();
    }
    
    function testCreateAuctionFailDurationTooShort() public {
        vm.startPrank(seller);
        
        vm.expectRevert("Duration must be at least 1 hour");
        market.createAuction(address(nft), 1, 0.5 ether, 3599); // 59分59秒
        
        vm.stopPrank();
    }
    
    function testCreateAuctionFailDurationTooLong() public {
        vm.startPrank(seller);
        
        vm.expectRevert("Duration cannot exceed 30 days");
        market.createAuction(address(nft), 1, 0.5 ether, 31 days);
        
        vm.stopPrank();
    }
    
    // ========== 出价功能测试 ==========
    function testPlaceBidSuccess() public {
        uint256 startingPrice = 0.5 ether;
        uint256 bidAmount = 1 ether;
        
        vm.startPrank(seller);
        market.createAuction(address(nft), 1, startingPrice, 1 days);
        vm.stopPrank();
        
        vm.startPrank(bidder1);
        
        vm.expectEmit(true, true, false, true);
        emit BidPlaced(1, bidder1, bidAmount);
        
        market.placeBid{value: bidAmount}(1);
        
        (, , , , , uint256 currentBid, address currentBidder, , ,) = market.auctions(1);
        assertEq(currentBid, bidAmount);
        assertEq(currentBidder, bidder1);
        
        vm.stopPrank();
    }
    
    function testPlaceBidWithRefund() public {
        uint256 startingPrice = 0.5 ether;
        uint256 firstBid = 1 ether;
        uint256 secondBid = 1.5 ether;
        
        vm.startPrank(seller);
        market.createAuction(address(nft), 1, startingPrice, 1 days);
        vm.stopPrank();
        
        // 第一次出价
        vm.startPrank(bidder1);
        market.placeBid{value: firstBid}(1);
        vm.stopPrank();
        
        uint256 bidder1BalanceBefore = bidder1.balance;
        
        // 第二次出价，应该退还第一次出价
        vm.startPrank(bidder2);
        market.placeBid{value: secondBid}(1);
        vm.stopPrank();
        
        assertEq(bidder1.balance, bidder1BalanceBefore + firstBid);
        
        (, , , , , uint256 currentBid, address currentBidder, , ,) = market.auctions(1);
        assertEq(currentBid, secondBid);
        assertEq(currentBidder, bidder2);
    }
    
    function testPlaceBidExtendTime() public {
        uint256 startingPrice = 0.5 ether;
        uint256 duration = 1 hours;
        
        vm.startPrank(seller);
        market.createAuction(address(nft), 1, startingPrice, duration);
        vm.stopPrank();
        
        // 跳到拍卖结束前4分钟
        vm.warp(block.timestamp + duration - 4 minutes);
        
        vm.startPrank(bidder1);
        market.placeBid{value: 1 ether}(1);
        vm.stopPrank();
        
        // 检查时间是否延长了5分钟
        (, , , , , , , uint256 endTime, ,) = market.auctions(1);
        assertEq(endTime, block.timestamp + 5 minutes);
    }
    
    function testPlaceBidFailBelowStarting() public {
        uint256 startingPrice = 1 ether;
        
        vm.startPrank(seller);
        market.createAuction(address(nft), 1, startingPrice, 1 days);
        vm.stopPrank();
        
        vm.startPrank(bidder1);
        
        vm.expectRevert("Bid below starting price");
        market.placeBid{value: startingPrice - 1}(1);
        
        vm.stopPrank();
    }
    
    function testPlaceBidFailOwnAuction() public {
        vm.startPrank(seller);
        market.createAuction(address(nft), 1, 0.5 ether, 1 days);
        
        vm.expectRevert("Cannot bid on your own auction");
        market.placeBid{value: 1 ether}(1);
        
        vm.stopPrank();
    }
    
    // ========== 结束拍卖测试 ==========
    function testEndAuctionWithWinner() public {
        uint256 startingPrice = 0.5 ether;
        uint256 bidAmount = 1 ether;
        
        vm.startPrank(seller);
        market.createAuction(address(nft), 1, startingPrice, 1 hours);
        vm.stopPrank();
        
        vm.startPrank(bidder1);
        market.placeBid{value: bidAmount}(1);
        vm.stopPrank();
        
        // 跳到拍卖结束后
        vm.warp(block.timestamp + 1 hours + 1);
        
        uint256 sellerBalanceBefore = seller.balance;
        uint256 feeRecipientBalanceBefore = feeRecipient.balance;
        
        market.endAuction(1);
        
        // 检查NFT转移
        assertEq(nft.ownerOf(1), bidder1);
        
        // 检查拍卖状态
        (, , , , , , , , bool active,) = market.auctions(1);
        assertFalse(active);
        
        // 检查资金分配
        uint256 platformFee = (bidAmount * PLATFORM_FEE) / 10000;
        uint256 sellerAmount = bidAmount - platformFee;
        
        assertEq(seller.balance, sellerBalanceBefore + sellerAmount);
        assertEq(feeRecipient.balance, feeRecipientBalanceBefore + platformFee);
    }
    
    function testEndAuctionWithoutBids() public {
        vm.startPrank(seller);
        market.createAuction(address(nft), 1, 0.5 ether, 1 hours);
        vm.stopPrank();
        
        // 跳到拍卖结束后
        vm.warp(block.timestamp + 1 hours + 1);
        
        market.endAuction(1);
        
        // NFT应该还在seller手中
        assertEq(nft.ownerOf(1), seller);
        
        // 拍卖应该标记为非活跃
        (, , , , , , , , bool active,) = market.auctions(1);
        assertFalse(active);
    }
    
    // ========== 报价功能测试 ==========
    function testMakeOfferSuccess() public {
        uint256 offerPrice = 0.8 ether;
        uint256 expiration = block.timestamp + 1 days;
        
        vm.startPrank(buyer);
        
        vm.expectEmit(true, true, true, true);
        emit OfferMade(1, address(nft), 1, buyer, offerPrice, expiration);
        
        market.makeOffer{value: offerPrice}(address(nft), 1, expiration);
        
        (
            uint256 offerId,
            address nftContract,
            uint256 tokenId,
            address offerBuyer,
            uint256 price,
            uint256 offerExpiration,
            bool active,
            uint256 createdAt
        ) = market.offers(1);
        
        assertEq(offerId, 1);
        assertEq(nftContract, address(nft));
        assertEq(tokenId, 1);
        assertEq(offerBuyer, buyer);
        assertEq(price, offerPrice);
        assertEq(offerExpiration, expiration);
        assertTrue(active);
        assertEq(createdAt, block.timestamp);
        
        vm.stopPrank();
    }
    
    function testMakeOfferFailOwnNFT() public {
        vm.startPrank(seller);
        
        vm.expectRevert("Cannot make offer on your own NFT");
        market.makeOffer{value: 1 ether}(address(nft), 1, block.timestamp + 1 days);
        
        vm.stopPrank();
    }
    
    function testAcceptOfferSuccess() public {
        uint256 offerPrice = 0.8 ether;
        uint256 expiration = block.timestamp + 1 days;
        
        // 买家提出报价
        vm.startPrank(buyer);
        market.makeOffer{value: offerPrice}(address(nft), 1, expiration);
        vm.stopPrank();
        
        uint256 sellerBalanceBefore = seller.balance;
        uint256 feeRecipientBalanceBefore = feeRecipient.balance;
        
        // 卖家接受报价
        vm.startPrank(seller);
        market.acceptOffer(1);
        vm.stopPrank();
        
        // 检查NFT转移
        assertEq(nft.ownerOf(1), buyer);
        
        // 检查报价状态
        (, , , , , , bool active,) = market.offers(1);
        assertFalse(active);
        
        // 检查资金分配
        uint256 platformFee = (offerPrice * PLATFORM_FEE) / 10000;
        uint256 sellerAmount = offerPrice - platformFee;
        
        assertEq(seller.balance, sellerBalanceBefore + sellerAmount);
        assertEq(feeRecipient.balance, feeRecipientBalanceBefore + platformFee);
    }
    
    function testCancelOfferSuccess() public {
        uint256 offerPrice = 0.8 ether;
        
        vm.startPrank(buyer);
        market.makeOffer{value: offerPrice}(address(nft), 1, block.timestamp + 1 days);
        
        uint256 buyerBalanceBefore = buyer.balance;
        
        market.cancelOffer(1);
        
        // 检查资金退还
        assertEq(buyer.balance, buyerBalanceBefore + offerPrice);
        
        // 检查报价状态
        (, , , , , , bool active,) = market.offers(1);
        assertFalse(active);
        
        vm.stopPrank();
    }
    
    // ========== 管理员功能测试 ==========
    function testSetPlatformFee() public {
        uint256 newFee = 500; // 5%
        
        market.setPlatformFee(newFee);
        assertEq(market.platformFeePercentage(), newFee);
    }
    
    function testSetPlatformFeeFailTooHigh() public {
        vm.expectRevert("Platform fee cannot exceed 10%");
        market.setPlatformFee(1001);
    }
    
    function testSetFeeRecipient() public {
        address newRecipient = makeAddr("newRecipient");
        
        market.setFeeRecipient(newRecipient);
        assertEq(market.feeRecipient(), newRecipient);
    }
    
    function testSetMinimumPrice() public {
        uint256 newMinPrice = 0.01 ether;
        
        market.setMinimumPrice(newMinPrice);
        assertEq(market.minimumPrice(), newMinPrice);
    }
    
    function testPauseUnpause() public {
        market.pause();
        assertTrue(market.paused());
        
        market.unpause();
        assertFalse(market.paused());
    }
    
    function testEmergencyWithdraw() public {
        // 向合约发送一些ETH
        vm.deal(address(market), 10 ether);
        
        uint256 ownerBalanceBefore = address(this).balance;
        
        market.emergencyWithdraw();
        
        assertEq(address(market).balance, 0);
        assertEq(address(this).balance, ownerBalanceBefore + 10 ether);
    }
    
    // ========== 查询功能测试 ==========
    function testGetActiveListings() public {
        // 创建多个上架
        vm.startPrank(seller);
        market.listNFT(address(nft), 1, NFT_PRICE);
        market.listNFT(address(nft), 2, NFT_PRICE);
        market.listNFT(address(nft), 3, NFT_PRICE);
        vm.stopPrank();
        
        // 取消一个上架
        vm.startPrank(seller);
        market.cancelListing(2);
        vm.stopPrank();
        
        NFTMarket.Listing[] memory activeListings = market.getActiveListings(0, 10);
        assertEq(activeListings.length, 2);
        assertEq(activeListings[0].tokenId, 1);
        assertEq(activeListings[1].tokenId, 3);
    }
    
    function testGetUserListings() public {
        vm.startPrank(seller);
        market.listNFT(address(nft), 1, NFT_PRICE);
        market.listNFT(address(nft), 2, NFT_PRICE);
        vm.stopPrank();
        
        NFTMarket.Listing[] memory userListings = market.getUserListings(seller);
        assertEq(userListings.length, 2);
        assertEq(userListings[0].tokenId, 1);
        assertEq(userListings[1].tokenId, 2);
    }
    
    // ========== 暂停状态测试 ==========
    function testListNFTFailWhenPaused() public {
        market.pause();
        
        vm.startPrank(seller);
        
        vm.expectRevert(Pausable.EnforcedPause.selector);
        market.listNFT(address(nft), 1, NFT_PRICE);
        
        vm.stopPrank();
    }
    
    function testBuyNFTFailWhenPaused() public {
        // 先上架
        vm.startPrank(seller);
        market.listNFT(address(nft), 1, NFT_PRICE);
        vm.stopPrank();
        
        // 暂停合约
        market.pause();
        
        vm.startPrank(buyer);
        
        vm.expectRevert(Pausable.EnforcedPause.selector);
        market.buyNFT{value: NFT_PRICE}(1);
        
        vm.stopPrank();
    }
    
    // ========== 辅助函数 ==========
    receive() external payable {}
}