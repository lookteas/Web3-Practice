// 部署和测试脚本 - BigBank & Admin 合约部署到 Sepolia
// 使用 Node.js 和 ethers.js 进行合约部署和交互测试

const { ethers } = require('ethers');
const fs = require('fs');

// BigBank 合约 ABI
const BIGBANK_ABI = [
    {
        "inputs": [],
        "stateMutability": "nonpayable",
        "type": "constructor"
    },
    {
        "inputs": [],
        "name": "admin",
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
        "inputs": [
            {
                "internalType": "address",
                "name": "newAdmin",
                "type": "address"
            }
        ],
        "name": "changeAdmin",
        "outputs": [],
        "stateMutability": "nonpayable",
        "type": "function"
    },
    {
        "inputs": [],
        "name": "deposit",
        "outputs": [],
        "stateMutability": "payable",
        "type": "function"
    },
    {
        "inputs": [
            {
                "internalType": "address",
                "name": "depositor",
                "type": "address"
            }
        ],
        "name": "getDeposit",
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
        "name": "getContractBalance",
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
        "name": "getTopDepositorsWithAmounts",
        "outputs": [
            {
                "internalType": "address[3]",
                "name": "",
                "type": "address[3]"
            },
            {
                "internalType": "uint256[3]",
                "name": "",
                "type": "uint256[3]"
            }
        ],
        "stateMutability": "view",
        "type": "function"
    },
    {
        "inputs": [],
        "name": "owner",
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
        "inputs": [
            {
                "internalType": "uint256",
                "name": "",
                "type": "uint256"
            }
        ],
        "name": "topDepositors",
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
        "name": "withdraw",
        "outputs": [],
        "stateMutability": "nonpayable",
        "type": "function"
    },
    {
        "stateMutability": "payable",
        "type": "receive"
    }
];

