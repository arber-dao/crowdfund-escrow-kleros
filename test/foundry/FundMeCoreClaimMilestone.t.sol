pragma solidity 0.8.13;

import "forge-std/Test.sol";
import "forge-std/console.sol";

import {FundMeCoreHelper} from "./FundMeCoreHelper.t.sol";
import {FundMeCore} from "@root/arbitrable/FundMeCore.sol";
import {CentralizedArbitrator} from "@root/arbitrator/CentralizedArbitrator.sol";
import {IFundMeErrors} from "@root/interfaces/IFundMeErrors.sol";
import {IFundMeCore} from "@root/interfaces/IFundMeCore.sol";
import {IArbitrator} from "@root/interfaces/IArbitrator.sol";

contract FundMeCoreClaimMilestoneTestParams {
  uint64[] public milestoneAmountUnlockable1 = [0.4e18, 0.1e18, 0.2e18, 0.2e18, 0.1e18];
  uint256[] public donations1 = [uint256(30e18), uint256(20e18), uint256(10e18), uint256(0), uint256(60e18)];
  uint256[] public expectedClaimableAmount1 = [
    uint256(12e18),
    uint256(6.33e18),
    uint256(16.67e18),
    uint256(16.67e18),
    uint256(68.33e18)
  ];
  uint256[] public expectedRemainingFunds1 = [
    uint256(18e18),
    uint256(31.67e18),
    uint256(25e18),
    uint256(8.33e18),
    uint256(0)
  ];
  uint256[] public expectedEvidenceGroupId1 = [
    uint256(340282366920938463463374607431768211456), // hex"0000000000000000000000000000000100000000000000000000000000000000"
    uint256(340282366920938463463374607431768211457), // hex"0000000000000000000000000000000100000000000000000000000000000001"
    uint256(340282366920938463463374607431768211458), // hex"0000000000000000000000000000000100000000000000000000000000000002"
    uint256(340282366920938463463374607431768211459), // hex"0000000000000000000000000000000100000000000000000000000000000003"
    uint256(340282366920938463463374607431768211460) // hex"0000000000000000000000000000000100000000000000000000000000000004"
  ];

  /* ---------------------------------------------------------------------------------------------- */

  uint64[] public milestoneAmountUnlockable2 = [0.1e18, 0.5e18, 0.4e18];
  uint256[] public donations2 = [uint256(10e18), uint256(30e18), uint256(10e18)];
  uint256[] public expectedClaimableAmount2 = [uint256(1e18), uint256(21.67e18), uint256(27.33e18)];
  uint256[] public expectedRemainingFunds2 = [uint256(9e18), uint256(17.33e18), uint256(0)];
  uint256[] public expectedEvidenceGroupId2 = [
    uint256(340282366920938463463374607431768211456), // hex"0000000000000000000000000000000100000000000000000000000000000000"
    uint256(340282366920938463463374607431768211457), // hex"0000000000000000000000000000000100000000000000000000000000000001"
    uint256(340282366920938463463374607431768211458) // hex"0000000000000000000000000000000100000000000000000000000000000002"
  ];
}

