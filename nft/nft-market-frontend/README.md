# NFT 市场前端

一个基于 Polygon 主网的 NFT 市场前端应用，支持 NFT 铸造、展示、购买和交易功能。

## 功能特性

### 🎨 NFT 铸造
- 支持通过元数据 URI 铸造 NFT
- **IPFS 集成**: 直接上传图片和元数据到 IPFS (Pinata)
- 拖拽上传图片，自动生成元数据
- 动态添加 NFT 属性和特征
- 实时显示铸造价格和总供应量
- 上传进度显示和错误处理
- 交易状态实时反馈

### 🏪 NFT 市场
- 浏览所有在售的 NFT
- 支持搜索和过滤功能
- 实时价格显示
- 一键购买功能

### 👤 个人 NFT 管理
- 查看拥有的所有 NFT
- 上架/下架 NFT
- 设置销售价格
- 管理授权状态

### 🔗 钱包集成
- MetaMask 钱包连接
- 自动网络切换到 Polygon
- 账户状态实时显示
- 交易确认和状态跟踪

## 技术栈

- **前端框架**: 原生 HTML/CSS/JavaScript
- **Web3 库**: Ethers.js v5
- **区块链网络**: Polygon Mainnet
- **钱包**: MetaMask
- **IPFS 存储**: Pinata (去中心化存储)
- **样式**: CSS3 + Flexbox/Grid
- **图标**: Font Awesome

## 合约信息

### 部署地址 (Polygon Mainnet)
- **MyNFT**: `0x742d35Cc6634C0532925a3b8D4C9db96C4b5Da5C`
- **NFTMarket**: `0x8A791620dd6260079BF849Dc5567aDC3F2FdC318`

