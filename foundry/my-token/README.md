# MyToken - ERC20代币合约

一个基于OpenZeppelin的标准ERC20代币合约，使用Foundry框架进行开发和测试。

## 📋 项目概述

MyToken是一个简单而完整的ERC20代币实现，具有以下特性：

- **标准ERC20功能**：转账、授权、余额查询等
- **可配置参数**：代币名称、符号、初始供应量
- **安全性**：基于OpenZeppelin的经过审计的合约库
- **全面测试**：包含单元测试、边界测试、模糊测试和集成测试

## 🏗️ 项目结构

```
my-token/
├── src/
│   └── MyToken.sol          # 主合约文件
├── test/
│   └── MyTokenTest.sol      # 测试文件
├── script/
│   └── DeployMyToken.s.sol  # 部署脚本
├── lib/                     # 依赖库
├── foundry.toml            # Foundry配置
└── README.md               # 项目文档
```

## 🔧 技术栈

- **Solidity**: ^0.8.25
- **Foundry**: 开发框架
- **OpenZeppelin**: 安全的智能合约库
- **Forge**: 测试和编译工具

## 📦 合约详情

### MyToken.sol

```solidity
contract MyToken is ERC20 { 
    constructor(string memory name_, string memory symbol_, uint256 initialSupply) 
        ERC20(name_, symbol_) {
        _mint(msg.sender, initialSupply);  
    } 
}
```

**构造函数参数：**
- `name_`: 代币名称（如："MyToken"）
- `symbol_`: 代币符号（如："MTK"）
- `initialSupply`: 初始供应量（单位：wei）

## 🧪 测试套件

测试文件 `MyTokenTest.sol` 包含全面的测试覆盖：

### 测试类别

#### 1. 构造函数测试
- ✅ 正确设置代币名称
- ✅ 正确设置代币符号
- ✅ 正确设置小数位数（18位）
- ✅ 正确铸造初始供应量
- ✅ 发射Transfer事件

#### 2. 基础ERC20功能测试
- ✅ `transfer()` - 基本转账功能
- ✅ `approve()` - 授权功能
- ✅ `transferFrom()` - 授权转账功能
- ✅ 事件发射验证

#### 3. 边界条件和错误情况测试
- ✅ 零金额转账
- ✅ 自转账
- ❌ 超过余额转账（应失败）
- ❌ 向零地址转账（应失败）
- ❌ 超过授权额度转账（应失败）
- ❌ 未授权转账（应失败）

#### 4. 模糊测试（Fuzz Testing）
- 🎲 随机金额转账测试
- 🎲 随机金额授权测试
- 🎲 随机金额授权转账测试

#### 5. 不变量测试
- 🔒 总供应量保持不变
- 🔒 所有余额之和等于总供应量

#### 6. 集成测试
- 🔄 复杂转账场景：owner → alice → bob → charlie
- 🔄 复杂授权转账场景

### 测试常量

```solidity
string constant TOKEN_NAME = "MyToken";
string constant TOKEN_SYMBOL = "MTK";
uint256 constant INITIAL_SUPPLY = 10_000_000_000 * 1e18; // 100亿代币
uint256 constant DECIMALS = 18;
```

## 🚀 快速开始

### 环境要求