// BigBank 合约字节码
const BIGBANK_BYTECODE = "0x60a0604052348015600e575f5ffd5b50335f5f6101000a81548173ffffffffffffffffffffffffffffffffffffffff021916908373ffffffffffffffffffffffffffffffffffffffff1602179055503373ffffffffffffffffffffffffffffffffffffffff1660808173ffffffffffffffffffffffffffffffffffffffff16815250506080516115516100a15f395f818161059b01526105bf01526115515ff3fe60806040526004361061007e575f3560e01c80638f2839701161004d5780638f28397014610181578063d0e30db0146101a9578063f851a440146101b3578063fc7e286d146101dd576100d6565b806330861078146100da5780633ccfd60b1461011657806381454f711461012c5780638da5cb5b14610157576100d6565b366100d65766038d7ea4c6800034116100cc576040517f08c379a00000000000000000000000000000000000000000000000000000000081526004016100c390610e16565b60405180910390fd5b6100d4610219565b005b5f5ffd5b3480156100e5575f5ffd5b5061010060048036038101906100fb9190610e6b565b610277565b60405161010d9190610ed5565b60405180910390f35b348015610121575f5ffd5b5061012a6102ab565b005b348015610137575f5ffd5b5061014061044b565b60405161014e929190611038565b60405180910390f35b348015610162575f5ffd5b5061016b610599565b6040516101789190610ed5565b60405180910390f35b34801561018c575f5ffd5b506101a760048036038101906101a29190611089565b6105bd565b005b6101b16106fb565b005b3480156101be575f5ffd5b506101c761074e565b6040516101d49190610ed5565b60405180910390f35b3480156101e8575f5ffd5b5061020360048036038101906101fe9190611089565b610772565b60405161021091906110c3565b60405180910390f35b3460015f3373ffffffffffffffffffffffffffffffffffffffff1673ffffffffffffffffffffffffffffffffffffffff1681526020019081526020015f205f8282546102659190611109565b9250508190555061027533610787565b565b60028160038110610286575f80fd5b015f915054906101000a900473ffffffffffffffffffffffffffffffffffffffff1681565b5f5f9054906101000a900473ffffffffffffffffffffffffffffffffffffffff1673ffffffffffffffffffffffffffffffffffffffff163373ffffffffffffffffffffffffffffffffffffffff1614610339576040517f08c379a000000000000000000000000000000000000000000000000000000000815260040161033090611186565b60405180910390fd5b5f4790505f811161037f576040517f08c379a0000000000000000000000000000000000000000000000000000000008152600401610376906111ee565b60405180910390fd5b5f5f5f9054906101000a900473ffffffffffffffffffffffffffffffffffffffff1673ffffffffffffffffffffffffffffffffffffffff16826040516103c490611239565b5f6040518083038185875af1925050503d805f81146103fe576040519150601f19603f3d011682016040523d82523d5f602084013e610403565b606091505b5050905080610447576040517f08c379a000000000000000000000000000000000000000000000000000000000815260040161043e90611297565b60405180910390fd5b5050565b610453610d52565b61045b610d74565b610463610d74565b5f5f90505b600360ff168160ff1610156105185760015f60028360ff1660038110610491576104906112b5565b5b015f9054906101000a900473ffffffffffffffffffffffffffffffffffffffff1673ffffffffffffffffffffffffffffffffffffffff1673ffffffffffffffffffffffffffffffffffffffff1681526020019081526020015f2054828260ff1660038110610502576105016112b5565b5b6020020181815250508080600101915050610468565b5060028181600380602002604051908101604052809291908260038015610589576020028201915b815f9054906101000a900473ffffffffffffffffffffffffffffffffffffffff1673ffffffffffffffffffffffffffffffffffffffff1681526020019060010190808311610540575b5050505050915092509250509091565b7f000000000000000000000000000000000000000000000000000000000000000081565b7f000000000000000000000000000000000000000000000000000000000000000073ffffffffffffffffffffffffffffffffffffffff163373ffffffffffffffffffffffffffffffffffffffff161461064b576040517f08c379a00000000000000000000000000000000000000000000000000000000081526004016106429061132c565b60405180910390fd5b5f73ffffffffffffffffffffffffffffffffffffffff168173ffffffffffffffffffffffffffffffffffffffff16036106b9576040517f08c379a00000000000000000000000000000000000000000000000000000000081526004016106b090611394565b60405180910390fd5b805f5f6101000a81548173ffffffffffffffffffffffffffffffffffffffff021916908373ffffffffffffffffffffffffffffffffffffffff16021790555050565b66038d7ea4c680003411610744576040517f08c379a000000000000000000000000000000000000000000000000000000000815260040161073b90610e16565b60405180910390fd5b61074c610219565b565b5f5f9054906101000a900473ffffffffffffffffffffffffffffffffffffffff1681565b6001602052805f5260405f205f915090505481565b5f60015f8373ffffffffffffffffffffffffffffffffffffffff1673ffffffffffffffffffffffffffffffffffffffff1681526020019081526020015f205490505f5f90505b600360ff168160ff161015610862578273ffffffffffffffffffffffffffffffffffffffff1660028260ff166003811061080a576108096112b5565b5b015f9054906101000a900473ffffffffffffffffffffffffffffffffffffffff1673ffffffffffffffffffffffffffffffffffffffff16036108555761084e610a5e565b5050610a5b565b80806001019150506107cd565b505f5f90505b600360ff168160ff161015610a58575f60028260ff166003811061088f5761088e6112b5565b5b015f9054906101000a900473ffffffffffffffffffffffffffffffffffffffff1690505f73ffffffffffffffffffffffffffffffffffffffff168173ffffffffffffffffffffffffffffffffffffffff161480610928575060015f8273ffffffffffffffffffffffffffffffffffffffff1673ffffffffffffffffffffffffffffffffffffffff1681526020019081526020015f205483115b15610a4a575f600290505b8260ff168160ff1611156109ed57600260018261095091906113be565b60ff1660038110610964576109636112b5565b5b015f9054906101000a900473ffffffffffffffffffffffffffffffffffffffff1660028260ff166003811061099c5761099b6112b5565b5b015f6101000a81548173ffffffffffffffffffffffffffffffffffffffff021916908373ffffffffffffffffffffffffffffffffffffffff16021790555080806109e5906113f2565b915050610933565b508360028360ff1660038110610a0657610a056112b5565b5b015f6101000a81548173ffffffffffffffffffffffffffffffffffffffff021916908373ffffffffffffffffffffffffffffffffffffffff16021790555050610a58565b508080600101915050610868565b50505b50565b5f600190505b600360ff168160ff161015610d4f575f60028260ff1660038110610a8b57610a8a6112b5565b5b015f9054906101000a900473ffffffffffffffffffffffffffffffffffffffff1690505f73ffffffffffffffffffffffffffffffffffffffff168173ffffffffffffffffffffffffffffffffffffffff1603610ae75750610d42565b5f60015f8373ffffffffffffffffffffffffffffffffffffffff1673ffffffffffffffffffffffffffffffffffffffff1681526020019081526020015f205490505f600184610b369190611424565b90505b5f815f0b12158015610c2b57505f73ffffffffffffffffffffffffffffffffffffffff1660028260ff1660038110610b7457610b736112b5565b5b015f9054906101000a900473ffffffffffffffffffffffffffffffffffffffff1673ffffffffffffffffffffffffffffffffffffffff161480610c2a57508160015f60028460ff1660038110610bcd57610bcc6112b5565b5b015f9054906101000a900473ffffffffffffffffffffffffffffffffffffffff1673ffffffffffffffffffffffffffffffffffffffff1673ffffffffffffffffffffffffffffffffffffffff1681526020019081526020015f2054105b5b15610cdc5760028160ff1660038110610c4757610c466112b5565b5b015f9054906101000a900473ffffffffffffffffffffffffffffffffffffffff166002600183610c77919061147c565b60ff1660038110610c8b57610c8a6112b5565b5b015f6101000a81548173ffffffffffffffffffffffffffffffffffffffff021916908373ffffffffffffffffffffffffffffffffffffffff1602179055508080610cd4906114d4565b915050610b39565b826002600183610cec919061147c565b60ff1660038110610d0057610cff6112b5565b5b015f6101000a81548173ffffffffffffffffffffffffffffffffffffffff021916908373ffffffffffffffffffffffffffffffffffffffff16021790555050505b8080600101915050610a64565b50565b6040518060600160405280600390602082028036833780820191505090505090565b6040518060600160405280600390602082028036833780820191505090505090565b5f82825260208201905092915050565b7f4465706f73697420616d6f756e74206d757374206265206772656174657220745f8201527f68616e20302e3030312065746865720000000000000000000000000000000000602082015250565b5f610e00602f83610d96565b9150610e0b82610da6565b604082019050919050565b5f6020820190508181035f830152610e2d81610df4565b9050919050565b5f5ffd5b5f819050919050565b610e4a81610e38565b8114610e54575f5ffd5b50565b5f81359050610e6581610e41565b92915050565b5f60208284031215610e8057610e7f610e34565b5b5f610e8d84828501610e57565b91505092915050565b5f73ffffffffffffffffffffffffffffffffffffffff82169050919050565b5f610ebf82610e96565b9050919050565b610ecf81610eb5565b82525050565b5f602082019050610ee85f830184610ec6565b92915050565b5f60039050919050565b5f81905092915050565b5f819050919050565b610f1481610eb5565b82525050565b5f610f258383610f0b565b60208301905092915050565b5f602082019050919050565b610f4681610eee565b610f508184610ef8565b9250610f5b82610f02565b805f5b83811015610f8b578151610f728782610f1a565b9650610f7d83610f31565b925050600181019050610f5e565b505050505050565b5f60039050919050565b5f81905092915050565b5f819050919050565b610fb981610e38565b82525050565b5f610fca8383610fb0565b60208301905092915050565b5f602082019050919050565b610feb81610f93565b610ff58184610f9d565b925061100082610fa7565b805f5b838110156110305781516110178782610fbf565b965061102283610fd6565b925050600181019050611003565b505050505050565b5f60c08201905061104b5f830185610f3d565b6110586060830184610fe2565b9392505050565b61106881610eb5565b8114611072575f5ffd5b50565b5f813590506110838161105f565b92915050565b5f6020828403121561109e5761109d610e34565b5b5f6110ab84828501611075565b91505092915050565b6110bd81610e38565b82525050565b5f6020820190506110d65f8301846110b4565b92915050565b7f4e487b71000000000000000000000000000000000000000000000000000000005f52601160045260245ffd5b5f61111382610e38565b915061111e83610e38565b9250828201905080821115611136576111356110dc565b5b92915050565b7f4f6e6c792061646d696e2063616e2077697468647261770000000000000000005f82015250565b5f611170601783610d96565b915061117b8261113c565b602082019050919050565b5f6020820190508181035f83015261119d81611164565b9050919050565b7f4e6f2062616c616e636520746f207769746864726177000000000000000000005f82015250565b5f6111d8601683610d96565b91506111e3826111a4565b602082019050919050565b5f6020820190508181035f830152611205816111cc565b9050919050565b5f81905092915050565b50565b5f6112245f8361120c565b915061122f82611216565b5f82019050919050565b5f61124382611219565b9150819050919050565b7f5769746864726177616c206661696c65640000000000000000000000000000005f82015250565b5f611281601183610d96565b915061128c8261124d565b602082019050919050565b5f6020820190508181035f8301526112ae81611275565b9050919050565b7f4e487b71000000000000000000000000000000000000000000000000000000005f52603260045260245ffd5b7f4f6e6c79206f776e65722063616e206368616e67652061646d696e00000000005f82015250565b5f611316601b83610d96565b9150611321826112e2565b602082019050919050565b5f6020820190508181035f8301526113438161130a565b9050919050565b7f4e65772061646d696e2063616e6e6f74206265207a65726f20616464726573735f82015250565b5f61137e602083610d96565b91506113898261134a565b602082019050919050565b5f6020820190508181035f8301526113ab81611372565b9050919050565b5f60ff82169050919050565b5f6113c8826113b2565b91506113d3836113b2565b9250828203905060ff8111156113ec576113eb6110dc565b5b92915050565b5f6113fc826113b2565b91505f820361140e5761140d6110dc565b5b600182039050919050565b5f815f0b9050919050565b5f61142e82611419565b915061143983611419565b92508282039050607f81137fffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff8082121715611476576114756110dc565b5b92915050565b5f61148682611419565b915061149183611419565b925082820190507fffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff808112607f821317156114ce576114cd6110dc565b5b92915050565b5f6114de82611419565b91507fffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff8082036115105761150f6110dc565b5b60018203905091905056fea264697066735822122042893ca0b96b04354320d603b31bb873c30f40f943f3a5ebed665fd8ead7bdf464736f6c634300081e0033";

