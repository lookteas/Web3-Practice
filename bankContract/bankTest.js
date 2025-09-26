// Bank 合约测试示例
// 这个文件展示了如何与部署的 Bank 合约进行交互

// 合约 ABI（应用程序二进制接口）
const BANK_ABI = [
    {
        "inputs": [],
        "stateMutability": "nonpayable",
        "type": "constructor"
    },
    {
        "anonymous": false,
        "inputs": [
            {
                "indexed": true,
                "internalType": "address",
                "name": "depositor",
                "type": "address"
            },
            {
                "indexed": false,
                "internalType": "uint256",
                "name": "amount",
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
                "indexed": false,
                "internalType": "address[3]",
                "name": "topDepositors",
                "type": "address[3]"
            }
        ],
        "name": "TopDepositorsUpdated",
        "type": "event"
    },
    {
        "anonymous": false,
        "inputs": [
            {
                "indexed": true,
                "internalType": "address",
                "name": "admin",
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
        "inputs": [],
        "name": "admin",
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
        "inputs": [
            {
                "internalType": "uint256",
                "name": "",
                "type": "uint256"
            }
        ],
        "name": "depositors",
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
        "inputs": [
            {
                "internalType": "address",
                "name": "depositor",
                "type": "address"
            }
        ],
        "name": "getDeposit",
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
        "name": "getDepositorsCount",
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
        "name": "getTopDepositors",
        "outputs": [
            {
                "internalType": "address[3]",
                "name": "",
                "type": "address[3]"
            }
        ],
        "stateMutability": "view",
        "type": "function"
    },
    {
        "inputs": [],
        "name": "getTopDepositorsWithAmounts",
        "outputs": [
            {
                "internalType": "address[3]",
                "name": "",
                "type": "address[3]"
            },
            {
                "internalType": "uint256[3]",
                "name": "",
                "type": "uint256[3]"
            }
        ],
        "stateMutability": "view",
        "type": "function"
    },
    {
        "inputs": [
            {
                "internalType": "uint256",
                "name": "",
                "type": "uint256"
            }
        ],
        "name": "topDepositors",
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
                "internalType": "address",
                "name": "newAdmin",
                "type": "address"
            }
        ],
        "name": "transferAdmin",
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
        "inputs": [],
        "name": "withdrawAll",
        "outputs": [],
        "stateMutability": "nonpayable",
        "type": "function"
    },
    {
        "stateMutability": "payable",
        "type": "receive"
    }
];

// 使用示例（需要在浏览器环境中运行，且安装了 MetaMask）
class BankContract {
    constructor(contractAddress) {
        this.contractAddress = contractAddress;
        this.web3 = null;
        this.contract = null;
        this.currentAccount = null;
    }

    // 初始化 Web3 连接
    async init() {
        if (typeof window.ethereum !== 'undefined') {
            this.web3 = new Web3(window.ethereum);
            
            // 请求账户访问权限
            const accounts = await window.ethereum.request({
                method: 'eth_requestAccounts'
            });
            this.currentAccount = accounts[0];
            
            // 创建合约实例
            this.contract = new this.web3.eth.Contract(BANK_ABI, this.contractAddress);
            
            console.log('连接成功！当前账户:', this.currentAccount);
            return true;
        } else {
            console.error('请安装 MetaMask!');
            return false;
        }
    }

    // 存款
    async deposit(amountInEther) {
        try {
            const amountInWei = this.web3.utils.toWei(amountInEther.toString(), 'ether');
            
            const result = await this.contract.methods.deposit().send({
                from: this.currentAccount,
                value: amountInWei
            });
            
            console.log('存款成功！交易哈希:', result.transactionHash);
            return result;
        } catch (error) {
            console.error('存款失败:', error);
            throw error;
        }
    }

    // 直接发送以太币到合约地址（触发 receive 函数）
    async sendEther(amountInEther) {
        try {
            const amountInWei = this.web3.utils.toWei(amountInEther.toString(), 'ether');
            
            const result = await this.web3.eth.sendTransaction({
                from: this.currentAccount,
                to: this.contractAddress,
                value: amountInWei
            });
            
            console.log('发送以太币成功！交易哈希:', result.transactionHash);
            return result;
        } catch (error) {
            console.error('发送以太币失败:', error);
            throw error;
        }
    }

    // 查询存款余额
    async getMyDeposit() {
        try {
            const deposit = await this.contract.methods.getDeposit(this.currentAccount).call();
            const depositInEther = this.web3.utils.fromWei(deposit, 'ether');
            console.log('我的存款余额:', depositInEther, 'ETH');
            return depositInEther;
        } catch (error) {
            console.error('查询存款失败:', error);
            throw error;
        }
    }

    // 查询合约余额
    async getContractBalance() {
        try {
            const balance = await this.contract.methods.getContractBalance().call();
            const balanceInEther = this.web3.utils.fromWei(balance, 'ether');
            console.log('合约余额:', balanceInEther, 'ETH');
            return balanceInEther;
        } catch (error) {
            console.error('查询合约余额失败:', error);
            throw error;
        }
    }

    // 获取前3名存款用户
    async getTopDepositors() {
        try {
            const result = await this.contract.methods.getTopDepositorsWithAmounts().call();
            const [addresses, amounts] = result;
            
            console.log('前3名存款用户:');
            for (let i = 0; i < 3; i++) {
                if (addresses[i] !== '0x0000000000000000000000000000000000000000') {
                    const amountInEther = this.web3.utils.fromWei(amounts[i], 'ether');
                    console.log(`第${i + 1}名: ${addresses[i]} - ${amountInEther} ETH`);
                }
            }
            
            return { addresses, amounts };
        } catch (error) {
            console.error('查询前3名失败:', error);
            throw error;
        }
    }

    // 提款（仅管理员）
    async withdraw(amountInEther) {
        try {
            const amountInWei = this.web3.utils.toWei(amountInEther.toString(), 'ether');
            
            const result = await this.contract.methods.withdraw(amountInWei).send({
                from: this.currentAccount
            });
            
            console.log('提款成功！交易哈希:', result.transactionHash);
            return result;
        } catch (error) {
            console.error('提款失败:', error);
            throw error;
        }
    }

    // 提取所有资金（仅管理员）
    async withdrawAll() {
        try {
            const result = await this.contract.methods.withdrawAll().send({
                from: this.currentAccount
            });
            
            console.log('提取所有资金成功！交易哈希:', result.transactionHash);
            return result;
        } catch (error) {
            console.error('提取所有资金失败:', error);
            throw error;
        }
    }

    // 检查是否为管理员
    async isAdmin() {
        try {
            const admin = await this.contract.methods.admin().call();
            const isAdmin = admin.toLowerCase() === this.currentAccount.toLowerCase();
            console.log('是否为管理员:', isAdmin);
            return isAdmin;
        } catch (error) {
            console.error('检查管理员权限失败:', error);
            throw error;
        }
    }
}

// 导出类供其他文件使用
if (typeof module !== 'undefined' && module.exports) {
    module.exports = { BankContract, BANK_ABI };
}