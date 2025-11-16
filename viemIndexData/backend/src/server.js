import 'dotenv/config'
import express from 'express'
import cors from 'cors'
import { createPublicClient, http, parseAbiItem, formatUnits } from 'viem'
import { init, getTransfers, getLastIndexedBlock, setLastIndexedBlock, addTransfer } from './db.js'

const app = express()
app.use(cors())
app.use(express.json())

const rpcUrl = process.env.RPC_URL || ''
const tokenAddress = process.env.TOKEN_ADDRESS || ''
const tokenDecimals = process.env.TOKEN_DECIMALS ? Number(process.env.TOKEN_DECIMALS) : 18
const pollingIntervalMs = process.env.POLL_INTERVAL_MS ? Number(process.env.POLL_INTERVAL_MS) : 15000
const chunkSize = process.env.CHUNK_SIZE ? BigInt(process.env.CHUNK_SIZE) : 2000n
const startBlockEnv = process.env.START_BLOCK
const startBlock = startBlockEnv ? BigInt(startBlockEnv) : null

const client = rpcUrl ? createPublicClient({ transport: http(rpcUrl) }) : null
const transferEvent = parseAbiItem('event Transfer(address indexed from, address indexed to, uint256 value)')

async function getBlockTimestamp(blockNumber) {
  const block = await client.getBlock({ blockNumber })
  return Number(block.timestamp)
}

async function indexLoop() {
  if (!client || !tokenAddress) return
  const currentBlock = await client.getBlockNumber()
  let last = await getLastIndexedBlock()
  let from = last != null ? BigInt(last) + 1n : startBlock || currentBlock
  if (from > currentBlock) return
  while (from <= currentBlock) {
    const to = from + chunkSize - 1n <= currentBlock ? from + chunkSize - 1n : currentBlock
    const logs = await client.getLogs({ address: tokenAddress, event: transferEvent, fromBlock: from, toBlock: to, strict: true })
    const tsCache = new Map()
    for (const log of logs) {
      const bn = log.blockNumber
      let ts = tsCache.get(bn)
      if (ts == null) {
        ts = await getBlockTimestamp(bn)
        tsCache.set(bn, ts)
      }
      await addTransfer({ txHash: log.transactionHash, blockNumber: Number(bn), timestamp: ts, from: log.args.from, to: log.args.to, value: log.args.value.toString() })
    }
    await setLastIndexedBlock(Number(to))
    from = to + 1n
  }
}

setInterval(() => {
  indexLoop().catch(() => {})
}, pollingIntervalMs)

app.get('/api/transfers/:address', async (req, res) => {
  const addr = req.params.address
  const limit = req.query.limit ? Number(req.query.limit) : 100
  const rows = await getTransfers(addr, limit)
  const list = rows.map((r) => ({ txHash: r.tx_hash, blockNumber: r.block_number, timestamp: r.timestamp, from: r.from_addr, to: r.to_addr, value: r.value, valueFormatted: formatUnits(BigInt(r.value), tokenDecimals) }))
  res.json({ address: addr, total: list.length, data: list })
})

app.get('/api/indexing/status', async (req, res) => {
  const last = await getLastIndexedBlock()
  res.json({ lastIndexedBlock: last, tokenAddress, hasConfig: Boolean(rpcUrl && tokenAddress) })
})

await init()
const port = process.env.PORT ? Number(process.env.PORT) : 3001
app.listen(port, () => {})