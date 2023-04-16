pragma solidity 0.8.13;

import "forge-std/Test.sol";
import "forge-std/console.sol";

import {FundMeCoreHelper} from "./FundMeCoreHelper.t.sol";
import {FundMeCore} from "@root/arbitrable/FundMeCore.sol";
import {IFundMeErrors} from "@root/interfaces/IFundMeErrors.sol";
import {IFundMeCore} from "@root/interfaces/IFundMeCore.sol";
import {CentralizedArbitrator} from "@root/arbitrator/CentralizedArbitrator.sol";

contract FundMeCoreCreateProjectTest is Test, FundMeCoreHelper {
  uint64[] public milestoneAmountUnlockable = [0.1e18, 0.5e18, 0.4e18];
  bytes arbitratorExtraData =
    hex"0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000a"; // 10 jurors
  bytes[] public milestoneArbitratorExtraData = [arbitratorExtraData, arbitratorExtraData, arbitratorExtraData];

  event ProjectCreated(uint32 indexed _projectId, address indexed _creator, address indexed _crowdFundToken);

  function testTooLittlePayment() public {
    uint128 payment = CREATE_PROJECT_COST - 1;

    vm.expectRevert(
      abi.encodeWithSelector(IFundMeErrors.FundMe__IncorrectPayment.selector, CREATE_PROJECT_COST, payment)
    );

    fundMeCore.createProject{value: payment}(
      milestoneAmountUnlockable,
      milestoneArbitratorExtraData,
      CREATOR_WITHDRAW_TIMEOUT,
      address(erc20Mock),
      META_EVIDENCE_URI
    );
  }

  function testIncorrectPaymentFuzz(uint64 payment) public {
    if (payment != CREATE_PROJECT_COST) {
      vm.expectRevert(
        abi.encodeWithSelector(IFundMeErrors.FundMe__IncorrectPayment.selector, CREATE_PROJECT_COST, payment)
      );
    }

    fundMeCore.createProject{value: payment}(
      milestoneAmountUnlockable,
      milestoneArbitratorExtraData,
      CREATOR_WITHDRAW_TIMEOUT,
      address(erc20Mock),
      META_EVIDENCE_URI
    );
  }

  function testIncorrectNumberMilestones() public {
    uint16 tooManyMilestones = ALLOWED_NUMBER_OF_MILESTONES + 1;
    uint64[] memory tooManyMilestoneAmountUnlockable = new uint64[](tooManyMilestones);
    for (uint16 i = 0; i < tooManyMilestones; i++) {
      tooManyMilestoneAmountUnlockable[i] = 1e18 / tooManyMilestones;
    }

    vm.expectRevert(
      abi.encodeWithSelector(
        IFundMeErrors.FundMe__IncorrectNumberOfMilestoneInitilized.selector,
        1,
        ALLOWED_NUMBER_OF_MILESTONES
      )
    );

    fundMeCore.createProject{value: CREATE_PROJECT_COST}(
      tooManyMilestoneAmountUnlockable,
      milestoneArbitratorExtraData,
      CREATOR_WITHDRAW_TIMEOUT,
      address(erc20Mock),
      META_EVIDENCE_URI
    );
  }

  function testMilestoneArbitratorExtraDataLengthMismatch() public {
    milestoneArbitratorExtraData.pop();

    vm.expectRevert(IFundMeErrors.FundMe__MilestoneDataMismatch.selector);

    fundMeCore.createProject{value: CREATE_PROJECT_COST}(
      milestoneAmountUnlockable,
      milestoneArbitratorExtraData,
      CREATOR_WITHDRAW_TIMEOUT,
      address(erc20Mock),
      META_EVIDENCE_URI
    );
  }

  function testMilestoneAmountUnlockablePercentageNot100() public {
    milestoneAmountUnlockable[0] -= 1;

    vm.expectRevert(
      abi.encodeWithSelector(IFundMeErrors.FundMe__MilestoneAmountUnlockablePercentageNot1.selector, 1e18 - 1)
    );

    fundMeCore.createProject{value: CREATE_PROJECT_COST}(
      milestoneAmountUnlockable,
      milestoneArbitratorExtraData,
      CREATOR_WITHDRAW_TIMEOUT,
      address(erc20Mock),
      META_EVIDENCE_URI
    );
  }

  function testCrowdfundTokenNotERC20() public {
    vm.expectRevert(
      abi.encodeWithSelector(IFundMeErrors.FundMe__NonCompliantERC20.selector, address(nonCompliantERC20Mock))
    );

    fundMeCore.createProject{value: CREATE_PROJECT_COST}(
      milestoneAmountUnlockable,
      milestoneArbitratorExtraData,
      CREATOR_WITHDRAW_TIMEOUT,
      address(nonCompliantERC20Mock),
      META_EVIDENCE_URI
    );
  }

  function testMaxMilestonesSuccess() public {
    uint32 projectId = 1;
    uint64[] memory maxMilestoneAmountUnlockable = new uint64[](ALLOWED_NUMBER_OF_MILESTONES);
    bytes[] memory maxMilestoneArbitratorExtraData = new bytes[](ALLOWED_NUMBER_OF_MILESTONES);

    for (uint16 i = 0; i < ALLOWED_NUMBER_OF_MILESTONES; i++) {
      maxMilestoneAmountUnlockable[i] = 1e18 / ALLOWED_NUMBER_OF_MILESTONES;
      maxMilestoneArbitratorExtraData[i] = arbitratorExtraData;
    }

    vm.expectEmit(true, true, false, true, address(fundMeCore));
    emit ProjectCreated(projectId, address(this), address(erc20Mock));

    fundMeCore.createProject{value: CREATE_PROJECT_COST}(
      maxMilestoneAmountUnlockable,
      maxMilestoneArbitratorExtraData,
      CREATOR_WITHDRAW_TIMEOUT,
      address(erc20Mock),
      META_EVIDENCE_URI
    );

    assertEq(fundMeCore.getProject(projectId).creator, address(this));
    assertEq(fundMeCore.getProject(projectId).nextClaimableMilestoneCounter, 0);
    assertEq(fundMeCore.getProject(projectId).timing.creatorWithdrawTimeout, CREATOR_WITHDRAW_TIMEOUT);
    assertEq(fundMeCore.getProject(projectId).timing.lastInteraction, 0);
    assertEq(fundMeCore.getProject(projectId).projectFunds.totalFunded, 0);
    assertEq(fundMeCore.getProject(projectId).projectFunds.remainingFunds, 0);
    assertEq(address(fundMeCore.getProject(projectId).crowdfundToken), address(erc20Mock));
    assertEq(fundMeCore.getProject(projectId).paidDisputeFees, 0);
    assertEq(fundMeCore.getProject(projectId).latestRefundableDisputeId, 0);
    assertEq(fundMeCore.getProject(projectId).milestones.length, ALLOWED_NUMBER_OF_MILESTONES);
    for (uint16 i = 0; i < ALLOWED_NUMBER_OF_MILESTONES; i++) {
      assertEq(
        fundMeCore.getProjectMilestone(projectId, i).amountUnlockablePercentage,
        1e18 / ALLOWED_NUMBER_OF_MILESTONES
      );
      assertEq(fundMeCore.getProjectMilestone(projectId, i).arbitratorExtraData, arbitratorExtraData);
      assertEq(fundMeCore.getProjectMilestone(projectId, i).amountClaimable, 0);
      if (fundMeCore.getProjectMilestone(projectId, 1).status != IFundMeCore.Status.Created) {
        fail("Milestone status should be Created");
      }
    }
  }
}
