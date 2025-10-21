// ChainLink 自动化银行 DApp 前端逻辑

class AutomatedBankDApp {
    constructor() {
        this.provider = null;
        this.signer = null;
        this.contract = null;
        this.userAddress = null;
        this.contractAddress = null;
        
        // 合约 ABI
        this.contractABI = [
	{
		"inputs": [
			{
				"internalType": "uint256",
				"name": "_threshold",
				"type": "uint256"
			}
		],
		"stateMutability": "nonpayable",
		"type": "constructor"
	},
	{
		"inputs": [],
		"name": "InsufficientBalance",
		"type": "error"
	},
	{
		"inputs": [],
		"name": "InvalidThreshold",
		"type": "error"
	},
	{
		"inputs": [],
		"name": "TransferAmountTooSmall",
		"type": "error"
	},
	{
		"inputs": [],
		"name": "UpkeepConditionsNotMet",
		"type": "error"
	},
	{
		"inputs": [],
		"name": "ZeroAddressNotAllowed",
		"type": "error"
	},
	{
		"anonymous": false,
		"inputs": [
			{
				"indexed": false,
				"internalType": "uint256",
				"name": "amount",
				"type": "uint256"
			},
			{
				"indexed": false,
				"internalType": "uint256",
				"name": "remainingBalance",
				"type": "uint256"
			},
			{
				"indexed": false,
				"internalType": "uint256",
				"name": "timestamp",
				"type": "uint256"
			}
		],
		"name": "AutoTransfer",
		"type": "event"
	},
	{
		"anonymous": false,
		"inputs": [
			{
				"indexed": true,
				"internalType": "address",
				"name": "user",
				"type": "address"
			},
			{
				"indexed": false,
				"internalType": "uint256",
				"name": "amount",
				"type": "uint256"
			},
			{
				"indexed": false,
				"internalType": "uint256",
				"name": "newTotal",
				"type": "uint256"
			}
		],
		"name": "Deposit",
		"type": "event"
	},
	{
		"anonymous": false,
		"inputs": [
			{
				"indexed": true,
				"internalType": "address",
				"name": "previousOwner",
				"type": "address"
			},
			{
				"indexed": true,
				"internalType": "address",
				"name": "newOwner",
				"type": "address"
			}
		],
		"name": "OwnershipTransferred",
		"type": "event"
	},
	{
		"anonymous": false,
		"inputs": [
			{
				"indexed": false,
				"internalType": "uint256",
				"name": "oldThreshold",
				"type": "uint256"
			},
			{
				"indexed": false,
				"internalType": "uint256",
				"name": "newThreshold",
				"type": "uint256"
			}
		],
		"name": "ThresholdUpdated",
		"type": "event"
	},
	{
		"anonymous": false,
		"inputs": [
			{
				"indexed": true,
				"internalType": "address",
				"name": "user",
				"type": "address"
			},
			{
				"indexed": false,
				"internalType": "uint256",
				"name": "amount",
				"type": "uint256"
			}
		],
		"name": "Withdrawal",
		"type": "event"
	},
	{
		"stateMutability": "payable",
		"type": "fallback"
	},
	{
		"inputs": [],
		"name": "MIN_INTERVAL",
		"outputs": [
			{
				"internalType": "uint256",
				"name": "",
				"type": "uint256"
			}
		],
		"stateMutability": "view",
		"type": "function"
	},
	{
		"inputs": [],
		"name": "MIN_TRANSFER_AMOUNT",
		"outputs": [
			{
				"internalType": "uint256",
				"name": "",
				"type": "uint256"
			}
		],
		"stateMutability": "view",
		"type": "function"
	},
	{
		"inputs": [
			{
				"internalType": "bytes",
				"name": "",
				"type": "bytes"
			}
		],
		"name": "checkUpkeep",
		"outputs": [
			{
				"internalType": "bool",
				"name": "upkeepNeeded",
				"type": "bool"
			},
			{
				"internalType": "bytes",
				"name": "",
				"type": "bytes"
			}
		],
		"stateMutability": "view",
		"type": "function"
	},
	{
		"inputs": [],
		"name": "deposit",
		"outputs": [],
		"stateMutability": "payable",
		"type": "function"
	},
	{
		"inputs": [
			{
				"internalType": "address",
				"name": "",
				"type": "address"
			}
		],
		"name": "deposits",
		"outputs": [
			{
				"internalType": "uint256",
				"name": "",
				"type": "uint256"
			}
		],
		"stateMutability": "view",
		"type": "function"
	},
	{
		"inputs": [],
		"name": "emergencyWithdraw",
		"outputs": [],
		"stateMutability": "nonpayable",
		"type": "function"
	},
	{
		"inputs": [],
		"name": "getContractBalance",
		"outputs": [
			{
				"internalType": "uint256",
				"name": "",
				"type": "uint256"
			}
		],
		"stateMutability": "view",
		"type": "function"
	},
	{
		"inputs": [],
		"name": "getExpectedTransferAmount",
		"outputs": [
			{
				"internalType": "uint256",
				"name": "",
				"type": "uint256"
			}
		],
		"stateMutability": "view",
		"type": "function"
	},
	{
		"inputs": [],
		"name": "getTimeUntilNextTransfer",
		"outputs": [
			{
				"internalType": "uint256",
				"name": "",
				"type": "uint256"
			}
		],
		"stateMutability": "view",
		"type": "function"
	},
	{
		"inputs": [],
		"name": "getUpkeepStatus",
		"outputs": [
			{
				"internalType": "bool",
				"name": "thresholdMet",
				"type": "bool"
			},
			{
				"internalType": "bool",
				"name": "intervalMet",
				"type": "bool"
			},
			{
				"internalType": "bool",
				"name": "balanceSufficient",
				"type": "bool"
			},
			{
				"internalType": "bool",
				"name": "amountValid",
				"type": "bool"
			},
			{
				"internalType": "bool",
				"name": "upkeepNeeded",
				"type": "bool"
			},
			{
				"internalType": "uint256",
				"name": "currentDeposits",
				"type": "uint256"
			},
			{
				"internalType": "uint256",
				"name": "currentThreshold",
				"type": "uint256"
			},
			{
				"internalType": "uint256",
				"name": "timeRemaining",
				"type": "uint256"
			},
			{
				"internalType": "uint256",
				"name": "calculatedTransferAmount",
				"type": "uint256"
			}
		],
		"stateMutability": "view",
		"type": "function"
	},
	{
		"inputs": [
			{
				"internalType": "address",
				"name": "user",
				"type": "address"
			}
		],
		"name": "getUserBalance",
		"outputs": [
			{
				"internalType": "uint256",
				"name": "",
				"type": "uint256"
			}
		],
		"stateMutability": "view",
		"type": "function"
	},
	{
		"inputs": [],
		"name": "lastTransferTime",
		"outputs": [
			{
				"internalType": "uint256",
				"name": "",
				"type": "uint256"
			}
		],
		"stateMutability": "view",
		"type": "function"
	},
	{
		"inputs": [],
		"name": "owner",
		"outputs": [
			{
				"internalType": "address",
				"name": "",
				"type": "address"
			}
		],
		"stateMutability": "view",
		"type": "function"
	},
	{
		"inputs": [
			{
				"internalType": "bytes",
				"name": "",
				"type": "bytes"
			}
		],
		"name": "performUpkeep",
		"outputs": [],
		"stateMutability": "nonpayable",
		"type": "function"
	},
	{
		"inputs": [],
		"name": "threshold",
		"outputs": [
			{
				"internalType": "uint256",
				"name": "",
				"type": "uint256"
			}
		],
		"stateMutability": "view",
		"type": "function"
	},
	{
		"inputs": [],
		"name": "totalDeposits",
		"outputs": [
			{
				"internalType": "uint256",
				"name": "",
				"type": "uint256"
			}
		],
		"stateMutability": "view",
		"type": "function"
	},
	{
		"inputs": [
			{
				"internalType": "address",
				"name": "newOwner",
				"type": "address"
			}
		],
		"name": "transferOwnership",
		"outputs": [],
		"stateMutability": "nonpayable",
		"type": "function"
	},
	{
		"inputs": [
			{
				"internalType": "uint256",
				"name": "_newThreshold",
				"type": "uint256"
			}
		],
		"name": "updateThreshold",
		"outputs": [],
		"stateMutability": "nonpayable",
		"type": "function"
	},
	{
		"inputs": [
			{
				"internalType": "uint256",
				"name": "amount",
				"type": "uint256"
			}
		],
		"name": "withdraw",
		"outputs": [],
		"stateMutability": "nonpayable",
		"type": "function"
	},
	{
		"stateMutability": "payable",
		"type": "receive"
	}
];
        
        this.init();
    }
    
