// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;
import "./IERC3234BatchFlashBorrower.sol";

interface IERC3234BatchFlashLender {
    /**
     * @dev The amount of currency available to be lended.
     * @param tokens The currency for each loan in the batch.
     * @return The maximum amount that can be borrowed for each loan in the batch.
     */
    function maxFlashLoans(address[] calldata tokens)
        external
        view
        returns (uint256[] calldata);

    /**
     * @dev The fees to be charged for a given batch loan.
     * @param tokens The loan currencies.
     * @param amounts The amounts of tokens lent.
     * @return The amount of each `token` to be charged for each loan, on top of the returned principal.
     */
    function flashFees(address[] calldata tokens, uint256[] calldata amounts)
        external
        view
        returns (uint256[] calldata);

    /**
     * @dev Initiate a batch flash loan.
     * @param receiver The receiver of the tokens in the loan, and the receiver of the callback.
     * @param tokens The loan currencies.
     * @param amounts The amount of tokens lent.
     * @param data Arbitrary data structure, intended to contain user-defined parameters.
     */
    function batchFlashLoan(
        IERC3234BatchFlashBorrower receiver,
        address[] calldata tokens,
        uint256[] calldata amounts,
        bytes[] calldata data
    ) external returns (bool);
}
