// 🔧 配置：替换为你的多签钱包合约地址（部署后填写）
const MULTISIG_CONTRACT_ADDRESS = "0xefa1096834ba72b799a29efbb2920c4d082a0701";

// 📜 多签合约 ABI（仅包含前端需要的函数）
// 注意：submitTransaction 返回 uint256，其他函数按需声明
const MULTISIG_ABI =  [
	{
		"inputs": [
			{
				"internalType": "uint256",
				"name": "_txIndex",
				"type": "uint256"
			}
		],
		"name": "confirmTransaction",
		"outputs": [],
		"stateMutability": "nonpayable",
		"type": "function"
	},
	{
		"inputs": [
			{
				"internalType": "address[]",
				"name": "_owners",
				"type": "address[]"
			},
			{
				"internalType": "uint256",
				"name": "_required",
				"type": "uint256"
			}
		],
		"stateMutability": "nonpayable",
		"type": "constructor"
	},
	{
		"anonymous": false,
		"inputs": [
			{
				"indexed": true,
				"internalType": "uint256",
				"name": "txIndex",
				"type": "uint256"
			},
			{
				"indexed": true,
				"internalType": "address",
				"name": "owner",
				"type": "address"
			}
		],
		"name": "ConfirmTransaction",
		"type": "event"
	},
	{
		"inputs": [
			{
				"internalType": "uint256",
				"name": "_txIndex",
				"type": "uint256"
			}
		],
		"name": "executeTransaction",
		"outputs": [],
		"stateMutability": "nonpayable",
		"type": "function"
	},
	{
		"anonymous": false,
		"inputs": [
			{
				"indexed": true,
				"internalType": "uint256",
				"name": "txIndex",
				"type": "uint256"
			},
			{
				"indexed": true,
				"internalType": "address",
				"name": "to",
				"type": "address"
			},
			{
				"indexed": false,
				"internalType": "uint256",
				"name": "value",
				"type": "uint256"
			},
			{
				"indexed": false,
				"internalType": "bool",
				"name": "success",
				"type": "bool"
			}
		],
		"name": "ExecuteTransaction",
		"type": "event"
	},
	{
		"inputs": [
			{
				"internalType": "address",
				"name": "_to",
				"type": "address"
			},
			{
				"internalType": "uint256",
				"name": "_value",
				"type": "uint256"
			},
			{
				"internalType": "bytes",
				"name": "_data",
				"type": "bytes"
			}
		],
		"name": "submitTransaction",
		"outputs": [
			{
				"internalType": "uint256",
				"name": "",
				"type": "uint256"
			}
		],
		"stateMutability": "nonpayable",
		"type": "function"
	},
	{
		"anonymous": false,
		"inputs": [
			{
				"indexed": true,
				"internalType": "uint256",
				"name": "txIndex",
				"type": "uint256"
			},
			{
				"indexed": true,
				"internalType": "address",
				"name": "owner",
				"type": "address"
			},
			{
				"indexed": false,
				"internalType": "address",
				"name": "to",
				"type": "address"
			},
			{
				"indexed": false,
				"internalType": "uint256",
				"name": "value",
				"type": "uint256"
			},
			{
				"indexed": false,
				"internalType": "bytes",
				"name": "data",
				"type": "bytes"
			}
		],
		"name": "SubmitTransaction",
		"type": "event"
	},
	{
		"stateMutability": "payable",
		"type": "receive"
	},
	{
		"inputs": [
			{
				"internalType": "uint256",
				"name": "_txIndex",
				"type": "uint256"
			}
		],
		"name": "getConfirmationCount",
		"outputs": [
			{
				"internalType": "uint256",
				"name": "",
				"type": "uint256"
			}
		],
		"stateMutability": "view",
		"type": "function"
	},
	{
		"inputs": [],
		"name": "getOwners",
		"outputs": [
			{
				"internalType": "address[]",
				"name": "",
				"type": "address[]"
			}
		],
		"stateMutability": "view",
		"type": "function"
	},
	{
		"inputs": [],
		"name": "getTransactionCount",
		"outputs": [
			{
				"internalType": "uint256",
				"name": "",
				"type": "uint256"
			}
		],
		"stateMutability": "view",
		"type": "function"
	},
	{
		"inputs": [
			{
				"internalType": "uint256",
				"name": "_txIndex",
				"type": "uint256"
			},
			{
				"internalType": "address",
				"name": "_owner",
				"type": "address"
			}
		],
		"name": "isConfirmed",
		"outputs": [
			{
				"internalType": "bool",
				"name": "",
				"type": "bool"
			}
		],
		"stateMutability": "view",
		"type": "function"
	},
	{
		"inputs": [
			{
				"internalType": "address",
				"name": "",
				"type": "address"
			}
		],
		"name": "isOwner",
		"outputs": [
			{
				"internalType": "bool",
				"name": "",
				"type": "bool"
			}
		],
		"stateMutability": "view",
		"type": "function"
	},
	{
		"inputs": [
			{
				"internalType": "uint256",
				"name": "",
				"type": "uint256"
			}
		],
		"name": "owners",
		"outputs": [
			{
				"internalType": "address",
				"name": "",
				"type": "address"
			}
		],
		"stateMutability": "view",
		"type": "function"
	},
	{
		"inputs": [],
		"name": "required",
		"outputs": [
			{
				"internalType": "uint256",
				"name": "",
				"type": "uint256"
			}
		],
		"stateMutability": "view",
		"type": "function"
	},
	{
		"inputs": [
			{
				"internalType": "bytes32",
				"name": "",
				"type": "bytes32"
			}
		],
		"name": "transactionExists",
		"outputs": [
			{
				"internalType": "bool",
				"name": "",
				"type": "bool"
			}
		],
		"stateMutability": "view",
		"type": "function"
	},
	{
		"inputs": [
			{
				"internalType": "uint256",
				"name": "",
				"type": "uint256"
			}
		],
		"name": "transactions",
		"outputs": [
			{
				"internalType": "address",
				"name": "to",
				"type": "address"
			},
			{
				"internalType": "uint256",
				"name": "value",
				"type": "uint256"
			},
			{
				"internalType": "bytes",
				"name": "data",
				"type": "bytes"
			},
			{
				"internalType": "bool",
				"name": "executed",
				"type": "bool"
			},
			{
				"internalType": "uint256",
				"name": "confirmationCount",
				"type": "uint256"
			}
		],
		"stateMutability": "view",
		"type": "function"
	}
];

