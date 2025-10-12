import { Wallet } from '../src/wallet.js';
import dotenv from 'dotenv';

// 加载环境变量
dotenv.config();

async function example() {
  // 初始化钱包
  const wallet = new Wallet(process.env.SEPOLIA_RPC_URL);
  
  console.log('🚀 Web3 钱包使用示例\n');
  
  try {
    // 1. 生成新账户
    console.log('1. 生成新账户...');
    const { privateKey, address } = wallet.generateAccount();
    console.log(`   地址: ${address}`);
    console.log(`   私钥: ${privateKey}\n`);
    
    // 2. 查询 ETH 余额
    console.log('2. 查询 ETH 余额...');
    const ethBalance = await wallet.getETHBalance(address);
    console.log(`   ETH 余额: ${ethBalance} ETH\n`);
    
    // 3. 查询 ERC20 代币余额（示例代币地址）
    console.log('3. 查询 ERC20 代币余额...');
    const testTokenAddress = '0x779877A7B0D9E8603169DdbD7836e478b4624789'; // LINK on Sepolia
    
    try {
      const tokenInfo = await wallet.getERC20Balance(testTokenAddress, address);
      console.log(`   代币: ${tokenInfo.name} (${tokenInfo.symbol})`);
      console.log(`   余额: ${tokenInfo.balance} ${tokenInfo.symbol}\n`);
    } catch (error) {
      console.log(`   查询代币余额失败: ${error.message}\n`);
    }
    
    // 4. 构建 ERC20 转账交易（不发送）
    console.log('4. 构建 ERC20 转账交易...');
    try {
      const transaction = await wallet.buildERC20Transaction(
        testTokenAddress,
        '0x742d35Cc6634C0532925a3b8D400e5e5c8c8b8b8', // 示例接收地址
        '0.1', // 转账数量
        18 // 代币精度
      );
      
      console.log('   交易构建成功:');
      console.log(`   - 目标合约: ${transaction.to}`);
      console.log(`   - Gas Limit: ${transaction.gasLimit}`);
      console.log(`   - Max Fee Per Gas: ${transaction.maxFeePerGas}`);
      console.log(`   - Nonce: ${transaction.nonce}\n`);
      
      // 5. 签名交易（不发送）
      console.log('5. 签名交易...');
      const signedTransaction = await wallet.signTransaction(transaction);
      console.log(`   签名成功，交易数据长度: ${signedTransaction.length} 字符\n`);
      
    } catch (error) {
      console.log(`   构建交易失败: ${error.message}\n`);
    }
    
    console.log('✅ 示例执行完成！');
    console.log('\n💡 提示:');
    console.log('   - 要发送真实交易，请确保账户有足够的 ETH 支付 gas 费用');
    console.log('   - 可以从 Sepolia 水龙头获取测试 ETH: https://sepoliafaucet.com/');
    console.log('   - 使用 npm start 启动交互式钱包界面');
    
  } catch (error) {
    console.error(`❌ 示例执行失败: ${error.message}`);
  }
}

// 运行示例
example().catch(console.error);