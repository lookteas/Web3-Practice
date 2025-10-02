# 🧪 Foundry 入门教程与多环境调试指南

> **Foundry 是什么？**  
> 它是一套用 **Rust 编写的 Solidity 开发工具集**，让你不用写 JavaScript 就能开发、测试、部署智能合约。它快、轻量、贴近链上真实环境，是现在最流行的 Solidity 开发工具之一。

---

[TOC]



## 一、入门基础

### 1.1 Foundry 是什么？（四大组件）

Foundry 由四个核心工具组成：

| 工具       | 作用                           | 通俗解释                        |
| ---------- | ------------------------------ | ------------------------------- |
| **Forge**  | 编译、测试、部署合约           | 就像你的"Solidity 开发主控台"   |
| **Cast**   | 和链上交互（查余额、发交易等） | 就像"命令行钱包 + 区块链浏览器" |
| **Anvil**  | 本地启动一个以太坊测试网       | 就像你自己的"私人以太坊沙盒"    |
| **Chisel** | 交互式写 Solidity 代码（可选） | 类似 Python 的 REPL，边写边试   |

> ✅ 你现在主要用 **Forge + Anvil + Cast**，Chisel 可以先不管。

---

### 1.2 安装 Foundry：用 `foundryup`

> 💡 原理：`foundryup` 是一个安装脚本，会自动下载最新版 Foundry 工具到你电脑。

**安装命令（Mac/Linux）**：
```bash
curl -L https://foundry.paradigm.xyz | bash
```

然后运行：
```bash
foundryup
```

> ⚠️ Windows 用户建议用 **WSL2**（Windows Subsystem for Linux），否则可能遇到兼容问题。

---

### 1.3 验证安装

运行：
```bash
forge --version
```

如果看到类似：
```
forge 0.2.0 (...)
```
说明安装成功！

---

## 二、创建与初始化项目

### 2.1 创建新项目

```bash
forge init my-project
cd my-project
```

> 💡 `init` = initialize（初始化），就像新建一个空白项目文件夹。

---

### 2.2 项目结构解析

```
my-project/
├── src/          ← 你的合约代码（.sol 文件）
├── test/         ← 测试文件（以 Test 开头或 .t.sol 结尾）
├── script/       ← 部署脚本（.s.sol 文件）
├── foundry.toml  ← 配置文件（类似 package.json）
└── lib/          ← 依赖库（比如 OpenZeppelin）
```

> ✅ 初学者重点看 `src/` 和 `test/`。

---

## 三、核心：编译与测试（Forge）

### 3.1 编译合约：`forge build`

```bash
forge build
```

> 💡 原理：Solidity 是编译型语言，`.sol` 文件不能直接上链，要先编译成字节码（bytecode）和 ABI（接口描述）。

编译后会在 `out/` 目录生成：
- `MyContract.sol/MyContract.json`：包含字节码、ABI 等信息

---

### 3.2 理解 `out/` 目录

- **bytecode**：合约的"机器码"，部署时用
- **abi**：合约的"说明书"，告诉别人怎么调用你的函数

> 🧠 类比：就像你写了一个 C 程序，编译后生成 `.exe`（bytecode）和 `.h` 头文件（ABI）。

---

## 四、运行测试

### 4.1 基础命令：`forge test`

```bash
forge test
```

自动运行 `test/` 下所有测试。

---

### 4.2 测试文件结构（继承 `Test`）

```solidity
// test/MyTest.t.sol
pragma solidity ^0.8.13;

import "forge-std/Test.sol";

contract MyTest is Test {
    function testExample() public {
        assertEq(1 + 1, 2);
    }
}
```

> 💡 `Test.sol` 是 Foundry 提供的测试基类，里面包含了断言和作弊码（后面讲）。

---

### 4.3 常用断言（Assertions）

| 断言                    | 作用         |
| ----------------------- | ------------ |
| `assertEq(a, b)`        | 检查 a == b  |
| `assertTrue(condition)` | 检查条件为真 |
| `assertNotEq(a, b)`     | 检查 a != b  |

> ✅ 测试就是"写代码验证你的合约行为是否符合预期"。

---

### 4.4 核心：作弊码（Cheatcodes）

作弊码是 Foundry 的"超能力"，让你在测试中模拟各种链上场景。