    async init() {
        // 绑定事件监听器
        this.bindEvents();
        
        // 检查是否已连接钱包
        if (typeof window.ethereum !== 'undefined') {
            try {
                const accounts = await window.ethereum.request({ method: 'eth_accounts' });
                if (accounts.length > 0) {
                    await this.connectWallet();
                }
            } catch (error) {
                console.error('初始化检查钱包失败:', error);
            }
        }
        
        // 启动状态更新定时器
        this.startStatusUpdater();
    }
    
    bindEvents() {
        // 钱包连接
        document.getElementById('connectWallet').addEventListener('click', () => this.connectWallet());
        document.getElementById('switchNetwork').addEventListener('click', () => this.switchToSepolia());
        
        // 合约交互
        document.getElementById('contractAddress').addEventListener('input', (e) => this.setContractAddress(e.target.value));
        document.getElementById('depositBtn').addEventListener('click', () => this.deposit());
        document.getElementById('withdrawBtn').addEventListener('click', () => this.withdraw());
        document.getElementById('updateThresholdBtn').addEventListener('click', () => this.updateThreshold());
        
        // Upkeep 操作
        document.getElementById('checkUpkeepBtn').addEventListener('click', () => this.checkUpkeepStatus());
        document.getElementById('performUpkeepBtn').addEventListener('click', () => this.performUpkeep());
        
        // 监听账户变化
        if (typeof window.ethereum !== 'undefined') {
            window.ethereum.on('accountsChanged', (accounts) => {
                if (accounts.length === 0) {
                    this.disconnect();
                } else {
                    this.connectWallet();
                }
            });
            
            window.ethereum.on('chainChanged', () => {
                window.location.reload();
            });
        }
    }
    
