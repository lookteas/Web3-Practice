# 更新日志

## [2.1.0] - 2025-11-18

### ✅ 重大更新：完整的 EIP-7702 支持

#### 升级内容

1. **Viem 升级到 2.39.0**
   - 完整支持 EIP-7702 原生 API
   - 使用官方的 `prepareAuthorization` 和 `signAuthorization`
   - 支持 `authorizationList` 参数

2. **移除降级逻辑**
   - 不再需要降级到 DelegateContract
   - 直接使用 EIP-7702 交易
   - MetaMask 已完全支持

3. **代码简化**
   - 移除了复杂的降级判断逻辑
   - 代码更清晰、更易维护
   - 完全符合官方文档示例

#### 技术细节

**之前的实现（错误）**：
```javascript
// 错误地认为需要降级
if (authorization) {
    // EIP-7702
} else {
    // 降级到 DelegateContract
}
```

**现在的实现（正确）**：
```javascript
// 直接使用 EIP-7702
const authorization = await signAuthorizationForContract();
const hash = await walletClient.sendTransaction({
    account: walletClient.account,
    to: TOKEN_BANK_ADDRESS,
    authorizationList: [authorization],
    data: depositCalldata,
    value: amount
});
```

#### 参考文档

- [prepareAuthorization](https://viem.sh/docs/eip7702/prepareAuthorization)
- [signAuthorization](https://viem.sh/docs/eip7702/signAuthorization)
- [Contract Writes](https://viem.sh/docs/eip7702/contract-writes)
- [Sending Transactions](https://viem.sh/docs/eip7702/sending-transactions)

#### 感谢

感谢用户指出错误判断，确认 Viem 2.39.0 和 MetaMask 已完全支持 EIP-7702！

---

## [2.0.0] - 2025-11-18

### 初始版本

- 基于 Viem 的 EIP-7702 实现
- 支持批量操作
- 完整的前端界面
- 详细的文档

---

**维护者**: EIP-7702 Demo Team  
**最后更新**: 2025年11月18日
