// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;


contract BaseERC20 {
    string public name; 
    string public symbol; 
    uint8 public decimals; 

    uint256 public totalSupply; 

    mapping (address => uint256) balances; 

    mapping (address => mapping (address => uint256)) allowances; 

    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);

    constructor() public {
        // write your code here
        // set name,symbol,decimals,totalSupply
        name = "BaseERC20";
        symbol = "BERC20";
        decimals = 18;
        totalSupply = 100000000*10**18;

        balances[msg.sender] = totalSupply;
    }

    function balanceOf(address _owner) public view returns (uint256 balance) {
        // write your code here
        balance = balances[_owner];

    }

    //取钱操作
    function transfer(address _to, uint256 _value) public returns (bool success) {
        // write your code here
        require(_to != address(0), "ERC20: transfer to the zero address");
        require(balances[msg.sender] >= _value, "ERC20: transfer amount exceeds balance");
        //转出的钱及时更新到合约钱包中
        balances[msg.sender] -= _value;
        //转出的钱同样要更新到对应转出地址的钱包中
        balances[_to] += _value;
        //在事件中同步本次操作
        emit Transfer(msg.sender, _to, _value);  
        return true;
    }

    //转账操作
    function transferFrom(address _from, address _to, uint256 _value) public returns (bool success) {
        // write your code here

        require(_to != address(0), "ERC20: transfer to the zero address");
        require(_value <= balances[_from] ,"ERC20: transfer amount exceeds balance");
        //超出授权数量的时候提示
        require(_value <= allowances[_from][msg.sender],"ERC20: transfer amount exceeds allowance");
        //转账与取钱逻辑一致，把发起人钱包数量减少
        balances[_from] -= _value;
        //转入者的钱包数量增加
        balances[_to] += _value;

        //更新转账记录
        allowances[_from][msg.sender] -= _value;

        emit Transfer(_from, _to, _value); 
        return true; 
    }

    function approve(address _spender, uint256 _value) public returns (bool success) {
        // write your code here
        require(_spender != address(0), "must be a address");
        //授权转账金额
        allowances[msg.sender][_spender] = _value;

        emit Approval(msg.sender, _spender, _value); 
        return true; 
    }

    function allowance(address _owner, address _spender) public view returns (uint256 remaining) {   
        // write your code here     
        remaining = allowances[_owner][_spender];
    }
}