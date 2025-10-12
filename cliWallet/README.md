# Web3 命令行钱包

基于 Viem.js 构建的 Sepolia 测试网命令行钱包，支持私钥生成、余额查询、ERC20 转账等功能。

## 功能特性

- 🔑 **私钥生成**: 安全生成新的以太坊账户
- 📥 **账户导入**: 通过私钥导入现有账户
- 💰 **余额查询**: 查询 ETH 和 ERC20 代币余额
- 💸 **ERC20 转账**: 支持 EIP-1559 的 ERC20 代币转账
- 🔐 **交易签名**: 本地签名，私钥不离开设备
- 🌐 **Sepolia 网络**: 连接到 Sepolia 测试网络

## 安装依赖

```bash
npm install
```

## 环境配置

1. 复制环境变量模板：
```bash
copy .env.example .env
```

2. 编辑 `.env` 文件，配置 Sepolia RPC URL：
```env
SEPOLIA_RPC_URL=https://sepolia.infura.io/v3/YOUR_PROJECT_ID
ETHERSCAN_API_KEY=YOUR_ETHERSCAN_API_KEY
```

### 获取 RPC URL

你可以从以下服务商获取免费的 Sepolia RPC URL：

- **Infura**: https://infura.io/
- **Alchemy**: https://www.alchemy.com/
- **QuickNode**: https://www.quicknode.com/

## 使用方法

### 交互式模式（推荐）

启动交互式命令行界面：

```bash
npm start
```

或者：

```bash
node src/cli.js interactive
```

### 命令行模式

#### 生成新账户
```bash
node src/cli.js generate
```

#### 查询指定地址余额
```bash
node src/cli.js balance --address 0x1234567890123456789012345678901234567890
```

#### 查看帮助
```bash
node src/cli.js --help
```

## 项目结构

```
cliWallet/
├── src/
│   ├── wallet.js          # 钱包核心功能
│   └── cli.js             # 命令行界面
├── package.json           # 项目配置和依赖
├── .env.example          # 环境变量模板
├── .gitignore            # Git 忽略文件
└── README.md             # 项目说明
```

## 核心功能详解

### 1. 私钥生成

使用 Viem.js 的 `generatePrivateKey()` 函数安全生成私钥：

```javascript
const { privateKey, address } = wallet.generateAccount();
```

### 2. 账户导入

通过私钥导入现有账户：

```javascript
const address = wallet.importAccount('0x...');
```

### 3. 余额查询

支持查询 ETH 和 ERC20 代币余额：

```javascript
// 查询 ETH 余额
const ethBalance = await wallet.getETHBalance(address);

// 查询 ERC20 代币余额
const tokenInfo = await wallet.getERC20Balance(tokenAddress, address);
```

### 4. ERC20 转账

构建、签名并发送 EIP-1559 交易：

```javascript
// 一步完成转账
const hash = await wallet.sendERC20Transaction(tokenAddress, to, amount, decimals);

// 或者分步操作
const transaction = await wallet.buildERC20Transaction(tokenAddress, to, amount, decimals);
const signedTx = await wallet.signTransaction(transaction);
const hash = await wallet.sendSignedTransaction(signedTx);
```

## 安全注意事项

⚠️ **重要安全提醒**：

1. **私钥安全**: 
   - 私钥是您资产的唯一凭证
   - 不要与任何人分享私钥
   - 不要将私钥存储在不安全的地方

2. **测试网络**: 
   - 本钱包仅连接 Sepolia 测试网
   - 测试网代币没有实际价值
   - 正式使用前请充分测试

3. **环境变量**: 
   - 不要在 `.env` 文件中存储真实私钥
   - 将 `.env` 文件添加到 `.gitignore`

4. **代码审计**: 
   - 使用前请仔细审查代码
   - 理解每个功能的工作原理

## 获取测试代币

在 Sepolia 测试网上，你可以从以下水龙头获取免费的测试 ETH：

- **Sepolia Faucet**: https://sepoliafaucet.com/
- **Alchemy Faucet**: https://sepoliafaucet.net/
- **Infura Faucet**: https://www.infura.io/faucet/sepolia

## 常见问题

### Q: 如何获取 ERC20 代币合约地址？

A: 你可以在 Sepolia 测试网上部署自己的 ERC20 合约，或使用现有的测试代币。常见的测试代币地址可以在 Sepolia Etherscan 上找到。

### Q: 交易失败怎么办？

A: 检查以下几点：
- 账户是否有足够的 ETH 支付 gas 费用
- 代币合约地址是否正确
- 转账数量是否超过余额
- 网络连接是否正常

### Q: 如何查看交易详情？

A: 每次成功发送交易后，会显示交易哈希和 Etherscan 链接，点击链接可以查看详细的交易信息。

## 技术栈

- **Viem.js**: 现代化的以太坊 JavaScript 库
- **Commander.js**: 命令行参数解析
- **Inquirer.js**: 交互式命令行界面
- **Chalk**: 终端文本样式
- **Ora**: 终端加载动画

## 开发说明

### 添加新功能

1. 在 `src/wallet.js` 中添加核心功能
2. 在 `src/cli.js` 中添加命令行接口
3. 更新 README.md 文档

### 测试

建议在 Sepolia 测试网上充分测试所有功能后再使用。

## 许可证

MIT License

## 贡献

欢迎提交 Issue 和 Pull Request！

---

**免责声明**: 本项目仅用于学习和测试目的。使用前请确保理解相关风险，作者不承担任何资产损失责任。