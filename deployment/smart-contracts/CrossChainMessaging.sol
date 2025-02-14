// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract CrossChainMessaging {
    event MessageSent(bytes32 indexed messageId, address sender, uint256 destinationChainId, bytes message);
    event MessageReceived(bytes32 indexed messageId, address sender, uint256 sourceChainId, bytes message);
    
    struct Message {
        address sender;
        uint256 sourceChainId;
        bytes message;
        bool processed;
    }
    
    mapping(bytes32 => Message) public messages;
    mapping(uint256 => address) public trustedRelayers;
    address public owner;
    
    constructor() {
        owner = msg.sender;
    }
    
    modifier onlyOwner() {
        require(msg.sender == owner, "Only owner can call this function");
        _;
    }
    
    modifier onlyTrustedRelayer(uint256 chainId) {
        require(trustedRelayers[chainId] == msg.sender, "Only trusted relayer can call this function");
        _;
    }
    
    function setTrustedRelayer(uint256 chainId, address relayer) external onlyOwner {
        trustedRelayers[chainId] = relayer;
    }
    
    function sendMessage(uint256 destinationChainId, bytes calldata message) external {
        bytes32 messageId = keccak256(abi.encodePacked(block.timestamp, msg.sender, destinationChainId, message));
        emit MessageSent(messageId, msg.sender, destinationChainId, message);
    }
    
    function receiveMessage(bytes32 messageId, address sender, uint256 sourceChainId, bytes calldata message) 
        external onlyTrustedRelayer(sourceChainId) 
    {
        require(!messages[messageId].processed, "Message already processed");
        
        messages[messageId] = Message({
            sender: sender,
            sourceChainId: sourceChainId,
            message: message,
            processed: true
        });
        
        emit MessageReceived(messageId, sender, sourceChainId, message);
    }
}
