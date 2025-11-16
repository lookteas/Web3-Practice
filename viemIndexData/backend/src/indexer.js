import 'dotenv/config'
import { createPublicClient, http, parseAbiItem } from 'viem'
import { init, addTransfer, getLastIndexedBlock, setLastIndexedBlock } from './db.js'

const rpcUrl = process.env.RPC_URL || ''
const tokenAddress = process.env.TOKEN_ADDRESS || ''
const startBlockEnv = process.env.START_BLOCK
const chunkSizeEnv = process.env.CHUNK_SIZE

const chunkSize = chunkSizeEnv ? BigInt(chunkSizeEnv) : 2000n
const startBlock = startBlockEnv ? BigInt(startBlockEnv) : null

if (!rpcUrl) {
  console.error('Missing RPC_URL')
  process.exit(1)
}

if (!tokenAddress) {
  console.error('Missing TOKEN_ADDRESS')
  process.exit(1)
}

const client = createPublicClient({ transport: http(rpcUrl) })

const transferEvent = parseAbiItem(
  'event Transfer(address indexed from, address indexed to, uint256 value)'
)

async function getBlockTimestamp(blockNumber) {
  const block = await client.getBlock({ blockNumber })
  return Number(block.timestamp)
}

async function runOnce() {
  const currentBlock = await client.getBlockNumber()
  let last = await getLastIndexedBlock()
  let from = last != null ? BigInt(last) + 1n : startBlock || currentBlock
  if (from > currentBlock) return
  while (from <= currentBlock) {
    const to = from + chunkSize - 1n <= currentBlock ? from + chunkSize - 1n : currentBlock
    const logs = await client.getLogs({
      address: tokenAddress,
      event: transferEvent,
      fromBlock: from,
      toBlock: to,
      strict: true
    })
    const tsCache = new Map()
    for (const log of logs) {
      const bn = log.blockNumber
      let ts = tsCache.get(bn)
      if (ts == null) {
        ts = await getBlockTimestamp(bn)
        tsCache.set(bn, ts)
      }
      await addTransfer({
        txHash: log.transactionHash,
        blockNumber: Number(bn),
        timestamp: ts,
        from: log.args.from,
        to: log.args.to,
        value: log.args.value.toString()
      })
    }
    await setLastIndexedBlock(Number(to))
    from = to + 1n
  }
}

await init()
runOnce()
  .then(() => process.exit(0))
  .catch((e) => {
    console.error(e)
    process.exit(1)
  })