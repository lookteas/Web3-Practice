// Polygon Mainnet 合约地址
const CONTRACT_ADDRESSES = {
    MyNFT: "0x1C4603F4366606Ba1EFd588D48150ef21ECcA4e1",
    NFTMarket: "0xb100eC78E6B1E3604A08F8262B902fDde9bCd619"
};

// 网络配置
const NETWORK_CONFIG = {
    chainId: 137, // Polygon Mainnet
    chainName: "Polygon Mainnet",
    nativeCurrency: {
        name: "MATIC",
        symbol: "MATIC",
        decimals: 18
    },
    rpcUrls: ["https://polygon-rpc.com/"],
    blockExplorerUrls: ["https://polygonscan.com/"]
};

// MyNFT 合约 ABI
const NFT_ABI = [
    // ERC721 标准函数
    "function approve(address to, uint256 tokenId) external",
    "function balanceOf(address owner) external view returns (uint256)",
    "function getApproved(uint256 tokenId) external view returns (address)",
    "function isApprovedForAll(address owner, address operator) external view returns (bool)",
    "function name() external view returns (string)",
    "function ownerOf(uint256 tokenId) external view returns (address)",
    "function safeTransferFrom(address from, address to, uint256 tokenId) external",
    "function safeTransferFrom(address from, address to, uint256 tokenId, bytes calldata data) external",
    "function setApprovalForAll(address operator, bool approved) external",
    "function supportsInterface(bytes4 interfaceId) external view returns (bool)",
    "function symbol() external view returns (string)",
    "function tokenURI(uint256 tokenId) external view returns (string)",
    "function transferFrom(address from, address to, uint256 tokenId) external",
    
    // NFT 特定函数
    "function mint(address to, string memory uri) external payable returns (uint256)",
    "function totalSupply() external view returns (uint256)",
    "function tokenByIndex(uint256 index) external view returns (uint256)",
    "function tokenOfOwnerByIndex(address owner, uint256 index) external view returns (uint256)",
    
    // 管理员函数
    "function owner() external view returns (address)",
    "function renounceOwnership() external",
    "function transferOwnership(address newOwner) external",
    "function setMintPrice(uint256 _mintPrice) external",
    "function setMaxSupply(uint256 _maxSupply) external",
    "function withdraw() external",
    "function mintPrice() external view returns (uint256)",
    "function maxSupply() external view returns (uint256)",
    
    // 版税函数
    "function royaltyInfo(uint256 tokenId, uint256 salePrice) external view returns (address, uint256)",
    "function setDefaultRoyalty(address receiver, uint96 feeNumerator) external",
    "function deleteDefaultRoyalty() external",
    "function setTokenRoyalty(uint256 tokenId, address receiver, uint96 feeNumerator) external",
    "function resetTokenRoyalty(uint256 tokenId) external",
    
    // 事件
    "event Approval(address indexed owner, address indexed approved, uint256 indexed tokenId)",
    "event ApprovalForAll(address indexed owner, address indexed operator, bool approved)",
    "event OwnershipTransferred(address indexed previousOwner, address indexed newOwner)",
    "event Transfer(address indexed from, address indexed to, uint256 indexed tokenId)"
];

