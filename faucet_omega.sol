// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract OmegaFaucet {
    
    // Simple ownable
    address private _owner;
    
    modifier onlyOwner() {
        require(msg.sender == _owner, "Not owner");
        _;
    }
    
    // Claim tracking
    mapping(address => uint256) public lastClaimTime;
    uint256 public constant CLAIM_AMOUNT = 1 ether; // 1 OMEGA token
    uint256 public constant CLAIM_COOLDOWN = 24 hours; // 24 hour cooldown
    
    // Contract state
    uint256 public totalClaims;
    uint256 public faucetBalance;
    
    // Events
    event TokensClaimed(address indexed user, uint256 amount, uint256 timestamp);
    event FaucetRefilled(uint256 amount);
    
    constructor() {
        _owner = msg.sender;
    }
    
    // Claim 5 OMEGA tokens (once every 24 hours)
    function claim() external {
        require(faucetBalance >= CLAIM_AMOUNT, "Faucet empty");
        require(canClaim(msg.sender), "Claim cooldown active");
        
        // Update claim tracking
        lastClaimTime[msg.sender] = block.timestamp;
        totalClaims++;
        
        // Update contract state
        faucetBalance -= CLAIM_AMOUNT;
        
        // Transfer tokens
        payable(msg.sender).transfer(CLAIM_AMOUNT);
        
        emit TokensClaimed(msg.sender, CLAIM_AMOUNT, block.timestamp);
    }
    
    // Check if user can claim
    function canClaim(address user) public view returns (bool) {
        uint256 lastClaim = lastClaimTime[user];
        return lastClaim == 0 || block.timestamp >= lastClaim + CLAIM_COOLDOWN;
    }
    
    // Get time until next claim is available
    function getTimeUntilNextClaim(address user) public view returns (uint256) {
        uint256 lastClaim = lastClaimTime[user];
        if (lastClaim == 0) {
            return 0; // Can claim immediately
        }
        
        uint256 nextClaimTime = lastClaim + CLAIM_COOLDOWN;
        if (block.timestamp >= nextClaimTime) {
            return 0; // Can claim now
        }
        
        return nextClaimTime - block.timestamp;
    }
    
    // Get user's claim info
    function getClaimInfo(address user) external view returns (
        bool canClaimNow,
        uint256 lastClaim,
        uint256 timeUntilNextClaim,
        uint256 claimAmount
    ) {
        canClaimNow = canClaim(user);
        lastClaim = lastClaimTime[user];
        timeUntilNextClaim = getTimeUntilNextClaim(user);
        claimAmount = CLAIM_AMOUNT;
    }
    
    // Owner functions
    function refillFaucet() external payable onlyOwner {
        faucetBalance += msg.value;
        emit FaucetRefilled(msg.value);
    }
    
    function withdrawFaucet() external onlyOwner {
        uint256 amount = faucetBalance;
        faucetBalance = 0;
        payable(_owner).transfer(amount);
    }
    
    function getFaucetBalance() external view returns (uint256) {
        return faucetBalance;
    }
    
    // Emergency functions
    function emergencyWithdraw() external onlyOwner {
        uint256 balance = address(this).balance;
        payable(_owner).transfer(balance);
        faucetBalance = 0;
    }
    
    // Fallback function to receive ETH
    receive() external payable {
        faucetBalance += msg.value;
    }
} 
