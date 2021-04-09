// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import '../ETF.sol';
import '../mocks/MockERC20.sol';
import '../mocks/MockETFRebalanceValidator.sol';

/// @dev Invariant testing
contract ETFFuzzing {
    address holder = address(this);
    uint256 internal constant tokenSupply = 1e9;
    MockETFRebalanceValidator internal validator;
    MockERC20 internal token1;
    MockERC20 internal token2;
    MockERC20 internal token3;

    ETF internal etf;

    uint256 _value;

    constructor() {
        validator = new MockETFRebalanceValidator();
        token1 = new MockERC20('A', 'A', tokenSupply, holder);
        token2 = new MockERC20('B', 'B', tokenSupply, holder);
        token3 = new MockERC20('C', 'D', tokenSupply, holder);
        // Sort the tokens
        MockERC20 tmp;
        if (token1 > token2) {
            tmp = token1;
            token1 = token2;
            token2 = tmp;
        }
        if (token2 > token3) {
            tmp = token2;
            token2 = token3;
            token3 = tmp;
        }
        if (token1 > token2) {
            tmp = token1;
            token1 = token2;
            token2 = tmp;
        }

        IERC20[] memory _tokens = new IERC20[](3);
        _tokens[0] = token1;
        _tokens[1] = token2;
        _tokens[2] = token3;

        uint256[] memory _amounts = new uint256[](3);
        _amounts[0] = 100;
        _amounts[1] = 3;
        _amounts[2] = 10;

        etf = new ETF('ETF', 'ETF', _tokens, _amounts, validator);
    }

    function setVal(uint256 value) public {
        _value = value;
    }

    function echidna_redeem() public view returns (bool) {
        return _value < 100000000000000000000000;
    }

    function echidna_create() public view returns (bool) {
        return _value < 10000000;
    }

    function echidna_supply() public view returns (bool) {
        return etf.totalSupply() < 100;
    }

    // function create(uint256 value) public {
    //     assert(token1.balanceOf(address(this)) + token1.balanceOf(address(etf)) == tokenSupply);
    // }

    ///invariants
    ///balance of each token == totalSupply * amount
    ///supply
}
