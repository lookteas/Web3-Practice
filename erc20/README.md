# ERC20 代币项目

这是一个基于 ERC20 标准的代币合约项目，用于 DeFi 生态系统。

## 项目结构

```
erc20/
├── BaseERC20.sol   - ERC20 基础合约实现
└── MyToken.sol     - 自定义代币合约
```

## 合约说明

### BaseERC20.sol

基础 ERC20 代币合约，实现了 ERC20 标准的所有核心功能：

- 代币基本信息（名称、符号、小数位数）
- 代币总供应量管理
- 账户余额查询
- 代币转账功能
- 授权和委托转账
- 标准 ERC20 事件

### MyToken.sol

自定义 ERC20 代币合约，继承自 BaseERC20，添加了以下特性：

- 可铸造（Mintable）：允许创建新代币
- 可销毁（Burnable）：允许销毁代币
- 权限控制：只有合约所有者可以铸造代币
- DeFi 生态系统集成支持

## 主要功能

1. **代币铸造**
   - 合约所有者可以创建新代币
   - 铸造事件通知

2. **代币转账**
   - 直接转账
   - 授权转账
   - 批量转账

3. **余额管理**
   - 查询账户余额
   - 查询授权额度
   - 查询总供应量

4. **权限控制**
   - 所有者管理
   - 铸造权限控制
   - 合约升级权限（如果需要）

## 使用方法

1. **部署合约**
   ```solidity
   // 部署 MyToken 合约
   constructor(string memory name, string memory symbol) BaseERC20(name, symbol) {
       // 初始化代币参数
   }
   ```

2. **铸造代币**
   ```solidity
   // 只有合约所有者可以调用
   function mint(address to, uint256 amount) public onlyOwner {
       _mint(to, amount);
   }
   ```

3. **转账代币**
   ```solidity
   // 直接转账
   function transfer(address to, uint256 amount) public returns (bool)

   // 授权转账
   function transferFrom(address from, address to, uint256 amount) public returns (bool)
   ```

4. **查询余额**
   ```solidity
   // 查询账户余额
   function balanceOf(address account) public view returns (uint256)

   // 查询授权额度
   function allowance(address owner, address spender) public view returns (uint256)
   ```

## 安全性考虑

1. **溢出保护**
   - 使用 SafeMath 库防止数值溢出
   - 严格的余额检查

2. **权限控制**
   - 所有者权限管理
   - 铸造权限限制
   - 转账限制（如果需要）

3. **重入攻击防护**
   - 检查-生效-交互模式
   - 状态变量保护

## 测试

建议在部署到主网之前进行以下测试：

1. 单元测试
   - 基本功能测试
   - 权限控制测试
   - 边界条件测试

2. 集成测试
   - DeFi 协议交互测试
   - 多合约交互测试

3. 安全测试
   - 溢出测试
   - 权限测试
   - 重入攻击测试

## 部署检查清单

- [ ] 合约参数配置正确
- [ ] 所有测试通过
- [ ] 代码审计完成
- [ ] Gas 优化检查
- [ ] 文档更新完整
- [ ] 部署脚本准备就绪

## 注意事项

1. 确保理解 ERC20 标准的所有要求
2. 部署前进行充分测试
3. 考虑 Gas 优化
4. 保持合约简单性
5. 做好文档记录

## 贡献

欢迎提交 Issue 和 Pull Request 来改进代码。

## 许可证

MIT License