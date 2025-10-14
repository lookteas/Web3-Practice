# Meme Factory - EIP-1167 最小代理 Meme 代币工厂

基于 EIP-1167 最小代理模式的 Meme 代币工厂合约，支持高效部署和铸造 ERC20 代币。

## 📋 项目概述

Meme Factory 是一个智能合约系统，允许用户以极低的 gas 成本部署和铸造 Meme 代币。通过使用 EIP-1167 最小代理模式，每个新代币的部署成本大大降低。

### 🎯 主要特性

- **EIP-1167 最小代理**: 使用最小代理模式，大幅降低部署成本
- **双核心方法**: `deployInscription` 和 `mintInscription`
- **灵活配置**: 支持自定义总供应量和每次铸造数量
- **安全保障**: 集成 ReentrancyGuard 和 Ownable
- **批量铸造**: 支持一次性铸造多个代币
- **完整查询**: 提供丰富的代币信息查询功能
- **费用管理**: 支持部署和铸造费用设置

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
forge test -vvv

# 运行特定测试
forge test --match-test testDeployInscription

# 生成测试覆盖率报告
forge coverage
```

## 🌐 部署指南

### 本地部署（Anvil）

1. **启动本地节点**:
```bash
anvil
```

2. **部署合约**:
```bash
forge script script/Deploy.s.sol --rpc-url anvil --broadcast --private-key $PRIVATE_KEY
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
// 调用工厂合约的 deployInscription 方法
address tokenAddress = factory.deployInscription{value: deploymentFee}(
    "PEPE",              // 代币符号
    1000000 * 10**18,    // 总供应量 (1M tokens)
    1000 * 10**18        // 每次铸造数量 (1K tokens)
);
```

### 2. 铸造代币

```solidity
// 单次铸造
factory.mintInscription{value: mintingFee}(tokenAddress);

// 批量铸造（最多5次）
factory.batchMintInscription{value: mintingFee * 3}(tokenAddress, 3);
```

### 3. 查询代币信息

```solidity
// 获取代币详细信息
(
    string memory name,
    string memory symbol,
    uint256 totalSupply,
    uint256 perMint,
    uint256 mintedAmount,
    uint256 remainingSupply,
    address deployer
) = factory.getTokenInfo(tokenAddress);

// 根据符号查找代币
address tokenAddr = factory.getTokenBySymbol("PEPE");

// 检查符号是否可用
bool available = factory.isSymbolAvailable("DOGE");
```

## 🔍 合约接口

### MemeFactory 主要方法

#### deployInscription
```solidity
function deployInscription(
    string memory symbol,
    uint256 totalSupply,
    uint256 perMint
) external payable returns (address tokenAddress)
```

#### mintInscription
```solidity
function mintInscription(address tokenAddr) external payable
```

#### batchMintInscription
```solidity
function batchMintInscription(address tokenAddr, uint256 count) external payable
```

### 查询方法

- `getTokenInfo(address)`: 获取代币详细信息
- `getDeployedTokens(uint256, uint256)`: 分页获取已部署代币
- `getTokenBySymbol(string)`: 根据符号获取代币地址
- `isSymbolAvailable(string)`: 检查符号可用性
- `getDeployedTokensCount()`: 获取已部署代币数量

### 管理员方法

- `setFees(uint256, uint256)`: 设置部署和铸造费用
- `withdraw()`: 提取合约余额
- `transferOwnership(address)`: 转移所有权

## 💰 费用结构

### 默认费用设置

| 网络 | 部署费用 | 铸造费用 |
|------|----------|----------|
| 本地 (Anvil) | 0 ETH | 0 ETH |
| Sepolia | 0.001 ETH | 0.0001 ETH |
| 主网 | 0.01 ETH | 0.001 ETH |

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
