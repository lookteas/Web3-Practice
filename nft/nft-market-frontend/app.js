// 全局变量
let provider = null;
let signer = null;
let userAddress = null;
let nftContract = null;
let marketContract = null;

// IPFS 相关变量
let selectedImageFile = null;
let currentNFTData = null;

// 初始化应用
document.addEventListener('DOMContentLoaded', async () => {
    console.log('应用初始化...');
    
    // 加载 Pinata 配置
    loadPinataCredentials();
    
    // 启动网络状态监控
    startNetworkMonitoring();
    
    // 检查是否已连接钱包
    if (typeof window.ethereum !== 'undefined') {
        try {
            const accounts = await window.ethereum.request({ method: 'eth_accounts' });
            if (accounts.length > 0) {
                await connectWallet();
            }
        } catch (error) {
            console.error('检查钱包连接状态失败:', error);
        }
    }
    
    // 绑定事件监听器
    bindEventListeners();
    
    // 加载初始数据
    await loadInitialData();
    
    // 更新 Pinata 状态显示
    updatePinataStatus();
});

// 绑定事件监听器
function bindEventListeners() {
    // 处理账户变化
function handleAccountsChanged(accounts) {
    console.log('账户变化:', accounts);
    
    if (accounts.length === 0) {
        // 用户断开了钱包连接
        provider = null;
        signer = null;
        userAddress = null;
        nftContract = null;
        marketContract = null;
        
        // 更新UI
        updateWalletUI();
        showNotification('钱包已断开连接', 'info');
    } else {
        // 用户切换了账户，重新连接
        connectWallet();
    }
}

// 处理网络变化
function handleChainChanged(chainId) {
    console.log('网络变化:', chainId);
    
    // 重新加载页面以确保状态一致
    window.location.reload();
}

// 连接钱包按钮
    const connectWalletBtn = document.getElementById('connectWallet');
    if (connectWalletBtn) {
        connectWalletBtn.addEventListener('click', connectWallet);
    }
    
    // 铸造NFT按钮
    const createNFTBtn = document.getElementById('createNFTBtn');
    if (createNFTBtn) {
        createNFTBtn.addEventListener('click', createNFTWithIPFS);
    }
    
    // URI铸造按钮
    const mintBtn = document.getElementById('mintBtn');
    if (mintBtn) {
        mintBtn.addEventListener('click', mintNFT);
    }
    
    // 刷新按钮（带防抖）
    const refreshListingsBtn = document.getElementById('refreshListings');
    if (refreshListingsBtn) {
        refreshListingsBtn.addEventListener('click', debounce(() => {
            clearContractCache('getActiveListings');
            loadMarketplaceNFTs();
        }, 1000));
    }
    
    const refreshMyNFTsBtn = document.getElementById('refreshMyNFTs');
    if (refreshMyNFTsBtn) {
        refreshMyNFTsBtn.addEventListener('click', debounce(() => {
            if (userAddress) {
                clearContractCache(`balanceOf_${userAddress}`);
            }
            loadMyNFTs();
        }, 1000));
    }
    
    // 模态框关闭按钮
    document.querySelectorAll('.modal-close').forEach(btn => {
        btn.addEventListener('click', closeModal);
    });
    
    // 模态框背景点击关闭
    document.querySelectorAll('.modal').forEach(modal => {
        modal.addEventListener('click', (e) => {
            if (e.target === modal) {
                closeModal();
            }
        });
    });
    
    // NFT详情模态框按钮
    const buyBtn = document.getElementById('buyBtn');
    if (buyBtn) {
        buyBtn.addEventListener('click', buyNFT);
    }
    
    const listBtn = document.getElementById('listBtn');
    if (listBtn) {
        listBtn.addEventListener('click', () => showListModal());
    }
    
    const cancelListingBtn = document.getElementById('cancelListingBtn');
    if (cancelListingBtn) {
        cancelListingBtn.addEventListener('click', cancelListing);
    }
    
    const confirmListBtn = document.getElementById('confirmListBtn');
    if (confirmListBtn) {
        confirmListBtn.addEventListener('click', listNFT);
    }
    
    // 搜索功能
    const searchInput = document.getElementById('searchInput');
    if (searchInput) {
        searchInput.addEventListener('input', filterNFTs);
    }
    
    // IPFS 配置相关事件
    const savePinataConfigBtn = document.getElementById('savePinataConfig');
    if (savePinataConfigBtn) {
        savePinataConfigBtn.addEventListener('click', savePinataConfig);
    }
    
    const testPinataConnectionBtn = document.getElementById('testPinataConnection');
    if (testPinataConnectionBtn) {
        testPinataConnectionBtn.addEventListener('click', testPinataConnection);
    }
    
    const clearPinataConfigBtn = document.getElementById('clearPinataConfig');
    if (clearPinataConfigBtn) {
        clearPinataConfigBtn.addEventListener('click', clearPinataConfig);
    }
    
    // 铸造标签切换
    document.querySelectorAll('.tab-btn').forEach(btn => {
        btn.addEventListener('click', switchMintTab);
    });
    
    // 文件上传相关事件
    const fileInput = document.getElementById('nftImage');
    const dropZone = document.getElementById('imageDropZone');
    
    if (fileInput) {
        fileInput.addEventListener('change', handleFileSelect);
    }
    
    // 拖拽上传
    if (dropZone) {
        dropZone.addEventListener('dragover', (e) => {
            e.preventDefault();
            dropZone.classList.add('dragover');
        });
        
        dropZone.addEventListener('dragleave', () => {
            dropZone.classList.remove('dragover');
        });
        
        dropZone.addEventListener('drop', (e) => {
            e.preventDefault();
            dropZone.classList.remove('dragover');
            const files = e.dataTransfer.files;
            if (files.length > 0) {
                handleFileSelect({ target: { files } });
            }
        });
        
        // 点击上传区域触发文件选择
        dropZone.addEventListener('click', () => {
            fileInput.click();
        });
    }
    
    // 属性管理
    const addAttributeBtn = document.getElementById('addAttribute');
    if (addAttributeBtn) {
        addAttributeBtn.addEventListener('click', addNFTAttribute);
    }
    
    // 添加预览更新事件监听
    const nftNameInput = document.getElementById('nft-name');
    const nftDescInput = document.getElementById('nft-description');
    
    if (nftNameInput) {
        nftNameInput.addEventListener('input', updatePreview);
    }
    
    if (nftDescInput) {
        nftDescInput.addEventListener('input', updatePreview);
    }
    
    // 为现有的属性行添加事件监听
    document.querySelectorAll('.attribute-row input').forEach(input => {
        input.addEventListener('input', updatePreview);
    });
    
    document.querySelectorAll('.btn-remove-attr').forEach(btn => {
        btn.addEventListener('click', (e) => {
            e.target.closest('.attribute-row').remove();
            updatePreview();
        });
    });
    
    // 监听账户变化
    if (typeof window.ethereum !== 'undefined') {
        window.ethereum.on('accountsChanged', handleAccountsChanged);
        window.ethereum.on('chainChanged', handleChainChanged);
    }
}

// 连接钱包
async function connectWallet() {
    try {
        if (typeof window.ethereum === 'undefined') {
            showNotification('请安装 MetaMask 钱包', 'error');
            return;
        }
        
        showLoading(true);
        
        // 请求连接账户
        const accounts = await window.ethereum.request({
            method: 'eth_requestAccounts'
        });
        
        if (accounts.length === 0) {
            throw new Error('未选择账户');
        }
        
        // 检查并切换到 Polygon 网络
        await switchToPolygon();
        
        // 初始化 ethers (ethers v6 语法)
        provider = new ethers.BrowserProvider(window.ethereum);
        signer = await provider.getSigner();
        userAddress = await signer.getAddress();
        
        // 初始化合约实例
        nftContract = new ethers.Contract(CONTRACT_ADDRESSES.MyNFT, NFT_ABI, signer);
        marketContract = new ethers.Contract(CONTRACT_ADDRESSES.NFTMarket, MARKET_ABI, signer);
        
        // 更新UI
        updateWalletUI();
        
        // 加载用户数据
        await loadUserData();
        
        showNotification('钱包连接成功！', 'success');
        
    } catch (error) {
        console.error('连接钱包失败:', error);
        showNotification(`连接钱包失败: ${error.message}`, 'error');
    } finally {
        showLoading(false);
    }
}

