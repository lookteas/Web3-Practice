当然可以！以下是一份完整的 **多签钱包测试指南（Markdown 文档）**，涵盖合约部署、权限说明、操作流程、常见问题等，适用于你已部署在 Sepolia 网络上的多签钱包合约。

---

# 🛡️ 多签钱包测试指南

> 本指南适用于已部署在 **Sepolia 测试网** 的 `SimpleMultiSigWallet` 合约，包含部署、授权、转账、执行等全流程说明。

---

## 📌 1. 合约基本信息

- **合约名称**：`SimpleMultiSigWallet`
- **功能**：允许多个所有者共同管理资产，需达到指定确认数才能执行交易
- **核心特性**：
  - 防重放（相同交易不可重复提交）
  - 使用底层 `call` 执行任意调用
  - 执行失败即终止（不可重试）
  - 任何人可执行已确认交易

---

## 🔧 2. 合约部署流程

### 2.1 部署参数

部署时需提供两个参数：

| 参数        | 类型        | 说明                                                         |
| ----------- | ----------- | ------------------------------------------------------------ |
| `_owners`   | `address[]` | 所有者地址列表（至少 1 个，无重复，非零地址）                |
| `_required` | `uint256`   | 执行交易所需的最小确认人数（`1 ≤ required ≤ owners.length`） |

### 2.2 示例（4 个所有者，门槛 = 3）

```javascript
_owners = [
  "0x1Dc79b944d6fB2Afb80b0D1d8b5FC708eF3f661F",
  "0x2E8F4bB8e3C1d5a9F7B2c3D4e5F6a7B8c9D0e1F2",
  "0x3F9A5cC9f4D2e6b8A1c3D4e5F6a7B8c9D0e1F3A4",
  "0x4A0B6dD0e5F3f7c9B2d4E5f6A7b8C9d0E1f2A3B5"
]
_required = 3
```

### 2.3 部署方式（推荐 Remix）

1. 在 [Remix IDE](https://remix.ethereum.org/) 编译合约
2. 切换 MetaMask 到 **Sepolia 网络**
3. 在 **Deploy & Run Transactions** 面板：
   - Environment: `Injected Provider - MetaMask`
   - 填写构造函数参数（如上）
4. 点击 **Deploy**

> ✅ 部署后记录合约地址（如 `0xefa1096834ba72b799a29efbb2920C4D082a0701`）

---

## 🔐 3. 权限说明

| 操作                                | 是否需要授权 | 说明                                       |
| ----------------------------------- | ------------ | ------------------------------------------ |
| **提交交易** (`submitTransaction`)  | ✅ 是         | 仅 `owners` 列表中的地址可调用             |
| **确认交易** (`confirmTransaction`) | ✅ 是         | 仅 `owners` 可确认，且每人只能确认一次     |
| **执行交易** (`executeTransaction`) | ❌ 否         | **任何人**均可调用（包括非所有者）         |
| **接收 ETH**                        | ❌ 否         | 合约有 `receive() payable`，可直接接收 ETH |

> 📝 注意：执行交易前必须满足 `confirmationCount ≥ required`

---

## 💸 4. 操作流程（以 ERC20 转账为例）

### 4.1 前提条件

- 多签钱包合约地址已持有足够 ERC20 代币（如 USDC）
  - 若无，请先向合约地址转账代币
- 所有参与者 MetaMask 已切换到 **Sepolia 网络**
- 前端已配置正确的合约地址

### 4.2 步骤一：提交交易（由任一所有者操作）

1. 打开前端页面，点击 **“连接钱包”**
2. 填写：
   - **目标合约地址**：ERC20 代币合约地址（如 Sepolia USDC: `0x1c7D4B196Cb0C7B01d743Fbc6116a902379C7238`）
   - **接收者地址**：目标收款地址
   - **代币数量**：如 `100`
3. 点击 **“提交交易”**
4. MetaMask 弹出确认 → 确认交易
5. 成功后获得 **交易索引（txIndex）**，如 `0`

> 📌 提示：相同内容的交易无法重复提交（防重放）

### 4.3 步骤二：确认交易（由其他所有者操作）

1. 其他所有者打开前端，连接自己的钱包
2. 在 **“交易索引”** 输入框填入 `0`
3. 点击 **“确认交易”**
4. MetaMask 确认 → 交易上链
5. 重复此步骤，直到确认人数 ≥ 3

> ✅ 可通过 `getConfirmationCount(0)` 查询当前确认数

### 4.4 步骤三：执行交易（由任何人操作）

1. 任意地址（包括非所有者）打开前端
2. 输入交易索引 `0`
3. 点击 **“执行交易”**
4. MetaMask 确认 → 调用目标合约的 `transfer` 函数
5. 成功后，代币从多签钱包转出

> ✅ 执行成功后，可在 Sepolia Etherscan 查看目标地址余额变化

---

## 🧪 5. 其他操作示例

### 5.1 发送 ETH

- **目标地址**：任意地址（EOA 或合约）
- **代币数量**：留空或填 `0`
- **额外设置**：
  - 在前端代码中，将 `value` 设为 `ethers.parseEther("0.1")`
  - `data` 设为 `"0x"`

> ⚠️ 目标地址必须能接收 ETH（有 `receive()` 或为 EOA）

### 5.2 调用自定义合约函数

1. 修改前端 `Interface`：
   ```js
   const iface = new ethers.Interface([
     "function setAdmin(address newAdmin)"
   ]);
   const data = iface.encodeFunctionData("setAdmin", ["0x..."]);
   ```
2. 提交交易时：
   - `_to` = 目标合约地址
   - `_value` = `0n`
   - `_data` = 上述 `data`

---

## ❓ 6. 常见问题排查

### Q1: 执行交易失败，提示 “Transaction execution failed”

**原因**：目标交易本身失败（非多签逻辑问题）  
**排查**：
- 检查多签钱包是否持有足够代币/ETH
- 检查目标函数参数是否正确
- 在 Etherscan 手动调用目标函数测试

### Q2: 提交交易时提示 “Transaction already submitted”

**原因**：已提交过完全相同的交易（`to + value + data` 相同）  
**解决**：修改任一参数（如加 nonce）或等待执行后提交新交易

### Q3: 确认交易时提示 “Already confirmed”

**原因**：该地址已确认过此交易  
**解决**：无需重复确认

### Q4: 执行交易时提示 “Not enough confirmations”

**原因**：确认人数未达门槛  
**解决**：通知其他所有者确认

---

## 🔗 7. 有用链接

- [Sepolia 水龙头（获取测试 ETH）](https://sepoliafaucet.com/)
- [Sepolia Etherscan](https://sepolia.etherscan.io/)
- [Sepolia USDC 合约](https://sepolia.etherscan.io/address/0x1c7D4B196Cb0C7B01d743Fbc6116a902379C7238)

---

## ✅ 8. 测试成功标志

- [ ] 多签钱包成功接收 ETH/代币
- [ ] 所有者可提交交易
- [ ] 其他所有者可确认交易
- [ ] 满足门槛后，交易可被成功执行
- [ ] 相同交易无法重复提交

---

> 📝 **备注**：本合约适用于学习和测试。如用于管理真实资产，建议进行安全审计并考虑使用 Gnosis Safe 等成熟方案。

---

你可以将此 Markdown 保存为 `MULTISIG_TEST_GUIDE.md`，用于团队协作或测试记录。如需 PDF 或 Word 版本，也可告知！