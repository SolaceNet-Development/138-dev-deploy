// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface IERC20 {
    function totalSupply() external view returns (uint256);
    function balanceOf(address account) external view returns (uint256);
    function transfer(address recipient, uint256 amount) external returns (bool);
    function allowance(address owner, address spender) external view returns (uint256);
    function approve(address spender, uint256 amount) external returns (bool);
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);
}

contract TokenizedVault {
    IERC20 public immutable asset;
    uint256 public totalAssets;
    mapping(address => uint256) public balanceOf;
    
    constructor(address _asset) {
        asset = IERC20(_asset);
    }
    
    function deposit(uint256 assets, address receiver) public returns (uint256 shares) {
        require(assets > 0, "Cannot deposit 0 assets");
        shares = assets;  // 1:1 ratio for simplicity
        
        asset.transferFrom(msg.sender, address(this), assets);
        balanceOf[receiver] += shares;
        totalAssets += assets;
    }
    
    function withdraw(uint256 shares, address receiver, address owner) public returns (uint256 assets) {
        require(shares > 0, "Cannot withdraw 0 shares");
        require(balanceOf[owner] >= shares, "Insufficient balance");
        
        assets = shares;  // 1:1 ratio for simplicity
        balanceOf[owner] -= shares;
        totalAssets -= assets;
        
        asset.transfer(receiver, assets);
    }
}
