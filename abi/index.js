// 合约 ABI（只包含需要的函数）
const contractABI = [
	{
		"inputs": [
			{
				"internalType": "bytes",
				"name": "data",
				"type": "bytes"
			}
		],
		"name": "decodeMultiple",
		"outputs": [
			{
				"internalType": "uint256",
				"name": "",
				"type": "uint256"
			},
			{
				"internalType": "string",
				"name": "",
				"type": "string"
			}
		],
		"stateMutability": "pure",
		"type": "function"
	},
	{
		"inputs": [
			{
				"internalType": "bytes",
				"name": "data",
				"type": "bytes"
			}
		],
		"name": "decodeUint",
		"outputs": [
			{
				"internalType": "uint256",
				"name": "",
				"type": "uint256"
			}
		],
		"stateMutability": "pure",
		"type": "function"
	},
	{
		"inputs": [
			{
				"internalType": "uint256",
				"name": "num",
				"type": "uint256"
			},
			{
				"internalType": "string",
				"name": "text",
				"type": "string"
			}
		],
		"name": "encodeMultiple",
		"outputs": [
			{
				"internalType": "bytes",
				"name": "",
				"type": "bytes"
			}
		],
		"stateMutability": "pure",
		"type": "function"
	},
	{
		"inputs": [
			{
				"internalType": "uint256",
				"name": "value",
				"type": "uint256"
			}
		],
		"name": "encodeUint",
		"outputs": [
			{
				"internalType": "bytes",
				"name": "",
				"type": "bytes"
			}
		],
		"stateMutability": "pure",
		"type": "function"
	}
];

// 🔴 替换为你的实际合约地址！
let contractAddress = "";

let provider;
let signer;
let contract;

document.getElementById("connect").addEventListener("click", async () => {
  if (typeof window.ethereum !== "undefined") {
    try {
      // 请求账户访问
      await window.ethereum.request({ method: "eth_requestAccounts" });

      // 创建 ethers v6 provider
      provider = new ethers.BrowserProvider(window.ethereum);
      signer = await provider.getSigner();
      contract = undefined; // 合约地址应用后再构造合约实例

	  const network = await provider.getNetwork();
	  console.log("Connected to chain ID:", network.chainId);

      // 获取用户地址
      const address = await signer.getAddress();
      console.log("Connected account:", address);
      
      document.getElementById("addr").innerHTML = `钱包地址：${address}（链ID：${Number(network.chainId)}）`;
      document.getElementById("result").innerHTML = "✅ 钱包已连接！";
    } catch (error) {
      console.error("连接失败:", error);
      document.getElementById("result").innerHTML = "❌ 连接钱包失败";
    }
  } else {
    alert("请安装 MetaMask 或其他 EIP-1193 兼容钱包");
  }
});

// 应用合约地址并进行链上预检
document.getElementById("applyAddr").addEventListener("click", async () => {
  if (!provider || !signer) {
    document.getElementById("contractStatus").innerHTML = "❌ 请先连接钱包";
    return;
  }
  const addr = document.getElementById("contractAddress").value.trim();
  if (!ethers.isAddress(addr)) {
    document.getElementById("contractStatus").innerHTML = "❌ 请输入有效的合约地址";
    return;
  }
  try {
    const code = await provider.getCode(addr);
    if (!code || code === "0x") {
      document.getElementById("contractStatus").innerHTML = "❌ 该地址未部署合约或网络不一致";
      return;
    }
    contractAddress = addr;
    contract = new ethers.Contract(contractAddress, contractABI, signer);
    document.getElementById("contractStatus").innerHTML = `✅ 地址有效，已创建合约实例：${addr}`;
  } catch (e) {
    document.getElementById("contractStatus").innerHTML = `❌ 预检失败：${e.shortMessage || e.message}`;
  }
});

// 只编码按钮
document.getElementById("encodeBtn").addEventListener("click", async () => {
  const numRaw = document.getElementById("num").value.trim();
  const text = document.getElementById("text").value.trim();

  if (!numRaw || !text) {
    document.getElementById("result").innerHTML = "❌ 请输入数字和文本（只编码）";
    return;
  }

  let num;
  try {
    num = BigInt(numRaw);
  } catch (e) {
    document.getElementById("result").innerHTML = `❌ 数字无效: ${e.message}`;
    return;
  }

  try {
    if (!contract) throw new Error("contract_not_ready");
    const encoded = await contract.encodeMultiple(num, text);
    document.getElementById("encodedResult").innerHTML =
      `<b>编码结果</b><br>${encoded}<br><span style='color:#666'>长度: ${encoded.length - 2} hex chars</span>`;
    // 便于解码，自动填充到待解码输入框
    const bytesHexInput = document.getElementById("bytesHex");
    if (bytesHexInput) bytesHexInput.value = encoded;
    document.getElementById("result").innerHTML = `✅ 模式: 链上<br>输入: ${num.toString()}, "${text}"`;
  } catch (onChainErr) {
    try {
      const coder = ethers.AbiCoder.defaultAbiCoder();
      const encodedOffline = coder.encode(["uint256", "string"], [num, text]);
      document.getElementById("encodedResult").innerHTML =
        `<b>编码结果</b><br>${encodedOffline}<br><span style='color:#666'>长度: ${encodedOffline.length - 2} hex chars</span>`;
      const bytesHexInput = document.getElementById("bytesHex");
      if (bytesHexInput) bytesHexInput.value = encodedOffline;
      document.getElementById("result").innerHTML = `⚠️ 模式: 离线<br>说明: 链上编码不可用，已使用 ethers.AbiCoder 编码`;
    } catch (offlineErr) {
      document.getElementById("result").innerHTML = `❌ 离线编码失败: ${offlineErr.message}`;
    }
  }
});