// 切换到 Polygon 网络
async function switchToPolygon() {
    try {
        await window.ethereum.request({
            method: 'wallet_switchEthereumChain',
            params: [{ chainId: `0x${NETWORK_CONFIG.chainId.toString(16)}` }]
        });
    } catch (switchError) {
        // 如果网络不存在，添加网络
        if (switchError.code === 4902) {
            try {
                await window.ethereum.request({
                    method: 'wallet_addEthereumChain',
                    params: [{
                        chainId: `0x${NETWORK_CONFIG.chainId.toString(16)}`,
                        chainName: NETWORK_CONFIG.chainName,
                        nativeCurrency: NETWORK_CONFIG.nativeCurrency,
                        rpcUrls: NETWORK_CONFIG.rpcUrls,
                        blockExplorerUrls: NETWORK_CONFIG.blockExplorerUrls
                    }]
                });
            } catch (addError) {
                throw new Error('添加 Polygon 网络失败');
            }
        } else {
            throw switchError;
        }
    }
}

// 更新钱包UI
function updateWalletUI() {
    const connectBtn = document.getElementById('connectWallet');
    const walletStatus = document.getElementById('walletStatus');
    const walletAddress = document.getElementById('walletAddress');
    
    if (userAddress) {
        connectBtn.innerHTML = '<i class="fas fa-check"></i> 已连接';
        connectBtn.style.background = '#28a745';
        walletStatus.classList.remove('hidden');
        walletAddress.textContent = `${userAddress.slice(0, 6)}...${userAddress.slice(-4)}`;
    } else {
        connectBtn.innerHTML = '<i class="fas fa-wallet"></i> 连接钱包';
        connectBtn.style.background = '';
        walletStatus.classList.add('hidden');
    }
}

// 加载初始数据
async function loadInitialData() {
    try {
        // 加载铸造价格和总供应量
        if (nftContract) {
            const mintPrice = await nftContract.mintPrice();
            const totalSupply = await nftContract.totalSupply();
            const maxSupply = await nftContract.maxSupply();
            
            document.getElementById('mintPrice').textContent = `${ethers.formatEther(mintPrice)} MATIC`;
            document.getElementById('totalSupply').textContent = `${totalSupply} / ${maxSupply}`;
        }
        
        // 加载市场NFT
        await loadMarketplaceNFTs();
        
    } catch (error) {
        console.error('加载初始数据失败:', error);
    }
}

// 加载用户数据
async function loadUserData() {
    try {
        await loadMyNFTs();
        await loadInitialData();
    } catch (error) {
        console.error('加载用户数据失败:', error);
    }
}

// 铸造NFT
async function mintNFT() {
    console.log('mintNFT函数被调用');
    try {
        if (!nftContract) {
            console.log('NFT合约未初始化');
            showNotification('请先连接钱包', 'error');
            return;
        }
        
        const tokenURI = document.getElementById('tokenURI').value.trim();
        console.log('获取到的tokenURI:', tokenURI);
        
        if (!tokenURI) {
            console.log('tokenURI为空');
            showNotification('请输入NFT元数据URI', 'error');
            return;
        }
        
        // 验证URI格式
        try {
            new URL(tokenURI);
            console.log('URI格式验证通过');
        } catch {
            console.log('URI格式验证失败');
            showNotification('请输入有效的URI格式', 'error');
            return;
        }
        
        showLoading(true);
        console.log('开始铸造NFT...');
        
        // 获取铸造价格
        const mintPrice = await nftContract.mintPrice();
        console.log('铸造价格:', mintPrice.toString());
        
        // 发送铸造交易
        const tx = await nftContract.mint(userAddress, tokenURI, {
            value: mintPrice,
            gasLimit: 300000
        });
        
        console.log('交易已发送:', tx.hash);
        showNotification('交易已发送，等待确认...', 'info');
        
        // 等待交易确认
        const receipt = await tx.wait();
        console.log('交易确认:', receipt);
        
        // 从事件中获取tokenId
        const transferEvent = receipt.events.find(event => event.event === 'Transfer');
        const tokenId = transferEvent.args.tokenId.toString();
        
        console.log('NFT铸造成功，Token ID:', tokenId);
        showNotification(`NFT铸造成功！Token ID: ${tokenId}`, 'success');
        
        // 清空输入框
        document.getElementById('tokenURI').value = '';
        
        // 刷新数据
        await loadUserData();
        
    } catch (error) {
        console.error('铸造NFT失败:', error);
        showNotification(`铸造失败: ${error.message}`, 'error');
    } finally {
        showLoading(false);
    }
}

// 加载市场NFT
async function loadMarketplaceNFTs() {
    try {
        const nftGrid = document.getElementById('nftGrid');
        nftGrid.innerHTML = '<div class="loading-placeholder"><i class="fas fa-spinner fa-spin"></i><p>加载中...</p></div>';
        
        if (!marketContract) {
            nftGrid.innerHTML = '<div class="empty-placeholder"><i class="fas fa-wallet"></i><p>请先连接钱包</p></div>';
            return;
        }
        
        // 检查合约是否正确部署（带重试机制）
        try {
            const contractCode = await retryWithDelay(
                () => provider.getCode(CONTRACT_ADDRESSES.NFTMarket),
                3, // 最多重试3次
                1000 // 每次重试间隔1秒
            );
            if (contractCode === '0x') {
                throw new Error('市场合约未部署或地址错误');
            }
        } catch (error) {
            console.error('合约检查失败:', error);
            
            // 检查是否是熔断器错误
            if (error.message && error.message.includes('circuit breaker is open')) {
                nftGrid.innerHTML = '<div class="empty-placeholder"><i class="fas fa-exclamation-triangle"></i><p>网络请求过于频繁，请稍后再试</p><button onclick="loadMarketplaceNFTs()" class="retry-btn">重试</button></div>';
            } else {
                nftGrid.innerHTML = '<div class="empty-placeholder"><i class="fas fa-exclamation-triangle"></i><p>市场合约检查失败，请稍后重试</p><button onclick="loadMarketplaceNFTs()" class="retry-btn">重试</button></div>';
            }
            return;
        }
        
        // 获取活跃的上架列表（使用缓存）
        let listings;
        try {
            listings = await cachedContractCall(
                'getActiveListings',
                () => marketContract.getActiveListings(0, 100), // 添加offset和limit参数
                30000 // 30秒缓存
            );
            console.log('获取到的listings:', listings);
        } catch (error) {
            console.error('调用getActiveListings失败:', error);
            console.error('错误详情:', {
                code: error.code,
                message: error.message,
                data: error.data,
                contractAddress: CONTRACT_ADDRESSES.NFTMarket,
                functionName: 'getActiveListings'
            });
            
            // 如果是解码错误，说明合约返回了空数据或函数不存在
            if (error.code === 'BAD_DATA' || error.message.includes('could not decode result data')) {
                console.log('合约返回空数据，可能没有活跃的上架列表');
                nftGrid.innerHTML = '<div class="empty-placeholder"><i class="fas fa-box-open"></i><p>暂无NFT在售</p></div>';
                return;
            }
            
            // 如果是网络错误或其他错误
            showNotification('加载市场NFT失败，请检查网络连接', 'error');
            nftGrid.innerHTML = '<div class="empty-placeholder"><i class="fas fa-exclamation-triangle"></i><p>加载失败，请刷新重试</p></div>';
            return;
            
            throw error;
        }
        
        if (!listings || listings.length === 0) {
            nftGrid.innerHTML = '<div class="empty-placeholder"><i class="fas fa-box-open"></i><p>暂无NFT在售</p></div>';
            return;
        }
        
        // 渲染NFT卡片
        const nftCards = await Promise.all(listings.map(async (listing) => {
            try {
                const tokenURI = await nftContract.tokenURI(listing.tokenId);
                const metadata = await fetchMetadata(tokenURI);
                
                return createNFTCard({
                    tokenId: listing.tokenId.toString(),
                    name: metadata.name || `NFT #${listing.tokenId}`,
                    description: metadata.description || '无描述',
                    image: metadata.image || './placeholder.svg',
                    price: ethers.formatEther(listing.price),
                    seller: listing.seller,
                    isListed: true
                });
            } catch (error) {
                console.error(`加载NFT ${listing.tokenId} 失败:`, error);
                return createNFTCard({
                    tokenId: listing.tokenId.toString(),
                    name: `NFT #${listing.tokenId}`,
                    description: '元数据加载失败',
                    image: './placeholder.svg',
                    price: ethers.formatEther(listing.price),
                    seller: listing.seller,
                    isListed: true
                });
            }
        }));
        
        nftGrid.innerHTML = nftCards.join('');
        
        // 绑定点击事件
        bindNFTCardEvents();
        
    } catch (error) {
        console.error('加载市场NFT失败:', error);
        document.getElementById('nftGrid').innerHTML = '<div class="empty-placeholder"><i class="fas fa-exclamation-triangle"></i><p>加载失败，请重试</p></div>';
    }
}