// 🌐 全局变量：Provider、Signer 和合约实例
let provider;
let signer;
let multisigContract;

// ==============================
// 1️⃣ 连接钱包（MetaMask）
// ==============================
document.getElementById("connect").addEventListener("click", async () => {
  // 检查是否安装了 MetaMask
  if (typeof window.ethereum === "undefined") {
    alert("⚠️ 请安装 MetaMask 钱包插件！");
    return;
  }

  try {
    // 请求用户授权连接账户（弹出 MetaMask 确认框）
    await window.ethereum.request({ method: "eth_requestAccounts" });

    // 创建 ethers.js v6 的 Provider（浏览器注入的 Ethereum provider）
    provider = new ethers.BrowserProvider(window.ethereum);

    // 获取当前选中的账户作为 Signer（用于签名交易）
    signer = await provider.getSigner();

    // 创建多签合约实例：地址 + ABI + Signer
    multisigContract = new ethers.Contract(
      MULTISIG_CONTRACT_ADDRESS,
      MULTISIG_ABI,
      signer
    );

    // 显示连接成功的地址
    const address = await signer.getAddress();
    document.getElementById("status").innerText = `✅ 已连接钱包: ${address}`;
    document.getElementById("result").innerText = "";
  } catch (error) {
    console.error("连接钱包失败:", error);
    document.getElementById("result").innerText = "❌ 连接失败，请检查 MetaMask 并重试。";
  }
});

