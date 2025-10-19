// SPDX-License-Identifier: MIT
pragma solidity ^0.8.25;

import "./ITokenReceiver.sol";

/**
 * @title ERC20Token
 * @dev 实现了 ERC20 标准的代币合约，支持 EIP-2612 Permit 功能
 */
contract ERC20Token {
    string public name = "SuiToken";
    string public symbol = "SUI";
    uint8 public decimals = 18;
    uint256 public totalSupply = 100000000 * 10**decimals; // 1亿代币
    
    mapping(address => uint256) public balanceOf;
    mapping(address => mapping(address => uint256)) public allowance;
    
    // EIP-2612 Permit 相关
    mapping(address => uint256) public nonces;
    bytes32 public DOMAIN_SEPARATOR;
    bytes32 public constant PERMIT_TYPEHASH = keccak256("Permit(address owner,address spender,uint256 value,uint256 nonce,uint256 deadline)");

    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);

    constructor() {
        balanceOf[msg.sender] = totalSupply;
        
        // 初始化 EIP-712 域分隔符
        DOMAIN_SEPARATOR = keccak256(
            abi.encode(
                keccak256("EIP712Domain(string name,string version,uint256 chainId,address verifyingContract)"),
                keccak256(bytes(name)),
                keccak256(bytes("1")),
                block.chainid,
                address(this)
            )
        );
    }

    function transfer(address _to, uint256 _value) public returns (bool success) {
        require(balanceOf[msg.sender] >= _value, "Insufficient balance");
        require(_to != address(0), "Cannot transfer to zero address");
        
        balanceOf[msg.sender] -= _value;
        balanceOf[_to] += _value;
        
        emit Transfer(msg.sender, _to, _value);
        return true;
    }

    function approve(address _spender, uint256 _value) public returns (bool success) {
        allowance[msg.sender][_spender] = _value;
        emit Approval(msg.sender, _spender, _value);
        return true;
    }

    function transferFrom(address _from, address _to, uint256 _value) public returns (bool success) {
        require(balanceOf[_from] >= _value, "Insufficient balance");
        require(allowance[_from][msg.sender] >= _value, "Insufficient allowance");
        require(_to != address(0), "Cannot transfer to zero address");
        
        balanceOf[_from] -= _value;
        balanceOf[_to] += _value;
        allowance[_from][msg.sender] -= _value;
        
        emit Transfer(_from, _to, _value);
        return true;
    }

    function transferWithCallback(address _to, uint256 _value) public returns (bool success) {
        require(transfer(_to, _value), "Transfer failed");
        
        // 检查接收方是否是合约
        if (_to.code.length > 0) {
            try ITokenReceiver(_to).tokensReceived(msg.sender, _value, "") {
                // 回调成功
            } catch {
                // 回调失败，但转账已经完成
            }
        }
        
        return true;
    }

    /**
     * @dev EIP-2612 permit 函数
     */
    function permit(
        address owner,
        address spender,
        uint256 value,
        uint256 deadline,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external {
        require(deadline >= block.timestamp, "Permit expired");
        
        bytes32 structHash = keccak256(
            abi.encode(
                PERMIT_TYPEHASH,
                owner,
                spender,
                value,
                nonces[owner]++,
                deadline
            )
        );
        
        bytes32 hash = keccak256(
            abi.encodePacked(
                "\x19\x01",
                DOMAIN_SEPARATOR,
                structHash
            )
        );
        
        address signer = ecrecover(hash, v, r, s);
        require(signer == owner, "Invalid signature");
        
        allowance[owner][spender] = value;
        emit Approval(owner, spender, value);
    }
}