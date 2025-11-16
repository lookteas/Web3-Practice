import mysql from 'mysql2/promise'
import 'dotenv/config'

let pool

export async function init() {
  const host = process.env.MYSQL_HOST || 'localhost'
  const port = process.env.MYSQL_PORT ? Number(process.env.MYSQL_PORT) : 3306
  const user = process.env.MYSQL_USER || 'root'
  const password = process.env.MYSQL_PASSWORD || ''
  const database = process.env.MYSQL_DATABASE || 'viem_index'
  const baseConfig = { host, port, user, password }
  const conn = await mysql.createConnection(baseConfig)
  await conn.query(`CREATE DATABASE IF NOT EXISTS \`${database}\``)
  await conn.end()
  pool = mysql.createPool({ host, port, user, password, database, connectionLimit: 8 })
  await pool.query(
    'CREATE TABLE IF NOT EXISTS transfers (id INT AUTO_INCREMENT PRIMARY KEY, tx_hash VARCHAR(66) NOT NULL, block_number BIGINT NOT NULL, timestamp INT NOT NULL, from_addr VARCHAR(42) NOT NULL, to_addr VARCHAR(42) NOT NULL, value VARCHAR(78) NOT NULL, UNIQUE KEY unique_tx (tx_hash, from_addr, to_addr, value), KEY idx_addr (from_addr, to_addr))'
  )
  await pool.query(
    'CREATE TABLE IF NOT EXISTS index_state (id TINYINT PRIMARY KEY, last_block BIGINT)'
  )
}

export async function setLastIndexedBlock(b) {
  await pool.query(
    'INSERT INTO index_state(id, last_block) VALUES(1, ?) ON DUPLICATE KEY UPDATE last_block=VALUES(last_block)',
    [b]
  )
}

export async function getLastIndexedBlock() {
  const [rows] = await pool.query('SELECT last_block FROM index_state WHERE id=1')
  if (Array.isArray(rows) && rows.length > 0) return rows[0].last_block
  return null
}

export async function addTransfer(t) {
  await pool.query(
    'INSERT IGNORE INTO transfers(tx_hash, block_number, timestamp, from_addr, to_addr, value) VALUES(?, ?, ?, ?, ?, ?)',
    [t.txHash, t.blockNumber, t.timestamp, t.from, t.to, t.value]
  )
}

export async function getTransfers(addr, limit = 100) {
  const [rows] = await pool.query(
    'SELECT tx_hash, block_number, timestamp, from_addr, to_addr, value FROM transfers WHERE lower(from_addr)=lower(?) OR lower(to_addr)=lower(?) ORDER BY block_number DESC LIMIT ?',
    [addr, addr, limit]
  )
  return rows
}

export async function close() {
  if (pool) await pool.end()
}