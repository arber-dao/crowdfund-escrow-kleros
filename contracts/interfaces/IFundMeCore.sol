// SPDX-License-Identifier: MIT
pragma solidity 0.8.13;

import {IArbitrable} from "../interfaces/IArbitrable.sol";
import {IEvidence} from "../interfaces/IEvidence.sol";
import {IArbitrator} from "../interfaces/IArbitrator.sol";
import {IFundMeErrors} from "../interfaces/IFundMeErrors.sol";
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";

/** @title FundMe
 *  A contract storing ERC20 tokens raised in a crowdfunding event.
 */
interface IFundMeCore is IArbitrable, IEvidence, IFundMeErrors {
  /**************************************/
  /**** Types ***************************/
  /**************************************/

  struct Constants {
    IArbitrator arbitrator; // The address of the arbitrator
    address governor; // The address of the governor contract
    uint16 allowedNumberOfMilestones; // The allowed number of milestones in a project. NOTE MAX = 2^16 - 1 = 65535
    uint128 createProjectCost; // the amount of eth to send when calling createProject. NOTE MAX = 2^128 - 1 = 3.4*10^20 ether
  }

  /** @notice the current status of a milestone
   *  @param Created The milestone has been created
   *  @param Claiming The milestone has had a request to be claimed by the creator. The milestone 
             can be disputed by the donors for the next creatorWithdrawTimeout seconds
   *  @param WaitingCreator A request to dispute has been submitted by the donors. Currently
   *         waiting for the creator to pay arbitration fee so dispute can be created
   *  @param DisputeCreated creator has submitted arbitration fee, and a dispute has been forwarded
             to the kleros court for ruling
   *  @param Resolved milestone is complete, any disputes are resolved, and the milestone funds have 
             been transfered into the balance of the creator
   */
  enum Status {
    Created,
    Claiming,
    DisputeCreated,
    Resolved
  }

  enum DisputeChoices {
    None,
    DonorWins,
    CreatorWins
  }

  struct DisputeStruct {
    uint32 projectId; // ID of the project
    uint16 milestoneId; // ID of the milestone
    bool isRuled; // Whether the dispute has been ruled or not.
    DisputeChoices ruling; // Ruling given by the arbitrator. corresponds to one of enum DisputeChoices
  }

  struct Milestone {
    uint64 amountUnlockablePercentage /* The amount as a percentage which can be unlocked for this milestone (value for each milestone 
            is measured between 0 and 1 ether ie. 0.2 ether corresponds to 20%). NOTE uint64 is safe since amountUnlockablePercentage cannot exceed
            1 ether and uint64 allows up to 18 ether  */;
    uint256 amountClaimable /* The amount claimable which is declared when creator wants to claim a milestone. NOTE should be kept as uint256 incase 
            crowdfundToken has a very large supply */;
    bytes arbitratorExtraData /* Additional info about the dispute. We use it to pass the ID of the dispute's subcourt (first 32 bytes),
                                the minimum number of jurors required (next 32 bytes) and the ID of the specific dispute kit (last 32 bytes). */;
    Status status; // the dispute status for a milestone. TODO IMPLEMENTATION QUESTION: 1! Should disputes occur at the milestone level
  }

  struct Timer {
    uint64 creatorWithdrawTimeout /* A time in seconds set in the project for the length of time that donors have to dispute a milestone. If this 
            time is exceeded, and there are no disputes, then the creator may withdraw the according amount of funds for this milestone */;
    uint64 lastInteraction /* A reference point used for the former 2 timeouts for calculating whether appealFeeTimeout or creatorWithdrawTimeout time 
            has passed. This value will be set to block.timestamp in payDisputeFeeByDonors, requestClaimMilestone functions. */;
  }

  struct ProjectDonorDetails {
    uint256 amountFunded; // The total amount that has been funded to a project for a given address, denominated in the specified erc20 token
    uint32 latestRefundedDisputeId; // the dispute ids for which the donor has been refunded
  }

  struct ProjectFunds {
    uint256 totalFunded; // Total amount funded denominated in the given crowdfundToken
    uint256 remainingFunds; // Total amount of remaining funds in the project after milestones have been finalized. denominated in the given crowdfundToken
  }

  struct Project {
    address creator; // the address that will be paid in the case of completing a milestone
    ProjectFunds projectFunds;
    uint16 nextClaimableMilestoneCounter; // a counter used to track the next milestone which can be claimed. NOTE MAX = 2^16 - 1 = 65535
    Timer timing;
    Milestone[] milestones; // All the milestones to be completed for this crowdfunding event
    IERC20 crowdfundToken; // Token used for the crowdfunding event. The creator will be paid in this token
    uint128 paidDisputeFees; // Arbitration fee paid by all donors denominated in ETH for the current milestone. NOTE MAX = 2^128 - 1 = 3.4*10^20 ether
    uint32 latestRefundableDisputeId; // tracks the latest dispute id for which the donors can withdraw their funds
  }

  /**************************************/
  /**** Events **************************/
  /**************************************/

  /** @notice Emitted when a project is created.
   *  @param _projectId The ID of the project.
   *  @param _creator The address of the creator. (creator of the project)
   *  @param _crowdFundToken the token address used for this crowdfunding event (project)
   */
  event ProjectCreated(uint32 indexed _projectId, address indexed _creator, address indexed _crowdFundToken);

  /** @notice Emitted when a project is funded.
   *  @param _projectId The ID of the project.
   *  @param _sender the address that sent funds to _projectId
   *  @param _amountFunded The amount funded to the project
   */
  event FundProject(uint32 indexed _projectId, address indexed _sender, uint256 _amountFunded);

