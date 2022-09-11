import { assert, expect } from "chai"
import { SignerWithAddress } from "@nomiclabs/hardhat-ethers/signers"
import { BigNumber } from "ethers"
import { ethers } from "hardhat"
import { CREATE_TRANSACTION_FEE } from "../utils/constants"

export const ensureBalanceAfterTransaction = async (
  account: SignerWithAddress,
  transactionValue: string,
  transactionCallback: () => any
) => {
  const balanceBefore = await account.getBalance()
  await transactionCallback()

  // Ensure receiver gets their payment
  const balanceAfter = await account.getBalance()

  assert(
    (balanceAfter.toBigInt() - balanceBefore.toBigInt()).toString() == transactionValue,
    "balance after transaction is not the sum of the balance before and the amount that should have been transfered"
  )
}
