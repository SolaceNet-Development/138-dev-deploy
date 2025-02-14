// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import { IOracle } from "../interfaces/IOracle.sol";

contract Oracle is IOracle {
    error PriceNotAvailable(bytes32 asset);
    error NotAdmin();
    error NotAuthority();
    
    mapping(bytes32 => uint256) private prices;
    mapping(address => bool) public authorities;
    address public admin;

    constructor() {
        admin = msg.sender;
        authorities[msg.sender] = true;
    }

    modifier onlyAdmin() {
        if (msg.sender != admin) revert NotAdmin();
        _;
    }

    modifier onlyAuthority() {
        if (!authorities[msg.sender]) revert NotAuthority();
        _;
    }

    function updatePrice(bytes32 asset, uint256 price) external override onlyAuthority {
        prices[asset] = price;
        emit PriceUpdated(asset, price);
    }

    function getPrice(bytes32 asset) external view override returns (uint256) {
        if (prices[asset] == 0) revert PriceNotAvailable(asset);
        return prices[asset];
    }

    function addAuthority(address authority) external override onlyAdmin {
        authorities[authority] = true;
        emit AuthorityAdded(authority);
    }

    function removeAuthority(address authority) external override onlyAdmin {
        authorities[authority] = false;
        emit AuthorityRemoved(authority);
    }
}
