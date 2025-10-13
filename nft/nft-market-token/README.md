# ERC20代币NFT市场系统

这个项目实现了一个支持ERC20代币购买NFT的市场系统，集成了扩展的ERC20代币合约和NFT市场合约。

## 项目结构

```
nft/
├── nft-market-token/
│   ├── ExpendERC20.sol         - 扩展的ERC20代币合约
│   ├── ITokenReceiver.sol      - 代币接收回调接口
│   ├── MyNFT.sol               - ERC721 NFT合约
│   ├── NFTMarketWithERC20.sol  - 支持ERC20代币的NFT市场
│   └── info.md                 - 代币信息说明
└── README.md  - 本说明文档
```

## 核心功能

### 1. ExpendERC20代币合约
- 标准ERC20功能：转账、授权、余额查询
- **扩展功能**：`transferWithCallback` - 支持转账时回调目标合约
- 初始供应量：100,000,000 tokens (18位小数)

### 2. NFTMarketWithERC20市场合约
- **双重购买方式**：
  - 传统方式：先授权，再调用`buyNFT()`
  - 自动方式：直接调用`transferWithCallback()`自动购买
- **智能匹配**：自动购买价格最低的可用NFT
- **安全保障**：重入攻击防护、权限控制、暂停机制
- **费用管理**：可配置的平台费用（默认2.5%）

## 使用流程

### 部署合约

```bash
# 使用remix部署合约
# 1. 打开remix IDE
# 2. 导入项目文件（ExpendERC20.sol, MyNFT.sol, NFTMarketWithERC20.sol）
1. 第一步：部署ERC20代币合约
- 合约： ExpendERC20.sol
- 原因：NFT市场合约需要ERC20代币合约地址作为构造函数参数
- 无依赖：该合约不依赖其他合约，可以独立部署 
2. 第二步：部署NFT合约
- 合约： MyNFT.sol
- 构造参数：需要版税接收者地址（可以是部署者地址或专门的费用接收地址）
- 依赖：不依赖其他合约，但需要确定版税接收者 
3. 第三步：部署NFT市场合约
- 合约： NFTMarketWithERC20.sol
- 构造参数：
  - ERC20代币合约地址（第一步部署的地址）
  - 平台费用接收者地址
- 依赖：必须在ERC20合约部署后进行
```

### 基本操作

#### 1. 上架NFT
```solidity
// NFT所有者需要先授权市场合约
nft.setApprovalForAll(marketAddress, true);

// 上架NFT，价格以ERC20代币为单位
market.listNFT(nftAddress, tokenId, price);
```

#### 2. 购买NFT - 传统方式
```solidity
// 买家先授权市场合约使用代币
token.approve(marketAddress, price);

// 购买指定的NFT
market.buyNFT(listingId);
```

#### 3. 购买NFT - 自动方式
```solidity
// 直接转账给市场合约，自动购买最便宜的NFT
token.transferWithCallback(marketAddress, amount);
```

### JavaScript示例

```javascript
// 连接合约
const token = await ethers.getContractAt("ExpendERC20", tokenAddress);
const nft = await ethers.getContractAt("MyNFT", nftAddress);
const market = await ethers.getContractAt("NFTMarketWithERC20", marketAddress);

// 上架NFT
await nft.setApprovalForAll(market.address, true);
await market.listNFT(nft.address, tokenId, ethers.parseEther("10"));

// 传统购买
await token.approve(market.address, ethers.parseEther("10"));
await market.buyNFT(listingId);

// 自动购买
await token.transferWithCallback(market.address, ethers.parseEther("10"));
```

## 技术特性

### 1. 回调机制
- 实现了`ITokenReceiver`接口
- 支持`tokensReceived`回调函数
- 自动处理代币接收和NFT购买

### 2. 安全机制
- **重入攻击防护**：使用OpenZeppelin的ReentrancyGuard
- **权限控制**：基于Ownable的管理员功能
- **暂停机制**：紧急情况下可暂停合约
- **零地址检查**：防止向零地址转账

### 3. 费用管理
- 可配置的平台费用百分比
- 自动计算和分配费用
- 支持紧急提取功能

### 4. 智能匹配
- 自动查找价格最低的可用NFT
- 支持多余代币自动退还
- 优化的查询算法

## 合约接口

### NFTMarketWithERC20主要函数

```solidity
// 上架NFT
function listNFT(address nftContract, uint256 tokenId, uint256 price) external;

// 传统购买
function buyNFT(uint256 listingId) external;

// 回调购买（由transferWithCallback触发）
function tokensReceived(address _from, address _to, uint256 _value) external;

// 下架NFT
function delistNFT(uint256 listingId) external;

// 更新价格
function updatePrice(uint256 listingId, uint256 newPrice) external;

// 查询函数
function getListing(uint256 listingId) external view returns (Listing memory);
function getUserListings(address user) external view returns (uint256[] memory);
```

### ExpendERC20主要函数

```solidity
// 标准ERC20函数
function transfer(address _to, uint256 _value) public returns (bool);
function transferFrom(address _from, address _to, uint256 _value) public returns (bool);
function approve(address _spender, uint256 _value) public returns (bool);
function balanceOf(address _owner) public view returns (uint256);

// 扩展函数
function transferWithCallback(address _to, uint256 _value) public returns (bool);
```

## 事件日志

```solidity
// NFT市场事件
event NFTListed(uint256 indexed listingId, address indexed nftContract, uint256 indexed tokenId, address seller, uint256 price);
event NFTSold(uint256 indexed listingId, address indexed nftContract, uint256 indexed tokenId, address seller, address buyer, uint256 price);
event NFTDelisted(uint256 indexed listingId, address indexed nftContract, uint256 indexed tokenId, address seller);
event PriceUpdated(uint256 indexed listingId, uint256 oldPrice, uint256 newPrice);

// ERC20事件
event Transfer(address indexed from, address indexed to, uint256 value);
event Approval(address indexed owner, address indexed spender, uint256 value);
```

## 测试用例

部署脚本包含了完整的测试流程：

1. ✅ 部署所有合约
2. ✅ 分发测试代币
3. ✅ 铸造测试NFT
4. ✅ 设置授权
5. ✅ 上架NFT
6. ✅ 传统购买测试
7. ✅ 回调购买测试
8. ✅ 验证所有权转移

## 注意事项

### 1. 授权要求
- NFT所有者必须授权市场合约：`setApprovalForAll(marketAddress, true)`
- 传统购买需要代币授权：`approve(marketAddress, amount)`

### 2. 价格单位
- 所有价格以ERC20代币为单位（18位小数）
- 最小价格默认为1 token

### 3. 自动购买逻辑
- `transferWithCallback`会自动购买最便宜的可用NFT
- 如果没有合适的NFT，交易会失败
- 多余的代币会自动退还

### 4. 费用计算
- 平台费用从NFT价格中扣除
- 卖家收到：`价格 - 平台费用`
- 平台收到：`价格 × 费用百分比 / 10000`

## 升级和扩展

### 可能的改进方向

1. **批量操作**：支持批量上架和购买
2. **拍卖功能**：添加拍卖机制
3. **报价系统**：支持买家出价
4. **多代币支持**：支持多种ERC20代币
5. **元数据索引**：改进NFT查询和过滤

### 兼容性

- Solidity ^0.8.25
- OpenZeppelin Contracts v4.x+
- 兼容标准ERC20和ERC721接口
- 支持Hardhat开发环境

## 许可证

MIT License - 详见各合约文件头部的SPDX许可证标识。