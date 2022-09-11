// SPDX-License-Identifier: MIT
pragma solidity 0.8.13;

import "../interfaces/IArbitrable.sol";
import "../interfaces/IEvidence.sol";
import "../interfaces/IArbitrator.sol";
import "../interfaces/IFundMeErrors.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

/** @title FundMe
 *  A contract storing ERC20 tokens raised in a crowdfunding event.
 */
interface IFundMeCore is IArbitrable, IEvidence, IFundMeErrors {
  /**************************************/
  /**** Types ***************************/
  /**************************************/

  enum Status {
    NoDispute,
    WaitingSender,
    WaitingReceiver,
    DisputeCreated,
    Resolved
  }

  struct Milestone {
    uint256 amountUnlockablePercentage; /* The amount as a percentage which can be unlocked for this milestone (value for each milestone 
            is measured between 0 and 1 ether ie. 0.2 ether corresponds to 20%) */
    uint256 amountClaimable; // The amount claimable which is declared when receiver wants to claim a milestone
    bool claimed; // boolean to track if the funds have been claimed
    uint256 disputeFeeReceiver; // Arbitration fee paid by the receiver denominated in ETH
    uint256 disputeFeeFunders; // Arbitration fee paid by all funders denominated in ETH  TODO HIGH LEVEL QUESTION: 3!
    uint256 disputeId; // ID of the dispute if this claim is disputed.
    address disputePayerForFunders; // The address who first paid the arbitration fee and will be refunded in case of victory. TODO HIGH LEVEL QUESTION: 3!
    Status status; // the dispute status for a milestone. TODO IMPLEMENTATION QUESTION: 1! Should disputes occur at the milestone level
  }

  struct Transaction {
    address receiver; // the address that will be paid in the case of completing a dispute
    uint256 totalFunded; // Total amount funded denominated in the given erc20 token
    uint256 remainingFunds; // Total amount funded denominated in the given erc20 token
    uint256 nextClaimableMilestoneCounter; // a counter used to track the next milestone which can be claimed
    Milestone[] milestones; // All the milestones to be completed for this crowdfunding event
    IERC20 crowdfundToken; // Token used for the crowdfunding event. The receiver will be paid in this token
    IERC20 voteToken; // token which will be used to vote in the case of a dispute. TODO HIGH LEVEL QUESTION: 6! Do we want a vote token?
  }

  /**************************************/
  /**** Events **************************/
  /**************************************/

  /** @notice Emitted when a transaction is created.
   *  @param _transactionID The ID of the transaction.
   *  @param _receiver The address of the receiver. (creator of the transaction)
   *  @param _crowdFundToken the token address used for the transaction
   */
  event TransactionCreated(uint256 indexed _transactionID, address indexed _receiver, address indexed _crowdFundToken);

  /** @notice Emitted when a transaction is funded.
   *  @param _transactionID The ID of the transaction.
   *  @param _amountFunded The amount funded to the transaction
   *  @param _amountFunded The amount funded to the transaction
   */
  event FundTransaction(uint256 indexed _transactionID, address indexed _sender, uint256 _amountFunded);

  /**************************************/
  /**** Only Governor *******************/
  /**************************************/

  /** @notice change the allowed number of milestones only callable by the contract governor
   *  @param _allowedNumberOfMilestones the updated number of milestones allowed to be created
   */
  function changeAllowedNumberOfMilestones(uint256 _allowedNumberOfMilestones) external;

  /** @notice change the cost to create a transaction only callable by the transaction governor
   *  @param _createTransactionCost the updated cost in order to create a transaction
   */
  function changeCreateTransactionCost(uint256 _createTransactionCost) external;

  /**************************************/
  /**** Only Transaction Receiver *******/
  /**************************************/

  /** @notice change the receiver address for a given transaction only callable by transaction receiver
   *  @param transactionId ID of the transaction.
   *  @param newTransactionReceiver the address of the new transaction receiver
   */
  function changeTransactionReceiver(uint256 transactionId, address newTransactionReceiver) external;

  /**************************************/
  /**** Core Transactions ***************/
  /**************************************/

  /** @notice Create a transaction.
   *  @param _milestoneAmountUnlockablePercentage an array of the % withdrawable from each milestone denominated by 1 ether (see struct Milestone {amountUnlockable})
   *  @param _crowdfundToken The erc20 token to be used in the crowdfunding event
   *  @param _metaEvidenceUri Link to the meta-evidence
   *  @return transactionId The index of the transaction.
   */
  function createTransaction(
    uint256[] memory _milestoneAmountUnlockablePercentage,
    address _crowdfundToken,
    string memory _metaEvidenceUri
  ) external payable returns (uint256 transactionId);

  /** @notice declare a ruling only callable by the arbitrator
   *  @param _disputeID the dispute ID
   *  @param _ruling the ruling declarded by the arbitrator
   */
  function rule(uint256 _disputeID, uint256 _ruling) external;

  /** @notice Give funds to a transaction
   *  @param _transactionId the ID of the transaction
   *  @param _amountFunded amount to fund to transactionId of the corresponding transactions crowdfundToken
   */
  function fundTransaction(uint256 _transactionId, uint256 _amountFunded) external;

  /** @notice Request to claim a milestone, can only be called by the transaction receiver
   *  @param _transactionId The ID of the transaction to claim funds from
   *  @param _milestoneId The ID of the milestone to claim funds of
   */
  function requestClaimMilestone(
    uint256 _transactionId,
    uint256 _milestoneId,
    string memory _evidenceUri
  ) external;

  /** @notice Pay fee to dispute a milestone. To be called by parties claiming the milestone was not completed.
   *  The first party to pay the fee entirely will be reimbursed if the dispute is won.
   *  @param _transactionId The transaction ID
   *  @param _milestoneId The milestone ID which is disputed.
   */
  function payDisputeFeeByFunders(uint256 _transactionId, uint256 _milestoneId) external payable;

  /** @notice Withdraw the money claimed in a milestone. to be called when a dispute has not been created within the time limit.
   *  @param _transactionId the transaction ID
   *  @param _milestoneId the milestone ID to withdraw funds
   */
  function withdraw(uint256 _transactionId, uint256 _milestoneId) external;

  /** @notice timeout to use whe the receiver doesnt pay the dispute fee
   *  @param _transactionId the transaction ID
   *  @param _milestoneId the milestone ID to call timeout on
   */
  function timeoutByFunders(uint256 _transactionId, uint256 _milestoneId) external;

  /** @notice Appeal an appealable ruling. Transfer the funds to the arbitrator.
   *  @param _transactionId the transaction ID
   *  @param _milestoneId the milestone ID to appeal
   */
  function appeal(uint256 _transactionId, uint256 _milestoneId) external payable;
}
