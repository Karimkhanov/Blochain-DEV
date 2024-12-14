// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract DocumentSigning {
    address public owner;
    mapping(address => bool) public whitelist;
    mapping(address => uint256) public whitelistTimestamp; // Timestamp for whitelisting
    mapping(address => bool) public admins; // Admin roles
    uint256 public totalDocumentsSigned; // Document counter
    address[] public whitelistedAccounts;

    event WhitelistUpdated(address indexed account, bool isAdded);
    event DocumentSigned(address indexed signer, uint256 timestamp);
    event AdminUpdated(address indexed admin, bool isAdded);

    modifier onlyOwner() {
        require(msg.sender == owner, "Only the owner can perform this action");
        _;
    }

    modifier onlyAdmin() {
        require(admins[msg.sender] || msg.sender == owner, "Only an admin can perform this action");
        _;
    }

    constructor() {
        owner = msg.sender;
    }

    // Add an address to the whitelist with timestamp
    function addToWhitelist(address account) public onlyAdmin {
        require(!whitelist[account], "Address is already whitelisted");
        whitelist[account] = true;
        whitelistTimestamp[account] = block.timestamp; // Record timestamp
        whitelistedAccounts.push(account);
        emit WhitelistUpdated(account, true);
    }

    // Remove an address from the whitelist
    function removeFromWhitelist(address account) public onlyAdmin {
    require(whitelist[account], "Address is not whitelisted");
    whitelist[account] = false;

    // Remove the account from the whitelistedAccounts array
    for (uint256 i = 0; i < whitelistedAccounts.length; i++) {
        if (whitelistedAccounts[i] == account) {
            whitelistedAccounts[i] = whitelistedAccounts[whitelistedAccounts.length - 1]; // Replace with the last element
            whitelistedAccounts.pop(); // Remove the last element
            break;
        }
    }
    
    emit WhitelistUpdated(account, false);
}


    // Sign a document
    function signDocument() public {
        require(whitelist[msg.sender], "Caller is not whitelisted");
        totalDocumentsSigned += 1; // Increment document counter
        emit DocumentSigned(msg.sender, block.timestamp);
    }

    // Add an admin
    function addAdmin(address account) public onlyOwner {
        require(!admins[account], "Address is already an admin");
        admins[account] = true;
        emit AdminUpdated(account, true);
    }

    // Remove an admin
    function removeAdmin(address account) public onlyOwner {
        require(admins[account], "Address is not an admin");
        admins[account] = false;
        emit AdminUpdated(account, false);
    }

    // View all whitelisted accounts
    function getWhitelistedAccounts() public view returns (address[] memory) {
        return whitelistedAccounts;
    }
}
