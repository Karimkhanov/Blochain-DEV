// SPDX-License-Identifier: MIT
pragma solidity ^0.8.26;

// Import Chainlink's VRFConsumerBase for random number generation
import "@chainlink/contracts/src/v0.8/VRFConsumerBase.sol";

contract RockPaperScissors is VRFConsumerBase {
    // Address of the contract owner
    address public owner;

    // Minimum bet amount (0.0001 tBNB)
    uint256 public constant MIN_BET = 0.0001 ether;

    // Event for logging the result
    event GameResult(
        address indexed player1,
        address indexed player2,
        string result,
        uint256 amount
    );

    // Enum to represent choices
    enum Move {
        Rock,
        Paper,
        Scissors
    }

    // Struct to represent a player
    struct Player {
        address payable playerAddress;
        Move move;
        bool hasPlayed;
    }

    // Store players
    Player[2] public players;

    // Variables for Chainlink VRF
    bytes32 internal keyHash;
    uint256 internal fee;
    uint256 public randomResult;

    // Event to log the random result (for verification)
    event RandomNumberGenerated(uint256 randomNumber);

    // Constructor to initialize VRF and set the owner
    constructor()
        VRFConsumerBase(
            0xDA3b641D438362C440Ac5458c57e00a712b66700, // VRF Coordinator
            0x84b9B910527Ad5C03A9Ca831909E21e236EA7b06 // LINK token address
        )
    {
        owner = msg.sender;
        keyHash = 0x8596b430971ac45bdf6088665b9ad8e8630c9d5049ab54b14dff711bee7c0e26; // Key hash for VRF
        fee = 0.1 * 10**18; // Fee in LINK for requesting randomness
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
        require(
            players[0].playerAddress != msg.sender &&
                players[1].playerAddress != msg.sender,
            "You are already in the game"
        );

        // Add the player to the first available slot
        if (!players[0].hasPlayed) {
            players[0] = Player(payable(msg.sender), _move, true);
        } else if (!players[1].hasPlayed) {
            players[1] = Player(payable(msg.sender), _move, true);
        } else {
            revert(
                "The game is full. Please wait for the current round to finish."
            );
        }

        // If two players have joined, request randomness to determine the winner
        if (players[0].hasPlayed && players[1].hasPlayed) {
            requestRandomNumber();
        }
    }

    // Function to request a random number using Chainlink VRF
    function requestRandomNumber() private returns (bytes32 requestId) {
        require(
            LINK.balanceOf(address(this)) >= fee,
            "Not enough LINK in contract"
        );
        return requestRandomness(keyHash, fee);
    }

    // Callback function used by Chainlink VRF to return the random number
    function fulfillRandomness(
        bytes32, /* requestId */
        uint256 randomness
    ) internal override {
        randomResult = randomness; // Store the random result
        emit RandomNumberGenerated(randomness); // Emit event for logging
        determineWinner(randomness % 2); // Use random number to determine the winner (0 or 1)
    }

    // Function to determine the winner between two players using randomness
    function determineWinner(uint256 randomOutcome) private {
        Player memory player1 = players[0];
        Player memory player2 = players[1];

        string memory result;
        uint256 reward = MIN_BET * 2;

        if (randomOutcome == 0) {
            // Player 1 wins
            result = "Player 1 wins!";
            require(
                address(this).balance >= reward,
                "Not enough balance in contract"
            );
            player1.playerAddress.transfer(reward);
        } else {
            // Player 2 wins
            result = "Player 2 wins!";
            require(
                address(this).balance >= reward,
                "Not enough balance in contract"
            );
            player2.playerAddress.transfer(reward);
        }

        // Emit event with the result
        emit GameResult(
            player1.playerAddress,
            player2.playerAddress,
            result,
            MIN_BET
        );

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
        require(msg.sender == owner, "Only the owner can withdraw");
        payable(owner).transfer(address(this).balance);
    }

    // Fallback function to receive funds
    receive() external payable {}

    // Fallback function for invalid calls
    fallback() external payable {}
}
