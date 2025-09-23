



# powLabs

本目录包含两个独立的 Go 文件：
- pow_sha256：工作量证明（PoW）- 使用 SHA-256 寻找满足前导若干个 0 的哈希
- rsa_sign_verify：RSA 非对称加密：生成密钥对 + PoW + 签名 + 验签

## 运行前准备
- 已安装 Go 环境（建议 Go 1.20+）
- 进入本目录后运行示例命令，或从仓库根目录使用 `go -C` 指定工作目录

---

## 1) pow_sha256：PoW 演示

![](/powLabs/image/1.png)

位置：`./pow_sha256/pow_sha256.go`

功能：
- 对输入字符串（昵称 + nonce）做 SHA-256 哈希
- 依次寻找满足“前导 4 个 0”和“前导 5 个 0”的哈希
- 输出命中的 nonce、哈希值、耗时以及计算速度（H/s）

命令行参数：
- `-nickname`（必填）：你的昵称
- `-start`（可选，默认 0）：起始 nonce（便于续算或调试）

示例（在本目录 powLabs 下执行）：
```
# 进入模块根目录（如尚未进入）
cd powLabs

# 运行 PoW 演示
go run ./pow_sha256 -nickname "Alice"
# 可选：指定起始 nonce
# go run ./pow_sha256 -nickname "Alice" -start 1000000
```

从仓库根目录执行（可选）：
```
go -C ./powLabs run ./pow_sha256 -nickname "Alice"
```



![](/powLabs/image/2.gif)

---

## 2) rsa_sign_verify：RSA 签名/验签 + PoW
位置：`./rsa_sign_verify/rsa_sign_verify.go`

流程：
1. 生成 RSA 公私钥对（默认 2048 位）
2. 执行 PoW：寻找昵称+nonce 的 SHA-256，满足“前导 N 个 0”（N 可配置）
3. 对消息摘要（SHA-256）进行 PKCS#1 v1.5 签名
4. 使用公钥验证签名

命令行参数：
- `-nickname`（必填）：你的昵称
- `-zeros`（可选，默认 1）：PoW 难度，即需要的前导 0 个数（如 4、5）
- `-start`（可选，默认 0）：起始 nonce
- `-bits`（可选，默认 2048）：RSA 密钥位数

示例（在本目录 powLabs 下执行）：
```
# 进入模块根目录（如尚未进入）
cd powLabs

# 运行 RSA + PoW 演示（5 个前导 0）
go run ./rsa_sign_verify -nickname "Alice" -zeros 5
# 可选：指定起始 nonce 或调整密钥位数
# go run ./rsa_sign_verify -nickname "Alice" -zeros 4 -start 10000 -bits 2048
```

从仓库根目录执行（可选）：
```
go -C ./powLabs run ./rsa_sign_verify -nickname "Alice" -zeros 5
```

![](/powLabs/image/3.png)





## 常见问题
- 提示“找不到模块”或类似错误：请确认当前工作目录在 `powLabs`，或使用 `go -C ./powLabs ...` 运行。
- 计算较慢：提高 `-start` 仅影响起点；若提高 `-zeros`（难度），计算时间会显著增加。
- 本项目仅使用标准库，无第三方依赖；`go.mod` 的 module 名称当前为 `powLabs`。