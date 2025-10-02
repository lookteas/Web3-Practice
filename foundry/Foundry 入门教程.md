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

### 4.3 常用断言（Assertions）详解

> 💡 断言(assertion)是程序中的一段逻辑(如：一个结果为真或假的逻辑判断)，目的为了验证开发者预期的结果——当程序执行到断言的位置时，对应的断言应该为真。若断言不为真时，程序会中止执行，并给出错误信息。

#### 1. 相等性断言

```solidity
// 基础相等断言
assertEq(actual, expected);        // 检查两个值是否相等
assertEq(actual, expected, "错误信息"); // 带自定义错误信息

// 示例：测试代币余额， 假如Alice钱包余额为 0，发送者钱包余额为 1000
function testTransfer() public {
    token.transfer(alice, 100);  //给alice 转账100
    assertEq(token.balanceOf(alice), 100, "Alice应该收到100个代币");
    assertEq(token.balanceOf(address(this)), 900, "发送者余额应该减少100");
}
```

**参数说明**：

- assertEq(actual, expected);

- `actual`：实际得到的值
- `expected`：期望的值  
- `"错误信息"`：可选，测试失败时显示的提示

**用途举例**：验证转账后余额、计算结果、状态变量等

#### 2. 不等断言

```solidity
assertNotEq(a, b);                 // 检查 a != b
assertNotEq(a, b, "错误信息");

// 示例：确保随机数不重复
function testRandomness() public {
    uint256 random1 = generateRandom();
    uint256 random2 = generateRandom();
    assertNotEq(random1, random2, "随机数不应该相同");
}
```

#### 3. 布尔断言

```solidity
assertTrue(condition);             // 检查条件为真
assertTrue(condition, "错误信息");
assertFalse(condition);            // 检查条件为假
assertFalse(condition, "错误信息");

// 示例：检查权限控制
function testOnlyOwner() public {
    assertTrue(contract.isOwner(owner), "owner应该有管理员权限");
    assertFalse(contract.isOwner(alice), "普通用户不应该有管理员权限");
}
```

#### 4. 数值比较断言

```solidity
assertGt(a, b);    // a > b (greater than)
assertGe(a, b);    // a >= b (greater equal)
assertLt(a, b);    // a < b (less than)
assertLe(a, b);    // a <= b (less equal)

// 示例：测试拍卖出价
function testBidding() public {
    auction.bid{value: 1 ether}();
    uint256 highestBid = auction.getHighestBid();
    
    assertGt(highestBid, 0, "最高出价应该大于0");
    assertGe(highestBid, 1 ether, "最高出价应该至少是1 ETH");
}
```

#### 5. 近似相等断言（处理精度问题）

```solidity
assertApproxEqAbs(a, b, maxDelta);     // |a - b| <= maxDelta
assertApproxEqRel(a, b, maxPercentDelta); // 相对误差检查

// 示例：测试利息计算（可能有精度误差）
function testInterestCalculation() public {
    uint256 principal = 1000 ether;
    uint256 expectedInterest = 50 ether;  // 5%年利率
    uint256 actualInterest = calculateInterest(principal, 5, 365);
    
    // 允许0.01 ETH的绝对误差
    assertApproxEqAbs(actualInterest, expectedInterest, 0.01 ether, "利息计算误差过大");
}
```

#### 6. 字符串和字节断言

```solidity
// 字符串比较
assertEq(string1, string2);

// 字节数组比较  
assertEq(bytes1, bytes2);

// 示例：测试代币名称
function testTokenMetadata() public {
    assertEq(token.name(), "MyToken", "代币名称不正确");
    assertEq(token.symbol(), "MTK", "代币符号不正确");
    assertEq(token.decimals(), 18, "小数位数应该是18");
}
```

#### 7. 数组断言

