# 🛡️《DeFi 项目自检清单 v3.0》  
## —— 47项生死红线 | 每一条都曾导致过数千万美元损失

> **作者**：一位亲历 10+ 次 DeFi 攻击、参与过 Uniswap V3 / Aave v3 / MakerDAO 审计的资深区块链架构师  
> **适用对象**：产品经理、智能合约开发者、前端工程师、审计员、DAO 成员  
> **GitHub 存储位置**：`/docs/SELF-CHECK.md`

---

> ✅ **这不是一份“建议清单”——这是你项目的生存底线。**  
> 如果你连这 47 条都做不到，那你不是在构建 DeFi，你是在拿用户的资金玩俄罗斯轮盘。

---

## 🔴 I. 安全架构（Safety First）

| 编号 | 检查项                                                       | 是否通过？ | 说明与最佳实践                                               |
| ---- | ------------------------------------------------------------ | ---------- | ------------------------------------------------------------ |
| 1    | 所有合约部署后是否移除了 `Ownable` 或 `onlyOwner` 权限？     | ☐          | **必须删除或转移所有权**。保留管理员 = 自杀。使用 `transferOwnership(address(0))` 彻底禁用。 |
| 2    | 是否使用 `TimelockController`（延迟 ≥24 小时）控制所有升级？ | ☐          | 无延迟升级 = 被黑倒计时。参考 MakerDAO。使用 OpenZeppelin `TimelockController`，最小延迟设为 `86400` 秒。 |
| 3    | 升级/执行权限是否由 ≥5 个独立地址共同管理，且需 ≥3 签名？    | ☐          | 至少包含：团队×2、审计机构×1、社区代表×1、基金会×1。禁止热钱包、交易所地址或单点控制。 |
| 4    | 所有外部调用（如 `transfer`、`call`）是否使用 `ReentrancyGuard`？ | ☐          | OpenZeppelin 已提供。**任何手动实现都是高危风险**。确保每个关键函数都继承它。 |
| 5    | 是否全部使用 Solidity 0.8.20+ 的内置溢出保护？               | ☐          | 不要引入 SafeMath 库！0.8+ 已自动启用。检查编译器版本：`pragma solidity ^0.8.20;` |
| 6    | 所有函数参数是否都校验了边界（如 `amount > 0`、`address != address(0)`）？ | ☐          | 零值、空地址攻击是初学者最大陷阱。例如：`require(amount > 0, "Amount must be positive");` |
| 7    | 是否避免 `delegatecall`、`selfdestruct`、`call.value()` 未校验返回值？ | ☐          | `call().value()` 必须加 `require(success, "Call failed")`。否则攻击者可耗尽合约 ETH。 |
| 8    | 是否**绝对不使用**中心化 API（如 CoinGecko、Coingecko REST）？ | ☐          | **只允许 Chainlink 预言机**。这是硬性红线。Sepolia 可用官方地址：<br>• WETH/USD: `0x694AA1769357215DE4FAC081bf1f309aDC325306`<br>• USDC/USD: `0x39B92C9E8D4d88b446e641c3b9d3d1d7d3a6c98d` |
| 9    | 是否检查 `AggregatorV3Interface` 的 `answer` 是否过期（`blockTimestamp > 10min`）？ | ☐          | 防止“价格冻结”攻击（曾致 bZx、Cream Finance 崩溃）。加入 `isPriceStale()` 检查逻辑。 |
| 10   | 清算触发是否基于链上真实价格 × LTV，而非固定阈值？           | ☐          | 如：`collateralValue / debtValue < 110e18`，**不可硬编码**。动态计算，依赖预言机实时喂价。 |
| 11   | 是否实现 `emergencyStop()` 功能，并由多签控制？              | ☐          | 仅用于极端攻击场景，暂停后只允许提款，禁止新增操作。使用 `paused` 状态变量 + `onlyEmergencyAdmin` 修饰符。 |
| 12   | 是否避免使用 `approve` + `transferFrom` 的双步模式？         | ☐          | 使用 `safeTransferFrom`（OpenZeppelin）或 EIP-2612（permit）减少 gas 和授权风险。防止“无限授权”攻击。 |

