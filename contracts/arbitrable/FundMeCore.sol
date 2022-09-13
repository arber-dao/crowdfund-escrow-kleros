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
import "../libs/Arrays.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/utils/introspection/ERC165.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "hardhat/console.sol";

/** @title FundMeCore
 *  A contract storing ERC20 tokens raised in a crowdfunding event.
 */
abstract contract FundMeCore is IFundMeCore, Ownable, ReentrancyGuard, ERC165 {
  // Lib for arrays
  using Arrays for uint256[];

  /**************************************/
  /**** State ***************************/
  /**************************************/

  /**** Constants ***********************/
  uint256 public allowedNumberOfMilestones; // The allowed number of milestones in a transaction. NOTE MAX = 2^16
  uint256 createTransactionCost; // the amount of eth to send when calling createTransaction

  address public governor; // The address of the governor contract
  IArbitrator public arbitrator;

  /**** Transaction State ***************/
  uint256 public transactionIdCounter;
  mapping(uint256 => Transaction) private transactions; // mapping of all of the transactions

  // The total amount that has been funded to a transaction for a given address, denominated in the specified erc20 token
  // transactionId => funders address --> returns amount funded towards transaction[id]
  mapping(uint256 => mapping(address => uint256)) public transactionAddressAmountFunded;

  /**** Milestone State ****************/
  // The total amount that has been funded to a milestone dispute for a given address, denominated in ETH
  // transactionId => milestoneId => dispute funders address --> returns amount funded dispute for milestone transaction[transactionId].milestones[milestoneId]
  mapping(uint256 => mapping(uint64 => mapping(address => uint256))) private milestoneAddressDisputeAmountFunded;

  /** @dev Constructor. Choose the arbitrator.
   *  @param _arbitrator The arbitrator of the contract.
   *  @param _arbitratorExtraData arbitrator extradata
   */
  constructor(
    address _arbitrator,
    bytes memory _arbitratorExtraData,
    uint16 _allowedNumberOfMilestones,
    uint256 _createTransactionCost
  ) {
    arbitrator = IArbitrator(_arbitrator);
    transactionIdCounter = 0;
    allowedNumberOfMilestones = _allowedNumberOfMilestones;
    createTransactionCost = _createTransactionCost;
  }

  /**************************************/
  /**** Modifiers ***********************/
  /**************************************/

  /** @notice only the owner of the transaction can execute
   *  @param _transactionId ID of the transaction.
   */
  modifier onlyTransactionReceiver(uint256 _transactionId) {
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
  modifier transactionExists(uint256 _transactionId) {
    // receiver address cannot be zero address, therefore the transaction does not exist if the receiver address is the 0 address
    if (transactions[_transactionId].receiver == address(0)) {
      revert FundMe__TransactionNotFound(_transactionId);
    }
    _;
  }

  /**************************************/
  /**** Only Governor *******************/
  /**************************************/

  /// @notice See {IFundMeCore}
  function changeAllowedNumberOfMilestones(uint256 _allowedNumberOfMilestones) external override onlyOwner {
    allowedNumberOfMilestones = _allowedNumberOfMilestones;
  }

  /// @notice See {IFundMeCore}
  function changeCreateTransactionCost(uint256 _createTransactionCost) external override onlyOwner {
    createTransactionCost = _createTransactionCost;
  }

  /**************************************/
  /**** Only Transaction Receiver *******/
  /**************************************/

  /// @notice See {IFundMeCore}
  function changeTransactionReceiver(uint256 transactionId, address newTransactionReceiver)
    external
    override
    onlyTransactionReceiver(transactionId)
  {
    if (newTransactionReceiver == address(0)) {
      revert FundMe__ZeroAddressInvalid();
    }
    if (newTransactionReceiver == address(this)) {
      revert FundMe__FundMeContractAddressInvalid();
    }
    transactions[transactionId].receiver = newTransactionReceiver;
  }

  /**************************************/
  /**** Core Transactions ***************/
  /**************************************/

  /// @notice See {IFundMeCore}
  function createTransaction(
    uint256[] memory _milestoneAmountUnlockablePercentage,
    address _crowdfundToken,
    string memory _metaEvidenceUri
  ) public payable override returns (uint256 transactionId) {
    if (msg.value < createTransactionCost) {
      revert FundMe__PaymentTooSmall({amountRequired: createTransactionCost, amountSent: msg.value});
    }
    // milestone length must be less than the allowed number of milestones
    if (_milestoneAmountUnlockablePercentage.length > allowedNumberOfMilestones) {
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
    _transaction.crowdfundToken = IERC20(_crowdfundToken);
    _transaction.voteToken = IERC20(_crowdfundToken); // TODO UPDATE WITH A VIABLE VOTING TOKEN!

    for (uint256 i = 0; i < _milestoneAmountUnlockablePercentage.length; i++) {
      Milestone[] storage _milestones = _transaction.milestones;
      _milestones.push(
        Milestone({
          amountUnlockablePercentage: _milestoneAmountUnlockablePercentage[i],
          amountClaimable: 0,
          claimed: false,
          disputeFeeReceiver: 0,
          disputeFeeFunders: 0,
          disputeId: 0,
          disputePayerForFunders: address(0),
          status: Status.NoDispute
        })
      );
    }

    transactionIdCounter++;

    emit MetaEvidence(transactionId, _metaEvidenceUri);
    emit TransactionCreated(transactionId, msg.sender, _crowdfundToken);
  }

  function rule(uint256 _disputeID, uint256 _ruling) external override {}

  /// @notice See {IFundMeCore}
  function fundTransaction(uint256 _transactionId, uint256 _amountFunded)
    public
    override
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

  /// @notice See {IFundMeCore} TODO NOT COMPLETE!!!
  function requestClaimMilestone(
    uint256 _transactionId,
    uint256 _milestoneId,
    string memory _evidenceUri
  ) public override onlyTransactionReceiver(_transactionId) transactionExists(_transactionId) {
    Transaction storage _transaction = transactions[_transactionId];
    Milestone storage _milestone = _transaction.milestones[_milestoneId];

    if (_transaction.nextClaimableMilestoneCounter != _milestoneId) {
      revert FundMe__MilestoneIdNotClaimable({
        milestoneIdRequired: _transaction.nextClaimableMilestoneCounter,
        milestoneIdGiven: _milestoneId
      });
    }

    // TODO need more checks!!

    // since funders can keep funding a transaction after milestones have been claimed, a milestones amountClaimable should
    // depend on the remaining milestones amountUnlockable. Therefore we need to adjust the % claimable such that the REMAINING
    // milestones amountUnlockablePercentage total to 100% (1 ether), then we can calculate the amountClaimable
    _milestone.amountClaimable = getMilestoneAmountClaimable(_transactionId, _milestoneId);

    // bitwise shift. this allows us to create a unique id for the evidence group.
    // this should be safe since transactionId and milestoneId will never exceed 2^128 this can be decoded by:
    // _transactionId = uint128(_evidenceGroupId >> 128);  _milestoneId = uint128(_evidenceGroupId);
    uint256 _evidenceGroupId = (_transactionId << 128) + _milestoneId;

    emit Evidence(
      arbitrator,
      _evidenceGroupId,
      msg.sender, // What do i put for the party? funders can be many different addresses
      _evidenceUri
    );
  }

  /// @notice See {IFundMeCore}
  function payDisputeFeeByFunders(uint256 _transactionId, uint256 _milestoneId) public payable override {}

  /// @notice See {IFundMeCore}
  function withdraw(uint256 _milestoneID) public {}

  /// @notice See {IFundMeCore}
  function timeoutByFunders(uint256 _milestoneID) public {}

  /// @notice See {IFundMeCore}
  function appeal(uint256 _milestoneID) public payable {}

  /// @notice See {IFundMeCore}
  function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
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
  function getMilestoneAmountClaimable(uint256 _transactionId, uint256 _milestoneId)
    internal
    view
    returns (uint256 amountClaimable)
  {
    Transaction memory _transaction = transactions[_transactionId];

    uint256[] memory remainingMilestonesAmountUnlockable;

    // put the remaining milestones amountUnlockablePercentage into an array
    for (uint256 i = 0; i < _transaction.milestones.length - _milestoneId; i++) {
      remainingMilestonesAmountUnlockable[i] = _transaction.milestones[i + _milestoneId].amountUnlockablePercentage;
    }

    // sum of remaining milestones amountUnlockablePercentage will total < 100% (1 ether). dividing each remaining milestone
    // amountUnlockablePercentage by the sum of all remaining amountUnlockablePercentage, and recalculating the sum of all those
    // values will yield a total of 100% (1 ether). since we only require percentage claimable for the given milestone, we only
    // calculate percentage claimable for the first index of the remaining milestones amountUnlockablePercentage
    uint256 percentageClaimable = remainingMilestonesAmountUnlockable[0] / remainingMilestonesAmountUnlockable.getSum();

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
  function createDispute(uint256 _milestoneID, uint256 _arbitrationCost) internal {}

  /**************************************/
  /**** public getters ******************/
  /**************************************/

  /** @notice fetch a transaction given a transactionId
   *  @param transactionId ID of the transaction.
   */
  function getTransaction(uint256 transactionId) public view returns (Transaction memory _transaction) {
    _transaction = transactions[transactionId];
  }

  /** @notice fetch a milestone given a transactionId and milestoneId
   *  @param transactionId ID of the transaction.
   *  @param transactionId ID of the milestone.
   *  @dev milestoneId is indexed starting at 0 for every transaction. That is milestoneId's are NOT unique between transactions.
   */
  function getTransactionMilestone(uint256 transactionId, uint256 milestoneId)
    public
    view
    returns (Milestone memory _milestone)
  {
    _milestone = transactions[transactionId].milestones[milestoneId];
  }
}