- [Foundry](https://book.getfoundry.sh/getting-started/installation)
- Git

### 安装依赖

```bash
# 克隆项目
git clone <repository-url>
cd my-token

# 安装依赖
forge install
```

### 编译合约

```bash
forge build
```

### 运行测试

```bash
# 运行所有测试
forge test

# 运行测试并显示详细输出
forge test -vvv

# 运行特定测试
forge test --match-test test_Transfer

# 运行模糊测试
forge test --match-test testFuzz

# 生成测试覆盖率报告
forge coverage
```

### 测试输出示例

```bash
Running 20 tests for test/MyTokenTest.sol:MyTokenFoundryTest
[PASS] test_Approve() (gas: 46327)
[PASS] test_ApproveEmitsEvent() (gas: 46349)
[PASS] test_BalanceSumEqualsTotalSupply() (gas: 130691)
[PASS] test_ComplexApprovalScenario() (gas: 142156)
[PASS] test_ComplexTransferScenario() (gas: 108371)
[PASS] test_ConstructorEmitsTransferEvent() (gas: 1221070)
[PASS] test_ConstructorMintsInitialSupply() (gas: 12580)
[PASS] test_ConstructorSetsDecimals() (gas: 7726)
[PASS] test_ConstructorSetsName() (gas: 9816)
[PASS] test_ConstructorSetsSymbol() (gas: 9838)
[PASS] test_Transfer() (gas: 51309)
[PASS] test_TransferEmitsEvent() (gas: 51331)
[PASS] test_TransferExceedsBalance() (gas: 13168)
[PASS] test_TransferFrom() (gas: 97659)
[PASS] test_TransferFromEmitsEvent() (gas: 74677)
[PASS] test_TransferFromExceedsAllowance() (gas: 49006)
[PASS] test_TransferFromExceedsBalance() (gas: 75438)
[PASS] test_TransferFromWithoutApproval() (gas: 13190)
[PASS] test_TransferToSelf() (gas: 28531)
[PASS] test_TransferToZeroAddress() (gas: 13146)
[PASS] test_TransferZeroAmount() (gas: 28509)
Test result: ok. 21 passed; 0 failed; finished in 15.89ms
```

## 🌐 部署

### 环境变量设置

创建 `.env` 文件：

```bash
# 部署者私钥（测试网）
PRIVATE_KEY_SEPOLIA=your_private_key_here

# Infura项目ID（可选）
INFURA_PROJECT_ID=your_infura_project_id

# Etherscan API Key（用于合约验证）
SEPOLIA_ETHERSCAN_KEY=your_etherscan_api_key
```

### 部署到Sepolia测试网

```bash
# 部署合约
forge script script/DeployMyToken.s.sol --rpc-url sepolia --broadcast --verify

# 或者分步执行
forge script script/DeployMyToken.s.sol --rpc-url sepolia --broadcast
```

### 合约验证

```bash
# 使用Foundry验证
forge verify-contract <CONTRACT_ADDRESS> src/MyToken.sol:MyToken \
  --chain sepolia \
  --constructor-args $(cast abi-encode "constructor(string,string,uint256)" "MyToken" "MTK" 10000000000000000000000000000)
```

## 📊 Gas优化

当前Gas使用情况：

| 函数 | Gas消耗 |
|------|---------|
| transfer() | ~51,309 |
| approve() | ~46,327 |
| transferFrom() | ~97,659 |
| 部署成本 | ~1,221,070 |

## 🔒 安全考虑

1. **使用OpenZeppelin库**：经过审计的标准实现
2. **全面测试覆盖**：包含边界条件和错误情况
3. **模糊测试**：随机输入测试合约健壮性
4. **不变量测试**：确保关键属性始终成立

## 🤝 贡献指南

1. Fork项目
2. 创建功能分支 (`git checkout -b feature/AmazingFeature`)
3. 提交更改 (`git commit -m 'Add some AmazingFeature'`)
4. 推送到分支 (`git push origin feature/AmazingFeature`)
5. 开启Pull Request

## 📄 许可证

本项目采用MIT许可证 - 查看 [LICENSE](LICENSE) 文件了解详情。

## 🔗 相关链接

- [Foundry文档](https://book.getfoundry.sh/)
- [OpenZeppelin合约](https://docs.openzeppelin.com/contracts/)
- [ERC20标准](https://eips.ethereum.org/EIPS/eip-20)
- [Solidity文档](https://docs.soliditylang.org/)

**注意**：本合约仅用于学习和测试目的。在生产环境中使用前，请进行充分的安全审计。