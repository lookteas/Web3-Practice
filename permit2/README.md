# 🏦 Permit2 银行合约项目

基于 Foundry 开发的 DeFi 项目，实现支持 Permit2 签名授权的银行合约系统。

## 📋 项目概述

展示如何使用 Permit2 协议实现无需预先授权的代币转账，包含：

- **ERC20 代币合约**：支持 EIP-2612 Permit 的 SUI Token
- **Permit2 合约**：Uniswap Permit2 协议实现
- **Bank 合约**：支持 ETH 存取款和 Permit2 代币存款
- **前端界面**：完整的 Web3 交互界面，支持 ETH 和 ERC20 分离显示

<img src="./image/1.jpg" style="zoom:80%;" />

## 🏗️ 项目结构

```
permit2/
├── contracts/           # 智能合约
│   ├── Bank.sol        # 银行合约
│   ├── ERC20.sol       # SUI Token 合约
│   ├── Permit2.sol     # Permit2 协议合约
│   └── IPermit2.sol    # Permit2 接口
├── test/               # 测试文件
├── script/             # 部署脚本
└── index.html          # 完整的前端测试界面
```

## ✨ 核心功能

### 智能合约功能
- **ERC20 Token**：标准功能 + EIP-2612 Permit 签名授权
- **Permit2 协议**：批量授权、时间限制、防重放攻击
- **Bank 合约**：ETH 存取款、Permit2 代币存款、存款排行榜

### 前端界面功能
- **钱包连接**：MetaMask 钱包集成
- **代币管理**：获取、铸造、转账 ERC20 代币
- **Permit2 授权**：安全的签名授权机制
- **银行操作**：
  - ETH 存款/提款（分离显示）
  - ERC20 存款（通过 Permit2）
  - 存款查询（支持 ETH 和 ERC20 分离显示）
  - 合约余额查询
  - 存款排行榜查询

## 🎯 特色功能

### ETH 和 ERC20 分离显示
通过事件日志分析，实现了 ETH 和 ERC20 存款的精确分离显示：
- **ETH 存款**：通过 `Deposit` 事件追踪
- **ERC20 存款**：通过 `DepositWithPermit2` 事件追踪
- **综合查询**：同时显示银行存款和钱包余额

### 安全的 Permit2 机制
- 无需预先授权即可进行代币转账
- 支持批量操作和时间限制
- 防重放攻击保护

## 🚀 快速开始

### 环境要求
- [Foundry](https://book.getfoundry.sh/getting-started/installation)
- [MetaMask](https://metamask.io/) 钱包
- Python 3.x（用于启动本地服务器）

### 使用步骤
```bash
# 1. 克隆项目
git clone <repository-url>
cd permit2

# 2. 安装依赖
forge install

# 3. 编译合约
forge build

# 4. 运行测试
forge test -vv

# 5. 启动本地网络
anvil --chain-id 1337 --host 0.0.0.0 --port 8545

# 6. 部署合约（新终端）
forge script script/Deploy.s.sol --rpc-url http://localhost:8545 --broadcast

# 7. 启动前端服务
python -m http.server 8080

# 8. 访问前端界面
# 浏览器打开: http://localhost:8080
```

## 📊 合约地址 (本地网络部署后会显示)

```
ERC20Token:  0x5FbDB2315678afecb367f032d93F642f64180aa3
Permit2:     0xe7f1725E7734CE288F8367e1Bb143E90bb3F0512
Bank:        0x9fE46736679d2D9a65F0992F2272dE9f3c7fa6e0
```

## 🔧 使用指南





### 1. 连接钱包
- 点击"连接 MetaMask"按钮
- 确保钱包连接到本地网络（Chain ID: 1337）

<img src="./image/2.jpg" style="zoom:80%;" />



### 2. 获取测试代币
- 在"获取 ERC20代币"区域铸造 SUI Token
- 建议铸造 10000 个代币用于测试

<img src="D:\code\web3\Web3-Practice\permit2\image\4.jpg" style="zoom:80%;" />

### 3. Permit2 授权
- 授权 Permit2 合约管理你的代币
- 查询当前授权状态

<img src="./image/5.jpg" style="zoom:80%;" />

### 4. 银行操作
- **ETH 存款**：直接存入 ETH 到银行合约
- **ERC20 存款**：使用 Permit2 签名机制存入代币
- **查询功能**：
  - 查询我的 ETH 存款
  - 查询我的 ERC20 存款
  - 查询我的所有存款（分离显示）
  - 查询合约余额
  - 查询存款排行榜

<img src="./image/7.jpg" style="zoom:80%;" />



## 📝 更新日志

### v2.0.0 (最新)
- ✅ 实现 ETH 和 ERC20 存款分离显示
- ✅ 通过事件日志精确追踪存款记录
- ✅ 优化前端界面布局和用户体验
- ✅ 完善查询功能，支持综合显示
- ✅ 移动 Permit2 授权查询按钮到合适位置

### v1.0.0
- ✅ 基础 Permit2 银行合约实现
- ✅ ERC20 代币和 Permit2 集成
- ✅ 前端 Web3 交互界面