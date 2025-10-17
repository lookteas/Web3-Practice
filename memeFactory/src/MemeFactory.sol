// SPDX-License-Identifier: MIT
pragma solidity ^0.8.25;

import "@openzeppelin/contracts/proxy/Clones.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/ReentrancyGuard.sol";
import "./MemeToken.sol";

/**
 * @title MemeFactory
 * @dev 使用 EIP-1167 最小代理模式的 Meme 代币工厂合约
 * 实现 deployMeme 和 mintMeme 方法
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
    
    // 代币地址到价格的映射（每次铸造的费用，以 wei 计价）
    mapping(address => uint256) public tokenToPrice;
    
    // 部署费用
    uint256 public deploymentFee;
    
    // 铸造费用
    uint256 public mintingFee;
    
    // 项目方费用比例（基点，100 = 1%）
    uint256 public constant PROJECT_FEE_BASIS_POINTS = 100;
    
    // 事件
    event TokenDeployed(
        address indexed tokenAddress,
        string symbol,
        uint256 totalSupply,
        uint256 perMint,
        uint256 price,
        address indexed deployer
    );
    
    event TokenMinted(
        address indexed tokenAddress,
        address indexed to,
        uint256 amount,
        uint256 fee,
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
     * @param price 每次铸造的费用（以 wei 计价）
     * @return tokenAddress 新部署的代币地址
     */
    function deployMeme(
        string memory symbol,
        uint256 totalSupply,
        uint256 perMint,
        uint256 price
    ) external payable nonReentrant returns (address tokenAddress) {
        require(bytes(symbol).length > 0, "Symbol cannot be empty");
        require(bytes(symbol).length <= 10, "Symbol too long");
        require(totalSupply > 0, "Total supply must be greater than 0");
        require(perMint > 0, "Per mint must be greater than 0");
        require(perMint <= totalSupply, "Per mint cannot exceed total supply");
        require(price > 0, "Price must be greater than 0");
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
        tokenToPrice[tokenAddress] = price;
        
        emit TokenDeployed(tokenAddress, symbol, totalSupply, perMint, price, msg.sender);
        
        return tokenAddress;
    }
    
    /**
     * @dev 铸造代币
     * @param tokenAddr 代币合约地址
     */
    function mintMeme(address tokenAddr) external payable nonReentrant {
        require(tokenAddr != address(0), "Invalid token address");
        require(isDeployedToken(tokenAddr), "Token not deployed by this factory");
        
        uint256 price = tokenToPrice[tokenAddr];
        require(msg.value >= price, "Insufficient payment");
        
        MemeToken token = MemeToken(tokenAddr);
        require(token.canMint(msg.sender), "Cannot mint to this address");
        
        // 计算费用分配
        uint256 projectFee = (price * PROJECT_FEE_BASIS_POINTS) / 10000; // 1%
        uint256 deployerFee = price - projectFee; // 99%
        
        // 分配费用
        address deployer = tokenToDeployer[tokenAddr];
        if (projectFee > 0) {
            (bool success1, ) = payable(owner()).call{value: projectFee}("");
            require(success1, "Project fee transfer failed");
        }
        
        if (deployerFee > 0) {
            (bool success2, ) = payable(deployer).call{value: deployerFee}("");
            require(success2, "Deployer fee transfer failed");
        }
        
        // 调用代币合约的铸造函数
        token.mint(msg.sender);
        
        emit TokenMinted(tokenAddr, msg.sender, token.perMint(), price, msg.sender);
    }
    
    /**
     * @dev 批量铸造代币
     * @param tokenAddr 代币合约地址
     * @param count 铸造次数
     */
    function batchMintMeme(address tokenAddr, uint256 count) external payable nonReentrant {
        require(tokenAddr != address(0), "Invalid token address");
        require(isDeployedToken(tokenAddr), "Token not deployed by this factory");
        require(count > 0 && count <= 5, "Invalid count (1-5)");
        
        uint256 price = tokenToPrice[tokenAddr];
        uint256 totalPrice = price * count;
        require(msg.value >= totalPrice, "Insufficient payment");
        
        MemeToken token = MemeToken(tokenAddr);
        
        // 计算费用分配
        uint256 projectFee = (totalPrice * PROJECT_FEE_BASIS_POINTS) / 10000; // 1%
        uint256 deployerFee = totalPrice - projectFee; // 99%
        
        // 分配费用
        address deployer = tokenToDeployer[tokenAddr];
        if (projectFee > 0) {
            (bool success1, ) = payable(owner()).call{value: projectFee}("");
            require(success1, "Project fee transfer failed");
        }
        
        if (deployerFee > 0) {
            (bool success2, ) = payable(deployer).call{value: deployerFee}("");
            require(success2, "Deployer fee transfer failed");
        }
        
        for (uint256 i = 0; i < count; i++) {
            require(token.canMint(msg.sender), "Cannot mint more to this address");
            token.mint(msg.sender);
        }
        
        emit TokenMinted(tokenAddr, msg.sender, token.perMint() * count, totalPrice, msg.sender);
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
        uint256 price,
        address deployer
    ) {
        require(isDeployedToken(tokenAddr), "Token not deployed by this factory");
        
        MemeToken token = MemeToken(tokenAddr);
        (name, symbol, totalSupply, perMint, mintedAmount, remainingSupply) = token.getTokenInfo();
        price = tokenToPrice[tokenAddr];
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