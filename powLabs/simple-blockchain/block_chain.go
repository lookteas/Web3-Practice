// 最小区块链实现
// 功能：POW 证明出块（难度为 4 个前导 0），区块通过 previous_hash 串联
package main

import (
	"crypto/sha256"
	"encoding/json"
	"fmt"
	"time"
)

// Transaction 交易结构
type Transaction struct {
	Sender    string  `json:"sender"`
	Recipient string  `json:"recipient"`
	Amount    float64 `json:"amount"`
}

// Block 区块结构
type Block struct {
	Index        int           `json:"index"`
	Timestamp    int64         `json:"timestamp"`
	Transactions []Transaction `json:"transactions"`
	Proof        int64         `json:"proof"`
	PreviousHash string        `json:"previous_hash"`
}

// Blockchain 区块链结构
type Blockchain struct {
	Chain []Block `json:"chain"`
}

// NewBlockchain 创建新的区块链，包含原始区块
func NewBlockchain() *Blockchain {
	bc := &Blockchain{}
	// 创建创世区块
	genesisBlock := Block{
		Index:        0,
		Timestamp:    time.Now().Unix(),
		Transactions: []Transaction{},
		Proof:        0,
		PreviousHash: "0",
	}
	bc.Chain = append(bc.Chain, genesisBlock)
	return bc
}

// GetLastBlock 获取最后一个区块
func (bc *Blockchain) GetLastBlock() Block {
	return bc.Chain[len(bc.Chain)-1]
}

// CalculateHash 计算区块的哈希值
func (b *Block) CalculateHash() string {
	// 将区块数据序列化为 JSON 字符串
	blockData, _ := json.Marshal(b)
	hash := sha256.Sum256(blockData)
	return fmt.Sprintf("%x", hash)
}

// IsValidProof 验证 proof 是否满足 POW 条件（4 个前导 0）
func IsValidProof(block Block, proof int64) bool {
	// 创建临时区块用于验证
	tempBlock := block
	tempBlock.Proof = proof
	hash := tempBlock.CalculateHash()

	// 检查是否有 4 个前导 0
	return hash[:4] == "0000"
}

// ProofOfWork 执行工作量证明，寻找满足条件的 proof
func ProofOfWork(block Block) (int64, string, int64) {
	var proof int64 = 0
	var tried int64 = 0
	start := time.Now()

	for {
		tried++
		if IsValidProof(block, proof) {
			// 计算最终哈希
			tempBlock := block
			tempBlock.Proof = proof
			hash := tempBlock.CalculateHash()
			elapsed := time.Since(start).Seconds()
			fmt.Printf("POW 完成！耗时: %.3f 秒, 尝试次数: %d, 速度: %.0f H/s\n",
				elapsed, tried, float64(tried)/elapsed)
			return proof, hash, tried
		}
		proof++
	}
}

// AddBlock 添加新区块到区块链
func (bc *Blockchain) AddBlock(transactions []Transaction) {
	lastBlock := bc.GetLastBlock()

	// 模拟交易收集和验证时间
	fmt.Printf("正在收集和验证交易...\n")
	time.Sleep(1 * time.Second)

	// 创建新区块
	newBlock := Block{
		Index:        lastBlock.Index + 1,
		Timestamp:    time.Now().Unix(),
		Transactions: transactions,
		Proof:        0, // 将在 POW 中设置
		PreviousHash: lastBlock.CalculateHash(),
	}

	fmt.Printf("开始串联区块 #%d...\n", newBlock.Index)

	// 执行工作量证明
	proof, hash, _ := ProofOfWork(newBlock)
	newBlock.Proof = proof

	fmt.Printf("区块 #%d 串联成功！\n", newBlock.Index)
	fmt.Printf("区块哈希: %s\n", hash)
	fmt.Printf("Proof: %d\n", proof)

	// 模拟区块广播和确认时间
	fmt.Printf("正在广播区块到网络...\n")
	time.Sleep(500 * time.Millisecond)
	fmt.Printf("区块已被网络确认并添加到区块链\n")
	fmt.Println("------------------------------")

	// 添加到区块链
	bc.Chain = append(bc.Chain, newBlock)

	// 区块间隔时间，模拟真实区块链的出块间隔
	fmt.Printf("等待下一个区块...\n")
	time.Sleep(2 * time.Second)
}

