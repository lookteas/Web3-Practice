// SPDX-License-Identifier: MIT
pragma solidity ^0.8.25;

import "./IPermit2.sol";

/**
 * @title Permit2
 * @dev 实现 Permit2 协议，支持 EIP-712 签名授权转账
 */
contract Permit2 is IPermit2 {
    bytes32 public constant PERMIT_DETAILS_TYPEHASH = keccak256("PermitDetails(address token,uint160 amount,uint48 expiration,uint48 nonce)");
    bytes32 public constant PERMIT_SINGLE_TYPEHASH = keccak256("PermitSingle(PermitDetails details,address spender,uint256 sigDeadline)PermitDetails(address token,uint160 amount,uint48 expiration,uint48 nonce)");
    
    bytes32 public immutable DOMAIN_SEPARATOR;
    
    // owner => token => spender => allowance details
    mapping(address => mapping(address => mapping(address => uint48))) public nonces;
    mapping(address => mapping(address => mapping(address => uint160))) private allowances;
    mapping(address => mapping(address => mapping(address => uint48))) private expirations;

    event Permit(
        address indexed owner,
        address indexed token,
        address indexed spender,
        uint160 amount,
        uint48 expiration,
        uint48 nonce
    );

    event NonceInvalidation(
        address indexed owner,
        address indexed token,
        address indexed spender,
        uint48 newNonce
    );

    constructor() {
        DOMAIN_SEPARATOR = keccak256(
            abi.encode(
                keccak256("EIP712Domain(string name,string version,uint256 chainId,address verifyingContract)"),
                keccak256("Permit2"),
                keccak256("1"),
                block.chainid,
                address(this)
            )
        );
    }

    function permit(
        address owner,
        PermitSingle memory permitSingle,
        bytes calldata signature
    ) external override {
        require(permitSingle.sigDeadline >= block.timestamp, "Signature expired");
        require(permitSingle.details.expiration >= block.timestamp, "Permit expired");
        
        bytes32 structHash = keccak256(
            abi.encode(
                PERMIT_SINGLE_TYPEHASH,
                keccak256(
                    abi.encode(
                        PERMIT_DETAILS_TYPEHASH,
                        permitSingle.details.token,
                        permitSingle.details.amount,
                        permitSingle.details.expiration,
                        permitSingle.details.nonce
                    )
                ),
                permitSingle.spender,
                permitSingle.sigDeadline
            )
        );
        
        bytes32 hash = keccak256(
            abi.encodePacked(
                "\x19\x01",
                DOMAIN_SEPARATOR,
                structHash
            )
        );
        
        address signer = _recoverSigner(hash, signature);
        require(signer == owner, "Invalid signature");
        require(nonces[owner][permitSingle.details.token][permitSingle.spender] == permitSingle.details.nonce, "Invalid nonce");
        
        // 更新 nonce
        nonces[owner][permitSingle.details.token][permitSingle.spender]++;
        
        // 设置授权
        allowances[owner][permitSingle.details.token][permitSingle.spender] = permitSingle.details.amount;
        expirations[owner][permitSingle.details.token][permitSingle.spender] = permitSingle.details.expiration;
        
        emit Permit(
            owner,
            permitSingle.details.token,
            permitSingle.spender,
            permitSingle.details.amount,
            permitSingle.details.expiration,
            permitSingle.details.nonce
        );
    }

    function transferFrom(
        address from,
        address to,
        uint160 amount,
        address token
    ) external override {
        uint160 allowedAmount = allowances[from][token][msg.sender];
        uint48 expiration = expirations[from][token][msg.sender];
        
        require(allowedAmount >= amount, "Insufficient allowance");
        require(expiration >= block.timestamp, "Allowance expired");
        
        // 减少授权额度
        allowances[from][token][msg.sender] = allowedAmount - amount;
        
        // 执行转账
        (bool success, ) = token.call(
            abi.encodeWithSignature("transferFrom(address,address,uint256)", from, to, amount)
        );
        require(success, "Transfer failed");
    }

    function transferFrom(
        AllowanceTransferDetails[] calldata transferDetails
    ) external override {
        for (uint256 i = 0; i < transferDetails.length; i++) {
            this.transferFrom(
                transferDetails[i].from,
                transferDetails[i].to,
                transferDetails[i].amount,
                transferDetails[i].token
            );
        }
    }

    function allowance(
        address owner,
        address token,
        address spender
    ) external view override returns (uint160 amount, uint48 expiration, uint48 nonce) {
        return (
            allowances[owner][token][spender],
            expirations[owner][token][spender],
            nonces[owner][token][spender]
        );
    }

    function invalidateNonce(
        address token,
        address spender,
        uint48 newNonce
    ) external override {
        require(newNonce > nonces[msg.sender][token][spender], "Nonce must be greater than current");
        nonces[msg.sender][token][spender] = newNonce;
        
        emit NonceInvalidation(msg.sender, token, spender, newNonce);
    }

    function _recoverSigner(bytes32 hash, bytes memory signature) internal pure returns (address) {
        require(signature.length == 65, "Invalid signature length");
        
        bytes32 r;
        bytes32 s;
        uint8 v;
        
        assembly {
            r := mload(add(signature, 32))
            s := mload(add(signature, 64))
            v := byte(0, mload(add(signature, 96)))
        }
        
        return ecrecover(hash, v, r, s);
    }
}