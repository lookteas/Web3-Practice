![](./letsgo.png)


# Web3-Practice

web3 练习 包含合约开发： EVM 、GAS 优化 ，去中心化金融（DEFI）， 去中心化金融（DEFI），协议数据分析，Layer2 开发等等

> **特别说明： 本目录中所有合约均要求solidity版本 ≥ 0.8.10, 且合约都在本地 Anvil 节点部署测试过，但安全性未经过检验不建议在主网部署，仅用于学习交流和实验。**


## 目录
- [1 ：POW 与 RSA 相关练习](#1-pow-与-rsa-相关练习)
- [2 ：solidity 基础 合约测试](#2-solidity-基础-合约测试)
- [3 ：solidity 基础 合约继承和接口](#3-solidity-基础-合约继承和接口)
- [4 ：如何使用 ERC20 实现代币](#4-如何使用-erc20-实现代币)
- [5 ：使用 ERC721 实现 NFT 和 NFT的交互](#5-使用-erc721-实现-nft-和-nft的交互)
- [6 ：Foundry的工程化： 项目初始化、编译、测试、部署](#6-foundry的工程化-项目初始化-编译-测试-部署)
- [7 ：NFT合约部署](#7-nft合约部署)
- [8 ：Solidity 实现用 Token 购买 NFT](#8-solidity-实现用-token-购买-nft)
- [9 ：使⽤ Viem 监听 NFTMarket 的买卖记录](#9-使-viem-监听-nftmarket-的买卖记录)
- [10 ：Web3 命令行钱包](#10-web3-命令行钱包)
- [11 ：使用多签名实现 Token 购买 NFT](#11-使用多签名实现-token-购买-nft)
- [12 ：读取 esRNT 合约的锁信息](#12-读取-esrnt-合约的锁信息)
- [13 ：ABI 编码-解码演示](#13-abi-编码-解码演示)
- [14 ：用solidity 编写 多签名钱包合约](#14-用solidity-编写-多签合约钱包)



- [新增目录说明](#新增目录说明)


------


### **1 ：POW 与 RSA 相关练习**

- POW 与 RSA 实验详情请查看 [powLabs/README.md](powLabs/README.md)

- 位置：powLabs/README.md

- 包含两个 go 程序的实现与运行方式
  - POW 实验：[powLabs/pow.go](powLabs/pow.go)
  - RSA 实验：[powLabs/rsa.go](powLabs/rsa.go)

  ------
  

### **2 ：solidity 基础 合约测试**
- 用solidity 编写 Bank 智能合约  详情请查看[bankContract/README.md](bankContract/README.md)
- 位置：bankContract/README.md
- 包含一个bank的demo合约，实现存款、提款和排行榜功能

  ------


### **3 ：solidity 基础 合约继承和接口**
- 用solidity 编写 BigBank 实践 solidity 继承及接口合约交互  详情请查看[bigBankContract/README.md](bigBankContract/README.md)
- 位置：bigBankContract/README.md
- 包含bank基础合约，管理员合约，银行合约接口文件，实现存款、提款、余额查询和转移管理员权限功能

  -------


### **4 ：如何使用 ERC20 实现代币**
- 用solidity 编写 ERC20 合约  详情请查看[erc20/README.md](erc20/README.md)
- 位置：erc20/README.md
- 包含ERC20合约，实现代币的基本功能：转账、查询余额、授权转账等。

  -------


### **5 ：使用 ERC721 实现 NFT 和 NFT的交互**
- 用solidity 编写 ERC721 合约  详情请查看[nft/README.md](nft/README.md)
- 位置：nft/README.md
- 包含ERC721合约，实现NFT的基本功能： mint、transfer、approve、balanceOf等。

  -------


### **6 ：foundry的工程化 项目初始化 编译 测试 部署**
- 用solidity 编写 Foundry 项目  详情请查看[foundry/README.md](foundry/README.md)
- 位置：foundry/README.md
- 包含Foundry项目的基本结构，以及如何初始化、编译、测试和部署智能合约。

  -------


### **7 ：nft合约部署**
- 用solidity 编写 NFT项目  详情请查看[nft/README.md](nft/README.md)
- 位置：nft/nft-market
- 包含nft合约项目的基本结构，以及如何铸造nft、查看nft、测试和部署智能合约。

  -------


### **8 ：Solidity 实现用 Token 购买 NFT**
- 用solidity 编写 NFTMarketWithERC20 合约  详情请查看[nft/nft-market-token/README.md](nft/nft-market-token/README.md)
- 位置：nft/nft-market-token
- 包含NFTMarketWithERC20合约，实现用ERC20代币购买NFT的功能。

  -------


### **9 ：使⽤ Viem 监听 NFTMarket 的买卖记录**
- 使用 Viem.sh 监听 NFTMarket 的买卖记录 详情请查看[viemTokenBank/README.md](viemTokenBank/)
- 位置：viemTokenBank/README.md
- 包含Viem.sh项目的基本结构，以及如何监听智能合约。
- 监听 NFTMarket 的买卖记录，包括购买和销售事件。

  -------


### **10 ：Web3 命令行钱包**
- 基于 Viem.js 构建的 Sepolia 测试网命令行钱包，支持私钥生成、余额查询、ERC20 转账等功能。详情请查看[cliWallet/README.md](cliWallet/README.md)
- 位置：cliWallet
- 包含Viem.js项目的基本结构，以及如何使用命令行钱包进行操作。

  -------

### **11 ：使用多签名实现 Token 购买 NFT**
- 用solidity 编写 NFTMarketWithERC20 合约  详情请查看[nft/nft-market-token/README.md](nft/nft-market-token/README.md)
- 位置：nft/nft-market-token
- 包含NFTMarketWithERC20合约，实现用ERC20代币购买NFT的功能。

  -------

### **12 ：读取 esRNT 合约的锁信息**
- 用solidity 编写 esRNT 合约部署测试网后，使用viem读取锁信息  详情请查看[evm/read-esrnt-locks/esrnt.sol](evm/read-esrnt-locks)
- 位置：evm/read-esrnt-locks
- 包含readLocks.js，实现读取esRNT合约锁信息的功能。

  -------

### **13 ：ABI 编码 解码演示**
- 用solidity 编写 ABI 编码/解码合约  详情请查看[abi/README.md](abi)
- 位置：abi
- 包含ABI编码/解码合约，实现对不同数据类型的编码和解码。

  -------

### **14 ：用solidity 编写 多签合约钱包**
- 用solidity 编写 MultiSigWallet 合约  详情请查看[multiSigner/README.md](multiSigner)
- 位置：multiSigner
- 包含MultiSigWallet合约，实现多签名钱包的功能。
- 允许多个所有者共同管理资产，需要达到指定数量的人确认后才能执行交易

  -------

  ### **15 ： Permit2 银行合约项目**
  - 基于 Foundry 开发的 DeFi 项目，实现支持 Permit2 签名授权的银行合约系统。详情请查看[permit2/README.md](permit2)
  - 位置：permit2
  - 包含前端界面：Permit2 协议实现完整的 Web3 交互界面，支持 ETH 和 ERC20 分离显示

  -------
  
### 新增目录说明


> 说明：后续新增练习代码时，在此处添加目录相对链接，方便从首页快速跳转。