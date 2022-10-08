// SPDX-License-Identifier: MIT

/**
 *  @authors: [@ljrahn]
 *  @reviewers: []
 *  @auditors: []
 *  @bounties: []
 *  @deployments: []
 */

pragma solidity 0.8.13;

import "../interfaces/IFundMeCore.sol";
import "../libs/Arrays64.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/utils/introspection/ERC165.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "hardhat/console.sol";

/** @title FundMeCore
 *  A contract storing ERC20 tokens raised in a crowdfunding event.
 */
contract FundMeCore is IFundMeCore, Ownable, ReentrancyGuard, ERC165 {
  // Lib for arrays
  using Arrays64 for uint64[];

  /**************************************/
  /**** State ***************************/
  /**************************************/

  /**** Constants ***********************/
  Constants public constants;

  /**** Amount Payable ***************/
  // balance of native token to be paid from this contract.
  // account address --> returns native token balance
  mapping(address => uint256) public balanceNativeToken;

  // balance of an erc20 token to be paid from this contract. note that in order to keep track of the tokens to be paid to an address, an indexer like
  // thegraph will be very useful for this
  // account address => erc20 contract address --> returns balance of erc20 token to be paid to account address
  mapping(address => mapping(address => uint256)) public balanceCrowdFundToken;

  /**** Transaction State ***************/
  uint32 public transactionIdCounter;
  mapping(uint32 => Transaction) private transactions; // mapping of all of the transactions

  // The total amount that has been funded to a transaction for a given address, denominated in the specified erc20 token
  // transactionId => funders address --> returns amount funded towards transaction[id]
  mapping(uint32 => mapping(address => uint256)) public transactionAddressAmountFunded;

  /**** Milestone State ****************/
  // The total amount that has been funded to a milestone dispute for a given address, denominated in ETH
  // transactionId => milestoneId => dispute funders address --> returns amount funded dispute for milestone transaction[transactionId].milestones[milestoneId]
  mapping(uint32 => mapping(uint16 => mapping(address => uint256))) private milestoneAddressDisputeAmountFunded;

  /** @dev Constructor. Choose the arbitrator.
   *  @param _arbitrator The arbitrator of the contract.
   *  @param _allowedNumberOfMilestones maximum number of allowed milestones included in a transaction
   *  @param _createTransactionCost cost of creating a transaction
   *  @param _appealFeeTimeout amount of time given to provide appeal fee before dispute closes and apposing side wins
   */
  constructor(
    address _arbitrator,
    uint16 _allowedNumberOfMilestones,
    uint128 _createTransactionCost,
    uint64 _appealFeeTimeout
  ) {
    transactionIdCounter = 0;
    constants.arbitrator = IArbitrator(_arbitrator);
    constants.allowedNumberOfMilestones = _allowedNumberOfMilestones;
    constants.createTransactionCost = _createTransactionCost;
    constants.appealFeeTimeout = _appealFeeTimeout;
  }

  /**************************************/
  /**** Modifiers ***********************/
  /**************************************/

  /** @notice only the owner of the transaction can execute
   *  @param _transactionId ID of the transaction.
   */
  modifier onlyTransactionReceiver(uint32 _transactionId) {
    if (transactions[_transactionId].receiver != msg.sender) {
      revert FundMe__OnlyTransactionReceiver({
        requiredReceiver: transactions[_transactionId].receiver,
        sender: msg.sender
      });
    }
    _;
  }

  /** @notice can only execute function if the transaction exists
   *  @param _transactionId ID of the transaction.
   */
  modifier transactionExists(uint32 _transactionId) {
    // receiver address cannot be zero address, therefore the transaction does not exist if the receiver address is the 0 address
    if (transactions[_transactionId].receiver == address(0)) {
      revert FundMe__TransactionNotFound(_transactionId);
    }
    _;
  }

  /** @notice A check to make sure someone doesnt try to call claimMilestone() or requestClaimMilestone() on a milestone that
   *          that is not currently in progress
   *  @param _transactionId ID of the transaction.
   *  @param _milestoneId ID of the milestone.
   */
  modifier milestoneIdNotClaimable(uint32 _transactionId, uint16 _milestoneId) {
    Transaction memory _transaction = transactions[_transactionId];
    if (_transaction.nextClaimableMilestoneCounter != _milestoneId) {
      revert FundMe__MilestoneIdNotClaimable({
        milestoneIdRequired: _transaction.nextClaimableMilestoneCounter,
        milestoneIdGiven: _milestoneId
      });
    }
    _;
  }

  /**************************************/
  /**** Only Governor *******************/
  /**************************************/

  /// @notice See {IFundMeCore}
  function changeAllowedNumberOfMilestones(uint16 _allowedNumberOfMilestones) external override(IFundMeCore) onlyOwner {
    constants.allowedNumberOfMilestones = _allowedNumberOfMilestones;
  }

  /// @notice See {IFundMeCore}
  function changeCreateTransactionCost(uint128 _createTransactionCost) external override(IFundMeCore) onlyOwner {
    constants.createTransactionCost = _createTransactionCost;
  }

  /**************************************/
  /**** Only Transaction Receiver *******/
  /**************************************/

  /// @notice See {IFundMeCore}
  function changeTransactionReceiver(uint32 _transactionId, address _newTransactionReceiver)
    external
    override(IFundMeCore)
    onlyTransactionReceiver(_transactionId)
  {
    if (_newTransactionReceiver == address(0)) {
      revert FundMe__ZeroAddressInvalid();
    }
    if (_newTransactionReceiver == address(this)) {
      revert FundMe__FundMeContractAddressInvalid();
    }
    transactions[_transactionId].receiver = _newTransactionReceiver;
  }

  /**************************************/
  /**** Core Transactions ***************/
  /**************************************/

  /// @notice See {IFundMeCore}
  function createTransaction(
    uint64[] memory _milestoneAmountUnlockablePercentage,
    uint64 _receiverWithdrawTimeout,
    bytes memory _arbitratorExtraData,
    address _crowdfundToken,
    string memory _metaEvidenceUri
  ) public payable override(IFundMeCore) returns (uint32 transactionId) {
    if (msg.value < constants.createTransactionCost) {
      revert FundMe__PaymentTooSmall({amountRequired: constants.createTransactionCost, amountSent: uint128(msg.value)});
    }
    // milestone length must be less than the allowed number of milestones
    if (_milestoneAmountUnlockablePercentage.length > constants.allowedNumberOfMilestones) {
      revert FundMe__TooManyMilestonesInitilized();
    }
    if (_milestoneAmountUnlockablePercentage.getSum() != 1 ether) {
      revert FundMe__MilestoneAmountUnlockablePercentageNot1();
    }

    // check if the crowdfundToken is an erc20 compliant contract. NOTE that most erc20 contracts will not
    // have ERC165 standard implemented in them so its not possible to check using supportsInterface
    try IERC20(_crowdfundToken).totalSupply() {} catch {
      revert FundMe__NonCompliantERC20(_crowdfundToken);
    }

    transactionId = transactionIdCounter;
    Transaction storage _transaction = transactions[transactionId];

    _transaction.receiver = msg.sender;
    _transaction.timing.receiverWithdrawTimeout = _receiverWithdrawTimeout;
    _transaction.arbitratorExtraData = _arbitratorExtraData;
    _transaction.crowdfundToken = IERC20(_crowdfundToken);
    _transaction.voteToken = IERC20(_crowdfundToken); // TODO UPDATE WITH A VIABLE VOTING TOKEN!

    for (uint16 i = 0; i < _milestoneAmountUnlockablePercentage.length; i++) {
      Milestone[] storage _milestones = _transaction.milestones;
      _milestones.push(
        Milestone({
          amountUnlockablePercentage: _milestoneAmountUnlockablePercentage[i],
          amountClaimable: 0,
          disputeFeeReceiver: 0,
          disputeFeeFunders: 0,
          disputeId: 0,
          disputePayerForFunders: address(0),
          status: Status.Created
        })
      );
    }

    transactionIdCounter++;

    emit MetaEvidence(transactionId, _metaEvidenceUri);
    emit TransactionCreated(transactionId, msg.sender, _crowdfundToken);
  }

  /// @notice See {IFundMeCore}
  function fundTransaction(uint32 _transactionId, uint256 _amountFunded)
    public
    override(IFundMeCore)
    nonReentrant
    transactionExists(_transactionId)
  {
    Transaction storage _transaction = transactions[_transactionId];

    bool success = _transaction.crowdfundToken.transferFrom(msg.sender, address(this), _amountFunded);

    if (!success) {
      revert FundMe__ERC20TransferUnsuccessful(address(_transaction.crowdfundToken));
    }

    _transaction.totalFunded += _amountFunded;
    _transaction.remainingFunds += _amountFunded;
    transactionAddressAmountFunded[_transactionId][msg.sender] += _amountFunded;

    emit FundTransaction(_transactionId, msg.sender, _amountFunded);
  }

  /// @notice See {IFundMeCore} TODO Needs testing
  function requestClaimMilestone(
    uint32 _transactionId,
    uint16 _milestoneId,
    string memory _evidenceUri
  )
    public
    override(IFundMeCore)
    nonReentrant
    transactionExists(_transactionId)
    onlyTransactionReceiver(_transactionId)
    milestoneIdNotClaimable(_transactionId, _milestoneId)
  {
    Transaction storage _transaction = transactions[_transactionId];
    Milestone storage _milestone = _transaction.milestones[_milestoneId];

    if (_milestone.status != Status.Created) {
      revert FundMe__MilestoneStatusNotCreated(_transactionId, _milestoneId);
    }

    _transaction.timing.lastInteraction = uint64(block.timestamp);
    _milestone.status = Status.Claiming;

    // since funders can keep funding a transaction after milestones have been claimed, a milestones amountClaimable should
    // depend on the remaining milestones amountUnlockable. Therefore we need to adjust the % claimable such that the REMAINING
    // milestones amountUnlockablePercentage total to 100% (1 ether), then we can calculate the amountClaimable
    _milestone.amountClaimable = getMilestoneAmountClaimable(_transactionId, _milestoneId);
    // bitwise shift. this allows us to create a unique id for the evidence group.
    // this should be safe since transactionId and milestoneId will never exceed 2^128 this can be decoded if needed by:
    // _transactionId = uint128(_evidenceGroupId >> 128);  _milestoneId = uint128(_evidenceGroupId);
    uint256 _evidenceGroupId = (uint256(_transactionId) << 128) + uint256(_milestoneId);

    emit MilestoneProposed(_transactionId, _milestoneId);
    emit Evidence(
      constants.arbitrator,
      _evidenceGroupId,
      msg.sender, // What do i put for the party? funders can be many different addresses
      _evidenceUri
    );
  }

  /// @notice See {IFundMeCore} TODO Needs testing
  function claimMilestone(uint32 _transactionId, uint16 _milestoneId)
    public
    override(IFundMeCore)
    nonReentrant
    transactionExists(_transactionId)
    milestoneIdNotClaimable(_transactionId, _milestoneId)
  {
    Transaction storage _transaction = transactions[_transactionId];
    Milestone storage _milestone = _transaction.milestones[_milestoneId];

    if (_milestone.status != Status.Claiming) {
      revert FundMe__MilestoneStatusNotClaiming(_transactionId, _milestoneId);
    }

    // check to see receiverWithdrawTimeout has passed
    if (uint64(block.timestamp) - _transaction.timing.lastInteraction < _transaction.timing.receiverWithdrawTimeout) {
      revert FundMe__RequiredTimeoutNotPassed({
        requiredTimeout: _transaction.timing.receiverWithdrawTimeout,
        timePassed: uint64(block.timestamp) - _transaction.timing.lastInteraction
      });
    }

    // TODO Possibly need more checks.

    _transaction.nextClaimableMilestoneCounter += 1;
    _milestone.status = Status.Resolved;
    balanceCrowdFundToken[_transaction.receiver][address(_transaction.crowdfundToken)] = _milestone.amountClaimable;
    _transaction.remainingFunds -= _milestone.amountClaimable;

    emit MilestoneResolved(_transactionId, _milestoneId);
  }

  /// @notice See {IFundMeCore}
  function rule(uint256 _disputeId, uint256 _ruling) external override(IFundMeCore) {}

  /// @notice See {IFundMeCore}
  function payDisputeFeeByFunders(uint32 _transactionId, uint16 _milestoneId) public payable override(IFundMeCore) {
    // Transaction storage transaction = transactions[_transactionId];
    // uint256 arbitrationCost = constants.arbitrator.arbitrationCost(arbitratorExtraData);
    // require(
    //   transaction.status < Status.DisputeCreated,
    //   "Dispute has already been created or because the transaction has been executed."
    // );
    // require(msg.sender == transaction.receiver, "The caller must be the receiver.");
    // transaction.receiverFee += msg.value;
    // // Require that the total paid to be at least the arbitration cost.
    // require(transaction.receiverFee >= arbitrationCost, "The receiver fee must cover arbitration costs.");
    // transaction.lastInteraction = now;
    // // The sender still has to pay. This can also happen if he has paid, but arbitrationCost has increased.
    // if (transaction.senderFee < arbitrationCost) {
    //   transaction.status = Status.WaitingSender;
    //   emit HasToPayFee(_transactionID, Party.Sender);
    // } else {
    //   // The sender has also paid the fee. We create the dispute.
    //   raiseDispute(_transactionID, arbitrationCost);
    // }
  }

  /// @notice See {IFundMeCore}
  function withdraw(uint32 _transactionId, uint16 _milestoneId) public override(IFundMeCore) {}

  /// @notice See {IFundMeCore}
  function timeoutByFunders(uint32 _transactionId, uint16 _milestoneId) public override(IFundMeCore) {}

  /// @notice See {IFundMeCore}
  function appeal(uint32 _transactionId, uint16 _milestoneId) public payable override(IFundMeCore) {}

  /// @notice See {IFundMeCore}
  function supportsInterface(bytes4 interfaceId) public view override(ERC165) returns (bool) {
    return interfaceId == type(IFundMeCore).interfaceId || super.supportsInterface(interfaceId);
  }

  /**************************************/
  /**** internal functions ****************/
  /**************************************/

  /** @notice calculate the amountClaimable based on the REMAINING milestones left to claim and the transaction remainingFunds
   *  @param _transactionId ID of the transaction.
   *  @param _milestoneId ID of the milestone.
   *  @dev The reason we need to calculate the percentage claimable based on the remaining transactions is because funds
   *  can keep being added to the transaction after a milestone is claimed if funders want to continue supporting it.
   *  if we were to use the original milestone amountUnlockablePercentage to calculate milestone amountClaimable the total
   *  amount withdrawable would always be <= totalFunds deposited.
   *  TODO Needs testing
   */
  function getMilestoneAmountClaimable(uint32 _transactionId, uint16 _milestoneId)
    internal
    view
    returns (uint256 amountClaimable)
  {
    Transaction memory _transaction = transactions[_transactionId];

    uint64[] memory remainingMilestonesAmountUnlockable = new uint64[](_transaction.milestones.length - _milestoneId);
    // put the remaining milestones amountUnlockablePercentage into an array
    for (uint16 i = 0; i < remainingMilestonesAmountUnlockable.length; i++) {
      remainingMilestonesAmountUnlockable[i] = _transaction.milestones[i + _milestoneId].amountUnlockablePercentage;
    }

    // sum of remaining milestones amountUnlockablePercentage will total < 100% (1 ether). dividing each remaining milestone
    // amountUnlockablePercentage by the sum of all remaining amountUnlockablePercentage, and recalculating the sum of all those
    // values will yield a total of 100% (1 ether). since we only require percentage claimable for the given milestone, we only
    // calculate percentage claimable for the first index of the remaining milestones amountUnlockablePercentage
    uint256 percentageClaimable = (uint256(remainingMilestonesAmountUnlockable[0]) * 1 ether) /
      remainingMilestonesAmountUnlockable.getSum();
    // now we can calculate the amountClaimable of the erc20 crowdFundToken. since percentageClaimable is denominated by 1 ether
    // we must divide by 1 ether in order to to get an actual percentage as a fraction (if percentageClaimable for a given
    // milestone was 0.2 ether the amount claimable should be remainingFunds * 0.2, NOT remainingFunds * 0.2 ether)
    amountClaimable = (_transaction.remainingFunds * percentageClaimable) / 1 ether;
  }

  /** @dev Execute a ruling of a dispute.
   *  @param _disputeID ID of the dispute in the Arbitrator contract.
   *  @param _ruling Ruling given by the arbitrator. Note that 0 is reserved for "Not able/wanting to make a decision".
   */
  function executeRuling(uint256 _disputeID, uint256 _ruling) internal {}

  /** @notice Create a dispute.
   *  @param _milestoneID The milestone which is disputed.
   *  @param _arbitrationCost The amount which should be paid to the arbitrator.
   */
  function createDispute(
    uint32 _transactionId,
    uint16 _milestoneID,
    uint128 _arbitrationCost
  ) internal {}

  /**************************************/
  /**** public getters ******************/
  /**************************************/

  /** @notice fetch a transaction given a transactionId
   *  @param transactionId ID of the transaction.
   */
  function getTransaction(uint32 transactionId) public view returns (Transaction memory _transaction) {
    _transaction = transactions[transactionId];
  }

  /** @notice fetch a milestone given a transactionId and milestoneId
   *  @param transactionId ID of the transaction.
   *  @param transactionId ID of the milestone.
   *  @dev milestoneId is indexed starting at 0 for every transaction. That is milestoneId's are NOT unique between transactions.
   */
  function getTransactionMilestone(uint32 transactionId, uint16 milestoneId)
    public
    view
    returns (Milestone memory _milestone)
  {
    _milestone = transactions[transactionId].milestones[milestoneId];
  }
}