// Admin 合约 ABI
const ADMIN_ABI = [
    {
        "inputs": [],
        "stateMutability": "nonpayable",
        "type": "constructor"
    },
    {
        "inputs": [
            {
                "internalType": "address",
                "name": "bank",
                "type": "address"
            }
        ],
        "name": "adminWithdraw",
        "outputs": [],
        "stateMutability": "nonpayable",
        "type": "function"
    },
    {
        "inputs": [],
        "name": "owner",
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
        "name": "withdrawAllToOwner",
        "outputs": [],
        "stateMutability": "nonpayable",
        "type": "function"
    },
    {
        "stateMutability": "payable",
        "type": "receive"
    }
];

// Admin 合约字节码
const ADMIN_BYTECODE = "0x60a0604052348015600e575f5ffd5b503373ffffffffffffffffffffffffffffffffffffffff1660808173ffffffffffffffffffffffffffffffffffffffff16815250506080516105db61006f5f395f818160ac015281816101810152818161024c015261033801526105db5ff3fe608060405260043610610037575f3560e01c80633cb40e1614610042578063a28835b614610058578063f851a440146100805761003e565b3661003e57005b5f5ffd5b34801561004d575f5ffd5b506100566100aa565b005b348015610063575f5ffd5b5061007e600480360381019061007991906103c9565b61024a565b005b34801561008b575f5ffd5b50610094610336565b6040516100a19190610403565b60405180910390f35b7f000000000000000000000000000000000000000000000000000000000000000073ffffffffffffffffffffffffffffffffffffffff163373ffffffffffffffffffffffffffffffffffffffff1614610138576040517f08c379a000000000000000000000000000000000000000000000000000000000815260040161012f90610476565b60405180910390fd5b5f4790505f811161017e576040517f08c379a0000000000000000000000000000000000000000000000000000000008152600401610175906104de565b60405180910390fd5b5f7f000000000000000000000000000000000000000000000000000000000000000073ffffffffffffffffffffffffffffffffffffffff16826040516101c390610529565b5f6040518083038185875af1925050503d805f81146101fd576040519150601f19603f3d011682016040523d82523d5f602084013e610202565b606091505b5050905080610246576040517f08c379a000000000000000000000000000000000000000000000000000000000815260040161023d90610587565b60405180910390fd5b5050565b7f000000000000000000000000000000000000000000000000000000000000000073ffffffffffffffffffffffffffffffffffffffff163373ffffffffffffffffffffffffffffffffffffffff16146102d8576040517f08c379a00000000000000000000000000000000000000000000000000000000081526004016102cf90610476565b60405180910390fd5b8073ffffffffffffffffffffffffffffffffffffffff16633ccfd60b6040518163ffffffff1660e01b81526004015f604051808303815f87803b15801561031d575f5ffd5b505af115801561032f573d5f5f3e3d5ffd5b5050505050565b7f000000000000000000000000000000000000000000000000000000000000000081565b5f5ffd5b5f73ffffffffffffffffffffffffffffffffffffffff82169050919050565b5f6103878261035e565b9050919050565b5f6103988261037d565b9050919050565b6103a88161038e565b81146103b2575f5ffd5b50565b5f813590506103c38161039f565b92915050565b5f602082840312156103de576103dd61035a565b5b5f6103eb848285016103b5565b91505092915050565b6103fd8161037d565b82525050565b5f6020820190506104165f8301846103f4565b92915050565b5f82825260208201905092915050565b7f4f6e6c792061646d696e2063616e2077697468647261770000000000000000005f82015250565b5f61046060178361041c565b915061046b8261042c565b602082019050919050565b5f6020820190508181035f83015261048d81610454565b9050919050565b7f4e6f2062616c616e636520746f207769746864726177000000000000000000005f82015250565b5f6104c860168361041c565b91506104d382610494565b602082019050919050565b5f6020820190508181035f8301526104f5816104bc565b9050919050565b5f81905092915050565b50565b5f6105145f836104fc565b915061051f82610506565b5f82019050919050565b5f61053382610509565b9150819050919050565b7f5769746864726177616c206661696c65640000000000000000000000000000005f82015250565b5f61057160118361041c565b915061057c8261053d565b602082019050919050565b5f6020820190508181035f83015261059e81610565565b905091905056fea2646970667358221220257891be81e413145ed989f4a889399ddd5012fae918c7c59136eaa56995415c64736f6c634300081e0033";

