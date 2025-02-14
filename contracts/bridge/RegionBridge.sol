// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import { IBridge } from "../interfaces/IBridge.sol";

contract RegionBridge is IBridge {
    error NotImplemented();
    
    function bridgeToken(address /* token */, uint256 /* amount */, uint256 /* targetChainId */) external pure {
        revert NotImplemented();
    }
    
    function claimToken(bytes32 /* txHash */) external pure {
        revert NotImplemented();
    }
    
    function verifyTransaction(bytes32 /* txHash */) external pure returns (bool) {
        return false;
    }

    function transfer(bytes32 /* to */, uint256 /* amount */) external payable {
        revert NotImplemented();
    }

    function validateTransfer(bytes32 /* from */, bytes32 /* to */, uint256 /* amount */, bytes[] calldata /* signatures */) external pure {
        revert NotImplemented();
    }

    function addValidator(address /* validator */) external pure {
        revert NotImplemented();
    }

    function removeValidator(address /* validator */) external pure {
        revert NotImplemented();
    }
}
