// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface IDiamondCut {
    enum FacetCutAction {Add, Replace, Remove}
    
    struct FacetCut {
        address facetAddress;
        FacetCutAction action;
        bytes4[] functionSelectors;
    }

    function diamondCut(
        FacetCut[] calldata _diamondCut,
        address _init,
        bytes calldata _calldata
    ) external;
}

contract DiamondProxy {
    bytes32 constant DIAMOND_STORAGE_POSITION = keccak256("diamond.standard.diamond.storage");
    
    struct FacetAddressAndPosition {
        address facetAddress;
        uint96 functionSelectorPosition;
    }

    struct DiamondStorage {
        mapping(bytes4 => FacetAddressAndPosition) selectorToFacetAndPosition;
        mapping(address => bool) facetAddresses;
        bytes4[] selectors;
    }
    
    constructor(address _contractOwner, address _diamondCutFacet) {
        require(_contractOwner != address(0), "Diamond: owner can't be zero address");
        DiamondStorage storage ds = diamondStorage();
        ds.facetAddresses[_diamondCutFacet] = true;
    }

    function diamondStorage() internal pure returns (DiamondStorage storage ds) {
        bytes32 position = DIAMOND_STORAGE_POSITION;
        assembly {
            ds.slot := position
        }
    }

    fallback() external payable {
        DiamondStorage storage ds = diamondStorage();
        address facet = ds.selectorToFacetAndPosition[msg.sig].facetAddress;
        require(facet != address(0), "Diamond: function does not exist");
        assembly {
            calldatacopy(0, 0, calldatasize())
            let result := delegatecall(gas(), facet, 0, calldatasize(), 0, 0)
            returndatacopy(0, 0, returndatasize())
            switch result
            case 0 {revert(0, returndatasize())}
            default {return(0, returndatasize())}
        }
    }

    receive() external payable {}
}
