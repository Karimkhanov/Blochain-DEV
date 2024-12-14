// SPDX-License-Identifier: MIT
// Compatible with OpenZeppelin Contracts ^5.0.0
pragma solidity ^0.8.26;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";

contract GoChainToken is ERC20 {
    constructor() ERC20("GoChain Token", "GCT") {
        _mint(msg.sender, 100 * 10**decimals());
    }
}