  /** @notice Emitted when there is an update to an accounts balance
   *  @param _account the address of the EOA/contract
   *  @param _token the address of the token the account is to be paid back in
   *  @param _balance the balance for the given token
   */
  event BalanceUpdate(address indexed _account, address indexed _token, uint256 _balance);

  /** @notice Emitted when a milestone completion is requested by creator. This milestone can be disputed for time specified by 
              creatorWithdrawTimeout. 
   *  @param _projectId The ID of the project.
   *  @param _milestoneId The ID of the milestone
   */
  event MilestoneProposed(uint32 indexed _projectId, uint16 indexed _milestoneId);

  /** @notice Emitted when a milestone is resolved. At this point a specific amount of the crowdfund token has been placed into 
              the balance of the creator. The creator can now call withdraw to withdraw the funds to their address 
   *  @param _projectId The ID of the project.
   *  @param _milestoneId The ID of the milestone
   */
  event MilestoneResolved(uint32 indexed _projectId, uint16 indexed _milestoneId);

  /** @notice Emitted when a dispute needs more funds
   *  @param _projectId The ID of the project.
   *  @param _milestoneId The ID of the milestone
   *  @param _donor address of donor
   *  @param _amountContributed amount contributed by _contributor
   *  @param _amountRequired amount required to pay for dispute
   *  @param _amountPaid amount total paid towards raising dispute
   */
  event DisputeContribution(
    uint32 indexed _projectId,
    uint16 indexed _milestoneId,
    address indexed _donor,
    uint128 _amountContributed,
    uint128 _amountRequired,
    uint128 _amountPaid
  );

  /**************************************/
  /**** Only Governor *******************/
  /**************************************/

  /** @notice change the allowed number of milestones only callable by the contract governor
   *  @param _allowedNumberOfMilestones the updated number of milestones allowed to be created
   */
  function changeAllowedNumberOfMilestones(uint16 _allowedNumberOfMilestones) external;

  /** @notice change the cost to create a project only callable by the contract governor
   *  @param _createProjectCost the updated cost in order to create a project
   */
  function changeCreateProjectCost(uint128 _createProjectCost) external;

  /**************************************/
  /**** Only Project Creator *******/
  /**************************************/

  /** @notice change the creator address for a given project only callable by project creator
   *  @param _projectId ID of the project.
   *  @param _newProjectCreator the address of the new project creator
   */
  function changeProjectCreator(uint32 _projectId, address _newProjectCreator) external;

  /**************************************/
  /**** Only Donors ********************/
  /**************************************/

  /**************************************/
  /**** Core Transactions ***************/
  /**************************************/

  /** @notice Create a project.
   *  @param _milestoneAmountUnlockablePercentage an array of the % withdrawable from each milestone denominated by 1 ether (see struct Milestone {amountUnlockable})
   *  @param _milestoneArbitratorExtraData the milestone arbitratorExtraData to be used (see Milestone.arbitratorExtraData)
   *  @param _creatorWithdrawTimeout amount of time donors have to dispute a milestone
   *  @param _crowdfundToken The erc20 token to be used in the crowdfunding event
   *  @param _metaEvidenceUri Link to the meta-evidence
   *  @return projectId The index of the project.
   */
  function createProject(
    uint64[] memory _milestoneAmountUnlockablePercentage,
    bytes[] memory _milestoneArbitratorExtraData,
    uint64 _creatorWithdrawTimeout,
    address _crowdfundToken,
    string memory _metaEvidenceUri
  ) external payable returns (uint32);

  /** @notice Give funds to a project
   *  @param _projectId the ID of the project
   *  @param _amountFunded amount to fund to projectId of the corresponding projects crowdfundToken
   */
  function donateProject(uint32 _projectId, uint256 _amountFunded) external;

  /** @notice Request to claim a milestone, can only be called by the project creator. at this point, the creator must submit
              evidence they have completed the milestone. donors can submit a dispute until creatorWithdrawTimeout passes.
   *  @param _projectId The ID of the project to claim funds from
   */
  function requestClaimMilestone(uint32 _projectId, string memory _evidenceUri) external;

  /** @notice Claim a milestone. if creatorWithdrawTimeout has passed, anyone can call this function to transfer the milestone funds
              the milestone funds into the balance of the creator.
   *  @param _projectId The ID of the project to claim funds from
   */
  function claimMilestone(uint32 _projectId) external;

  /** @notice Pay fee to dispute a milestone. To be called by parties claiming the milestone was not completed.
   *  The first party to pay the fee entirely will be reimbursed if the dispute is won.
   *  @param _projectId The project ID
   */
  function createDispute(uint32 _projectId) external payable;

  /** @notice declare a ruling only callable by the arbitrator
   *  @param _disputeId the dispute ID
   *  @param _ruling the ruling declarded by the arbitrator
   */
  function rule(uint256 _disputeId, uint256 _ruling) external override(IArbitrable);

  /** @notice withdraw funds that are owed to you. Most commonly used by creators to claim milestone funds, and to withdraw eth funds
   *  @param tokenAddress tokenAddress to withdraw funds for. NOTE set to 0 address to withdraw eth
   */
  function withdraw(address tokenAddress) external;

  /** @notice refund erc20 tokens that should be refunded from donors winning a dispute case on a milestone. NOTE the donor still has to call
   * withdraw() to withdraw the funds
   *  @param _projectId the projectId to refund for
   */
  function refund(uint32 _projectId) external;
}
