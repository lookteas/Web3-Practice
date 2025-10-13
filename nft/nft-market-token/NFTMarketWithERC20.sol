// SPDX-License-Identifier: MIT
pragma solidity ^0.8.25;

import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721Receiver.sol";
import "@openzeppelin/contracts/utils/ReentrancyGuard.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Pausable.sol";
import "./ITokenReceiver.sol";
import "./ExpendERC20.sol";

/**
 * @title NFTMarketWithERC20
 * @dev NFT市场合约，支持使用ERC20代币购买NFT
 * 实现ITokenReceiver接口，支持通过transferWithCallback自动购买NFT
 */
contract NFTMarketWithERC20 is IERC721Receiver, ITokenReceiver, ReentrancyGuard, Ownable, Pausable {
    
    // 上架ID计数器
    uint256 private _listingIdCounter;
    
    // 支持的ERC20代币合约
    ExpendERC20 public paymentToken;
    
    // 平台费用百分比（基数为10000）
    uint256 public platformFeePercentage = 250; // 2.5%
    
    // 平台费用接收地址
    address public feeRecipient;
    
    // 最小上架价格（以ERC20代币为单位）
    uint256 public minimumPrice = 1 * 10**18; // 1 token
    
    // 上架结构体
    struct Listing {
        uint256 listingId;
        address nftContract;
        uint256 tokenId;
        address seller;
        uint256 price; // 以ERC20代币为单位
        bool active;
        uint256 createdAt;
        uint256 updatedAt;
    }
    
    // 存储所有上架信息
    mapping(uint256 => Listing) public listings;
    
    // NFT合约地址 => tokenId => listingId 的映射
    mapping(address => mapping(uint256 => uint256)) public nftToListingId;
    
    // 用户的上架列表
    mapping(address => uint256[]) public userListings;
    
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
    
    event NFTDelisted(
        uint256 indexed listingId,
        address indexed nftContract,
        uint256 indexed tokenId,
        address seller
    );
    
    event PriceUpdated(
        uint256 indexed listingId,
        uint256 oldPrice,
        uint256 newPrice
    );
    
    event PlatformFeeUpdated(uint256 oldFee, uint256 newFee);
    
    constructor(
        address _paymentToken,
        address _feeRecipient
    ) Ownable(msg.sender) {
        require(_paymentToken != address(0), "Payment token cannot be zero address");
        require(_feeRecipient != address(0), "Fee recipient cannot be zero address");
        
        paymentToken = ExpendERC20(_paymentToken);
        feeRecipient = _feeRecipient;
        
        // 从ID 1开始
        _listingIdCounter = 1;
    }
    
    /**
     * @dev 上架NFT
     * @param nftContract NFT合约地址
     * @param tokenId 代币ID
     * @param price 价格（以ERC20代币为单位）
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
        
        uint256 listingId = _listingIdCounter;
        _listingIdCounter++;
        
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
     * @dev 传统购买NFT方式（需要先授权）
     * @param listingId 上架ID
     */
    function buyNFT(uint256 listingId) external nonReentrant whenNotPaused {
        Listing storage listing = listings[listingId];
        require(listing.active, "Listing not active");
        require(msg.sender != listing.seller, "Cannot buy your own NFT");
        
        IERC721 nft = IERC721(listing.nftContract);
        require(nft.ownerOf(listing.tokenId) == listing.seller, "Seller no longer owns NFT");
        
        // 检查买家是否有足够的代币余额
        require(paymentToken.balanceOf(msg.sender) >= listing.price, "Insufficient token balance");
        
        // 检查买家是否已授权足够的代币
        require(
            paymentToken.allowance(msg.sender, address(this)) >= listing.price,
            "Insufficient token allowance"
        );
        
        // 执行购买
        _executePurchase(listingId, msg.sender, listing.price);
    }
    
    /**
     * @dev 实现ITokenReceiver接口，支持通过transferWithCallback自动购买NFT
     * 用户可以直接调用paymentToken.transferWithCallback(marketAddress, amount)来购买NFT
     * 在转账数据中编码listingId信息
     */
    function tokensReceived(address _from, address _to, uint256 _value) external override {
        // 安全检查：确保调用者是支持的ERC20代币合约
        require(msg.sender == address(paymentToken), "Only payment token contract can trigger callback");
        require(_to == address(this), "Callback receiver mismatch");
        
        // 由于当前的ExpendERC20合约的transferWithCallback没有data参数，
        // 我们需要通过其他方式来确定要购买的NFT
        // 这里我们实现一个简化版本：购买当前最便宜的可用NFT
        uint256 listingId = _findCheapestListing(_value);
        require(listingId != 0, "No suitable listing found for this amount");
        
        Listing storage listing = listings[listingId];
        require(listing.active, "Listing not active");
        require(_from != listing.seller, "Cannot buy your own NFT");
        require(_value >= listing.price, "Insufficient payment");
        
        // 执行购买
        _executePurchase(listingId, _from, _value);
        
        // 如果支付金额超过NFT价格，退还多余的代币
        if (_value > listing.price) {
            uint256 refund = _value - listing.price;
            require(paymentToken.transfer(_from, refund), "Refund transfer failed");
        }
    }
    
    /**
     * @dev 内部函数：执行NFT购买
     * @param listingId 上架ID
     * @param buyer 买家地址
     * @param paidAmount 支付金额
     */
    function _executePurchase(uint256 listingId, address buyer, uint256 paidAmount) internal {
        Listing storage listing = listings[listingId];
        
        // 标记为非活跃
        listing.active = false;
        nftToListingId[listing.nftContract][listing.tokenId] = 0;
        
        // 计算费用
        uint256 platformFee = (listing.price * platformFeePercentage) / 10000;
        uint256 sellerAmount = listing.price - platformFee;
        
        // 转移NFT
        IERC721 nft = IERC721(listing.nftContract);
        nft.safeTransferFrom(listing.seller, buyer, listing.tokenId);
        
        // 如果是传统购买方式，需要从买家转移代币
        if (msg.sender != address(paymentToken)) {
            require(
                paymentToken.transferFrom(buyer, address(this), listing.price),
                "Token transfer failed"
            );
        }
        
        // 转移资金给卖家和平台
        if (platformFee > 0) {
            require(paymentToken.transfer(feeRecipient, platformFee), "Platform fee transfer failed");
        }
        require(paymentToken.transfer(listing.seller, sellerAmount), "Seller payment failed");
        
        emit NFTSold(
            listingId,
            listing.nftContract,
            listing.tokenId,
            listing.seller,
            buyer,
            listing.price
        );
    }
    
    /**
     * @dev 查找指定金额可以购买的最便宜的NFT
     * @param amount 可用金额
     * @return 找到的上架ID，如果没有找到返回0
     */
    function _findCheapestListing(uint256 amount) internal view returns (uint256) {
        uint256 cheapestId = 0;
        uint256 cheapestPrice = type(uint256).max;
        
        // 遍历所有上架，找到价格最低且在预算内的NFT
        for (uint256 i = 1; i < _listingIdCounter; i++) {
            Listing storage listing = listings[i];
            if (listing.active && listing.price <= amount && listing.price < cheapestPrice) {
                cheapestPrice = listing.price;
                cheapestId = i;
            }
        }
        
        return cheapestId;
    }
    
    /**
     * @dev 下架NFT
     * @param listingId 上架ID
     */
    function delistNFT(uint256 listingId) external nonReentrant {
        Listing storage listing = listings[listingId];
        require(listing.active, "Listing not active");
        require(listing.seller == msg.sender || msg.sender == owner(), "Not authorized");
        
        listing.active = false;
        nftToListingId[listing.nftContract][listing.tokenId] = 0;
        
        emit NFTDelisted(listingId, listing.nftContract, listing.tokenId, listing.seller);
    }
    
    /**
     * @dev 更新NFT价格
     * @param listingId 上架ID
     * @param newPrice 新价格
     */
    function updatePrice(uint256 listingId, uint256 newPrice) external nonReentrant {
        Listing storage listing = listings[listingId];
        require(listing.active, "Listing not active");
        require(listing.seller == msg.sender, "Not the seller");
        require(newPrice >= minimumPrice, "Price below minimum");
        
        uint256 oldPrice = listing.price;
        listing.price = newPrice;
        listing.updatedAt = block.timestamp;
        
        emit PriceUpdated(listingId, oldPrice, newPrice);
    }
    
    /**
     * @dev 获取用户的上架列表
     * @param user 用户地址
     * @return 上架ID数组
     */
    function getUserListings(address user) external view returns (uint256[] memory) {
        return userListings[user];
    }
    
    /**
     * @dev 获取活跃的上架信息
     * @param listingId 上架ID
     * @return 上架信息
     */
    function getListing(uint256 listingId) external view returns (Listing memory) {
        return listings[listingId];
    }
    
    /**
     * @dev 设置平台费用百分比（仅所有者）
     * @param newFeePercentage 新的费用百分比
     */
    function setPlatformFeePercentage(uint256 newFeePercentage) external onlyOwner {
        require(newFeePercentage <= 1000, "Fee too high"); // 最大10%
        uint256 oldFee = platformFeePercentage;
        platformFeePercentage = newFeePercentage;
        emit PlatformFeeUpdated(oldFee, newFeePercentage);
    }
    
    /**
     * @dev 设置费用接收地址（仅所有者）
     * @param newFeeRecipient 新的费用接收地址
     */
    function setFeeRecipient(address newFeeRecipient) external onlyOwner {
        require(newFeeRecipient != address(0), "Fee recipient cannot be zero address");
        feeRecipient = newFeeRecipient;
    }
    
    /**
     * @dev 设置最小价格（仅所有者）
     * @param newMinimumPrice 新的最小价格
     */
    function setMinimumPrice(uint256 newMinimumPrice) external onlyOwner {
        minimumPrice = newMinimumPrice;
    }
    
    /**
     * @dev 暂停/恢复合约（仅所有者）
     */
    function pause() external onlyOwner {
        _pause();
    }
    
    function unpause() external onlyOwner {
        _unpause();
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
     * @dev 紧急提取代币（仅所有者）
     * @param amount 提取数量
     */
    function emergencyWithdraw(uint256 amount) external onlyOwner {
        require(paymentToken.transfer(owner(), amount), "Emergency withdraw failed");
    }
}