#### 1. `vm.prank(address)`：假装是别人调用

```solidity
vm.prank(user);
myContract.deposit{value: 1 ether}();
```

> 💡 原理：正常调用合约时，`msg.sender` 是你自己的地址。`prank` 可以临时把 `msg.sender` 改成任意地址，模拟用户行为。

#### 2. `vm.deal(address, amount)`：给地址发 ETH

```solidity
vm.deal(user, 10 ether); // 给 user 发 10 ETH
```

> 💡 测试时不需要真实转账，直接"变出"ETH。

#### 3. `vm.warp(timestamp)`：跳到未来时间

```solidity
vm.warp(block.timestamp + 7 days);
```

> 💡 用于测试时间锁、质押到期等功能。

#### 4. `vm.expectRevert()`：期望交易失败

```solidity
vm.expectRevert();
myContract.withdrawTooMuch();
```

> 💡 如果 `withdrawTooMuch()` 没有 revert，测试就失败！

#### 5. `vm.recordLogs()` + `vm.getRecordedLogs()`：检查事件

```solidity
vm.recordLogs();
myContract.doSomething();
Vm.Log[] memory logs = vm.getRecordedLogs();
assertEq(logs[0].topics[0], ...); // 检查事件是否发出
```

> 💡 事件（Event）是合约的"日志"，用于前端监听。测试时也要验证是否正确发出。

---

## 五、高级测试技巧

### 5.1 模糊测试（Fuzzing）

```solidity
function testAdd(uint256 a, uint256 b) public {
    assertEq(a + b, b + a); // 交换律
}
```

> 💡 Foundry 会**自动用成千上万组随机数**测试这个函数！  
> 原理：模糊测试能发现边界情况（比如溢出、0 值等）。

默认跑 256 次，可在 `foundry.toml` 中修改。

---

### 5.2 Gas 消耗报告

```bash
forge test --gas-report
```

> 💡 输出每个函数的 Gas 消耗，帮你优化成本。

---

### 5.3 运行单个测试

```bash
forge test -m "testAdd"
```

> `-m` = match（匹配），支持正则。

---

### 5.4 并行 vs 串行

- 默认**并行运行**（更快）
- 加 `--no-match-coverage` 或某些场景会串行
- 一般不用管，除非测试之间有依赖

---

## 六、部署合约（Forge Script）

### 6.1 脚本结构

```solidity
// script/Deploy.s.sol
pragma solidity ^0.8.13;

import "forge-std/Script.sol";

contract DeployScript is Script {
    function run() external {
        vm.startBroadcast(); // 开始广播交易
        MyContract c = new MyContract();
        vm.stopBroadcast();  // 结束
    }
}
```

---

### 6.2 `vm.startBroadcast()`

- 开启后，所有 `new` 或函数调用都会**真实发送交易**
- 私钥通过环境变量传入（见下）

---

### 6.3 安全使用私钥（环境变量）

创建 `.env` 文件：
```env
PRIVATE_KEY=your_private_key_here
```

运行脚本时：
```bash
source .env
forge script script/Deploy.s.sol --broadcast --rpc-url <url>
```

> 🔒 **永远不要把私钥写进代码！**

---

## 七、部署到不同网络

### 7.1 部署到本地 Anvil

先启动 Anvil（见下节），然后：

```bash
forge script script/Deploy.s.sol --broadcast --rpc-url http://localhost:8545
```

### 7.2 部署到测试网（如 Sepolia）

```bash
forge script script/Deploy.s.sol --broadcast --rpc-url https://sepolia.infura.io/v3/YOUR_KEY
```

### 7.3 验证合约（Etherscan）

```bash
forge script ... --verify --etherscan-api-key YOUR_ETHERSCAN_KEY
```

> 需要在 `foundry.toml` 中配置 Etherscan API Key。

---

## 八、本地开发环境：Anvil

### 8.1 启动本地测试网

```bash
anvil
```

输出类似：
```
Accounts:
  (0) 0xf39Fd6e51aad88F6F4ce6aB8827279cffFb92266 (10000 ETH)
      Private Key: 0xac0974bec39a17e36ba4a6b4d238ff944bacb478cbed5efcae784d7bf4f2ff80
...
```

