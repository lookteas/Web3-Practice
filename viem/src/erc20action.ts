// src/erc20Actions.ts
import { createPublicClient, createWalletClient, custom, http, parseAbi } from 'viem'
import { sepolia } from 'viem/chains'

// Sepolia USDC 测试代币（可替换为你自己的 ERC20 地址）
export const USDC_ADDRESS = '0xD4F009Eb5b5A5C211675411aD0DED6A7966679A7' as const

// ERC20 标准 ABI（只包含我们需要的方法）
const erc20Abi = parseAbi([
  'function balanceOf(address owner) view returns (uint256)',
  'function transfer(address to, uint256 amount) returns (bool)',
  'function decimals() view returns (uint8)'
])

// 1. 查询 ERC20 余额
export async function getErc20Balance(address: `0x${string}`, tokenAddress: `0x${string}` = USDC_ADDRESS) {
  const publicClient = createPublicClient({
    chain: sepolia,
    transport: http(),
  })

  const [balance, decimals] = await Promise.all([
    publicClient.readContract({
      address: tokenAddress,
      abi: erc20Abi,
      functionName: 'balanceOf',
      args: [address],
    }),
    publicClient.readContract({
      address: tokenAddress,
      abi: erc20Abi,
      functionName: 'decimals',
    })
  ])

  const formattedBalance = Number(balance) / Math.pow(10, Number(decimals))
  return {
    raw: balance,
    formatted: formattedBalance,
    decimals: Number(decimals)
  }
}

// 2. 发送 ERC20 转账（安全：先 simulate 再发送）
export async function sendErc20Transfer(
  fromAddress: `0x${string}`,
  toAddress: `0x${string}`,
  amount: number, // 单位：代币单位（如 10 USDC）
  tokenAddress: `0x${string}` = USDC_ADDRESS
) {
  const publicClient = createPublicClient({ chain: sepolia, transport: http() })
  const walletClient = createWalletClient({ chain: sepolia, transport: custom(window.ethereum) })

  // 获取 decimals 以转换金额
  const decimals = await publicClient.readContract({
    address: tokenAddress,
    abi: erc20Abi,
    functionName: 'decimals'
  })

  const amountInWei = BigInt(Math.floor(amount * Math.pow(10, Number(decimals))))

  // ✅ 先模拟交易（避免无效交易）
  const { request } = await publicClient.simulateContract({
    address: tokenAddress,
    abi: erc20Abi,
    functionName: 'transfer',
    args: [toAddress, amountInWei],
    account: fromAddress,
  })

  // ✅ 再发送
  const hash = await walletClient.writeContract(request)
  return hash
}