// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract OmegaMixerFlexible {
    uint256 public round = 1;
    uint256 public usersInRound = 0;
    uint256 public requiredUsers = 3; // Set for demo, increase for more privacy

    struct Deposit {
        uint256 round;
        uint256 amount;
        bool withdrawn;
    }

    mapping(bytes32 => Deposit) public deposits;

    event DepositMade(bytes32 indexed commitment, uint256 round, uint256 amount);
    event Withdrawn(address indexed to, uint256 amount);

    // Accept any positive deposit amount
    function deposit(bytes32 commitment) external payable {
        require(msg.value > 0, "Deposit must be greater than zero");
        require(deposits[commitment].amount == 0, "Commitment already used");

        deposits[commitment] = Deposit(round, msg.value, false);
        usersInRound += 1;

        emit DepositMade(commitment, round, msg.value);

        if (usersInRound >= requiredUsers) {
            round += 1;
            usersInRound = 0;
        }
    }

    function withdraw(bytes32 secret, address payable to) external {
        bytes32 commitment = keccak256(abi.encodePacked(secret));
        Deposit storage dep = deposits[commitment];
        require(dep.amount > 0, "No deposit found");
        require(!dep.withdrawn, "Already withdrawn");
        dep.withdrawn = true;
        to.transfer(dep.amount);
        emit Withdrawn(to, dep.amount);
    }
}
