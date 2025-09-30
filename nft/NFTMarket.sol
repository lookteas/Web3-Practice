// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721Receiver.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/security/Pausable.sol";

/**
 * @title NFTMarket
 * @dev NFT市场合约，支持上架、购买、拍卖等功能
 */
contract NFTMarket is IERC721Receiver, ReentrancyGuard, Ownable, Pausable {
    using Counters for Counters.Counter;
    
    // 上架ID计数器
    Counters.Counter private _listingIdCounter;
    
    // 平台费用百分比（基数为10000）
    uint256 public platformFeePercentage = 250; // 2.5%
    
    // 平台费用接收地址
    address public feeRecipient;
    
    // 最小上架价格
    uint256 public minimumPrice = 0.001 ether;
    
    // 上架结构体
    struct Listing {
        uint256 listingId;
        address nftContract;
        uint256 tokenId;
        address seller;
        uint256 price;
        bool active;
        uint256 createdAt;
        uint256 updatedAt;
    }
    
    // 拍卖结构体
    struct Auction {
        uint256 auctionId;
        address nftContract;
        uint256 tokenId;
        address seller;
        uint256 startingPrice;
        uint256 currentBid;
        address currentBidder;
        uint256 endTime;
        bool active;
        uint256 createdAt;
    }
    
    // 出价结构体
    struct Offer {
        uint256 offerId;
        address nftContract;
        uint256 tokenId;
        address buyer;
        uint256 price;
        uint256 expiration;
        bool active;
        uint256 createdAt;
    }
    
    // 存储映射
    mapping(uint256 => Listing) public listings;
    mapping(address => mapping(uint256 => uint256)) public nftToListingId; // nftContract => tokenId => listingId
    mapping(uint256 => Auction) public auctions;
    mapping(address => mapping(uint256 => uint256)) public nftToAuctionId;
    mapping(uint256 => Offer) public offers;
    mapping(address => mapping(uint256 => uint256[])) public nftToOfferIds;
    
    // 用户相关映射
    mapping(address => uint256[]) public userListings;
    mapping(address => uint256[]) public userAuctions;
    mapping(address => uint256[]) public userOffers;
    
    // 计数器
    Counters.Counter private _auctionIdCounter;
    Counters.Counter private _offerIdCounter;
    
    // 事件
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
    
    event ListingPriceUpdated(
        uint256 indexed listingId,
        uint256 oldPrice,
        uint256 newPrice
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
    
    event AuctionEnded(
        uint256 indexed auctionId,
        address indexed winner,
        uint256 winningBid
    );
    
    event OfferMade(
        uint256 indexed offerId,
        address indexed nftContract,
        uint256 indexed tokenId,
        address buyer,
        uint256 price,
        uint256 expiration
    );
    
    event OfferAccepted(
        uint256 indexed offerId,
        address indexed nftContract,
        uint256 indexed tokenId,
        address seller,
        address buyer,
        uint256 price
    );
    
    event PlatformFeeUpdated(uint256 oldFee, uint256 newFee);
    
    constructor(address _feeRecipient) {
        require(_feeRecipient != address(0), "Fee recipient cannot be zero address");
        feeRecipient = _feeRecipient;
        
        // 从ID 1开始
        _listingIdCounter.increment();
        _auctionIdCounter.increment();
        _offerIdCounter.increment();
    }
    
    /**
     * @dev 上架NFT
     * @param nftContract NFT合约地址
     * @param tokenId 代币ID
     * @param price 价格
     */
    function listNFT(
        address nftContract,
        uint256 tokenId,
        uint256 price
    ) external nonReentrant whenNotPaused {
        require(nftContract != address(0), "NFT contract cannot be zero address");
        require(price >= minimumPrice, "Price below minimum");
        require(nftToListingId[nftContract][tokenId] == 0, "NFT already listed");
        
        IERC721 nft = IERC721(nftContract);
        require(nft.ownerOf(tokenId) == msg.sender, "Not the owner of this NFT");
        require(
            nft.getApproved(tokenId) == address(this) || 
            nft.isApprovedForAll(msg.sender, address(this)),
            "Market not approved to transfer NFT"
        );
        
        uint256 listingId = _listingIdCounter.current();
        _listingIdCounter.increment();
        
        listings[listingId] = Listing({
            listingId: listingId,
            nftContract: nftContract,
            tokenId: tokenId,
            seller: msg.sender,
            price: price,
            active: true,
            createdAt: block.timestamp,
            updatedAt: block.timestamp
        });
        
        nftToListingId[nftContract][tokenId] = listingId;
        userListings[msg.sender].push(listingId);
        
        emit NFTListed(listingId, nftContract, tokenId, msg.sender, price);
    }
    
    /**
     * @dev 购买NFT
     * @param listingId 上架ID
     */
    function buyNFT(uint256 listingId) external payable nonReentrant whenNotPaused {
        Listing storage listing = listings[listingId];
        require(listing.active, "Listing not active");
        require(msg.value >= listing.price, "Insufficient payment");
        require(msg.sender != listing.seller, "Cannot buy your own NFT");
        
        IERC721 nft = IERC721(listing.nftContract);
        require(nft.ownerOf(listing.tokenId) == listing.seller, "Seller no longer owns NFT");
        
        // 标记为非活跃
        listing.active = false;
        nftToListingId[listing.nftContract][listing.tokenId] = 0;
        
        // 计算费用
        uint256 platformFee = (listing.price * platformFeePercentage) / 10000;
        uint256 sellerAmount = listing.price - platformFee;
        
        // 转移NFT
        nft.safeTransferFrom(listing.seller, msg.sender, listing.tokenId);
        
        // 转移资金
        if (platformFee > 0) {
            payable(feeRecipient).transfer(platformFee);
        }
        payable(listing.seller).transfer(sellerAmount);
        
        // 退还多余的ETH
        if (msg.value > listing.price) {
            payable(msg.sender).transfer(msg.value - listing.price);
        }
        
        emit NFTSold(
            listingId,
            listing.nftContract,
            listing.tokenId,
            listing.seller,
            msg.sender,
            listing.price
        );
    }
    
    /**
     * @dev 取消上架
     * @param listingId 上架ID
     */
    function cancelListing(uint256 listingId) external nonReentrant {
        Listing storage listing = listings[listingId];
        require(listing.active, "Listing not active");
        require(
            msg.sender == listing.seller || msg.sender == owner(),
            "Not authorized to cancel"
        );
        
        listing.active = false;
        nftToListingId[listing.nftContract][listing.tokenId] = 0;
        
        emit ListingCancelled(
            listingId,
            listing.nftContract,
            listing.tokenId,
            listing.seller
        );
    }
    
    /**
     * @dev 更新上架价格
     * @param listingId 上架ID
     * @param newPrice 新价格
     */
    function updateListingPrice(uint256 listingId, uint256 newPrice) external {
        Listing storage listing = listings[listingId];
        require(listing.active, "Listing not active");
        require(msg.sender == listing.seller, "Not the seller");
        require(newPrice >= minimumPrice, "Price below minimum");
        require(newPrice != listing.price, "Same price");
        
        uint256 oldPrice = listing.price;
        listing.price = newPrice;
        listing.updatedAt = block.timestamp;
        
        emit ListingPriceUpdated(listingId, oldPrice, newPrice);
    }
    
    /**
     * @dev 创建拍卖
     * @param nftContract NFT合约地址
     * @param tokenId 代币ID
     * @param startingPrice 起拍价
     * @param duration 拍卖持续时间（秒）
     */
    function createAuction(
        address nftContract,
        uint256 tokenId,
        uint256 startingPrice,
        uint256 duration
    ) external nonReentrant whenNotPaused {
        require(nftContract != address(0), "NFT contract cannot be zero address");
        require(startingPrice >= minimumPrice, "Starting price below minimum");
        require(duration >= 3600, "Duration must be at least 1 hour");
        require(duration <= 30 days, "Duration cannot exceed 30 days");
        require(nftToAuctionId[nftContract][tokenId] == 0, "NFT already in auction");
        
        IERC721 nft = IERC721(nftContract);
        require(nft.ownerOf(tokenId) == msg.sender, "Not the owner of this NFT");
        require(
            nft.getApproved(tokenId) == address(this) || 
            nft.isApprovedForAll(msg.sender, address(this)),
            "Market not approved to transfer NFT"
        );
        
        uint256 auctionId = _auctionIdCounter.current();
        _auctionIdCounter.increment();
        
        auctions[auctionId] = Auction({
            auctionId: auctionId,
            nftContract: nftContract,
            tokenId: tokenId,
            seller: msg.sender,
            startingPrice: startingPrice,
            currentBid: 0,
            currentBidder: address(0),
            endTime: block.timestamp + duration,
            active: true,
            createdAt: block.timestamp
        });
        
        nftToAuctionId[nftContract][tokenId] = auctionId;
        userAuctions[msg.sender].push(auctionId);
        
        emit AuctionCreated(
            auctionId,
            nftContract,
            tokenId,
            msg.sender,
            startingPrice,
            block.timestamp + duration
        );
    }
    
    /**
     * @dev 出价
     * @param auctionId 拍卖ID
     */
    function placeBid(uint256 auctionId) external payable nonReentrant whenNotPaused {
        Auction storage auction = auctions[auctionId];
        require(auction.active, "Auction not active");
        require(block.timestamp < auction.endTime, "Auction ended");
        require(msg.sender != auction.seller, "Cannot bid on your own auction");
        require(
            msg.value >= auction.startingPrice,
            "Bid below starting price"
        );
        require(
            msg.value > auction.currentBid,
            "Bid must be higher than current bid"
        );
        
        // 退还前一个出价者的资金
        if (auction.currentBidder != address(0)) {
            payable(auction.currentBidder).transfer(auction.currentBid);
        }
        
        auction.currentBid = msg.value;
        auction.currentBidder = msg.sender;
        
        // 如果在最后5分钟内出价，延长5分钟
        if (auction.endTime - block.timestamp < 300) {
            auction.endTime = block.timestamp + 300;
        }
        
        emit BidPlaced(auctionId, msg.sender, msg.value);
    }
    
    /**
     * @dev 结束拍卖
     * @param auctionId 拍卖ID
     */
    function endAuction(uint256 auctionId) external nonReentrant {
        Auction storage auction = auctions[auctionId];
        require(auction.active, "Auction not active");
        require(block.timestamp >= auction.endTime, "Auction not ended");
        
        auction.active = false;
        nftToAuctionId[auction.nftContract][auction.tokenId] = 0;
        
        IERC721 nft = IERC721(auction.nftContract);
        
        if (auction.currentBidder != address(0)) {
            // 有出价者，完成交易
            uint256 platformFee = (auction.currentBid * platformFeePercentage) / 10000;
            uint256 sellerAmount = auction.currentBid - platformFee;
            
            // 转移NFT
            nft.safeTransferFrom(auction.seller, auction.currentBidder, auction.tokenId);
            
            // 转移资金
            if (platformFee > 0) {
                payable(feeRecipient).transfer(platformFee);
            }
            payable(auction.seller).transfer(sellerAmount);
            
            emit AuctionEnded(auctionId, auction.currentBidder, auction.currentBid);
        } else {
            // 无出价者，拍卖失败
            emit AuctionEnded(auctionId, address(0), 0);
        }
    }
    
    /**
     * @dev 提出报价
     * @param nftContract NFT合约地址
     * @param tokenId 代币ID
     * @param expiration 报价过期时间
     */
    function makeOffer(
        address nftContract,
        uint256 tokenId,
        uint256 expiration
    ) external payable nonReentrant whenNotPaused {
        require(nftContract != address(0), "NFT contract cannot be zero address");
        require(msg.value >= minimumPrice, "Offer below minimum");
        require(expiration > block.timestamp, "Expiration must be in the future");
        require(expiration <= block.timestamp + 30 days, "Expiration too far in future");
        
        IERC721 nft = IERC721(nftContract);
        require(nft.ownerOf(tokenId) != msg.sender, "Cannot make offer on your own NFT");
        
        uint256 offerId = _offerIdCounter.current();
        _offerIdCounter.increment();
        
        offers[offerId] = Offer({
            offerId: offerId,
            nftContract: nftContract,
            tokenId: tokenId,
            buyer: msg.sender,
            price: msg.value,
            expiration: expiration,
            active: true,
            createdAt: block.timestamp
        });
        
        nftToOfferIds[nftContract][tokenId].push(offerId);
        userOffers[msg.sender].push(offerId);
        
        emit OfferMade(offerId, nftContract, tokenId, msg.sender, msg.value, expiration);
    }
    
    /**
     * @dev 接受报价
     * @param offerId 报价ID
     */
    function acceptOffer(uint256 offerId) external nonReentrant {
        Offer storage offer = offers[offerId];
        require(offer.active, "Offer not active");
        require(block.timestamp <= offer.expiration, "Offer expired");
        
        IERC721 nft = IERC721(offer.nftContract);
        require(nft.ownerOf(offer.tokenId) == msg.sender, "Not the owner of this NFT");
        require(
            nft.getApproved(offer.tokenId) == address(this) || 
            nft.isApprovedForAll(msg.sender, address(this)),
            "Market not approved to transfer NFT"
        );
        
        offer.active = false;
        
        // 计算费用
        uint256 platformFee = (offer.price * platformFeePercentage) / 10000;
        uint256 sellerAmount = offer.price - platformFee;
        
        // 转移NFT
        nft.safeTransferFrom(msg.sender, offer.buyer, offer.tokenId);
        
        // 转移资金
        if (platformFee > 0) {
            payable(feeRecipient).transfer(platformFee);
        }
        payable(msg.sender).transfer(sellerAmount);
        
        // 取消该NFT的其他活跃上架
        uint256 listingId = nftToListingId[offer.nftContract][offer.tokenId];
        if (listingId != 0) {
            listings[listingId].active = false;
            nftToListingId[offer.nftContract][offer.tokenId] = 0;
        }
        
        emit OfferAccepted(
            offerId,
            offer.nftContract,
            offer.tokenId,
            msg.sender,
            offer.buyer,
            offer.price
        );
    }
    
    /**
     * @dev 取消报价
     * @param offerId 报价ID
     */
    function cancelOffer(uint256 offerId) external nonReentrant {
        Offer storage offer = offers[offerId];
        require(offer.active, "Offer not active");
        require(msg.sender == offer.buyer, "Not the buyer");
        
        offer.active = false;
        
        // 退还资金
        payable(offer.buyer).transfer(offer.price);
    }
    
    /**
     * @dev 获取活跃上架列表
     * @param offset 偏移量
     * @param limit 限制数量
     */
    function getActiveListings(uint256 offset, uint256 limit)
        external
        view
        returns (Listing[] memory)
    {
        uint256 totalListings = _listingIdCounter.current() - 1;
        if (offset >= totalListings) {
            return new Listing[](0);
        }
        
        uint256 end = offset + limit;
        if (end > totalListings) {
            end = totalListings;
        }
        
        uint256 activeCount = 0;
        for (uint256 i = offset + 1; i <= end; i++) {
            if (listings[i].active) {
                activeCount++;
            }
        }
        
        Listing[] memory activeListings = new Listing[](activeCount);
        uint256 index = 0;
        
        for (uint256 i = offset + 1; i <= end && index < activeCount; i++) {
            if (listings[i].active) {
                activeListings[index] = listings[i];
                index++;
            }
        }
        
        return activeListings;
    }
    
    /**
     * @dev 获取用户的上架
     * @param user 用户地址
     */
    function getUserListings(address user) external view returns (Listing[] memory) {
        uint256[] memory listingIds = userListings[user];
        Listing[] memory userListingArray = new Listing[](listingIds.length);
        
        for (uint256 i = 0; i < listingIds.length; i++) {
            userListingArray[i] = listings[listingIds[i]];
        }
        
        return userListingArray;
    }
    
    /**
     * @dev 设置平台费用（仅限所有者）
     * @param _platformFeePercentage 新的平台费用百分比
     */
    function setPlatformFee(uint256 _platformFeePercentage) external onlyOwner {
        require(_platformFeePercentage <= 1000, "Platform fee cannot exceed 10%");
        
        uint256 oldFee = platformFeePercentage;
        platformFeePercentage = _platformFeePercentage;
        
        emit PlatformFeeUpdated(oldFee, _platformFeePercentage);
    }
    
    /**
     * @dev 设置费用接收地址（仅限所有者）
     * @param _feeRecipient 新的费用接收地址
     */
    function setFeeRecipient(address _feeRecipient) external onlyOwner {
        require(_feeRecipient != address(0), "Fee recipient cannot be zero address");
        feeRecipient = _feeRecipient;
    }
    
    /**
     * @dev 设置最小价格（仅限所有者）
     * @param _minimumPrice 新的最小价格
     */
    function setMinimumPrice(uint256 _minimumPrice) external onlyOwner {
        minimumPrice = _minimumPrice;
    }
    
    /**
     * @dev 暂停合约（仅限所有者）
     */
    function pause() external onlyOwner {
        _pause();
    }
    
    /**
     * @dev 恢复合约（仅限所有者）
     */
    function unpause() external onlyOwner {
        _unpause();
    }
    
    /**
     * @dev 紧急提取（仅限所有者）
     */
    function emergencyWithdraw() external onlyOwner {
        uint256 balance = address(this).balance;
        require(balance > 0, "No funds to withdraw");
        
        payable(owner()).transfer(balance);
    }
    
    /**
     * @dev 实现IERC721Receiver接口
     */
    function onERC721Received(
        address,
        address,
        uint256,
        bytes calldata
    ) external pure override returns (bytes4) {
        return IERC721Receiver.onERC721Received.selector;
    }
    
    /**
     * @dev 接收ETH
     */
    receive() external payable {}
    
    /**
     * @dev 回退函数
     */
    fallback() external payable {}
}