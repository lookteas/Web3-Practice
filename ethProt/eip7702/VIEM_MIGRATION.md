# Viem 迁移指南

## 📋 概述

本文档说明了从 Ethers.js 到 Viem 的迁移过程，以及如何使用 Viem 实现真正的 EIP-7702 功能。

## 🎯 迁移目标

### 从演示模式到生产实现

**旧版本（Ethers.js）**：
- ❌ 只能模拟 EIP-7702 授权过程
- ❌ 无法发送真实的 EIP-7702 交易
- ❌ 存款记录在 DelegateContract 地址下
- ❌ 需要两步操作：授权 + 执行

**新版本（Viem）**：
- ✅ 真实的 EIP-7702 交易支持
- ✅ 一键完成授权 + 存款
- ✅ 存款记录在用户 EOA 地址下
- ✅ EOA 真正拥有智能合约功能

## 🔄 核心变化

### 1. 客户端初始化

#### Ethers.js（旧）
```javascript
window.provider = new ethers.BrowserProvider(window.ethereum);
window.signer = await window.provider.getSigner();
```

#### Viem（新）
```javascript
import { createWalletClient, createPublicClient, custom, http } from 'viem';
import { sepolia } from 'viem/chains';
import { eip7702Actions } from 'viem/experimental';

// Public Client（用于读取）
window.publicClient = createPublicClient({
    chain: sepolia,
    transport: http()
});

// Wallet Client（用于签名和发送交易）
window.walletClient = createWalletClient({
    account: getAddress(accounts[0]),
    chain: sepolia,
    transport: custom(window.ethereum)
}).extend(eip7702Actions());  // 关键：扩展 EIP-7702 功能
```

**关键点**：
- 使用 `eip7702Actions()` 扩展 Wallet Client
- 分离读取和写入客户端
- 使用 ESM 模块导入

### 2. EIP-7702 授权签名

#### Ethers.js（旧 - 模拟）
```javascript
// 手动构建授权消息
const authorizationMessage = ethers.solidityPacked(
    ['uint8', 'uint256', 'address', 'uint256'],
    [0x05, chainId, address, nonce]
);
const messageHash = ethers.keccak256(authorizationMessage);
const signature = await signer.signMessage(ethers.getBytes(messageHash));
// 无法真正发送 EIP-7702 交易
```

#### Viem（新 - 真实）
```javascript
// 使用 Viem 的原生 EIP-7702 支持
const authorization = await walletClient.signAuthorization({
    contractAddress: DELEGATE_CONTRACT_ADDRESS,
});
// 返回标准的 EIP-7702 授权对象
```

**关键点**：
- Viem 原生支持 EIP-7702
- 自动处理签名格式
- 返回标准授权对象

### 3. 发送 EIP-7702 交易

#### Ethers.js（旧 - 无法实现）
```javascript
// Ethers.js 不支持 EIP-7702 交易类型
// 只能通过 DelegateContract 中转
const tx = await delegateContract.batchExecute(...);
```

#### Viem（新 - 真实实现）
```javascript
// 发送真正的 EIP-7702 交易
const hash = await walletClient.sendTransaction({
    account: account.address,
    to: account.address,  // 重要：发送给自己的 EOA
    authorizationList: [authorization],  // EIP-7702 授权列表
    data: batchExecuteCalldata,
    value: amount
});
```

**关键点**：
- `to` 字段是用户自己的 EOA 地址
- `authorizationList` 包含 EIP-7702 授权
- 交易执行时，EOA 临时拥有 DelegateContract 的代码

### 4. 余额查询

#### Ethers.js（旧 - 错误）
```javascript
// 查询 DelegateContract 的余额（错误）
const balance = await tokenBank.getBalance(DELEGATE_CONTRACT_ADDRESS);
```

#### Viem（新 - 正确）
```javascript
// 查询用户 EOA 的余额（正确）
const balance = await publicClient.readContract({
    address: TOKEN_BANK_ADDRESS,
    abi: TOKEN_BANK_ABI,
    functionName: 'getBalance',
    args: [account.address]  // 用户 EOA 地址
});
```

**关键点**：
- 存款记录在用户 EOA 地址下
- 不是 DelegateContract 地址

## 📝 完整示例

### 一键存款（授权 + 存款）

