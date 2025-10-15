// SPDX-License-Identifier: MIT
pragma solidity ^0.8.25;

import "forge-std/Test.sol";
import "../src/NFTMarketOptimized.sol";
import "../src/MyNFT.sol";

contract NFTMarketOptimizedTest is Test {
    NFTMarketOptimized public market;
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
    
    // Events - 优化后的事件
    event NFTListed(uint256 indexed listingId, address indexed nftContract, uint256 indexed tokenId, uint256 price);
    event NFTSold(uint256 indexed listingId, address indexed buyer, uint256 price);
    event ListingCancelled(uint256 indexed listingId);
    event ListingPriceUpdated(uint256 indexed listingId, uint256 newPrice);
    event AuctionCreated(uint256 indexed auctionId, address indexed nftContract, uint256 indexed tokenId, uint256 endTime);
    event BidPlaced(uint256 indexed auctionId, address indexed bidder, uint256 bidAmount);
    event AuctionEnded(uint256 indexed auctionId, address indexed winner, uint256 winningBid);
    event OfferMade(uint256 indexed offerId, address indexed nftContract, uint256 indexed tokenId, uint256 price);
    event OfferAccepted(uint256 indexed offerId, address indexed buyer, uint256 price);
    event PlatformFeeUpdated(uint256 newFee);
    
    // 添加 receive 函数以接收以太币
    receive() external payable {}
    
    function setUp() public {
        owner = address(this);
        feeRecipient = makeAddr("feeRecipient");
        seller = makeAddr("seller");
        buyer = makeAddr("buyer");
        bidder1 = makeAddr("bidder1");
        bidder2 = makeAddr("bidder2");
        
        // Deploy contracts
        market = new NFTMarketOptimized(feeRecipient);
        nft = new MyNFT("Test NFT", "TNFT", feeRecipient);
        
        // Setup balances
        vm.deal(seller, 100 ether);
        vm.deal(buyer, 100 ether);
        vm.deal(bidder1, 100 ether);
        vm.deal(bidder2, 100 ether);
        
        // Mint NFTs for testing
        vm.startPrank(seller);
        nft.mint{value: MINT_PRICE}(seller, TOKEN_URI);
        nft.mint{value: MINT_PRICE}(seller, TOKEN_URI);
        nft.mint{value: MINT_PRICE}(seller, TOKEN_URI);
        vm.stopPrank();
    }
    
    // ============ Listing Tests ============
    
    function testListNFT() public {
        vm.startPrank(seller);
        nft.approve(address(market), 1);
        
        vm.expectEmit(true, true, true, true);
        emit NFTListed(1, address(nft), 1, NFT_PRICE);
        
        market.listNFT(address(nft), 1, NFT_PRICE);
        
        (address nftContract, address listingSeller, uint96 price, uint32 tokenId, uint32 createdAt, bool active) = market.listings(1);
        assertEq(nftContract, address(nft));
        assertEq(listingSeller, seller);
        assertEq(price, NFT_PRICE);
        assertEq(tokenId, 1);
        assertTrue(active);
        assertEq(market.nftToListingId(address(nft), 1), 1);
        
        vm.stopPrank();
    }
    
    function testListNFTFailsWithInvalidAddress() public {
        vm.startPrank(seller);
        vm.expectRevert(NFTMarketOptimized.InvalidAddress.selector);
        market.listNFT(address(0), 1, NFT_PRICE);
        vm.stopPrank();
    }
    
    function testListNFTFailsWithPriceBelowMinimum() public {
        vm.startPrank(seller);
        nft.approve(address(market), 1);
        vm.expectRevert(NFTMarketOptimized.PriceBelowMinimum.selector);
        market.listNFT(address(nft), 1, MINIMUM_PRICE - 1);
        vm.stopPrank();
    }
    
    function testListNFTFailsWhenNotOwner() public {
        vm.startPrank(buyer);
        vm.expectRevert(NFTMarketOptimized.NotNFTOwner.selector);
        market.listNFT(address(nft), 1, NFT_PRICE);
        vm.stopPrank();
    }
    
    function testListNFTFailsWhenNotApproved() public {
        vm.startPrank(seller);
        vm.expectRevert(NFTMarketOptimized.MarketNotApproved.selector);
        market.listNFT(address(nft), 1, NFT_PRICE);
        vm.stopPrank();
    }
    
    function testListNFTFailsWhenAlreadyListed() public {
        vm.startPrank(seller);
        nft.approve(address(market), 1);
        market.listNFT(address(nft), 1, NFT_PRICE);
        
        vm.expectRevert(NFTMarketOptimized.NFTAlreadyListed.selector);
        market.listNFT(address(nft), 1, NFT_PRICE);
        vm.stopPrank();
    }
    
    // ============ Buying Tests ============
    
    function testBuyNFT() public {
        // List NFT
        vm.startPrank(seller);
        nft.approve(address(market), 1);
        market.listNFT(address(nft), 1, NFT_PRICE);
        vm.stopPrank();
        
        uint256 sellerBalanceBefore = seller.balance;
        uint256 feeRecipientBalanceBefore = feeRecipient.balance;
        
        // Buy NFT
        vm.startPrank(buyer);
        vm.expectEmit(true, true, false, true);
        emit NFTSold(1, buyer, NFT_PRICE);
        
        market.buyNFT{value: NFT_PRICE}(1);
        
        // Check NFT ownership
        assertEq(nft.ownerOf(1), buyer);
        
        // Check listing is inactive
        (, , , , , bool active) = market.listings(1);
        assertFalse(active);
        assertEq(market.nftToListingId(address(nft), 1), 0);
        
        // Check balances
        uint256 platformFee = (NFT_PRICE * PLATFORM_FEE) / 10000;
        uint256 sellerAmount = NFT_PRICE - platformFee;
        
        assertEq(seller.balance, sellerBalanceBefore + sellerAmount);
        assertEq(feeRecipient.balance, feeRecipientBalanceBefore + platformFee);
        
        vm.stopPrank();
    }
    
    function testBuyNFTWithExcessPayment() public {
        // List NFT
        vm.startPrank(seller);
        nft.approve(address(market), 1);
        market.listNFT(address(nft), 1, NFT_PRICE);
        vm.stopPrank();
        
        uint256 buyerBalanceBefore = buyer.balance;
        uint256 excessAmount = 0.5 ether;
        
        // Buy NFT with excess payment
        vm.startPrank(buyer);
        market.buyNFT{value: NFT_PRICE + excessAmount}(1);
        
        // Check buyer got refund
        assertEq(buyer.balance, buyerBalanceBefore - NFT_PRICE);
        
        vm.stopPrank();
    }
    
    function testBuyNFTFailsWithInsufficientPayment() public {
        // List NFT
        vm.startPrank(seller);
        nft.approve(address(market), 1);
        market.listNFT(address(nft), 1, NFT_PRICE);
        vm.stopPrank();
        
        // Try to buy with insufficient payment
        vm.startPrank(buyer);
        vm.expectRevert(NFTMarketOptimized.InsufficientPayment.selector);
        market.buyNFT{value: NFT_PRICE - 1}(1);
        vm.stopPrank();
    }
    
    function testBuyNFTFailsWhenListingNotActive() public {
        vm.startPrank(buyer);
        vm.expectRevert(NFTMarketOptimized.ListingNotActive.selector);
        market.buyNFT{value: NFT_PRICE}(1);
        vm.stopPrank();
    }
    
    function testBuyNFTFailsWhenBuyingOwnNFT() public {
        // List NFT
        vm.startPrank(seller);
        nft.approve(address(market), 1);
        market.listNFT(address(nft), 1, NFT_PRICE);
        
        // Try to buy own NFT
        vm.expectRevert(NFTMarketOptimized.CannotBuyOwnNFT.selector);
        market.buyNFT{value: NFT_PRICE}(1);
        vm.stopPrank();
    }
    
    // ============ Cancel Listing Tests ============
    
    function testCancelListing() public {
        // List NFT
        vm.startPrank(seller);
        nft.approve(address(market), 1);
        market.listNFT(address(nft), 1, NFT_PRICE);
        
        // Cancel listing
        vm.expectEmit(true, false, false, false);
        emit ListingCancelled(1);
        
        market.cancelListing(1);
        
        // Check listing is inactive
        (, , , , , bool active) = market.listings(1);
        assertFalse(active);
        assertEq(market.nftToListingId(address(nft), 1), 0);
        
        vm.stopPrank();
    }
    
    function testCancelListingByOwner() public {
        // List NFT
        vm.startPrank(seller);
        nft.approve(address(market), 1);
        market.listNFT(address(nft), 1, NFT_PRICE);
        vm.stopPrank();
        
        // Cancel listing as owner
        vm.expectEmit(true, false, false, false);
        emit ListingCancelled(1);
        
        market.cancelListing(1);
        
        // Check listing is inactive
        (, , , , , bool active) = market.listings(1);
        assertFalse(active);
    }
    
    function testCancelListingFailsWhenNotAuthorized() public {
        // List NFT
        vm.startPrank(seller);
        nft.approve(address(market), 1);
        market.listNFT(address(nft), 1, NFT_PRICE);
        vm.stopPrank();
        
        // Try to cancel as unauthorized user
        vm.startPrank(buyer);
        vm.expectRevert(NFTMarketOptimized.NotAuthorized.selector);
        market.cancelListing(1);
        vm.stopPrank();
    }
    
    // ============ Update Listing Price Tests ============
    
    function testUpdateListingPrice() public {
        uint256 newPrice = 2 ether;
        
        // List NFT
        vm.startPrank(seller);
        nft.approve(address(market), 1);
        market.listNFT(address(nft), 1, NFT_PRICE);
        
        // Update price
        vm.expectEmit(true, false, false, true);
        emit ListingPriceUpdated(1, newPrice);
        
        market.updateListingPrice(1, newPrice);
        
        // Check price updated
        (, , uint96 price, , , ) = market.listings(1);
        assertEq(price, newPrice);
        
        vm.stopPrank();
    }
    
    function testUpdateListingPriceFailsWhenNotSeller() public {
        // List NFT
        vm.startPrank(seller);
        nft.approve(address(market), 1);
        market.listNFT(address(nft), 1, NFT_PRICE);
        vm.stopPrank();
        
        // Try to update price as non-seller
        vm.startPrank(buyer);
        vm.expectRevert(NFTMarketOptimized.NotAuthorized.selector);
        market.updateListingPrice(1, 2 ether);
        vm.stopPrank();
    }
    
    function testUpdateListingPriceFailsWithSamePrice() public {
        // List NFT
        vm.startPrank(seller);
        nft.approve(address(market), 1);
        market.listNFT(address(nft), 1, NFT_PRICE);
        
        // Try to update with same price
        vm.expectRevert(NFTMarketOptimized.SamePrice.selector);
        market.updateListingPrice(1, NFT_PRICE);
        vm.stopPrank();
    }
    
    // ============ Auction Tests ============
    
    function testCreateAuction() public {
        uint256 duration = 1 days;
        uint256 expectedEndTime = block.timestamp + duration;
        
        vm.startPrank(seller);
        nft.approve(address(market), 1);
        
        vm.expectEmit(true, true, true, true);
        emit AuctionCreated(1, address(nft), 1, expectedEndTime);
        
        market.createAuction(address(nft), 1, NFT_PRICE, duration);
        
        (address nftContract, address auctionSeller, address currentBidder, uint96 startingPrice, uint96 currentBid, uint32 tokenId, uint32 endTime, uint32 createdAt, bool active) = market.auctions(1);
        assertEq(nftContract, address(nft));
        assertEq(auctionSeller, seller);
        assertEq(currentBidder, address(0));
        assertEq(startingPrice, NFT_PRICE);
        assertEq(currentBid, 0);
        assertEq(tokenId, 1);
        assertEq(endTime, expectedEndTime);
        assertTrue(active);
        
        vm.stopPrank();
    }
    
    function testPlaceBid() public {
        uint256 duration = 1 days;
        uint256 bidAmount = 1.5 ether;
        
        // Create auction
        vm.startPrank(seller);
        nft.approve(address(market), 1);
        market.createAuction(address(nft), 1, NFT_PRICE, duration);
        vm.stopPrank();
        
        // Place bid
        vm.startPrank(bidder1);
        vm.expectEmit(true, true, false, true);
        emit BidPlaced(1, bidder1, bidAmount);
        
        market.placeBid{value: bidAmount}(1);
        
        (, , address currentBidder, , uint96 currentBid, , , , ) = market.auctions(1);
        assertEq(currentBidder, bidder1);
        assertEq(currentBid, bidAmount);
        
        vm.stopPrank();
    }
    
    function testPlaceBidWithTimeExtension() public {
        uint256 duration = 1 days;
        uint256 bidAmount = 1.5 ether;
        
        // Create auction
        vm.startPrank(seller);
        nft.approve(address(market), 1);
        market.createAuction(address(nft), 1, NFT_PRICE, duration);
        vm.stopPrank();
        
        // Fast forward to near end
        vm.warp(block.timestamp + duration - 200); // 200 seconds before end
        
        // Place bid (should extend time)
        vm.startPrank(bidder1);
        market.placeBid{value: bidAmount}(1);
        
        (, , , , , , uint32 endTime, , ) = market.auctions(1);
        assertEq(endTime, block.timestamp + 300); // Extended by 5 minutes
        
        vm.stopPrank();
    }
    
    function testEndAuctionWithWinner() public {
        uint256 duration = 1 days;
        uint256 bidAmount = 1.5 ether;
        
        // Create auction
        vm.startPrank(seller);
        nft.approve(address(market), 1);
        market.createAuction(address(nft), 1, NFT_PRICE, duration);
        vm.stopPrank();
        
        // Place bid
        vm.startPrank(bidder1);
        market.placeBid{value: bidAmount}(1);
        vm.stopPrank();
        
        uint256 sellerBalanceBefore = seller.balance;
        uint256 feeRecipientBalanceBefore = feeRecipient.balance;
        
        // Fast forward past end time
        vm.warp(block.timestamp + duration + 1);
        
        // End auction
        vm.expectEmit(true, true, false, true);
        emit AuctionEnded(1, bidder1, bidAmount);
        
        market.endAuction(1);
        
        // Check NFT ownership
        assertEq(nft.ownerOf(1), bidder1);
        
        // Check auction is inactive
        (, , , , , , , , bool active) = market.auctions(1);
        assertFalse(active);
        
        // Check balances
        uint256 platformFee = (bidAmount * PLATFORM_FEE) / 10000;
        uint256 sellerAmount = bidAmount - platformFee;
        
        assertEq(seller.balance, sellerBalanceBefore + sellerAmount);
        assertEq(feeRecipient.balance, feeRecipientBalanceBefore + platformFee);
    }
    
    // ============ Offer Tests ============
    
    function testMakeOffer() public {
        uint256 offerPrice = 0.8 ether;
        uint256 expiration = block.timestamp + 1 days;
        
        vm.startPrank(buyer);
        vm.expectEmit(true, true, true, true);
        emit OfferMade(1, address(nft), 1, offerPrice);
        
        market.makeOffer{value: offerPrice}(address(nft), 1, expiration);
        
        (address nftContract, address offerBuyer, uint96 price, uint32 tokenId, uint32 offerExpiration, uint32 createdAt, bool active) = market.offers(1);
        assertEq(nftContract, address(nft));
        assertEq(offerBuyer, buyer);
        assertEq(price, offerPrice);
        assertEq(tokenId, 1);
        assertEq(offerExpiration, expiration);
        assertTrue(active);
        
        vm.stopPrank();
    }
    
    function testAcceptOffer() public {
        uint256 offerPrice = 0.8 ether;
        uint256 expiration = block.timestamp + 1 days;
        
        // Make offer
        vm.startPrank(buyer);
        market.makeOffer{value: offerPrice}(address(nft), 1, expiration);
        vm.stopPrank();
        
        uint256 sellerBalanceBefore = seller.balance;
        uint256 feeRecipientBalanceBefore = feeRecipient.balance;
        
        // Accept offer
        vm.startPrank(seller);
        nft.approve(address(market), 1);
        
        vm.expectEmit(true, true, false, true);
        emit OfferAccepted(1, buyer, offerPrice);
        
        market.acceptOffer(1);
        
        // Check NFT ownership
        assertEq(nft.ownerOf(1), buyer);
        
        // Check offer is inactive
        (, , , , , , bool active) = market.offers(1);
        assertFalse(active);
        
        // Check balances
        uint256 platformFee = (offerPrice * PLATFORM_FEE) / 10000;
        uint256 sellerAmount = offerPrice - platformFee;
        
        assertEq(seller.balance, sellerBalanceBefore + sellerAmount);
        assertEq(feeRecipient.balance, feeRecipientBalanceBefore + platformFee);
        
        vm.stopPrank();
    }
    
    // ============ Admin Tests ============
    
    function testSetPlatformFee() public {
        uint256 newFee = 500; // 5%
        
        vm.expectEmit(false, false, false, true);
        emit PlatformFeeUpdated(newFee);
        
        market.setPlatformFee(newFee);
        
        assertEq(market.platformFeePercentage(), newFee);
    }
    
    function testSetPlatformFeeFailsWhenTooHigh() public {
        vm.expectRevert(NFTMarketOptimized.PlatformFeeTooHigh.selector);
        market.setPlatformFee(1001); // > 10%
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
    
    function testPauseAndUnpause() public {
        // Pause
        market.pause();
        assertTrue(market.paused());
        
        // Try to list while paused (should fail)
        vm.startPrank(seller);
        nft.approve(address(market), 1);
        vm.expectRevert();
        market.listNFT(address(nft), 1, NFT_PRICE);
        vm.stopPrank();
        
        // Unpause
        market.unpause();
        assertFalse(market.paused());
        
        // Should work now
        vm.startPrank(seller);
        market.listNFT(address(nft), 1, NFT_PRICE);
        vm.stopPrank();
    }
    
    // ============ Query Tests ============
    
    function testGetActiveListings() public {
        // Create multiple listings
        vm.startPrank(seller);
        nft.approve(address(market), 1);
        nft.approve(address(market), 2);
        nft.approve(address(market), 3);
        
        market.listNFT(address(nft), 1, NFT_PRICE);
        market.listNFT(address(nft), 2, NFT_PRICE);
        market.listNFT(address(nft), 3, NFT_PRICE);
        
        // Cancel one listing
        market.cancelListing(2);
        vm.stopPrank();
        
        // Get active listings
        (NFTMarketOptimized.Listing[] memory listings, uint256 total) = market.getActiveListings(0, 10);
        
        assertEq(total, 2);
        assertEq(listings.length, 2);
        assertEq(listings[0].tokenId, 1);
        assertEq(listings[1].tokenId, 3);
    }
    
    // ============ Edge Cases ============
    
    function testReceiveEther() public {
        uint256 amount = 1 ether;
        
        (bool success, ) = address(market).call{value: amount}("");
        assertTrue(success);
        assertEq(address(market).balance, amount);
    }
    
    function testEmergencyWithdraw() public {
        uint256 amount = 1 ether;
        
        // Send some ETH to contract
        (bool success, ) = address(market).call{value: amount}("");
        assertTrue(success);
        
        uint256 ownerBalanceBefore = owner.balance;
        
        // Emergency withdraw
        market.emergencyWithdraw();
        
        assertEq(owner.balance, ownerBalanceBefore + amount);
        assertEq(address(market).balance, 0);
    }
    
    function testOnERC721Received() public {
        bytes4 selector = market.onERC721Received(address(0), address(0), 0, "");
        assertEq(uint32(selector), uint32(0x150b7a02)); // IERC721Receiver.onERC721Received.selector
    }
}