---

## 💰 II. 经济模型（Economics）

| 编号 | 检查项                                                       | 是否通过？ | 说明与最佳实践                                               |
| ---- | ------------------------------------------------------------ | ---------- | ------------------------------------------------------------ |
| 13   | 是否无预挖、无私募、无团队锁仓（仅线性释放）？               | ☐          | 团队份额 ≤20%，4 年线性解锁，否则会被视为“拉盘跑路”。MD 总量 10M，分配应公开透明。 |
| 14   | 初始流动性挖矿 APY 是否 ≤80%？                               | ☐          | >100% 的 APY 是“套利者磁铁”，不是真实用户。高激励会吸引机器人，导致流动性瞬间蒸发。 |
| 15   | 挖矿奖励是否来自协议收入（手续费）？还是纯通胀？             | ☐          | 纯通胀模型（如早期 SushiSwap）必然崩溃。应逐步过渡到“手续费分红”机制，形成正反馈循环。 |
| 16   | 是否只奖励 LP Token 持有者，而非单纯质押原生代币？           | ☐          | 防止“空投套利”：用户买 LP → 赚奖励 → 立即卖出 → 流动性蒸发。奖励应绑定真实流动性。 |
| 17   | 提案投票门槛是否 ≥1,000 MD？总票数门槛是否 ≥100,000 MD？     | ☐          | 防止女巫攻击。太低=机器人操控；太高=无人参与。参考 Snapshot.org 的治理设计。 |
| 18   | 总供应量中，流通部分是否 ≥90%？                              | ☐          | 若 50% 代币被团队或基金会锁定，社区不会信任。确保绝大多数代币通过挖矿公平释放。 |
| 19   | 交易手续费是否 100% 分配给流动性提供者？                     | ☐          | 这是 DEX 生存的核心正反馈循环。不要截留。每笔交易 0.3% 手续费必须全额返还 LP。 |
| 20   | 是否强制要求提案附带：问题描述、解决方案、风险评估、替代方案？ | ☐          | 没有结构化提案 = 民主变闹剧。参考 MakerDAO 的 [Governance Proposal Template](https://github.com/makerdao/community/blob/master/governance/proposals/template.md)。 |

---

## ⚙️ III. 技术实现（Engineering）

| 编号 | 检查项                                                       | 是否通过？ | 说明与最佳实践                                               |
| ---- | ------------------------------------------------------------ | ---------- | ------------------------------------------------------------ |
| 21   | 是否使用 Solidity 0.8.20+？                                  | ☐          | 旧版本无溢出保护，禁用。`pragma solidity ^0.8.20;`           |
| 22   | 是否开启编译器优化（runs=200）？                             | ☐          | `optimizer: { enabled: true, runs: 200 }` —— 减少 Gas 成本 15–30%，提升部署效率。 |
| 23   | 单元测试覆盖率是否 ≥95%？                                    | ☐          | 使用 `npx hardhat coverage` 生成报告。低于此值，不准部署。测试应覆盖所有分支路径。 |
| 24   | 是否运行过 Foundry Fuzzing？                                 | ☐          | 对关键函数（如 `swap`, `deposit`, `borrow`）输入随机值，模拟极端市场波动。示例：<br>`forge test --ffi --fork-url $ALCHEMY_URL -vvv` |
| 25   | 是否通过 Slither、Solhint、MythX 扫描，且无高危告警？        | ☐          | Slither 输出必须为 “0 High Severity Issues”。定期运行：`slither . --checklist` |
| 26   | 所有关键操作（Deposit, Withdraw, Swap, Vote, Claim）是否 emit 事件？ | ☐          | 无事件 = The Graph 无法索引 = 用户看不到历史记录。每个函数至少 emit 一个事件。 |
| 27   | 是否避免重复读取 storage 变量？是否将频繁访问变量缓存为 local？ | ☐          | Storage 读取昂贵。`uint balance = balances[msg.sender];` 比多次读取节省 2k+ gas。 |
| 28   | 是否使用 Hardhat + GitHub Actions 实现 CI/CD？               | ☐          | PR Merge → 自动测试 → 自动部署 → 自动生成报告。见下方示例流程。 |
| 29   | 是否有可重复的部署脚本（scripts/deploy-sepolia.ts）？        | ☐          | 每次部署必须记录：合约地址、交易哈希、时间戳、负责人。输出至 `/deployments/sepolia/`。 |
| 30   | 是否生成并保存所有合约的 ABI JSON 文件？                     | ☐          | 前端、子图、工具链都依赖它。不能临时生成。路径：`artifacts/contracts/*.json` |

### ✅ 示例 CI/CD 流程（GitHub Actions）
```yaml
# .github/workflows/ci.yml
name: CI Pipeline
on:
  push:
    branches: [ develop ]
  pull_request:
    branches: [ develop ]

jobs:
  test:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      - uses: actions/setup-node@v4
        with:
          node-version: '20'
      - run: npm ci
      - run: npx hardhat compile
      - run: npx hardhat test --network hardhat
      - run: npx hardhat coverage
      - run: npx slither . --checklist
      - run: npx solhint contracts/**/*.sol
      - name: Check Coverage Threshold
        run: |
          if ! grep -q "Lines:.*95" coverage/lcov.info; then
            echo "Coverage below 95%!"
            exit 1
          fi
```

---

## 🌐 IV. 数据与前端（Data & UX）

| 编号 | 检查项                                                       | 是否通过？ | 说明与最佳实践                                               |
| ---- | ------------------------------------------------------------ | ---------- | ------------------------------------------------------------ |
| 31   | 是否使用 The Graph 创建子图？是否索引了至少 5 个核心事件？   | ☐          | 必须索引：<br>`Deposit`, `Withdraw`, `Swap`, `Borrow`, `Repay`, `Vote`<br>子图文件路径：`/frontend/graphs/` |
| 32   | 前端是否通过 GraphQL 查询 The Graph，而非直接轮询链？        | ☐          | 直接调用合约查询历史数据 ≈ 用拖拉机运快递，慢且贵。使用 `graphql-request` 或 `useQuery`。 |
| 33   | 是否使用 Next.js（App Router）而非 Create React App？        | ☐          | SSR 支持、SEO 友好、便于 IPFS 部署。避免传统 CRA。           |
| 34   | 是否使用 Web3Modal 而非手动注入 `window.ethereum`？          | ☐          | 支持 WalletConnect、Coinbase Wallet、MetaMask 等 ≥10 种钱包。避免兼容性问题。 |
| 35   | 是否强制验证当前网络为 Sepolia（chainId 11155111）？         | ☐          | 防止钓鱼网站诱导用户切换到主网。代码示例：<br>`if (network.chainId !== 11155111) await switchNetwork()` |
| 36   | 是否在每次交易前弹出完整确认框（含金额、代币、目标合约地址）？ | ☐          | 用户点击“确认”前，必须看到：“你正在向 0x...a1b2 发送 100 USDC”。防钓鱼关键。 |
| 37   | 是否部署于 IPFS，而非 Vercel/Netlify/AWS？                   | ☐          | 中心化托管 = 项目可被关闭。IPFS CID 必须公开于 GitHub Release。使用 `ipfs-http-client` 或 Pinata。 |
| 38   | 是否在页面显著位置显示 “TESTNET - NOT REAL MONEY”？          | ☐          | 避免用户误以为是主网，造成心理误导和法律纠纷。字体颜色：红色或橙色。 |
| 39   | 是否所有静态资源（.png, .svg, .woff2）均放在 `/public/` 下？ | ☐          | 放在 `/src/assets/` 会被打包成哈希文件，无法预测 IPFS 地址。必须使用 `/images/logo.png` 直接引用。 |
| 40   | 是否支持移动端（手机钱包）？                                 | ☐          | 80% 的 DeFi 用户通过手机交互。按钮最小 48×48dp，表单适配触屏，加载速度 ≤2s。 |

---

## 🗳️ V. 治理与透明（Governance & Trust）

| 编号 | 检查项                                                       | 是否通过？ | 说明与最佳实践                                               |
| ---- | ------------------------------------------------------------ | ---------- | ------------------------------------------------------------ |
| 41   | 是否注册 Snapshot.org 空间（如 mydefi.eth）？                | ☐          | 链下投票是唯一可行方式。链上投票 Gas 太贵，参与度趋近于零。注册地址：https://snapshot.org/#/mydefi.eth |
| 42   | 是否提供标准治理提案模板（标题、描述、影响、替代方案）？     | ☐          | 模板链接必须出现在每个投票页面。参考：[MakerDAO Proposal Template](https://github.com/makerdao/community/blob/master/governance/proposals/template.md) |
| 43   | 是否将所有提案与投票结果永久归档于 GitHub `/docs/governance/`？ | ☐          | 社区需要追溯决策过程。不能只存在 Snapshot。建议格式：`proposal-001.md` |
| 44   | 是否已规划至少两次独立第三方审计（Pre-Launch + Mainnet）？   | ☐          | 第一次审计应在测试网部署前完成。审计报告必须全文公开于 `/docs/audits/`。推荐机构：CertiK、PeckShield、OpenZeppelin。 |
| 45   | 是否启动 ≥$20,000 美元漏洞赏金计划（Immunefi 或 Gitcoin）？  | ☐          | 这是社区对你“真正重视安全”的第一份信任投票。设置奖金梯度：高危 $10k，中危 $5k。 |
| 46   | 是否公开声明：“我们无风投、无预售、无团队私钥”？             | ☐          | 匿名 ≠ 隐蔽。你可以匿名，但必须承诺责任。在 README 和文档首页明确写出。 |
| 47   | 是否将本文档（《DeFi 项目自检清单》）置于 `/docs/SELF-CHECK.md`，并在 README 中置顶？ | ☐          | 如果你连这份清单都不愿公开，那你根本没准备好面对世界。       |

### ✅ 在 `README.md` 中添加：
```md
> 🔒 **安全第一**：请阅读 [《DeFi 项目自检清单》](docs/SELF-CHECK.md) —— 我们承诺遵守全部 47 条红线。
```

---

## 🚫 最终红牌警告（Red Flags —— 一旦出现，立即停手）

| 你是否说过或做过以下任何一句话？  | 结果                                     |
| --------------------------------- | ---------------------------------------- |
| “我们先上线，再补安全。”          | → 你将在 72 小时内被黑。                 |
| “我们的合约很简单，没人会攻击。”  | → 黑客专门找“简单”项目，因为它们最脆弱。 |
| “我们信任团队，不需要多签。”      | → 你是在拿用户的资金赌博。               |
| “我们用 CoinGecko 喂价，没问题。” | → 你已经放弃了去中心化的灵魂。           |
| “我们没有钱做审计。”              | → 你没有资格做 DeFi。                    |
| “这个功能只是测试网，无所谓。”    | → 测试网上的漏洞，就是主网的定时炸弹。   |

---

## ✅ 交付物清单（你必须提交的 5 份证据）

在你准备部署第一个合约前，请确保你已准备好：

| 文件                      | 位置         | 内容                                                    |
| ------------------------- | ------------ | ------------------------------------------------------- |
| 1. `docs/SELF-CHECK.md`   | 仓库根目录   | 本清单 + 所有 ☑️ 已打钩                                  |
| 2. `deployments/sepolia/` | 合约部署记录 | 包含所有合约地址、交易哈希、部署时间、签名人            |
| 3. `coverage/lcov.info`   | 测试报告     | 覆盖率 ≥95%                                             |
| 4. `slither-report.txt`   | 安全扫描     | 无 High Severity Issue                                  |
| 5. `docs/SECURITY.md`     | 安全承诺     | 明确写出：“我们使用 Timelock + 多签 + Chainlink + IPFS” |

