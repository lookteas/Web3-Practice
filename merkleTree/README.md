# AirdropMerkleNFTMarket

基于 Merkle 树白名单验证的 NFT 空投市场合约，支持 ERC20 permit 授权和 multicall 批量操作。

## 项目概述

AirdropMerkleNFTMarket 是一个去中心化的 NFT 市场，专为空投活动设计。该项目包含三个核心合约：

1. **AirdropToken** - 支持 permit 授权的 ERC20 代币
2. **AirdropNFT** - 基础 NFT 合约，支持铸造和市场功能
3. **AirdropMerkleNFTMarket** - 主要市场合约，集成 Merkle 树验证和折扣机制

## 核心功能

### 🎯 Merkle 树白名单验证
- 使用 Merkle 树高效验证用户白名单资格
- 支持动态更新 Merkle 根哈希
- 防止重复领取机制

### 💰 折扣机制
- 白名单用户享受 50% 折扣
- 自动计算折扣价格
- 透明的价格计算逻辑

### 🔐 Permit 授权
- 支持 EIP-2612 permit 标准
- 无需预先授权，节省 gas 费用
- 支持元交易和批量操作

### 🚀 Multicall 功能
- 使用 delegatecall 实现批量操作
- 支持在单笔交易中完成 permit 和购买
- 提升用户体验和操作效率

## 合约架构

```
AirdropMerkleNFTMarket
├── AirdropToken (ERC20 + Permit)
├── AirdropNFT (ERC721 + Marketplace)
└── Merkle Tree Verification
```

## 技术规格

- **Solidity 版本**: 0.8.25
- **开发框架**: Foundry
- **依赖库**: OpenZeppelin Contracts v5.x
- **测试覆盖**: 100% 核心功能测试

## 快速开始

### 环境要求

- [Foundry](https://book.getfoundry.sh/getting-started/installation)
- Git

### 安装依赖

```bash
# 克隆项目
git clone <repository-url>
cd merkleTree

# 安装依赖
forge install

# 编译合约
forge build
```

### 运行测试

```bash
# 运行所有测试
forge test

# 运行详细测试
forge test -vv

# 运行特定测试
forge test --match-test testClaimNFT
```

### 部署合约

```bash
# 本地模拟部署
forge script script/Deploy.s.sol

# 部署到测试网（需要配置 RPC 和私钥）
forge script script/Deploy.s.sol --rpc-url <RPC_URL> --private-key <PRIVATE_KEY> --broadcast
```

## 合约详解

### AirdropToken

支持 permit 授权的 ERC20 代币合约。

**主要功能：**
- 标准 ERC20 功能
- EIP-2612 permit 支持
- 铸造和销毁功能
- 所有者权限管理

**关键方法：**
```solidity
function permit(address owner, address spender, uint256 value, uint256 deadline, uint8 v, bytes32 r, bytes32 s) external
function mint(address to, uint256 amount) external onlyOwner
function burn(uint256 amount) external
```

### AirdropNFT

基础 NFT 合约，集成市场功能。

**主要功能：**
- ERC721 标准实现
- NFT 铸造和元数据管理
- 市场上架/下架功能
- 价格管理

**关键方法：**
```solidity
function mint(address to, string memory tokenURI) external onlyOwner returns (uint256)
function listToken(uint256 tokenId, uint256 price) external
function unlistToken(uint256 tokenId) external
function updateTokenPrice(uint256 tokenId, uint256 newPrice) external
```

### AirdropMerkleNFTMarket

主要市场合约，实现核心业务逻辑。

**主要功能：**
- Merkle 树白名单验证
- 折扣价格计算
- Permit 预付款
- NFT 领取
- Multicall 批量操作

**关键方法：**
```solidity
function verifyWhitelist(address user, bytes32[] calldata proof) public view returns (bool)
function permitPrePay(uint256 value, uint256 deadline, uint8 v, bytes32 r, bytes32 s) external
function claimNFT(uint256 tokenId, bytes32[] calldata proof) external nonReentrant
function multicall(bytes[] calldata data) external returns (bytes[] memory results)
```

## 使用示例

### 1. 生成 Merkle 树

```javascript
// 使用 JavaScript 生成 Merkle 树
const { MerkleTree } = require('merkletreejs');
const keccak256 = require('keccak256');

const addresses = [
    '0x1234567890123456789012345678901234567890',
    '0x2345678901234567890123456789012345678901',
    '0x3456789012345678901234567890123456789012'
];

const leaves = addresses.map(addr => keccak256(addr));
const tree = new MerkleTree(leaves, keccak256, { sortPairs: true });
const root = tree.getHexRoot();

console.log('Merkle Root:', root);
```

### 2. 获取 Merkle 证明

```javascript
const leaf = keccak256('0x1234567890123456789012345678901234567890');
const proof = tree.getHexProof(leaf);
console.log('Merkle Proof:', proof);
```

### 3. 使用 Multicall 购买 NFT

```solidity
// 准备 multicall 数据
bytes[] memory calls = new bytes[](2);

// 第一个调用：permitPrePay
calls[0] = abi.encodeWithSelector(
    market.permitPrePay.selector,
    discountedPrice,
    deadline,
    v, r, s
);

// 第二个调用：claimNFT
calls[1] = abi.encodeWithSelector(
    market.claimNFT.selector,
    tokenId,
    proof
);

// 执行 multicall
market.multicall(calls);
```

## 安全特性

### 🛡️ 重入攻击防护
- 使用 OpenZeppelin 的 ReentrancyGuard
- 关键函数添加 nonReentrant 修饰符

### 🔒 权限控制
- 基于 Ownable 的权限管理
- 关键操作仅限所有者执行

### ✅ 输入验证
- 完整的参数验证
- 自定义错误信息
- 边界条件检查

### 🚫 防重复领取
- 地址级别的领取状态跟踪
- 防止同一用户多次领取

## Gas 优化

- 使用 immutable 变量减少存储读取
- 批量操作减少交易次数
- 高效的 Merkle 树验证
- 优化的存储布局

## 测试覆盖

项目包含全面的测试用例：

- ✅ Merkle 树验证测试
- ✅ Permit 授权测试
- ✅ NFT 领取测试
- ✅ Multicall 功能测试
- ✅ 错误情况测试
- ✅ 权限控制测试

## 部署地址

### 本地测试部署

```
AirdropToken: 0x5FbDB2315678afecb367f032d93F642f64180aa3
AirdropNFT: 0xe7f1725E7734CE288F8367e1Bb143E90bb3F0512
AirdropMerkleNFTMarket: 0x9fE46736679d2D9a65F0992F2272dE9f3c7fa6e0
```

## 贡献指南

1. Fork 项目
2. 创建功能分支 (`git checkout -b feature/AmazingFeature`)
3. 提交更改 (`git commit -m 'Add some AmazingFeature'`)
4. 推送到分支 (`git push origin feature/AmazingFeature`)
5. 开启 Pull Request

## 许可证

本项目采用 MIT 许可证 - 查看 [LICENSE](LICENSE) 文件了解详情。

## 致谢

- [OpenZeppelin](https://openzeppelin.com/) - 安全的智能合约库
- [Foundry](https://book.getfoundry.sh/) - 快速的智能合约开发框架
- [Merkle Tree](https://en.wikipedia.org/wiki/Merkle_tree) - 高效的数据验证结构
