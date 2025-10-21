import { createPublicClient, createWalletClient, custom, http } from 'viem'
import { sepolia } from 'viem/chains'

// 1. 创建 PublicClient（用于读取链上数据）
const publicClient = createPublicClient({
  chain: sepolia,
  transport: http(), // 使用公共 RPC（viem 内置 Infura）
})

// 2. 检查是否在浏览器环境
if (typeof window === 'undefined') {
  throw new Error('此脚本必须在浏览器中运行（需要 window.ethereum）')
}


// 3. 连接钱包并获取余额
export async function connectWalletAndGetBalance() {
  try {
    // 请求用户授权连接钱包
    const [address] = await (window.ethereum as any).request({
      method: 'eth_requestAccounts',
    })

    if (!address) throw new Error('用户拒绝连接钱包')

    console.log('✅ 钱包地址:', address)

    // 4. 创建 WalletClient（用于签名，这里仅用于确认账户）
    const walletClient = createWalletClient({
      chain: sepolia,
      transport: custom(window.ethereum),
    })

    // 5. 查询 ETH 余额（单位：wei）
    const balanceWei = await publicClient.getBalance({ address })
    const balanceEth = Number(balanceWei) / 1e18

    console.log(`💰 Sepolia ETH 余额: ${balanceEth.toFixed(6)} ETH`)

    return { address, balanceEth, balanceWei }
  } catch (error: any) {
    console.error('❌ 连接或查询失败:', error.message || error)
    throw error
  }
}