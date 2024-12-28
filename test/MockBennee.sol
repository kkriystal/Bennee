// SPDX-License-Identifier: MIT
pragma solidity 0.8.28;

import { ERC20, ERC20Burnable } from "@openzeppelin/contracts/token/ERC20/extensions/ERC20Burnable.sol";

contract MockBennee is ERC20Burnable {
    constructor() ERC20("Bennee Token", "BT") {
        _mint(msg.sender, 1000000e18);
    }

    function mint(address to, uint256 amount) external {
        _mint(to, amount);
    }

    function burn(address to, uint256 amount) external {
        _burn(to, amount);
    }
}
