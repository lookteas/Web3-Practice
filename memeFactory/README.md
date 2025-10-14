# Meme Factory 最小代理 Meme 代币工厂

基于 EIP-1167 最小代理模式的 Meme 代币工厂合约，支持部署和铸造 ERC20 代币。



## 📋 项目概述

Meme Factory 是一个智能合约系统，允许用户以极低的 gas 成本部署和铸造 Meme 代币。通过使用 EIP-1167 最小代理模式，每个新代币的部署成本大大降低。

### 🎯 主要特性

- **EIP-1167 最小代理**: 使用最小代理模式，大幅降低部署成本
- **双核心方法**: `deployMeme` 和 `mintMeme`
- **灵活配置**: 支持自定义总供应量、每次铸造数量和铸造价格
- **费用分配机制**: 智能费用分配，1% 给项目方，99% 给代币发行者
- **安全保障**: 集成 ReentrancyGuard 和 Ownable
- **批量铸造**: 支持一次性铸造多个代币
- **完整查询**: 提供丰富的代币信息查询功能
- **价格管理**: 每个代币可设置独立的铸造价格

## 🏗️ 项目结构

```
memeFactory/
├── src/
│   ├── MemeToken.sol      # ERC20 代币实现合约
│   └── MemeFactory.sol    # 工厂合约
├── script/
│   └── Deploy.s.sol       # 部署脚本
├── test/
│   └── MemeFactory.t.sol  # 测试文件
├── foundry.toml           # Foundry 配置
└── README.md              # 项目文档
```

## 🔧 技术栈

- **Solidity**: ^0.8.25
- **OpenZeppelin**: 5.0.2
- **Foundry**: 构建和测试框架
- **EIP-1167**: 最小代理标准

## 📦 安装和设置

### 1. 克隆项目

```bash
git clone <repository-url>
cd memeFactory
```

### 2. 安装依赖

```bash
forge install
```

### 3. 环境配置

创建 `.env` 文件：

```bash
# 私钥（用于部署）
PRIVATE_KEY=your_private_key_here

# API 密钥
INFURA_API_KEY=your_infura_api_key
ALCHEMY_API_KEY=your_alchemy_api_key
ETHERSCAN_API_KEY=your_etherscan_api_key
```

## 🚀 编译和测试

### 编译合约

```bash
# 编译所有合约
forge build

# 检查合约大小
forge build --sizes
```

### 运行测试

```bash
# 运行所有测试
forge test

# 运行详细测试
forge test -vv

# 运行超详细测试（显示所有日志）
forge test -vvv

# 运行特定测试函数
forge test --match-test testDeployMeme

# 运行特定测试合约
forge test --match-contract MemeFactoryTest

# 生成测试覆盖率报告
forge coverage

# 生成 Gas 使用报告
forge test --gas-report
```

### 🧪 测试功能详解

#### 基础功能测试
```bash
# 测试代币部署功能
forge test --match-test testDeployMeme -vv
# 验证：代币合约正确部署，参数设置正确

# 测试代币铸造功能
forge test --match-test testMintMeme -vv
# 验证：用户可以支付费用铸造代币

# 测试批量铸造功能
forge test --match-test testBatchMintMeme -vv
# 验证：用户可以一次铸造多个代币
```

#### 费用分配测试
```bash
# 测试费用分配机制
forge test --match-test testFeeDistribution -vv
# 验证：1% 费用给项目方，99% 费用给发行者

# 测试价格参数验证
forge test --match-test testDeployMemeInvalidParams -vv
# 验证：价格为 0 时部署失败

# 测试支付金额验证
forge test --match-test testMintMemeInvalidToken -vv
# 验证：支付金额不足时铸造失败
```

#### 边界条件测试
```bash
# 测试重复符号
forge test --match-test testDuplicateSymbol -vv
# 验证：相同符号不能重复部署

# 测试铸造限制
forge test --match-test testMintLimit -vv
# 验证：不能超过总供应量铸造

# 测试批量铸造数量限制
forge test --match-test testBatchMintInvalidCount -vv
# 验证：批量铸造数量不能超过5次
```

