package main

import (
	"crypto/sha256"
	"flag"
	"fmt"
	"time"
)

// sha256Hex 计算输入字符串 s 的 SHA-256，并返回其小写十六进制字符串表示。
func sha256Hex(s string) string {
	sum := sha256.Sum256([]byte(s))
	return fmt.Sprintf("%x", sum)
}

// countLeadingZeroHex 统计十六进制字符串 hex 的前导 '0' 字符个数。
// 例如："0001ab..." 的返回值为 3
func countLeadingZeroHex(hex string) int {
	n := 0
	for i := 0; i < len(hex); i++ {
		if hex[i] == '0' {
			n++
		} else {
			break
		}
	}
	return n
}

// mine 尝试寻找满足“前缀 targetZeros 个 0”的 SHA-256(昵称+nonce) 的解。
// 参数：
//   - nickname: 用户昵称，用于参与哈希输入
//   - targetZeros: 目标前导 0 的个数（例如 4 或 5）
//   - startNonce: 起始 nonce 值（默认 0）
//
// 返回：
//   - foundNonce: 满足条件的 nonce 值
//   - hash: 对应的哈希（十六进制字符串）
//   - tried: 尝试次数（包含命中那一次）
//   - elapsedSec: 总耗时（秒）
func mine(nickname string, targetZeros int, startNonce uint64) (foundNonce uint64, hash string, tried uint64, elapsedSec float64) {
	start := time.Now()    // 记录开始时间
	var nonce = startNonce // 当前尝试的 nonce
	for {
		content := fmt.Sprintf("%s+%d", nickname, nonce) // 输入内容：昵称 + nonce
		h := sha256Hex(content)                          // 计算 SHA-256 哈希
		tried++                                          // 尝试次数 +1
		if countLeadingZeroHex(h) >= targetZeros {       // 达到目标：前缀 0 的个数满足条件
			return nonce, h, tried, time.Since(start).Seconds()
		}
		nonce++ // 继续尝试下一个 nonce
	}
}

func main() {
	flag.Usage = func() {
		fmt.Println("用法：go run . -nickname <昵称> [-start <起始 nonce>]")
		flag.PrintDefaults()
	}
	var nickname string   // 用户昵称，用于参与哈希的输入
	var startNonce uint64 // 起始 nonce（默认 0）
	flag.StringVar(&nickname, "nickname", "", "你的昵称（必填）")
	flag.Uint64Var(&startNonce, "start", 0, "起始 nonce（默认 0）")
	flag.Parse()

	// 基本校验：昵称为必填项
	if nickname == "" {
		fmt.Println("请使用 -nickname 指定你的昵称，例如：go run . -nickname Alice")
		return
	}

	// 依次计算目标为 4 个 0 和 5 个 0 的哈希值
	for _, target := range []int{4, 5} {
		fmt.Printf("开始计算：目标为前缀 %d 个 0\n", target)
		nonce, hash, tried, elapsed := mine(nickname, target, startNonce)
		speed := float64(tried) / elapsed // 计算速度：每秒哈希次数（H/s）
		fmt.Printf("满足 %d 个 0 的哈希值：\n", target)
		fmt.Printf("耗时：%.3f 秒\n", elapsed)
		fmt.Printf("Hash 的内容：%s+%d\n", nickname, nonce)
		fmt.Printf("Hash 值：%s\n", hash)
		fmt.Printf("尝试次数：%d，速度：%.0f H/s\n", tried, speed)
		fmt.Println("------------------------------")
	}
}
