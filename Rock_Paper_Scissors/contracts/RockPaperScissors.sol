// SPDX-License-Identifier: MIT
pragma solidity ^0.8.26;

import "@chainlink/contracts/src/v0.8/VRFConsumerBase.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

contract RockPaperScissors is VRFConsumerBase {
    // Enum for possible moves
    enum Move {Rock, Paper, Scissors}
    
    // Constants for game parameters
    uint256 public constant betAmount = 0.0001 ether;  // Bet amount in tBNB
    bytes32 internal keyHash;  // Used for requesting randomness from Chainlink
    uint256 internal fee;  // LINK fee for randomness requests

    // ERC20 token to be used for payments
    IERC20 public token;

    // Player and game data
    address payable public player1;
    address payable public player2;
    Move private player1Move;
    bool public gameComplete;
    uint256 public randomResult;

    // Events for game status
    event GameStarted(address indexed player1);
    event GameCompleted(address indexed winner, uint256 reward);

    // Constructor to initialize Chainlink VRF and ERC20 token settings
    constructor(
        address _vrfCoordinator, 
        address _linkToken, 
        bytes32 _keyHash, 
        uint256 _fee, 
        address _tokenAddress
    ) 
        VRFConsumerBase(_vrfCoordinator, _linkToken) 
    {
        keyHash = _keyHash;  // Set key hash for randomness
        fee = _fee;  // Set the LINK fee required for randomness
        token = IERC20(_tokenAddress);  // Initialize the ERC20 token
    }

    // Player initiates the game with a bet and a move
    function play(Move _move) public payable {
        require(msg.value == betAmount, "Incorrect bet amount");  // Ensure correct bet

        if (player1 == address(0)) {
            player1 = payable(msg.sender);  // Set player 1's address
            player1Move = _move;  // Record player 1's move
            emit GameStarted(player1);  // Emit game start event
        } else if (player2 == address(0)) {
            player2 = payable(msg.sender);  // Set player 2's address
            requestRandomnessForWinner();  // Request randomness to determine winner
        } else {
            revert("Game in progress. Wait for completion.");
        }
    }

    // Request randomness from Chainlink VRF to determine the winner
    function requestRandomnessForWinner() private returns (bytes32 requestId) {
        require(LINK.balanceOf(address(this)) >= fee, "Not enough LINK to request randomness");
        return requestRandomness(keyHash, fee);  // Request randomness from Chainlink
    }

    // Chainlink callback function to fulfill the randomness request
  // Function to handle randomness returned by Chainlink
    function fulfillRandomness(bytes32 /* requestId */, uint256 randomness) internal override {
        randomResult = randomness % 3;  // Get a random value between 0 and 2
        _decideWinner();  // Call function to decide the winner
}


    // Function to determine the winner based on randomness
    function _decideWinner() private {
        require(!gameComplete, "Game already complete");  // Ensure the game isn't finished
        gameComplete = true;  // Mark the game as complete

        address payable winner;

        if (randomResult == 0) {
            // It's a draw, both players get refunded
            player1.transfer(betAmount);
            player2.transfer(betAmount);
        } else if (randomResult == 1) {
            // Player 1 wins
            winner = player1;
        } else {
            // Player 2 wins
            winner = player2;
        }

        // If there is a winner, transfer the reward
        if (winner != address(0)) {
            uint256 reward = betAmount * 2;  // Winner gets 2x the bet
            winner.transfer(reward);  // Send the reward to the winner
            emit GameCompleted(winner, reward);  // Emit game completion event
        }
    }

    // Add ERC20 token payments for the game
    function playWithTokens(Move _move, uint256 tokenAmount) public {
        require(token.balanceOf(msg.sender) >= tokenAmount, "Insufficient token balance");
        require(tokenAmount == betAmount, "Incorrect token amount");

        token.transferFrom(msg.sender, address(this), tokenAmount);  // Transfer tokens for bet

        if (player1 == address(0)) {
            player1 = payable(msg.sender);  // Set player 1
            player1Move = _move;  // Record player 1's move
            emit GameStarted(player1);  // Emit game start event
        } else if (player2 == address(0)) {
            player2 = payable(msg.sender);  // Set player 2
            requestRandomnessForWinner();  // Request randomness to determine the winner
        } else {
            revert("Game in progress. Wait for completion.");
        }
    }

    // Function to withdraw LINK tokens from the contract (optional)
    function withdrawLink() public {
        require(LINK.transfer(msg.sender, LINK.balanceOf(address(this))), "Unable to transfer");
    }
}
