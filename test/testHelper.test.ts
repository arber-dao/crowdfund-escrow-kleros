import { assert, expect } from "chai"
import { SignerWithAddress } from "@nomiclabs/hardhat-ethers/signers"
import { BigNumber } from "ethers"
import { ethers } from "hardhat"
import { CREATE_TRANSACTION_FEE } from "../utils/constants"

/**
 * @notice performs a transaction and ensures the balance of given account is the expected value after the transaction is complete
 * @param account the account used to check the balance of
 * @param transactionValue a string of the transaction value used to compare to account balance
 * @param transactionCallback a function that executes a transaction
 */
export const ensureBalanceAfterTransaction = async (
  account: SignerWithAddress,
  transactionValue: string,
  transactionCallback: () => any
): Promise<void> => {
  const balanceBefore = await account.getBalance()
  await transactionCallback()

  // Ensure receiver gets their payment
  const balanceAfter = await account.getBalance()

  assert(
    (balanceAfter.toBigInt() - balanceBefore.toBigInt()).toString() == transactionValue,
    "balance after transaction is not the sum of the balance before and the amount that should have been transfered"
  )
}

/**
 * @notice Does bitwise shift of transactionID and milestoneID to get evidenceGroupId for FundMeContract
 * @param transactionId ID of the transaction
 * @param milestoneId ID of the milestone
 * @returns evidenceGroupId for given transactionID and milestoneID
 */
export const getEvidenceGroupId = (transactionId: number, milestoneId: number): String => {
  return ethers.utils.hexConcat([
    ethers.utils.hexZeroPad(ethers.utils.hexlify(transactionId), 16),
    ethers.utils.hexZeroPad(ethers.utils.hexlify(milestoneId), 16),
  ])
}

/**
 * @notice Calculates the amount claimable for a given milestone
 * @param milestonesAmountUnlockable an array of the amount unlockable for each milestone
 * @param milestoneId ID of the milestone
 * @returns the amount claimable for the given milestone
 */
export const getMilestoneAmountClaimable = (
  milestonesAmountUnlockable: BigNumber[],
  milestoneId: number
): BigNumber => {}
