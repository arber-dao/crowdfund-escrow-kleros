import { assert, expect } from "chai"
import { network, deployments, ethers } from "hardhat"
import { developmentChains, networkConfig } from "../../helper-hardhat-config"
import {
  CentralizedArbitrator,
  ERC20Mock,
  FundMeCore,
  MultipleArbitrableTransaction,
  NonCompliantERC20Mock,
} from "../../typechain-types"
import { BigNumber, ContractReceipt, ContractTransaction } from "ethers"
import { SignerWithAddress } from "@nomiclabs/hardhat-ethers/signers"
import { ArbitrableStatus, ArbitrableParty } from "../../types/types"
import { moveTime } from "../../utils/move-network"
import { ensureBalanceAfterTransaction } from "../testHelper.test"
import {
  ALLOWED_NUMBER_OF_MILESTONES,
  APPEAL_DURATION,
  ARBITRATION_FEE,
  CREATE_TRANSACTION_FEE,
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
      // const timeoutPayment = 10 /* seconds */
      const metaEvidence = "This is the Meta Evidence!"

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
              .createTransaction(milestoneAmountUnlockable, erc20Contract.address, metaEvidence, {
                value: CREATE_TRANSACTION_FEE.sub(ethers.utils.parseEther("0.0001")),
              })
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
                erc20Contract.address,
                metaEvidence,
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
                erc20Contract.address,
                metaEvidence,
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
                nonCompliantErc20Mock.address,
                metaEvidence,
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
                  erc20Contract.address,
                  metaEvidence,
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

            assert(
              transaction.receiver == receiver.address,
              "transaction receiver address is not correct"
            )
            assert(
              transaction.totalFunded.toNumber() == 0,
              "transaction amount does not equal the amount sent"
            )
            assert(
              transaction.crowdfundToken == erc20Contract.address,
              "transaction erc20 token does not match the address passed in the transaction"
            )

            // check all milestones for the transaction are properly initilized
            for (let idx in transaction.milestones) {
              const {
                amountUnlockable,
                amountClaimed,
                disputeFeeReceiver,
                disputeFeeFunders,
                disputeId,
                disputePayerForFunders,
                status,
              } = await fundMeContract.getTransactionMilestone(mainTransactionId, idx)

              assert(
                amountUnlockable.toString() == milestoneAmountUnlockable[idx].toString(),
                `amountUnlockable for milestoneId ${idx} does not match expected. Expected: ${milestoneAmountUnlockable[idx]}. Actual: ${amountUnlockable}`
              )
              assert(amountClaimed.toNumber() == 0, "amountClaimed is not initilized to 0")
              assert(
                disputeFeeReceiver.toNumber() == 0,
                "disputeFeeReceiver is not initilized to 0"
              )
              assert(disputeFeeFunders.toNumber() == 0, "disputeFeeFunders is not initilized to 0")
              assert(disputeId.toNumber() == 0, "disputeId is not initilized to 0")
              assert(
                disputePayerForFunders == ZERO_ADDRESS,
                "disputePayerForFunders is not initilized to the zero address"
              )
              assert(status == ArbitrableStatus.NoDispute, "status is not initilized to NoDispute")
            }
          }
        )
      })

      describe("fundTransaction()", async () => {
        const funder1ApproveFundMeContractAllowance = ethers.utils.parseEther("10")

        beforeEach(async () => {
          const milestoneAmountUnlockable = [
            ethers.utils.parseEther("0.2"),
            ethers.utils.parseEther("0.4"),
            ethers.utils.parseEther("0.4"),
          ]
          const createTransactionTx = await fundMeContract
            .connect(receiver)
            .createTransaction(milestoneAmountUnlockable, erc20Contract.address, metaEvidence, {
              value: CREATE_TRANSACTION_FEE,
            })

          await createTransactionTx.wait()
        })

        it("funding a transaction without approving the FundMe contract should revert", async () => {
          await expect(
            fundMeContract
              .connect(funder1)
              .fundTransaction(mainTransactionId, funder1ApproveFundMeContractAllowance)
          ).to.be.revertedWith("ERC20: insufficient allowance")
        })

        it("funding a transaction that doesn't exist should revert", async () => {
          const increaseAllowanceTx = await erc20Contract
            .connect(funder1)
            .increaseAllowance(fundMeContract.address, funder1ApproveFundMeContractAllowance)
          await increaseAllowanceTx.wait()

          await expect(
            fundMeContract
              .connect(funder1)
              .fundTransaction(mainTransactionId + 1, funder1ApproveFundMeContractAllowance)
          ).to.be.revertedWith("FundMe__TransactionNotFound")
        })

        it(
          "funding a transaction should increase the value of the transactions totalFunded parameter," +
            " and transactionAddressAmountFunded mapping variable",
          async () => {
            await expect(
              erc20Contract
                .connect(funder1)
                .increaseAllowance(fundMeContract.address, funder1ApproveFundMeContractAllowance)
            )
              .to.emit(erc20Contract, "Approval")
              .withArgs(
                funder1.address,
                fundMeContract.address,
                funder1ApproveFundMeContractAllowance
              )

            await expect(
              fundMeContract
                .connect(funder1)
                .fundTransaction(mainTransactionId, funder1ApproveFundMeContractAllowance)
            )
              .to.emit(erc20Contract, "Transfer")
              .withArgs(
                funder1.address,
                fundMeContract.address,
                funder1ApproveFundMeContractAllowance
              )
              .to.emit(fundMeContract, "FundTransaction")
              .withArgs(mainTransactionId, funder1ApproveFundMeContractAllowance)

            const transaction = await fundMeContract.getTransaction(mainTransactionId)
            assert(
              transaction.totalFunded.toString() ==
                funder1ApproveFundMeContractAllowance.toString(),
              `total funded value not expected. Expected: ${funder1ApproveFundMeContractAllowance}.` +
                ` Actual: ${transaction.totalFunded}`
            )

            const transactionAddressAmountFunded =
              await fundMeContract.transactionAddressAmountFunded(
                mainTransactionId,
                funder1.address
              )
            assert(
              transactionAddressAmountFunded.toString() ==
                funder1ApproveFundMeContractAllowance.toString(),
              `amount funded for transaction ID ${mainTransactionId} for address ${funder1.address}` +
                `not expected. Expected: ${funder1ApproveFundMeContractAllowance}.` +
                `Actual: ${transactionAddressAmountFunded}`
            )
          }
        )
      })
    })
