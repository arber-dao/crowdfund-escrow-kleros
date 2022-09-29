import { assert, expect } from "chai"
import { network, deployments, ethers } from "hardhat"
import { developmentChains, networkConfig } from "../../helper-hardhat-config"
import { CentralizedArbitrator, ERC20Mock, FundMeCore, NonCompliantERC20Mock } from "../../typechain-types"
import { BigNumber, ContractReceipt, ContractTransaction } from "ethers"
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
  : describe("Fund Me Contract Test Suite", async function () {
      let centralizedArbitratorContract: CentralizedArbitrator,
        fundMeContract: FundMeCore,
        erc20Contract: ERC20Mock,
        nonCompliantErc20Mock: NonCompliantERC20Mock,
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
        centralizedArbitratorContract = await ethers.getContract("CentralizedArbitrator")
        fundMeContract = await ethers.getContract("FundMeCore")
        erc20Contract = await ethers.getContract("ERC20Mock")
        nonCompliantErc20Mock = await ethers.getContract("NonCompliantERC20Mock")
      })

      describe("createTransaction()", async () => {
        const milestoneAmountUnlockable = [
          ethers.utils.parseEther("0.2"),
          ethers.utils.parseEther("0.4"),
          ethers.utils.parseEther("0.4"),
        ]

        it("creating a transaction with too little payment should revert", async () => {
          // should revert if not enough ether is sent to create the transaction
          await expect(
            fundMeContract
              .connect(receiver)
              .createTransaction(
                milestoneAmountUnlockable,
                RECEIVER_WITHDRAW_TIMEOUT,
                ARBITRATOR_EXTRA_DATA,
                erc20Contract.address,
                metaEvidenceUri,
                {
                  value: CREATE_TRANSACTION_FEE.sub(ethers.utils.parseEther("0.0001")),
                }
              )
          ).to.be.revertedWith("FundMe__PaymentTooSmall")
        })

        it("creating a transaction with too many milestones should revert", async () => {
          // populate an array with 1 too many milestones such that the array totals to 100
          // (milestoneAmountUnlockable needs to total to 100%)
          let milestoneAmountUnlockableRevertTooManyMilestonesInitilized: Array<BigNumber> = []
          let tooManyMilestones = ALLOWED_NUMBER_OF_MILESTONES + 1
          for (let i = 0; i < tooManyMilestones; i++) {
            milestoneAmountUnlockableRevertTooManyMilestonesInitilized.push(
              ethers.utils.parseEther(String(1 / tooManyMilestones))
            )
          }

          // should revert if there are too many milestones initilized
          await expect(
            fundMeContract
              .connect(receiver)
              .createTransaction(
                milestoneAmountUnlockableRevertTooManyMilestonesInitilized,
                RECEIVER_WITHDRAW_TIMEOUT,
                ARBITRATOR_EXTRA_DATA,
                erc20Contract.address,
                metaEvidenceUri,
                {
                  value: CREATE_TRANSACTION_FEE,
                }
              )
          ).to.be.revertedWith("FundMe__TooManyMilestonesInitilized")
        })

        it("creating a transaction with milestoneAmountUnlockable array does not totaling to 1 ether should revert", async () => {
          const milestoneAmountUnlockableRevertPercentageNot100 = [
            ethers.utils.parseEther("0.2"),
            ethers.utils.parseEther("0.3"),
            ethers.utils.parseEther("0.4"),
          ]

          // should revert if milestoneAmountUnlockable array does not total to 100
          await expect(
            fundMeContract
              .connect(receiver)
              .createTransaction(
                milestoneAmountUnlockableRevertPercentageNot100,
                RECEIVER_WITHDRAW_TIMEOUT,
                ARBITRATOR_EXTRA_DATA,
                erc20Contract.address,
                metaEvidenceUri,
                {
                  value: CREATE_TRANSACTION_FEE,
                }
              )
          ).to.be.revertedWith("FundMe__MilestoneAmountUnlockablePercentageNot1")
        })

        it("user should not be able to pass a non compliant erc20 token", async () => {
          await expect(
            fundMeContract
              .connect(receiver)
              .createTransaction(
                milestoneAmountUnlockable,
                RECEIVER_WITHDRAW_TIMEOUT,
                ARBITRATOR_EXTRA_DATA,
                nonCompliantErc20Mock.address,
                metaEvidenceUri,
                {
                  value: CREATE_TRANSACTION_FEE,
                }
              )
          ).to.be.revertedWith("FundMe__NonCompliantERC20")
        })

        it(
          "creating a transaction should emit two events and all transaction parameters" +
            " should hold a particular initilization value",
          async () => {
            // should successfully create transaction and emit events
            await expect(
              fundMeContract
                .connect(receiver)
                .createTransaction(
                  milestoneAmountUnlockable,
                  RECEIVER_WITHDRAW_TIMEOUT,
                  ARBITRATOR_EXTRA_DATA,
                  erc20Contract.address,
                  metaEvidenceUri,
                  {
                    value: CREATE_TRANSACTION_FEE,
                  }
                )
            )
              .to.emit(fundMeContract, "MetaEvidence")
              .withArgs(mainTransactionId, "My evidence")
              .to.emit(fundMeContract, "TransactionCreated")
              .withArgs(mainTransactionId, receiver.address, erc20Contract.address)

            const transaction = await fundMeContract.getTransaction(mainTransactionId)

            assert(transaction.receiver == receiver.address, "transaction receiver address is not correct")
            assert(transaction.totalFunded.toNumber() == 0, "transaction amount does not equal the amount sent")
            assert(
              transaction.arbitratorExtraData == ARBITRATOR_EXTRA_DATA,
              "transaction arbitrator data sent with transaction" +
                " does not equal transaction arbitrator data fetched"
            )
            assert(
              transaction.crowdfundToken == erc20Contract.address,
              "transaction erc20 token does not match the address passed in the transaction"
            )

            // check all milestones for the transaction are properly initilized
            for (let idx in transaction.milestones) {
              const {
                amountUnlockablePercentage,
                amountClaimable,
                disputeFeeReceiver,
                disputeFeeFunders,
                disputeId,
                disputePayerForFunders,
                status,
              } = await fundMeContract.getTransactionMilestone(mainTransactionId, idx)

              assert(
                amountUnlockablePercentage.toString() == milestoneAmountUnlockable[idx].toString(),
                `amountUnlockable for milestoneId ${idx} does not match expected. Expected: ${milestoneAmountUnlockable[idx]}. Actual: ${amountUnlockablePercentage}`
              )
              assert(amountClaimable.toNumber() == 0, "amountClaimable is not initilized to 0")
              assert(disputeFeeReceiver.toNumber() == 0, "disputeFeeReceiver is not initilized to 0")
              assert(disputeFeeFunders.toNumber() == 0, "disputeFeeFunders is not initilized to 0")
              assert(disputeId.toNumber() == 0, "disputeId is not initilized to 0")
              assert(
                disputePayerForFunders == ZERO_ADDRESS,
                "disputePayerForFunders is not initilized to the zero address"
              )
              assert(status == ArbitrableStatus.Created, "status is not initilized to Created")
            }
          }
        )
      })

      describe("fundTransaction()", async () => {
        let funders: SignerWithAddress[]

        const funderApproveFundMeContractAllowance = [
          ethers.utils.parseEther("10"), // funder 1 allowance
          ethers.utils.parseEther("20"), // funder 2 allowance
          ethers.utils.parseEther("30"), // funder 3 allowance
        ]

        beforeEach(async () => {
          funders = [funder1, funder2, funder3]

          const milestoneAmountUnlockable = [
            ethers.utils.parseEther("0.2"),
            ethers.utils.parseEther("0.4"),
            ethers.utils.parseEther("0.4"),
          ]
          const createTransactionTx = await fundMeContract
            .connect(receiver)
            .createTransaction(
              milestoneAmountUnlockable,
              RECEIVER_WITHDRAW_TIMEOUT,
              ARBITRATOR_EXTRA_DATA,
              erc20Contract.address,
              metaEvidenceUri,
              {
                value: CREATE_TRANSACTION_FEE,
              }
            )

          await createTransactionTx.wait()
        })

        it("funding a transaction without approving the FundMe contract should revert", async () => {
          await expect(
            fundMeContract.connect(funder1).fundTransaction(mainTransactionId, funderApproveFundMeContractAllowance[0])
          ).to.be.revertedWith("ERC20: insufficient allowance")
        })

        it("funding a transaction that doesn't exist should revert", async () => {
          const increaseAllowanceTx = await erc20Contract
            .connect(funder1)
            .increaseAllowance(fundMeContract.address, funderApproveFundMeContractAllowance[0])
          await increaseAllowanceTx.wait()

          await expect(
            fundMeContract
              .connect(funder1)
              .fundTransaction(mainTransactionId + 1, funderApproveFundMeContractAllowance[0])
          ).to.be.revertedWith("FundMe__TransactionNotFound")
        })

        it(
          "funding a transaction should increase the value of the transactions totalFunded, remainingFunds," +
            " and transactionAddressAmountFunded mapping variable",
          async () => {
            let expectedTotalFunded = ethers.utils.parseEther("0")
            let expectedRemainingFunds = ethers.utils.parseEther("0")

            for (const i in funders) {
              await expect(
                erc20Contract
                  .connect(funders[i])
                  .increaseAllowance(fundMeContract.address, funderApproveFundMeContractAllowance[i])
              )
                .to.emit(erc20Contract, "Approval")
                .withArgs(funders[i].address, fundMeContract.address, funderApproveFundMeContractAllowance[i])

              await expect(
                fundMeContract
                  .connect(funders[i])
                  .fundTransaction(mainTransactionId, funderApproveFundMeContractAllowance[i])
              )
                .to.emit(erc20Contract, "Transfer")
                .withArgs(funders[i].address, fundMeContract.address, funderApproveFundMeContractAllowance[i])
                .to.emit(fundMeContract, "FundTransaction")
                .withArgs(mainTransactionId, funders[i].address, funderApproveFundMeContractAllowance[i])

              expectedTotalFunded = expectedTotalFunded.add(funderApproveFundMeContractAllowance[i])
              expectedRemainingFunds = expectedRemainingFunds.add(funderApproveFundMeContractAllowance[i])

              const transactionAddressAmountFunded = await fundMeContract.transactionAddressAmountFunded(
                mainTransactionId,
                funders[i].address
              )
              const transaction = await fundMeContract.getTransaction(mainTransactionId)

              assert(
                transaction.totalFunded.toBigInt() == expectedTotalFunded.toBigInt(),
                `total funded value not expected. Expected: ${expectedTotalFunded}.` +
                  ` Actual: ${transaction.totalFunded}`
              )

              assert(
                transaction.remainingFunds.toBigInt() == expectedRemainingFunds.toBigInt(),
                `total funded value not expected. Expected: ${expectedRemainingFunds}.` +
                  ` Actual: ${transaction.totalFunded}`
              )

              assert(
                transactionAddressAmountFunded.toBigInt() == funderApproveFundMeContractAllowance[i].toBigInt(),
                `amount funded for transaction ID ${mainTransactionId} for address ${funders[i].address}` +
                  `not expected. Expected: ${funderApproveFundMeContractAllowance[i]}.` +
                  `Actual: ${transactionAddressAmountFunded}`
              )
            }
          }
        )
      })

      describe("requestClaimMilestone()", async () => {
        let funders: SignerWithAddress[]

        const funderApproveFundMeContractAllowance = [
          ethers.utils.parseEther("10"), // funder 1 allowance
          ethers.utils.parseEther("20"), // funder 2 allowance
          ethers.utils.parseEther("30"), // funder 3 allowance
        ]

        beforeEach(async () => {
          funders = [funder1, funder2, funder3]

          const milestoneAmountUnlockable = [
            ethers.utils.parseEther("0.2"),
            ethers.utils.parseEther("0.4"),
            ethers.utils.parseEther("0.4"),
          ]
          const createTransactionTx = await fundMeContract
            .connect(receiver)
            .createTransaction(
              milestoneAmountUnlockable,
              RECEIVER_WITHDRAW_TIMEOUT,
              ARBITRATOR_EXTRA_DATA,
              erc20Contract.address,
              metaEvidenceUri,
              {
                value: CREATE_TRANSACTION_FEE,
              }
            )

          await createTransactionTx.wait()

          for (const i in funders) {
            const increaseAllowanceTx = await erc20Contract
              .connect(funders[i])
              .increaseAllowance(fundMeContract.address, funderApproveFundMeContractAllowance[i])
            await increaseAllowanceTx.wait()

            const functionTransactionTx = await fundMeContract
              .connect(funders[i])
              .fundTransaction(mainTransactionId, funderApproveFundMeContractAllowance[i])
            await functionTransactionTx.wait()
          }
        })

        it("requesting to claim a milestone ahead of the one currently in progress should revert", async () => {
          await expect(
            fundMeContract.connect(receiver).requestClaimMilestone(mainTransactionId, mainMilestoneId + 1, evidenceUri)
          ).to.be.revertedWith("FundMe__MilestoneIdNotClaimable")
        })

        it("requesting to claim a milestone by anyone but the transaction receiver should revert", async () => {
          await expect(
            fundMeContract.connect(funders[0]).requestClaimMilestone(mainTransactionId, mainMilestoneId, evidenceUri)
          ).to.be.revertedWith("FundMe__OnlyTransactionReceiver")
        })

        it("requesting to claim a milestone with status that is not set to created should revert", async () => {})

        it(
          "requesting to claim a milestone should set milestone status to Claiming, set the milestone amountClaimable, " +
            "and emit relevent events",
          async () => {
            await expect(
              fundMeContract.connect(receiver).requestClaimMilestone(mainTransactionId, mainMilestoneId, evidenceUri)
            )
              .to.emit(fundMeContract, "MilestoneProposed")
              .withArgs(mainTransactionId, mainMilestoneId)
              .to.emit(fundMeContract, "Evidence")
              .withArgs(
                centralizedArbitratorContract.address,
                getEvidenceGroupId(mainTransactionId, mainMilestoneId),
                receiver.address,
                evidenceUri
              )
          }
        )
      })

      describe("claimMilestone()", async () => {
        beforeEach(async () => {})

        it("", async () => {})

        it("", async () => {})

        it("", async () => {})
      })
    })