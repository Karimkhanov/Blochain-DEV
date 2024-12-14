// SPDX-License-Identifier: MIT
pragma solidity ^0.8.26;

// A basic contract for multiplayer chess
contract ChessGame {
    // Struct to represent a chess game
    struct Game {
        address player1; // Address of player 1 (white)
        address player2; // Address of player 2 (black)
        uint256 turn; // Keeps track of turns (1 for white, 2 for black)
        string boardState; // The state of the chess board (encoded in FEN notation)
        bool isActive; // Indicates if the game is active
    }

    // Mapping of game IDs to Game structs
    mapping(uint256 => Game) public games;

    // Counter for generating unique game IDs
    uint256 public gameIdCounter;

    // Event emitted when a new game is created
    event GameCreated(uint256 gameId, address player1);

    // Event emitted when a player joins a game
    event PlayerJoined(uint256 gameId, address player2);

    // Event emitted when a move is made
    event MoveMade(uint256 gameId, address player, string boardState);

    /// @notice Creates a new chess game with the caller as player1
    /// @return The ID of the created game
    function createGame() external returns (uint256) {
        gameIdCounter++;
        games[gameIdCounter] = Game({
            player1: msg.sender,
            player2: address(0),
            turn: 1,
            boardState: "start", // Initial board state
            isActive: true
        });

        emit GameCreated(gameIdCounter, msg.sender);
        return gameIdCounter;
    }

    /// @notice Allows a second player to join an existing game
    /// @param gameId The ID of the game to join
    function joinGame(uint256 gameId) external {
        Game storage game = games[gameId];
        require(game.player1 != address(0), "Game does not exist");
        require(game.player2 == address(0), "Game already has two players");
        require(game.player1 != msg.sender, "Cannot join your own game");

        game.player2 = msg.sender;

        emit PlayerJoined(gameId, msg.sender);
    }

    /// @notice Makes a move in the game and updates the board state
    /// @param gameId The ID of the game
    /// @param newBoardState The updated board state in FEN notation
    function makeMove(uint256 gameId, string calldata newBoardState) external {
        Game storage game = games[gameId];
        require(game.isActive, "Game is not active");
        require(
            (game.turn == 1 && msg.sender == game.player1) ||
            (game.turn == 2 && msg.sender == game.player2),
            "Not your turn"
        );

        // Update the board state
        game.boardState = newBoardState;

        // Switch turns
        game.turn = game.turn == 1 ? 2 : 1;

        emit MoveMade(gameId, msg.sender, newBoardState);
    }

    /// @notice Ends the game, making it inactive
    /// @param gameId The ID of the game
    function endGame(uint256 gameId) external {
        Game storage game = games[gameId];
        require(msg.sender == game.player1 || msg.sender == game.player2, "Not a participant");
        require(game.isActive, "Game is already inactive");

        game.isActive = false;
    }
}