    async connectWallet() {
        try {
            if (typeof window.ethereum === 'undefined') {
                this.showMessage('请安装 MetaMask 钱包', 'error');
                return;
            }
            
            // 请求连接钱包
            const accounts = await window.ethereum.request({ method: 'eth_requestAccounts' });
            
            // 创建 provider 和 signer
            this.provider = new ethers.BrowserProvider(window.ethereum);
            this.signer = await this.provider.getSigner();
            this.userAddress = accounts[0];
            
            // 检查网络
            const network = await this.provider.getNetwork();
            if (network.chainId !== 11155111) { // Sepolia testnet
                document.getElementById('switchNetwork').style.display = 'block';
                this.showMessage('请切换到 Sepolia 测试网络', 'error');
                return;
            } else {
                document.getElementById('switchNetwork').style.display = 'none';
            }
            
            // 更新 UI
            this.updateWalletInfo();
            this.showMessage('钱包连接成功', 'success');
            
        } catch (error) {
            console.error('连接钱包失败:', error);
            this.showMessage('连接钱包失败: ' + error.message, 'error');
        }
    }
    
    async switchToSepolia() {
        try {
            await window.ethereum.request({
                method: 'wallet_switchEthereumChain',
                params: [{ chainId: '0xaa36a7' }], // Sepolia chainId
            });
        } catch (error) {
            if (error.code === 4902) {
                // 网络不存在，添加网络
                try {
                    await window.ethereum.request({
                        method: 'wallet_addEthereumChain',
                        params: [{
                            chainId: '0xaa36a7',
                            chainName: 'Sepolia Test Network',
                            nativeCurrency: {
                                name: 'ETH',
                                symbol: 'ETH',
                                decimals: 18
                            },
                            rpcUrls: ['https://sepolia.infura.io/v3/'],
                            blockExplorerUrls: ['https://sepolia.etherscan.io/']
                        }]
                    });
                } catch (addError) {
                    this.showMessage('添加网络失败: ' + addError.message, 'error');
                }
            } else {
                this.showMessage('切换网络失败: ' + error.message, 'error');
            }
        }
    }
    
