// readLocks.js
import { createPublicClient, http, keccak256, toBytes, hexToBigInt, hexToNumber, pad } from 'viem';
import { sepolia } from 'viem/chains';
import dotenv from 'dotenv';

// 加载环境变量
dotenv.config();

// 从环境变量读取配置
const CONTRACT_ADDRESS = process.env.CONTRACT_ADDRESS;
const RPC_URL = process.env.RPC_URL;

// 验证必要的环境变量
if (!CONTRACT_ADDRESS) {
  throw new Error('CONTRACT_ADDRESS 环境变量未设置，请在 .env 文件中配置');
}

if (!RPC_URL) {
  throw new Error('RPC_URL 环境变量未设置，请在 .env 文件中配置');
}

const client = createPublicClient({
  chain: sepolia,
  transport: http(RPC_URL),
});

// 计算动态数组的存储槽位置
function getArrayElementSlot(arraySlot, index, elementSize = 3n) {
  // 对于动态数组，数据存储在 keccak256(slot) 开始的位置
  const baseSlot = BigInt(keccak256(pad(toBytes(arraySlot))));
  return baseSlot + BigInt(index) * elementSize;
}

async function readLocks() {
  try {
    // _locks 是第 0 个状态变量（动态数组）
    const arraySlot = 0n;
    
    // 读取动态数组长度（存储在 slot 0）
    const lengthHex = await client.getStorageAt({
      address: CONTRACT_ADDRESS,
      slot: arraySlot,
    });
    
    const length = hexToBigInt(lengthHex || '0x0');
    console.log(`Array length: ${length}`);
    
    if (length === 0n) {
      console.log('No locks found');
      return;
    }

    // 读取所有锁数据
    for (let i = 0; i < Number(length); i++) {
      // 每个 Lock 结构体占用 3 个存储槽
      const baseSlot = getArrayElementSlot(arraySlot, i, 3n);
      
      // 读取 user (address) - 第一个字段
      const userHex = await client.getStorageAt({
        address: CONTRACT_ADDRESS,
        slot: baseSlot,
      });
      
      // 正确提取地址（地址是右对齐的20字节）
      let user = '0x';
      if (userHex) {
        // 取最后20字节（40个字符）
        user = '0x' + userHex.slice(-40).toLowerCase();
      }
      
      // 读取 startTime (uint64) - 第二个字段
      const startTimeHex = await client.getStorageAt({
        address: CONTRACT_ADDRESS,
        slot: baseSlot + 1n,
      });
      const startTime = startTimeHex ? hexToNumber(startTimeHex) : 0;
      
      // 读取 amount (uint256) - 第三个字段
      const amountHex = await client.getStorageAt({
        address: CONTRACT_ADDRESS,
        slot: baseSlot + 2n,
      });
      const amount = amountHex ? hexToBigInt(amountHex) : 0n;
      
      console.log(`locks[${i}]: user: ${user}, startTime: ${startTime}, amount: ${amount}`);
    }
    
  } catch (error) {
    console.error('Error reading locks:', error);
  }
}

readLocks().catch(console.error);