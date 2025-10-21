// src/main.ts
import { connectWalletAndGetBalance } from './index'
import { getErc20Balance, sendErc20Transfer, USDC_ADDRESS } from './erc20action'
import { depositToBank, withdrawFromBank, getTokenBankBalance, TOKEN_BANK_ADDRESS } from './tokenBankActions'

let currentUserAddress: `0x${string}` | null = null

// 连接钱包
document.getElementById('connectBtn')!.onclick = async () => {
  try {
    const result = await connectWalletAndGetBalance()
    currentUserAddress = result.address

    // 同时查 USDC 余额和银行余额
    const usdc = await getErc20Balance(result.address)
    const bankBalance = await getTokenBankBalance(result.address)

    document.getElementById('result')!.innerHTML = `
      地址: ${result.address}<br>
      ETH 余额: ${result.balanceEth.toFixed(6)} ETH<br>
      USDC 余额: ${usdc.formatted.toFixed(2)}<br>
      银行余额: ${Number(bankBalance) / 1e6} USDC
    `
  } catch (error) {
    console.error(error)
    document.getElementById('result')!.innerText = '连接失败'
  }
}

// 发送 ETH（已有）
document.getElementById('sendEthBtn')!.onclick = async () => { /* ... */ }

// 发送 USDC
document.getElementById('sendUsdcBtn')!.onclick = async () => {
  if (!currentUserAddress) return alert('请先连接钱包')
  const to = (document.getElementById('usdcTo') as HTMLInputElement).value as `0x${string}`
  const amt = parseFloat((document.getElementById('usdcAmount') as HTMLInputElement).value)
  if (!to || isNaN(amt)) return alert('输入无效')
  try {
    const hash = await sendErc20Transfer(currentUserAddress, to, amt)
    alert(`USDC 转账成功！\nTx: ${hash}`)
  } catch (err) {
    alert('USDC 转账失败: ' + (err as Error).message)
  }
}

// 存款到银行
document.getElementById('depositBtn')!.onclick = async () => {
  if (!currentUserAddress) return alert('请先连接钱包')
  const amt = parseFloat((document.getElementById('depositAmount') as HTMLInputElement).value)
  if (isNaN(amt)) return alert('请输入金额')
  try {
    const hash = await depositToBank(currentUserAddress, amt)
    alert(`存款成功！\nTx: ${hash}`)
  } catch (err) {
    alert('存款失败: ' + (err as Error).message)
  }
}

// 从银行提款
document.getElementById('withdrawBtn')!.onclick = async () => {
  if (!currentUserAddress) return alert('请先连接钱包')
  const amt = parseFloat((document.getElementById('withdrawAmount') as HTMLInputElement).value)
  if (isNaN(amt)) return alert('请输入金额')
  try {
    const hash = await withdrawFromBank(currentUserAddress, amt)
    alert(`提款成功！\nTx: ${hash}`)
  } catch (err) {
    alert('提款失败: ' + (err as Error).message)
  }
}