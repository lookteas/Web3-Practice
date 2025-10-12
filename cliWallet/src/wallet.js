import { 
  createWalletClient, 
  createPublicClient, 
  http, 
  parseEther, 
  formatEther, 
  parseUnits,
  formatUnits,
  getContract
} from 'viem';
import { sepolia } from 'viem/chains';
import { privateKeyToAccount } from 'viem/accounts';
import { generatePrivateKey } from 'viem/accounts';

// ERC20 ABI (简化版本，包含必要的函数)
const ERC20_ABI = [
  {
    "constant": true,
    "inputs": [{"name": "_owner", "type": "address"}],
    "name": "balanceOf",
    "outputs": [{"name": "balance", "type": "uint256"}],
    "type": "function"
  },
  {
    "constant": false,
    "inputs": [
      {"name": "_to", "type": "address"},
      {"name": "_value", "type": "uint256"}
    ],
    "name": "transfer",
    "outputs": [{"name": "", "type": "bool"}],
    "type": "function"
  },
  {
    "constant": true,
    "inputs": [],
    "name": "decimals",
    "outputs": [{"name": "", "type": "uint8"}],
    "type": "function"
  },
  {
    "constant": true,
    "inputs": [],
    "name": "symbol",
    "outputs": [{"name": "", "type": "string"}],
    "type": "function"
  },
  {
    "constant": true,
    "inputs": [],
    "name": "name",
    "outputs": [{"name": "", "type": "string"}],
    "type": "function"
  }
];

export class Wallet {
  constructor(rpcUrl = 'https://sepolia.infura.io/v3/YOUR_PROJECT_ID') {
    this.rpcUrl = rpcUrl;
    this.chain = sepolia;
    
    // 创建公共客户端用于查询
    this.publicClient = createPublicClient({
      chain: this.chain,
      transport: http(this.rpcUrl)
    });
    
    this.account = null;
    this.walletClient = null;
  }

  /**
   * 生成新的私钥和账户
   * @returns {Object} 包含私钥和地址的对象
   */
  generateAccount() {
    const privateKey = generatePrivateKey();
    const account = privateKeyToAccount(privateKey);
    
    this.account = account;
    this.walletClient = createWalletClient({
      account: this.account,
      chain: this.chain,
      transport: http(this.rpcUrl)
    });

    return {
      privateKey,
      address: account.address
    };
  }

  /**
   * 从私钥导入账户
   * @param {string} privateKey - 私钥 (0x开头的十六进制字符串)
   * @returns {string} 账户地址
   */
  importAccount(privateKey) {
    try {
      this.account = privateKeyToAccount(privateKey);
      this.walletClient = createWalletClient({
        account: this.account,
        chain: this.chain,
        transport: http(this.rpcUrl)
      });
      
      return this.account.address;
    } catch (error) {
      throw new Error(`导入账户失败: ${error.message}`);
    }
  }

  /**
   * 查询 ETH 余额
   * @param {string} address - 要查询的地址
   * @returns {Promise<string>} ETH 余额
   */
  async getETHBalance(address) {
    try {
      const balance = await this.publicClient.getBalance({ 
        address: address || this.account?.address 
      });
      return formatEther(balance);
    } catch (error) {
      throw new Error(`查询 ETH 余额失败: ${error.message}`);
    }
  }

  /**
   * 查询 ERC20 代币余额
   * @param {string} tokenAddress - ERC20 代币合约地址
   * @param {string} walletAddress - 钱包地址
   * @returns {Promise<Object>} 代币信息和余额
   */
  async getERC20Balance(tokenAddress, walletAddress) {
    try {
      const address = walletAddress || this.account?.address;
      
      const contract = getContract({
        address: tokenAddress,
        abi: ERC20_ABI,
        client: this.publicClient
      });

      // 并行获取代币信息和余额
      const [balance, decimals, symbol, name] = await Promise.all([
        contract.read.balanceOf([address]),
        contract.read.decimals(),
        contract.read.symbol(),
        contract.read.name()
      ]);

      const formattedBalance = formatUnits(balance, decimals);

      return {
        name,
        symbol,
        decimals,
        balance: formattedBalance,
        rawBalance: balance.toString()
      };
    } catch (error) {
      throw new Error(`查询 ERC20 余额失败: ${error.message}`);
    }
  }

