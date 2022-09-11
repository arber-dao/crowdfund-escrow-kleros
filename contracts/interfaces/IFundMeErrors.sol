// SPDX-License-Identifier: MIT
pragma solidity 0.8.13;

/** @title FundMeErrors
 *  Errors for FundMeCore Contract
 */
interface IFundMeErrors {
  /** @notice throw when msg.sender tries to call a function that only the transaction receiver has access to call
   *  @param requiredReceiver the authorized receiver
   *  @param sender the caller (msg.sender)
   */
  error FundMe__OnlyTransactionReceiver(address requiredReceiver, address sender);

  /** @notice throw when milestoneId specified is not claimable either because it has already been claimed, 
              or milestone proceeding it have not been claimed yet
   *  @param milestoneIdRequired the next milestoneId which should be claimed
   *  @param milestoneIdGiven the milestoneId attempted to claim
   */
  error FundMe__MilestoneIdNotClaimable(uint256 milestoneIdRequired, uint256 milestoneIdGiven);

  /** @notice throw when payment to a payable function is not enough
   *  @param amountRequired amount required to complete the transaction
   *  @param amountSent amount sent with the transaction
   */
  error FundMe__PaymentTooSmall(uint256 amountRequired, uint256 amountSent);

  /** @notice throw when the requested transaction does not exist
   *  @param transactionId the id of the requested transaction
   */
  error FundMe__TransactionNotFound(uint256 transactionId);

  /** @notice throw when erc20 contract transfer is unsuccessful
   *  @param erc20 the contract address that failed token transfer
   */
  error FundMe__ERC20TransferUnsuccessful(address erc20);

  /** @notice throw when erc20 contract does not comply to normal erc20 interface
   *  @param nonCompliantErc20 the contract address that failed token transfer
   */
  error FundMe__NonCompliantERC20(address nonCompliantErc20);

  /// @notice throw when receiver tries to initilize more than allowedNumberOfMilestones milestones
  error FundMe__TooManyMilestonesInitilized();

  /// @notice throw when a transactions sum of all milestones amountUnlockable does not total 1 ether
  error FundMe__MilestoneAmountUnlockablePercentageNot1();

  /// @notice throw when the zero address is not a useable address
  error FundMe__ZeroAddressInvalid();

  /// @notice throw when the FundMe contract address is not a useable address
  error FundMe__FundMeContractAddressInvalid();
}
