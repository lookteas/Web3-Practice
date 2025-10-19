// SPDX-License-Identifier: MIT
pragma solidity ^0.8.25;

/**
 * @title IPermit2
 * @dev Permit2 合约接口，用于 EIP-712 签名授权转账
 */
interface IPermit2 {
    struct PermitDetails {
        address token;
        uint160 amount;
        uint48 expiration;
        uint48 nonce;
    }

    struct PermitSingle {
        PermitDetails details;
        address spender;
        uint256 sigDeadline;
    }

    struct PermitBatch {
        PermitDetails[] details;
        address spender;
        uint256 sigDeadline;
    }

    struct AllowanceTransferDetails {
        address from;
        address to;
        uint160 amount;
        address token;
    }

    function permit(
        address owner,
        PermitSingle memory permitSingle,
        bytes calldata signature
    ) external;

    function transferFrom(
        address from,
        address to,
        uint160 amount,
        address token
    ) external;

    function transferFrom(
        AllowanceTransferDetails[] calldata transferDetails
    ) external;

    function allowance(
        address owner,
        address token,
        address spender
    ) external view returns (uint160 amount, uint48 expiration, uint48 nonce);

    function invalidateNonce(
        address token,
        address spender,
        uint48 newNonce
    ) external;

    function DOMAIN_SEPARATOR() external view returns (bytes32);
}