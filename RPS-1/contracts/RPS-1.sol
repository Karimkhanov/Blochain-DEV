// SPDX-License-Identifier: MIT
pragma solidity ^0.8.26;

contract RockPaperScissors {
    // Address of the contract owner
    address public owner;

    // Minimum bet amount (0.0001 tBNB)
    uint256 public constant MIN_BET = 0.0001 ether;

    // Event for logging the result
    event GameResult(address indexed player1, address indexed player2, string result, uint256 amount);

    // Enum to represent choices
    enum Move { Rock, Paper, Scissors }

    // Struct to represent a player
    struct Player {
        address payable playerAddress;
        Move move;
        bool hasPlayed;
    }

    // Store players
    Player[2] public players;

    // Constructor to set the owner
    constructor() {
        owner = msg.sender;
    }

    /* 
    Win: If you win, you are paid double the amount of your bet (i.e. 0.0002 tBNB).
    Losing: If you lose, the contract keeps your bet.
    Draw: If you draw, you are refunded the amount you bet (0.0001 tBNB).

    0 for Rock
    1 for Paper
    2 for Scissors
    */

    // Function to join the game and make a move
    function joinGame(Move _move) public payable {
        require(msg.value == MIN_BET, "You must bet exactly 0.0001 tBNB");
        
        // Check if the player is already in the game
        require(players[0].playerAddress != msg.sender && players[1].playerAddress != msg.sender, "You are already in the game");

        // Add the player to the first available slot
        if (!players[0].hasPlayed) {
            players[0] = Player(payable(msg.sender), _move, true);
        } else if (!players[1].hasPlayed) {
            players[1] = Player(payable(msg.sender), _move, true);
        } else {
            revert("The game is full. Please wait for the current round to finish.");
        }

        // If two players have joined, determine the winner
        if (players[0].hasPlayed && players[1].hasPlayed) {
            determineWinner();
        }
    }

    // Function to determine the winner between two players
    function determineWinner() private {
        Player memory player1 = players[0];
        Player memory player2 = players[1];

        string memory result;
        uint256 reward = MIN_BET * 2;

        if (player1.move == player2.move) {
            // Tie case: Refund both players
            result = "It's a tie!";
            player1.playerAddress.transfer(MIN_BET);
            player2.playerAddress.transfer(MIN_BET);
        } else if (
            (player1.move == Move.Rock && player2.move == Move.Scissors) ||
            (player1.move == Move.Paper && player2.move == Move.Rock) ||
            (player1.move == Move.Scissors && player2.move == Move.Paper)
        ) {
            // Player 1 wins
            result = "Player 1 wins!";
            require(address(this).balance >= reward, "Not enough balance in contract");
            player1.playerAddress.transfer(reward);
        } else {
            // Player 2 wins
            result = "Player 2 wins!";
            require(address(this).balance >= reward, "Not enough balance in contract");
            player2.playerAddress.transfer(reward);
        }

        // Emit event with the result
        emit GameResult(player1.playerAddress, player2.playerAddress, result, MIN_BET);

        // Reset the game for the next round
        resetGame();
    }

    // Function to reset the game after each round
    function resetGame() private {
        players[0].playerAddress = payable(address(0));  // Clear Player 1's address
        players[1].playerAddress = payable(address(0));  // Clear Player 2's address
        players[0].hasPlayed = false;                    // Reset Player 1's state
        players[1].hasPlayed = false;                    // Reset Player 2's state
    }

    // Function to withdraw the balance (owner only)
    function withdraw() public {
        require(msg.sender == owner, "Only the owner can withdraw");
        payable(owner).transfer(address(this).balance);
    }

    // Fallback function to receive funds
    receive() external payable {}

    // Fallback function for invalid calls
    fallback() external payable {}
}
