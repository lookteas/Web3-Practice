# 🏦 ChainLink 自动化银行合约

基于 Solidity 0.8.25 和 ChainLink Automation 的智能合约自动化演示项目。当银行合约的存款超过设定阈值时，自动转移一半存款到合约所有者地址。

## 📋 项目概述

本项目实现了一个支持 ChainLink Automation 的银行合约，具有以下核心功能：

- ✅ 用户存款和提取功能
- ✅ 基于阈值的自动化触发机制
- ✅ ChainLink Automation 集成
- ✅ 安全的资金管理
- ✅ 现代化的 Web 前端界面

## 🏗️ 项目结构

```
chainLink/
├── Bank.sol              # 主合约文件
├── deploy.js             # 部署脚本
├── package.json          # 项目依赖
├── .env.example          # 环境变量示例
├── index.html            # 前端界面
├── app.js               # 前端逻辑
└── README.md            # 项目文档
```

## 🔧 核心功能

### 智能合约功能

1. **存款功能** (`deposit()`)
   - 用户可以向合约存入 ETH
   - 记录每个用户的存款余额
   - 触发存款事件

2. **提取功能** (`withdraw()`)
   - 用户可以提取自己的存款
   - 安全检查确保余额充足

3. **自动化检查** (`checkUpkeep()`)
   - 检查总存款是否超过阈值
   - 验证时间间隔是否满足（最小1小时）
   - 确认合约余额充足

4. **自动化执行** (`performUpkeep()`)
   - 当条件满足时自动执行
   - 转移一半存款到合约所有者
   - 更新相关状态变量

5. **管理功能**
   - 更新触发阈值（仅所有者）
   - 紧急提取功能（仅所有者）
   - 状态查询功能

### ChainLink Automation 集成

本合约完全兼容 ChainLink Automation 标准：

- 实现了 `checkUpkeep()` 接口用于条件检查
- 实现了 `performUpkeep()` 接口用于自动执行
- 支持链下计算和链上执行的分离

## 🚀 快速开始

### 环境要求

- Node.js >= 16.0.0
- MetaMask 钱包
- Sepolia 测试网 ETH
- 合约地址 ： 0xcE3BE1592Ec695FF5c311839f3b1399158f6AbaB

### 技术栈更新

- **前端框架**: 原生 HTML/CSS/JavaScript
- **Web3 库**: Ethers.js v6.x
- **智能合约**: Solidity 0.8.25
- **自动化服务**: ChainLink Automation
- **测试网络**: Sepolia

### 1. 安装依赖

```bash
npm install
```

### 2. 配置环境变量

复制 `.env.example` 为 `.env` 并填入配置：

```bash
cp .env.example .env
```

编辑 `.env` 文件：

```env
RPC_URL=https://sepolia.infura.io/v3/YOUR_INFURA_KEY
PRIVATE_KEY=your_private_key_here
DEFAULT_THRESHOLD=1000000000000000000  # 1 ETH
```

### 3. 编译和部署合约

#### 使用 Remix IDE（推荐）