class ContractDeployer {
    constructor(providerUrl, privateKeys) {
        this.provider = new ethers.JsonRpcProvider(providerUrl);
        this.wallets = privateKeys.map(key => new ethers.Wallet(key, this.provider));
        this.deployer = this.wallets[0]; // 第一个钱包作为部署者
        this.users = this.wallets.slice(1); // 其他钱包作为用户
        
        console.log(`🔗 连接到网络: ${providerUrl}`);
        console.log(`👤 部署者地址: ${this.deployer.address}`);
        console.log(`👥 用户地址: ${this.users.map(w => w.address).join(', ')}`);
    }

    async checkBalances() {
        console.log('\n 检查账户余额...');
        
        for (let i = 0; i < this.wallets.length; i++) {
            const wallet = this.wallets[i];
            const balance = await this.provider.getBalance(wallet.address);
            const balanceEth = ethers.formatEther(balance);
            const role = i === 0 ? '部署者' : `用户${i}`;
            console.log(`${role} (${wallet.address}): ${balanceEth} ETH`);
            
            if (parseFloat(balanceEth) < 0.01) {
                console.warn(`⚠️  ${role} 余额不足，可能无法完成操作`);
            }
        }
    }

    async deployContracts() {
        console.log('\n 开始部署合约...');
        
        try {
            // 检查余额
            await this.checkBalances();
            
            // 部署 BigBank 合约
            console.log('\n 部署 BigBank 合约...');
            const BigBankFactory = new ethers.ContractFactory(
                BIGBANK_ABI, 
                BIGBANK_BYTECODE, 
                this.deployer
            );
            
            console.log('发送部署交易...');
            this.bigBank = await BigBankFactory.deploy();
            console.log(`交易哈希: ${this.bigBank.deploymentTransaction().hash}`);
            
            console.log('等待合约部署确认...');
            await this.bigBank.waitForDeployment();
            const bigBankAddress = await this.bigBank.getAddress();
            console.log(` BigBank 合约部署成功: ${bigBankAddress}`);

            // 部署 Admin 合约
            console.log('\n 部署 Admin 合约...');
            const AdminFactory = new ethers.ContractFactory(
                ADMIN_ABI, 
                ADMIN_BYTECODE, 
                this.deployer
            );
            
            console.log('发送部署交易...');
            this.admin = await AdminFactory.deploy();
            console.log(`交易哈希: ${this.admin.deploymentTransaction().hash}`);
            
            console.log('等待合约部署确认...');
            await this.admin.waitForDeployment();
            const adminAddress = await this.admin.getAddress();
            console.log(`Admin 合约部署成功: ${adminAddress}`);

            // 转移 BigBank 的管理员权限给 Admin 合约
            console.log('\n 转移 BigBank 管理员权限给 Admin 合约...');
            const transferTx = await this.bigBank.changeAdmin(adminAddress);
            console.log(`交易哈希: ${transferTx.hash}`);
            await transferTx.wait();
            console.log(' 管理员权限转移成功');

            return {
                bigBank: bigBankAddress,
                admin: adminAddress
            };
        } catch (error) {
            console.error(' 部署失败:', error.message);
            if (error.code === 'INSUFFICIENT_FUNDS') {
                console.error(' 余额不足，请确保账户有足够的 ETH');
            }
            throw error;
        }
    }

