// SPDX-License-Identifier: MIT

/**
 *  @authors: [@ljrahn]
 *  @reviewers: []
 *  @auditors: []
 *  @bounties: []
 *  @deployments: []
 */

pragma solidity 0.8.13;

import {IFundMeCore} from "../interfaces/IFundMeCore.sol";
import {IArbitrator} from "../interfaces/IArbitrator.sol";
import {Arrays64} from "../libs/Arrays64.sol";
import {ReentrancyGuard} from "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import {ERC165} from "@openzeppelin/contracts/utils/introspection/ERC165.sol";
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";

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

  // balance of an erc20 token to be paid from this contract. NOTE that in order to keep track of the tokens to be paid to an address, an indexer like
  // thegraph will be very useful for this
  // account address => erc20 contract address --> returns balance of erc20 token to be paid to account address
  // NOTE that if the address for the second mapping (erc20 contract address) is the 0 address, that indicates the native token balance (ETH)
  mapping(address => mapping(address => uint256)) public accountBalance;

  /**** Project State ***************/
  uint32 public projectIdCounter;
  mapping(uint32 => Project) private projects; // mapping of all of the projects

  // projectId => donors address --> returns ProjectDonorDetails
  mapping(uint32 => mapping(address => ProjectDonorDetails)) public projectDonorDetails;

  /**** Dispute State ******************/
  uint32 public localDisputeIdCounter;
  mapping(uint32 => DisputeStruct) public disputes;
  mapping(uint256 => uint32) public externalDisputeIdToLocalDisputeId; // Maps external (arbitrator side) dispute IDs to local dispute IDs.

  /**** Milestone State ****************/

  /** @dev Constructor. Choose the arbitrator.
   *  @param _arbitrator The arbitrator of the contract.
   *  @param _allowedNumberOfMilestones maximum number of allowed milestones included in a project
   *  @param _createProjectCost cost of creating a project
   */
  constructor(address _arbitrator, uint16 _allowedNumberOfMilestones, uint128 _createProjectCost) {
    constants.arbitrator = IArbitrator(_arbitrator);
    constants.allowedNumberOfMilestones = _allowedNumberOfMilestones;
    constants.createProjectCost = _createProjectCost;

    // fill the 0 spot for projects
    projectIdCounter++;

    // fill the 0 spot for disputes
    localDisputeIdCounter++;
  }

  /**************************************/
  /**** Modifiers ***********************/
  /**************************************/

  /** @notice only the owner of the project can execute
   *  @param _projectId ID of the project.
   */
  modifier onlyProjectCreator(uint32 _projectId) {
    if (projects[_projectId].creator != msg.sender) {
      revert FundMe__OnlyProjectCreator({creator: projects[_projectId].creator});
    }
    _;
  }

  /** @notice can only execute function if the project exists
   *  @param _projectId ID of the project.
   */
  modifier projectExists(uint32 _projectId) {
    // creator address cannot be zero address, therefore the project does not exist if the creator address is the 0 address
    if (projects[_projectId].creator == address(0)) {
      revert FundMe__ProjectNotFound(_projectId);
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
  function changeCreateProjectCost(uint128 _createProjectCost) external override(IFundMeCore) onlyOwner {
    constants.createProjectCost = _createProjectCost;
  }

  /**************************************/
  /**** Only Project Creator *******/
  /**************************************/

  /// @notice See {IFundMeCore}
  function changeProjectCreator(
    uint32 _projectId,
    address _newProjectCreator
  ) external override(IFundMeCore) onlyProjectCreator(_projectId) {
    if (_newProjectCreator == address(0)) {
      revert FundMe__ZeroAddressInvalid();
    }
    if (_newProjectCreator == address(this)) {
      revert FundMe__FundMeContractAddressInvalid();
    }
    projects[_projectId].creator = _newProjectCreator;
  }

  /**************************************/
  /**** Only Donors ********************/
  /**************************************/

  /**************************************/
  /**** Core Projects ***************/
  /**************************************/

  /// @notice See {IFundMeCore}
  function createProject(
    uint64[] memory _milestoneAmountUnlockablePercentage,
    bytes[] memory _milestoneArbitratorExtraData,
    uint64 _creatorWithdrawTimeout,
    address _crowdfundToken,
    string memory _metaEvidenceUri
  ) public payable override(IFundMeCore) returns (uint32 projectId) {
    if (msg.value < constants.createProjectCost) {
      revert FundMe__PaymentTooSmall({amountRequired: constants.createProjectCost, amountSent: uint128(msg.value)});
    }
    // milestone length must be less than the allowed number of milestones
    if (
      _milestoneAmountUnlockablePercentage.length > constants.allowedNumberOfMilestones &&
      _milestoneAmountUnlockablePercentage.length > 0
    ) {
      revert FundMe__IncorrectNumberOfMilestoneInitilized({min: 1, max: constants.allowedNumberOfMilestones});
    }
    if (_milestoneAmountUnlockablePercentage.getSum() != 1 ether) {
      revert FundMe__MilestoneAmountUnlockablePercentageNot1();
    }
    if (_milestoneAmountUnlockablePercentage.length != _milestoneArbitratorExtraData.length) {
      revert FundMe__MilestoneDataMismatch();
    }
    // check if the crowdfundToken is an erc20 compliant contract. NOTE that most erc20 contracts will not
    // have ERC165 standard implemented in them so its not possible to check using supportsInterface
    try IERC20(_crowdfundToken).totalSupply() {} catch {
      revert FundMe__NonCompliantERC20(_crowdfundToken);
    }
    projectId = projectIdCounter;
    Project storage _project = projects[projectId];
    _project.creator = msg.sender;
    _project.timing.creatorWithdrawTimeout = _creatorWithdrawTimeout;
    _project.crowdfundToken = IERC20(_crowdfundToken);
    for (uint16 i = 0; i < _milestoneAmountUnlockablePercentage.length; i++) {
      Milestone[] storage _milestones = _project.milestones;
      _milestones.push(
        Milestone({
          amountUnlockablePercentage: _milestoneAmountUnlockablePercentage[i],
          arbitratorExtraData: _milestoneArbitratorExtraData[i],
          amountClaimable: 0,
          status: Status.Created
        })
      );
    }
    projectIdCounter++;
    emit MetaEvidence(projectId, _metaEvidenceUri); // projectId == MetaEvidenceId
    emit ProjectCreated(projectId, msg.sender, _crowdfundToken);
  }

  /// @notice See {IFundMeCore}
  // TODO needs testing!
  function donateProject(
    uint32 _projectId,
    uint256 _amountFunded
  ) public override(IFundMeCore) nonReentrant projectExists(_projectId) {
    Project storage _project = projects[_projectId];

    // covers edge case where donor has never funded this disputed project
    hasDonorNeverFundedDisputedProject(_projectId);

    if (!isDonorRefunded(_projectId)) {
      revert FundMe__NotRefundedForDispute({latestDisputeId: _project.latestRefundableDisputeId});
    }

    _project.crowdfundToken.transferFrom(msg.sender, address(this), _amountFunded);

    _project.projectFunds.totalFunded += _amountFunded;
    _project.projectFunds.remainingFunds += _amountFunded;
    projectDonorDetails[_projectId][msg.sender].amountFunded += _amountFunded;

    emit FundProject(_projectId, msg.sender, _amountFunded);
  }

  /// @notice See {IFundMeCore} TODO Needs testing
  function requestClaimMilestone(
    uint32 _projectId,
    string memory _evidenceUri
  ) public override(IFundMeCore) nonReentrant projectExists(_projectId) onlyProjectCreator(_projectId) {
    Project storage _project = projects[_projectId];
    uint16 _milestoneId = _project.nextClaimableMilestoneCounter;
    Milestone storage _milestone = _project.milestones[_milestoneId];

    if (_milestone.status != Status.Created) {
      revert FundMe__MilestoneStatusNotCreated(_projectId, _milestoneId);
    }

    _project.timing.lastInteraction = uint64(block.timestamp);
    _milestone.status = Status.Claiming;

    // since donors can keep funding a project after milestones have been claimed, a milestones amountClaimable should
    // depend on the remaining milestones amountUnlockable. Therefore we need to adjust the % claimable such that the REMAINING
    // milestones amountUnlockablePercentage total to 100% (1 ether), then we can calculate the amountClaimable
    _milestone.amountClaimable = getMilestoneAmountClaimable(_projectId);

    emit MilestoneProposed(_projectId, _milestoneId);
    emit Evidence(
      constants.arbitrator,
      getEvidenceGroupId(_projectId, _milestoneId),
      msg.sender, // What do i put for the party? donors can be many different addresses
      _evidenceUri
    );
  }

  /// @notice See {IFundMeCore} TODO Needs testing
  function claimMilestone(uint32 _projectId) public override(IFundMeCore) nonReentrant projectExists(_projectId) {
    Project storage _project = projects[_projectId];
    uint16 _milestoneId = _project.nextClaimableMilestoneCounter;
    Milestone storage _milestone = _project.milestones[_milestoneId];

    if (_milestone.status != Status.Claiming) {
      revert FundMe__MilestoneStatusNotClaiming(_projectId, _milestoneId);
    }

    // check to see creatorWithdrawTimeout has passed
    if (uint64(block.timestamp) - _project.timing.lastInteraction < _project.timing.creatorWithdrawTimeout) {
      revert FundMe__RequiredTimeoutNotPassed({
        requiredTimeout: _project.timing.creatorWithdrawTimeout,
        timePassed: uint64(block.timestamp) - _project.timing.lastInteraction
      });
    }

    // TODO Possibly need more checks.

    _project.nextClaimableMilestoneCounter += 1;
    _milestone.status = Status.Resolved;
    accountBalance[_project.creator][address(_project.crowdfundToken)] += _milestone.amountClaimable;
    _project.projectFunds.remainingFunds -= _milestone.amountClaimable;

    emit BalanceUpdate(
      _project.creator,
      address(_project.crowdfundToken),
      accountBalance[_project.creator][address(_project.crowdfundToken)]
    );
    emit MilestoneResolved(_projectId, _milestoneId);
  }

  /// @notice See {IFundMeCore}
  function rule(uint256 _disputeId, uint256 _ruling) external override(IFundMeCore) {
    if (_ruling > uint256(DisputeChoices.CreatorWins)) {
      revert FundMe__InvalidRuling({rulingGiven: _ruling, numberOfChoices: uint256(DisputeChoices.CreatorWins)});
    }

    DisputeChoices ruling = DisputeChoices(_ruling);
    uint32 _localDisputeId = externalDisputeIdToLocalDisputeId[_disputeId];
    DisputeStruct memory dispute = disputes[_localDisputeId];
    Project memory _project = projects[dispute.projectId];
    Milestone memory _milestone = _project.milestones[dispute.milestoneId];

    if (msg.sender != address(constants.arbitrator)) {
      revert FundMe__OnlyArbitrator({arbitrator: address(constants.arbitrator)});
    }

    if (dispute.isRuled) {
      revert FundMe__DisputeAlreadyRuled();
    }

    if (_milestone.status != Status.DisputeCreated) {
      revert FundMe__MilestoneStatusNotCreated({projectId: dispute.projectId, milestoneId: dispute.milestoneId});
    }

    executeRuling(_localDisputeId, ruling);
  }

  /// @notice See {IFundMeCore} TODO needs testing!
  function createDispute(uint32 _projectId) public payable override(IFundMeCore) projectExists(_projectId) {
    Project storage _project = projects[_projectId];
    uint16 _milestoneId = _project.nextClaimableMilestoneCounter;
    Milestone storage _milestone = _project.milestones[_milestoneId];
    uint256 arbitrationCost = constants.arbitrator.arbitrationCost(_milestone.arbitratorExtraData);

    if (_milestone.status != Status.Claiming) {
      revert FundMe__MilestoneStatusNotClaiming(_projectId, _milestoneId);
    }

    _project.paidDisputeFees += uint128(msg.value);
    uint256 _refundAmount = 0;

    if (uint256(_project.paidDisputeFees) < arbitrationCost) {
      // dispute requires more funds, emit event that indicates this and exit the function
      emit DisputeContribution({
        _projectId: _projectId,
        _milestoneId: _milestoneId,
        _donor: msg.sender,
        _amountContributed: uint128(msg.value),
        _amountRequired: uint128(arbitrationCost),
        _amountPaid: _project.paidDisputeFees
      });
      return;
    } else if (uint256(_project.paidDisputeFees) > arbitrationCost) {
      // dispute fee was overpaid, adjust account balance, and set disputeFee to the arbitration cost
      _refundAmount = uint256(_project.paidDisputeFees) - arbitrationCost;

      accountBalance[msg.sender][address(0)] += _refundAmount;
      _project.paidDisputeFees = uint128(arbitrationCost);
      emit BalanceUpdate(msg.sender, address(0), accountBalance[msg.sender][address(0)]);
    }

    // the following will execute only one time, and will only execute when the dispute fee has been fully paid
    emit DisputeContribution({
      _projectId: _projectId,
      _milestoneId: _milestoneId,
      _donor: msg.sender,
      _amountContributed: uint128(msg.value - _refundAmount),
      _amountRequired: _project.paidDisputeFees,
      _amountPaid: _project.paidDisputeFees
    });

    uint32 localDisputeId = localDisputeIdCounter;
    disputes[localDisputeId] = DisputeStruct({
      projectId: _projectId,
      milestoneId: _milestoneId,
      isRuled: false,
      ruling: DisputeChoices(0)
    });

    uint256 externalDisputeId = constants.arbitrator.createDispute{value: arbitrationCost}(
      uint256(DisputeChoices.CreatorWins), //number of ruling options
      _milestone.arbitratorExtraData
    );

    externalDisputeIdToLocalDisputeId[externalDisputeId] = localDisputeId;
    localDisputeIdCounter += 1;
    _milestone.status = Status.DisputeCreated;

    emit Dispute(
      constants.arbitrator,
      externalDisputeId,
      _projectId, // projectId == MetaEvidenceId
      getEvidenceGroupId(_projectId, _milestoneId)
    );
  }

  /// @notice See {IFundMeCore}
  function withdraw(address tokenAddress) public override(IFundMeCore) nonReentrant {
    uint256 balance = accountBalance[msg.sender][tokenAddress];
    if (balance > 0) {
      if (tokenAddress == address(0)) {
        (bool success, ) = payable(msg.sender).call{value: balance}("");
        // revert if transfer was not successful
        if (!success) {
          revert FundMe__TransferUnsuccessful();
        }
      } else {
        IERC20(tokenAddress).transfer(msg.sender, balance);
      }

      // NOTE contracts with modified fallbacks should still be able to use this contract. We dont want to update balance before incase low level
      // call fails so we modify after the transfer. Still guarded against reentrancy
      accountBalance[msg.sender][tokenAddress] = 0;
    } else {
      revert FundMe__NoWithdrawableFunds();
    }
  }

  /// @notice See {IFundMeCore}
  function refund(uint32 _projectId) public override(IFundMeCore) nonReentrant projectExists(_projectId) {
    Project storage _project = projects[_projectId];

    if (!isDonorRefunded(_projectId)) {
      uint256 _refundAmount = projectDonorDetails[_projectId][msg.sender].amountFunded;
      accountBalance[msg.sender][address(_project.crowdfundToken)] += _refundAmount;
      projectDonorDetails[_projectId][msg.sender].amountFunded = 0;
      projectDonorDetails[_projectId][msg.sender].latestRefundedDisputeId = _project.latestRefundableDisputeId;
    } else {
      revert FundMe__NoRefundableFunds();
    }
  }

  /// @notice See {IFundMeCore}
  function supportsInterface(bytes4 interfaceId) public view override(ERC165) returns (bool) {
    return interfaceId == type(IFundMeCore).interfaceId || super.supportsInterface(interfaceId);
  }

  /**************************************/
  /**** internal functions **************/
  /**************************************/

  /** @notice execute the ruling and modify the necessary state. called by rule()
   *  @param _localDisputeId local ID of the dispute.
   *  @param _ruling ruling ID in the form of DisputeChoices enum.
   *  TODO Needs testing
   */
  function executeRuling(uint32 _localDisputeId, DisputeChoices _ruling) internal {
    DisputeStruct storage _dispute = disputes[_localDisputeId];
    Project storage _project = projects[_dispute.projectId];
    Milestone storage _milestone = _project.milestones[_dispute.milestoneId];

    _dispute.isRuled = true;
    _dispute.ruling = _ruling;
    _project.paidDisputeFees = 0;

    if (_ruling == DisputeChoices.CreatorWins) {
      // maybe have to set timing.lastInteraction to 0 value so claim milestone can be called?
      _project.timing.lastInteraction = 0;
      _milestone.status = Status.Claiming;
      claimMilestone(_dispute.projectId);
    } else if (_ruling == DisputeChoices.DonorWins) {
      refundDonors(_dispute.projectId, _localDisputeId);
    } else {
      // TODO ruling was 'Refused to arbitrate', what to do here? For now refund the donors, the onus is on the creator to submit meaningful evidence
      refundDonors(_dispute.projectId, _localDisputeId);
    }
  }

  /** @notice modifies necessary state to refund the donors. NOTE that the donors still have to call refund() to actually have their funds refunded,
   *          and have to call withdraw() to actually withdraw refunded funds.
   *  @param _projectId ID of the project.
   *  @param _localDisputeId local ID of the dispute.
   *  TODO Needs testing
   */
  function refundDonors(uint32 _projectId, uint32 _localDisputeId) internal {
    Project storage _project = projects[_projectId];
    uint16 _milestoneId = _project.nextClaimableMilestoneCounter;
    Milestone storage _milestone = _project.milestones[_milestoneId];

    _project.latestRefundableDisputeId = _localDisputeId;

    _project.projectFunds.totalFunded -= _project.projectFunds.remainingFunds;
    _project.projectFunds.remainingFunds = 0;
    _milestone.status = Status.Created;
  }

  /** @notice calculate the amountClaimable based on the REMAINING milestones left to claim and the project remainingFunds
   *  @param _projectId ID of the project.
   *  @dev The reason we need to calculate the percentage claimable based on the remaining projects is because funds
   *  can keep being added to the project after a milestone is claimed if donors want to continue supporting it.
   *  if we were to use the original milestone amountUnlockablePercentage to calculate milestone amountClaimable the total
   *  amount withdrawable would always be <= totalFunds deposited.
   *  TODO Needs testing
   */
  function getMilestoneAmountClaimable(uint32 _projectId) internal view returns (uint256 amountClaimable) {
    Project memory _project = projects[_projectId];
    uint16 _milestoneId = _project.nextClaimableMilestoneCounter;

    uint64[] memory remainingMilestonesAmountUnlockable = new uint64[](_project.milestones.length - _milestoneId);
    // put the remaining milestones amountUnlockablePercentage into an array
    for (uint16 i = 0; i < remainingMilestonesAmountUnlockable.length; i++) {
      remainingMilestonesAmountUnlockable[i] = _project.milestones[i + _milestoneId].amountUnlockablePercentage;
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
    amountClaimable = (_project.projectFunds.remainingFunds * percentageClaimable) / 1 ether;
  }

  /** @notice check if the donor has been refunded
   *  @param _projectId ID of the project
   *  @dev if the latest disputeId the donor has been refunded for is less than the projects latest disputeId then we know that the donor has not
   *  been refunded because disputeIds are always incrementing so if theres a new dispute, then its dispute id will always be greater than the disputeId
   *  the donor has been refunded for IF they have not been refunded for the latest dispute, otherwise they will be equal
   *  TODO Needs testing
   */
  function isDonorRefunded(uint32 _projectId) internal view returns (bool) {
    Project memory _project = projects[_projectId];

    uint32 latestRefundedDisputeId = projectDonorDetails[_projectId][msg.sender].latestRefundedDisputeId;

    return
      (latestRefundedDisputeId < _project.latestRefundableDisputeId &&
        projectDonorDetails[_projectId][msg.sender].amountFunded > 0)
        ? false
        : true;
  }

  /** @notice check if the donor has never funded this project, and if it has been previously disputed, update the necessary state
   *  @param _projectId ID of the project
   *  @dev Covers the edge case where a donor has never funded a disputed project. They should still be able to fund this project, so we
           need to adjust the latestRefundedDisputeId. NOTE The UI should acknowledge the user that they are funding a preivously dispute project
   *  TODO Needs testing
   */
  function hasDonorNeverFundedDisputedProject(uint32 _projectId) internal {
    Project memory _project = projects[_projectId];

    uint32 latestRefundedDisputeId = projectDonorDetails[_projectId][msg.sender].latestRefundedDisputeId;

    if (
      latestRefundedDisputeId < _project.latestRefundableDisputeId &&
      projectDonorDetails[_projectId][msg.sender].amountFunded == 0
    ) {
      projectDonorDetails[_projectId][msg.sender].latestRefundedDisputeId = _project.latestRefundableDisputeId;
    }
  }

  /**************************************/
  /**** public getters ******************/
  /**************************************/

  /** @notice fetch a project given a projectId
   *  @param projectId ID of the project.
   */
  function getProject(uint32 projectId) public view returns (Project memory _project) {
    _project = projects[projectId];
  }

  /** @notice fetch a milestone given a projectId and milestoneId
   *  @param projectId ID of the project.
   *  @param milestoneId ID of the milestone.
   *  @dev milestoneId is indexed starting at 0 for every project. That is milestoneId's are NOT unique between projects.
   */
  function getProjectMilestone(uint32 projectId, uint16 milestoneId) public view returns (Milestone memory _milestone) {
    _milestone = projects[projectId].milestones[milestoneId];
  }

  /** @notice get evidenceGroupId for a given projectId, and milestoneId. this allows us to create a unique id for the evidence group.
   *  @param projectId ID of the project.
   *  @param milestoneId ID of the milestone.
   *  @dev bitwise shift allows us to create unique id. this should be safe since projectId and milestoneId will never exceed 2^128
   *       this can be decoded if needed by: _projectId = uint128(_evidenceGroupId >> 128); _milestoneId = uint128(_evidenceGroupId);
   */
  function getEvidenceGroupId(uint32 projectId, uint16 milestoneId) public pure returns (uint256 evidenceGroupId) {
    evidenceGroupId = (uint256(projectId) << 128) + uint256(milestoneId);
  }
}
