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

  /** @notice the current status of a milestone
   *  @param Created The milestone has been created
   *  @param Claiming The milestone has had a request to be claimed by the receiver. The milestone 
             can be disputed by the funders for the next receiverWithdrawTimeout seconds
   *  @param WaitingReceiver A request to dispute has been submitted by the funders. Currently
   *         waiting for the receiver to pay arbitration fee so dispute can be created
   *  @param DisputeCreated receiver has submitted arbitration fee, and a dispute has been forwarded
             to the kleros court for ruling
   *  @param Resolved milestone is complete, any disputes are resolved, and the milestone funds have 
             been transfered into the balance of the receiver
   */
  enum Status {
    Created,
    Claiming,
    WaitingReceiver,
    DisputeCreated,
    Resolved
  }

  struct Constants {
    IArbitrator arbitrator; // The address of the arbitrator
    address governor; // The address of the governor contract
    uint16 allowedNumberOfMilestones; // The allowed number of milestones in a transaction. NOTE MAX = 2^16 - 1 = 65535
    uint128 createTransactionCost; // the amount of eth to send when calling createTransaction. NOTE MAX = 2^128 - 1 = 3.4*10^20 ether
    uint64 appealFeeTimeout; /* Time in seconds a party can take to pay arbitration fees before being considered unresponsive at which point they lose 
                              the dispute. set by the governors. NOTE MAX = 2^64 - 1 seconds = 5.8*10^11 years. Safe */
  }

  struct Milestone {
    uint64 amountUnlockablePercentage; /* The amount as a percentage which can be unlocked for this milestone (value for each milestone 
            is measured between 0 and 1 ether ie. 0.2 ether corresponds to 20%). NOTE uint64 is safe since amountUnlockablePercentage cannot exceed
            1 ether and uint64 allows up to 18 ether  */
    uint256 amountClaimable; /* The amount claimable which is declared when receiver wants to claim a milestone. NOTE should be kept as uint256 incase 
            crowdfundToken has a very large supply */
    uint128 disputeFeeReceiver; // Arbitration fee paid by the receiver denominated in ETH. NOTE MAX = 2^128 - 1 = 3.4*10^20 ether
    uint128 disputeFeeFunders; // Arbitration fee paid by all funders denominated in ETH  TODO HIGH LEVEL QUESTION: 3!. NOTE MAX = 2^128 - 1 = 3.4*10^20 ether
    uint256 disputeId; // ID of the dispute if this claim is disputed. NOTE this must be uint256 since that is the type the kleros arbitrator passes to rule()
    address disputePayerForFunders; // The address who first paid the arbitration fee and will be refunded in case of victory. TODO HIGH LEVEL QUESTION: 3!
    Status status; // the dispute status for a milestone. TODO IMPLEMENTATION QUESTION: 1! Should disputes occur at the milestone level
  }

  struct Timer {
    uint64 receiverWithdrawTimeout; /* A time in seconds set in the transaction for the length of time that funders have to dispute a milestone. If this 
            time is exceeded, and there are no disputes, then the receiver may withdraw the according amount of funds for this milestone */
    uint64 lastInteraction; /* A reference point used for the former 2 timeouts for calculating whether appealFeeTimeout or receiverWithdrawTimeout time 
            has passed. This value will be set to block.timestamp in payDisputeFeeByFunders, requestClaimMilestone functions. */
  }

  struct Transaction {
    address receiver; // the address that will be paid in the case of completing a dispute
    uint256 totalFunded; // Total amount funded denominated in the given crowdfundToken
    uint256 remainingFunds; // Total amount of remaining funds in the transaction after milestones have been finalized. denominated in the given crowdfundToken
    uint16 nextClaimableMilestoneCounter; // a counter used to track the next milestone which can be claimed. NOTE MAX = 2^16 - 1 = 65535
    bytes arbitratorExtraData; /* Additional info about the dispute. We use it to pass the ID of the dispute's subcourt (first 32 bytes),
                                the minimum number of jurors required (next 32 bytes) and the ID of the specific dispute kit (last 32 bytes). */
    Timer timing;
    Milestone[] milestones; // All the milestones to be completed for this crowdfunding event
    IERC20 crowdfundToken; // Token used for the crowdfunding event. The receiver will be paid in this token
    IERC20 voteToken; // token which will be used to vote in the case of a dispute. TODO HIGH LEVEL QUESTION: 6! Do we want a vote token?
  }

  /**************************************/
  /**** Events **************************/
  /**************************************/

  /** @notice Emitted when a transaction is created.
   *  @param _transactionId The ID of the transaction.
   *  @param _receiver The address of the receiver. (creator of the transaction)
   *  @param _crowdFundToken the token address used for this crowdfunding event (transaction)
   */
  event TransactionCreated(uint32 indexed _transactionId, address indexed _receiver, address indexed _crowdFundToken);

  /** @notice Emitted when a transaction is funded.
   *  @param _transactionId The ID of the transaction.
   *  @param _sender the address that sent funds to _transactionId
   *  @param _amountFunded The amount funded to the transaction
   */
  event FundTransaction(uint32 indexed _transactionId, address indexed _sender, uint256 _amountFunded);

  /** @notice Emitted when a milestone completion is requested by receiver. This milestone can be disputed for time specified by 
              receiverWithdrawTimeout. 
   *  @param _transactionId The ID of the transaction.
   *  @param _milestoneId The ID of the milestone
   */
  event MilestoneProposed(uint32 indexed _transactionId, uint16 indexed _milestoneId);

  /** @notice Emitted when a milestone is resolved. At this point a specific amount of the crowdfund token has been placed into 
              the balance of the receiver. The receiver can now call withdraw to withdraw the funds to their address 
   *  @param _transactionId The ID of the transaction.
   *  @param _milestoneId The ID of the milestone
   */
  event MilestoneResolved(uint32 indexed _transactionId, uint16 indexed _milestoneId);

  /**************************************/
  /**** Only Governor *******************/
  /**************************************/

  /** @notice change the allowed number of milestones only callable by the contract governor
   *  @param _allowedNumberOfMilestones the updated number of milestones allowed to be created
   */
  function changeAllowedNumberOfMilestones(uint16 _allowedNumberOfMilestones) external;

  /** @notice change the cost to create a transaction only callable by the contract governor
   *  @param _createTransactionCost the updated cost in order to create a transaction
   */
  function changeCreateTransactionCost(uint128 _createTransactionCost) external;

  /**************************************/
  /**** Only Transaction Receiver *******/
  /**************************************/

  /** @notice change the receiver address for a given transaction only callable by transaction receiver
   *  @param _transactionId ID of the transaction.
   *  @param _newTransactionReceiver the address of the new transaction receiver
   */
  function changeTransactionReceiver(uint32 _transactionId, address _newTransactionReceiver) external;

  /**************************************/
  /**** Core Transactions ***************/
  /**************************************/

  /** @notice Create a transaction.
   *  @param _milestoneAmountUnlockablePercentage an array of the % withdrawable from each milestone denominated by 1 ether (see struct Milestone {amountUnlockable})
   *  @param _receiverWithdrawTimeout amount of time funders have to dispute a milestone
   *  @param _arbitratorExtraData The erc20 token to be used in the crowdfunding event
   *  @param _crowdfundToken The erc20 token to be used in the crowdfunding event
   *  @param _metaEvidenceUri Link to the meta-evidence
   *  @return transactionId The index of the transaction.
   */
  function createTransaction(
    uint64[] memory _milestoneAmountUnlockablePercentage,
    uint64 _receiverWithdrawTimeout,
    bytes memory _arbitratorExtraData,
    address _crowdfundToken,
    string memory _metaEvidenceUri
  ) external payable returns (uint32 transactionId);

  /** @notice declare a ruling only callable by the arbitrator
   *  @param _disputeId the dispute ID
   *  @param _ruling the ruling declarded by the arbitrator
   */
  function rule(uint256 _disputeId, uint256 _ruling) external override(IArbitrable);

  /** @notice Give funds to a transaction
   *  @param _transactionId the ID of the transaction
   *  @param _amountFunded amount to fund to transactionId of the corresponding transactions crowdfundToken
   */
  function fundTransaction(uint32 _transactionId, uint256 _amountFunded) external;

  /** @notice Request to claim a milestone, can only be called by the transaction receiver. at this point, the receiver must submit
              evidence they have completed the milestone. funders can submit a dispute until receiverWithdrawTimeout passes.
   *  @param _transactionId The ID of the transaction to claim funds from
   *  @param _milestoneId The ID of the milestone to claim funds of
   */
  function requestClaimMilestone(
    uint32 _transactionId,
    uint16 _milestoneId,
    string memory _evidenceUri
  ) external;

  /** @notice Claim a milestone. if receiverWithdrawTimeout has passed, anyone can call this function to transfer the milestone funds
              the milestone funds into the balance of the receiver.
   *  @param _transactionId The ID of the transaction to claim funds from
   *  @param _milestoneId The ID of the milestone to claim funds of
   */
  function claimMilestone(uint32 _transactionId, uint16 _milestoneId) external;

  /** @notice Pay fee to dispute a milestone. To be called by parties claiming the milestone was not completed.
   *  The first party to pay the fee entirely will be reimbursed if the dispute is won.
   *  @param _transactionId The transaction ID
   *  @param _milestoneId The milestone ID which is disputed.
   */
  function payDisputeFeeByFunders(uint32 _transactionId, uint16 _milestoneId) external payable;

  /** @notice Withdraw the money claimed in a milestone. to be called when a dispute has not been created within the time limit.
   *  @param _transactionId the transaction ID
   *  @param _milestoneId the milestone ID to withdraw funds
   */
  function withdraw(uint32 _transactionId, uint16 _milestoneId) external;

  /** @notice timeout to use whe the receiver doesnt pay the dispute fee
   *  @param _transactionId the transaction ID
   *  @param _milestoneId the milestone ID to call timeout on
   */
  function timeoutByFunders(uint32 _transactionId, uint16 _milestoneId) external;

  /** @notice Appeal an appealable ruling. Transfer the funds to the arbitrator.
   *  @param _transactionId the transaction ID
   *  @param _milestoneId the milestone ID to appeal
   */
  function appeal(uint32 _transactionId, uint16 _milestoneId) external payable;
}
