const addrSpan = document.getElementById('addr')
const statusSpan = document.getElementById('status')
const tbody = document.getElementById('tbody')
const connectBtn = document.getElementById('connect')
const refreshBtn = document.getElementById('refresh')

let currentAddress = null

async function connectWallet() {
  if (!window.ethereum) return
  const accounts = await window.ethereum.request({ method: 'eth_requestAccounts' })
  currentAddress = accounts[0]
  addrSpan.textContent = currentAddress
}

async function fetchTransfers() {
  if (!currentAddress) return
  statusSpan.textContent = '加载中'
  const res = await fetch(`${backendBase}/api/transfers/${currentAddress}`)
  const json = await res.json()
  statusSpan.textContent = `共 ${json.total} 条`
  tbody.innerHTML = ''
  for (const r of json.data) {
    const tr = document.createElement('tr')
    const date = new Date(r.timestamp * 1000).toLocaleString()
    tr.innerHTML = `<td>${date}</td><td>${r.blockNumber}</td><td>${r.txHash}</td><td>${r.from}</td><td>${r.to}</td><td>${r.valueFormatted}</td>`
    tbody.appendChild(tr)
  }
}

connectBtn.onclick = () => connectWallet()
refreshBtn.onclick = () => fetchTransfers()