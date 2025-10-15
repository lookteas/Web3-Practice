# EVM 存储布局学习笔记

## 概述

以太坊虚拟机（EVM）的存储布局是智能合约开发中的核心概念，理解存储布局对于优化gas消耗、避免存储冲突以及编写高效的智能合约至关重要。

## 1. EVM 存储模型

### 1.1 存储类型

EVM 中主要有以下几种存储类型：

- **Storage（存储）**：持久化存储，数据保存在区块链上
- **Memory（内存）**：临时存储，函数执行期间使用
- **Stack（栈）**：用于局部变量和函数调用
- **Calldata**：函数调用时的输入数据

### 1.2 Storage 存储特点

- 每个存储槽（slot）为 32 字节（256 位）
- 存储是键值对映射：slot number → 32-byte value
- 读写操作消耗大量 gas
- 数据永久保存在区块链上

## 2. 存储槽分配规则

### 2.1 基本类型存储

```solidity
contract StorageExample {
    uint256 a;      // slot 0
    uint256 b;      // slot 1
    uint128 c;      // slot 2 (前16字节)
    uint128 d;      // slot 2 (后16字节) - 打包存储
    uint256 e;      // slot 3
}
```

### 2.2 存储打包（Storage Packing）

- 小于 32 字节的变量会尝试打包到同一个存储槽
- 按声明顺序从右到左填充
- 不能跨越存储槽边界

```solidity
contract PackingExample {
    uint128 a;      // slot 0, 占用前16字节
    uint64 b;       // slot 0, 占用后8字节
    uint32 c;       // slot 0, 占用最后4字节
    uint256 d;      // slot 1, 需要完整的32字节
}
```

### 2.3 数组存储

#### 定长数组
```solidity
uint256[3] fixedArray;  // 占用 slot 0, 1, 2
```

#### 动态数组
```solidity
uint256[] dynamicArray;
// slot p: 存储数组长度
// 数组元素存储在: keccak256(p) + index
```

### 2.4 映射存储

```solidity
mapping(uint256 => uint256) myMapping;
// slot p: 通常为空（除非是packed）
// 映射值存储在: keccak256(key . p)
```

### 2.5 结构体存储

```solidity
struct Person {
    uint256 id;     // slot n
    uint128 age;    // slot n+1 (前16字节)
    uint128 score;  // slot n+1 (后16字节)
}
Person person;      // 从 slot 0 开始
```

## 3. 存储布局优化

### 3.1 变量重排序

**不优化的写法：**
```solidity
contract Unoptimized {
    uint128 a;      // slot 0
    uint256 b;      // slot 1 (浪费了slot 0的后16字节)
    uint128 c;      // slot 2
}
```

**优化后的写法：**
```solidity
contract Optimized {
    uint128 a;      // slot 0 (前16字节)
    uint128 c;      // slot 0 (后16字节)
    uint256 b;      // slot 1
}
```

## 总结

理解 EVM 存储布局是智能合约开发的基础技能。通过合理的存储设计和优化，可以显著降低 gas 消耗，提高合约性能，并避免潜在的安全风险。

---

*本笔记基于 EVM 存储布局的核心概念整理，建议结合实际代码练习加深理解。*
