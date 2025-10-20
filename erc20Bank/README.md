# ERC20 Bank 项目

 ERC20 代币银行系统，包含代币合约和银行存取款功能。

## 项目概述

本项目实现了一个完整的 ERC20 代币生态系统，包括：
- **ERC20Token**: 标准的 ERC20 代币合约
- **Bank**: 基础银行合约，支持代币存取款
- **BigBank**: 增强版银行合约，支持更多功能

## 合约功能

### ERC20Token (Hai Token)
- 代币名称: Hai Token
- 代币符号: HAI
- 总供应量: 100,000,000 HAI
- 支持标准 ERC20 功能：转账、授权、余额查询等

### Bank 合约
- 支持 ERC20 代币存款
- 支持提取存款
- 记录用户存款余额
- 事件日志记录

### BigBank 合约
- 继承 Bank 的所有功能
- 支持更大金额的存取操作
- 增强的安全性检查

## 部署信息

### Sepolia 测试网部署地址

| 合约名称 | 地址 | Etherscan 链接 |
|---------|------|---------------|
| ERC20Token (HAI) | `0x2fDD1d135257E3b90A92Ee94854d56AEe55a1438` | [查看合约](https://sepolia.etherscan.io/address/0x2fdd1d135257e3b90a92ee94854d56aee55a1438) |
| Bank | `0xc6ee41c31a0534bE45f9F45065Fe4077FAE81993` | [查看合约](https://sepolia.etherscan.io/address/0xc6ee41c31a0534be45f9f45065fe4077fae81993) |
| BigBank | `0x8F01b3F0eb756C74f18f3448e1049d710Cc8BC16` | [查看合约](https://sepolia.etherscan.io/address/0x8f01b3f0eb756c74f18f3448e1049d710cc8bc16) |

### 部署详情
- **网络**: Sepolia 测试网
- **验证状态**: ✅ 所有合约已在 Etherscan 上开源验证

## 技术栈

- **开发框架**: Foundry
- **智能合约语言**: Solidity ^0.8.25
- **测试框架**: Forge
- **部署工具**: Forge Script
- **网络**: Ethereum Sepolia Testnet

## 项目结构

```
erc20Bank/
├── src/
│   ├── ERC20Token.sol      # ERC20 代币合约
│   ├── Bank.sol            # 基础银行合约
│   ├── BigBank.sol         # 增强银行合约
│   └── IBank.sol           # 银行接口
├── script/
│   ├── Deploy.s.sol        # 本地部署脚本
│   └── SepoliaDeployScript.s.sol  # Sepolia 部署脚本
├── test/
│   └── BankIntegrationTest.sol    # 集成测试
├── broadcast/              # 部署记录
└── foundry.toml           # Foundry 配置
```

## 快速开始

### 环境要求
- Foundry 工具链
- Git

### 安装依赖
```bash
# 克隆项目
git clone <repository-url>
cd erc20Bank

# 安装 Foundry 依赖
forge install
```

### 编译合约
```bash
forge build
```

### 运行测试
```bash
forge test
```

### 本地部署
```bash
# 启动本地节点
anvil

# 部署到本地网络
forge script script/Deploy.s.sol --rpc-url http://localhost:8545 --broadcast
```

### Sepolia 测试网部署
```bash
# 设置环境变量（在 .env 文件中）
SEPOLIA_RPC_URL="https://sepolia.infura.io/v3/<YOUR_API_KEY>"
PRIVATE_KEY="<YOUR_PRIVATE_KEY>"
ETHERSCAN_API_KEY="<YOUR_ETHERSCAN_API_KEY>"

# 部署到 Sepolia 测试网
source .env && forge script script/SepoliaDeployScript.s.sol --rpc-url $SEPOLIA_RPC_URL --broadcast --private-key $PRIVATE_KEY

# 验证合约（部署后执行）
# 验证 ERC20Token 合约
source .env && forge verify-contract <ERC20_CONTRACT_ADDRESS> src/ERC20Token.sol:ERC20Token --rpc-url $SEPOLIA_RPC_URL --etherscan-api-key $ETHERSCAN_API_KEY --constructor-args $(cast abi-encode "constructor(string,string,uint256)" "Hai Token" "HAI" "100000000000000000000000000")

# 验证 Bank 合约
source .env && forge verify-contract <BANK_CONTRACT_ADDRESS> src/Bank.sol:Bank --rpc-url $SEPOLIA_RPC_URL --etherscan-api-key $ETHERSCAN_API_KEY --constructor-args $(cast abi-encode "constructor(address)" "<ERC20_CONTRACT_ADDRESS>")

# 验证 BigBank 合约
source .env && forge verify-contract <BIGBANK_CONTRACT_ADDRESS> src/BigBank.sol:BigBank --rpc-url $SEPOLIA_RPC_URL --etherscan-api-key $ETHERSCAN_API_KEY --constructor-args $(cast abi-encode "constructor(address)" "<ERC20_CONTRACT_ADDRESS>")
```

## 合约交互示例

### 使用 Cast 工具交互

#### ERC20 代币基本操作

##### 查询代币基本信息
```bash
# 查询代币名称
cast call 0x2fDD1d135257E3b90A92Ee94854d56AEe55a1438 "name()" --rpc-url https://sepolia.infura.io/v3/<API_KEY>

# 查询代币符号
cast call 0x2fDD1d135257E3b90A92Ee94854d56AEe55a1438 "symbol()" --rpc-url https://sepolia.infura.io/v3/<API_KEY>

# 查询代币精度
cast call 0x2fDD1d135257E3b90A92Ee94854d56AEe55a1438 "decimals()" --rpc-url https://sepolia.infura.io/v3/<API_KEY>

# 查询总供应量
cast call 0x2fDD1d135257E3b90A92Ee94854d56AEe55a1438 "totalSupply()" --rpc-url https://sepolia.infura.io/v3/<API_KEY>
```

##### 查询余额和授权
```bash
# 查询指定地址的代币余额
cast call 0x2fDD1d135257E3b90A92Ee94854d56AEe55a1438 "balanceOf(address)" <用户地址> --rpc-url https://sepolia.infura.io/v3/<API_KEY>

# 查询授权额度
cast call 0x2fDD1d135257E3b90A92Ee94854d56AEe55a1438 "allowance(address,address)" <所有者地址> <被授权地址> --rpc-url https://sepolia.infura.io/v3/<API_KEY>
```

##### 代币转账操作
```bash
# 直接转账
cast send 0x2fDD1d135257E3b90A92Ee94854d56AEe55a1438 "transfer(address,uint256)" <接收地址> 1000000000000000000 --private-key <私钥> --rpc-url https://sepolia.infura.io/v3/<API_KEY>

# 授权操作
cast send 0x2fDD1d135257E3b90A92Ee94854d56AEe55a1438 "approve(address,uint256)" <被授权地址> 1000000000000000000 --private-key <私钥> --rpc-url https://sepolia.infura.io/v3/<API_KEY>

# 代理转账（需要先授权）
cast send 0x2fDD1d135257E3b90A92Ee94854d56AEe55a1438 "transferFrom(address,address,uint256)" <发送方地址> <接收方地址> 1000000000000000000 --private-key <私钥> --rpc-url https://sepolia.infura.io/v3/<API_KEY>
```

#### Bank 合约操作

##### 查询银行信息
```bash
# 查询银行关联的代币地址
cast call 0xc6ee41c31a0534bE45f9F45065Fe4077FAE81993 "token()" --rpc-url https://sepolia.infura.io/v3/<API_KEY>

# 查询用户在银行的存款余额
cast call 0xc6ee41c31a0534bE45f9F45065Fe4077FAE81993 "balanceOf(address)" <用户地址> --rpc-url https://sepolia.infura.io/v3/<API_KEY>

# 查询银行总存款
cast call 0xc6ee41c31a0534bE45f9F45065Fe4077FAE81993 "totalSupply()" --rpc-url https://sepolia.infura.io/v3/<API_KEY>
```

##### 银行存取款操作
```bash
# 1. 向银行存款（需要先授权代币给银行）
# 授权银行使用代币
cast send 0x2fDD1d135257E3b90A92Ee94854d56AEe55a1438 "approve(address,uint256)" 0xc6ee41c31a0534bE45f9F45065Fe4077FAE81993 1000000000000000000 --private-key <私钥> --rpc-url https://sepolia.infura.io/v3/<API_KEY>

# 存款到银行
cast send 0xc6ee41c31a0534bE45f9F45065Fe4077FAE81993 "deposit(uint256)" 1000000000000000000 --private-key <私钥> --rpc-url https://sepolia.infura.io/v3/<API_KEY>

# 2. 从银行提款
cast send 0xc6ee41c31a0534bE45f9F45065Fe4077FAE81993 "withdraw(uint256)" 500000000000000000 --private-key <私钥> --rpc-url https://sepolia.infura.io/v3/<API_KEY>

# 3. 提取所有存款
cast send 0xc6ee41c31a0534bE45f9F45065Fe4077FAE81993 "withdrawAll()" --private-key <私钥> --rpc-url https://sepolia.infura.io/v3/<API_KEY>
```

#### BigBank 合约操作

BigBank 合约继承了 Bank 的所有功能，操作方法相同，只需要将合约地址替换为 BigBank 地址：

```bash
# BigBank 合约地址: 0x8F01b3F0eb756C74f18f3448e1049d710Cc8BC16

# 查询 BigBank 存款余额
cast call 0x8F01b3F0eb756C74f18f3448e1049d710Cc8BC16 "balanceOf(address)" <用户地址> --rpc-url https://sepolia.infura.io/v3/<API_KEY>

# 向 BigBank 存款
cast send 0x2fDD1d135257E3b90A92Ee94854d56AEe55a1438 "approve(address,uint256)" 0x8F01b3F0eb756C74f18f3448e1049d710Cc8BC16 1000000000000000000 --private-key <私钥> --rpc-url https://sepolia.infura.io/v3/<API_KEY>
cast send 0x8F01b3F0eb756C74f18f3448e1049d710Cc8BC16 "deposit(uint256)" 1000000000000000000 --private-key <私钥> --rpc-url https://sepolia.infura.io/v3/<API_KEY>
```

#### 实用工具命令

##### 单位转换
```bash
# 将 Wei 转换为 Ether
cast to-unit 1000000000000000000 ether

# 将 Ether 转换为 Wei  
cast to-wei 1 ether

# 将十六进制转换为十进制
cast to-dec 0x1

# 将十进制转换为十六进制
cast to-hex 1000000000000000000
```

##### 地址和哈希工具
```bash
# 计算合约地址（CREATE）
cast compute-address <部署者地址> --nonce <nonce>

# 生成随机地址
cast wallet new

# 从私钥获取地址
cast wallet address --private-key <私钥>
```

##### 交易查询
```bash
# 查询交易详情
cast tx <交易哈希> --rpc-url https://sepolia.infura.io/v3/<API_KEY>

# 查询交易收据
cast receipt <交易哈希> --rpc-url https://sepolia.infura.io/v3/<API_KEY>

# 查询区块信息
cast block <区块号> --rpc-url https://sepolia.infura.io/v3/<API_KEY>
```

### 环境变量设置

为了简化命令，建议设置环境变量：

```bash
# 在 .env 文件中设置
export SEPOLIA_RPC_URL="https://sepolia.infura.io/v3/<YOUR_API_KEY>"
export PRIVATE_KEY="<YOUR_PRIVATE_KEY>"
export HAI_TOKEN="0x2fDD1d135257E3b90A92Ee94854d56AEe55a1438"
export BANK="0xc6ee41c31a0534bE45f9F45065Fe4077FAE81993"
export BIG_BANK="0x8F01b3F0eb756C74f18f3448e1049d710Cc8BC16"

# 使用环境变量的示例
cast call $HAI_TOKEN "balanceOf(address)" <地址> --rpc-url $SEPOLIA_RPC_URL
```

## 安全考虑

- 所有合约都经过了完整的测试
- 使用了 OpenZeppelin 的安全模式
- 实现了适当的访问控制
- 包含了重入攻击防护

## 许可证

MIT License

## 贡献

欢迎提交 Issue 和 Pull Request！

## 联系方式

如有问题，请通过 GitHub Issues 联系。