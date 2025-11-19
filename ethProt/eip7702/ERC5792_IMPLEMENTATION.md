# ERC-5792 实现说明

## 🎯 核心变更

根据 MetaMask 官方的 [7702-Readiness](https://github.com/MetaMask/7702-Readiness) 示例，我们已将实现从直接使用 EIP-7702 `authorizationList` 改为使用 **ERC-5792** 标准。

## 📝 ERC-5792 vs 直接 EIP-7702

### ❌ 之前的方式（不工作）
```javascript
const hash = await walletClient.sendTransaction({
    to: TOKEN_BANK_ADDRESS,
    authorizationList: [authorization],  // ❌ Infura/Alchemy 不支持
    data: depositCalldata,
    value: amount
});
```

### ✅ 现在的方式（MetaMask 官方）
```javascript
const result = await window.ethereum.request({
    method: 'wallet_sendCalls',  // ✅ ERC-5792 标准
    params: [{
        version: '1.0',
        chainId: '0xaa36a7',
        from: userAccount,
        calls: [{
            to: TOKEN_BANK_ADDRESS,
            value: `0x${amount.toString(16)}`,
            data: depositCalldata
        }]
    }]
});
```

## 🔧 ERC-5792 API

### 1. `wallet_sendCalls` - 发送批量交易
```javascript
const result = await window.ethereum.request({
    method: 'wallet_sendCalls',
    params: [{
        version: '1.0',
        chainId: '0xaa36a7',  // Sepolia
        from: userAccount,
        calls: [
            { to: address1, value: '0x0', data: '0x...' },
            { to: address2, value: '0x0', data: '0x...' }
        ]
    }]
});
// 返回: { id: 'call-id-string' }
```

### 2. `wallet_getCallsStatus` - 查询交易状态
```javascript
const status = await window.ethereum.request({
    method: 'wallet_getCallsStatus',
    params: [result.id]
});
// 返回: { status: 'CONFIRMED', receipts: [...] }
```

### 3. `wallet_getCapabilities` - 检查钱包能力
```javascript
const capabilities = await window.ethereum.request({
    method: 'wallet_getCapabilities',
    params: [account, [chainId]]
});
```

## 🌐 支持的网络

根据 MetaMask 官方文档，EIP-7702 目前支持：
- ✅ **Sepolia Testnet** (chainId: `0xaa36a7`)
- ✅ **Gnosis Mainnet**

## 📚 参考资料

- [MetaMask 7702-Readiness](https://github.com/MetaMask/7702-Readiness)
- [ERC-5792 规范](https://eips.ethereum.org/EIPS/eip-5792)
- [EIP-7702 规范](https://eips.ethereum.org/EIPS/eip-7702)

## ✅ 优势

1. **兼容性更好** - 使用 MetaMask 官方支持的 API
2. **无需 RPC 支持** - 不依赖 RPC 端点的 EIP-7702 支持
3. **批量交易** - 天然支持多个交易的原子执行
4. **状态查询** - 可以轮询交易状态

## 🚀 使用方式

1. **连接 MetaMask** - 支持 Sepolia 测试网
2. **使用 `wallet_sendCalls`** - 发送交易
3. **轮询 `wallet_getCallsStatus`** - 等待确认
4. **获取交易哈希** - 从 receipts 中提取

现在你可以在 Sepolia 测试网上使用 MetaMask 进行 EIP-7702 交易了！
