import { assert, expect } from "chai"
import { network, deployments, ethers } from "hardhat"
import { developmentChains, networkConfig } from "../../helper-hardhat-config"
import {
  CentralizedArbitrator,
  ERC20Mock,
  FundMeCore,
  NonCompliantERC20Mock,
  TestFundMeCore,
} from "../../typechain-types"
import { BigNumber, ContractReceipt, ContractTransaction, Event } from "ethers"
import { SignerWithAddress } from "@nomiclabs/hardhat-ethers/signers"
import { ArbitrableStatus, ArbitrableParty } from "../../types/types"
import { moveTime } from "../../utils/move-network"
import { ensureBalanceAfterTransaction, getEvidenceGroupId } from "../testHelper.test"
import {
  ALLOWED_NUMBER_OF_MILESTONES,
  APPEAL_DURATION,
  ARBITRATION_FEE,
  ARBITRATOR_EXTRA_DATA,
  CREATE_TRANSACTION_FEE,
  RECEIVER_WITHDRAW_TIMEOUT,
  ZERO_ADDRESS,
} from "../../utils/constants"

!developmentChains.includes(network.name)
  ? describe.skip
  : describe("Fund Me Contract Internal Function Test Suite", async function () {
      let testFundMeContract: TestFundMeCore,
        erc20Contract: ERC20Mock,
        deployer: SignerWithAddress,
        receiver: SignerWithAddress,
        funder1: SignerWithAddress,
        funder2: SignerWithAddress,
        funder3: SignerWithAddress

      const mainTransactionId = 0
      const mainMilestoneId = 0
      // const timeoutPayment = 10 /* seconds */
      const metaEvidenceUri = "This is the Meta Evidence!"
      const evidenceUri = "This is my Evidence!"

      beforeEach(async () => {
        ;[deployer, receiver, funder1, funder2, funder3] = await ethers.getSigners()
        await deployments.fixture(["main", "mock"])
        testFundMeContract = await ethers.getContract("TestFundMeCore")
        erc20Contract = await ethers.getContract("ERC20Mock")
      })

      describe("getMilestoneAmountClaimable()", async () => {
        let funders: [SignerWithAddress, SignerWithAddress, SignerWithAddress]
        let transactionIds: number[] = []

        // must be BigNumber[4][] - 4 corresponds to number of transaction
        const transactionsMilestoneAmountUnlockable = [
          [ethers.utils.parseEther("0.2"), ethers.utils.parseEther("0.4"), ethers.utils.parseEther("0.4")],
          [
            ethers.utils.parseEther("0.3"),
            ethers.utils.parseEther("0.3"),
            ethers.utils.parseEther("0.15"),
            ethers.utils.parseEther("0.25"),
          ],
          [ethers.utils.parseEther("0.1"), ethers.utils.parseEther("0.1"), ethers.utils.parseEther("0.8")],
          [
            ethers.utils.parseEther("0.25"),
            ethers.utils.parseEther("0.25"),
            ethers.utils.parseEther("0.25"),
            ethers.utils.parseEther("0.25"),
          ],
        ]

        // must be BigNumber[4][3] - 4 corresponds to number of transaction - 3 corresponds to number of funders
        const transactionsAmountFunded = [
          [ethers.utils.parseEther("10"), ethers.utils.parseEther("20"), ethers.utils.parseEther("30")], //total = 60
          [ethers.utils.parseEther("30"), ethers.utils.parseEther("10"), ethers.utils.parseEther("100")], //total = 140
          [ethers.utils.parseEther("20"), ethers.utils.parseEther("20"), ethers.utils.parseEther("10")], //total = 50
          [ethers.utils.parseEther("70"), ethers.utils.parseEther("10"), ethers.utils.parseEther("90")], //total = 170
        ]

        beforeEach(async () => {
          funders = [funder1, funder2, funder3]

          for (const transaction in transactionsMilestoneAmountUnlockable) {
            const createTransactionTx = await testFundMeContract
              .connect(receiver)
              .createTransaction(
                transactionsMilestoneAmountUnlockable[transaction],
                RECEIVER_WITHDRAW_TIMEOUT,
                ARBITRATOR_EXTRA_DATA,
                erc20Contract.address,
                metaEvidenceUri,
                {
                  value: CREATE_TRANSACTION_FEE,
                }
              )

            const createTransactionReceipt = await createTransactionTx.wait()
            transactionIds.push(createTransactionReceipt.events![1].args!._transactionId)

            for (const funder in funders) {
              const increaseAllowanceTx = await erc20Contract
                .connect(funders[funder])
                .increaseAllowance(testFundMeContract.address, transactionsAmountFunded[transaction][funder])
              await increaseAllowanceTx.wait()

              const functionTransactionTx = await testFundMeContract
                .connect(funders[funder])
                .fundTransaction(transactionIds[transaction], transactionsAmountFunded[transaction][funder])
              await functionTransactionTx.wait()
            }
          }
        })

        it("test getMilestoneAmountClaimable() for various transactions with varying amounts for milestoneAmountUnlockable ", async () => {
          // const expectedMilestoneAmountClaimable = [
          //   [ethers.utils.parseEther("12"), ethers.utils.parseEther("24"), ethers.utils.parseEther("24")],
          //   [
          //     ethers.utils.parseEther("42"),
          //     ethers.utils.parseEther("42"),
          //     ethers.utils.parseEther("21"),
          //     ethers.utils.parseEther("35"),
          //   ],
          //   [ethers.utils.parseEther("5"), ethers.utils.parseEther("5"), ethers.utils.parseEther("40")],
          //   [
          //     ethers.utils.parseEther("42.5"),
          //     ethers.utils.parseEther("42.5"),
          //     ethers.utils.parseEther("42.5"),
          //     ethers.utils.parseEther("42.5"),
          //   ],
          // ]

          for (const transactionId in transactionIds) {
            for (const milestoneId in transactionsMilestoneAmountUnlockable[transactionId]) {
              // call requestClaimMilestone for milestone 0
              // check amountClaimable for milestone 0
              // move time
              // call claimMilestone for milestone 0
              // add more funds
              // check amountClaimable for milestone 1 considering the added funds
              // ...... continue
              const amountClaimable = await testFundMeContract
                .connect(receiver)
                .getMilestoneAmountClaimablePublic(transactionIds[transactionId], milestoneId)
              assert(
                amountClaimable.toBigInt() == expectedMilestoneAmountClaimable[transactionId][milestoneId].toBigInt(),
                `amount claimable for transactionId ${transactionIds[transactionId]}, milestoneId ${milestoneId} does not equal expected value. ` +
                  `Expected: ${expectedMilestoneAmountClaimable[transactionId][
                    milestoneId
                  ].toBigInt()}. Actual: ${amountClaimable.toBigInt()}`
              )
            }
          }
        })
      })
    })