    disconnect() {
        this.provider = null;
        this.signer = null;
        this.contract = null;
        this.userAddress = null;
        this.contractAddress = null;
        
        document.getElementById('walletInfo').innerHTML = '<p>请连接您的 MetaMask 钱包</p>';
        this.disableButtons();
    }
    
    async updateWalletInfo() {
        if (!this.userAddress) return;
        
        try {
            const balance = await this.provider.getBalance(this.userAddress);
            const network = await this.provider.getNetwork();
            
            document.getElementById('walletInfo').innerHTML = `
                <p><strong>地址:</strong> ${this.userAddress.slice(0, 6)}...${this.userAddress.slice(-4)}</p>
                <p><strong>余额:</strong> ${ethers.formatEther(balance)} ETH</p>
                <p><strong>网络:</strong> ${network.name} (${network.chainId})</p>
            `;
        } catch (error) {
            console.error('更新钱包信息失败:', error);
        }
    }
    
    setContractAddress(address) {
        this.contractAddress = address;
        if (address && ethers.isAddress(address) && this.signer) {
            this.contract = new ethers.Contract(address, this.contractABI, this.signer);
            this.enableButtons();
            this.updateContractStatus();
        } else {
            this.contract = null;
            this.disableButtons();
        }
    }
    
    enableButtons() {
        document.getElementById('depositBtn').disabled = false;
        document.getElementById('withdrawBtn').disabled = false;
        document.getElementById('updateThresholdBtn').disabled = false;
        document.getElementById('checkUpkeepBtn').disabled = false;
        document.getElementById('performUpkeepBtn').disabled = false;
    }
    
    disableButtons() {
        document.getElementById('depositBtn').disabled = true;
        document.getElementById('withdrawBtn').disabled = true;
        document.getElementById('updateThresholdBtn').disabled = true;
        document.getElementById('checkUpkeepBtn').disabled = true;
        document.getElementById('performUpkeepBtn').disabled = true;
    }
    
    async deposit() {
        if (!this.contract) {
            this.showMessage('请先输入有效的合约地址', 'error');
            return;
        }
        
        const amount = document.getElementById('depositAmount').value;
        if (!amount || parseFloat(amount) <= 0) {
            this.showMessage('请输入有效的存款金额', 'error');
            return;
        }
        
        try {
            this.showLoading('depositBtn', true);
            
            const tx = await this.contract.deposit({
                value: ethers.parseEther(amount)
            });
            
            this.showMessage('交易已提交，等待确认...', 'info');
            await tx.wait();
            
            this.showMessage(`成功存款 ${amount} ETH`, 'success');
            document.getElementById('depositAmount').value = '';
            
            // 更新状态
            await this.updateContractStatus();
            await this.updateWalletInfo();
            
        } catch (error) {
            console.error('存款失败:', error);
            this.showMessage('存款失败: ' + error.message, 'error');
        } finally {
            this.showLoading('depositBtn', false);
        }
    }
    
