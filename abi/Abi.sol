// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract ABIcoder {
    //使用abi编码
    function encodeUint(uint256 value) public pure returns (bytes memory) {
        //
        return abi.encode(value);
    }

    function encodeMultiple(
        uint num,
        string memory text
    ) public pure returns (bytes memory) {
       //
       return abi.encode(num, text);
    }

    //使用abi解码
    function decodeUint(bytes memory data) public pure returns (uint) {
        //
        return abi.decode(data,(uint));
    }

    function decodeMultiple(
        bytes memory data
    ) public pure returns (uint, string memory) {
        //
        return abi.decode(data,(uint,string));
    }
}