#### 查询功能测试
```bash
# 测试代币信息查询
forge test --match-test testGetTokenInfo -vv
# 验证：正确返回代币的所有信息（包含价格）

# 测试符号查询
forge test --match-test testGetTokenBySymbol -vv
# 验证：根据符号正确查找代币地址

# 测试符号可用性检查
forge test --match-test testIsSymbolAvailable -vv
# 验证：正确判断符号是否已被使用
```

#### 权限控制测试
```bash
# 测试余额提取
forge test --match-test testWithdrawBalance -vv
# 验证：只有所有者可以提取合约余额

# 测试费用设置
forge test --match-test testSetFees -vv
# 验证：只有所有者可以设置费用
```

#### 性能测试
```bash
# 测试部署 Gas 消耗
forge test --match-test testDeploymentGasUsage -vv
# 验证：使用最小代理模式大幅降低 Gas 消耗

# 测试多代币部署
forge test --match-test testMultipleTokens -vv
# 验证：可以部署多个不同价格的代币
```

## 🌐 部署指南

### 本地部署（Anvil）

1. **启动本地节点**:
```bash
anvil --port 8546
```

2. **部署合约**:
```bash
forge script script/Deploy.s.sol --rpc-url http://localhost:8546 --broadcast --private-key 0xac097...(你的私钥地址)
```

3. **验证部署结果**:
```bash
# 查看部署日志，记录合约地址
# Factory 地址: 0x5FbDB2315678afecb367f032d93F642f64180aa3
# Implementation 地址: 0xa16E02E87b7454126E5E10d957A927A7F5B5d2be
```

### 🧪 功能测试命令

#### 1. 部署代币测试
```bash
# 部署 BOSE 代币（价格：2 ETH）
cast send 0x5FbDB2315678afecb367f032d93F642f64180aa3 \
  "deployMeme(string,uint256,uint256,uint256)" \
  "BOSE" 1000000000000000000000000 100000000000000000000000 2000000000000000000 \
  --rpc-url http://localhost:8546 \
  --private-key 0xac097...(你的私钥地址)

# 查询 BOSE 代币地址
cast call 0x5FbDB2315678afecb367f032d93F642f64180aa3 \
  "getTokenBySymbol(string)" "BOSE" \
  --rpc-url http://localhost:8546
```

#### 2. 代币铸造测试
```bash
# 铸造 BOSE 代币（支付 2 ETH）
cast send 0x5FbDB2315678afecb367f032d93F642f64180aa3 \
  "mintMeme(address)" 0xb7a5bd0345ef1cc5e66bf61bdec17d2461fbd968 \
  --value 2000000000000000000 \
  --rpc-url http://localhost:8546 \
  --private-key 0xac097...(你的私钥地址)

# 查询用户代币余额
cast call 0xb7a5bd0345ef1cc5e66bf61bdec17d2461fbd968 \
  "balanceOf(address)" 0xf39Fd6e51aad88F6F4ce6aB8827279cffFb92266 \
  --rpc-url http://localhost:8546
```

#### 3. 费用分配验证
```bash
# 查询项目方余额（应该收到 1% 费用）
cast balance 0xf39Fd6e51aad88F6F4ce6aB8827279cffFb92266 \
  --rpc-url http://localhost:8546

# 查询发行者余额（应该收到 99% 费用）
cast balance 0xf39Fd6e51aad88F6F4ce6aB8827279cffFb92266 \
  --rpc-url http://localhost:8546
```

#### 4. 代币信息查询测试
```bash
# 查询代币详细信息
cast call 0x5FbDB2315678afecb367f032d93F642f64180aa3 \
  "getTokenInfo(address)" 0xb7a5bd0345ef1cc5e66bf61bdec17d2461fbd968 \
  --rpc-url http://localhost:8546

# 查询代币价格
cast call 0x5FbDB2315678afecb367f032d93F642f64180aa3 \
  "tokenToPrice(address)" 0xb7a5bd0345ef1cc5e66bf61bdec17d2461fbd968 \
  --rpc-url http://localhost:8546
```

#### 5. 批量铸造测试
```bash
# 批量铸造 3 次（支付 6 ETH）
cast send 0x5FbDB2315678afecb367f032d93F642f64180aa3 \
  "batchMintMeme(address,uint256)" 0xb7a5bd0345ef1cc5e66bf61bdec17d2461fbd968 3 \
  --value 6000000000000000000 \
  --rpc-url http://localhost:8546 \
  --private-key 0xac097...(你的私钥地址)
```

