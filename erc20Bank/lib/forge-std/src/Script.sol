// SPDX-License-Identifier: MIT
pragma solidity ^0.8.25;

import "./console.sol";

abstract contract Script {
    // Script utilities
    
    // VM interface for scripts
    function vm() internal pure returns (Vm) {
        return Vm(address(uint160(uint256(keccak256("hevm cheat code")))));
    }
}

// VM interface for scripting
interface Vm {
    function startBroadcast() external;
    function startBroadcast(uint256) external;
    function stopBroadcast() external;
    function addr(uint256) external returns (address);
    function envUint(string memory) external returns (uint256);
    function expectRevert(string memory) external;
}