> 💡 这 10 个账户各有 10000 ETH，随便用！私钥也给你了，方便测试。

### 8.2 用 Anvil 做端到端测试

- 部署合约 → 调用函数 → 检查状态
- 所有操作都在你电脑上完成，**不花真钱、不联网**

---

## 九、链上交互：Cast

### 9.1 查询数据

```bash
# 查余额
cast balance 0xf39...2266

# 调用只读函数（view/pure）
cast call <contract> "name()(string)"
```

### 9.2 发送交易

```bash
cast send <contract> "mint(address)" 0xf39...2266 --private-key <key> --rpc-url http://localhost:8545
```

### 9.3 编码/解码

```bash
# 把函数调用转成 calldata
cast calldata "transfer(address,uint256)" 0x... 100

# 把 bytes 转成字符串
cast --from-utf8 0x48656c6c6f  # 输出 "Hello"
```

### 9.4 计算合约地址

```bash
cast compute-address <deployer> --nonce 5
```

> 💡 合约地址 = deployer 地址 + nonce（部署次数）的哈希

---

## 十、依赖管理

### 10.1 安装依赖（如 OpenZeppelin）

```bash
forge install OpenZeppelin/openzeppelin-contracts
```

会下载到 `lib/openzeppelin-contracts/`

### 10.2 更新依赖

```bash
forge update
```

### 10.3 重映射（Remappings）

在 `remappings.txt` 中写：
```
@openzeppelin/=lib/openzeppelin-contracts/
```

然后在合约中：
```solidity
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
```

> 💡 避免写超长路径，像 npm 的 alias。

---

## 十一、配置文件：foundry.toml

示例：
```toml
[profile.default]
src = "src"
out = "out"
libs = ["lib"]

# 编译器
solc_version = "0.8.20"
optimizer = true
optimizer_runs = 1000

# 测试
fuzz_runs = 512

# 部署
[rpc_endpoints]
sepolia = "https://sepolia.infura.io/v3/..."

[etherscan]
sepolia = { key = "YOUR_KEY" }
```

---

## 十二、Gas 优化

### 12.1 看 Gas 报告

```bash
forge test --gas-report
```

关注高 Gas 函数，比如：
- 循环太多
- 存储读写频繁
- 使用 `string` 而不是 `bytes32`

### 12.2 优化建议

- 用 `uint128` 代替 `uint256`（如果够用）
- 批量操作代替多次调用
- 避免在循环中读写状态变量

---

## 十三、高级测试模式（了解即可）

### 13.1 不变性测试（Invariant Testing）

> 测试"无论怎么操作，某些条件永远成立"。

例如：总供应量不变、余额非负。

需要写"状态机" + 随机操作序列。

### 13.2 差分测试

> 用两个不同实现（比如新旧版本）跑相同输入，结果应该一致。

---

## 十四、集成与协作

### 14.1 和 Hardhat 一起用

- 把 Foundry 测试放在 `test/foundry/`
- Hardhat 负责部署，Foundry 负责深度测试

### 14.2 GitHub Actions CI

在 `.github/workflows/test.yml` 中：

```yaml
- name: Run Forge tests
  run: forge test
```

每次 push 自动跑测试！

---

## 十五、调试技巧

### 15.1 详细日志

```bash
forge test -vv     # 显示事件
forge test -vvv    # 显示调用栈
forge test -vvvv   # 显示存储变化
forge test -vvvvv  # 显示汇编级别（慎用）
```

### 15.2 看失败回溯

测试失败时，Foundry 会告诉你：
- 哪一行断言失败
- 当前变量值
- 调用路径

---

## 十六、安全工具集成

### 16.1 静态分析：`slither` 或 `solstat`

虽然 Foundry 本身不包含，但你可以：

```bash
pip install slither-analyzer
slither .
```

> 检查常见漏洞：重入、整数溢出、权限问题等。

---

# 🧪 Foundry 多环境联合调试完整指南  
> **本地（Anvil） → Sepolia 测试网 → Polygon 主网**

---

## 十七、多环境配置文件管理

### ✅ 目标：用 `foundry.toml` 管理网络，用 `.env` 管理敏感信息

---

### 17.1 `foundry.toml` —— 网络、编译、验证配置

