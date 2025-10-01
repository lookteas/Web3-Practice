# ERC20 银行项目

基于ERC20代币的银行系统智能合约项目，实现了代币的存取功能，并支持代币转账回调机制。同时目录中还包含了两个独立的ERC20代币合约实现，用于学习和测试。

## 项目结构

```
erc20/
├── BaseERC20.sol     - 基础ERC20代币实现（独立合约）
├── MyToken.sol       - 可铸造和销毁的ERC20代币（独立合约）
│
├── 银行系统项目文件：
    ├── ExpendERC20.sol     - 扩展的ERC20代币合约
    ├── ITokenReceiver.sol   - 代币接收回调接口
    ├── TokenBank.sol        - 基础银行合约
    └── TokenBankV2.sol      - 支持自动回调存款的升级版银行合约
```

### 独立合约说明

> BaseERC20.sol  和 MyToken.sol  **两个合约仅提供学习参考，与下面的银行项目无法**

#### BaseERC20.sol
- 基础ERC20代币的标准实现
- 包含代币基本信息（名称、符号、小数位）
- 实现了转账、授权等标准ERC20功能
- 初始供应量：100,000,000 tokens (18位小数)
- 适合学习ERC20标准的基本实现

#### MyToken.sol
- 基于OpenZeppelin的ERC20实现
- 继承自ERC20和Ownable合约
- 包含铸造(mint)和销毁(burn)功能
- 初始供应量：10,000,000 tokens (18位小数)
- 展示了如何使用OpenZeppelin库实现安全的ERC20代币

## 银行系统项目说明

### ExpendERC20.sol
- 实现了标准ERC20代币的基本功能
- 扩展了`transferWithCallback`方法，支持代币转账时的回调机制
- 初始总供应量：100,000,000 tokens (带18位小数)
- 支持标准的转账、授权等ERC20功能

### ITokenReceiver.sol
- 定义了代币接收的回调接口
- 包含`tokensReceived`函数声明，用于处理代币接收事件

### TokenBank.sol
- 基础银行合约，用于存取ERC20代币
- 主要功能：
  - 存款：用户可以存入ExpendERC20代币
  - 提款：用户可以提取之前存入的代币
  - 余额查询：查看用户的存款余额

### TokenBankV2.sol
- 继承自TokenBank，增加了自动存款功能
- 实现了ITokenReceiver接口
- 当用户通过`transferWithCallback`转账时，自动记录存款
- 无需用户手动调用deposit函数

## 部署顺序

1. 部署 `ExpendERC20.sol`
2. 使用ExpendERC20合约地址部署 `TokenBank.sol`
3. 使用相同的ExpendERC20地址部署 `TokenBankV2.sol`

注意：`ITokenReceiver.sol`是接口文件，不需要部署。

## 使用流程

### 基础银行（TokenBank）使用流程：

1. 用户需要先获得ExpendERC20代币
2. 调用ExpendERC20的`approve`函数，授权TokenBank合约
3. 调用TokenBank的`deposit`函数存入代币
4. 可以随时调用`withdraw`函数提取代币

```solidity
// 授权银行合约
token.approve(bankAddress, amount);
// 存款
bank.deposit(amount);
// 提款
bank.withdraw(amount);
```

### 升级版银行（TokenBankV2）使用流程：

1. 用户获得ExpendERC20代币
2. 直接调用ExpendERC20的`transferWithCallback`函数转账给银行
3. 存款会自动记录，无需额外操作
4. 提款操作与基础版相同

```solidity
// 直接转账，自动存款
token.transferWithCallback(bankV2Address, amount);
// 提款
bankV2.withdraw(amount);
```

## 安全考虑

1. 所有转账操作都有余额检查
2. TokenBankV2的回调函数有严格的安全检查：
   - 只接受来自正确代币合约的回调
   - 验证接收地址是否为银行合约本身
3. 防止整数溢出（使用Solidity 0.8.x的内置检查）
4. 所有关键操作都有事件日志

## 测试建议

1. 测试基本的存取款功能
2. 验证授权机制是否正常工作
3. 测试回调存款功能
4. 检查各种边界条件：
   - 零地址检查
   - 余额不足
   - 未授权操作
   - 重复存取款

## 最佳实践

1. 部署前确保所有合约代码已经过审计
2. 使用安全的开发工具和框架（如Hardhat、Truffle）
3. 在测试网络充分测试后再部署到主网
4. 保持合约的可升级性
5. 记录所有重要操作的事件日志