  /**
   * 构建 ERC20 转账交易 (EIP-1559)
   * @param {string} tokenAddress - ERC20 代币合约地址
   * @param {string} to - 接收地址
   * @param {string} amount - 转账数量
   * @param {number} decimals - 代币精度
   * @returns {Promise<Object>} 交易对象
   */
  async buildERC20Transaction(tokenAddress, to, amount, decimals = 18) {
    try {
      if (!this.account) {
        throw new Error('请先导入或生成账户');
      }

      // 获取当前 gas 价格信息
      const feeData = await this.publicClient.estimateFeesPerGas();
      
      // 获取 nonce
      const nonce = await this.publicClient.getTransactionCount({
        address: this.account.address
      });

      // 编码转账数据
      const transferData = encodeFunctionData({
        abi: ERC20_ABI,
        functionName: 'transfer',
        args: [to, parseUnits(amount, decimals)]
      });

      // 估算 gas limit
      const gasLimit = await this.publicClient.estimateGas({
        account: this.account,
        to: tokenAddress,
        data: transferData
      });

      const transaction = {
        to: tokenAddress,
        data: transferData,
        nonce,
        gasLimit: gasLimit + (gasLimit * 20n / 100n), // 增加 20% 的 gas buffer
        maxFeePerGas: feeData.maxFeePerGas,
        maxPriorityFeePerGas: feeData.maxPriorityFeePerGas,
        chainId: this.chain.id,
        type: 2 // EIP-1559 交易类型
      };

      return transaction;
    } catch (error) {
      throw new Error(`构建交易失败: ${error.message}`);
    }
  }

  /**
   * 签名交易
   * @param {Object} transaction - 交易对象
   * @returns {Promise<string>} 签名后的交易哈希
   */
  async signTransaction(transaction) {
    try {
      if (!this.walletClient) {
        throw new Error('请先导入或生成账户');
      }

      const signedTransaction = await this.walletClient.signTransaction(transaction);
      return signedTransaction;
    } catch (error) {
      throw new Error(`签名交易失败: ${error.message}`);
    }
  }

  /**
   * 发送已签名的交易
   * @param {string} signedTransaction - 已签名的交易
   * @returns {Promise<string>} 交易哈希
   */
  async sendSignedTransaction(signedTransaction) {
    try {
      const hash = await this.publicClient.sendRawTransaction({
        serializedTransaction: signedTransaction
      });
      return hash;
    } catch (error) {
      throw new Error(`发送交易失败: ${error.message}`);
    }
  }

  /**
   * 发送 ERC20 转账交易
   * @param {string} tokenAddress - ERC20 代币合约地址
   * @param {string} to - 接收地址
   * @param {string} amount - 转账数量
   * @param {number} decimals - 代币精度
   * @returns {Promise<string>} 交易哈希
   */
  async sendERC20Transaction(tokenAddress, to, amount, decimals = 18) {
    try {
      // 1. 构建交易
      const transaction = await this.buildERC20Transaction(tokenAddress, to, amount, decimals);
      
      // 2. 签名交易
      const signedTransaction = await this.signTransaction(transaction);
      
      // 3. 发送交易
      const hash = await this.sendSignedTransaction(signedTransaction);
      
      return hash;
    } catch (error) {
      throw new Error(`发送 ERC20 交易失败: ${error.message}`);
    }
  }

  /**
   * 等待交易确认
   * @param {string} hash - 交易哈希
   * @returns {Promise<Object>} 交易收据
   */
  async waitForTransaction(hash) {
    try {
      const receipt = await this.publicClient.waitForTransactionReceipt({
        hash,
        confirmations: 1
      });
      return receipt;
    } catch (error) {
      throw new Error(`等待交易确认失败: ${error.message}`);
    }
  }

  /**
   * 获取当前账户地址
   * @returns {string|null} 账户地址
   */
  getCurrentAddress() {
    return this.account?.address || null;
  }

  /**
   * 检查是否已连接账户
   * @returns {boolean} 是否已连接
   */
  isConnected() {
    return !!this.account;
  }
}

// 修复 encodeFunctionData 导入
import { encodeFunctionData } from 'viem';