// 加载我的NFT
async function loadMyNFTs() {
    try {
        const myNFTGrid = document.getElementById('myNFTGrid');
        myNFTGrid.innerHTML = '<div class="loading-placeholder"><i class="fas fa-spinner fa-spin"></i><p>加载中...</p></div>';
        
        if (!nftContract || !userAddress) {
            myNFTGrid.innerHTML = '<div class="empty-placeholder"><i class="fas fa-wallet"></i><p>请先连接钱包</p></div>';
            return;
        }
        
        // 获取用户拥有的NFT数量（使用缓存）
        const balance = await cachedContractCall(
            `balanceOf_${userAddress}`,
            () => nftContract.balanceOf(userAddress),
            15000 // 15秒缓存，用户NFT数量变化较频繁
        );
        
        if (balance === 0n) {
            myNFTGrid.innerHTML = '<div class="empty-placeholder"><i class="fas fa-box-open"></i><p>您还没有任何NFT</p><p>去铸造您的第一个NFT吧！</p></div>';
            return;
        }
        
        // 获取用户的所有NFT
        const tokenIds = [];
        for (let i = 0; i < Number(balance); i++) {
            const tokenId = await nftContract.tokenOfOwnerByIndex(userAddress, i);
            tokenIds.push(tokenId);
        }
        
        // 渲染NFT卡片
        const nftCards = await Promise.all(tokenIds.map(async (tokenId) => {
            try {
                const tokenURI = await nftContract.tokenURI(tokenId);
                const metadata = await fetchMetadata(tokenURI);
                
                // 检查是否已上架
                let isListed = false;
                let price = '0';
                try {
                    const listing = await marketContract.getListing(CONTRACT_ADDRESSES.MyNFT, tokenId);
                    isListed = listing.active;
                    price = ethers.formatEther(listing.price);
                } catch (error) {
                    // 忽略查询错误
                }
                
                return createNFTCard({
                    tokenId: tokenId.toString(),
                    name: metadata.name || `NFT #${tokenId}`,
                    description: metadata.description || '无描述',
                    image: metadata.image || './placeholder.svg',
                    price: price,
                    seller: userAddress,
                    isListed: isListed,
                    isOwned: true
                });
            } catch (error) {
                console.error(`加载NFT ${tokenId} 失败:`, error);
                return createNFTCard({
                    tokenId: tokenId.toString(),
                    name: `NFT #${tokenId}`,
                    description: '元数据加载失败',
                    image: './placeholder.svg',
                    price: '0',
                    seller: userAddress,
                    isListed: false,
                    isOwned: true
                });
            }
        }));
        
        myNFTGrid.innerHTML = nftCards.join('');
        
        // 绑定点击事件
        bindNFTCardEvents();
        
    } catch (error) {
        console.error('加载我的NFT失败:', error);
        document.getElementById('myNFTGrid').innerHTML = '<div class="empty-placeholder"><i class="fas fa-exclamation-triangle"></i><p>加载失败，请重试</p></div>';
    }
}

// 创建NFT卡片HTML
function createNFTCard(nft) {
    const priceDisplay = nft.isListed ? `${nft.price} MATIC` : '未上架';
    const statusClass = nft.isListed ? 'listed' : 'not-listed';
    
    return `
        <div class="nft-card ${statusClass}" data-token-id="${nft.tokenId}" data-seller="${nft.seller}" data-price="${nft.price}" data-is-listed="${nft.isListed}" data-is-owned="${nft.isOwned || false}">
            <div class="nft-image">
                <img src="${nft.image}" alt="${nft.name}" onerror="this.src='./placeholder.svg'">
            </div>
            <div class="nft-info">
                <h3 class="nft-name">${nft.name}</h3>
                <p class="nft-description">${nft.description.length > 100 ? nft.description.substring(0, 100) + '...' : nft.description}</p>
                <div class="nft-details">
                    <span class="nft-price">${priceDisplay}</span>
                    <span class="nft-token-id">#${nft.tokenId}</span>
                </div>
            </div>
        </div>
    `;
}

// 绑定NFT卡片点击事件
function bindNFTCardEvents() {
    document.querySelectorAll('.nft-card').forEach(card => {
        card.addEventListener('click', () => {
            const tokenId = card.dataset.tokenId;
            const seller = card.dataset.seller;
            const price = card.dataset.price;
            const isListed = card.dataset.isListed === 'true';
            const isOwned = card.dataset.isOwned === 'true';
            
            showNFTModal(tokenId, seller, price, isListed, isOwned);
        });
    });
}

// 显示NFT详情模态框
async function showNFTModal(tokenId, seller, price, isListed, isOwned) {
    try {
        showLoading(true);
        
        // 获取NFT元数据
        const tokenURI = await nftContract.tokenURI(tokenId);
        const metadata = await fetchMetadata(tokenURI);
        
        // 填充模态框内容
        document.getElementById('modalTitle').textContent = metadata.name || `NFT #${tokenId}`;
        document.getElementById('modalImage').src = metadata.image || './placeholder.svg';
        document.getElementById('modalNFTName').textContent = metadata.name || `NFT #${tokenId}`;
        document.getElementById('modalDescription').textContent = metadata.description || '无描述';
        document.getElementById('modalTokenId').textContent = tokenId;
        document.getElementById('modalOwner').textContent = `${seller.slice(0, 6)}...${seller.slice(-4)}`;
        document.getElementById('modalPrice').textContent = isListed ? `${price} MATIC` : '未上架';
        
        // 显示/隐藏按钮
        const buyBtn = document.getElementById('buyBtn');
        const listBtn = document.getElementById('listBtn');
        const cancelListingBtn = document.getElementById('cancelListingBtn');
        
        buyBtn.classList.add('hidden');
        listBtn.classList.add('hidden');
        cancelListingBtn.classList.add('hidden');
        
        if (isOwned) {
            // 用户拥有的NFT
            if (isListed) {
                cancelListingBtn.classList.remove('hidden');
            } else {
                listBtn.classList.remove('hidden');
            }
        } else if (isListed) {
            // 其他用户上架的NFT
            buyBtn.classList.remove('hidden');
        }
        
        // 存储当前NFT信息
        window.currentNFT = { tokenId, seller, price, isListed, isOwned };
        
        // 显示模态框
        document.getElementById('nftModal').classList.remove('hidden');
        
    } catch (error) {
        console.error('显示NFT详情失败:', error);
        showNotification('加载NFT详情失败', 'error');
    } finally {
        showLoading(false);
    }
}