// 只解码按钮
document.getElementById("decodeBtn").addEventListener("click", async () => {
  const bytesHex = document.getElementById("bytesHex").value.trim();
  if (!bytesHex) {
    document.getElementById("result").innerHTML = "❌ 请输入待解码的字节（0x 开头的 hex）";
    return;
  }
  // hex 格式校验
  const isHex = /^0x[0-9a-fA-F]*$/.test(bytesHex);
  if (!isHex || ((bytesHex.length - 2) % 2 !== 0)) {
    document.getElementById("result").innerHTML = "❌ 字节格式无效，请输入 0x 开头的有效 hex";
    return;
  }

  try {
    if (!contract) throw new Error("contract_not_ready");
    const [decodedNum, decodedText] = await contract.decodeMultiple(bytesHex);
    document.getElementById("decodedResult").innerHTML =
      `<b>解码结果</b><br>数字: ${decodedNum.toString()}<br>文本: "${decodedText}"`;
    document.getElementById("result").innerHTML = `✅ 模式: 链上<br>解码来源: 手动输入`;
  } catch (onChainErr) {
    try {
      const coder = ethers.AbiCoder.defaultAbiCoder();
      const [decodedNum, decodedText] = coder.decode(["uint256", "string"], bytesHex);
      document.getElementById("decodedResult").innerHTML =
        `<b>解码结果</b><br>数字: ${BigInt(decodedNum).toString()}<br>文本: "${decodedText}"`;
      document.getElementById("result").innerHTML = `⚠️ 模式: 离线<br>说明: 链上解码不可用，已使用 ethers.AbiCoder 解码`;
    } catch (offlineErr) {
      document.getElementById("result").innerHTML = `❌ 离线解码失败: ${offlineErr.message}`;
    }
  }
});

// 编码并解码（组合）
document.getElementById("test").addEventListener("click", async () => {
  const numRaw = document.getElementById("num").value.trim();
  const text = document.getElementById("text").value.trim();

  if (!numRaw || !text) {
    document.getElementById("result").innerHTML = "❌ 请输入数字和文本";
    return;
  }

  let num;
  try {
    num = BigInt(numRaw);
  } catch (e) {
    document.getElementById("result").innerHTML = `❌ 数字无效: ${e.message}`;
    return;
  }

  if (!contract) {
    document.getElementById("result").innerHTML = "❌ 请先连接钱包并应用合约地址";
    return;
  }

  try {
    // 链上编码
    const encoded = await contract.encodeMultiple(num, text);
    // 链上解码
    const [decodedNum, decodedText] = await contract.decodeMultiple(encoded);

    document.getElementById("encodedResult").innerHTML =
      `<b>编码结果</b><br>${encoded}<br><span style='color:#666'>长度: ${encoded.length - 2} hex chars</span>`;

    document.getElementById("decodedResult").innerHTML =
      `<b>解码结果</b><br>数字: ${decodedNum.toString()}<br>文本: "${decodedText}"`;

    const numMatch = decodedNum === num;
    const textMatch = decodedText === text;

    let summaryHTML = `<b>模式:</b> 链上<br>`;
    summaryHTML += `<b>原始输入:</b> ${num.toString()}, "${text}"<br>`;
    summaryHTML += `<b>验证结果:</b> 数字匹配: ${numMatch ? '✅' : '❌'}, 文本匹配: ${textMatch ? '✅' : '❌'}`;
    document.getElementById("result").innerHTML = summaryHTML;
  } catch (onChainErr) {
    console.warn("On-chain call failed, switching to offline mode:", onChainErr);

    try {
      // 离线编码/解码
      const coder = ethers.AbiCoder.defaultAbiCoder();
      const encodedOffline = coder.encode(["uint256", "string"], [num, text]);
      const [decodedNum, decodedText] = coder.decode(["uint256", "string"], encodedOffline);

      document.getElementById("encodedResult").innerHTML =
        `<b>编码结果</b><br>${encodedOffline}<br><span style='color:#666'>长度: ${encodedOffline.length - 2} hex chars</span>`;

      document.getElementById("decodedResult").innerHTML =
        `<b>解码结果</b><br>数字: ${BigInt(decodedNum).toString()}<br>文本: "${decodedText}"`;

      const numMatch = BigInt(decodedNum) === num;
      const textMatch = decodedText === text;

      let summaryHTML = `<b>模式:</b> 离线<br>`;
      summaryHTML += `<b>原始输入:</b> ${num.toString()}, "${text}"<br>`;
      summaryHTML += `<b>验证结果:</b> 数字匹配: ${numMatch ? '✅' : '❌'}, 文本匹配: ${textMatch ? '✅' : '❌'}`;
      summaryHTML += `<br><span style='color:#888'>提示：请确认合约地址、网络与 ABI 一致；当前链上调用失败。</span>`;
      document.getElementById("result").innerHTML = summaryHTML;
    } catch (offlineErr) {
      document.getElementById("result").innerHTML = `❌ 离线编码/解码失败: ${offlineErr.message}`;
    }
  }
});