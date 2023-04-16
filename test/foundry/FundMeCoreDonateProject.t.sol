pragma solidity 0.8.13;

import "forge-std/Test.sol";
import "forge-std/console.sol";

import {FundMeCoreHelper} from "./FundMeCoreHelper.t.sol";
import {FundMeCore} from "@root/arbitrable/FundMeCore.sol";
import {CentralizedArbitrator} from "@root/arbitrator/CentralizedArbitrator.sol";
import {IFundMeErrors} from "@root/interfaces/IFundMeErrors.sol";
import {IFundMeCore} from "@root/interfaces/IFundMeCore.sol";

contract FundMeCoreDonateProjectTest is Test, FundMeCoreHelper {
  uint64[] public milestoneAmountUnlockable = [0.1e18, 0.5e18, 0.4e18];
  bytes arbitratorExtraData =
    hex"0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000a"; // 10 jurors
  bytes[] public milestoneArbitratorExtraData = [arbitratorExtraData, arbitratorExtraData, arbitratorExtraData];

  event ProjectDonated(uint32 indexed _projectId, address indexed _sender, uint256 _amountFunded);
  event Transfer(address indexed from, address indexed to, uint256 amount);

  function setUp() public {
    fundMeCore.createProject{value: CREATE_PROJECT_COST}(
      milestoneAmountUnlockable,
      milestoneArbitratorExtraData,
      CREATOR_WITHDRAW_TIMEOUT,
      address(erc20Mock),
      META_EVIDENCE_URI
    );
  }

  function testDonateProjectDoesNotExist() public {
    uint32 projectId = 2;
    uint256 amount = 10e18;

    erc20Mock.increaseAllowance(address(fundMeCore), amount);

    vm.expectRevert(abi.encodeWithSelector(IFundMeErrors.FundMe__ProjectNotFound.selector, projectId));

    fundMeCore.donateProject(projectId, amount);
  }

  function testDonateProjectFuzz(
    uint64 addressOnePayment,
    uint64 addressTwoPayment,
    uint64 addressThreePayment
  ) public {
    uint32 projectId = 1;
    uint64[3] memory payments = [addressOnePayment, addressTwoPayment, addressThreePayment];
    address[3] memory donors = [TEST_ADDRESS_ONE, TEST_ADDRESS_TWO, TEST_ADDRESS_THREE];

    // donate to project with 3 different addresses
    for (uint256 i = 0; i < donors.length; i++) {
      erc20Mock.transfer(donors[i], payments[i]);

      vm.startPrank(donors[i]);

      erc20Mock.increaseAllowance(address(fundMeCore), payments[i]);

      vm.expectEmit(true, true, false, true, address(erc20Mock));
      emit Transfer(donors[i], address(fundMeCore), payments[i]);
      vm.expectEmit(true, true, false, true, address(fundMeCore));
      emit ProjectDonated(projectId, donors[i], payments[i]);

      fundMeCore.donateProject(projectId, payments[i]);

      vm.stopPrank();
    }

    // check that the total amount donated is correct
    uint256 expectedBalance = uint256(addressOnePayment) + uint256(addressTwoPayment) + uint256(addressThreePayment);

    assertEq(erc20Mock.balanceOf(address(fundMeCore)), expectedBalance);
    assertEq(fundMeCore.getProject(projectId).projectFunds.totalFunded, expectedBalance);
    assertEq(fundMeCore.getProject(projectId).projectFunds.remainingFunds, expectedBalance);
  }
}
