// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

// import '../ETF.sol';
import '../mocks/MockERC20.sol';

// import '../mocks/MockETFRebalanceValidator.sol';

/// @dev A contract that will receive weth, and allows for it to be retrieved.
// contract MockHolder {
//     constructor(address payable weth, address retriever) {
//         ETF(weth).approve(retriever, type(uint256).max);
//     }
// }

/// @dev Invariant testing
contract ETHFuzzing {
    // MockETFRebalanceValidator internal validator;
    MockERC20 internal token1;

    // ETF internal etf;
    // address internal holder;

    constructor() {
        // validator = new MockETFRebalanceValidator();
        // IERC20[] memory _tokens = new IERC20[](1);
        // _tokens[0] = token1;
        // uint256[] memory _amounts = new uint256[](1);
        // _amounts[0] = 1;
        token1 = new MockERC20('A', 'A', 1000);
        // etf = new ETF('ETF', 'ETF', _tokens, _amounts, validator);
    }

    function echidna_check_balance() public pure returns (bool) {
        return false;
    }

    ///invariants
    ///balance of each token == totalSupply * amount
    ///supply
}