### Sepolia 测试网部署

1. **部署到 Sepolia**:
```bash
forge script script/Deploy.s.sol --rpc-url sepolia --broadcast --private-key $PRIVATE_KEY --verify
```

2. **验证合约**:
```bash
forge verify-contract <contract_address> src/MemeFactory.sol:MemeFactory --chain sepolia
```

### 主网部署

```bash
forge script script/Deploy.s.sol --rpc-url mainnet --broadcast --private-key $PRIVATE_KEY --verify
```

## 📖 使用指南

### 1. 部署新的 Meme 代币

```solidity
// 调用工厂合约的 deployMeme 方法
address tokenAddress = factory.deployMeme{value: deploymentFee}(
    "PEPE",              // 代币符号
    1000000 * 10**18,    // 总供应量 (1M tokens)
    1000 * 10**18,       // 每次铸造数量 (1K tokens)
    0.001 ether          // 铸造价格 (0.001 ETH per mint)
);
```

### 2. 铸造代币

```solidity
// 单次铸造 - 需要支付代币设定的价格
factory.mintMeme{value: tokenPrice}(tokenAddress);

// 批量铸造（最多5次）- 需要支付总价格
factory.batchMintMeme{value: tokenPrice * 3}(tokenAddress, 3);
```

### 3. 费用分配机制

当用户铸造代币时，支付的费用会自动分配：
- **1%** 费用给项目方（合约所有者）
- **99%** 费用给代币发行者

```solidity
// 例如：用户支付 1 ETH 铸造代币
// 项目方收到：0.01 ETH
// 发行者收到：0.99 ETH
```

### 4. 查询代币信息

```solidity
// 获取代币详细信息（包含价格）
(
    string memory name,
    string memory symbol,
    uint256 totalSupply,
    uint256 perMint,
    uint256 mintedAmount,
    uint256 remainingSupply,
    uint256 price,
    address deployer
) = factory.getTokenInfo(tokenAddress);

// 根据符号查找代币
address tokenAddr = factory.getTokenBySymbol("PEPE");

// 检查符号是否可用
bool available = factory.isSymbolAvailable("PEPE");

// 查询代币价格
uint256 price = factory.tokenToPrice(tokenAddress);
```

## 🔍 合约接口

### MemeFactory 主要方法

#### deployMeme
```solidity
function deployMeme(
    string memory symbol,
    uint256 totalSupply,
    uint256 perMint,
    uint256 price
) external payable returns (address tokenAddress)
```
部署新的 Meme 代币，设置代币符号、总供应量、每次铸造数量和铸造价格。

#### mintMeme
```solidity
function mintMeme(address tokenAddr) external payable
```
铸造指定代币，需要支付该代币设定的价格。费用自动分配给项目方和发行者。

#### batchMintMeme
```solidity
function batchMintMeme(address tokenAddr, uint256 count) external payable
```
批量铸造代币，最多支持5次铸造。需要支付总价格（单价 × 数量）。

### 查询方法

- `getTokenInfo(address)`: 获取代币详细信息（包含价格）
- `getDeployedTokens(uint256, uint256)`: 分页获取已部署代币
- `getTokenBySymbol(string)`: 根据符号获取代币地址
- `isSymbolAvailable(string)`: 检查符号可用性
- `getDeployedTokensCount()`: 获取已部署代币数量
- `tokenToPrice(address)`: 查询代币铸造价格

### 管理员方法

- `setFees(uint256, uint256)`: 设置部署和铸造费用
- `withdraw()`: 提取合约余额
- `transferOwnership(address)`: 转移所有权

## 💰 费用结构

### 费用分配机制

当用户铸造代币时，支付的费用会按以下比例自动分配：

| 接收方 | 比例 | 说明 |
|--------|------|------|
| 项目方（合约所有者） | 1% | 平台维护费用 |
| 代币发行者 | 99% | 激励发行者创建优质代币 |

### 示例费用计算

```bash
# 用户支付 1 ETH 铸造代币
总费用: 1.000 ETH
├── 项目方收入: 0.010 ETH (1%)
└── 发行者收入: 0.990 ETH (99%)

# 用户支付 0.1 ETH 铸造代币  
总费用: 0.100 ETH
├── 项目方收入: 0.001 ETH (1%)
└── 发行者收入: 0.099 ETH (99%)
```