```toml
# foundry.toml
[profile.default]
src = "src"                 # 合约源码目录
out = "out"                 # 编译输出目录
libs = ["lib"]              # 依赖库目录
solc_version = "0.8.20"     # Solidity 编译器版本
optimizer = true            # 启用优化器
optimizer_runs = 1000       # 优化器运行次数（影响 Gas）

# === 网络 RPC 端点别名（方便切换）===
[rpc_endpoints]
anvil = "http://localhost:8545"
sepolia = "https://sepolia.infura.io/v3/${INFURA_PROJECT_ID}"
polygon = "https://polygon-rpc.com"

# === 区块链浏览器 API Key（用于合约验证）===
[etherscan]
sepolia = { key = "${SEPOLIA_ETHERSCAN_KEY}" }
polygon = { key = "${POLYGONSCAN_API_KEY}" }
```

> 💡 `${VAR}` 表示从环境变量读取，**不会硬编码敏感信息**。

---

### 17.2 `.env` 文件 —— 存放私钥和 API Key（**绝不提交到 Git！**）

```env
# .env
# === 私钥 ===
PRIVATE_KEY_ANVIL=0xac0974bec39a17e36ba4a6b4d238ff944bacb478cbed5efcae784d7bf4f2ff80
PRIVATE_KEY_SEPOLIA=你的_sepolia测试网私钥（仅用于测试）
# PRIVATE_KEY_POLYGON=你的_polygon主网私钥（强烈建议不要放这里！见后文）

# === Infura（可选，也可用 Alchemy 或 public RPC）===
INFURA_PROJECT_ID=你的_infura_project_id

# === 区块链浏览器 API Key ===
SEPOLIA_ETHERSCAN_KEY=你的_etherscan_api_key
POLYGONSCAN_API_KEY=你的_polygonscan_api_key
```

> 🔒 **安全操作**：
> ```bash
> # 确保 .env 不被 Git 跟踪
> echo ".env" >> .gitignore
> ```

---

## 十八、如何在不同环境运行测试和部署？

### ✅ 原则：
- **测试（`forge test`）只在本地运行**
- **部署（`forge script`）可跨环境**

---

### 18.1 本地测试（Anvil）

```bash
# 终端1：启动本地测试网
anvil

# 终端2：运行单元测试（自动连 http://127.0.0.1:8545）
forge test
```

> ✅ 无需任何参数，`forge test` 默认连本地节点。

---

### 18.2 部署到 Sepolia 测试网

```bash
# 加载环境变量
source .env

# 部署命令
forge script script/Deploy.s.sol \
  --rpc-url sepolia \                # 使用 foundry.toml 中定义的 sepolia 别名
  --private-key $PRIVATE_KEY_SEPOLIA \  # 从 .env 读取私钥
  --broadcast \                      # 真实发送交易（不是模拟）
  --verify                           # 部署后自动验证合约
```

> 📌 参数说明：
> - `--rpc-url sepolia`：自动使用 `foundry.toml` 中的 URL
> - `--broadcast`：实际上链（不加则只模拟）
> - `--verify`：部署后立即调用 Etherscan 验证

---

### 18.3 部署到 Polygon 主网（**安全版**）

> ⚠️ **主网私钥绝不建议写进 `.env`！**

```bash
# 安全方式：手动输入私钥（终端不显示）
read -s PK

# 执行部署
forge script script/Deploy.s.sol \
  --rpc-url polygon \    # 使用 foundry.toml 中的 polygon 别名
  --private-key $PK \    # 使用刚输入的临时变量
  --broadcast \
  --verify

# 立即清除私钥变量
unset PK
```

> ✅ 这样私钥**不会留在历史记录、文件或内存中太久**。

---

## 十九、部署后如何开源合约？

"开源" = **在区块链浏览器上验证源代码**，让所有人可读。

### 19.1 自动验证（推荐）

在部署命令中加 `--verify`（如上所示），Foundry 会自动完成验证。

### 19.2 手动验证（如果自动失败）

```bash
# 验证 Sepolia 合约
forge verify-contract \
  --chain sepolia \                  # 网络名称（必须与部署一致）
  0xYourContractAddress \            # 替换为实际合约地址
  src/MyContract.sol:MyContract      # 合约路径:合约名

# 验证 Polygon 合约
forge verify-contract \
  --chain polygon \
  0xYourContractAddress \
  src/MyContract.sol:MyContract
```