    async withdraw() {
        if (!this.contract) {
            this.showMessage('请先输入有效的合约地址', 'error');
            return;
        }
        
        try {
            this.showLoading('withdrawBtn', true);
            
            // 获取用户余额
            const userBalance = await this.contract.getUserBalance(this.userAddress);
            
            if (userBalance === 0n) {
                this.showMessage('您没有可提取的存款', 'error');
                return;
            }
            
            const tx = await this.contract.withdraw(userBalance);
            
            this.showMessage('交易已提交，等待确认...', 'info');
            await tx.wait();
            
            this.showMessage(`成功提取 ${ethers.formatEther(userBalance)} ETH`, 'success');
            
            // 更新状态
            await this.updateContractStatus();
            await this.updateWalletInfo();
            
        } catch (error) {
            console.error('提取失败:', error);
            this.showMessage('提取失败: ' + error.message, 'error');
        } finally {
            this.showLoading('withdrawBtn', false);
        }
    }
    
    async updateThreshold() {
        if (!this.contract) {
            this.showMessage('请先输入有效的合约地址', 'error');
            return;
        }
        
        const newThreshold = document.getElementById('thresholdAmount').value;
        if (!newThreshold || parseFloat(newThreshold) <= 0) {
            this.showMessage('请输入有效的阈值', 'error');
            return;
        }
        
        try {
            this.showLoading('updateThresholdBtn', true);
            
            const tx = await this.contract.updateThreshold(ethers.parseEther(newThreshold));
            
            this.showMessage('交易已提交，等待确认...', 'info');
            await tx.wait();
            
            this.showMessage(`阈值已更新为 ${newThreshold} ETH`, 'success');
            document.getElementById('thresholdAmount').value = '';
            
            // 更新状态
            await this.updateContractStatus();
            
        } catch (error) {
            console.error('更新阈值失败:', error);
            this.showMessage('更新阈值失败: ' + error.message, 'error');
        } finally {
            this.showLoading('updateThresholdBtn', false);
        }
    }
    
    async checkUpkeepStatus() {
        if (!this.contract) return;
        
        try {
            this.showLoading('checkUpkeepBtn', true);
            
            const [upkeepNeeded] = await this.contract.checkUpkeep("0x");
            const [thresholdMet, intervalMet, balanceSufficient, currentDeposits, currentThreshold, timeRemaining] = 
                await this.contract.getUpkeepStatus();
            
            // 更新自动化状态显示
            this.updateAutomationStatus({
                thresholdMet,
                intervalMet,
                balanceSufficient,
                upkeepNeeded
            });
            
            this.showMessage('Upkeep 状态已更新', 'success');
            
        } catch (error) {
            console.error('检查 Upkeep 状态失败:', error);
            this.showMessage('检查状态失败: ' + error.message, 'error');
        } finally {
            this.showLoading('checkUpkeepBtn', false);
        }
    }
    
    async performUpkeep() {
        if (!this.contract) return;
        
        try {
            this.showLoading('performUpkeepBtn', true);
            
            const tx = await this.contract.performUpkeep("0x");
            
            this.showMessage('Upkeep 交易已提交，等待确认...', 'info');
            await tx.wait();
            
            this.showMessage('Upkeep 执行成功！', 'success');
            
            // 更新状态
            await this.updateContractStatus();
            
        } catch (error) {
            console.error('执行 Upkeep 失败:', error);
            this.showMessage('执行 Upkeep 失败: ' + error.message, 'error');
        } finally {
            this.showLoading('performUpkeepBtn', false);
        }
    }
    
