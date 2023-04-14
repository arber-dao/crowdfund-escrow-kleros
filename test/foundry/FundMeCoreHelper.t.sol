pragma solidity 0.8.13;

import "forge-std/Test.sol";
import "forge-std/console.sol";

import {FundMeCore} from "@root/arbitrable/FundMeCore.sol";
import {CentralizedArbitrator} from "@root/arbitrator/CentralizedArbitrator.sol";
import {ERC20Mock} from "@root/mock/ERC20Mock.sol";
import {NonCompliantERC20Mock} from "@root/mock/NonCompliantERC20Mock.sol";

abstract contract FundMeCoreHelper is Test {
  uint256 public constant ARBITRATION_FEE = 0.1 ether;
  uint256 public constant APPEAL_DURATION = 1 minutes;
  uint256 public constant APPEAL_FEE = 0.1 ether;
  uint16 public constant ALLOWED_NUMBER_OF_MILESTONES = 20;
  uint128 public constant CREATE_PROJECT_COST = 0.1 ether;
  uint256 public constant ERC20_MOCK_TOTAL_SUPPLY = 100000 ether;

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
