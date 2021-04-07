// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import './ERC2612.sol';
import '../interfaces/erc/IERC2612.sol';
import '../interfaces/erc/IERC3156FlashBorrower.sol';
import '../interfaces/erc/IERC3156FlashLender.sol';

abstract contract ERC3156FlashLender is ERC2612, IERC3156FlashLender {
    constructor(string memory name_, string memory symbol_) ERC2612(name_, symbol_) {}

    bytes32 private immutable CB_SUCCESS = keccak256('ERC3156FlashBorrower.onFlashLoan');

    function maxFlashLoan(address token) external view override returns (uint256) {
        return token == address(this) ? type(uint256).max - totalSupply : 0;
    }

    function flashFee(address token, uint256) external view override returns (uint256) {
        require(token == address(this), 'Unsupported token');
        return 0;
    }

    function flashLoan(
        IERC3156FlashBorrower receiver,
        address token,
        uint256 amount,
        bytes calldata data
    ) external override returns (bool) {
        require(token == address(this), 'Unsupported token');
        _mint(address(receiver), amount);
        require(receiver.onFlashLoan(msg.sender, token, amount, 0, data) == CB_SUCCESS, 'Callback failed');
        uint256 _allowance = allowance[address(receiver)][address(this)];
        if (_allowance != type(uint256).max) {
            _approve(address(receiver), address(this), _allowance - amount);
        }
        _burn(address(receiver), amount);
        return true;
    }
}
