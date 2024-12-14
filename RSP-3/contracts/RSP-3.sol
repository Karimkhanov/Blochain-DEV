// SPDX-License-Identifier: MIT
pragma solidity ^0.8.26;

import "@chainlink/contracts/src/v0.8/VRFConsumerBase.sol"; // Importing VRF consumer base
import "@openzeppelin/contracts/token/ERC20/IERC20.sol"; // Importing ERC20 interface

contract RockPaperScissors is VRFConsumerBase {
    address public owner;
    uint256 public constant MIN_BET = 0.0001 ether; // Minimum bet amount in tBNB
    uint256 public randomResult; // To store the random number result
    IERC20 public token; // ERC20 token instance
    uint256 public tokenBetAmount = 100 * 10 ** 18; // Bet amount in tokens (100 tokens)

    // Event for logging the game result
    event GameResult(address indexed player1, address indexed player2, string result, uint256 amount);

    // Enum to represent choices
    enum Move { Rock, Paper, Scissors }

    // Struct to represent a player
    struct Player {
        address payable playerAddress; // Player's address
        Move move; // Player's move
        bool hasPlayed; // Whether the player has played
    }

    // Store players
    Player[2] public players;

    // VRF Coordinator and LINK token addresses (for testnet)
    bytes32 internal keyHash;
    uint256 internal fee;

    // Constructor to set the owner and initialize VRF
    constructor(address _tokenAddress)
        VRFConsumerBase(
            0x6168499D32a4Fb92c9A1658f49F54Dab90510F0B, // VRF Coordinator address (update for your network)
            0x514910771AF9Ca656af840dff83E8264EcF986CA   // LINK token address (update for your network)
        )
    {
        owner = msg.sender; // Set contract deployer as owner
        token = IERC20(_tokenAddress); // Initialize ERC20 token
        keyHash = 0xAA77729D3466CA35AE8D28E23EA3D82DA8AA3D7899A56A9A31F0CC53AAB53456; // VRF keyHash for testnet
        fee = 0.1 * 10 ** 18; // Fee for VRF request (0.1 LINK)
    }

    // Function to join the game and make a move with tokens
    function joinGameWithTokens(Move _move) public {
        require(token.balanceOf(msg.sender) >= tokenBetAmount, "Not enough tokens"); // Check token balance
        token.transferFrom(msg.sender, address(this), tokenBetAmount); // Transfer tokens to contract

        // Check if the player is already in the game
        require(players[0].playerAddress != msg.sender && players[1].playerAddress != msg.sender, "You are already in the game");

        // Add the player to the first available slot
        if (!players[0].hasPlayed) {
            players[0] = Player(payable(msg.sender), _move, true);
        } else if (!players[1].hasPlayed) {
            players[1] = Player(payable(msg.sender), _move, true);
            getRandomNumber(); // Request a random number
        } else {
            revert("The game is full. Please wait for the current round to finish.");
        }
    }

    // Function to get a random number from Chainlink VRF
    function getRandomNumber() internal returns (bytes32 requestId) {
        require(LINK.balanceOf(address(this)) >= fee, "Not enough LINK in contract"); // Ensure contract has LINK
        return requestRandomness(keyHash, fee); // Request random number
    }

    // Callback function called by VRF Coordinator
    function fulfillRandomness(bytes32, uint256 randomness) internal override {
        randomResult = randomness; // Store the random number
        determineWinner(); // Determine the winner
    }

    // Function to determine the winner between two players
    function determineWinner() private {
        Player memory player1 = players[0];
        Player memory player2 = players[1];
        uint256 rewardAmount = tokenBetAmount * 2; // Calculate the reward amount in tokens
        string memory result;

        // Determine the game outcome
        if (player1.move == player2.move) {
            // Tie case: Refund both players
            result = "It's a tie!";
            token.transfer(player1.playerAddress, tokenBetAmount); // Refund Player 1
            token.transfer(player2.playerAddress, tokenBetAmount); // Refund Player 2
        } else if (
            (player1.move == Move.Rock && player2.move == Move.Scissors) ||
            (player1.move == Move.Paper && player2.move == Move.Rock) ||
            (player1.move == Move.Scissors && player2.move == Move.Paper)
        ) {
            // Player 1 wins
            result = "Player 1 wins!";
            token.transfer(player1.playerAddress, rewardAmount); // Reward Player 1
        } else {
            // Player 2 wins
            result = "Player 2 wins!";
            token.transfer(player2.playerAddress, rewardAmount); // Reward Player 2
        }

        // Emit event with the result
        emit GameResult(player1.playerAddress, player2.playerAddress, result, tokenBetAmount);

        // Reset the game for the next round
        resetGame();
    }

    // Function to reset the game after each round
    function resetGame() private {
        players[0].playerAddress = payable(address(0)); // Clear Player 1's address
        players[1].playerAddress = payable(address(0)); // Clear Player 2's address
        players[0].hasPlayed = false; // Reset Player 1's state
        players[1].hasPlayed = false; // Reset Player 2's state
    }

    // Function to withdraw the balance (owner only)
    function withdraw() public {
        require(msg.sender == owner, "Only the owner can withdraw"); // Check if the caller is the owner
        payable(owner).transfer(address(this).balance); // Withdraw tBNB balance
    }

    // Fallback function to receive funds
    receive() external payable {}

    // Fallback function for invalid calls
    fallback() external payable {}
}
