// SPDX-License-Identifier: MIT
pragma solidity ^0.8.26;

/**
 * @title RockPaperScissors
 * @dev A simple contract for playing Rock-Paper-Scissors on the blockchain.
 */
contract RockPaperScissors {
    enum Move { None, Rock, Paper, Scissors }
    enum Result { None, Player1Wins, Player2Wins, Draw }

    struct Game {
        address player1;
        address player2;
        Move move1;
        Move move2;
        uint256 wager;
        Result result;
    }

    mapping(uint256 => Game) public games;
    uint256 public gameIdCounter;
    mapping(address => uint256[]) public playerGames;

    event GameCreated(uint256 indexed gameId, address indexed player1, uint256 wager);
    event GamePlayed(uint256 indexed gameId, address indexed player, Move move);
    event GameResult(uint256 indexed gameId, Result result);

    /**
     * @dev Create a new game with an initial wager.
     * @param wager The amount bet by the player.
     */
    function createGame(uint256 wager) external payable {
        require(msg.value == wager, "Wager amount mismatch");
        games[gameIdCounter] = Game({
            player1: msg.sender,
            player2: address(0),
            move1: Move.None,
            move2: Move.None,
            wager: wager,
            result: Result.None
        });
        playerGames[msg.sender].push(gameIdCounter);
        emit GameCreated(gameIdCounter, msg.sender, wager);
        gameIdCounter++;
    }

    /**
     * @dev Join an existing game by providing the gameId and sending the wager.
     * @param gameId The ID of the game to join.
     */
    function joinGame(uint256 gameId) external payable {
        Game storage game = games[gameId];
        require(game.player1 != address(0), "Game does not exist");
        require(game.player2 == address(0), "Game already has two players");
        require(msg.value == game.wager, "Wager amount mismatch");

        game.player2 = msg.sender;
        playerGames[msg.sender].push(gameId);
    }

    /**
     * @dev Make a move in the game.
     * @param gameId The ID of the game to play.
     * @param move The move (Rock, Paper, Scissors).
     */
    function play(uint256 gameId, Move move) external {
        Game storage game = games[gameId];
        require(move != Move.None, "Invalid move");
        require(msg.sender == game.player1 || msg.sender == game.player2, "Not a player in this game");

        if (msg.sender == game.player1) {
            require(game.move1 == Move.None, "Player 1 already made a move");
            game.move1 = move;
        } else {
            require(game.move2 == Move.None, "Player 2 already made a move");
            game.move2 = move;
        }

        emit GamePlayed(gameId, msg.sender, move);

        // If both players have made their moves, determine the result
        if (game.move1 != Move.None && game.move2 != Move.None) {
            resolveGame(gameId);
        }
    }

    /**
     * @dev Internal function to determine the result of the game.
     * @param gameId The ID of the game to resolve.
     */
    function resolveGame(uint256 gameId) internal {
        Game storage game = games[gameId];
        if (game.move1 == game.move2) {
            game.result = Result.Draw;
            payable(game.player1).transfer(game.wager);
            payable(game.player2).transfer(game.wager);
        } else if (
            (game.move1 == Move.Rock && game.move2 == Move.Scissors) ||
            (game.move1 == Move.Paper && game.move2 == Move.Rock) ||
            (game.move1 == Move.Scissors && game.move2 == Move.Paper)
        ) {
            game.result = Result.Player1Wins;
            payable(game.player1).transfer(game.wager * 2);
        } else {
            game.result = Result.Player2Wins;
            payable(game.player2).transfer(game.wager * 2);
        }

        emit GameResult(gameId, game.result);
    }

    /**
     * @dev View game history for a specific player.
     * @param player The address of the player.
     * @return uint256[] List of game IDs the player has participated in.
     */
    function getPlayerGames(address player) external view returns (uint256[] memory) {
        return playerGames[player];
    }
}
