// SPDX-License-Identifier: MIT
pragma solidity ^0.8.27;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract MyToken is ERC20, Ownable {

    constructor()
        ERC20("Promise Token", "PMT")
        Ownable(msg.sender)
    {
        _mint(msg.sender, 1_000_000 * 10 ** decimals());
    }

    // Owner can mint more tokens
    function mint(address to, uint256 amount) external onlyOwner {
        _mint(to, amount);
    }

    // Users can burn their own tokens
    function burn(uint256 amount) external {
        _burn(msg.sender, amount);
    }
}