contract FundMeCoreClaimMilestoneTest is Test, FundMeCoreHelper, FundMeCoreClaimMilestoneTestParams {
  uint64[] public milestoneAmountUnlockable = [0.1e18, 0.5e18, 0.4e18];
  bytes arbitratorExtraData =
    hex"0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000a"; // 10 jurors
  bytes[] public milestoneArbitratorExtraData = [arbitratorExtraData, arbitratorExtraData, arbitratorExtraData];

  event MilestoneProposed(uint32 indexed _projectId, uint16 indexed _milestoneId);
  event MilestoneResolved(uint32 indexed _projectId, uint16 indexed _milestoneId);
  event BalanceUpdate(address indexed _account, address indexed _token, uint256 _balance);
  event Evidence(
    IArbitrator indexed _arbitrator,
    uint256 indexed _evidenceGroupId,
    address indexed _party,
    string _evidence
  );

  function setUp() public {}

  function testRequestClaimMilestoneStatusNotCreated() public {
    uint32 projectId = 1;
    uint32 milestoneId = 0;

    fundMeCore.createProject{value: CREATE_PROJECT_COST}(
      milestoneAmountUnlockable,
      milestoneArbitratorExtraData,
      CREATOR_WITHDRAW_TIMEOUT,
      address(erc20Mock),
      META_EVIDENCE_URI
    );

    fundMeCore.requestClaimMilestone(projectId, EVIDENCE_URI);

    vm.expectRevert(
      abi.encodeWithSelector(IFundMeErrors.FundMe__MilestoneStatusNotCreated.selector, projectId, milestoneId)
    );
    fundMeCore.requestClaimMilestone(projectId, EVIDENCE_URI);
  }

  function testClaimMilestoneStatusNotClaiming() public {
    uint32 projectId = 1;
    uint32 milestoneId = 0;

    fundMeCore.createProject{value: CREATE_PROJECT_COST}(
      milestoneAmountUnlockable,
      milestoneArbitratorExtraData,
      CREATOR_WITHDRAW_TIMEOUT,
      address(erc20Mock),
      META_EVIDENCE_URI
    );

    vm.expectRevert(
      abi.encodeWithSelector(IFundMeErrors.FundMe__MilestoneStatusNotClaiming.selector, projectId, milestoneId)
    );
    fundMeCore.claimMilestone(projectId);
  }

  function testClaimMilestoneCreatorWithdrawTimeoutNotPassed() public {
    uint32 projectId = 1;
    uint32 milestoneId = 0;

    fundMeCore.createProject{value: CREATE_PROJECT_COST}(
      milestoneAmountUnlockable,
      milestoneArbitratorExtraData,
      CREATOR_WITHDRAW_TIMEOUT,
      address(erc20Mock),
      META_EVIDENCE_URI
    );

    fundMeCore.requestClaimMilestone(projectId, EVIDENCE_URI);
    skip(CREATOR_WITHDRAW_TIMEOUT - 1);

    vm.expectRevert(
      abi.encodeWithSelector(
        IFundMeErrors.FundMe__RequiredTimeoutNotPassed.selector,
        CREATOR_WITHDRAW_TIMEOUT,
        CREATOR_WITHDRAW_TIMEOUT - 1
      )
    );
    fundMeCore.claimMilestone(projectId);
  }

  function testClaimMilestone1() public {
    claimMilestone(
      milestoneAmountUnlockable1,
      donations1,
      expectedClaimableAmount1,
      expectedRemainingFunds1,
      expectedEvidenceGroupId1
    );
  }

  function testClaimMilestone2() public {
    claimMilestone(
      milestoneAmountUnlockable2,
      donations2,
      expectedClaimableAmount2,
      expectedRemainingFunds2,
      expectedEvidenceGroupId2
    );
  }

  function claimMilestone(
    uint64[] memory milestoneAmountUnlockable,
    uint256[] memory donations,
    uint256[] memory expectedClaimableAmount,
    uint256[] memory expectedRemainingFunds,
    uint256[] memory expectedEvidenceGroupId
  ) private {
    uint32 projectId = 1;
    bytes[] memory milestoneArbitratorExtraData = new bytes[](milestoneAmountUnlockable.length);

    for (uint256 i = 0; i < milestoneAmountUnlockable.length; i++) {
      milestoneArbitratorExtraData[i] = arbitratorExtraData;
    }

    fundMeCore.createProject{value: CREATE_PROJECT_COST}(
      milestoneAmountUnlockable,
      milestoneArbitratorExtraData,
      CREATOR_WITHDRAW_TIMEOUT,
      address(erc20Mock),
      META_EVIDENCE_URI
    );

    uint256 expectedCreatorBalance = 0;

    // loop over claiming all milestones, and checking the correct amountClaimable when donating inbetween claims. Also make
    // sure other state is correct such as project remainingFunds, creator balance, and milestone status
    for (uint16 i = 0; i < donations.length; i++) {
      erc20Mock.transfer(TEST_ADDRESS_ONE, donations[i]);

      // donate
      vm.startPrank(TEST_ADDRESS_ONE);
      erc20Mock.increaseAllowance(address(fundMeCore), donations[i]);
      fundMeCore.donateProject(projectId, donations[i]);
      vm.stopPrank();

      // requestClaimMilestone
      vm.expectEmit(true, true, true, true, address(fundMeCore));
      emit Evidence(IArbitrator(centralizedArbitrator), expectedEvidenceGroupId[i], address(this), EVIDENCE_URI);
      vm.expectEmit(true, true, false, false, address(fundMeCore));
      emit MilestoneProposed(projectId, i);
      fundMeCore.requestClaimMilestone(projectId, EVIDENCE_URI);

      assertApproxEqRel(
        fundMeCore.getProjectMilestone(projectId, i).amountClaimable,
        expectedClaimableAmount[i],
        0.001e18
      );
      if (fundMeCore.getProjectMilestone(projectId, i).status != IFundMeCore.MilestoneStatus.Claiming) {
        fail("Milestone status should be Claiming");
      }
      expectedCreatorBalance += expectedClaimableAmount[i];

      // fast forward to allow claimMilestone
      skip(CREATOR_WITHDRAW_TIMEOUT);

      // claimMilestone
      vm.expectEmit(true, true, false, false, address(fundMeCore));
      emit BalanceUpdate(address(this), address(erc20Mock), 0);
      vm.expectEmit(true, true, false, false, address(fundMeCore));
      emit MilestoneResolved(projectId, i);
      fundMeCore.claimMilestone(projectId);

      assertApproxEqRel(
        fundMeCore.getAccountBalance(address(this), address(erc20Mock)),
        expectedCreatorBalance,
        0.001e18
      );
      assertApproxEqRel(
        fundMeCore.getProject(projectId).projectFunds.remainingFunds,
        expectedRemainingFunds[i],
        0.001e18
      );
      if (fundMeCore.getProjectMilestone(projectId, i).status != IFundMeCore.MilestoneStatus.Resolved) {
        fail("Milestone status should be Resolved");
      }
    }
  }
}
