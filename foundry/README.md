# 🧪 Foundry 开发框架学习项目

这是一个基于 Foundry 的智能合约开发学习项目，包含了 Foundry 框架的入门教程和实践项目。Foundry 是一套用 Rust 编写的 Solidity 开发工具集，提供了快速、轻量、贴近链上真实环境的开发体验。

## 📁 项目结构

```
foundry/
├── Foundry 入门教程.md    - 详细的Foundry学习教程
└── my-token/              - ERC20代币实践项目
    ├── src/               - 合约源码
    │   └── MyToken.sol    - ERC20代币合约
    ├── test/              - 测试文件
    │   └── MyTokenTest.sol
    ├── script/            - 部署脚本
    │   └── DeployMyToken.s.sol
    ├── foundry.toml       - Foundry配置文件
    └── README.md          - 项目说明文档
```

## 🛠️ Foundry 工具集

Foundry 由四个核心工具组成：

| 工具 | 功能 | 说明 |
|------|------|------|
| **Forge** | 编译、测试、部署合约 | 主要的开发工具 |
| **Cast** | 与区块链交互 | 命令行钱包和区块链浏览器 |
| **Anvil** | 本地测试网络 | 私人以太坊沙盒环境 |
| **Chisel** | 交互式Solidity REPL | 实时编写和测试代码 |

## 🚀 快速开始

### 1. 安装 Foundry

```bash
# 安装 foundryup
curl -L https://foundry.paradigm.xyz | bash

# 安装最新版本的 Foundry
foundryup
```

### 2. 验证安装

```bash
forge --version
cast --version
anvil --version
```

### 3. 创建新项目

```bash
forge init my-new-project
cd my-new-project
```

### 4. 编译合约

```bash
forge build
```

### 5. 运行测试

```bash
forge test
```

## 📚 学习资源

### 入门教程
- 📖 [Foundry 入门教程.md](./Foundry%20入门教程.md) - 完整的Foundry学习指南，包含：
  - Foundry 基础概念和安装
  - 项目创建和结构解析
  - 编译、测试、部署流程
  - 多环境配置和调试技巧
  - 实战案例和最佳实践

### 实践项目
- 🪙 [my-token](./my-token/) - ERC20代币合约项目
  - 基于OpenZeppelin的标准ERC20实现
  - 完整的测试套件（单元测试、模糊测试、集成测试）
  - 多环境部署脚本
  - Gas优化和安全性考虑

## 🔧 常用命令

### 项目管理
```bash
forge init <project-name>    # 创建新项目
forge install <dependency>   # 安装依赖
forge update                 # 更新依赖
```

### 开发流程
```bash
forge build                  # 编译合约
forge test                   # 运行测试
forge test -vvv             # 详细测试输出
forge coverage              # 测试覆盖率
```

### 部署和交互
```bash
forge script <script-path>  # 运行部署脚本
cast call <address> <sig>    # 调用合约函数
cast send <address> <sig>    # 发送交易
```

### 本地开发
```bash
anvil                        # 启动本地测试网
anvil --fork-url <rpc-url>   # 分叉主网进行测试
```

## 🎯 学习路径

1. **基础入门**
   - 阅读 [Foundry 入门教程.md](./Foundry%20入门教程.md)
   - 了解 Foundry 工具集的基本用法
   - 学习项目结构和配置文件

2. **实践操作**
   - 研究 my-token 项目的实现
   - 运行测试和部署脚本
   - 尝试修改合约和测试

3. **进阶学习**
   - 学习高级测试技巧（模糊测试、不变量测试）
   - 掌握多环境部署和配置
   - 了解Gas优化和安全最佳实践


## 🤝 贡献指南

欢迎提交 Issue 和 Pull Request 来改进这个学习项目：

1. Fork 本项目
2. 创建功能分支
3. 提交更改
4. 发起 Pull Request

## 📄 许可证

MIT License - 详见 LICENSE 文件