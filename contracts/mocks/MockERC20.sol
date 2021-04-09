// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;
import '../erc/ERC20.sol';

contract MockERC20 is ERC20 {
    constructor(
        string memory _name,
        string memory _symbol,
        uint256 _value,
        address holder
    ) ERC20(_name, _symbol) {
        _mint(holder, _value);
    }
}
