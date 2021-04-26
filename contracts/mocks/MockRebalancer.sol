// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;
import '../interfaces/erc/IERC20.sol';
import '../interfaces/IETFRebalancer.sol';

contract MockRebalancer is IETFRebalancer {
    function onRebalance(
        address initiator,
        uint256 units,
        IERC20[] memory,
        uint256[] memory,
        IERC20[] memory repayTokens,
        uint256[] memory repayAmounts,
        bytes memory
    ) external override returns (bool) {
        for (uint256 i = 0; i < repayTokens.length; i++) {
            repayTokens[i].transferFrom(initiator, address(this), repayAmounts[i] * units);
            repayTokens[i].approve(msg.sender, repayAmounts[i] * units);
        }
        return true;
    }
}
