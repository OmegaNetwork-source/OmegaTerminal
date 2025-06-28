// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract SimpleMiner {
    address public owner;
    mapping(address => uint256) public pendingRewards;
    mapping(address => uint256) public totalMined;
    mapping(address => uint256) public lastMineTime;
    
    uint256 public cooldownPeriod = 10 seconds;
    uint256 public totalRewardsDistributed;
    
    event BlockMined(address indexed miner, uint256 nonce, bytes32 solution, uint256 reward);
    event RewardsClaimed(address indexed miner, uint256 amount);
    
    constructor() {
        owner = msg.sender;
    }
    
    modifier onlyOwner() {
        require(msg.sender == owner, "Only owner can call this function");
        _;
    }
    
    // Mine a block - anyone can call this
    function mineBlock(uint256 nonce, bytes32 solution) external {
        require(block.timestamp >= lastMineTime[msg.sender] + cooldownPeriod, "Mining cooldown active");
        
        // Update last mine time
        lastMineTime[msg.sender] = block.timestamp;
        
        // Calculate reward based on probability
        uint256 reward = calculateReward(msg.sender, nonce, solution);
        
        if (reward > 0) {
            pendingRewards[msg.sender] += reward;
            totalMined[msg.sender] += reward;
            totalRewardsDistributed += reward;
        }
        
        emit BlockMined(msg.sender, nonce, solution, reward);
    }
    
    // Calculate reward with specified probability distribution
    function calculateReward(address miner, uint256 nonce, bytes32 solution) public view returns (uint256) {
        // Use deterministic but seemingly random hash
        bytes32 hash = keccak256(abi.encodePacked(miner, nonce, solution, block.number));
        uint256 randomValue = uint256(hash) % 10000; // 0-9999
        
        // Reward distribution:
        // 0.1% chance for max reward (1.0 OMEGA) - randomValue 0-9
        if (randomValue < 10) {
            return 1 ether; // 1.0 OMEGA
        }
        // 1% chance for medium reward (0.01 OMEGA) - randomValue 10-109
        else if (randomValue < 110) {
            return 0.01 ether; // 0.01 OMEGA
        }
        // 10% chance for small reward (0.001 OMEGA) - randomValue 110-1109
        else if (randomValue < 1110) {
            return 0.001 ether; // 0.001 OMEGA
        }
        // 30% chance for tiny reward (0.0001 OMEGA) - randomValue 1110-4109
        else if (randomValue < 4110) {
            return 0.0001 ether; // 0.0001 OMEGA
        }
        // 60% chance for no reward - randomValue 4110-9999
        else {
            return 0;
        }
    }
    
    // Claim pending rewards
    function claimRewards() external {
        uint256 amount = pendingRewards[msg.sender];
        require(amount > 0, "No rewards to claim");
        
        pendingRewards[msg.sender] = 0;
        
        // Transfer OMEGA to miner
        (bool success, ) = payable(msg.sender).call{value: amount}("");
        require(success, "Transfer failed");
        
        emit RewardsClaimed(msg.sender, amount);
    }
    
    // Claim pending rewards to a specified recipient
    function claimTo(address recipient) external {
        uint256 amount = pendingRewards[msg.sender];
        require(amount > 0, "No rewards to claim");
        pendingRewards[msg.sender] = 0;
        (bool success, ) = payable(recipient).call{value: amount}("");
        require(success, "Transfer failed");
        emit RewardsClaimed(recipient, amount);
    }
    
    // Get miner info
    function getMinerInfo(address miner) external view returns (
        uint256 _totalMined,
        uint256 _lastMineTime,
        uint256 _pendingRewards
    ) {
        return (
            totalMined[miner],
            lastMineTime[miner],
            pendingRewards[miner]
        );
    }
    
    // Owner functions
    function setCooldownPeriod(uint256 _cooldown) external onlyOwner {
        cooldownPeriod = _cooldown;
    }
    
    function withdrawExcess() external onlyOwner {
        uint256 balance = address(this).balance;
        require(balance > 0, "No balance to withdraw");
        
        (bool success, ) = payable(owner).call{value: balance}("");
        require(success, "Transfer failed");
    }
    
    // Receive function to accept OMEGA deposits
    receive() external payable {
        // Accept OMEGA deposits for rewards
    }
} 