```javascript
async function oneClickDeposit(amount) {
    // 1. 签署 EIP-7702 授权
    const authorization = await walletClient.signAuthorization({
        contractAddress: DELEGATE_CONTRACT_ADDRESS,
    });

    // 2. 获取当前 nonce
    const currentNonce = await publicClient.readContract({
        address: DELEGATE_CONTRACT_ADDRESS,
        abi: DELEGATE_ABI,
        functionName: 'getNonce',
        args: [account.address]
    });

    // 3. 构建 batchDeposit 的 calldata
    const depositCalldata = encodeFunctionData({
        abi: TOKEN_BANK_ABI,
        functionName: 'batchDeposit',
        args: [[account.address], [parseEther(amount)]]
    });

    // 4. 构建 batchExecute 的 calldata
    const batchExecuteCalldata = encodeFunctionData({
        abi: DELEGATE_ABI,
        functionName: 'batchExecute',
        args: [
            [TOKEN_BANK_ADDRESS],  // targets
            [parseEther(amount)],  // values
            [depositCalldata],     // calldatas
            currentNonce           // expectedNonce
        ]
    });

    // 5. 发送 EIP-7702 交易（一次完成授权 + 存款）
    const hash = await walletClient.sendTransaction({
        account: account.address,
        to: account.address,  // 发送给自己
        authorizationList: [authorization],
        data: batchExecuteCalldata,
        value: parseEther(amount)
    });

    // 6. 等待交易确认
    const receipt = await publicClient.waitForTransactionReceipt({ hash });
    
    return receipt;
}
```

## 🔍 工作原理

### EIP-7702 交易流程

```
1. 用户签署 EIP-7702 授权
   ↓
2. 构建交易：
   - to: 用户 EOA 地址
   - authorizationList: [授权对象]
   - data: batchExecute 调用数据
   ↓
3. 发送交易到网络
   ↓
4. 网络处理：
   - 临时设置 EOA 代码为 DelegateContract
   - 执行 batchExecute 函数
   - msg.sender 是用户 EOA
   ↓
5. TokenBank 记录存款：
   - balances[用户 EOA] += amount
   ↓
6. 交易结束后，EOA 恢复普通状态
```

### 关键理解

**传统方式（通过代理合约）**：
```
用户 EOA → DelegateContract.batchExecute() → TokenBank.deposit()
                ↓
         存款记录在 DelegateContract 地址下 ❌
```

**EIP-7702 方式**：
```
用户 EOA (临时设置 DelegateContract 代码)
    ↓
用户 EOA.batchExecute() → TokenBank.deposit()
    ↓
存款记录在用户 EOA 地址下 ✅
```

## 🎨 UI/UX 改进

### 1. 授权状态显示

```javascript
// 检查 EOA 是否已设置代码
const code = await publicClient.getCode({
    address: account.address
});

const isDelegated = code && code !== '0x' && code.length > 2;

// 更新 UI
document.getElementById('authStatus').textContent = 
    isDelegated ? '✅ 已授权' : '⭕ 未授权';
```

### 2. 一键操作

**旧版本**：
```
步骤 1: 点击"授权" → MetaMask 签名
步骤 2: 等待确认
步骤 3: 点击"存款" → MetaMask 签名
```

**新版本**：
```
步骤 1: 点击"一键存款" → MetaMask 签名一次
        ↓
        自动完成授权 + 存款
```

## 🚀 部署和测试

### 1. 安装依赖

```bash
npm install
```

### 2. 启动本地服务器

```bash
npm run dev
# 或
python -m http.server 8000
```

### 3. 访问页面

打开浏览器访问：`http://localhost:8000/index-viem.html`

### 4. 测试流程

1. 连接 MetaMask（确保在 Sepolia 测试网）
2. 检查授权状态
3. 输入存款金额（如 0.001 ETH）
4. 点击"一键存款"
5. MetaMask 弹出签名请求（只需签名一次）
6. 等待交易确认
7. 查询余额验证

## ⚠️ 注意事项

### 1. MetaMask 版本要求

- 需要 MetaMask 支持 EIP-7702
- 建议使用最新版本

### 2. 网络要求

- 必须在支持 EIP-7702 的网络上（如 Sepolia）
- 主网可能尚未支持

### 3. Gas 费用

- EIP-7702 交易的 Gas 费用可能略高于普通交易
- 建议设置足够的 Gas Limit

### 4. 授权持久性

- EIP-7702 授权在每次交易中都需要包含
- 不是永久性的授权

## 📚 参考资源

- [Viem 官方文档 - EIP-7702](https://viem.sh/docs/eip7702/contract-writes)
- [EIP-7702 规范](https://eips.ethereum.org/EIPS/eip-7702)
- [项目 GitHub](https://github.com/your-repo/eip7702-demo)

## 🎉 总结

通过迁移到 Viem，我们实现了：

1. ✅ **真实的 EIP-7702 支持** - 不再是演示模式
2. ✅ **更好的用户体验** - 一键完成授权 + 操作
3. ✅ **正确的余额归属** - 存款记录在用户 EOA 下
4. ✅ **现代化的技术栈** - 使用最新的 Web3 库
5. ✅ **生产级代码质量** - 可用于实际项目

这是 EIP-7702 账户抽象的真正实现，展示了 EOA 如何临时获得智能合约功能！
