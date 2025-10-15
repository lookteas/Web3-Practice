// SPDX-License-Identifier: MIT
pragma solidity ^0.8.25;

import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721Receiver.sol";
import "@openzeppelin/contracts/utils/ReentrancyGuard.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Pausable.sol";

/**
 * @title NFTMarketOptimized
 * @dev Gas优化版本的NFT市场合约，支持上架、购买、拍卖等功能
 */
contract NFTMarketOptimized is IERC721Receiver, ReentrancyGuard, Ownable, Pausable {
    
    // 上架ID计数器
    uint256 private _listingIdCounter = 1;
    
    // 平台费用百分比（基数为10000）
    uint256 public platformFeePercentage = 250; // 2.5%
    
    // 平台费用接收地址
    address public feeRecipient;
    
    // 最小上架价格
    uint256 public minimumPrice = 0.001 ether;
    
    // 优化后的上架结构体 - 打包存储
    struct Listing {
        address nftContract;    // 20 bytes
        address seller;         // 20 bytes  
        uint96 price;          // 12 bytes - 足够存储价格 (最大约79M ETH)
        uint32 tokenId;        // 4 bytes - 支持到42亿个token
        uint32 createdAt;      // 4 bytes - 时间戳压缩
        bool active;           // 1 byte
        // 总计: 61 bytes，优化为2个存储槽
    }
    
    // 优化后的拍卖结构体 - 打包存储
    struct Auction {
        address nftContract;    // 20 bytes
        address seller;         // 20 bytes
        address currentBidder;  // 20 bytes
        uint96 startingPrice;   // 12 bytes
        uint96 currentBid;      // 12 bytes
        uint32 tokenId;         // 4 bytes
        uint32 endTime;         // 4 bytes
        uint32 createdAt;       // 4 bytes
        bool active;            // 1 byte
        // 总计: 97 bytes，优化为4个存储槽
    }
    
    // 优化后的报价结构体 - 打包存储
    struct Offer {
        address nftContract;    // 20 bytes
        address buyer;          // 20 bytes
        uint96 price;          // 12 bytes
        uint32 tokenId;        // 4 bytes
        uint32 expiration;     // 4 bytes
        uint32 createdAt;      // 4 bytes
        bool active;           // 1 byte
        // 总计: 57 bytes，优化为2个存储槽
    }
    
    // 存储映射
    mapping(uint256 => Listing) public listings;
    mapping(address => mapping(uint256 => uint256)) public nftToListingId;
    mapping(uint256 => Auction) public auctions;
    mapping(address => mapping(uint256 => uint256)) public nftToAuctionId;
    mapping(uint256 => Offer) public offers;
    
    // 计数器
    uint256 private _auctionIdCounter = 1;
    uint256 private _offerIdCounter = 1;
    
    // 事件 - 优化参数数量
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
    
    // 自定义错误 - 节省gas
    error InvalidAddress();
    error PriceBelowMinimum();
    error NFTAlreadyListed();
    error NotNFTOwner();
    error MarketNotApproved();
    error ListingNotActive();
    error InsufficientPayment();
    error CannotBuyOwnNFT();
    error NotAuthorized();
    error SamePrice();
    error DurationTooShort();
    error DurationTooLong();
    error NFTAlreadyInAuction();
    error AuctionNotActive();
    error AuctionAlreadyEnded();
    error CannotBidOnOwnAuction();
    error BidBelowStartingPrice();
    error BidNotHigherThanCurrent();
    error AuctionNotEnded();
    error OfferNotActive();
    error OfferExpired();
    error CannotOfferOnOwnNFT();
    error ExpirationTooFar();
    error PlatformFeeTooHigh();
    error NoFundsToWithdraw();
    
    constructor(address _feeRecipient) Ownable(msg.sender) {
        if (_feeRecipient == address(0)) revert InvalidAddress();
        feeRecipient = _feeRecipient;
    }
    
    /**
     * @dev 上架NFT - 优化版本
     */
    function listNFT(
        address nftContract,
        uint256 tokenId,
        uint256 price
    ) external nonReentrant whenNotPaused {
        if (nftContract == address(0)) revert InvalidAddress();
        if (price < minimumPrice) revert PriceBelowMinimum();
        if (nftToListingId[nftContract][tokenId] != 0) revert NFTAlreadyListed();
        
        IERC721 nft = IERC721(nftContract);
        if (nft.ownerOf(tokenId) != msg.sender) revert NotNFTOwner();
        if (nft.getApproved(tokenId) != address(this) && !nft.isApprovedForAll(msg.sender, address(this))) {
            revert MarketNotApproved();
        }
        
        uint256 listingId = _listingIdCounter++;
        
        // 优化：直接赋值而不是逐个字段
        listings[listingId] = Listing({
            nftContract: nftContract,
            seller: msg.sender,
            price: uint96(price),
            tokenId: uint32(tokenId),
            createdAt: uint32(block.timestamp),
            active: true
        });
        
        nftToListingId[nftContract][tokenId] = listingId;
        
        emit NFTListed(listingId, nftContract, tokenId, price);
    }
    
    /**
     * @dev 购买NFT - 优化版本
     */
    function buyNFT(uint256 listingId) external payable nonReentrant whenNotPaused {
        Listing storage listing = listings[listingId];
        if (!listing.active) revert ListingNotActive();
        if (msg.value < listing.price) revert InsufficientPayment();
        if (msg.sender == listing.seller) revert CannotBuyOwnNFT();
        
        IERC721 nft = IERC721(listing.nftContract);
        if (nft.ownerOf(listing.tokenId) != listing.seller) revert NotNFTOwner();
        
        // 优化：先更新状态再进行外部调用
        listing.active = false;
        nftToListingId[listing.nftContract][listing.tokenId] = 0;
        
        uint256 price = listing.price;
        uint256 platformFee = (price * platformFeePercentage) / 10000;
        uint256 sellerAmount;
        
        // 优化：使用unchecked减少gas
        unchecked {
            sellerAmount = price - platformFee;
        }
        
        // 转移NFT
        nft.safeTransferFrom(listing.seller, msg.sender, listing.tokenId);
        
        // 转移资金 - 优化：合并转账
        if (platformFee > 0) {
            payable(feeRecipient).transfer(platformFee);
        }
        payable(listing.seller).transfer(sellerAmount);
        
        // 退还多余的ETH
        if (msg.value > price) {
            payable(msg.sender).transfer(msg.value - price);
        }
        
        emit NFTSold(listingId, msg.sender, price);
    }
    
    /**
     * @dev 取消上架 - 优化版本
     */
    function cancelListing(uint256 listingId) external nonReentrant {
        Listing storage listing = listings[listingId];
        if (!listing.active) revert ListingNotActive();
        if (msg.sender != listing.seller && msg.sender != owner()) revert NotAuthorized();
        
        listing.active = false;
        nftToListingId[listing.nftContract][listing.tokenId] = 0;
        
        emit ListingCancelled(listingId);
    }
    
    /**
     * @dev 更新上架价格 - 优化版本
     */
    function updateListingPrice(uint256 listingId, uint256 newPrice) external {
        Listing storage listing = listings[listingId];
        if (!listing.active) revert ListingNotActive();
        if (msg.sender != listing.seller) revert NotAuthorized();
        if (newPrice < minimumPrice) revert PriceBelowMinimum();
        if (newPrice == listing.price) revert SamePrice();
        
        listing.price = uint96(newPrice);
        
        emit ListingPriceUpdated(listingId, newPrice);
    }
    
    /**
     * @dev 创建拍卖 - 优化版本
     */
    function createAuction(
        address nftContract,
        uint256 tokenId,
        uint256 startingPrice,
        uint256 duration
    ) external nonReentrant whenNotPaused {
        if (nftContract == address(0)) revert InvalidAddress();
        if (startingPrice < minimumPrice) revert PriceBelowMinimum();
        if (duration < 3600) revert DurationTooShort();
        if (duration > 30 days) revert DurationTooLong();
        if (nftToAuctionId[nftContract][tokenId] != 0) revert NFTAlreadyInAuction();
        
        IERC721 nft = IERC721(nftContract);
        if (nft.ownerOf(tokenId) != msg.sender) revert NotNFTOwner();
        if (nft.getApproved(tokenId) != address(this) && !nft.isApprovedForAll(msg.sender, address(this))) {
            revert MarketNotApproved();
        }
        
        uint256 auctionId = _auctionIdCounter++;
        uint256 endTime = block.timestamp + duration;
        
        auctions[auctionId] = Auction({
            nftContract: nftContract,
            seller: msg.sender,
            currentBidder: address(0),
            startingPrice: uint96(startingPrice),
            currentBid: 0,
            tokenId: uint32(tokenId),
            endTime: uint32(endTime),
            createdAt: uint32(block.timestamp),
            active: true
        });
        
        nftToAuctionId[nftContract][tokenId] = auctionId;
        
        emit AuctionCreated(auctionId, nftContract, tokenId, endTime);
    }
    
    /**
     * @dev 出价 - 优化版本
     */
    function placeBid(uint256 auctionId) external payable nonReentrant whenNotPaused {
        Auction storage auction = auctions[auctionId];
        if (!auction.active) revert AuctionNotActive(); 
        if (block.timestamp >= auction.endTime) revert AuctionAlreadyEnded();
        if (msg.sender == auction.seller) revert CannotBidOnOwnAuction();
        if (msg.value < auction.startingPrice) revert BidBelowStartingPrice();
        if (msg.value <= auction.currentBid) revert BidNotHigherThanCurrent();
        
        // 退还前一个出价者的资金
        if (auction.currentBidder != address(0)) {
            payable(auction.currentBidder).transfer(auction.currentBid);
        }
        
        auction.currentBid = uint96(msg.value);
        auction.currentBidder = msg.sender;
        
        // 如果在最后5分钟内出价，延长5分钟
        if (auction.endTime - block.timestamp < 300) {
            auction.endTime = uint32(block.timestamp + 300);
        }
        
        emit BidPlaced(auctionId, msg.sender, msg.value);
    }
    
    /**
     * @dev 结束拍卖 - 优化版本
     */
    function endAuction(uint256 auctionId) external nonReentrant {
        Auction storage auction = auctions[auctionId];
        if (!auction.active) revert AuctionNotActive();
        if (block.timestamp < auction.endTime) revert AuctionNotEnded();
        
        auction.active = false;
        nftToAuctionId[auction.nftContract][auction.tokenId] = 0;
        
        IERC721 nft = IERC721(auction.nftContract);
        
        if (auction.currentBidder != address(0)) {
            uint256 currentBid = auction.currentBid;
            uint256 platformFee = (currentBid * platformFeePercentage) / 10000;
            uint256 sellerAmount;
            
            unchecked {
                sellerAmount = currentBid - platformFee;
            }
            
            // 转移NFT
            nft.safeTransferFrom(auction.seller, auction.currentBidder, auction.tokenId);
            
            // 转移资金
            if (platformFee > 0) {
                payable(feeRecipient).transfer(platformFee);
            }
            payable(auction.seller).transfer(sellerAmount);
            
            emit AuctionEnded(auctionId, auction.currentBidder, currentBid);
        } else {
            emit AuctionEnded(auctionId, address(0), 0);
        }
    }
    
    /**
     * @dev 提出报价 - 优化版本
     */
    function makeOffer(
        address nftContract,
        uint256 tokenId,
        uint256 expiration
    ) external payable nonReentrant whenNotPaused {
        if (nftContract == address(0)) revert InvalidAddress();
        if (msg.value < minimumPrice) revert PriceBelowMinimum();
        if (expiration <= block.timestamp) revert OfferExpired();
        if (expiration > block.timestamp + 30 days) revert ExpirationTooFar();
        
        IERC721 nft = IERC721(nftContract);
        if (nft.ownerOf(tokenId) == msg.sender) revert CannotOfferOnOwnNFT();
        
        uint256 offerId = _offerIdCounter++;
        
        offers[offerId] = Offer({
            nftContract: nftContract,
            buyer: msg.sender,
            price: uint96(msg.value),
            tokenId: uint32(tokenId),
            expiration: uint32(expiration),
            createdAt: uint32(block.timestamp),
            active: true
        });
        
        emit OfferMade(offerId, nftContract, tokenId, msg.value);
    }
    
    /**
     * @dev 接受报价 - 优化版本
     */
    function acceptOffer(uint256 offerId) external nonReentrant {
        Offer storage offer = offers[offerId];
        if (!offer.active) revert OfferNotActive();
        if (block.timestamp > offer.expiration) revert OfferExpired();
        
        IERC721 nft = IERC721(offer.nftContract);
        if (nft.ownerOf(offer.tokenId) != msg.sender) revert NotNFTOwner();
        if (nft.getApproved(offer.tokenId) != address(this) && !nft.isApprovedForAll(msg.sender, address(this))) {
            revert MarketNotApproved();
        }
        
        offer.active = false;
        
        uint256 price = offer.price;
        uint256 platformFee = (price * platformFeePercentage) / 10000;
        uint256 sellerAmount;
        
        unchecked {
            sellerAmount = price - platformFee;
        }
        
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
        
        emit OfferAccepted(offerId, offer.buyer, price);
    }
    
    /**
     * @dev 取消报价 - 优化版本
     */
    function cancelOffer(uint256 offerId) external nonReentrant {
        Offer storage offer = offers[offerId];
        if (!offer.active) revert OfferNotActive();
        if (msg.sender != offer.buyer) revert NotAuthorized();
        
        offer.active = false;
        payable(offer.buyer).transfer(offer.price);
    }
    
    /**
     * @dev 获取活跃上架列表 - 优化版本
     */
    function getActiveListings(uint256 offset, uint256 limit)
        external
        view
        returns (Listing[] memory activeListings, uint256 total)
    {
        uint256 totalListings = _listingIdCounter - 1;
        if (offset >= totalListings) {
            return (new Listing[](0), 0);
        }
        
        uint256 end = offset + limit;
        if (end > totalListings) {
            end = totalListings;
        }
        
        // 预先计算活跃数量
        uint256 activeCount = 0;
        for (uint256 i = offset + 1; i <= end; i++) {
            if (listings[i].active) {
                activeCount++;
            }
        }
        
        activeListings = new Listing[](activeCount);
        uint256 index = 0;
        
        for (uint256 i = offset + 1; i <= end && index < activeCount; i++) {
            if (listings[i].active) {
                activeListings[index] = listings[i];
                index++;
            }
        }
        
        return (activeListings, activeCount);
    }
    
    /**
     * @dev 设置平台费用（仅限所有者）
     */
    function setPlatformFee(uint256 _platformFeePercentage) external onlyOwner {
        if (_platformFeePercentage > 1000) revert PlatformFeeTooHigh();
        platformFeePercentage = _platformFeePercentage;
        emit PlatformFeeUpdated(_platformFeePercentage);
    }
    
    /**
     * @dev 设置费用接收地址（仅限所有者）
     */
    function setFeeRecipient(address _feeRecipient) external onlyOwner {
        if (_feeRecipient == address(0)) revert InvalidAddress();
        feeRecipient = _feeRecipient;
    }
    
    /**
     * @dev 设置最小价格（仅限所有者）
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
        if (balance == 0) revert NoFundsToWithdraw();
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