// ==============================
// 2️⃣ 提交新交易（示例：ERC20 transfer）
// ==============================
document.getElementById("submitTx").addEventListener("click", async () => {
  // 检查是否已连接钱包
  if (!multisigContract) {
    document.getElementById("result").innerText = "❌ 请先点击「连接钱包」！";
    return;
  }

  try {
    // 获取用户输入
    const targetAddr = document.getElementById("targetAddr").value.trim();
    const recipient = document.getElementById("recipient").value.trim();
    const amountStr = document.getElementById("tokenAmount").value.trim();

    // 校验输入格式
    if (!ethers.isAddress(targetAddr)) {
      document.getElementById("result").innerText = "❌ 目标合约地址格式错误！";
      return;
    }
    if (!ethers.isAddress(recipient)) {
      document.getElementById("result").innerText = "❌ 接收者地址格式错误！";
      return;
    }
    if (!amountStr || isNaN(amountStr)) {
      document.getElementById("result").innerText = "❌ 请输入有效的代币数量！";
      return;
    }

    // 将代币数量转换为 BigNumber（假设 18 位小数）
    // 如果是 6 位小数的 USDT，应使用 ethers.parseUnits(amountStr, 6)
    const amount = ethers.parseUnits(amountStr, 18);

    // 🔑 核心：使用 Interface 编码函数调用数据（data 字段）
    // 这里以 ERC20 的 transfer(address,uint256) 为例
    const erc20Interface = new ethers.Interface([
      "function transfer(address to, uint256 amount) returns (bool)"
    ]);
    const data = erc20Interface.encodeFunctionData("transfer", [recipient, amount]);

    // 调用多签合约的 submitTransaction 方法
    // 注意：_value = 0n（因为 ERC20 不需要发送 ETH）
    const txResponse = await multisigContract.submitTransaction(targetAddr, 0n, data);

    // 等待交易上链（获取回执）
    const txReceipt = await txResponse.wait();

    // 从 SubmitTransaction 事件中提取 txIndex（第一个 indexed 参数）
    const txIndex = txReceipt.logs[0].args.txIndex;

    document.getElementById("result").innerText = 
      `✅ 交易提交成功！交易索引为: ${txIndex}\n` +
      `📌 请将此索引告知其他所有者进行确认。\n` +
      `⚠️ 相同内容的交易无法重复提交（已启用防重放）。`;
  } catch (error) {
    console.error("提交交易失败:", error);
    // ethers v6 推荐使用 error.shortMessage 获取简洁错误
    const errorMsg = error.shortMessage || error.message || "未知错误";
    document.getElementById("result").innerText = `❌ 提交失败: ${errorMsg}`;
  }
});

// ==============================
// 3️⃣ 确认交易（由其他所有者操作）
// ==============================
document.getElementById("confirmTx").addEventListener("click", async () => {
  if (!multisigContract) {
    document.getElementById("result").innerText = "❌ 请先连接钱包！";
    return;
  }

  try {
    // 获取用户输入的交易索引，并转换为 BigInt（ethers v6 要求）
    const txIndexInput = document.getElementById("txIndex").value;
    const txIndex = BigInt(txIndexInput);

    // 调用 confirmTransaction
    const txResponse = await multisigContract.confirmTransaction(txIndex);
    await txResponse.wait(); // 等待上链

    document.getElementById("result").innerText = `✅ 已成功确认交易 #${txIndex}！`;
  } catch (error) {
    console.error("确认交易失败:", error);
    const errorMsg = error.shortMessage || error.message || "未知错误";
    document.getElementById("result").innerText = `❌ 确认失败: ${errorMsg}`;
  }
});

// ==============================
// 4️⃣ 执行交易（满足门槛后，任何人可执行）
// ==============================
document.getElementById("executeTx").addEventListener("click", async () => {
  if (!multisigContract) {
    document.getElementById("result").innerText = "❌ 请先连接钱包！";
    return;
  }

  try {
    const txIndexInput = document.getElementById("txIndex").value;
    const txIndex = BigInt(txIndexInput);

    // 【可选】先检查确认数是否足够（提升用户体验）
    const currentConfirmations = await multisigContract.getConfirmationCount(txIndex);
    const requiredConfirmations = await multisigContract.required();

    if (currentConfirmations < requiredConfirmations) {
      document.getElementById("result").innerText = 
        `⚠️ 确认数不足！当前 ${currentConfirmations} / ${requiredConfirmations}，无法执行。`;
      return;
    }

    // 执行交易（注意：此函数无权限限制，任何人都能调用）
    const txResponse = await multisigContract.executeTransaction(txIndex);
    await txResponse.wait();

    document.getElementById("result").innerText = `✅ 交易 #${txIndex} 已成功执行！`;
  } catch (error) {
    console.error("执行交易失败:", error);
    const errorMsg = error.shortMessage || error.message || "未知错误";
    document.getElementById("result").innerText = `❌ 执行失败: ${errorMsg}`;
  }
});