// 购买NFT
async function buyNFT() {
    try {
        if (!window.currentNFT) return;
        
        const { tokenId, price } = window.currentNFT;
        
        showLoading(true);
        
        // 发送购买交易
        const tx = await marketContract.buyNFT(CONTRACT_ADDRESSES.MyNFT, tokenId, {
            value: ethers.parseEther(price),
            gasLimit: 300000
        });
        
        showNotification('交易已发送，等待确认...', 'info');
        
        // 等待交易确认
        await tx.wait();
        
        showNotification('购买成功！', 'success');
        
        // 关闭模态框
        closeModal();
        
        // 刷新数据
        await loadMarketplaceNFTs();
        await loadMyNFTs();
        
    } catch (error) {
        console.error('购买NFT失败:', error);
        showNotification(`购买失败: ${error.message}`, 'error');
    } finally {
        showLoading(false);
    }
}

// 显示上架模态框
function showListModal() {
    document.getElementById('listModal').classList.remove('hidden');
    document.getElementById('listPrice').focus();
}

// 上架NFT
async function listNFT() {
    try {
        if (!window.currentNFT) return;
        
        const { tokenId } = window.currentNFT;
        const priceInput = document.getElementById('listPrice');
        const price = priceInput.value.trim();
        
        if (!price || parseFloat(price) <= 0) {
            showNotification('请输入有效的价格', 'error');
            return;
        }
        
        showLoading(true);
        
        // 检查是否已授权
        const isApproved = await nftContract.isApprovedForAll(userAddress, CONTRACT_ADDRESSES.NFTMarket);
        
        if (!isApproved) {
            showNotification('正在授权市场合约...', 'info');
            
            // 授权市场合约
            const approveTx = await nftContract.setApprovalForAll(CONTRACT_ADDRESSES.NFTMarket, true);
            await approveTx.wait();
            
            showNotification('授权成功，正在上架...', 'info');
        }
        
        // 上架NFT
        const tx = await marketContract.listNFT(
            CONTRACT_ADDRESSES.MyNFT,
            tokenId,
            ethers.parseEther(price),
            { gasLimit: 300000 }
        );
        
        showNotification('交易已发送，等待确认...', 'info');
        
        // 等待交易确认
        await tx.wait();
        
        showNotification('上架成功！', 'success');
        
        // 关闭模态框
        closeModal();
        
        // 清空输入框
        priceInput.value = '';
        
        // 刷新数据
        await loadMarketplaceNFTs();
        await loadMyNFTs();
        
    } catch (error) {
        console.error('上架NFT失败:', error);
        showNotification(`上架失败: ${error.message}`, 'error');
    } finally {
        showLoading(false);
    }
}

// 取消上架
async function cancelListing() {
    try {
        if (!window.currentNFT) return;
        
        const { tokenId } = window.currentNFT;
        
        showLoading(true);
        
        // 取消上架
        const tx = await marketContract.cancelListing(CONTRACT_ADDRESSES.MyNFT, tokenId, {
            gasLimit: 200000
        });
        
        showNotification('交易已发送，等待确认...', 'info');
        
        // 等待交易确认
        await tx.wait();
        
        showNotification('取消上架成功！', 'success');
        
        // 关闭模态框
        closeModal();
        
        // 刷新数据
        await loadMarketplaceNFTs();
        await loadMyNFTs();
        
    } catch (error) {
        console.error('取消上架失败:', error);
        showNotification(`取消上架失败: ${error.message}`, 'error');
    } finally {
        showLoading(false);
    }
}

// 获取NFT元数据
async function fetchMetadata(tokenURI) {
    try {
        // 处理IPFS链接
        let url = tokenURI;
        if (tokenURI.startsWith('ipfs://')) {
            const hash = tokenURI.replace('ipfs://', '');
            // 使用多网关逻辑获取最佳URL
            url = await getBestGatewayUrl(hash);
        }
        
        const response = await fetch(url);
        if (!response.ok) {
            throw new Error('获取元数据失败');
        }
        
        const metadata = await response.json();
        
        // 处理图片IPFS链接
        if (metadata.image && metadata.image.startsWith('ipfs://')) {
            const imageHash = metadata.image.replace('ipfs://', '');
            // 使用多网关逻辑获取最佳图片URL
            metadata.image = await getBestGatewayUrl(imageHash);
        }
        
        return metadata;
    } catch (error) {
        console.error('获取元数据失败:', error);
        return {
            name: 'Unknown NFT',
            description: '元数据加载失败',
            image: './placeholder.svg'
        };
    }
}

// 搜索过滤NFT
function filterNFTs() {
    const searchTerm = document.getElementById('searchInput').value.toLowerCase();
    const nftCards = document.querySelectorAll('#nftGrid .nft-card');
    
    nftCards.forEach(card => {
        const name = card.querySelector('.nft-name').textContent.toLowerCase();
        const description = card.querySelector('.nft-description').textContent.toLowerCase();
        const tokenId = card.querySelector('.nft-token-id').textContent.toLowerCase();
        
        if (name.includes(searchTerm) || description.includes(searchTerm) || tokenId.includes(searchTerm)) {
            card.style.display = 'block';
        } else {
            card.style.display = 'none';
        }
    });
}

// 关闭模态框
function closeModal() {
    document.querySelectorAll('.modal').forEach(modal => {
        modal.classList.add('hidden');
    });
    window.currentNFT = null;
}

// 显示通知
// 优化错误处理和用户体验
function showNotification(message, type = 'info', duration = 5000) {
    const notification = document.createElement('div');
    notification.className = `notification ${type}`;
    notification.innerHTML = `
        <div style="display: flex; align-items: center; gap: 10px;">
            <i class="fas ${getNotificationIcon(type)}"></i>
            <span>${message}</span>
            <button onclick="this.parentElement.parentElement.remove()" style="background: none; border: none; color: inherit; cursor: pointer; margin-left: auto;">
                <i class="fas fa-times"></i>
            </button>
        </div>
    `;
    
    document.getElementById('notifications').appendChild(notification);
    
    // 自动移除通知
    setTimeout(() => {
        if (notification.parentElement) {
            notification.remove();
        }
    }, duration);
}

function getNotificationIcon(type) {
    switch (type) {
        case 'success': return 'fa-check-circle';
        case 'error': return 'fa-exclamation-circle';
        case 'warning': return 'fa-exclamation-triangle';
        default: return 'fa-info-circle';
    }
}

// 优化文件验证
function validateImageFile(file) {
    const errors = [];
    
    // 检查文件类型
    if (!PINATA_CONFIG.OPTIONS.SUPPORTED_IMAGE_TYPES.includes(file.type)) {
        errors.push(`不支持的文件类型: ${file.type}。支持的类型: ${PINATA_CONFIG.OPTIONS.SUPPORTED_IMAGE_TYPES.join(', ')}`);
    }
    
    // 检查文件大小
    if (file.size > PINATA_CONFIG.OPTIONS.MAX_FILE_SIZE) {
        const maxSizeMB = (PINATA_CONFIG.OPTIONS.MAX_FILE_SIZE / (1024 * 1024)).toFixed(1);
        const fileSizeMB = (file.size / (1024 * 1024)).toFixed(1);
        errors.push(`文件过大: ${fileSizeMB}MB。最大允许: ${maxSizeMB}MB`);
    }
    
    // 检查文件名
    if (file.name.length > 100) {
        errors.push('文件名过长，请使用较短的文件名');
    }
    
    return errors;
}

// 优化handleFileSelect函数
async function handleFileSelect(event) {
    const file = event.target.files[0] || event.dataTransfer?.files[0];
    if (!file) return;
    
    try {
        // 验证文件
        const errors = validateImageFile(file);
        if (errors.length > 0) {
            showNotification(errors.join('<br>'), 'error');
            return;
        }
        
        selectedImageFile = file;
        
        // 显示文件信息
        const fileSizeMB = (file.size / (1024 * 1024)).toFixed(2);
        showNotification(`已选择文件: ${file.name} (${fileSizeMB}MB)`, 'success');
        
        // 创建预览
        const reader = new FileReader();
        reader.onload = function(e) {
            const previewContainer = document.getElementById('image-preview');
            previewContainer.innerHTML = `
                <div style="text-align: center;">
                    <img src="${e.target.result}" alt="预览图片" style="max-width: 100%; max-height: 200px; border-radius: 8px; box-shadow: 0 2px 8px rgba(0,0,0,0.1);">
                    <p style="margin-top: 10px; color: #666; font-size: 14px;">
                        文件名: ${file.name}<br>
                        大小: ${fileSizeMB}MB<br>
                        类型: ${file.type}
                    </p>
                </div>
            `;
            previewContainer.style.display = 'block';
        };
        reader.readAsDataURL(file);
        
        // 启用创建NFT按钮
        const createNFTBtn = document.getElementById('createNFTBtn');
        if (createNFTBtn) {
            createNFTBtn.disabled = false;
        }
        
    } catch (error) {
        console.error('文件选择错误:', error);
        showNotification('文件选择失败，请重试', 'error');
    }
}

