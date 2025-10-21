// src/tokenBankActions.ts
import { createPublicClient, createWalletClient, custom, http, parseAbi } from 'viem'
import { sepolia } from 'viem/chains'

// 替换为你的 TokenBankV2 合约地址（部署在 Sepolia 上）
export const TOKEN_BANK_ADDRESS = '0x520016837658BF78Fc8C6c6df5f099a001795A00' as const

const tokenBankAbi = parseAbi([
  'function deposit(uint256 amount) external',
  'function withdraw(uint256 amount) external',
  'function balanceOf(address user) view returns (uint256)',
  'function token() view returns (address)' // 假设合约持有一个 ERC20
])

// 1. 查询用户在银行中的余额
export async function getTokenBankBalance(user: `0x${string}`) {
  const publicClient = createPublicClient({ chain: sepolia, transport: http() })
  const balance = await publicClient.readContract({
    address: TOKEN_BANK_ADDRESS,
    abi: tokenBankAbi,
    functionName: 'balanceOf',
    args: [user]
  })
  return balance
}

// 2. 存款（需先 approve TokenBank 合约）
export async function depositToBank(
  user: `0x${string}`,
  amount: number // 单位：代币单位（如 10 USDC）
) {
  const publicClient = createPublicClient({ chain: sepolia, transport: http() })
  const walletClient = createWalletClient({ chain: sepolia, transport: custom(window.ethereum) })

  // 获取银行使用的 ERC20 地址
  const tokenAddress = await publicClient.readContract({
    address: TOKEN_BANK_ADDRESS,
    abi: tokenBankAbi,
    functionName: 'token'
  })

  // 获取 decimals
  const decimals = await publicClient.readContract({
    address: tokenAddress,
    abi: ['function decimals() view returns (uint8)'],
    functionName: 'decimals'
  })

  const amountInWei = BigInt(Math.floor(amount * Math.pow(10, Number(decimals))))

  //  模拟并发送 deposit
  const { request } = await publicClient.simulateContract({
    address: TOKEN_BANK_ADDRESS,
    abi: tokenBankAbi,
    functionName: 'deposit',
    args: [amountInWei],
    account: user
  })

  const hash = await walletClient.writeContract(request)
  return hash
}

// 3. 提款
export async function withdrawFromBank(user: `0x${string}`, amount: number) {
  const publicClient = createPublicClient({ chain: sepolia, transport: http() })
  const walletClient = createWalletClient({ chain: sepolia, transport: custom(window.ethereum) })

  const tokenAddress = await publicClient.readContract({
    address: TOKEN_BANK_ADDRESS,
    abi: tokenBankAbi,
    functionName: 'token'
  })

  const decimals = await publicClient.readContract({
    address: tokenAddress,
    abi: ['function decimals() view returns (uint8)'],
    functionName: 'decimals'
  })

  const amountInWei = BigInt(Math.floor(amount * Math.pow(10, Number(decimals))))

  const { request } = await publicClient.simulateContract({
    address: TOKEN_BANK_ADDRESS,
    abi: tokenBankAbi,
    functionName: 'withdraw',
    args: [amountInWei],
    account: user
  })

  const hash = await walletClient.writeContract(request)
  return hash
}