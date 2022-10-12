// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import '../interfaces/IETFRebalancer.sol';
import '../ETF.sol';
import '../mocks/MockERC20.sol';
import '../mocks/MockRebalancer.sol';
import '../mocks/MockETFRebalanceValidator.sol';

/// @dev Invariant testing

contract ETFFuzzing {
    address holder = address(this);
    ETF internal etf;
    IETFRebalancer internal rebalancer;
    bool invariant = true;

    constructor() {
        rebalancer = new MockRebalancer();
        uint256[] memory init = new uint256[](3);
        init[0] = 1;
        init[1] = 10;
        init[2] = 100;
        setEtf(init);
    }

    function setEtf(uint256[] memory amounts) private {
        IERC20[] memory _t = new IERC20[](amounts.length);
        for (uint256 i = 0; i < amounts.length; i++) {
            _t[i] = new MockERC20('A', 'A', 1e9, holder);
        }
        // Sort tokens
        for (uint256 i = 0; i < _t.length; i++) {
            uint256 minIndex = i;
            for (uint256 j = i + 1; j < _t.length; j++) {
                if (_t[j] < _t[minIndex]) {
                    minIndex = j;
                }
            }
            IERC20 tmp1 = _t[i];
            _t[i] = _t[minIndex];
            _t[minIndex] = tmp1;
        }
        etf = new ETF('ETF', 'ETF', _t, amounts, new MockETFRebalanceValidator());
        // CONVENIENCE METHOD SO CREATE WORKS
        for (uint256 i = 0; i < amounts.length; i++) {
            _t[i].approve(address(etf), type(uint256).max);
            _t[i].approve(address(rebalancer), type(uint256).max);
        }
    }

    function create(uint256 amt) public {
        etf.create(amt);
    }

    function redeem(uint256 amt) public {
        etf.redeem(amt);
    }

    function createRedeem(uint256 amt) public {
        uint256 myBal = etf.balanceOf(address(this));
        uint256 supply = etf.totalSupply();
        IERC20[] memory _t = etf.tokens();
        uint256[] memory _a = etf.amounts();
        create(amt);
        redeem(amt);
        if (myBal != etf.balanceOf(address(this)) || supply != etf.totalSupply()) {
            invariant = false;
        }
        IERC20[] memory _nt = etf.tokens();
        uint256[] memory _na = etf.amounts();
        for (uint256 i = 0; i < _nt.length; i++) {
            if (_t[i] != _nt[i] || _a[i] != _na[i]) {
                invariant = false;
            }
        }
    }

    function rebalance(uint256[] memory amounts) public {
        IERC20[] memory _t = new IERC20[](amounts.length);
        for (uint256 i = 0; i < amounts.length; i++) {
            _t[i] = new MockERC20('A', 'A', 1e9, holder);
        }
        // Sort tokens
        for (uint256 i = 0; i < _t.length; i++) {
            uint256 minIndex = i;
            for (uint256 j = i + 1; j < _t.length; j++) {
                if (_t[j] < _t[minIndex]) {
                    minIndex = j;
                }
            }
            IERC20 tmp1 = _t[i];
            _t[i] = _t[minIndex];
            _t[minIndex] = tmp1;
        }
        etf.rebalance(rebalancer, _t, amounts, '0x0');
    }

    function echidna_failed_invariant() public view returns (bool) {
        return invariant;
    }

    // KEY INVARIANT
    function echidna_equity_invariant() public view returns (bool) {
        IERC20[] memory tokens = etf.tokens();
        uint256[] memory amounts = etf.amounts();
        for (uint256 i = 0; i < tokens.length; i++) {
            bool pass = etf.totalSupply() * amounts[i] <= tokens[i].balanceOf(address(etf));
            if (!pass) {
                return false;
            }
        }
        return true;
    }

    function echidna_fully_specified() public view returns (bool) {
        IERC20[] memory tokens = etf.tokens();
        uint256[] memory amounts = etf.amounts();
        return tokens.length == amounts.length;
    }

    function echidna_etf_set() public view returns (bool) {
        return address(etf) != address(0);
    }
}