// 优化createNFTWithIPFS函数
async function createNFTWithIPFS() {
    console.log('createNFTWithIPFS函数被调用');
    
    if (!selectedImageFile) {
        console.log('没有选择图片文件');
        showNotification('请先选择要上传的图片', 'warning');
        return;
    }
    
    console.log('选择的图片文件:', selectedImageFile.name);
    
    const name = document.getElementById('nft-name').value.trim();
    const description = document.getElementById('nft-description').value.trim();
    
    console.log('NFT名称:', name);
    console.log('NFT描述:', description);
    
    if (!name) {
        showNotification('请输入NFT名称', 'warning');
        document.getElementById('nft-name').focus();
        return;
    }
    
    if (!description) {
        showNotification('请输入NFT描述', 'warning');
        document.getElementById('nft-description').focus();
        return;
    }
    
    // 检查Pinata配置
    if (!validatePinataConfig()) {
        showNotification('请先配置Pinata API密钥', 'warning');
        document.querySelector('a[href="#pinata-config"]').click();
        return;
    }
    
    // 检查钱包连接
    if (!window.ethereum || !userAddress) {
        showNotification('请先连接钱包', 'warning');
        return;
    }
    
    const createBtn = document.getElementById('createNFTBtn');
    const originalText = createBtn.textContent;
    
    try {
        createBtn.disabled = true;
        createBtn.textContent = '创建中...';
        
        showLoadingOverlay('正在创建NFT...');
        
        await createNFTWithIPFS_Internal(name, description);
        
        showNotification('NFT创建成功！', 'success');
        resetCreateForm();
        
        // 刷新NFT列表
        setTimeout(() => {
            loadMyNFTs();
        }, 2000);
        
    } catch (error) {
        console.error('创建NFT失败:', error);
        let errorMessage = '创建NFT失败';
        let showRetry = false;
        let shouldResetForm = false; // 添加标志控制是否重置表单
        
        if (error.message.includes('User denied') || error.message.includes('用户取消') || error.code === 'ACTION_REJECTED') {
            errorMessage = '用户取消了交易';
            // 用户取消交易时不重置表单，保留用户输入的数据
        } else if (error.message.includes('insufficient funds')) {
            errorMessage = '余额不足，请确保有足够的MATIC支付gas费';
        } else if (error.message.includes('network') || error.message.includes('网络')) {
            errorMessage = '网络连接异常，请检查网络后重试';
            showRetry = true;
        } else if (error.message.includes('timeout') || error.message.includes('超时')) {
            errorMessage = '请求超时，可能是网络较慢，请稍后重试';
            showRetry = true;
        } else if (error.message.includes('Pinata') || error.message.includes('IPFS') || error.message.includes('上传')) {
            errorMessage = 'IPFS上传失败，请检查Pinata配置或网络连接';
            showRetry = true;
        } else if (error.message.includes('配置')) {
            errorMessage = '请检查Pinata API配置是否正确';
        } else {
            errorMessage = `创建失败: ${error.message}`;
            showRetry = true;
            shouldResetForm = true; // 其他未知错误时重置表单
        }
        
        showNotification(errorMessage + (showRetry ? ' 点击重试按钮可以再次尝试' : ''), 'error');
        
        // 只在特定情况下重置表单
        if (shouldResetForm) {
            resetCreateForm();
        }
        
        // 如果是网络相关错误，显示重试按钮
        if (showRetry) {
            createBtn.textContent = '重试';
            createBtn.style.backgroundColor = '#ff6b6b';
            setTimeout(() => {
                createBtn.style.backgroundColor = '';
                createBtn.textContent = originalText;
            }, 5000);
        }
    } finally {
        createBtn.disabled = false;
        if (createBtn.textContent === '创建中...') {
            createBtn.textContent = originalText;
        }
        hideLoadingOverlay();
    }
}

// 优化createNFTWithIPFS_Internal函数
async function createNFTWithIPFS_Internal(name, description) {
    updateUploadProgress(0, '准备上传图片到IPFS...');
    
    try {
        // 上传图片到IPFS
        updateUploadProgress(5, '正在连接IPFS服务...');
        
        const imageResult = await uploadFileToIPFS(selectedImageFile, {
            name: `${name} - Image`,
            keyvalues: {
                type: 'nft-image',
                nftName: name
            }
        }, (progress) => {
            updateUploadProgress(5 + progress * 0.35, `上传图片中... ${Math.round(progress)}%`);
        });
        
        if (!imageResult.success) {
            throw new Error(`图片上传失败: ${imageResult.error}`);
        }
        
        updateUploadProgress(40, '图片上传完成，生成元数据...');
        
        // 收集属性
        const attributes = [];
        document.querySelectorAll('.attribute-item').forEach(item => {
            const name = item.querySelector('.attribute-name').value.trim();
            const value = item.querySelector('.attribute-value').value.trim();
            if (name && value) {
                attributes.push({ trait_type: name, value: value });
            }
        });
        
        // 生成元数据
        const metadata = generateNFTMetadata({
            name,
            description,
            imageUrl: imageResult.url,
            attributes
        });
        
        updateUploadProgress(50, '上传元数据到IPFS...');
        
        // 上传元数据到IPFS
        const metadataResult = await uploadJSONToIPFS(metadata, {
            name: `${name} - Metadata`,
            keyvalues: {
                type: 'nft-metadata',
                nftName: name
            }
        });
        
        if (!metadataResult.success) {
            throw new Error(`元数据上传失败: ${metadataResult.error}${metadataResult.attempts ? ` (尝试了${metadataResult.attempts}次)` : ''}`);
        }
        
        updateUploadProgress(80, '准备铸造NFT...');
        
        // 铸造NFT
        const tokenURI = metadataResult.url;
        
        updateUploadProgress(90, '正在铸造NFT...');
        
        const tx = await nftContract.mint(userAddress, tokenURI);
        
        updateUploadProgress(95, '等待交易确认...');
        
        await tx.wait();
        
        updateUploadProgress(100, 'NFT创建完成！');
        
        // 保存NFT数据
        currentNFTData = {
            name,
            description,
            imageUrl: imageResult.url,
            metadataUrl: metadataResult.url,
            attributes,
            tokenURI
        };
        
    } catch (error) {
        console.error('NFT创建过程中出错:', error);
        throw error;
    }
}

// 优化上传进度显示
function updateUploadProgress(percentage, message) {
    const progressContainer = document.getElementById('upload-progress');
    const progressFill = document.getElementById('progress-fill');
    const progressPercent = document.getElementById('progress-percent');
    const progressStep = document.getElementById('progress-step');
    
    // 检查元素是否存在，避免null引用错误
    if (!progressContainer || !progressFill || !progressPercent || !progressStep) {
        console.warn('进度条元素未找到，跳过进度更新');
        return;
    }
    
    if (percentage > 0) {
        progressContainer.style.display = 'block';
        progressFill.style.width = `${percentage}%`;
        progressPercent.textContent = `${percentage}%`;
        progressStep.textContent = message;
        
        // 添加动画效果
        if (percentage === 100) {
            progressFill.style.background = 'linear-gradient(90deg, #28a745, #20c997)';
            setTimeout(() => {
                progressContainer.style.display = 'none';
                progressFill.style.background = 'linear-gradient(90deg, #007bff, #28a745)';
                progressFill.style.width = '0%';
                progressPercent.textContent = '0%';
                progressStep.textContent = '准备上传...';
            }, 2000);
        }
    } else {
        progressContainer.style.display = 'none';
        progressFill.style.width = '0%';
        progressPercent.textContent = '0%';
        progressStep.textContent = '准备上传...';
    }
}

