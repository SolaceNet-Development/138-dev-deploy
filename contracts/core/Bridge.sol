// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import { IBridge } from "../interfaces/IBridge.sol";
import { IOracle } from "../interfaces/IOracle.sol";
import { IERC20 } from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import { AccessControl } from "@openzeppelin/contracts/access/AccessControl.sol";

contract Bridge is IBridge, AccessControl {
    bytes32 public constant VALIDATOR_ROLE = keccak256("VALIDATOR_ROLE");
    
    IOracle public oracle;
    uint256 public required;
    bool public paused;
    uint256 public transferLimit;
    mapping(bytes32 => bool) public processedTransfers;
    mapping(address => bool) public supportedTokens;
    uint256 public emergencyTimelock;
    bool public emergencyMode;
    uint256 public fee;
    mapping(bytes32 => uint256) public nonces;
    mapping(address => uint256) public collectedFees;

    event TransferLimitUpdated(uint256 newLimit);
    event BridgePaused(address indexed by);
    event BridgeUnpaused(address indexed by);
    event TokenAdded(address indexed token);
    event TokenRemoved(address indexed token);
    event EmergencyModeEnabled(uint256 timelock);
    event EmergencyModeDisabled();
    event FeeUpdated(uint256 newFee);
    event FeeCollected(address token, uint256 amount);
    event FeesWithdrawn(address token, address recipient, uint256 amount);

    error TransferPaused();
    error TransferLimitExceeded();
    error TransferAlreadyProcessed();
    error InvalidAmount();
    error UnsupportedToken();
    error EmergencyModeLocked();
    error NotInEmergencyMode();
    error BatchLimitExceeded();
    error InsufficientFee();
    error InvalidNonce();
    error FeeWithdrawalFailed();
    error InvalidSignature();
    error DuplicateValidator();
    error ValidationFailed();
    error ValidationExpired();
    error CacheNotFound();
    error InvalidSignatureLength(uint256 length);
    error InvalidSignatureV(uint8 v);
    error ArrayLengthMismatch();

    // Add validation cache
    mapping(bytes32 => mapping(address => bool)) private validationCache;
    uint256 private constant MAX_CACHE_AGE = 1 hours;
    mapping(bytes32 => uint256) public validationTimestamps;

    constructor(address _oracle, uint256 _required) {
        oracle = IOracle(_oracle);
        required = _required;
        transferLimit = 1000 ether; // Default limit
        fee = 0.001 ether; // Default fee of 0.001 ETH
        _grantRole(DEFAULT_ADMIN_ROLE, msg.sender);
    }

    modifier whenNotPaused() {
        if (paused) revert TransferPaused();
        _;
    }

    function transfer(bytes32 to, uint256 amount) external payable override whenNotPaused {
        if (msg.value < fee) revert InsufficientFee();
        if (amount == 0) revert InvalidAmount();
        if (amount > transferLimit) revert TransferLimitExceeded();

        bytes32 sender = bytes32(uint256(uint160(msg.sender)));
        uint256 currentNonce = nonces[sender];
        nonces[sender] = currentNonce + 1;
        collectedFees[address(0)] += msg.value;
        
        emit Transfer(sender, to, amount);
    }

    function _validateTransfer(
        bytes32 from,
        bytes32 to,
        uint256 amount,
        bytes[] calldata signatures
    ) internal whenNotPaused {
        bytes32 messageHash = keccak256(abi.encodePacked(from, to, amount));
        
        if (processedTransfers[messageHash]) revert TransferAlreadyProcessed();
        if (amount > transferLimit) revert TransferLimitExceeded();

        uint256 validCount;
        address[] memory uniqueSigners = new address[](signatures.length);

        unchecked {
            for (uint256 i = 0; i < signatures.length; i++) {
                address signer = recoverSigner(messageHash, signatures[i]);
                
                if (!hasRole(VALIDATOR_ROLE, signer)) revert InvalidSignature();
                if (isValidationCached(messageHash, signer)) continue;
                
                for (uint256 j = 0; j < validCount; j++) {
                    if (uniqueSigners[j] == signer) revert DuplicateValidator();
                }
                
                uniqueSigners[validCount] = signer;
                cacheValidation(messageHash, signer);
                validCount++;
            }
        }

        if (validCount < required) revert ValidationFailed();
        
        // Update nonce and mark transfer as processed atomically
        uint256 currentNonce = nonces[from];
        uint256 expectedNonce = currentNonce + 1;
        nonces[from] = expectedNonce;
        processedTransfers[messageHash] = true;
        
        emit Transfer(from, to, amount);
    }

    function recoverSigner(bytes32 message, bytes memory signature) internal pure returns (address) {
        bytes32 r;
        bytes32 s;
        uint8 v;

        if (signature.length != 65) revert InvalidSignatureLength(signature.length);

        assembly {
            r := mload(add(signature, 32))
            s := mload(add(signature, 64))
            v := byte(0, mload(add(signature, 96)))
        }

        if (v < 27) v += 27;
        if (v != 27 && v != 28) revert InvalidSignatureV(v);

        return ecrecover(
            keccak256(abi.encodePacked("\x19Ethereum Signed Message:\n32", message)),
            v,
            r,
            s
        );
    }

    function addValidator(address validator) external override onlyRole(DEFAULT_ADMIN_ROLE) {
        _grantRole(VALIDATOR_ROLE, validator);
        emit ValidatorAdded(validator);
    }

    function removeValidator(address validator) external override onlyRole(DEFAULT_ADMIN_ROLE) {
        _revokeRole(VALIDATOR_ROLE, validator);
        emit ValidatorRemoved(validator);
    }

    function setTransferLimit(uint256 _limit) external onlyRole(DEFAULT_ADMIN_ROLE) {
        transferLimit = _limit;
        emit TransferLimitUpdated(_limit);
    }

    function setFee(uint256 _fee) external onlyRole(DEFAULT_ADMIN_ROLE) {
        fee = _fee;
        emit FeeUpdated(_fee);
    }

    function withdrawFees(address token, address recipient) external onlyRole(DEFAULT_ADMIN_ROLE) {
        uint256 amount = collectedFees[token];
        if (amount == 0) revert FeeWithdrawalFailed();
        
        collectedFees[token] = 0;
        
        if (token == address(0)) {
            (bool success, ) = payable(recipient).call{value: amount}("");
            if (!success) revert FeeWithdrawalFailed();
        } else {
            IERC20(token).transfer(recipient, amount);
        }
        
        emit FeesWithdrawn(token, recipient, amount);
    }

    function pause() external onlyRole(DEFAULT_ADMIN_ROLE) {
        paused = true;
        emit BridgePaused(msg.sender);
    }

    function unpause() external onlyRole(DEFAULT_ADMIN_ROLE) {
        paused = false;
        emit BridgeUnpaused(msg.sender);
    }

    function addSupportedToken(address token) external onlyRole(DEFAULT_ADMIN_ROLE) {
        supportedTokens[token] = true;
        emit TokenAdded(token);
    }

    function removeSupportedToken(address token) external onlyRole(DEFAULT_ADMIN_ROLE) {
        supportedTokens[token] = false;
        emit TokenRemoved(token);
    }

    function cacheValidation(bytes32 messageHash, address validator) internal {
        validationCache[messageHash][validator] = true;
        validationTimestamps[messageHash] = block.timestamp;
    }

    function isValidationCached(bytes32 messageHash, address validator) internal view returns (bool) {
        if (block.timestamp > validationTimestamps[messageHash] + MAX_CACHE_AGE) {
            return false;
        }
        return validationCache[messageHash][validator];
    }

    function enableEmergencyMode() external onlyRole(DEFAULT_ADMIN_ROLE) {
        emergencyMode = true;
        emergencyTimelock = block.timestamp + 24 hours;
        emit EmergencyModeEnabled(emergencyTimelock);
    }

    function disableEmergencyMode() external onlyRole(DEFAULT_ADMIN_ROLE) {
        if (block.timestamp < emergencyTimelock) revert EmergencyModeLocked();
        emergencyMode = false;
        emit EmergencyModeDisabled();
    }

    function emergencyRecovery(
        address token,
        address recipient,
        uint256 amount
    ) external onlyRole(DEFAULT_ADMIN_ROLE) {
        if (!emergencyMode) revert NotInEmergencyMode();
        if (block.timestamp < emergencyTimelock) revert EmergencyModeLocked();
        
        if (token == address(0)) {
            payable(recipient).transfer(amount);
        } else {
            IERC20(token).transfer(recipient, amount);
        }
    }

    function validateTransfer(
        bytes32 from,
        bytes32 to,
        uint256 amount,
        bytes[] calldata signatures
    ) external override whenNotPaused {
        _validateTransfer(from, to, amount, signatures);
    }

    function batchValidateTransfers(
        bytes32[] calldata froms,
        bytes32[] calldata tos,
        uint256[] calldata amounts,
        bytes[][] calldata signatures
    ) external whenNotPaused {
        uint256 length = froms.length;
        if (length > 20) revert BatchLimitExceeded();
        if (length != tos.length || length != amounts.length || length != signatures.length) 
            revert ArrayLengthMismatch();

        unchecked {
            for(uint256 i = 0; i < length; i++) {
                _validateTransfer(froms[i], tos[i], amounts[i], signatures[i]);
            }
        }
    }
}
