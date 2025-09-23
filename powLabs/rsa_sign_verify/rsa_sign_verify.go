// Program RSA Demo: 使用 Go 实践 RSA 非对称加密签名/验证。
// 流程：
// 1) 生成 RSA 公私钥对（默认 2048 位）
// 2) 进行 PoW：昵称+nonce 做 SHA-256，直到满足可配置的前缀 N 个 0 的哈希（N 通过 -zeros 指定，默认 1）
// 3) 使用私钥对消息的 SHA-256 摘要进行 PKCS#1 v1.5 签名
// 4) 使用公钥验证签名
package main

import (
	"crypto"
	"crypto/rand"
	"crypto/rsa"
	"crypto/sha256"
	"crypto/x509"
	"encoding/base64"
	"encoding/pem"
	"flag"
	"fmt"
	"time"
)

// sha256Hex 返回字符串 s 的 SHA-256 十六进制表示。
func sha256Hex(s string) string {
	sum := sha256.Sum256([]byte(s))
	return fmt.Sprintf("%x", sum)
}

// countLeadingZeroHex 统计十六进制字符串 hex 的前导 '0' 个数。
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

// mineWithZeros 寻找满足 SHA-256 哈希前导N个 '0' 的昵称+nonce。
// 返回：命中的 nonce、命中哈希、尝试次数、耗时（秒）。
func mineWithZeros(nickname string, startNonce uint64, zeros int) (foundNonce uint64, hash string, tried uint64, elapsedSec float64) {
	start := time.Now()
	var nonce = startNonce
	for {
		content := fmt.Sprintf("%s+%d", nickname, nonce)
		h := sha256Hex(content)
		tried++
		if countLeadingZeroHex(h) >= zeros {
			return nonce, h, tried, time.Since(start).Seconds()
		}
		nonce++
	}
}

func main() {
	var nickname string   // 用户昵称（必填）
	var startNonce uint64 // 起始 nonce（可选）
	var bits int          // RSA 密钥长度（位数）
	var zeros int         // 需要的前导 0 的个数（PoW 难度）

	flag.StringVar(&nickname, "nickname", "", "你的昵称（必填）")
	flag.Uint64Var(&startNonce, "start", 0, "起始 nonce（默认 0）")
	flag.IntVar(&bits, "bits", 2048, "RSA 密钥位数（默认 2048）")
	flag.IntVar(&zeros, "zeros", 1, "需要的前导 0 的个数（默认 1，例如 4 或 5）")
	flag.Parse()

	if nickname == "" {
		fmt.Println("请使用 -nickname 指定你的昵称，例如：go run ./rsa_demo -nickname Alice -zeros 4")
		return
	}
	if zeros < 1 { // 合理性校验，至少需要 1 个前导 0
		zeros = 1
	}

	// 1) 生成 RSA 公私钥对
	fmt.Printf("正在生成 RSA 私钥（%d 位）...\n", bits)
	priv, err := rsa.GenerateKey(rand.Reader, bits)
	if err != nil {
		panic(err)
	}
	pub := &priv.PublicKey
	fmt.Println("RSA 密钥生成完成。")

	// 输出 PEM（可选，仅预览前 120 字符）
	privDER := x509.MarshalPKCS1PrivateKey(priv)
	privPEM := pem.EncodeToMemory(&pem.Block{Type: "RSA PRIVATE KEY", Bytes: privDER})
	pubDER := x509.MarshalPKCS1PublicKey(pub)
	pubPEM := pem.EncodeToMemory(&pem.Block{Type: "RSA PUBLIC KEY", Bytes: pubDER})
	fmt.Println("私钥 PEM（截断预览）：")
	fmt.Println(string(privPEM[:min(len(privPEM), 120)]), "...")
	fmt.Println("公钥 PEM（截断预览）：")
	fmt.Println(string(pubPEM[:min(len(pubPEM), 120)]), "...")

	// 2) PoW：寻找 zeros 个 0 开头的哈希
	fmt.Printf("开始计算：目标为前缀 %d 个 0\n", zeros)
	nonce, hashHex, tried, elapsed := mineWithZeros(nickname, startNonce, zeros)
	speed := float64(tried) / elapsed
	content := fmt.Sprintf("%s+%d", nickname, nonce)
	fmt.Println("PoW 命中：")
	fmt.Printf("耗时：%.3f 秒\n", elapsed)
	fmt.Printf("尝试次数：%d，速度：%.0f H/s\n", tried, speed)
	fmt.Printf("Hash 的内容：%s\n", content)
	fmt.Printf("Hash 值：%s\n", hashHex)

	// 3) 私钥签名（对消息的 SHA-256 摘要进行 PKCS#1 v1.5 签名）
	digest := sha256.Sum256([]byte(content))
	sig, err := rsa.SignPKCS1v15(rand.Reader, priv, crypto.SHA256, digest[:])
	if err != nil {
		panic(err)
	}
	fmt.Println("签名（Base64）:")
	fmt.Println(base64.StdEncoding.EncodeToString(sig))

	// 4) 公钥验证签名
	if err := rsa.VerifyPKCS1v15(pub, crypto.SHA256, digest[:], sig); err != nil {
		fmt.Println("验证失败：", err)
	} else {
		fmt.Println("验证成功：签名与消息匹配。")
	}
}

// min 返回两者中的较小值。
func min(a, b int) int {
	if a < b {
		return a
	}
	return b
}
