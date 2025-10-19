# EIP-7702 实践项目

基于 EIP-7702 的账户抽象实现，支持批量操作和代理执行。

## 项目结构

```
├── src/
│   ├── DelegateContract.sol    # EIP-7702 代理合约
│   └── TokenBank.sol          # 示例存款合约
├── test/
│   ├── DelegateContract.t.sol # 代理合约测试
│   └── TokenBank.t.sol        # 存款合约测试
├── script/
│   └── Deploy.s.sol           # 部署脚本
└── index.html                 # 前端页面
```

## 技术栈

- **合约开发**: Solidity 0.8.25
- **测试框架**: Foundry Test + 本地Anvil节点
- **部署网络**: Sepolia测试网（EIP-7702支持）
- **前端**: Viem + 原生JavaScript + HTML
- **开发模式**: 最小化、零构建开发模式

<img src="./2.jpg" style="zoom:80%;" />





<img src="./1.jpg" style="zoom:80%;" />

## 快速开始

### 1. 安装依赖

确保已安装 Foundry：
```bash
curl -L https://foundry.paradigm.xyz | bash
foundryup
```

### 2. 编译合约

```bash
forge build
```

### 3. 运行测试

```bash
forge test -vv
```

### 4. 部署到Sepolia

1. 复制环境变量文件：
```bash
cp .env.example .env
```

2. 编辑 `.env` 文件，填入你的私钥和RPC URL

3. 部署合约：
```bash
forge script script/Deploy.s.sol --rpc-url sepolia --broadcast --verify
```

## 合约功能

### DelegateContract
- 支持批量执行多个交易
- Nonce管理防止重放攻击
- ERC-1271签名验证
- 事件记录和错误处理

### TokenBank
- ETH存款和提取
- 批量存款功能
- 余额查询
- 紧急提取功能

## 前端集成

使用 Viem 库实现 EIP-7702 交易构建和发送，支持：
- 账户授权设置
- 批量操作构建
- 交易签名和发送
- 状态查询和显示

## Foundry 工具链

### Build

```shell
$ forge script script/Counter.s.sol:CounterScript --rpc-url <your_rpc_url> --private-key <your_private_key>
```

### Cast

```shell
$ cast <subcommand>
```

### Help

```shell
$ forge --help
$ anvil --help
$ cast --help
```
