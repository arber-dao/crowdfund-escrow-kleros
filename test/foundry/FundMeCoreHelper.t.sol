pragma solidity 0.8.13;

import "forge-std/Test.sol";
import "forge-std/console.sol";

import {FundMeCore} from "@root/arbitrable/FundMeCore.sol";
import {CentralizedArbitrator} from "@root/arbitrator/CentralizedArbitrator.sol";
import {ERC20Mock} from "@root/mock/ERC20Mock.sol";
import {NonCompliantERC20Mock} from "@root/mock/NonCompliantERC20Mock.sol";

abstract contract FundMeCoreHelper is Test {
  address public constant TEST_ADDRESS_ONE = address(0x0001);
  address public constant TEST_ADDRESS_TWO = address(0x0002);
  address public constant TEST_ADDRESS_THREE = address(0x0003);

  uint256 public constant ARBITRATION_FEE = 0.1e18;
  uint256 public constant APPEAL_DURATION = 1 minutes;
  uint64 public constant CREATOR_WITHDRAW_TIMEOUT = 1 hours;
  uint256 public constant APPEAL_FEE = 0.1e18;
  uint16 public constant ALLOWED_NUMBER_OF_MILESTONES = 20;
  uint128 public constant CREATE_PROJECT_COST = 0.1e18;
  uint256 public constant ERC20_MOCK_TOTAL_SUPPLY = 100000e18;
  string public constant META_EVIDENCE_URI = "ipfs://metaEvidence.pdf";

  FundMeCore public fundMeCore;
  CentralizedArbitrator public centralizedArbitrator;
  ERC20Mock public erc20Mock;
  NonCompliantERC20Mock public nonCompliantERC20Mock;

  constructor() {
    centralizedArbitrator = new CentralizedArbitrator(ARBITRATION_FEE, APPEAL_DURATION, APPEAL_FEE);
    fundMeCore = new FundMeCore(address(centralizedArbitrator), ALLOWED_NUMBER_OF_MILESTONES, CREATE_PROJECT_COST);
    nonCompliantERC20Mock = new NonCompliantERC20Mock();
    erc20Mock = new ERC20Mock(ERC20_MOCK_TOTAL_SUPPLY);
  }
}