// 优化Pinata配置测试
async function testPinataConnection() {
    const testBtn = document.getElementById('test-pinata-btn');
    const originalText = testBtn.textContent;
    
    try {
        testBtn.disabled = true;
        testBtn.textContent = '测试中...';
        
        const result = await getPinataUsage();
        
        if (result.success) {
            showNotification('Pinata连接测试成功！', 'success');
            updatePinataStatus();
        } else {
            showNotification(`连接测试失败: ${result.error}`, 'error');
        }
        
    } catch (error) {
        console.error('测试Pinata连接失败:', error);
        showNotification('连接测试失败，请检查API密钥', 'error');
    } finally {
        testBtn.disabled = false;
        testBtn.textContent = originalText;
    }
}

// 优化拖拽上传
function setupDragAndDrop() {
    const uploadZone = document.getElementById('upload-zone');
    
    if (!uploadZone) {
        console.warn('Upload zone element not found');
        return;
    }
    
    ['dragenter', 'dragover', 'dragleave', 'drop'].forEach(eventName => {
        uploadZone.addEventListener(eventName, preventDefaults, false);
    });
    
    function preventDefaults(e) {
        e.preventDefault();
        e.stopPropagation();
    }
    
    ['dragenter', 'dragover'].forEach(eventName => {
        uploadZone.addEventListener(eventName, highlight, false);
    });
    
    ['dragleave', 'drop'].forEach(eventName => {
        uploadZone.addEventListener(eventName, unhighlight, false);
    });
    
    function highlight(e) {
        uploadZone.classList.add('dragover');
    }
    
    function unhighlight(e) {
        uploadZone.classList.remove('dragover');
    }
    
    uploadZone.addEventListener('drop', handleFileSelect, false);
}

// 优化表单重置
function resetCreateForm() {
    selectedImageFile = null;
    currentNFTData = null;
    
    // 添加null检查，防止DOM元素不存在时出错
    const nameInput = document.getElementById('nft-name');
    const descInput = document.getElementById('nft-description');
    const imagePreview = document.getElementById('image-preview');
    const uploadProgress = document.getElementById('upload-progress');
    const attributesContainer = document.getElementById('nft-attributes');
    const fileInput = document.getElementById('nft-image');
    
    if (nameInput) nameInput.value = '';
    if (descInput) descInput.value = '';
    if (imagePreview) imagePreview.style.display = 'none';
    if (uploadProgress) uploadProgress.style.display = 'none';
    
    // 清空属性
    if (attributesContainer) {
        attributesContainer.innerHTML = '';
    }
    
    // 重置文件输入
    if (fileInput) {
        fileInput.value = '';
    }
    
    showNotification('表单已重置', 'info', 2000);
}

// 添加键盘快捷键支持
document.addEventListener('keydown', function(e) {
    // Ctrl+Enter 快速创建NFT
    if (e.ctrlKey && e.key === 'Enter') {
        const activeTab = document.querySelector('.tab-content.active');
        if (activeTab && activeTab.id === 'upload-create-tab') {
            createNFTWithIPFS();
        }
    }
    
    // Escape 关闭模态框
    if (e.key === 'Escape') {
        const modals = document.querySelectorAll('.modal:not(.hidden)');
        modals.forEach(modal => modal.classList.add('hidden'));
    }
});

// 添加自动保存功能
let autoSaveTimer;
function setupAutoSave() {
    const inputs = ['nft-name', 'nft-description'];
    
    inputs.forEach(inputId => {
        const input = document.getElementById(inputId);
        if (input) {
            input.addEventListener('input', () => {
                clearTimeout(autoSaveTimer);
                autoSaveTimer = setTimeout(() => {
                    const formData = {
                        name: document.getElementById('nft-name').value,
                        description: document.getElementById('nft-description').value,
                        timestamp: Date.now()
                    };
                    localStorage.setItem('nft-draft', JSON.stringify(formData));
                }, 1000);
            });
        }
    });
}

// 恢复草稿
function restoreDraft() {
    const draft = localStorage.getItem('nft-draft');
    if (draft) {
        try {
            const formData = JSON.parse(draft);
            // 只恢复24小时内的草稿
            if (Date.now() - formData.timestamp < 24 * 60 * 60 * 1000) {
                document.getElementById('nft-name').value = formData.name || '';
                document.getElementById('nft-description').value = formData.description || '';
                
                if (formData.name || formData.description) {
                    showNotification('已恢复之前的草稿', 'info', 3000);
                }
            }
        } catch (error) {
            console.error('恢复草稿失败:', error);
        }
    }
}

// 更新Pinata状态显示
function updatePinataStatus() {
    const pinataJWT = localStorage.getItem('pinataJWT');
    const pinataApiKey = localStorage.getItem('pinataApiKey');
    const pinataSecretKey = localStorage.getItem('pinataSecretKey');
    
    const statusElement = document.getElementById('pinataStatus');
    const configSection = document.querySelector('.pinata-config');
    
    if (pinataJWT || (pinataApiKey && pinataSecretKey)) {
        if (statusElement) {
            statusElement.innerHTML = '<i class="fas fa-check-circle"></i> Pinata已配置';
            statusElement.className = 'pinata-status configured';
        }
        
        if (configSection) {
            configSection.classList.add('configured');
        }
        
        // 填充已保存的配置
        const jwtInput = document.getElementById('pinataJWT');
        const apiKeyInput = document.getElementById('pinataApiKey');
        const secretKeyInput = document.getElementById('pinataSecretKey');
        
        if (jwtInput && pinataJWT) {
            jwtInput.value = pinataJWT;
        }
        
        if (apiKeyInput && pinataApiKey) {
            apiKeyInput.value = pinataApiKey;
        }
        
        if (secretKeyInput && pinataSecretKey) {
            secretKeyInput.value = pinataSecretKey;
        }
    } else {
        if (statusElement) {
            statusElement.innerHTML = '<i class="fas fa-exclamation-circle"></i> 请配置Pinata';
            statusElement.className = 'pinata-status not-configured';
        }
        
        if (configSection) {
            configSection.classList.remove('configured');
        }
    }
}

// 添加NFT属性
function addNFTAttribute() {
    const attributesContainer = document.getElementById('nft-attributes');
    if (!attributesContainer) return;
    
    const attributeRow = document.createElement('div');
    attributeRow.className = 'attribute-row';
    attributeRow.innerHTML = `
        <input type="text" placeholder="属性名称" class="attr-name">
        <input type="text" placeholder="属性值" class="attr-value">
        <button type="button" class="btn-remove-attr">
            <i class="fas fa-times"></i>
        </button>
    `;
    
    // 添加删除按钮事件
    const removeBtn = attributeRow.querySelector('.btn-remove-attr');
    removeBtn.addEventListener('click', () => {
        attributeRow.remove();
        updatePreview();
    });
    
    // 添加输入事件监听
    const inputs = attributeRow.querySelectorAll('input');
    inputs.forEach(input => {
        input.addEventListener('input', updatePreview);
    });
    
    attributesContainer.appendChild(attributeRow);
    updatePreview();
}

// 更新预览
function updatePreview() {
    const nameInput = document.getElementById('nft-name');
    const descInput = document.getElementById('nft-description');
    const previewName = document.getElementById('previewName');
    const previewDesc = document.getElementById('previewDescription');
    const previewAttrs = document.getElementById('previewAttributes');
    
    if (previewName && nameInput) {
        previewName.textContent = nameInput.value || 'NFT 名称';
    }
    
    if (previewDesc && descInput) {
        previewDesc.textContent = descInput.value || 'NFT 描述';
    }
    
    if (previewAttrs) {
        const attributes = [];
        document.querySelectorAll('.attribute-row').forEach(row => {
            const name = row.querySelector('.attr-name').value.trim();
            const value = row.querySelector('.attr-value').value.trim();
            if (name && value) {
                attributes.push({ name, value });
            }
        });
        
        previewAttrs.innerHTML = attributes.map(attr => 
            `<div class="preview-attr">
                <span class="attr-name">${attr.name}:</span>
                <span class="attr-value">${attr.value}</span>
            </div>`
        ).join('');
    }
}