### 区块链浏览器
- [MyNFT 合约](https://polygonscan.com/address/0x742d35Cc6634C0532925a3b8D4C9db96C4b5Da5C)
- [NFTMarket 合约](https://polygonscan.com/address/0x8A791620dd6260079BF849Dc5567aDC3F2FdC318)

## 快速开始

### 1. 环境准备
确保您已安装：
- 现代浏览器 (Chrome, Firefox, Safari, Edge)
- MetaMask 钱包扩展

### 2. 获取测试资金
在 Polygon 主网上进行交易需要 MATIC 代币：
- 可以通过交易所购买 MATIC
- 或使用跨链桥从其他网络转移资金

### 3. 启动应用
1. 下载或克隆项目文件
2. 使用本地服务器打开 `index.html`
   ```bash
   # 使用 Python 启动本地服务器
   python -m http.server 8000
   
   # 或使用 Node.js
   npx serve .
   ```
3. 在浏览器中访问 `http://localhost:8000`

### 4. 配置 IPFS (可选)
如果您想使用 IPFS 上传功能：
1. 注册 [Pinata](https://pinata.cloud/) 账户
2. 获取 API Key 和 Secret，或创建 JWT Token
3. 在应用中点击 "IPFS配置" 输入您的凭据
4. 测试连接确保配置正确

### 5. 连接钱包
1. 点击 "连接钱包" 按钮
2. 选择 MetaMask 钱包
3. 确认连接并切换到 Polygon 网络
4. 开始使用应用！

## 使用指南

### 配置 IPFS (Pinata)
1. 访问 [Pinata Cloud](https://pinata.cloud/) 并注册账户
2. 在控制台中创建 API Key 或 JWT Token
3. 在应用中点击导航栏的 "IPFS配置"
4. 选择认证方式并输入凭据：
   - **JWT Token**: 推荐方式，更安全
   - **API Key + Secret**: 传统方式
5. 点击 "测试连接" 验证配置
6. 配置成功后即可使用 IPFS 上传功能

### 铸造 NFT

#### 方式一：IPFS 上传创建 (推荐)
1. 确保已配置 Pinata IPFS
2. 在 "铸造 NFT" 部分选择 "上传创建" 标签
3. 上传 NFT 图片 (支持拖拽)：
   - 支持格式：JPG, PNG, GIF, WEBP
   - 最大文件大小：10MB
4. 填写 NFT 基本信息：
   - NFT 名称
   - 描述
5. 添加属性 (可选)：
   - 点击 "添加属性" 按钮
   - 输入属性名称和值
6. 点击 "创建 NFT" 按钮
7. 等待图片和元数据上传到 IPFS
8. 确认区块链交易

#### 方式二：URI 铸造
1. 准备 NFT 元数据 JSON 文件并上传到 IPFS 或其他存储服务
2. 在 "铸造 NFT" 部分选择 "URI 铸造" 标签
3. 输入元数据 URI
4. 点击 "铸造 NFT" 按钮
5. 确认交易并等待区块确认

### 购买 NFT
1. 在 "NFT 市场" 部分浏览可购买的 NFT
2. 点击感兴趣的 NFT 卡片查看详情
3. 点击 "购买" 按钮
4. 确认交易并等待完成

### 上架 NFT
1. 在 "我的 NFT" 部分找到要出售的 NFT
2. 点击 NFT 卡片打开详情
3. 点击 "上架销售" 按钮
4. 设置销售价格
5. 确认授权和上架交易

### 取消上架
1. 在 "我的 NFT" 部分找到已上架的 NFT
2. 点击 NFT 卡片打开详情
3. 点击 "取消上架" 按钮
4. 确认交易

## 项目结构

```
nft-frontend/
├── index.html          # 主页面
├── styles.css          # 样式文件
├── app.js             # 主要 JavaScript 逻辑
├── contracts.js       # 合约 ABI 和地址配置
├── config.js          # Pinata IPFS 配置
├── ipfs.js            # IPFS 上传工具函数
└── README.md          # 项目说明
```

## 核心功能实现

### IPFS 集成
```javascript
// 上传图片到 IPFS
async function uploadFileToIPFS(file, onProgress) {
    const formData = new FormData();
    formData.append('file', file);
    
    const response = await fetch('https://api.pinata.cloud/pinning/pinFileToIPFS', {
        method: 'POST',
        headers: {
            'Authorization': `Bearer ${PINATA_CONFIG.jwt}`
        },
        body: formData
    });
    
    return response.json();
}

// 上传元数据到 IPFS
async function uploadJSONToIPFS(metadata) {
    const response = await fetch('https://api.pinata.cloud/pinning/pinJSONToIPFS', {
        method: 'POST',
        headers: {
            'Content-Type': 'application/json',
            'Authorization': `Bearer ${PINATA_CONFIG.jwt}`
        },
        body: JSON.stringify({
            pinataContent: metadata,
            pinataMetadata: {
                name: `${metadata.name}_metadata.json`
            }
        })
    });
    
    return response.json();
}
```

### 钱包连接
```javascript
// 连接 MetaMask 钱包
async function connectWallet() {
    const accounts = await window.ethereum.request({
        method: 'eth_requestAccounts'
    });
    // 初始化 provider 和 signer
    provider = new ethers.providers.Web3Provider(window.ethereum);
    signer = provider.getSigner();
}
```

### NFT 铸造
```javascript
// 传统 URI 铸造
async function mintNFT() {
    const mintPrice = await nftContract.mintPrice();
    const tx = await nftContract.mint(tokenURI, {
        value: mintPrice
    });
    await tx.wait();
}

// IPFS 集成铸造
async function createNFTWithIPFS() {
    // 1. 上传图片到 IPFS
    const imageResult = await uploadFileToIPFS(selectedImageFile);
    const imageURI = `https://gateway.pinata.cloud/ipfs/${imageResult.IpfsHash}`;
    
    // 2. 生成元数据
    const metadata = generateNFTMetadata(nftName, description, imageURI, attributes);
    
    // 3. 上传元数据到 IPFS
    const metadataResult = await uploadJSONToIPFS(metadata);
    const tokenURI = `https://gateway.pinata.cloud/ipfs/${metadataResult.IpfsHash}`;
    
    // 4. 铸造 NFT
    const mintPrice = await nftContract.mintPrice();
    const tx = await nftContract.mint(tokenURI, {
        value: mintPrice
    });
    await tx.wait();
}
```

### NFT 交易
```javascript
// 购买 NFT
async function buyNFT() {
    const tx = await marketContract.buyNFT(nftContract.address, tokenId, {
        value: ethers.utils.parseEther(price)
    });
    await tx.wait();
}
```

## 安全注意事项

### 🔒 钱包安全
- 永远不要分享您的私钥或助记词
- 确认交易前仔细检查交易详情
- 使用官方 MetaMask 扩展

### 🛡️ 交易安全
- 验证合约地址的正确性
- 检查 NFT 元数据和图片
- 注意 Gas 费用设置

### 🌐 网络安全
- 确保连接到正确的网络 (Polygon Mainnet)
- 验证网站 URL 的正确性
- 避免在不安全的网络环境下进行交易

## 故障排除

### 常见问题

**Q: 无法连接钱包**
A: 确保已安装 MetaMask 并解锁钱包，刷新页面重试

**Q: 交易失败**
A: 检查账户余额是否足够支付 Gas 费用，确认网络连接正常

**Q: NFT 图片无法显示**
A: 检查元数据 URI 是否可访问，图片链接是否有效

**Q: IPFS 上传失败**
A: 检查 Pinata 配置是否正确，API Key 是否有效，网络连接是否正常

**Q: 图片无法上传**
A: 确认图片格式支持 (JPG/PNG/GIF/WEBP)，文件大小不超过 10MB

**Q: 元数据生成错误**
A: 检查 NFT 名称和描述是否填写，属性格式是否正确

### 调试模式
打开浏览器开发者工具 (F12) 查看控制台日志获取详细错误信息。

## 开发指南

### 本地开发
1. 修改 `contracts.js` 中的合约地址（如需要）
2. 在 `app.js` 中添加新功能
3. 使用浏览器开发者工具进行调试

### 自定义样式
在 `styles.css` 中修改样式：
- 主题颜色
- 布局样式
- 响应式设计

### 添加新功能
1. 在 `contracts.js` 中添加新的 ABI 函数
2. 在 `app.js` 中实现相应的 JavaScript 函数
3. 在 `index.html` 中添加 UI 元素

## 版本历史

- **v2.0.0** - IPFS 集成版本
  - 集成 Pinata IPFS 存储
  - 支持直接上传图片创建 NFT
  - 自动生成标准化元数据
  - 拖拽上传和进度显示
  - 动态属性管理
  - 增强的用户体验和错误处理
  - 自动保存草稿功能

- **v1.0.0** - 初始版本
  - NFT 铸造功能
  - 市场浏览和购买
  - 个人 NFT 管理
  - 钱包集成

## 许可证

MIT License - 详见 LICENSE 文件

## 联系方式

如有问题或建议，请通过以下方式联系：
- GitHub Issues
- 邮箱: [your-email@example.com]

---

**免责声明**: 本应用仅供学习和演示目的。在主网上进行真实交易前，请充分了解相关风险。