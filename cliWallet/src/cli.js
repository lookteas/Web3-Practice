#!/usr/bin/env node

import { Command } from 'commander';
import inquirer from 'inquirer';
import chalk from 'chalk';
import ora from 'ora';
import fs from 'fs';
import path from 'path';
import { fileURLToPath } from 'url';
import { Wallet } from './wallet.js';

const __filename = fileURLToPath(import.meta.url);
const __dirname = path.dirname(__filename);

const program = new Command();

// 全局钱包实例
let wallet = null;

// 初始化钱包
function initWallet() {
  const rpcUrl = process.env.SEPOLIA_RPC_URL || 'https://sepolia.infura.io/v3/23211bcb978542dbb55264865dd2ffd4';
  wallet = new Wallet(rpcUrl);
}

// 显示欢迎信息
function showWelcome() {
  console.log(chalk.cyan.bold('\n Web3 命令行钱包'));
  console.log(chalk.gray('基于 Viem.js 构建的 Sepolia 测试网钱包\n'));
}

// 生成新账户
async function generateAccount() {
  const spinner = ora('正在生成新账户...').start();
  
  try {
    const { privateKey, address } = wallet.generateAccount();
    
    spinner.succeed('账户生成成功！');
    
    console.log(chalk.green('\n 新账户信息:'));
    console.log(chalk.yellow(`地址: ${address}`));
    console.log(chalk.yellow(`私钥: ${privateKey}`));
    
    console.log(chalk.red('\n  重要提醒:'));
    console.log(chalk.red('• 请安全保存您的私钥'));
    console.log(chalk.red('• 不要与任何人分享您的私钥'));
    console.log(chalk.red('• 丢失私钥将无法恢复资产'));
    
    // 询问是否保存到文件
    const { saveToFile } = await inquirer.prompt([
      {
        type: 'confirm',
        name: 'saveToFile',
        message: '是否将账户信息保存到文件？',
        default: false
      }
    ]);
    
    if (saveToFile) {
      const accountData = {
        address,
        privateKey,
        createdAt: new Date().toISOString()
      };
      
      const filename = `account_${Date.now()}.json`;
      fs.writeFileSync(filename, JSON.stringify(accountData, null, 2));
      console.log(chalk.green(`\n账户信息已保存到: ${filename}`));
    }
    
  } catch (error) {
    spinner.fail('生成账户失败');
    console.error(chalk.red(`错误: ${error.message}`));
  }
}

// 导入账户
async function importAccount() {
  try {
    const { privateKey } = await inquirer.prompt([
      {
        type: 'password',
        name: 'privateKey',
        message: '请输入私钥 (0x开头):',
        validate: (input) => {
          if (!input.startsWith('0x') || input.length !== 66) {
            return '私钥格式不正确，应为 0x 开头的 64 位十六进制字符串';
          }
          return true;
        }
      }
    ]);
    
    const spinner = ora('正在导入账户...').start();
    
    const address = wallet.importAccount(privateKey);
    
    spinner.succeed('账户导入成功！');
    console.log(chalk.green(`\n 账户地址: ${address}`));
    
  } catch (error) {
    console.error(chalk.red(`导入失败: ${error.message}`));
  }
}

// 查询余额
async function checkBalance() {
  if (!wallet.isConnected()) {
    console.log(chalk.red('请先生成或导入账户'));
    return;
  }
  
  const address = wallet.getCurrentAddress();
  console.log(chalk.blue(`\n查询地址: ${address}`));
  
  // 查询 ETH 余额
  const ethSpinner = ora('查询 ETH 余额...').start();
  try {
    const ethBalance = await wallet.getETHBalance(address);
    ethSpinner.succeed(`ETH 余额: ${ethBalance} ETH`);
  } catch (error) {
    ethSpinner.fail(`查询 ETH 余额失败: ${error.message}`);
  }
  
  // 询问是否查询 ERC20 代币余额
  const { checkERC20 } = await inquirer.prompt([
    {
      type: 'confirm',
      name: 'checkERC20',
      message: '是否查询 ERC20 代币余额？',
      default: false
    }
  ]);
  
  if (checkERC20) {
    const { tokenAddress } = await inquirer.prompt([
      {
        type: 'input',
        name: 'tokenAddress',
        message: '请输入 ERC20 代币合约地址:',
        validate: (input) => {
          if (!input.startsWith('0x') || input.length !== 42) {
            return '合约地址格式不正确';
          }
          return true;
        }
      }
    ]);
    
    const erc20Spinner = ora('查询 ERC20 代币余额...').start();
    try {
      const tokenInfo = await wallet.getERC20Balance(tokenAddress, address);
      erc20Spinner.succeed(`${tokenInfo.name} (${tokenInfo.symbol}) 余额: ${tokenInfo.balance}`);
    } catch (error) {
      erc20Spinner.fail(`查询 ERC20 余额失败: ${error.message}`);
    }
  }
}