    async updateContractStatus() {
        if (!this.contract) return;
        
        try {
            const [
                contractBalance,
                totalDeposits,
                userBalance,
                threshold,
                owner,
                timeRemaining
            ] = await Promise.all([
                this.contract.getContractBalance(),
                this.contract.totalDeposits(),
                this.contract.getUserBalance(this.userAddress),
                this.contract.threshold(),
                this.contract.owner(),
                this.contract.getTimeUntilNextTransfer()
            ]);
            
            // 更新显示
            document.getElementById('contractBalance').textContent = ethers.formatEther(contractBalance) + ' ETH';
            document.getElementById('totalDeposits').textContent = ethers.formatEther(totalDeposits) + ' ETH';
            document.getElementById('userBalance').textContent = ethers.formatEther(userBalance) + ' ETH';
            document.getElementById('threshold').textContent = ethers.formatEther(threshold) + ' ETH';
            document.getElementById('owner').textContent = owner.slice(0, 6) + '...' + owner.slice(-4);
            
            // 格式化时间显示
            const timeRemainingNum = Number(timeRemaining);
            if (timeRemainingNum === 0) {
                document.getElementById('timeRemaining').textContent = '可立即执行';
                document.getElementById('timeRemaining').className = 'status-value status-success';
            } else {
                const hours = Math.floor(timeRemainingNum / 3600);
                const minutes = Math.floor((timeRemainingNum % 3600) / 60);
                document.getElementById('timeRemaining').textContent = `${hours}小时${minutes}分钟`;
                document.getElementById('timeRemaining').className = 'status-value';
            }
            
            // 检查是否需要执行 upkeep
            const upkeepStatusElement = document.getElementById('upkeepStatus').querySelector('.value');
            if (totalDeposits >= threshold && timeRemainingNum <= 0) {
                upkeepStatusElement.textContent = '是';
                upkeepStatusElement.className = 'value status-warning';
            } else {
                upkeepStatusElement.textContent = '否';
                upkeepStatusElement.className = 'value';
            }
            
        } catch (error) {
            console.error('更新合约状态失败:', error);
        }
    }
    
    updateAutomationStatus(status) {
        const { thresholdMet, intervalMet, balanceSufficient, upkeepNeeded } = status;
        
        // 更新各项状态
        this.updateStatusItem('thresholdStatus', thresholdMet, '阈值已达到', '阈值未达到');
        this.updateStatusItem('intervalStatus', intervalMet, '时间间隔满足', '等待时间间隔');
        this.updateStatusItem('balanceStatus', balanceSufficient, '余额充足', '余额不足');
        this.updateStatusItem('upkeepStatus', upkeepNeeded, '需要执行', '无需执行');
    }
    
    updateStatusItem(elementId, condition, activeText, inactiveText) {
        const element = document.getElementById(elementId);
        const valueElement = element.querySelector('.value');
        
        if (condition) {
            element.className = 'automation-item active';
            valueElement.textContent = activeText;
        } else {
            element.className = 'automation-item inactive';
            valueElement.textContent = inactiveText;
        }
    }
    
    showLoading(buttonId, show) {
        const button = document.getElementById(buttonId);
        if (show) {
            button.innerHTML = '<span class="loading"></span> 处理中...';
            button.disabled = true;
        } else {
            // 恢复按钮原始文本
            const buttonTexts = {
                'depositBtn': '存款',
                'withdrawBtn': '提取全部存款',
                'updateThresholdBtn': '更新阈值',
                'checkUpkeepBtn': '检查 Upkeep 状态',
                'performUpkeepBtn': '手动执行 Upkeep'
            };
            button.innerHTML = buttonTexts[buttonId] || '确定';
            button.disabled = false;
        }
    }
    
    showMessage(message, type) {
        const messageArea = document.getElementById('messageArea');
        const messageDiv = document.createElement('div');
        messageDiv.className = `alert alert-${type}`;
        messageDiv.textContent = message;
        
        messageArea.appendChild(messageDiv);
        
        // 3秒后自动移除消息
        setTimeout(() => {
            if (messageDiv.parentNode) {
                messageDiv.parentNode.removeChild(messageDiv);
            }
        }, 3000);
    }
    
    startStatusUpdater() {
        // 每30秒更新一次状态
        setInterval(() => {
            if (this.contract) {
                this.updateContractStatus();
            }
            if (this.userAddress) {
                this.updateWalletInfo();
            }
        }, 30000);
    }
}

// 初始化 DApp
document.addEventListener('DOMContentLoaded', () => {
    new AutomatedBankDApp();
});