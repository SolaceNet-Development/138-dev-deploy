// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import { IBridge } from "../interfaces/IBridge.sol";
import { IOracle } from "../interfaces/IOracle.sol";

contract RegionBridge is IBridge {
    // Implementation will be added later
    function bridgeToken(address token, uint256 amount, uint256 targetChainId) external override {
        revert("Not implemented");
    }
    
    function claimToken(bytes32 txHash) external override {
        revert("Not implemented");
    }
    
    function verifyTransaction(bytes32 txHash) external view override returns (bool) {
        return false;
    }
}
