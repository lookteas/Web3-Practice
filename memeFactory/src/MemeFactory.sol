// SPDX-License-Identifier: MIT
pragma solidity ^0.8.25;

import "@openzeppelin/contracts/proxy/Clones.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/ReentrancyGuard.sol";
import "./MemeToken.sol";

/**
 * @title MemeFactory
 * @dev 使用 EIP-1167 最小代理模式的 Meme 代币工厂合约
 * 实现 deployInscription 和 mintInscription 方法
 */
contract MemeFactory is Ownable, ReentrancyGuard {
    using Clones for address;
    
    // 实现合约地址（模板合约）
    address public immutable implementation;
    
    // 已部署的代币列表
    address[] public deployedTokens;
    
    // 代币符号到地址的映射
    mapping(string => address) public symbolToToken;
    
    // 代币地址到符号的映射
    mapping(address => string) public tokenToSymbol;
    
    // 代币地址到部署者的映射
    mapping(address => address) public tokenToDeployer;
    
    // 部署费用（可选）
    uint256 public deploymentFee;
    
    // 铸造费用（可选）
    uint256 public mintingFee;
    
    // 事件
    event TokenDeployed(
        address indexed tokenAddress,
        string symbol,
        uint256 totalSupply,
        uint256 perMint,
        address indexed deployer
    );
    
    event TokenMinted(
        address indexed tokenAddress,
        address indexed to,
        uint256 amount,
        address indexed minter
    );
    
    event FeesUpdated(uint256 deploymentFee, uint256 mintingFee);
    
    /**
     * @dev 构造函数
     */
    constructor() Ownable(msg.sender) {
        // 部署实现合约
        implementation = address(new MemeToken());
    }
    
    /**
     * @dev 部署新的 Meme 代币
     * @param symbol 代币符号
     * @param totalSupply 总供应量
     * @param perMint 每次铸造数量
     * @return tokenAddress 新部署的代币地址
     */
    function deployInscription(
        string memory symbol,
        uint256 totalSupply,
        uint256 perMint
    ) external payable nonReentrant returns (address tokenAddress) {
        require(bytes(symbol).length > 0, "Symbol cannot be empty");
        require(bytes(symbol).length <= 10, "Symbol too long");
        require(totalSupply > 0, "Total supply must be greater than 0");
        require(perMint > 0, "Per mint must be greater than 0");
        require(perMint <= totalSupply, "Per mint cannot exceed total supply");
        require(symbolToToken[symbol] == address(0), "Symbol already exists");
        require(msg.value >= deploymentFee, "Insufficient deployment fee");
        
        // 使用 EIP-1167 克隆实现合约
        tokenAddress = implementation.clone();
        
        // 初始化克隆的合约
        string memory name = string(abi.encodePacked("Meme ", symbol));
        MemeToken(tokenAddress).initialize(
            name,
            symbol,
            totalSupply,
            perMint,
            address(this)
        );
        
        // 记录部署信息
        deployedTokens.push(tokenAddress);
        symbolToToken[symbol] = tokenAddress;
        tokenToSymbol[tokenAddress] = symbol;
        tokenToDeployer[tokenAddress] = msg.sender;
        
        emit TokenDeployed(tokenAddress, symbol, totalSupply, perMint, msg.sender);
        
        return tokenAddress;
    }
    
    /**
     * @dev 铸造代币
     * @param tokenAddr 代币合约地址
     */
    function mintInscription(address tokenAddr) external payable nonReentrant {
        require(tokenAddr != address(0), "Invalid token address");
        require(isDeployedToken(tokenAddr), "Token not deployed by this factory");
        require(msg.value >= mintingFee, "Insufficient minting fee");
        
        MemeToken token = MemeToken(tokenAddr);
        require(token.canMint(msg.sender), "Cannot mint to this address");
        
        // 调用代币合约的铸造函数
        token.mint(msg.sender);
        
        emit TokenMinted(tokenAddr, msg.sender, token.perMint(), msg.sender);
    }
    
    /**
     * @dev 批量铸造代币
     * @param tokenAddr 代币合约地址
     * @param count 铸造次数
     */
    function batchMintInscription(address tokenAddr, uint256 count) external payable nonReentrant {
        require(tokenAddr != address(0), "Invalid token address");
        require(isDeployedToken(tokenAddr), "Token not deployed by this factory");
        require(count > 0 && count <= 5, "Invalid count (1-5)");
        require(msg.value >= mintingFee * count, "Insufficient minting fee");
        
        MemeToken token = MemeToken(tokenAddr);
        
        for (uint256 i = 0; i < count; i++) {
            require(token.canMint(msg.sender), "Cannot mint more to this address");
            token.mint(msg.sender);
        }
        
        emit TokenMinted(tokenAddr, msg.sender, token.perMint() * count, msg.sender);
    }
    
    /**
     * @dev 检查是否为工厂部署的代币
     */
    function isDeployedToken(address tokenAddr) public view returns (bool) {
        return bytes(tokenToSymbol[tokenAddr]).length > 0;
    }
    
    /**
     * @dev 获取已部署的代币数量
     */
    function getDeployedTokensCount() external view returns (uint256) {
        return deployedTokens.length;
    }
    
    /**
     * @dev 获取已部署的代币列表（分页）
     */
    function getDeployedTokens(uint256 offset, uint256 limit) 
        external 
        view 
        returns (address[] memory tokens, string[] memory symbols) 
    {
        require(offset < deployedTokens.length, "Offset out of bounds");
        
        uint256 end = offset + limit;
        if (end > deployedTokens.length) {
            end = deployedTokens.length;
        }
        
        uint256 length = end - offset;
        tokens = new address[](length);
        symbols = new string[](length);
        
        for (uint256 i = 0; i < length; i++) {
            tokens[i] = deployedTokens[offset + i];
            symbols[i] = tokenToSymbol[tokens[i]];
        }
    }
    
    /**
     * @dev 获取代币详细信息
     */
    function getTokenInfo(address tokenAddr) external view returns (
        string memory name,
        string memory symbol,
        uint256 totalSupply,
        uint256 perMint,
        uint256 mintedAmount,
        uint256 remainingSupply,
        address deployer
    ) {
        require(isDeployedToken(tokenAddr), "Token not deployed by this factory");
        
        MemeToken token = MemeToken(tokenAddr);
        (name, symbol, totalSupply, perMint, mintedAmount, remainingSupply) = token.getTokenInfo();
        deployer = tokenToDeployer[tokenAddr];
    }
    
    /**
     * @dev 根据符号获取代币地址
     */
    function getTokenBySymbol(string memory symbol) external view returns (address) {
        return symbolToToken[symbol];
    }
    
    /**
     * @dev 设置费用（仅所有者）
     */
    function setFees(uint256 _deploymentFee, uint256 _mintingFee) external onlyOwner {
        deploymentFee = _deploymentFee;
        mintingFee = _mintingFee;
        emit FeesUpdated(_deploymentFee, _mintingFee);
    }
    
    /**
     * @dev 提取合约余额（仅所有者）
     */
    function withdraw() external onlyOwner {
        uint256 balance = address(this).balance;
        require(balance > 0, "No funds to withdraw");
        
        (bool success, ) = payable(owner()).call{value: balance}("");
        require(success, "Withdrawal failed");
    }
    
    /**
     * @dev 紧急暂停功能（仅所有者）
     */
    function emergencyPause() external onlyOwner {
        // 可以添加暂停逻辑
    }
    
    /**
     * @dev 获取实现合约地址
     */
    function getImplementation() external view returns (address) {
        return implementation;
    }
    
    /**
     * @dev 检查符号是否可用
     */
    function isSymbolAvailable(string memory symbol) external view returns (bool) {
        return symbolToToken[symbol] == address(0);
    }
    
    /**
     * @dev 预测代币地址
     */
    function predictTokenAddress(bytes32 salt) external view returns (address) {
        return implementation.predictDeterministicAddress(salt);
    }
    
    /**
     * @dev 接收 ETH
     */
    receive() external payable {}
    
    /**
     * @dev 回退函数
     */
    fallback() external payable {}
}