// 切换铸造标签页
function switchMintTab(event) {
    const clickedTab = event.target.closest('.tab-btn');
    if (!clickedTab) return;
    
    const tabType = clickedTab.dataset.tab;
    
    // 更新标签按钮状态
    document.querySelectorAll('.tab-btn').forEach(btn => {
        btn.classList.remove('active');
    });
    clickedTab.classList.add('active');
    
    // 更新标签内容显示
    document.querySelectorAll('.tab-content').forEach(content => {
        content.classList.remove('active');
    });
    
    if (tabType === 'upload') {
        document.getElementById('uploadTab').classList.add('active');
    } else if (tabType === 'uri') {
        document.getElementById('uriTab').classList.add('active');
    }
}

// 清除草稿
function clearDraft() {
    localStorage.removeItem('nft-draft');
}

// 在页面加载时设置这些功能
document.addEventListener('DOMContentLoaded', function() {
    // ... existing code ...
    
    // 设置拖拽上传
    setupDragAndDrop();
    
    // 设置自动保存
    setupAutoSave();
    
    // 恢复草稿
    restoreDraft();
    
    // 清除旧草稿（在成功创建NFT后）
    const originalCreateFunction = createNFTWithIPFS;
    window.createNFTWithIPFS = async function() {
        try {
            await originalCreateFunction();
            clearDraft();
        } catch (error) {
            throw error;
        }
    };
});

// 显示/隐藏加载状态
function showLoading(show) {
    const loadingOverlay = document.getElementById('loadingOverlay');
    if (loadingOverlay) {
        if (show) {
            loadingOverlay.classList.remove('hidden');
        } else {
            loadingOverlay.classList.add('hidden');
        }
    }
}

// 显示加载覆盖层
function showLoadingOverlay(message = '加载中...') {
    const loadingOverlay = document.getElementById('loadingOverlay');
    const loadingText = loadingOverlay.querySelector('.loading-text');
    if (loadingText) {
        loadingText.textContent = message;
    }
    loadingOverlay.classList.remove('hidden');
}

// 隐藏加载覆盖层
function hideLoadingOverlay() {
    const loadingOverlay = document.getElementById('loadingOverlay');
    if (loadingOverlay) {
        loadingOverlay.classList.add('hidden');
    }
}

// 保存Pinata配置
async function savePinataConfig() {
    try {
        const jwtInput = document.getElementById('pinataJWT');
        const apiKeyInput = document.getElementById('pinataApiKey');
        const secretKeyInput = document.getElementById('pinataSecretKey');
        
        const jwt = jwtInput ? jwtInput.value.trim() : '';
        const apiKey = apiKeyInput ? apiKeyInput.value.trim() : '';
        const secretKey = secretKeyInput ? secretKeyInput.value.trim() : '';
        
        // 验证输入
        if (!jwt && (!apiKey || !secretKey)) {
            showNotification('请输入JWT令牌或API密钥对', 'warning');
            return;
        }
        
        if (jwt && (apiKey || secretKey)) {
            showNotification('请只使用JWT令牌或API密钥对中的一种', 'warning');
            return;
        }
        
        // 保存到localStorage
        if (jwt) {
            localStorage.setItem('pinataJWT', jwt);
            localStorage.removeItem('pinataApiKey');
            localStorage.removeItem('pinataSecretKey');
            setPinataCredentials('', '', jwt);
        } else {
            localStorage.setItem('pinataApiKey', apiKey);
            localStorage.setItem('pinataSecretKey', secretKey);
            localStorage.removeItem('pinataJWT');
            setPinataCredentials(apiKey, secretKey, '');
        }
        
        // 测试配置
        showNotification('正在测试Pinata连接...', 'info');
        
        const testResult = await testPinataConnection();
        
        if (testResult.success) {
            showNotification('Pinata配置保存成功！', 'success');
            updatePinataStatus();
            // 更新网络状态指示器
            checkNetworkStatus().then(updateNetworkStatusIndicator);
        } else {
            showNotification(`配置测试失败: ${testResult.error}`, 'error');
            // 即使测试失败也保存配置，可能是网络问题
            updatePinataStatus();
            // 更新网络状态指示器
            checkNetworkStatus().then(updateNetworkStatusIndicator);
        }
        
    } catch (error) {
        console.error('保存Pinata配置失败:', error);
        showNotification('保存配置失败，请重试', 'error');
    }
}

// 清除Pinata配置
function clearPinataConfig() {
    try {
        // 清除localStorage
        localStorage.removeItem('pinataJWT');
        localStorage.removeItem('pinataApiKey');
        localStorage.removeItem('pinataSecretKey');
        
        // 清除内存中的配置
        setPinataCredentials('', '', '');
        
        // 清除输入框
        const jwtInput = document.getElementById('pinataJWT');
        const apiKeyInput = document.getElementById('pinataApiKey');
        const secretKeyInput = document.getElementById('pinataSecretKey');
        
        if (jwtInput) jwtInput.value = '';
        if (apiKeyInput) apiKeyInput.value = '';
        if (secretKeyInput) secretKeyInput.value = '';
        
        // 更新状态显示
        updatePinataStatus();
        
        // 更新网络状态指示器
        checkNetworkStatus().then(updateNetworkStatusIndicator);
        
        showNotification('Pinata配置已清除', 'info');
        
    } catch (error) {
        console.error('清除Pinata配置失败:', error);
        showNotification('清除配置失败，请重试', 'error');
    }
}

// 测试Pinata连接
async function testPinataConnection() {
    try {
        if (!validatePinataConfig()) {
            return {
                success: false,
                error: '请先配置Pinata API密钥'
            };
        }
        
        const response = await fetch(`${PINATA_CONFIG.API_URL}/data/testAuthentication`, {
            method: 'GET',
            headers: {
                ...getPinataAuthHeaders()
            }
        });
        
        if (response.ok) {
            const data = await response.json();
            return {
                success: true,
                message: data.message || '连接成功'
            };
        } else {
            let errorMessage;
            try {
                const errorData = await response.json();
                errorMessage = errorData.error || errorData.message || `HTTP ${response.status}`;
            } catch (parseError) {
                errorMessage = `HTTP ${response.status} - ${response.statusText}`;
            }
            
            // 特殊处理401认证错误
            if (response.status === 401) {
                errorMessage = 'Pinata API认证失败，请检查JWT Token或API密钥是否正确';
            }
            
            return {
                success: false,
                error: errorMessage
            };
        }
        
    } catch (error) {
        return {
            success: false,
            error: error.message || '网络连接失败'
        };
    }
}

// 网络状态检测和连接测试功能
async function checkNetworkStatus() {
    const status = {
        online: navigator.onLine,
        pinataReachable: false,
        latency: null,
        error: null
    };
    
    try {
        // 检查基本网络连接
        if (!navigator.onLine) {
            status.error = '设备未连接到网络';
            return status;
        }
        
        // 测试Pinata API连接
        const startTime = Date.now();
        const controller = new AbortController();
        const timeoutId = setTimeout(() => controller.abort(), 10000); // 10秒超时
        
        try {
            // 检查是否有有效的Pinata凭据
            if (!validatePinataConfig()) {
                status.error = 'Pinata凭据未配置';
                status.pinataReachable = false;
                return status;
            }
            
            const response = await fetch('https://api.pinata.cloud/data/testAuthentication', {
                method: 'GET',
                headers: getPinataAuthHeaders(),
                signal: controller.signal
            });
            
            clearTimeout(timeoutId);
            status.latency = Date.now() - startTime;
            status.pinataReachable = response.ok;
            
            if (!response.ok) {
                const errorData = await response.json().catch(() => ({}));
                status.error = errorData.error || `Pinata API错误: ${response.status}`;
            }
        } catch (error) {
            clearTimeout(timeoutId);
            if (error.name === 'AbortError') {
                status.error = 'Pinata API连接超时';
            } else {
                status.error = `网络连接失败: ${error.message}`;
            }
        }
        
    } catch (error) {
        status.error = `网络检测失败: ${error.message}`;
    }
    
    return status;
}