    async simulateUserDeposits() {
        console.log('\n 模拟用户存款...');
        
        const deposits = [
            { user: 0, amount: '0.005' }, // 0.005 ETH
            { user: 1, amount: '0.01' },  // 0.01 ETH
            { user: 2, amount: '0.002' }, // 0.002 ETH
            { user: 0, amount: '0.003' }, // 用户0再次存款
        ];

        for (const deposit of deposits) {
            try {
                const userWallet = this.users[deposit.user];
                const bigBankWithUser = this.bigBank.connect(userWallet);
                
                console.log(`\n 用户 ${deposit.user + 1} (${userWallet.address}) 存款 ${deposit.amount} ETH...`);
                
                const tx = await bigBankWithUser.deposit({
                    value: ethers.parseEther(deposit.amount)
                });
                console.log(`交易哈希: ${tx.hash}`);
                await tx.wait();
                console.log(' 存款成功');
                
                // 查询用户存款余额
                const userBalance = await this.bigBank.getDeposit(userWallet.address);
                console.log(`用户当前存款余额: ${ethers.formatEther(userBalance)} ETH`);
                
            } catch (error) {
                console.error(` 用户 ${deposit.user + 1} 存款失败:`, error.message);
            }
        }
    }

    async checkContractStatus() {
        console.log('\n 检查合约状态...');
        
        try {
            // 检查 BigBank 余额
            const bankBalance = await this.bigBank.getContractBalance();
            console.log(`🏦 BigBank 合约余额: ${ethers.formatEther(bankBalance)} ETH`);
            
            // 检查前3名存款用户
            const [topDepositors, amounts] = await this.bigBank.getTopDepositorsWithAmounts();
            console.log('\n🏆 前3名存款用户:');
            for (let i = 0; i < 3; i++) {
                if (topDepositors[i] !== ethers.ZeroAddress) {
                    console.log(`  ${i + 1}. ${topDepositors[i]}: ${ethers.formatEther(amounts[i])} ETH`);
                }
            }
            
            // 检查 Admin 合约余额
            const adminBalance = await this.provider.getBalance(await this.admin.getAddress());
            console.log(`\n Admin 合约余额: ${ethers.formatEther(adminBalance)} ETH`);
            
            // 检查 BigBank 的管理员
            const bankAdmin = await this.bigBank.admin();
            const adminAddress = await this.admin.getAddress();
            console.log(`\n BigBank 当前管理员: ${bankAdmin}`);
            console.log(`Admin 合约地址: ${adminAddress}`);
            console.log(`管理员权限转移${bankAdmin === adminAddress ? '成功' : '失败'}`);
            
        } catch (error) {
            console.error('检查合约状态失败:', error.message);
        }
    }

