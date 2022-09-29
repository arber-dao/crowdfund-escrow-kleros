// SPDX-License-Identifier: MIT

/**
 *  @authors: [@ljrahn]
 *  @reviewers: []
 *  @auditors: []
 *  @bounties: []
 *  @deployments: []
 */

pragma solidity 0.8.13;

import "../arbitrable/FundMeCore.sol";
import "../interfaces/IArbitrator.sol";

/** @title TestFundMeCore
 *  A contract to test internal FundMeCore functions
 */

contract TestFundMeCore is FundMeCore {
  constructor(
    address _arbitrator,
    uint16 _allowedNumberOfMilestones,
    uint128 _createTransactionCost,
    uint64 _appealFeeTimeout
  ) FundMeCore(_arbitrator, _allowedNumberOfMilestones, _createTransactionCost, _appealFeeTimeout) {}

  function getMilestoneAmountClaimablePublic(uint32 _transactionId, uint16 _milestoneId)
    public
    view
    returns (uint256 amountClaimable)
  {
    return getMilestoneAmountClaimable(_transactionId, _milestoneId);
  }
}