```solidity
// 数组长度和内容比较
uint256[] memory expected = new uint256[](2);
expected[0] = 100;
expected[1] = 200;

uint256[] memory actual = contract.getArray();
assertEq(actual.length, expected.length, "数组长度不匹配");
assertEq(actual, expected, "数组内容不匹配");

// 示例：测试批量操作
function testBatchTransfer() public {
    address[] memory recipients = new address[](2);
    recipients[0] = alice;
    recipients[1] = bob;
    
    uint256[] memory amounts = new uint256[](2);
    amounts[0] = 100;
    amounts[1] = 200;
    
    token.batchTransfer(recipients, amounts);
    
    assertEq(token.balanceOf(alice), 100, "Alice余额错误");
    assertEq(token.balanceOf(bob), 200, "Bob余额错误");
}
```

> ✅ **最佳实践**：
> - 总是添加有意义的错误信息，方便调试
> - 一个测试函数专注测试一个功能点
> - 使用合适的断言类型（精确 vs 近似）

---

### 4.4 核心：作弊码（Cheatcodes）详解

> 💡  **作弊码是 Foundry 的超能力，它本质是提供一系列特殊函数，允许你在测试环境中任意修改和操纵区块链的状态。让你在测试环境中模拟各种链上场景，突破正常区块链的限制。**



### 为什么需要作弊码？



在真实的区块链上，许多状态是开发者无法控制的，例如：

- `msg.sender`：谁在调用你的合约。
- `block.timestamp`：当前区块的时间戳。
- `block.number`：当前的区块高度。
- 某个地址的以太币 (ETH) 余额。

如果你想测试一个有时间锁（timelock）的合约，可能要等上几天甚至几年，如果你想测试一个只有合约所有者 (`owner`) 才能调用的函数，该如何模拟其他人的调用呢？

**作弊码就是解决这些问题的关键。** 它们让你在测试时可以随心所欲地模拟任何想要的链上环境和条件。



#### 1. 身份伪装类作弊码

##### `vm.prank(address)` - 单次身份伪装

```solidity
// 语法
vm.prank(msgSender);
// 下一次合约调用的 msg.sender 将是 msgSender

// 示例：测试只有owner能调用的函数
function testOnlyOwnerCanWithdraw() public {
    // 设置场景：合约有100 ETH
    vm.deal(address(contract), 100 ether);
    
    // 伪装成owner调用
    vm.prank(owner);
    contract.withdraw(50 ether);  // 这次调用的msg.sender是owner
    
    // 验证提取成功
    assertEq(address(contract).balance, 50 ether);
}

// 测试非owner调用会失败
function testNonOwnerCannotWithdraw() public {
    vm.deal(address(contract), 100 ether);
    
    // 伪装成普通用户
    vm.prank(alice);
    vm.expectRevert("Only owner");  // 期望这次调用失败
    contract.withdraw(50 ether);
}
```

**参数说明**：
- `msgSender`：要伪装成的地址
- **作用范围**：仅影响下一次合约调用

**用途举例**：测试权限控制、多用户交互、代理调用等

##### `vm.startPrank(address)` / `vm.stopPrank()` - 持续身份伪装

```solidity
// 语法
vm.startPrank(msgSender);
// 所有后续调用的msg.sender都是msgSender，直到stopPrank()
vm.stopPrank();

// 示例：测试用户的完整交互流程
function testUserJourney() public {
    // 给Alice一些ETH
    vm.deal(alice, 10 ether);
    
    // 开始伪装成Alice
    vm.startPrank(alice);
    
    // Alice的一系列操作
    token.approve(exchange, 1000);           // Alice授权
    exchange.deposit{value: 5 ether}();      // Alice存款
    exchange.trade(tokenA, tokenB, 100);     // Alice交易
    
    // 停止伪装
    vm.stopPrank();
    
    // 验证Alice的最终状态
    assertEq(token.balanceOf(alice), 900);
}
```

**用途举例**：测试复杂的用户交互流程、批量操作

#### 2. 资产操作类作弊码

##### `vm.deal(address, amount)` - 设置ETH余额