### 默认费用设置

| 网络 | 部署费用 | 说明 |
|------|----------|------|
| 本地 (Anvil) | 0 ETH | 测试环境免费 |
| Sepolia | 0.001 ETH | 测试网络低费用 |
| 主网 | 0.01 ETH | 主网部署费用 |

**注意**: 铸造费用由各代币发行者自行设定，平台不收取固定铸造费用。

## 🔒 安全特性

### 1. 重入攻击防护
- 使用 OpenZeppelin 的 `ReentrancyGuard`
- 所有状态修改函数都有 `nonReentrant` 修饰符

### 2. 访问控制
- 使用 `Ownable` 模式管理管理员权限
- 关键函数仅限所有者调用

### 3. 输入验证
- 严格的参数验证
- 防止无效或恶意输入

### 4. 溢出保护
- Solidity 0.8+ 内置溢出检查
- 使用 SafeMath 概念

## 🧪 测试覆盖

测试套件包含以下测试类别：

- ✅ 基础功能测试
- ✅ 边界条件测试
- ✅ 错误处理测试
- ✅ 权限控制测试
- ✅ 批量操作测试
- ✅ 查询功能测试
- ✅ Gas 优化测试

运行测试：
```bash
forge test --gas-report
```

## 📊 Gas 优化

### EIP-1167 优势

传统部署 vs 最小代理部署：

| 方式 | 部署 Gas | 节省比例 |
|------|----------|----------|
| 传统部署 | ~2,000,000 | - |
| 最小代理 | ~200,000 | ~90% |

### 优化策略

1. **使用最小代理模式**: 大幅降低部署成本
2. **批量操作**: 支持批量铸造减少交易次数
3. **存储优化**: 合理使用 storage 和 memory
4. **事件优化**: 精简事件参数

## 🔧 配置说明

### foundry.toml 配置

```toml
[profile.default]
src = "src"
out = "out"
libs = ["lib"]
solc = "0.8.25"
optimizer = true
optimizer_runs = 200

[rpc_endpoints]
anvil = "http://127.0.0.1:8545"
sepolia = "https://sepolia.infura.io/v3/${INFURA_API_KEY}"

[etherscan]
sepolia = { key = "${ETHERSCAN_API_KEY}" }
```

## 🚨 注意事项

### 1. 私钥安全
- 永远不要在代码中硬编码私钥
- 使用环境变量或硬件钱包
- 定期轮换私钥

### 2. 网络选择
- 测试先在 Sepolia 进行
- 主网部署前进行充分测试
- 注意不同网络的 gas 价格

### 3. 费用设置
- 根据网络情况调整费用
- 考虑用户体验和收益平衡
- 定期评估和调整

## 🛠️ 故障排除

### 常见问题

1. **编译错误**
   ```bash
   # 清理缓存重新编译
   forge clean
   forge build
   ```

2. **测试失败**
   ```bash
   # 运行详细测试查看错误
   forge test -vvv
   ```

3. **部署失败**
   - 检查私钥和网络配置
   - 确认账户有足够的 ETH
   - 验证 RPC 端点可用性

### 调试技巧

```bash
# 使用 console.log 调试
forge test --match-test testName -vvv

# 检查合约字节码
forge inspect MemeFactory bytecode

# 分析 gas 使用
forge test --gas-report
```

## 📚 参考资料

- [EIP-1167: Minimal Proxy Contract](https://eips.ethereum.org/EIPS/eip-1167)
- [OpenZeppelin Contracts](https://docs.openzeppelin.com/contracts/)
- [Foundry Book](https://book.getfoundry.sh/)
- [Solidity Documentation](https://docs.soliditylang.org/)

## 🤝 贡献指南

1. Fork 项目
2. 创建功能分支
3. 提交更改
4. 推送到分支
5. 创建 Pull Request

## 📄 许可证

MIT License - 详见 LICENSE 文件

## 📞 联系方式

如有问题或建议，请通过以下方式联系：

- GitHub Issues
- Email: [your-email@example.com]
- Discord: [your-discord]

---

**⚠️ 免责声明**: 本项目仅用于教育和研究目的。在生产环境中使用前，请进行充分的安全审计。
