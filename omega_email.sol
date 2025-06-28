// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

/// @title Minimal ENS interface for resolving names to addresses
interface IOmegaENS {
    function resolve(string calldata name) external view returns (address);
}

/// @title Omega Direct Messenger with ENS support
contract OmegaDirectMessenger {
    IOmegaENS public ens;

    event DirectMessage(
        address indexed from,
        address indexed to,
        string message,
        uint256 timestamp
    );

    /// @notice Set the ENS contract address at deployment
    /// @param ensAddress The address of the deployed ENS contract
    constructor(address ensAddress) {
        require(ensAddress != address(0), "ENS address cannot be zero");
        ens = IOmegaENS(ensAddress);
    }

    /// @notice Send a direct message to an address or ENS name
    /// @param to The recipient's address (if not using ENS)
    /// @param ensName The recipient's ENS name (if using ENS, otherwise empty string)
    /// @param message The message content
    function sendMessage(address to, string calldata ensName, string calldata message) external {
        address recipient = to;
        if (recipient == address(0)) {
            require(bytes(ensName).length > 0, "ENS name required if address is zero");
            recipient = ens.resolve(ensName);
            require(recipient != address(0), "ENS name did not resolve");
        }
        require(bytes(message).length > 0, "Message cannot be empty");
        emit DirectMessage(msg.sender, recipient, message, block.timestamp);
    }
}