```solidity
// 语法
vm.deal(target, newBalance);

// 示例：测试大额转账
function testLargeTransfer() public {
    // 给用户1000 ETH（测试环境可以随意创造）
    vm.deal(alice, 1000 ether);
    assertEq(alice.balance, 1000 ether);
    
    // 测试转账功能
    vm.prank(alice);
    payable(bob).transfer(500 ether);
    
    assertEq(alice.balance, 500 ether);
    assertEq(bob.balance, 500 ether);
}
```

**参数说明**：
- `target`：要设置余额的地址
- `newBalance`：新的ETH余额（单位：wei）

**用途举例**：模拟富有用户、测试大额交易、设置初始状态

##### `vm.hoax(address, amount)` - 组合操作：设置余额+伪装身份

```solidity
// 等价于 vm.deal(user, amount) + vm.prank(user)
vm.hoax(user, 10 ether);
contract.deposit{value: 5 ether}();  // user调用，有10 ETH余额

// 示例：快速设置用户状态并执行操作
function testUserDeposit() public {
    // 一行代码：给Alice 10 ETH并伪装成她
    vm.hoax(alice, 10 ether);
    
    // Alice存款5 ETH
    vault.deposit{value: 5 ether}();
    
    // 验证结果
    assertEq(vault.balanceOf(alice), 5 ether);
    assertEq(alice.balance, 5 ether);  // 剩余5 ETH
}
```

#### 3. 时间操作类作弊码

##### `vm.warp(timestamp)` - 跳转到指定时间

```solidity
// 语法
vm.warp(newTimestamp);

// 示例：测试时间锁功能
function testTimeLock() public {
    // 创建一个7天后到期的时间锁
    uint256 unlockTime = block.timestamp + 7 days;
    timeLock.lock{value: 1 ether}(unlockTime);
    
    // 尝试立即解锁（应该失败）
    vm.expectRevert("Still locked");
    timeLock.unlock();
    
    // 跳转到7天后
    vm.warp(unlockTime);
    
    // 现在应该可以解锁了
    timeLock.unlock();
    assertEq(address(this).balance, 1 ether);
}
```

**参数说明**：
- `newTimestamp`：新的区块时间戳（Unix时间戳，秒）

**用途举例**：测试时间锁、质押到期、拍卖结束、利息计算

##### `vm.roll(blockNumber)` - 跳转到指定区块

```solidity
// 语法
vm.roll(newBlockNumber);

// 示例：测试基于区块数的逻辑
function testBlockBasedReward() public {
    uint256 startBlock = block.number;
    
    // 用户开始挖矿
    vm.prank(alice);
    miner.startMining();
    
    // 跳转100个区块后
    vm.roll(startBlock + 100);
    
    // 计算奖励（假设每个区块1个代币）
    uint256 reward = miner.calculateReward(alice);
    assertEq(reward, 100 * 1e18);  // 100个代币
}
```

#### 4. 错误测试类作弊码

##### `vm.expectRevert()` - 期望下次调用失败

```solidity
// 基础用法：期望任何revert
vm.expectRevert();
contract.riskyFunction();

// 带错误信息：期望特定错误
vm.expectRevert("Insufficient balance");
contract.withdraw(1000 ether);

// 带错误选择器：期望特定错误类型
vm.expectRevert(MyContract.InsufficientBalance.selector);
contract.withdraw(1000 ether);

// 示例：全面测试错误情况
function testWithdrawFailures() public {
    // 测试1：余额不足
    vm.expectRevert("Insufficient balance");
    contract.withdraw(1000 ether);
    
    // 测试2：未授权用户
    vm.prank(alice);
    vm.expectRevert("Not authorized");
    contract.adminWithdraw(100 ether);
    
    // 测试3：合约暂停时
    contract.pause();
    vm.expectRevert("Contract paused");
    contract.withdraw(1 ether);
}
```

**用途举例**：测试输入验证、权限控制、边界条件、异常处理

#### 5. 事件测试类作弊码