// ERC20 转账
async function transferERC20() {
  if (!wallet.isConnected()) {
    console.log(chalk.red('请先生成或导入账户'));
    return;
  }
  
  try {
    const answers = await inquirer.prompt([
      {
        type: 'input',
        name: 'tokenAddress',
        message: '请输入 ERC20 代币合约地址:',
        validate: (input) => {
          if (!input.startsWith('0x') || input.length !== 42) {
            return '合约地址格式不正确';
          }
          return true;
        }
      },
      {
        type: 'input',
        name: 'toAddress',
        message: '请输入接收地址:',
        validate: (input) => {
          if (!input.startsWith('0x') || input.length !== 42) {
            return '地址格式不正确';
          }
          return true;
        }
      },
      {
        type: 'input',
        name: 'amount',
        message: '请输入转账数量:',
        validate: (input) => {
          if (isNaN(parseFloat(input)) || parseFloat(input) <= 0) {
            return '请输入有效的数量';
          }
          return true;
        }
      }
    ]);
    
    // 获取代币信息
    const tokenSpinner = ora('获取代币信息...').start();
    let tokenInfo;
    try {
      tokenInfo = await wallet.getERC20Balance(answers.tokenAddress, wallet.getCurrentAddress());
      tokenSpinner.succeed(`代币: ${tokenInfo.name} (${tokenInfo.symbol})`);
      console.log(chalk.blue(`当前余额: ${tokenInfo.balance} ${tokenInfo.symbol}`));
    } catch (error) {
      tokenSpinner.fail(`获取代币信息失败: ${error.message}`);
      return;
    }
    
    // 确认转账
    const { confirm } = await inquirer.prompt([
      {
        type: 'confirm',
        name: 'confirm',
        message: `确认转账 ${answers.amount} ${tokenInfo.symbol} 到 ${answers.toAddress}？`,
        default: false
      }
    ]);
    
    if (!confirm) {
      console.log(chalk.yellow('转账已取消'));
      return;
    }
    
    // 执行转账
    const transferSpinner = ora('正在发送交易...').start();
    try {
      const hash = await wallet.sendERC20Transaction(
        answers.tokenAddress,
        answers.toAddress,
        answers.amount,
        tokenInfo.decimals
      );
      
      transferSpinner.succeed('交易已发送！');
      console.log(chalk.green(`\n 交易哈希: ${hash}`));
      console.log(chalk.blue(`Sepolia 浏览器: https://sepolia.etherscan.io/tx/${hash}`));
      
      // 等待确认
      const waitSpinner = ora('等待交易确认...').start();
      try {
        const receipt = await wallet.waitForTransaction(hash);
        if (receipt.status === 'success') {
          waitSpinner.succeed('交易确认成功！');
        } else {
          waitSpinner.fail('交易失败');
        }
      } catch (error) {
        waitSpinner.warn('等待确认超时，请手动检查交易状态');
      }
      
    } catch (error) {
      transferSpinner.fail(`转账失败: ${error.message}`);
    }
    
  } catch (error) {
    console.error(chalk.red(`操作失败: ${error.message}`));
  }
}

// 主菜单
async function showMainMenu() {
  const choices = [
    { name: ' 生成新账户', value: 'generate' },
    { name: ' 导入账户', value: 'import' },
    { name: ' 查询余额', value: 'balance' },
    { name: ' ERC20 转账', value: 'transfer' },
    { name: ' 退出', value: 'exit' }
  ];
  
  if (wallet.isConnected()) {
    const address = wallet.getCurrentAddress();
    console.log(chalk.green(`\n当前账户: ${address}`));
  }
  
  const { action } = await inquirer.prompt([
    {
      type: 'list',
      name: 'action',
      message: '请选择操作:',
      choices
    }
  ]);
  
  switch (action) {
    case 'generate':
      await generateAccount();
      break;
    case 'import':
      await importAccount();
      break;
    case 'balance':
      await checkBalance();
      break;
    case 'transfer':
      await transferERC20();
      break;
    case 'exit':
      console.log(chalk.cyan('感谢使用 Web3 命令行钱包！'));
      process.exit(0);
  }
  
  // 继续显示菜单
  setTimeout(() => showMainMenu(), 1000);
}

// 程序入口
program
  .name('web3-wallet')
  .description('Web3 命令行钱包')
  .version('1.0.0');

program
  .command('interactive')
  .alias('i')
  .description('启动交互式模式')
  .action(async () => {
    initWallet();
    showWelcome();
    await showMainMenu();
  });

program
  .command('generate')
  .description('生成新账户')
  .action(async () => {
    initWallet();
    await generateAccount();
  });

program
  .command('balance')
  .description('查询余额')
  .option('-a, --address <address>', '要查询的地址')
  .action(async (options) => {
    initWallet();
    if (options.address) {
      try {
        const balance = await wallet.getETHBalance(options.address);
        console.log(`ETH 余额: ${balance} ETH`);
      } catch (error) {
        console.error(chalk.red(`查询失败: ${error.message}`));
      }
    } else {
      console.log(chalk.red('请提供地址参数或使用交互模式'));
    }
  });

// 如果没有参数，显示帮助
if (process.argv.length === 2) {
  program.help();
}

program.parse();