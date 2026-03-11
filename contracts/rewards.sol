// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";
import "@openzeppelin/contracts/utils/cryptography/MessageHashUtils.sol";
import "@openzeppelin/contracts/utils/Pausable.sol";

/**
 * @title MementoQuizRewards
 * @dev ERC-20 token for Memento Academy Quiz Game rewards
 * 
 * Security features:
 * - Only backend can sign valid rewards (signature verification)
 * - Each session can only claim once (nonce system)
 * - Minimum score requirement (80% = 8/10)
 * - Maximum score validation (<=10)
 * - Maximum supply cap to prevent unlimited minting
 * - Pausable for emergency stops
 * - Signature expiration to prevent stale claims
 * - Contract address in hash to prevent cross-contract replay
 * - No public mint function
 */
contract MementoQuizRewards is ERC20, Ownable, Pausable {
    using ECDSA for bytes32;
    using MessageHashUtils for bytes32;

    // Backend signer address (set during deployment)
    address public backendSigner;
    
    // Track claimed sessions to prevent double-claiming
    mapping(bytes32 => bool) public claimedSessions;
    
    // Reward amount: 10 MEMO tokens (with 18 decimals)
    uint256 public constant REWARD_AMOUNT = 10 * 10**18;
    
    // Maximum supply: 1 million MEMO tokens
    uint256 public constant MAX_SUPPLY = 1_000_000 * 10**18;
    
    // Minimum score required for reward (8 out of 10)
    uint256 public constant MIN_SCORE = 8;
    
    // Maximum possible score
    uint256 public constant MAX_SCORE = 10;
    
    // Events
    event RewardClaimed(
        address indexed user,
        bytes32 indexed sessionId,
        uint256 score,
        uint256 amount
    );
    event BackendSignerUpdated(address oldSigner, address newSigner);
    
    constructor(address _backendSigner) 
        ERC20("Memento Quiz Token", "MEMO") 
        Ownable(msg.sender) 
    {
        require(_backendSigner != address(0), "Invalid signer address");
        backendSigner = _backendSigner;
    }
    
    /**
     * @dev Claim reward for completing a quiz with high score
     * @param sessionId Unique session identifier from backend
     * @param score User's score (0-10)
     * @param deadline Timestamp after which the signature expires
     * @param signature Backend signature proving the claim is valid
     */
    function claimReward(
        bytes32 sessionId,
        uint256 score,
        uint256 deadline,
        bytes calldata signature
    ) external whenNotPaused {
        // Check signature hasn't expired
        require(block.timestamp <= deadline, "Signature expired");
        
        // Check session hasn't been claimed
        require(!claimedSessions[sessionId], "Reward already claimed");
        
        // Check score is within valid range
        require(score >= MIN_SCORE && score <= MAX_SCORE, "Invalid score");
        
        // Check max supply won't be exceeded
        require(totalSupply() + REWARD_AMOUNT <= MAX_SUPPLY, "Max supply reached");
        
        // Verify signature from backend
        // Includes address(this) to prevent cross-contract replay attacks
        bytes32 messageHash = keccak256(abi.encodePacked(
            msg.sender,
            sessionId,
            score,
            deadline,
            block.chainid,
            address(this)
        ));
        bytes32 ethSignedHash = messageHash.toEthSignedMessageHash();
        address signer = ethSignedHash.recover(signature);
        
        require(signer == backendSigner, "Invalid signature");
        
        // Mark session as claimed
        claimedSessions[sessionId] = true;
        
        // Mint reward tokens
        _mint(msg.sender, REWARD_AMOUNT);
        
        emit RewardClaimed(msg.sender, sessionId, score, REWARD_AMOUNT);
    }
    
    /**
     * @dev Update backend signer (only owner)
     */
    function setBackendSigner(address _newSigner) external onlyOwner {
        require(_newSigner != address(0), "Invalid signer address");
        emit BackendSignerUpdated(backendSigner, _newSigner);
        backendSigner = _newSigner;
    }
    
    /**
     * @dev Pause the contract (only owner)
     * Use in case of emergency or discovered vulnerability
     */
    function pause() external onlyOwner {
        _pause();
    }
    
    /**
     * @dev Unpause the contract (only owner)
     */
    function unpause() external onlyOwner {
        _unpause();
    }
    
    /**
     * @dev Check if a session has been claimed
     */
    function isSessionClaimed(bytes32 sessionId) external view returns (bool) {
        return claimedSessions[sessionId];
    }
    
    /**
     * @dev Get remaining mintable supply
     */
    function remainingSupply() external view returns (uint256) {
        return MAX_SUPPLY - totalSupply();
    }
}
