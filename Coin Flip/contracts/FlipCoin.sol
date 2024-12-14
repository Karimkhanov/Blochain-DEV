// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract CoinFlip {
    address public owner;

    constructor() {
        owner = msg.sender;
    }

    event CoinFlipped(address indexed player, bool win, uint256 amount);

function flipCoin(bool betOnHeads) public payable {

    uint256 minBet = 10000000000;

    require(msg.value >= minBet, "You need to bet at least 10,000 gwei");

    bool coinFlipResult = (block.timestamp + block.prevrandao) % 2 == 0;

    emit CoinFlipped(msg.sender, coinFlipResult, msg.value);

    bool win = (coinFlipResult == betOnHeads);

    if (win) {
        uint256 payout = msg.value * 2;

        emit CoinFlipped(msg.sender, win, payout);
        
        require(address(this).balance >= payout, "Not enough balance in the contract");

        // Transfer the payout to the player
        (bool success, ) = payable(msg.sender).call{value: payout}("");
        require(success, "Transfer failed"); 
    }
        // Emit the event with the result
        emit CoinFlipped(msg.sender, win, msg.value);
    }

    function withdrawFunds() public {
        require(msg.sender == owner, "Only the owner can withdraw funds");
        payable(owner).transfer(address(this).balance);
    }

    receive() external payable {}
}