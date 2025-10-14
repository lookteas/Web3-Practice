// SPDX-License-Identifier: MIT
pragma solidity ^0.8.25;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/ReentrancyGuard.sol";

/**
 * @title MemeToken
 * @dev ERC20 代币合约，用作 Meme 代币的实现合约
 * 支持通过工厂合约进行铸造，每次铸造固定数量
 */
contract MemeToken is ERC20, Ownable, ReentrancyGuard {
    // 代币名称和符号（用于存储）
    string private _tokenName;
    string private _tokenSymbol;
    
    // 代币总供应量
    uint256 public totalSupplyLimit;
    
    // 每次铸造的数量
    uint256 public perMint;
    
    // 已铸造的数量
    uint256 public mintedAmount;
    
    // 工厂合约地址
    address public factory;
    
    // 是否已初始化
    bool public initialized;
    
    // 每个地址的铸造记录
    mapping(address => uint256) public mintedByAddress;
    
    // 每个地址最大铸造次数限制
    uint256 public constant MAX_MINT_PER_ADDRESS = 10;
    
    // 事件
    event TokenInitialized(string symbol, uint256 totalSupply, uint256 perMint);
    event TokenMinted(address indexed to, uint256 amount);
    
    /**
     * @dev 构造函数 - 创建空的代币合约用于克隆
     */
    constructor() ERC20("", "") Ownable(msg.sender) {
        // 空构造函数，实际初始化在 initialize 函数中进行
    }
    
    /**
     * @dev 初始化函数，用于最小代理合约的初始化
     * @param _name 代币名称
     * @param _symbol 代币符号
     * @param _totalSupply 总供应量
     * @param _perMint 每次铸造数量
     * @param _factory 工厂合约地址
     */
    function initialize(
        string memory _name,
        string memory _symbol,
        uint256 _totalSupply,
        uint256 _perMint,
        address _factory
    ) external {
        require(!initialized, "Already initialized");
        require(_totalSupply > 0, "Total supply must be greater than 0");
        require(_perMint > 0, "Per mint must be greater than 0");
        require(_perMint <= _totalSupply, "Per mint cannot exceed total supply");
        require(_factory != address(0), "Factory cannot be zero address");
        
        // 设置代币信息
        _tokenName = _name;
        _tokenSymbol = _symbol;
        
        totalSupplyLimit = _totalSupply;
        perMint = _perMint;
        factory = _factory;
        initialized = true;
        
        // 转移所有权给工厂合约
        _transferOwnership(_factory);
        
        emit TokenInitialized(_symbol, _totalSupply, _perMint);
    }
    
    /**
     * @dev 铸造代币函数，只能由工厂合约调用
     * @param to 接收地址
     */
    function mint(address to) external onlyOwner nonReentrant {
        require(to != address(0), "Cannot mint to zero address");
        require(mintedAmount + perMint <= totalSupplyLimit, "Exceeds total supply");
        require(mintedByAddress[to] < MAX_MINT_PER_ADDRESS, "Exceeds max mint per address");
        
        mintedAmount += perMint;
        mintedByAddress[to] += 1;
        
        _mint(to, perMint);
        
        emit TokenMinted(to, perMint);
    }
    
    /**
     * @dev 获取剩余可铸造数量
     */
    function remainingSupply() external view returns (uint256) {
        return totalSupplyLimit - mintedAmount;
    }
    
    /**
     * @dev 检查地址是否还能铸造
     */
    function canMint(address addr) external view returns (bool) {
        return mintedByAddress[addr] < MAX_MINT_PER_ADDRESS && 
               mintedAmount + perMint <= totalSupplyLimit;
    }
    
    /**
     * @dev 获取地址已铸造次数
     */
    function getMintedCount(address addr) external view returns (uint256) {
        return mintedByAddress[addr];
    }
    
    /**
     * @dev 获取代币基本信息
     */
    function getTokenInfo() external view returns (
        string memory tokenName,
        string memory tokenSymbol,
        uint256 totalSupply,
        uint256 perMintAmount,
        uint256 minted,
        uint256 remaining
    ) {
        return (
            name(),
            symbol(),
            totalSupplyLimit,
            perMint,
            mintedAmount,
            totalSupplyLimit - mintedAmount
        );
    }
    
    /**
     * @dev 重写 name 函数以支持动态设置
     */
    function name() public view virtual override returns (string memory) {
        if (!initialized) {
            return "Uninitialized Meme Token";
        }
        return string(abi.encodePacked("Meme ", _tokenSymbol));
    }
    
    /**
     * @dev 重写 symbol 函数以支持动态设置
     */
    function symbol() public view virtual override returns (string memory) {
        if (!initialized) {
            return "UNINITIALIZED";
        }
        return _tokenSymbol;
    }
    
    /**
     * @dev 重写 decimals 函数，设置为 18 位小数
     */
    function decimals() public pure override returns (uint8) {
        return 18;
    }
}