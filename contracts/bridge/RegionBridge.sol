// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import { IBridge } from "../interfaces/IBridge.sol";

contract RegionBridge is IBridge {
    error NotImplemented();
    
    function bridgeToken(address token, uint256 amount, uint256 targetChainId) external {
        revert NotImplemented();
    }
    
    function claimToken(bytes32 txHash) external {
        revert NotImplemented();
    }
    
    function verifyTransaction(bytes32 txHash) external view returns (bool) {
        return false;
    }

    function transfer(bytes32 to, uint256 amount) external {
        revert NotImplemented();
    }

    function validateTransfer(bytes32 from, bytes32 to, uint256 amount, bytes[] calldata signatures) external {
        revert NotImplemented();
    }

    function addValidator(address validator) external {
        revert NotImplemented();
    }

    function removeValidator(address validator) external {
        revert NotImplemented();
    }
}
