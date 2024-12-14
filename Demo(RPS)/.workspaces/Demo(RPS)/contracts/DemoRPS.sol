// SPDX-License-Identifier: MIT
pragma solidity ^0.8.26;

contract RockPaperScissors {
    // Address of the contract owner
    address public owner;

    // Minimum bet amount (0.0001 tBNB)
    uint256 public constant MIN_BET = 0.0001 ether;

    // Event for logging the result
    event GameResult(address indexed player, string result, uint256 amount);

    // Enum to represent choices
    enum Move { Rock, Paper, Scissors }

    // Mapping to store player's choice
    mapping(address => Move) public playerMove;

    // Constructor to set the owner
    constructor() {
        owner = msg.sender;
    }

    /*Win: If you win, you are paid double the amount of your bet (i.e. 0.0002 tBNB).
    Losing: If you lose, the contract keeps your bet.
    Draw: If you draw, you are refunded the amount you bet (0.0001 tBNB).*/

    // Function to play the game
    function playGame(Move _playerMove) public payable {
        require(msg.value == MIN_BET, "You must bet exactly 0.0001 tBNB");

        // Store player's move
        playerMove[msg.sender] = _playerMove;

        /*In the _playerMove field, input one of the following values:
        0 for Rock
        1 for Paper
        2 for Scissors*/

        // Randomly select a move for the contract (opponent)
        Move opponentMove = randomMove();

        // Determine the outcome
        string memory result;
        if (_playerMove == opponentMove) {
            // Tie case
            result = "Tie";
            payable(msg.sender).transfer(msg.value); // Refund the player
        } else if (
            (_playerMove == Move.Rock && opponentMove == Move.Scissors) ||
            (_playerMove == Move.Paper && opponentMove == Move.Rock) ||
            (_playerMove == Move.Scissors && opponentMove == Move.Paper)
        ) {
            // Player wins
            result = "You win!";
            uint256 reward = msg.value * 2;
            require(address(this).balance >= reward, "Not enough balance in contract");
            payable(msg.sender).transfer(reward); // Pay the winner
        } else {
            // Player loses
            result = "You lose.";
            // Bet amount is kept by the contract
        }

        // Emit event with the result
        emit GameResult(msg.sender, result, msg.value);
    }

    // Function to generate a random move for the opponent
    function randomMove() private view returns (Move) {
        uint256 random = uint256(keccak256(abi.encodePacked(block.timestamp, block.prevrandao, msg.sender))) % 3;
        return Move(random);
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



