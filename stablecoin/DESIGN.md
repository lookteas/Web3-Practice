# Rebase 型通缩 Token 设计文档

## 项目概述

实现一个基于 ERC-20 标准的 rebase 型通缩 Token，参考 Ampleforth (AMPL) 的设计理念。该 Token 具有自动通缩机制，每年在上一年发行量基础上下降 1%。

## 核心特性

### 1. 通缩机制
- **起始发行量**: 1 亿 Token (100,000,000)
- **通缩率**: 每年 1%
- **通缩公式**: `新发行量 = 当前发行量 × 0.99`
- **触发方式**: 通过 `rebase()` 方法手动触发或自动触发

### 2. Rebase 机制
- **份额系统**: 用户持有的是 Token 份额，而非绝对数量
- **动态余额**: `balanceOf()` 返回基于当前总供应量的实际余额
- **比例保持**: 用户在总供应量中的占比保持不变

## 技术实现方案

### 1. 核心数据结构

```solidity
contract RebaseToken {
    // 用户份额映射 (内部表示)
    mapping(address => uint256) private _shares;
    
    // 总份额数量
    uint256 private _totalShares;
    
    // 当前总供应量 (会随 rebase 变化)
    uint256 private _totalSupply;
    
    // 上次 rebase 时间
    uint256 public lastRebaseTime;
    
    // rebase 间隔 (1年 = 365天)
    uint256 public constant REBASE_INTERVAL = 365 days;
    
    // 通缩率 (1% = 99/100)
    uint256 public constant DEFLATION_RATE = 99;
    uint256 public constant DEFLATION_BASE = 100;
}
```

### 2. 关键算法

#### 2.1 余额计算
```solidity
function balanceOf(address account) public view returns (uint256) {
    if (_totalShares == 0) return 0;
    return (_shares[account] * _totalSupply) / _totalShares;
}
```

#### 2.2 份额计算
```solidity
function sharesOf(address account) public view returns (uint256) {
    return _shares[account];
}

function getSharesByAmount(uint256 amount) public view returns (uint256) {
    if (_totalSupply == 0) return amount;
    return (amount * _totalShares) / _totalSupply;
}

function getAmountByShares(uint256 shares) public view returns (uint256) {
    if (_totalShares == 0) return 0;
    return (shares * _totalSupply) / _totalShares;
}
```

#### 2.3 Rebase 逻辑
```solidity
function rebase() public returns (uint256) {
    require(canRebase(), "Rebase not available yet");
    
    uint256 newTotalSupply = (_totalSupply * DEFLATION_RATE) / DEFLATION_BASE;
    uint256 supplyDelta = _totalSupply - newTotalSupply;
    
    _totalSupply = newTotalSupply;
    lastRebaseTime = block.timestamp;
    
    emit Rebase(newTotalSupply, supplyDelta);
    return newTotalSupply;
}

function canRebase() public view returns (bool) {
    return block.timestamp >= lastRebaseTime + REBASE_INTERVAL;
}
```

### 3. ERC-20 标准实现

#### 3.1 转账逻辑
```solidity
function transfer(address to, uint256 amount) public returns (bool) {
    uint256 shares = getSharesByAmount(amount);
    _transferShares(msg.sender, to, shares);
    return true;
}

function _transferShares(address from, address to, uint256 shares) internal {
    require(from != address(0), "Transfer from zero address");
    require(to != address(0), "Transfer to zero address");
    require(_shares[from] >= shares, "Insufficient balance");
    
    _shares[from] -= shares;
    _shares[to] += shares;
    
    // 发出标准 ERC-20 Transfer 事件
    emit Transfer(from, to, getAmountByShares(shares));
}
```

#### 3.2 铸造和销毁
```solidity
function _mint(address account, uint256 amount) internal {
    require(account != address(0), "Mint to zero address");
    
    uint256 shares = getSharesByAmount(amount);
    _totalShares += shares;
    _shares[account] += shares;
    _totalSupply += amount;
    
    emit Transfer(address(0), account, amount);
}

function _burn(address account, uint256 amount) internal {
    require(account != address(0), "Burn from zero address");
    
    uint256 shares = getSharesByAmount(amount);
    require(_shares[account] >= shares, "Burn amount exceeds balance");
    
    _totalShares -= shares;
    _shares[account] -= shares;
    _totalSupply -= amount;
    
    emit Transfer(account, address(0), amount);
}
```

## 安全考虑

### 1. 精度问题
- 使用高精度计算避免舍入误差
- 在除法运算中考虑余数处理
- 设置最小转账金额限制

### 2. 重入攻击防护
- 使用 ReentrancyGuard 保护关键函数
- 遵循 Checks-Effects-Interactions 模式

### 3. 权限控制
- Rebase 功能可设置为公开或仅管理员可调用
- 考虑添加暂停机制用于紧急情况

### 4. 时间操作安全
- 使用 `block.timestamp` 而非 `block.number`
- 考虑时间戳操作的潜在风险

## 测试策略

### 1. 单元测试
- 测试 rebase 前后用户余额的正确性
- 验证份额计算的准确性
- 测试边界条件和异常情况

### 2. 集成测试
- 测试多用户场景下的 rebase 行为
- 验证转账在 rebase 前后的一致性
- 测试长期通缩的累积效应

### 3. 时间模拟测试
- 使用 Foundry 的时间跳跃功能模拟年度 rebase
- 测试多次 rebase 的复合效应

## 部署配置

### 1. 构造函数参数
```solidity
constructor(
    string memory name,
    string memory symbol,
    uint256 initialSupply
) ERC20(name, symbol) {
    _totalSupply = initialSupply;
    _totalShares = initialSupply;
    _shares[msg.sender] = initialSupply;
    lastRebaseTime = block.timestamp;
    
    emit Transfer(address(0), msg.sender, initialSupply);
}
```

### 2. 初始化参数
- **名称**: "Rebase Deflation Token"
- **符号**: "RDT"
- **初始供应量**: 100,000,000 * 10^18 (考虑 18 位小数)

## 事件定义

```solidity
event Rebase(uint256 newTotalSupply, uint256 supplyDelta);
event SharesTransfer(address indexed from, address indexed to, uint256 shares);
```

## 预期行为示例

假设 Alice 持有 1000 个 Token (占总供应量的 0.001%):

1. **初始状态**: 
   - 总供应量: 100,000,000
   - Alice 余额: 1,000
   - Alice 份额: 1,000

2. **第一次 rebase 后**:
   - 总供应量: 99,000,000 (下降 1%)
   - Alice 余额: 990 (保持 0.001% 占比)
   - Alice 份额: 1,000 (不变)

3. **第二次 rebase 后**:
   - 总供应量: 98,010,000
   - Alice 余额: 980.1
   - Alice 份额: 1,000 (不变)

## 技术栈

- **开发框架**: Foundry
- **Solidity 版本**: 0.8.25
- **测试工具**: Forge
- **部署工具**: Forge Script

## 项目结构

```
stablecoin/
├── src/
│   ├── RebaseToken.sol          # 主合约
│   └── interfaces/
│       └── IRebaseToken.sol     # 接口定义
├── test/
│   ├── RebaseToken.t.sol        # 主测试文件
│   └── utils/
│       └── TestHelper.sol       # 测试辅助工具
├── script/
│   └── Deploy.s.sol             # 部署脚本
├── foundry.toml                 # Foundry 配置
└── README.md                    # 项目说明
```

这个设计方案确保了 Token 的通缩机制能够正确工作，同时保持用户在总供应量中的相对份额不变，符合 rebase 型 Token 的核心特性。