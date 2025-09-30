// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721URIStorage.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";

/**
 * @title MyNFT
 * @dev ERC721 NFT合约，支持铸造、元数据存储和枚举功能
 */
contract MyNFT is ERC721, ERC721URIStorage, ERC721Enumerable, Ownable, ReentrancyGuard {
    using Counters for Counters.Counter;
    
    // 代币ID计数器
    Counters.Counter private _tokenIdCounter;
    
    // 铸造费用
    uint256 public mintPrice = 0.01 ether;
    
    // 最大供应量
    uint256 public maxSupply = 10000;
    
    // 每个地址最大铸造数量
    uint256 public maxMintPerAddress = 10;
    
    // 铸造状态
    bool public mintingEnabled = true;
    
    // 记录每个地址已铸造的数量
    mapping(address => uint256) public mintedCount;
    
    // 版税信息
    address public royaltyReceiver;
    uint256 public royaltyPercentage = 250; // 2.5% (基数为10000)
    
    // 事件
    event NFTMinted(address indexed to, uint256 indexed tokenId, string tokenURI);
    event MintPriceUpdated(uint256 oldPrice, uint256 newPrice);
    event MintingStatusChanged(bool enabled);
    event RoyaltyUpdated(address receiver, uint256 percentage);
    
    constructor(
        string memory name,
        string memory symbol,
        address _royaltyReceiver
    ) ERC721(name, symbol) {
        royaltyReceiver = _royaltyReceiver;
        // 从tokenId 1开始
        _tokenIdCounter.increment();
    }
    
    /**
     * @dev 铸造NFT
     * @param to 接收者地址
     * @param tokenURI 代币元数据URI
     */
    function mint(address to, string memory tokenURI) public payable nonReentrant {
        require(mintingEnabled, "Minting is currently disabled");
        require(to != address(0), "Cannot mint to zero address");
        require(bytes(tokenURI).length > 0, "Token URI cannot be empty");
        require(_tokenIdCounter.current() <= maxSupply, "Max supply reached");
        require(mintedCount[to] < maxMintPerAddress, "Max mint per address reached");
        
        // 检查支付金额（合约所有者免费铸造）
        if (msg.sender != owner()) {
            require(msg.value >= mintPrice, "Insufficient payment");
        }
        
        uint256 tokenId = _tokenIdCounter.current();
        _tokenIdCounter.increment();
        
        // 铸造NFT
        _safeMint(to, tokenId);
        _setTokenURI(tokenId, tokenURI);
        
        // 更新铸造计数
        mintedCount[to]++;
        
        emit NFTMinted(to, tokenId, tokenURI);
        
        // 退还多余的ETH
        if (msg.value > mintPrice && msg.sender != owner()) {
            payable(msg.sender).transfer(msg.value - mintPrice);
        }
    }
    
    /**
     * @dev 批量铸造NFT（仅限合约所有者）
     * @param to 接收者地址
     * @param tokenURIs 代币元数据URI数组
     */
    function batchMint(address to, string[] memory tokenURIs) external onlyOwner {
        require(to != address(0), "Cannot mint to zero address");
        require(tokenURIs.length > 0, "Token URIs array cannot be empty");
        require(_tokenIdCounter.current() + tokenURIs.length <= maxSupply, "Would exceed max supply");
        
        for (uint256 i = 0; i < tokenURIs.length; i++) {
            require(bytes(tokenURIs[i]).length > 0, "Token URI cannot be empty");
            
            uint256 tokenId = _tokenIdCounter.current();
            _tokenIdCounter.increment();
            
            _safeMint(to, tokenId);
            _setTokenURI(tokenId, tokenURIs[i]);
            
            emit NFTMinted(to, tokenId, tokenURIs[i]);
        }
        
        mintedCount[to] += tokenURIs.length;
    }
    
    /**
     * @dev 设置铸造价格（仅限合约所有者）
     * @param _mintPrice 新的铸造价格
     */
    function setMintPrice(uint256 _mintPrice) external onlyOwner {
        uint256 oldPrice = mintPrice;
        mintPrice = _mintPrice;
        emit MintPriceUpdated(oldPrice, _mintPrice);
    }
    
    /**
     * @dev 设置铸造状态（仅限合约所有者）
     * @param _enabled 是否启用铸造
     */
    function setMintingEnabled(bool _enabled) external onlyOwner {
        mintingEnabled = _enabled;
        emit MintingStatusChanged(_enabled);
    }
    
    /**
     * @dev 设置最大供应量（仅限合约所有者）
     * @param _maxSupply 新的最大供应量
     */
    function setMaxSupply(uint256 _maxSupply) external onlyOwner {
        require(_maxSupply >= _tokenIdCounter.current(), "Max supply cannot be less than current supply");
        maxSupply = _maxSupply;
    }
    
    /**
     * @dev 设置每个地址最大铸造数量（仅限合约所有者）
     * @param _maxMintPerAddress 新的每个地址最大铸造数量
     */
    function setMaxMintPerAddress(uint256 _maxMintPerAddress) external onlyOwner {
        maxMintPerAddress = _maxMintPerAddress;
    }
    
    /**
     * @dev 设置版税信息（仅限合约所有者）
     * @param _receiver 版税接收者地址
     * @param _percentage 版税百分比（基数为10000）
     */
    function setRoyalty(address _receiver, uint256 _percentage) external onlyOwner {
        require(_receiver != address(0), "Royalty receiver cannot be zero address");
        require(_percentage <= 1000, "Royalty percentage cannot exceed 10%");
        
        royaltyReceiver = _receiver;
        royaltyPercentage = _percentage;
        
        emit RoyaltyUpdated(_receiver, _percentage);
    }
    
    /**
     * @dev 获取当前代币ID
     */
    function getCurrentTokenId() external view returns (uint256) {
        return _tokenIdCounter.current();
    }
    
    /**
     * @dev 获取总供应量
     */
    function totalSupply() public view override returns (uint256) {
        return _tokenIdCounter.current() - 1;
    }
    
    /**
     * @dev 获取用户拥有的所有代币ID
     * @param owner 用户地址
     */
    function tokensOfOwner(address owner) external view returns (uint256[] memory) {
        uint256 tokenCount = balanceOf(owner);
        if (tokenCount == 0) {
            return new uint256[](0);
        }
        
        uint256[] memory tokenIds = new uint256[](tokenCount);
        for (uint256 i = 0; i < tokenCount; i++) {
            tokenIds[i] = tokenOfOwnerByIndex(owner, i);
        }
        
        return tokenIds;
    }
    
    /**
     * @dev 检查代币是否存在
     * @param tokenId 代币ID
     */
    function exists(uint256 tokenId) external view returns (bool) {
        return _exists(tokenId);
    }
    
    /**
     * @dev 支持EIP-2981版税标准
     * @param tokenId 代币ID
     * @param salePrice 销售价格
     */
    function royaltyInfo(uint256 tokenId, uint256 salePrice)
        external
        view
        returns (address receiver, uint256 royaltyAmount)
    {
        require(_exists(tokenId), "Token does not exist");
        
        receiver = royaltyReceiver;
        royaltyAmount = (salePrice * royaltyPercentage) / 10000;
    }
    
    /**
     * @dev 提取合约余额（仅限合约所有者）
     */
    function withdraw() external onlyOwner {
        uint256 balance = address(this).balance;
        require(balance > 0, "No funds to withdraw");
        
        (bool success, ) = payable(owner()).call{value: balance}("");
        require(success, "Withdrawal failed");
    }
    
    /**
     * @dev 紧急提取指定代币（仅限合约所有者）
     * @param token ERC20代币地址
     */
    function emergencyWithdrawToken(address token) external onlyOwner {
        require(token != address(0), "Token address cannot be zero");
        
        IERC20 tokenContract = IERC20(token);
        uint256 balance = tokenContract.balanceOf(address(this));
        require(balance > 0, "No token balance to withdraw");
        
        require(tokenContract.transfer(owner(), balance), "Token transfer failed");
    }
    
    // 重写必要的函数以解决继承冲突
    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 tokenId,
        uint256 batchSize
    ) internal override(ERC721, ERC721Enumerable) {
        super._beforeTokenTransfer(from, to, tokenId, batchSize);
    }
    
    function _burn(uint256 tokenId) internal override(ERC721, ERC721URIStorage) {
        super._burn(tokenId);
    }
    
    function tokenURI(uint256 tokenId)
        public
        view
        override(ERC721, ERC721URIStorage)
        returns (string memory)
    {
        return super.tokenURI(tokenId);
    }
    
    function supportsInterface(bytes4 interfaceId)
        public
        view
        override(ERC721, ERC721Enumerable, ERC721URIStorage)
        returns (bool)
    {
        return
            interfaceId == 0x2a55205a || // EIP-2981 royalty standard
            super.supportsInterface(interfaceId);
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

// IERC20接口用于紧急提取代币
interface IERC20 {
    function balanceOf(address account) external view returns (uint256);
    function transfer(address to, uint256 amount) external returns (bool);
}