1. 打开 [Remix IDE](https://remix.ethereum.org/)
2. 创建新文件并复制 `Bank.sol` 内容
3. 编译合约（Solidity 0.8.25）
4. 连接 MetaMask 到 Sepolia 测试网
5. 部署合约，设置初始阈值（如 1 ETH = 1000000000000000000 wei）


```

### 4. 启动前端界面

直接在浏览器中打开 `index.html` 文件，或使用本地服务器：

```bash
# 使用 Python 启动本地服务器
python -m http.server 8000

# 或使用 Node.js
npx http-server
```

**注意**: 前端已升级到 Ethers.js v6，具有以下改进：
- 更现代的 API 设计
- 更好的类型安全性
- 优化的性能表现
- 使用 CDN 加载，无需本地安装

## 📖 使用指南

### 前端操作步骤

1. **连接钱包**
   - 点击"连接钱包"按钮
   - 确保连接到 Sepolia 测试网

2. **设置合约地址**
   - 在"合约地址"输入框中输入已部署的合约地址
   - 系统会自动验证地址有效性

3. **存款操作**
   - 输入存款金额（ETH）
   - 点击"存款"按钮
   - 确认 MetaMask 交易

4. **监控自动化状态**
   - 查看"ChainLink Automation 状态"面板
   - 点击"检查 Upkeep 状态"更新状态
   - 当所有条件满足时，可手动执行或等待自动执行

### 命令行操作

```bash
# 验证合约状态
npm run verify <合约地址>

# 测试存款
npm run test-deposit <合约地址> <金额>

# 检查 Upkeep 状态
npm run check-upkeep <合约地址>
```

## 🔐 安全特性

1. **重入攻击防护**
   - 使用 checks-effects-interactions 模式
   - 状态更新在外部调用之前

2. **权限控制**
   - 只有合约所有者可以更新阈值
   - 只有合约所有者可以紧急提取

3. **条件验证**
   - `performUpkeep()` 中重新验证所有条件
   - 防止恶意调用

4. **时间锁定**
   - 最小1小时的转账间隔
   - 防止频繁自动转账

## 📊 ChainLink Automation 设置

### 在 ChainLink Automation 平台注册

1. 访问 [ChainLink Automation](https://automation.chain.link/)
2. 连接钱包并选择 Sepolia 网络
3. 点击"Register New Upkeep"
4. 填写以下信息：
   - **Target contract address**: 您的合约地址
   - **Admin address**: 管理员地址
   - **Gas limit**: 500,000
   - **Starting balance**: 5 LINK（用于支付 gas 费用）
   - **Check data**: 0x（空字节）

### 获取 LINK 代币

在 Sepolia 测试网上，您可以从以下水龙头获取 LINK 代币：
- [ChainLink Faucet](https://faucets.chain.link/)

## 🧪 测试场景

### 场景1：正常自动化流程

1. 部署合约，设置阈值为 1 ETH
2. 多个用户存款，总额超过 1 ETH
3. 等待1小时后，ChainLink Automation 自动执行转账
4. 验证一半存款已转移到所有者地址

### 场景2：手动触发

1. 存款超过阈值且时间间隔满足
2. 在前端点击"手动执行 Upkeep"
3. 验证转账执行成功

### 场景3：条件不满足

1. 存款未达到阈值
2. 验证 `checkUpkeep()` 返回 false
3. 确认不会执行自动转账

## 🔍 事件监听

合约发出以下事件，可用于监控和分析：

```solidity
event Deposit(address indexed user, uint256 amount, uint256 newTotal);
event AutoTransfer(uint256 amount, uint256 remainingBalance, uint256 timestamp);
event ThresholdUpdated(uint256 oldThreshold, uint256 newThreshold);
event Withdrawal(address indexed user, uint256 amount);
```

## 🐛 故障排除

### 常见问题

1. **交易失败**
   - 检查 gas 费用是否充足
   - 确认网络连接正常
   - 验证合约地址正确

2. **Upkeep 不执行**
   - 确认条件是否全部满足
   - 检查 LINK 余额是否充足
   - 验证时间间隔是否达到

3. **前端连接问题**
   - 确认 MetaMask 已安装并解锁
   - 检查网络是否为 Sepolia
   - 刷新页面重新连接

### 调试工具

```javascript
// 在浏览器控制台中检查合约状态（Ethers.js v6 语法）
const provider = new ethers.BrowserProvider(window.ethereum);
const contract = new ethers.Contract(address, abi, provider);
await contract.getUpkeepStatus();

// 检查钱包连接状态
const signer = await provider.getSigner();
console.log('当前账户:', await signer.getAddress());

// 格式化金额显示
const balance = await contract.balances(userAddress);
console.log('用户余额:', ethers.formatEther(balance), 'ETH');
```

## 🤝 贡献指南

欢迎提交 Issue 和 Pull Request！

1. Fork 本仓库
2. 创建功能分支
3. 提交更改
4. 发起 Pull Request

## 📄 许可证

MIT License - 详见 LICENSE 文件

## 🔗 相关链接

- [ChainLink Automation 文档](https://docs.chain.link/chainlink-automation/introduction)
- [Solidity 官方文档](https://docs.soliditylang.org/)
- [Ethers.js v6 文档](https://docs.ethers.org/v6/)


## ⚠️ 免责声明

本项目仅用于学习和演示目的。请勿在主网使用真实资金进行测试。使用前请充分了解智能合约的风险。

---