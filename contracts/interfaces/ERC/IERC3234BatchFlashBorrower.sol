// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface IERC3234BatchFlashBorrower {
    /**
     * @dev Receive a flash loan.
     * @param initiator The initiator of the loan.
     * @param tokens The loan currency.
     * @param amounts The amount of tokens lent.
     * @param fees The additional amount of tokens to repay.
     * @param data Arbitrary data structure, intended to contain user-defined parameters.
     * @return The keccak256 hash of "ERC3234BatchFlashBorrower.onBatchFlashLoan"
     */
    function onBatchFlashLoan(
        address initiator,
        address[] calldata tokens,
        uint256[] calldata amounts,
        uint256[] calldata fees,
        bytes calldata data
    ) external returns (bytes32);
}