// NFTMarket 合约 ABI
const MARKET_ABI = [
    // 核心交易函数
    "function listNFT(address nftContract, uint256 tokenId, uint256 price) external",
    "function buyNFT(address nftContract, uint256 tokenId) external payable",
    "function cancelListing(address nftContract, uint256 tokenId) external",
    "function updateListingPrice(address nftContract, uint256 tokenId, uint256 newPrice) external",
    
    // 出价函数
    "function makeOffer(address nftContract, uint256 tokenId) external payable",
    "function acceptOffer(address nftContract, uint256 tokenId, address buyer) external",
    "function cancelOffer(address nftContract, uint256 tokenId) external",
    
    // 拍卖函数
    "function createAuction(address nftContract, uint256 tokenId, uint256 startingPrice, uint256 duration) external",
    "function placeBid(address nftContract, uint256 tokenId) external payable",
    "function endAuction(address nftContract, uint256 tokenId) external",
    
    // 查询函数
    "function getListing(address nftContract, uint256 tokenId) external view returns (tuple(address seller, uint256 price, bool active))",
    "function getOffer(address nftContract, uint256 tokenId, address buyer) external view returns (uint256)",
    "function getAuction(address nftContract, uint256 tokenId) external view returns (tuple(address seller, uint256 startingPrice, uint256 currentBid, address highestBidder, uint256 endTime, bool active))",
    "function getActiveListings(uint256 offset, uint256 limit) external view returns (tuple(uint256 listingId, address nftContract, uint256 tokenId, address seller, uint256 price, bool active, uint256 createdAt, uint256 updatedAt)[])",
    "function getUserListings(address user) external view returns (tuple(address nftContract, uint256 tokenId, address seller, uint256 price)[])",
    "function getUserOffers(address user) external view returns (tuple(address nftContract, uint256 tokenId, address buyer, uint256 amount)[])",
    "function getUserAuctions(address user) external view returns (tuple(address nftContract, uint256 tokenId, address seller, uint256 startingPrice, uint256 currentBid, address highestBidder, uint256 endTime, bool active)[])",
    
    // 配置函数
    "function marketplaceFee() external view returns (uint256)",
    "function feeRecipient() external view returns (address)",
    
    // 管理员函数
    "function owner() external view returns (address)",
    "function renounceOwnership() external",
    "function transferOwnership(address newOwner) external",
    "function setMarketplaceFee(uint256 _fee) external",
    "function setFeeRecipient(address _feeRecipient) external",
    "function emergencyWithdraw() external",
    
    // ERC721接收器
    "function onERC721Received(address operator, address from, uint256 tokenId, bytes calldata data) external returns (bytes4)",
    
    // 事件
    "event NFTListed(address indexed nftContract, uint256 indexed tokenId, address indexed seller, uint256 price)",
    "event NFTSold(address indexed nftContract, uint256 indexed tokenId, address indexed seller, address buyer, uint256 price)",
    "event ListingCancelled(address indexed nftContract, uint256 indexed tokenId, address indexed seller)",
    "event ListingPriceUpdated(address indexed nftContract, uint256 indexed tokenId, address indexed seller, uint256 oldPrice, uint256 newPrice)",
    "event OfferMade(address indexed nftContract, uint256 indexed tokenId, address indexed buyer, uint256 amount)",
    "event OfferAccepted(address indexed nftContract, uint256 indexed tokenId, address indexed seller, address buyer, uint256 amount)",
    "event OfferCancelled(address indexed nftContract, uint256 indexed tokenId, address indexed buyer, uint256 amount)",
    "event AuctionCreated(address indexed nftContract, uint256 indexed tokenId, address indexed seller, uint256 startingPrice, uint256 endTime)",
    "event BidPlaced(address indexed nftContract, uint256 indexed tokenId, address indexed bidder, uint256 amount)",
    "event AuctionEnded(address indexed nftContract, uint256 indexed tokenId, address indexed winner, uint256 amount)"
];

// 向后兼容的合约对象
const CONTRACTS = {
    MyNFT: {
        address: CONTRACT_ADDRESSES.MyNFT,
        abi: NFT_ABI
    },
    NFTMarket: {
        address: CONTRACT_ADDRESSES.NFTMarket,
        abi: MARKET_ABI
    }
};

// 导出所有配置
if (typeof module !== 'undefined' && module.exports) {
    // Node.js 环境
    module.exports = {
        CONTRACT_ADDRESSES,
        NETWORK_CONFIG,
        NFT_ABI,
        MARKET_ABI,
        CONTRACTS
    };
} else {
    // 浏览器环境
    window.CONTRACT_ADDRESSES = CONTRACT_ADDRESSES;
    window.NETWORK_CONFIG = NETWORK_CONFIG;
    window.NFT_ABI = NFT_ABI;
    window.MARKET_ABI = MARKET_ABI;
    window.CONTRACTS = CONTRACTS;
}