##### `vm.expectEmit()` - 期望发出特定事件

```solidity
// 语法
vm.expectEmit(checkTopic1, checkTopic2, checkTopic3, checkData);
emit ExpectedEvent(param1, param2);  // 期望的事件
contract.functionThatEmitsEvent();   // 触发事件的调用

// 示例：测试转账事件
function testTransferEvent() public {
    // 期望发出Transfer事件，检查所有参数
    vm.expectEmit(true, true, false, true);
    emit Transfer(address(this), alice, 100);
    
    // 执行转账
    token.transfer(alice, 100);
}

// 复杂示例：测试多个事件
function testComplexEvents() public {
    vm.deal(alice, 10 ether);
    
    // 期望第一个事件：Deposit
    vm.expectEmit(true, true, false, true);
    emit Deposit(alice, 5 ether);
    
    // 期望第二个事件：BalanceUpdated
    vm.expectEmit(true, false, false, true);
    emit BalanceUpdated(alice, 5 ether);
    
    // 执行操作（会发出两个事件）
    vm.prank(alice);
    vault.deposit{value: 5 ether}();
}
```

**参数说明**：
- `checkTopic1/2/3`：是否检查对应的indexed参数
- `checkData`：是否检查非indexed参数

#### 6. 存储操作类作弊码

##### `vm.store(address, slot, value)` - 直接修改存储

```solidity
// 直接修改合约存储槽
vm.store(contractAddress, bytes32(slot), bytes32(value));

// 示例：修改ERC20代币余额（紧急情况下的测试）
function testDirectBalanceModification() public {
    // 假设余额存储在slot 0的mapping中
    // mapping(address => uint256) balances; // slot 0
    
    // 计算Alice余额的存储位置
    bytes32 slot = keccak256(abi.encode(alice, 0));
    
    // 直接设置Alice有1000个代币
    vm.store(address(token), slot, bytes32(uint256(1000 * 1e18)));
    
    // 验证修改成功
    assertEq(token.balanceOf(alice), 1000 * 1e18);
}
```

**用途举例**：测试极端状态、绕过正常流程、模拟历史状态

#### 7. 快照和回滚

##### `vm.snapshot()` / `vm.revertTo(snapshotId)` - 状态快照

```solidity
// 示例：测试多种情况而不互相影响
function testMultipleScenarios() public {
    // 设置初始状态
    vm.deal(alice, 10 ether);
    token.mint(alice, 1000);
    
    // 创建快照
    uint256 snapshot = vm.snapshot();
    
    // 场景1：Alice全部卖出
    vm.prank(alice);
    exchange.sellAll();
    assertEq(token.balanceOf(alice), 0);
    
    // 回滚到快照
    vm.revertTo(snapshot);
    
    // 场景2：Alice只卖一半
    vm.prank(alice);
    exchange.sell(500);
    assertEq(token.balanceOf(alice), 500);
}
```

#### 8. 模拟外部调用

##### `vm.mockCall()` - 模拟外部合约调用

```solidity
// 语法
vm.mockCall(target, calldata, returndata);

// 示例：模拟价格预言机
function testPriceBasedLogic() public {
    address oracle = 0x1234...;
    
    // 模拟预言机返回价格为2000美元
    vm.mockCall(
        oracle,
        abi.encodeWithSignature("getPrice()"),
        abi.encode(2000 * 1e8)  // 返回2000美元
    );
    
    // 测试基于价格的逻辑
    contract.updatePriceBasedReward();
    uint256 reward = contract.getCurrentReward();
    
    // 验证高价格时奖励更高
    assertGt(reward, 1000 * 1e18);
}
```

> ✅ **作弊码使用最佳实践**：
> - 每个测试开始时设置干净的状态
> - 使用`vm.expectRevert()`测试所有错误情况  
> - 用`vm.expectEmit()`验证重要事件
> - 组合使用多个作弊码模拟复杂场景
> - 测试时间相关功能时善用`vm.warp()`

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
