# BigBank & Admin 合约系统

## 📋 项目概述

这是一个基于以太坊的智能合约系统，包含了银行存款功能和管理员资金管理功能。系统由四个主要合约组成：

- **IBank.sol** - 银行合约接口
- **Bank.sol** - 基础银行合约，实现 IBank 接口
- **BigBank.sol** - 继承自 Bank，添加最小存款限制
- **Admin.sol** - 管理员合约，用于资金管理

## 🏗️ 合约架构

```
IBank (接口)
    ↑
Bank (基础实现)
    ↑
BigBank (继承 + 最小存款限制)
    ↓ (管理员权限转移)
Admin (资金管理)
```

## 📁 文件结构

```
bigBankContract/
├── IBank.sol          # 银行合约接口
├── Bank.sol           # 基础银行合约
├── BigBank.sol        # 大银行合约（继承 Bank）
├── Admin.sol          # 管理员合约
├── deploy.js          # 部署和测试脚本
├── test.html          # Web 测试界面
└── README.md          # 项目文档
```

## 🔧 合约功能详解

### IBank 接口
定义了银行合约的核心功能：
- `deposit()` - 存款函数
- `withdraw(uint256 amount)` - 提款函数
- `withdrawAll()` - 提取所有资金
- `getContractBalance()` - 获取合约余额
- `getTopDepositors()` - 获取前3名存款用户
- `transferAdmin(address newAdmin)` - 转移管理员权限

### Bank 合约
实现 IBank 接口的基础银行功能：
- ✅ 用户存款记录
- ✅ 前3名存款用户排行
- ✅ 管理员提款功能
- ✅ 存款用户管理

### BigBank 合约
继承自 Bank，添加额外限制：
- ✅ **最小存款限制**: 0.001 ETH
- ✅ 使用 `minDepositRequired` modifier 控制权限
- ✅ 重写 `deposit()` 和 `receive()` 函数

### Admin 合约
管理员资金管理合约：
- ✅ **Owner 权限控制**
- ✅ `adminWithdraw(IBank bank)` - 从银行合约提取资金
- ✅ 资金转移到 Owner 地址
- ✅ 合约余额查询

## 🚀 部署和使用流程

### 1. 编译合约
使用 Remix IDE、Hardhat 或 Foundry 编译所有合约：

```bash
# 使用 Hardhat
npx hardhat compile

# 使用 Foundry
forge build
```

### 2. 部署合约

#### 方法一：使用 Remix IDE
1. 在 Remix 中打开所有 `.sol` 文件
2. 编译合约
3. 先部署 `BigBank` 合约
4. 再部署 `Admin` 合约
5. 调用 `BigBank.transferAdmin(adminAddress)` 转移权限

#### 方法二：使用部署脚本
```bash
# 安装依赖
npm install ethers

# 配置 deploy.js 中的私钥和 RPC URL
# 运行部署脚本
node deploy.js
```

### 3. 测试流程

#### 完整测试流程：
1. **部署合约**
   - 部署 BigBank 合约
   - 部署 Admin 合约

2. **转移管理员权限**
   ```solidity
   bigBank.transferAdmin(adminContractAddress);
   ```

3. **模拟用户存款**
   ```solidity
   // 用户1存款 0.005 ETH
   bigBank.deposit{value: 0.005 ether}();
   
   // 用户2存款 0.01 ETH
   bigBank.deposit{value: 0.01 ether}();
   ```

4. **Admin 提取资金**
   ```solidity
   // Admin 合约的 Owner 调用
   admin.adminWithdraw(bigBankAddress);
   ```

## 🌐 Web 测试界面

使用 `test.html` 进行可视化测试：

1. 打开 `test.html` 文件
2. 连接 MetaMask 钱包
3. 输入合约地址并初始化
4. 进行存款、查询、管理员操作等测试

### 主要功能：
- 🔗 钱包连接
- 💰 存款操作（最小 0.001 ETH）
- 📊 余额查询
- 🏆 前3名存款用户查询
- 👑 Admin 资金管理
- 📝 操作日志记录

## ⚠️ 重要注意事项

### 安全考虑
1. **重入攻击防护**: 当前使用 `transfer()` 方法，建议生产环境使用 ReentrancyGuard
2. **权限控制**: 确保只有正确的地址能调用管理员函数
3. **地址验证**: 所有地址参数都进行了零地址检查

### 最佳实践
1. **测试网络**: 先在测试网络（如 Sepolia）上部署和测试
2. **Gas 优化**: 大量用户时考虑优化存储结构
3. **事件日志**: 所有重要操作都有事件记录

### 已知限制
1. **存款用户数组**: 会无限增长，大量用户时需要优化
2. **排序算法**: 使用冒泡排序，效率较低
3. **前端兼容性**: 需要 MetaMask 或兼容的 Web3 钱包

## 🔍 测试用例

### 基础功能测试
- ✅ 用户存款（≥0.001 ETH）
- ✅ 存款金额过小时拒绝（<0.001 ETH）
- ✅ 前3名存款用户排行更新
- ✅ 合约余额查询

### 管理员功能测试
- ✅ 管理员权限转移
- ✅ Admin 合约提取资金
- ✅ 非管理员调用时拒绝
- ✅ Owner 权限控制

### 边界条件测试
- ✅ 零地址检查
- ✅ 余额不足时的处理
- ✅ 重复存款用户处理
