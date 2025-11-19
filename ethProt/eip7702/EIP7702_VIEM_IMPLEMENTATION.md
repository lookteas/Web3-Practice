# EIP-7702 Viem 2.39.0 完整实现指南

## 📚 官方文档参考

本项目基于 Viem 2.39.0 的官方 EIP-7702 API 实现：

- **准备授权**: https://viem.sh/docs/eip7702/prepareAuthorization
- **签署授权**: https://viem.sh/docs/eip7702/signAuthorization
- **合约写入**: https://viem.sh/docs/eip7702/contract-writes
- **发送交易**: https://viem.sh/docs/eip7702/sending-transactions

## 🔧 核心实现

### 1. 导入必要的模块

```javascript
import { 
    createWalletClient, 
    createPublicClient,
    custom,
    parseEther,
    formatEther,
    encodeFunctionData,
    parseAccount
} from 'viem';

import { sepolia } from 'viem/chains';

// EIP-7702 专用功能
import { 
    prepareAuthorization,
    signAuthorization 
} from 'viem/experimental';
```

### 2. 准备和签署授权

```javascript
async function signAuthorizationForContract() {
    // 步骤 1: 准备授权
    const authorization = await prepareAuthorization(walletClient, {
        account: walletClient.account,
        contractAddress: DELEGATE_CONTRACT_ADDRESS,
    });

    // 步骤 2: 签署授权
    const signedAuthorization = await signAuthorization(walletClient, {
        account: walletClient.account,
        ...authorization
    });

    return signedAuthorization;
}
```

### 3. 发送 EIP-7702 交易

```javascript
// 使用 authorizationList 发送交易
const hash = await walletClient.sendTransaction({
    account: walletClient.account,
    to: TOKEN_BANK_ADDRESS,
    authorizationList: [authorization],  // 关键：授权列表
    data: depositCalldata,
    value: amount
});
```

## 🎯 关键特性

### ✅ 真正的 EIP-7702 实现

- 使用 `prepareAuthorization` 准备授权对象
- 使用 `signAuthorization` 签署授权
- 在交易中使用 `authorizationList` 参数
- EOA 临时获得合约代码能力

### ✅ 完整支持

Viem 2.39.0 和 MetaMask 已完全支持 EIP-7702，直接使用原生 API：

```javascript
// 准备和签署授权
const authorization = await signAuthorizationForContract();

// 直接发送 EIP-7702 交易
const hash = await walletClient.sendTransaction({
    account: walletClient.account,
    to: TOKEN_BANK_ADDRESS,
    authorizationList: [authorization],
    data: depositCalldata,
    value: amount
});
```

## 📊 工作流程

```
1. 用户连接钱包
   ↓
2. 准备授权 (prepareAuthorization)
   - 指定要授权的合约地址
   - 生成授权对象
   ↓
3. 签署授权 (signAuthorization)
   - 用户签名授权
   - 获得签名后的授权对象
   ↓
4. 发送 EIP-7702 交易
   - 在 authorizationList 中包含授权
   - EOA 临时获得合约代码
   - 直接调用目标合约
   ↓
5. 交易执行
   - EOA 以合约身份执行
   - 存款记录在 EOA 地址下
```

## 🚀 优势

### vs 传统方式

| 特性 | EIP-7702 | 传统方式 |
|------|----------|----------|
| 交易数量 | 1 笔 | 2 笔（授权 + 执行） |
| Gas 成本 | 更低 | 更高 |
| 用户体验 | 一键完成 | 需要两步 |
| 账户类型 | EOA 临时变合约 | 始终是 EOA |

### vs 账户抽象（ERC-4337）

| 特性 | EIP-7702 | ERC-4337 |
|------|----------|----------|
| 兼容性 | 向后兼容 EOA | 需要新账户 |
| 部署成本 | 无需部署 | 需要部署合约 |
| 实现复杂度 | 简单 | 复杂 |
| 临时性 | 每笔交易授权 | 永久合约账户 |

## ⚠️ 注意事项

### 钱包支持

✅ **完全支持**（2025年11月18日）：

- ✅ MetaMask - 完全支持
- ✅ Viem 2.39.0 - 原生 API 支持
- ✅ 可直接使用 EIP-7702 功能

### 网络支持

- ✅ Sepolia 测试网 - 完全支持
- ⚠️ 主网 - 等待激活

### 实现方式

本项目使用 Viem 2.39.0 的官方 EIP-7702 API：
1. `prepareAuthorization` - 准备授权
2. `signAuthorization` - 签署授权
3. `authorizationList` - 发送交易
4. 真正的 EIP-7702 实现，无需降级

## 📝 代码示例

### 完整的存款流程

```javascript
// 1. 签署授权
const authorization = await signAuthorizationForContract();

// 2. 构建 calldata
const depositCalldata = encodeFunctionData({
    abi: TOKEN_BANK_ABI,
    functionName: 'deposit',
    args: []
});

// 3. 发送交易
const hash = await walletClient.sendTransaction({
    account: walletClient.account,
    to: TOKEN_BANK_ADDRESS,
    authorizationList: [authorization],
    data: depositCalldata,
    value: parseEther('0.1')
});

// 4. 等待确认
const receipt = await publicClient.waitForTransactionReceipt({ hash });
```

## 🔗 相关资源

- [EIP-7702 提案](https://eips.ethereum.org/EIPS/eip-7702)
- [Viem 文档](https://viem.sh)
- [项目 GitHub](https://github.com/yourusername/eip7702-demo)

## 📦 依赖版本

```json
{
  "viem": "^2.39.0"
}
```

## 🎓 学习路径

1. 理解 EIP-7702 的核心概念
2. 学习 Viem 的基础用法
3. 掌握 `prepareAuthorization` 和 `signAuthorization`
4. 实践发送 EIP-7702 交易
5. 实现降级方案

---

**更新日期**: 2025年11月18日  
**Viem 版本**: 2.39.0  
**作者**: EIP-7702 Demo Team
