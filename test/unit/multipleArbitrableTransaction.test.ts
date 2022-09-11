import { assert, expect } from "chai"
import { network, deployments, ethers } from "hardhat"
import { developmentChains, networkConfig } from "../../helper-hardhat-config"
import { CentralizedArbitrator, MultipleArbitrableTransaction } from "../../typechain-types"
import { BigNumber, ContractReceipt, ContractTransaction } from "ethers"
import { SignerWithAddress } from "@nomiclabs/hardhat-ethers/signers"
import { ArbitrableStatus, ArbitrableParty } from "../../types/types"
import { moveTime } from "../../utils/move-network"
import { ensureBalanceAfterTransaction } from "../testHelper.test"
import { APPEAL_DURATION, ARBITRATOR_EXTRA_DATA } from "../../utils/constants"

!developmentChains.includes(network.name)
  ? describe.skip
  : describe("Multiple Arbitrable Transaction Test Suite", async function () {
      let centralizedArbitratorContract: CentralizedArbitrator,
        multipleArbitrableTransactionContract: MultipleArbitrableTransaction,
        deployer: SignerWithAddress,
        sender: SignerWithAddress,
        receiver: SignerWithAddress,
        arbitrationFee: BigNumber

      const mainTransactionId = 0
      const transactionValue = ethers.utils.parseEther("1")
      const timeoutPayment = 10 /* seconds */
      const metaEvidence = "This is the Meta Evidence!"

      let createTransactionTx: Promise<ContractTransaction>

      beforeEach(async () => {
        ;[deployer, sender, receiver] = await ethers.getSigners()
        await deployments.fixture(["arbitrator", "multiple-arbitrable-transaction"])
        centralizedArbitratorContract = await ethers.getContract("CentralizedArbitrator")
        arbitrationFee = await centralizedArbitratorContract.arbitrationCost(ARBITRATOR_EXTRA_DATA)
        multipleArbitrableTransactionContract = await ethers.getContract(
          "MultipleArbitrableTransaction"
        )

        createTransactionTx = multipleArbitrableTransactionContract
          .connect(sender)
          .createTransaction(timeoutPayment, receiver.address, metaEvidence, {
            value: transactionValue,
          })
      })

      describe("createTransaction()", async () => {
        it("creating a transaction should emit two events and all transaction parameters should hold a particular value", async () => {
          // Ensure createTransaction emits MetaEvidence event and TransactionCreated event with proper params
          await expect(createTransactionTx)
            .to.emit(multipleArbitrableTransactionContract, "MetaEvidence")
            .withArgs(mainTransactionId, "My evidence")
            .to.emit(multipleArbitrableTransactionContract, "TransactionCreated")
            .withArgs(mainTransactionId, sender.address, receiver.address, transactionValue)

          assert(
            transactionValue.toString() ==
              (await (
                await ethers.provider.getBalance(multipleArbitrableTransactionContract.address)
              ).toString())
          )

          const transaction = await multipleArbitrableTransactionContract.transactions(
            mainTransactionId
          )
          assert(transaction.sender == sender.address, "transaction sender address is not correct")
          assert(
            transaction.receiver == receiver.address,
            "transaction receiver address is not correct"
          )
          assert(
            transaction.amount.toString() == transactionValue.toString(),
            "transaction amount does not equal the amount sent"
          )
          assert(
            transaction.timeoutPayment.toNumber() == timeoutPayment,
            "transaction timeoutPayment does not equal the time sent correct"
          )
          assert(
            transaction.disputeId.toNumber() == 0,
            "transaction dispute id should initially be 0"
          )
          assert(
            transaction.senderFee.toNumber() == 0,
            "senderFee should be 0 when there is no dispute"
          )
          assert(
            transaction.receiverFee.toNumber() == 0,
            "receiverFee should be 0 when there is no dispute"
          )
          assert(
            transaction.status == ArbitrableStatus.NoDispute,
            "transaction status should be set to NoDispute"
          )
        })
      })

      describe("pay()/reimpurse()", async () => {
        it("sender can call pay() to transfer amount to receiver", async () => {
          await (await createTransactionTx).wait()
          await ensureBalanceAfterTransaction(receiver, transactionValue.toString(), async () => {
            await expect(
              multipleArbitrableTransactionContract
                .connect(sender)
                .pay(mainTransactionId, transactionValue)
            )
              .to.emit(multipleArbitrableTransactionContract, "Payment")
              .withArgs(mainTransactionId, transactionValue.toString(), sender.address)
          })
        })

        it("receiver can call resimburse() to transfer amount to sender", async () => {
          await (await createTransactionTx).wait()

          await ensureBalanceAfterTransaction(sender, transactionValue.toString(), async () => {
            await expect(
              multipleArbitrableTransactionContract
                .connect(receiver)
                .reimburse(mainTransactionId, transactionValue)
            )
              .to.emit(multipleArbitrableTransactionContract, "Payment")
              .withArgs(mainTransactionId, transactionValue.toString(), receiver.address)
          })
        })

        // TODO: Need to extend this for error cases
        // ...
      })

      describe("executeTransaction() --> transfers transaction amount to the receiver if timeout passed", async () => {
        it("can execute transaction after timeoutPayment has been exceeded", async () => {})

        it("execute transaction fails if we have not exceeded the time timeoutPayment ", async () => {})

        it("execute transaction fails if transaction is currently in a dispute", async () => {})
      })

      describe("timeOutBySender()/timeOutByReceiver() --> reimburse a party if other party fails to pay fee in time", async () => {})

      describe("payArbitrationFeeBySender()/payArbitrationFeeByReceiver() --> create a dispute", async () => {
        it("receiver can raise dispute and sender can agree to dispute, then arbitrator can call rule for sender", async () => {
          await (await createTransactionTx).wait()
          await expect(
            multipleArbitrableTransactionContract
              .connect(receiver)
              .payArbitrationFeeByReceiver(mainTransactionId, { value: arbitrationFee })
          )
            .to.emit(multipleArbitrableTransactionContract, "HasToPayFee")
            .withArgs(mainTransactionId, ArbitrableParty.Sender)

          await expect(
            multipleArbitrableTransactionContract
              .connect(sender)
              .payArbitrationFeeBySender(mainTransactionId, { value: arbitrationFee })
          )
            .to.emit(multipleArbitrableTransactionContract, "Dispute")
            .withArgs(
              centralizedArbitratorContract.address,
              0 /* disputeId */,
              mainTransactionId /* transactionId */,
              mainTransactionId /* transactionId? */
            )

          const ruleInFavorSender = 1

          // Have to call giveRuling twice, since the first the ruling puts dispute into appeal mode
          const appealableRulingTx = await centralizedArbitratorContract.giveRuling(
            0 /* disputeId */,
            ruleInFavorSender
          )
          await appealableRulingTx.wait()

          // move time till after the appeal duration
          await moveTime(APPEAL_DURATION + 1)

          await ensureBalanceAfterTransaction(
            sender,
            (
              transactionValue.toBigInt() + arbitrationFee.toBigInt()
            ).toString() /* sender should receive the transaction plus the arbitration fee back*/,
            async () => {
              await expect(
                centralizedArbitratorContract.giveRuling(0 /* disputeId */, ruleInFavorSender)
              )
                .to.emit(multipleArbitrableTransactionContract, "Ruling")
                .withArgs(
                  centralizedArbitratorContract.address,
                  0 /* disputeId */,
                  ruleInFavorSender
                )
            }
          )
        })

        // TODO: Need to extend this for error cases
        // ...
      })
    })