    async executeAdminWithdraw() {
        console.log('\n 执行管理员提取资金...');
        
        try {
            // Admin 合约的 owner 调用 adminWithdraw
            const adminWithOwner = this.admin.connect(this.deployer);
            
            console.log('Admin 合约 Owner 调用 adminWithdraw...');
            const withdrawTx = await adminWithOwner.adminWithdraw(await this.bigBank.getAddress());
            console.log(`交易哈希: ${withdrawTx.hash}`);
            await withdrawTx.wait();
            console.log('资金提取成功');
            
            // 检查提取后的状态
            await this.checkContractStatus();
            
        } catch (error) {
            console.error(' 管理员提取资金失败:', error.message);
        }
    }

    async runFullDemo() {
        console.log(' 开始完整演示流程...\n');
        
        try {
            // 1. 部署合约
            const addresses = await this.deployContracts();
            
            // 2. 模拟用户存款
            await this.simulateUserDeposits();
            
            // 3. 检查合约状态
            await this.checkContractStatus();
            
            // 4. 执行管理员提取
            await this.executeAdminWithdraw();
            
            console.log('\n 演示完成！');
            console.log('\n 合约地址汇总:');
            console.log(`BigBank: ${addresses.bigBank}`);
            console.log(`Admin: ${addresses.admin}`);
            
            // 保存地址到文件
            const deploymentInfo = {
                network: 'sepolia',
                timestamp: new Date().toISOString(),
                contracts: addresses,
                deployer: this.deployer.address
            };
            
            fs.writeFileSync('deployment.json', JSON.stringify(deploymentInfo, null, 2));
            console.log('\n 部署信息已保存到 deployment.json');
            
        } catch (error) {
            console.error(' 演示过程中出现错误:', error);
        }
    }
}

