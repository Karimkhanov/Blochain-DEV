// SPDX-License-Identifier: MIT
pragma solidity ^0.8.26;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

contract Airdrop {
    // Token to be airdropped (ERC20 token)
    IERC20 public token;

    // Owner of the contract
    address public owner;

    // Mapping to track token amounts assigned to recipients
    mapping(address => uint256) public airdropAmounts;

    // Events for transparency
    event AirdropDistributed(address indexed recipient, uint256 amount);
    event TokensClaimed(address indexed recipient, uint256 amount);
    event AirdropAssigned(address indexed recipient, uint256 amount);
    event TokensDeposited(address indexed depositor, uint256 amount);

    // Modifier to restrict access to the owner
    modifier onlyOwner() {
        require(msg.sender == owner, "Only the owner can perform this action");
        _;
    }

    /**
     * @dev Constructor sets the token and owner.
     * @param _token Address of the token contract.
     */
    constructor(address _token) {
        token = IERC20(_token);
        owner = msg.sender;
    }

    /**
     * @dev Assign tokens to multiple addresses for claiming later.
     * @param recipients Array of recipient addresses.
     * @param amounts Array of token amounts corresponding to recipients.
     */
    function assignAirdrop(address[] calldata recipients, uint256[] calldata amounts) external onlyOwner {
        require(recipients.length == amounts.length, "Recipients and amounts must have the same length");
        for (uint256 i = 0; i < recipients.length; i++) {
            airdropAmounts[recipients[i]] += amounts[i];
            emit AirdropAssigned(recipients[i], amounts[i]);
        }
    }

    /**
     * @dev Distribute tokens to multiple addresses in one transaction.
     * @param recipients Array of recipient addresses.
     * @param amounts Array of token amounts corresponding to recipients.
     */
    function distributeAirdrop(address[] calldata recipients, uint256[] calldata amounts) external onlyOwner {
        require(recipients.length == amounts.length, "Recipients and amounts must have the same length");
        for (uint256 i = 0; i < recipients.length; i++) {
            require(token.transfer(recipients[i], amounts[i]), "Token transfer failed");
            emit AirdropDistributed(recipients[i], amounts[i]);
        }
    }

    /**
     * @dev Allow recipients to claim their assigned tokens.
     */
    function claimTokens() external {
        uint256 amount = airdropAmounts[msg.sender];
        require(amount > 0, "No tokens to claim");
        airdropAmounts[msg.sender] = 0; // Prevent double-claim
        require(token.transfer(msg.sender, amount), "Token transfer failed");
        emit TokensClaimed(msg.sender, amount);
    }

    /**
     * @dev Function for the owner to deposit tokens into the contract.
     * @param amount Amount of tokens to deposit.
     */
    function depositTokens(uint256 amount) external onlyOwner {
        // Step 1: Check allowance of the sender (owner) for the contract to transfer tokens
        uint256 allowance = token.allowance(msg.sender, address(this));
        require(allowance >= amount, "Allowance not sufficient for deposit");

        // Step 2: Transfer tokens from the sender (owner) to the contract
        bool transferSuccess = token.transferFrom(msg.sender, address(this), amount);
        require(transferSuccess, "Token transfer failed");

        // Emit the event for transparency
        emit TokensDeposited(msg.sender, amount);
    }

    /**
     * @dev Get the balance of tokens held by the contract.
     * @return uint256 Token balance of the contract.
     */
    function contractBalance() external view returns (uint256) {
        return token.balanceOf(address(this));  // This will show the balance of tokens in the contract
    }
}
    // 5000000000000000000
    // ["0x51EC0b1edE1BBeadD345964f0Ccc34F35F25E8d1", "0xcD7Cb01BC3C62E5c5eF22f17e81E269E75f9909A"]
    // [2000000000000000000, 3000000000000000000]