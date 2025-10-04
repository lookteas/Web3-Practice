# NFT 市场项目

这是一个完整的NFT（非同质化代币）项目，包含NFT合约的实现以及功能丰富的NFT交易市场。项目基于OpenZeppelin框架开发，实现了完整的NFT生命周期管理。

## 项目结构

```
nft/
├── MyNFT.sol      - 可铸造的ERC721 NFT合约
└── NFTMarket.sol  - 功能完整的NFT交易市场合约
```

## 合约说明

### MyNFT.sol
- 继承自OpenZeppelin的ERC721标准实现
- 核心特性：
  - 支持代币URI存储（ERC721URIStorage）
  - 支持代币枚举功能（ERC721Enumerable）
  - 包含所有权控制（Ownable）
  - 防重入保护（ReentrancyGuard）

- 主要功能：
  - 单个NFT铸造
  - 批量NFT铸造（仅管理员）
  - 代币URI管理
  - 铸造价格设置
  - 版税机制（2.5%）
  - 最大供应量控制（默认10000）
  - 每地址最大铸造数量限制（默认10）

- 参数配置：
  - 铸造价格：0.01 ETH
  - 最大供应量：10,000
  - 每地址最大铸造：10个
  - 版税比例：2.5%

### NFTMarket.sol
- 完整的NFT交易市场实现
- 核心特性：
  - NFT接收能力（IERC721Receiver）
  - 防重入保护（ReentrancyGuard）
  - 所有权控制（Ownable）
  - 可暂停功能（Pausable）

- 主要功能：
  1. 固定价格交易
     - NFT上架
     - NFT购买
     - 价格更新
     - 取消上架
  
  2. 拍卖功能
     - 创建拍卖
     - 出价
     - 结束拍卖
     - 自动结算
  
  3. 报价系统
     - 创建报价
     - 接受报价
     - 报价过期管理

- 平台费用：
  - 交易费率：2.5%
  - 最低上架价格：0.001 ETH

## 部署流程

1. 部署MyNFT合约
```solidity
constructor(
    string memory name,          // NFT集合名称
    string memory symbol,        // NFT集合符号
    address _royaltyReceiver     // 版税接收地址
)
```

2. 部署NFTMarket合约
```solidity
constructor(
    address _feeRecipient        // 平台费用接收地址
)
```

## 使用指南

### NFT铸造

1. 普通用户铸造
```solidity
function mint(
    address to,                  // 接收地址
    string memory tokenURI      // 元数据URI
) public payable
```

2. 管理员批量铸造
```solidity
function batchMint(
    address to,                  // 接收地址
    string[] memory tokenURIs   // 元数据URI数组
) external onlyOwner
```

### 市场交易

1. 上架NFT
```solidity
function listNFT(
    address nftContract,         // NFT合约地址
    uint256 tokenId,            // 代币ID
    uint256 price               // 价格
) external
```

2. 购买NFT
```solidity
function buyNFT(
    uint256 listingId           // 上架ID
) external payable
```

3. 创建拍卖
```solidity
function createAuction(
    address nftContract,         // NFT合约地址
    uint256 tokenId,            // 代币ID
    uint256 startingPrice,      // 起拍价
    uint256 duration            // 持续时间
) external
```

## 安全特性

1. 防重入保护
   - 所有关键函数都使用ReentrancyGuard
   - 严格的状态更新顺序

2. 访问控制
   - 基于OpenZeppelin的Ownable实现
   - 精确的权限控制机制

3. 交易安全
   - 严格的余额检查
   - 完整的授权验证
   - 安全的转账流程

4. 紧急机制
   - 市场合约可暂停
   - 管理员紧急操作权限

## 测试要点

1. NFT合约测试
   - 铸造功能（普通/批量）
   - 铸造限制（数量/价格）
   - URI管理
   - 版税机制

2. 市场合约测试
   - 上架流程
   - 购买流程
   - 拍卖机制
   - 报价系统
   - 费用计算
   - 紧急暂停

## 最佳实践

1. 部署前准备
   - 确认所有参数配置
   - 准备元数据存储方案
   - 测试网络验证

2. 安全建议
   - 使用多重签名钱包
   - 定期审计合约
   - 监控异常交易

3. 运营建议
   - 合理设置费用比例
   - 建立应急响应机制
   - 保持文档更新

## 注意事项

1. Gas优化
   - 批量操作使用batchMint
   - 合理设置价格和数量限制
   - 避免不必要的存储操作

2. 元数据管理
   - 使用可靠的存储方案（如IPFS）
   - 确保元数据永久可用
   - 考虑元数据更新机制

3. 升级维护
   - 记录所有配置更改
   - 保持向后兼容
   - 提前规划升级方案