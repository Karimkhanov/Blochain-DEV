// SPDX-License-Identifier: MIT
pragma solidity ^0.8.26;

// Import OpenZeppelin's library for working with Merkle Trees
import "@openzeppelin/contracts/utils/cryptography/MerkleProof.sol";

/**
 * @title MerkleDocumentSigning
 * @dev A contract that manages a whitelist using Merkle Trees and manual mapping.
 *      Whitelisted users can sign documents, and admins can manage accounts.
 */
contract MerkleDocumentSigning {
    // Owner of the contract
    address public owner;

    // Root of the Merkle Tree
    bytes32 public merkleRoot;

    // Mapping to track manual whitelist (added by admins)
    mapping(address => bool) public manualWhitelist;

    // Mapping to track admins
    mapping(address => bool) public admins;

    // Mapping to track whitelisted accounts' timestamps
    mapping(address => uint256) public whitelistTimestamp;

    // List of all whitelisted accounts
    address[] public whitelistedAccounts;

    // Total signed documents counter
    uint256 public totalDocumentsSigned;

    // Events for transparency
    event DocumentSigned(address indexed signer, uint256 timestamp);
    event AdminUpdated(address indexed admin, bool isAdded);
    event MerkleRootUpdated(bytes32 newRoot);
    event AccountWhitelisted(address indexed account, uint256 timestamp);

    // Modifier to restrict access to owner
    modifier onlyOwner() {
        require(msg.sender == owner, "Only the owner can perform this action");
        _;
    }

    // Modifier to restrict access to admins or owner
    modifier onlyAdmin() {
        require(
            admins[msg.sender] || msg.sender == owner,
            "Only an admin can perform this action"
        );
        _;
    }

    /**
     * @dev Constructor initializes the owner and Merkle Root.
     * @param _merkleRoot Initial Merkle Root.
     */
    constructor(bytes32 _merkleRoot) {
        owner = msg.sender;
        merkleRoot = _merkleRoot;
    }

    /**
     * @dev Updates the Merkle Root and resets whitelist tracking.
     * @param _newRoot The new Merkle Root.
     * @notice Resets the manual whitelist and whitelistedAccounts list, but retains manual whitelisted accounts.
     */
    function updateMerkleRoot(bytes32 _newRoot) public onlyAdmin {
        merkleRoot = _newRoot;

        // Reset all manual whitelist mappings if root changes
        for (uint256 i = 0; i < whitelistedAccounts.length; i++) {
            manualWhitelist[whitelistedAccounts[i]] = false;
        }

        // Clear the list of whitelisted accounts
        delete whitelistedAccounts;

        // Re-add manually whitelisted accounts back to whitelistedAccounts
        for (uint256 i = 0; i < whitelistedAccounts.length; i++) {
            if (manualWhitelist[whitelistedAccounts[i]]) {
                whitelistedAccounts.push(whitelistedAccounts[i]);
            }
        }

        // Emit the Merkle Root updated event
        emit MerkleRootUpdated(_newRoot);
    }

    /**
     * @dev Verifies if an account is whitelisted using Merkle Proof or manual mapping.
     * @param proof Merkle Proof provided by the user.
     * @param account Address to verify.
     * @return bool Returns true if the address is whitelisted.
     */
    function isWhitelisted(bytes32[] calldata proof, address account)
        public
        view
        returns (bool)
    {
        // Check if the account is in the manual whitelist
        if (manualWhitelist[account]) {
            return true;
        }

        // Check if the account is in the Merkle Tree
        bytes32 leaf = keccak256(abi.encodePacked(account));
        return MerkleProof.verify(proof, merkleRoot, leaf);
    }

    /**
     * @dev Whitelist and track the caller if verified using a Merkle Proof.
     * @param proof Merkle Proof.
     */
    function whitelistAndTrack(bytes32[] calldata proof) public {
        require(isWhitelisted(proof, msg.sender), "Caller is not whitelisted");

        // Track timestamp and add to whitelisted accounts if not already added
        if (whitelistTimestamp[msg.sender] == 0) {
            whitelistTimestamp[msg.sender] = block.timestamp;
            whitelistedAccounts.push(msg.sender);
            emit AccountWhitelisted(msg.sender, block.timestamp);
        }
    }

    /**
     * @dev Sign a document if the caller is whitelisted.
     * @param proof Merkle Proof.
     */
    function signDocument(bytes32[] calldata proof) public {
        require(isWhitelisted(proof, msg.sender), "Caller is not whitelisted");

        // Increment the total signed document count
        totalDocumentsSigned += 1;

        // Emit an event for signing the document
        emit DocumentSigned(msg.sender, block.timestamp);
    }

    /**
     * @dev Add an admin account.
     * @param account Address to grant admin rights.
     */
    function addAdmin(address account) public onlyOwner {
        require(!admins[account], "Address is already an admin");
        admins[account] = true;
        emit AdminUpdated(account, true);
    }

    /**
     * @dev Remove an admin account.
     * @param account Address to revoke admin rights.
     */
    function removeAdmin(address account) public onlyOwner {
        require(admins[account], "Address is not an admin");
        admins[account] = false;
        emit AdminUpdated(account, false);
    }

    /**
     * @dev Add an account to the manual whitelist.
     * @param account Address to whitelist.
     */
    function addToWhitelist(address account) public onlyAdmin {
        require(
            !manualWhitelist[account],
            "Address is already manually whitelisted"
        );

        // Mark the account as whitelisted
        manualWhitelist[account] = true;

        // Track timestamp and add to whitelisted accounts
        if (whitelistTimestamp[account] == 0) {
            whitelistTimestamp[account] = block.timestamp;
            whitelistedAccounts.push(account);
        }

        emit AccountWhitelisted(account, block.timestamp);
    }

    /**
     * @dev Get all whitelisted accounts.
     * @return address[] Array of whitelisted accounts.
     */
    function getWhitelistedAccounts() public view returns (address[] memory) {
        return whitelistedAccounts;
    }

    /**
     * @dev Add multiple accounts to the manual whitelist at once.
     * @param accounts Array of addresses to whitelist.
     */
    function addMultipleToWhitelist(address[] calldata accounts)
        public
        onlyAdmin
    {
        for (uint256 i = 0; i < accounts.length; i++) {
            address account = accounts[i];

            if (!manualWhitelist[account]) {
                manualWhitelist[account] = true;

                if (whitelistTimestamp[account] == 0) {
                    whitelistTimestamp[account] = block.timestamp;
                    whitelistedAccounts.push(account);
                    emit AccountWhitelisted(account, block.timestamp);
                }
            }
        }
    }
    // ["0x51EC0b1edE1BBeadD345964f0Ccc34F35F25E8d1","0xcD7Cb01BC3C62E5c5eF22f17e81E269E75f9909A"]
}