// 显示网络状态指示器
function updateNetworkStatusIndicator(status) {
    let indicator = document.getElementById('network-status-indicator');
    if (!indicator) {
        indicator = document.createElement('div');
        indicator.id = 'network-status-indicator';
        indicator.style.cssText = `
            position: fixed;
            top: 20px;
            right: 20px;
            padding: 8px 12px;
            border-radius: 20px;
            font-size: 12px;
            font-weight: bold;
            z-index: 1000;
            transition: all 0.3s ease;
            cursor: pointer;
        `;
        document.body.appendChild(indicator);
        
        // 点击显示详细信息
        indicator.addEventListener('click', () => showNetworkStatusDetails(status));
    }
    
    if (status.online && status.pinataReachable) {
        indicator.textContent = `🟢 网络正常 ${status.latency}ms`;
        indicator.style.backgroundColor = '#d4edda';
        indicator.style.color = '#155724';
        indicator.style.border = '1px solid #c3e6cb';
    } else if (status.online && !status.pinataReachable) {
        indicator.textContent = '🟡 Pinata连接异常';
        indicator.style.backgroundColor = '#fff3cd';
        indicator.style.color = '#856404';
        indicator.style.border = '1px solid #ffeaa7';
    } else {
        indicator.textContent = '🔴 网络离线';
        indicator.style.backgroundColor = '#f8d7da';
        indicator.style.color = '#721c24';
        indicator.style.border = '1px solid #f5c6cb';
    }
}

// 显示网络状态详细信息
function showNetworkStatusDetails(status) {
    const details = `
网络状态详情:
• 设备在线: ${status.online ? '是' : '否'}
• Pinata可达: ${status.pinataReachable ? '是' : '否'}
• 延迟: ${status.latency ? status.latency + 'ms' : '未知'}
${status.error ? '• 错误: ' + status.error : ''}

${!status.pinataReachable ? '\n建议:\n• 检查Pinata API密钥配置\n• 确认网络连接稳定\n• 尝试刷新页面' : ''}
    `;
    
    alert(details);
}

// 改进的错误处理和用户提示
function handleNetworkError(error, context = '') {
    console.error(`网络错误 ${context}:`, error);
    
    let userMessage = '';
    let suggestions = [];
    let isCircuitBreakerError = false;
    
    // 检查是否为MetaMask熔断器错误
    if (error.message.includes('circuit breaker is open') || 
        error.message.includes('Execution prevented because the circuit breaker is open')) {
        isCircuitBreakerError = true;
        userMessage = 'MetaMask请求过于频繁，熔断器已激活';
        suggestions = [
            '等待30秒后重试',
            '减少页面刷新频率',
            '避免快速连续操作',
            '检查网络连接稳定性'
        ];
    } else if (error.message.includes('timeout') || error.message.includes('超时')) {
        userMessage = '请求超时';
        suggestions = [
            '检查网络连接是否稳定',
            '尝试切换到更稳定的网络',
            '稍后重试'
        ];
    } else if (error.message.includes('Failed to fetch') || error.message.includes('网络错误')) {
        userMessage = '网络连接失败';
        suggestions = [
            '检查设备网络连接',
            '确认防火墙设置',
            '尝试刷新页面'
        ];
    } else if (error.message.includes('Unauthorized') || error.message.includes('401')) {
        userMessage = 'Pinata API认证失败';
        suggestions = [
            '检查API密钥是否正确',
            '确认JWT令牌有效性',
            '重新配置Pinata凭据'
        ];
    } else if (error.message.includes('Rate limit') || error.message.includes('429')) {
        userMessage = 'API请求频率过高';
        suggestions = [
            '等待几分钟后重试',
            '检查Pinata账户配额',
            '考虑升级Pinata套餐'
        ];
    } else {
        userMessage = '未知网络错误';
        suggestions = [
            '检查网络连接',
            '刷新页面重试',
            '联系技术支持'
        ];
    }
    
    const fullMessage = `${userMessage}\n\n建议解决方案:\n${suggestions.map(s => '• ' + s).join('\n')}`;
    
    // 对于熔断器错误，显示更友好的提示
    if (isCircuitBreakerError) {
        showNotification('网络请求过于频繁，请稍后再试', 'warning', 8000);
        
        // 显示恢复提示
        setTimeout(() => {
            showNotification('您可以尝试重新操作了', 'info', 3000);
        }, 30000);
    } else {
        showNotification(userMessage, 'error');
    }
    
    // 在控制台显示详细信息供调试
    console.log('详细错误信息:', fullMessage);
    
    return {
        userMessage,
        suggestions,
        fullMessage,
        isCircuitBreakerError
    };
}

// 定期检查网络状态
let networkStatusInterval;

function startNetworkMonitoring() {
    // 立即检查一次
    checkNetworkStatus().then(updateNetworkStatusIndicator);
    
    // 每30秒检查一次
    networkStatusInterval = setInterval(async () => {
        const status = await checkNetworkStatus();
        updateNetworkStatusIndicator(status);
    }, 30000);
    
    // 监听网络状态变化
    window.addEventListener('online', () => {
        checkNetworkStatus().then(updateNetworkStatusIndicator);
        showNotification('网络连接已恢复', 'success');
    });
    
    window.addEventListener('offline', () => {
        updateNetworkStatusIndicator({ online: false, pinataReachable: false, error: '网络连接断开' });
        showNotification('网络连接已断开', 'warning');
    });
}

function stopNetworkMonitoring() {
    if (networkStatusInterval) {
        clearInterval(networkStatusInterval);
        networkStatusInterval = null;
    }
}

// 缓存机制
const contractCallCache = new Map();
const CACHE_DURATION = 30000; // 30秒缓存

// 带缓存的合约调用函数
async function cachedContractCall(key, fn, cacheDuration = CACHE_DURATION) {
    const now = Date.now();
    const cached = contractCallCache.get(key);
    
    if (cached && (now - cached.timestamp) < cacheDuration) {
        console.log(`使用缓存数据: ${key}`);
        return cached.data;
    }
    
    try {
        const data = await retryWithDelay(fn, 3, 1000);
        contractCallCache.set(key, {
            data,
            timestamp: now
        });
        console.log(`缓存新数据: ${key}`);
        return data;
    } catch (error) {
        // 如果有旧缓存数据，在出错时使用它
        if (cached) {
            console.log(`使用过期缓存数据: ${key}`);
            return cached.data;
        }
        throw error;
    }
}

// 清除缓存函数
function clearContractCache(pattern = null) {
    if (pattern) {
        for (const key of contractCallCache.keys()) {
            if (key.includes(pattern)) {
                contractCallCache.delete(key);
            }
        }
    } else {
        contractCallCache.clear();
    }
}

// 防抖函数
function debounce(func, wait) {
    let timeout;
    return function executedFunction(...args) {
        const later = () => {
            clearTimeout(timeout);
            func(...args);
        };
        clearTimeout(timeout);
        timeout = setTimeout(later, wait);
    };
}

// 重试机制函数 - 用于处理MetaMask熔断器错误
async function retryWithDelay(fn, maxRetries = 3, delay = 1000) {
    let lastError;
    
    for (let i = 0; i < maxRetries; i++) {
        try {
            return await fn();
        } catch (error) {
            lastError = error;
            console.log(`重试 ${i + 1}/${maxRetries} 失败:`, error.message);
            
            // 如果是熔断器错误，增加延迟时间
            const isCircuitBreakerError = error.message && error.message.includes('circuit breaker is open');
            const currentDelay = isCircuitBreakerError ? delay * (i + 2) : delay;
            
            if (i < maxRetries - 1) {
                console.log(`等待 ${currentDelay}ms 后重试...`);
                await new Promise(resolve => setTimeout(resolve, currentDelay));
            }
        }
    }
    
    throw lastError;
}