> ✅ 验证成功后，访问：
> - Sepolia: https://sepolia.etherscan.io/address/0x...
> - Polygon: https://polygonscan.com/address/0x...
>
> 点击 **"Contract"** 标签，看到源代码 = 开源成功！

---

## 二十、如何安全切换网络？

Foundry 通过 **`--rpc-url` + 网络别名** 实现无缝切换。

| 网络       | 命令中的 `--rpc-url` 值            |
| ---------- | ---------------------------------- |
| 本地 Anvil | `http://localhost:8545` 或 `anvil` |
| Sepolia    | `sepolia`                          |
| Polygon    | `polygon`                          |

### ✅ 切换示例

```bash
# 查看当前链 ID（验证连的是哪条链）
cast chain --rpc-url anvil      # 输出: 31337（Anvil）
cast chain --rpc-url sepolia    # 输出: Sepolia
cast chain --rpc-url polygon    # 输出: Polygon Mainnet
```

> 💡 只要 `foundry.toml` 中定义了别名，就可以直接用名字，不用记长 URL。

---

## 二十一、私钥如何管理？（安全第一！）

### 🛡️ 分层管理策略

| 环境               | 私钥来源                       | 是否可存 `.env` | 建议               |
| ------------------ | ------------------------------ | --------------- | ------------------ |
| **本地 Anvil**     | 固定测试私钥（如 `0xac09...`） | ✅ 可以          | 无风险             |
| **Sepolia 测试网** | 专用测试钱包                   | ✅ 可以          | **不要存主网资产** |
| **Polygon 主网**   | 主网钱包私钥                   | ❌ **绝对不要**  | 手动输入或硬件钱包 |

---

### 🔐 主网私钥安全操作（强烈推荐）

#### ✅ 方法：临时输入 + 立即清除

```bash
# 1. 输入私钥（-s 表示不回显）
read -s PK

# 2. 使用（部署或发交易）
forge script ... --private-key $PK --rpc-url polygon --broadcast

# 3. 立即删除变量
unset PK

# 4. （可选）清空终端历史
history -c
```

> ❌ 绝对不要：
> - `echo "PRIVATE_KEY=..." >> .env`
> - 把私钥写在脚本或命令历史中
> - 用主网私钥跑 `forge test`

---

## 二十二、📌 完整工作流命令汇总（可直接复制）

### 1. 本地测试
```bash
anvil  # 新终端
forge test
```

### 2. 部署到 Sepolia（测试网）
```bash
source .env
forge script script/Deploy.s.sol --rpc-url sepolia --private-key $PRIVATE_KEY_SEPOLIA --broadcast --verify
```

### 3. 部署到 Polygon（主网，安全版）
```bash
read -s PK
forge script script/Deploy.s.sol --rpc-url polygon --private-key $PK --broadcast --verify
unset PK
```

### 4. 手动验证（如果需要）
```bash
forge verify-contract --chain polygon 0xYourAddress src/MyContract.sol:MyContract
```

### 5. 开源到 GitHub
```bash
echo ".env" >> .gitignore
git init
git add .
git commit -m "feat: deploy and verify contract"
git remote add origin https://github.com/yourname/your-repo.git
git push -u origin main
```

---

## ✅ 最终效果

| 步骤         | 成果               |
| ------------ | ------------------ |
| 本地测试     | 快速、免费、全覆盖 |
| Sepolia 验证 | 真实网络行为确认   |
| Polygon 部署 | 安全上线主网       |
| 合约验证     | 链上开源，建立信任 |
| GitHub 开源  | 社区可审计、可协作 |

---

# 🎉 总结： Foundry 学习路线

1. **装好 Foundry** → `foundryup`
2. **写一个简单合约**（比如 Counter）
3. **写测试** → 用 `assertEq` + `vm.prank`
4. **本地跑 Anvil** → 部署 + Cast 交互
5. **加依赖**（如 OpenZeppelin ERC20）
6. **写部署脚本** → 用环境变量
7. **上测试网** → Sepolia + Etherscan 验证

> 💡 **记住：Foundry 的核心思想是——用 Solidity 写一切（合约 + 测试 + 部署），不用 JavaScript！**
