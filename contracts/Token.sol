pragma solidity ^0.6.12;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";

contract Token is ERC20 {
    constructor() ERC20("Fund The Restaurants", "FTR") public {
        _mint(msg.sender, 1000000000000000000000000);
    }
}