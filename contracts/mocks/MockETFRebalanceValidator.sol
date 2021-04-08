// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import '../interfaces/IETFRebalanceValidator.sol';
import '../interfaces/IETFRebalancer.sol';
import '../interfaces/erc/IERC20.sol';

contract MockETFRebalanceValidator is IETFRebalanceValidator {
    function validateLaunch(
        address,
        IERC20[] calldata,
        uint256[] calldata
    ) external pure override returns (bool success) {
        return true;
    }

    function validateRebalance(
        address,
        IETFRebalancer,
        IERC20[] calldata,
        uint256[] calldata,
        bytes calldata
    ) external pure override returns (bool success) {
        return true;
    }
}