// 配置信息
const CONFIG = {
    // Sepolia 测试网络 RPC URL
    PROVIDER_URL: 'https://sepolia.infura.io/v3/2xxxx4',
    
    // 测试私钥（请使用测试账户，不要使用真实资金）
    PRIVATE_KEYS: [
        '', // 部署者/Admin Owner
        // '0x...', // 用户1
        // '0x...', // 用户2
        // '0x...', // 用户3
    ]
};

// 主函数
async function main() {
    console.log('🏦 BigBank & Admin 合约部署脚本');
    console.log('================================\n');
    
    // 检查配置
    if (CONFIG.PROVIDER_URL.includes('YOUR_INFURA_PROJECT_ID')) {
        console.error('❌ 请先配置 Infura Project ID');
        console.log('1. 访问 https://infura.io/ 创建项目');
        console.log('2. 复制 Project ID 并替换 CONFIG.PROVIDER_URL 中的 YOUR_INFURA_PROJECT_ID');
        return;
    }
    
    if (CONFIG.PRIVATE_KEYS.some(key => key === '0x...')) {
        console.error('❌ 请先配置测试私钥');
        console.log('1. 使用 MetaMask 或其他钱包创建测试账户');
        console.log('2. 从 Sepolia 水龙头获取测试 ETH: https://sepoliafaucet.com/');
        console.log('3. 导出私钥并替换 CONFIG.PRIVATE_KEYS 中的占位符');
        console.log('⚠️  注意：仅使用测试账户，不要使用包含真实资金的账户！');
        return;
    }
    
    const deployer = new ContractDeployer(CONFIG.PROVIDER_URL, CONFIG.PRIVATE_KEYS);
    await deployer.runFullDemo();
}

// 如果直接运行此脚本
if (require.main === module) {
    main().catch(console.error);
}

module.exports = { ContractDeployer, BIGBANK_ABI, ADMIN_ABI };