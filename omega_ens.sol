// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract OmegaENS {
    mapping(string => address) public names;

    event NameRegistered(string indexed name, address indexed owner);

    function register(string calldata name) external {
        require(names[name] == address(0), "Name already taken");
        names[name] = msg.sender;
        emit NameRegistered(name, msg.sender);
    }

    function resolve(string calldata name) external view returns (address) {
        return names[name];
    }

    function transfer(string calldata name, address newOwner) external {
        require(names[name] == msg.sender, "Not name owner");
        names[name] = newOwner;
    }
}
