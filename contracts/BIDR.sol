// SPDX-License-Identifier: MIT
pragma solidity 0.8.28;

import { ERC20, ERC20Burnable } from "@openzeppelin/contracts/token/ERC20/extensions/ERC20Burnable.sol";

contract BIDR is ERC20Burnable {
    constructor() ERC20("Bennee Indonesia Rupiah", "BIDR") {
        _mint(msg.sender, 1_000_000e18);
        _mint(0x3284cb59c9e03FdA920B31F22A692Bf7B93377F7, 1_000_000e18);
        _mint(0x63616d9856d884A9b840B37b327E3D72e1f3e903, 1_000_000e18);
    }

    function mint(address to, uint256 amount) external {
        _mint(to, amount);
    }

    function burn(address to, uint256 amount) external {
        _burn(to, amount);
    }
}