// IsChainValid 验证区块链的有效性
func (bc *Blockchain) IsChainValid() bool {
	for i := 1; i < len(bc.Chain); i++ {
		currentBlock := bc.Chain[i]
		previousBlock := bc.Chain[i-1]

		// 验证当前区块的哈希
		if !IsValidProof(currentBlock, currentBlock.Proof) {
			fmt.Printf("区块 #%d 的 proof 无效\n", currentBlock.Index)
			return false
		}

		// 验证前一个区块的哈希链接
		if currentBlock.PreviousHash != previousBlock.CalculateHash() {
			fmt.Printf("区块 #%d 的 previous_hash 不匹配\n", currentBlock.Index)
			return false
		}
	}
	return true
}

// PrintBlockchain 打印区块链信息
func (bc *Blockchain) PrintBlockchain() {
	fmt.Println("=== 区块链信息 ===")
	for _, block := range bc.Chain {
		fmt.Printf("区块 #%d:\n", block.Index)
		fmt.Printf("  时间戳: %d (%s)\n", block.Timestamp, time.Unix(block.Timestamp, 0).Format("2006-01-02 15:04:05"))
		fmt.Printf("  交易数量: %d\n", len(block.Transactions))
		for j, tx := range block.Transactions {
			fmt.Printf("    交易 %d: %s -> %s (%.2f)\n", j+1, tx.Sender, tx.Recipient, tx.Amount)
		}
		fmt.Printf("  Proof: %d\n", block.Proof)
		fmt.Printf("  Previous Hash: %s\n", block.PreviousHash)
		fmt.Printf("  当前 Hash: %s\n", block.CalculateHash())
		fmt.Println()
	}
}

func main() {
	fmt.Println("=== 开始模拟最小区块链实现 ===")
	fmt.Println("POW 难度: 4 个前导 0")
	fmt.Println("模拟真实区块链的流程...")
	fmt.Println()

	//后续优化，统一调用添加区块的方法来实现，暂时没时间做
	// 创建区块链
	blockchain := NewBlockchain()
	fmt.Println("创世区块已创建")
	fmt.Printf("初始化完成，准备开始串联...\n")
	time.Sleep(1 * time.Second)
	fmt.Println()

	// 添加第一个区块（包含一些交易）
	fmt.Println("▶ 准备创建区块 #1")
	transactions1 := []Transaction{
		{Sender: "wang", Recipient: "li", Amount: 10.5},
		{Sender: "zhang", Recipient: "zhao", Amount: 5.0},
	}
	blockchain.AddBlock(transactions1)

	// 添加第二个区块
	fmt.Println("▶ 准备创建区块 #2")
	transactions2 := []Transaction{
		{Sender: "song", Recipient: "wang", Amount: 3.2},
	}
	blockchain.AddBlock(transactions2)

	// 添加第三个区块
	fmt.Println("▶ 准备创建区块 #3")
	transactions3 := []Transaction{
		{Sender: "wang", Recipient: "du", Amount: 7.8},
		{Sender: "feng", Recipient: "sun", Amount: 2.1},
	}
	blockchain.AddBlock(transactions3)

	fmt.Println("所有区块串联完成！")
	fmt.Println()

	// 打印区块链
	blockchain.PrintBlockchain()

	// 验证区块链
	fmt.Println("=== 区块链验证 ===")
	if blockchain.IsChainValid() {
		fmt.Println("ok, 区块链验证通过！")
	} else {
		fmt.Println("sorry, 区块链验证失败！")
	}

	fmt.Printf("\n区块链总长度: %d 个区块\n", len(blockchain.Chain))
}
