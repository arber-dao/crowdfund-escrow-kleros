pragma solidity 0.8.13;

import "forge-std/Test.sol";
import "forge-std/console.sol";

import {FundMeCoreHelper} from "./FundMeCoreHelper.t.sol";
import {FundMeCore} from "@root/arbitrable/FundMeCore.sol";
import {CentralizedArbitrator} from "@root/arbitrator/CentralizedArbitrator.sol";

contract FundMeCoreCreateProjectTest is Test, FundMeCoreHelper {
  function setUp() public {
    assertTrue(true);
  }

  function testTooLittlePayment() public {
    // should revert if not enough ether is sent to create the transaction
    // fundMeCore.createProject();
  }

  function testIncorrectNumberMilestones() public {}

  function testMilestoneArbitratorExtraDataLengthMismatch() public {}

  function testMilestoneAmountUnlockablePercentageNot100() public {}

  function testCrowdfundTokenNotERC20() public {}

  function testSuccess() public {}
}

// describe("createTransaction()", async () => {
//         it("creating a transaction with too little payment should revert", async () => {
//           // should revert if not enough ether is sent to create the transaction
//           await expect(
//             fundMeContract
//               .connect(receiver)
//               .createTransaction(
//                 milestoneAmountUnlockable,
//                 arbitratorExtraData,
//                 RECEIVER_WITHDRAW_TIMEOUT,
//                 erc20Contract.address,
//                 metaEvidenceUri,
//                 {
//                   value: CREATE_TRANSACTION_FEE.sub(ethers.utils.parseEther("0.0001")),
//                 }
//               )
//           ).to.be.revertedWith("FundMe__PaymentTooSmall")
//         })

//         it("creating a transaction with milestone data mismatch should revert", async () => {
//           const dataMismatchArbitratorExtraData = Array.from(
//             { length: milestoneAmountUnlockable.length - 1 },
//             () => ARBITRATOR_EXTRA_DATA
//           )
//           await expect(
//             fundMeContract
//               .connect(receiver)
//               .createTransaction(
//                 milestoneAmountUnlockable,
//                 dataMismatchArbitratorExtraData,
//                 RECEIVER_WITHDRAW_TIMEOUT,
//                 erc20Contract.address,
//                 metaEvidenceUri,
//                 {
//                   value: CREATE_TRANSACTION_FEE,
//                 }
//               )
//           ).to.be.revertedWith("FundMe__MilestoneDataMismatch")
//         })

//         it("creating a transaction with too many milestones should revert", async () => {
//           // populate an array with 1 too many milestones such that the array totals to 100
//           // (milestoneAmountUnlockable needs to total to 100%)
//           let milestoneAmountUnlockableRevertTooManyMilestonesInitilized: Array<BigNumber> = []
//           let tooManyMilestones = ALLOWED_NUMBER_OF_MILESTONES + 1
//           for (let i = 0; i < tooManyMilestones; i++) {
//             milestoneAmountUnlockableRevertTooManyMilestonesInitilized.push(
//               ethers.utils.parseEther(String(1 / tooManyMilestones))
//             )
//           }

//           // should revert if there are too many milestones initilized
//           await expect(
//             fundMeContract
//               .connect(receiver)
//               .createTransaction(
//                 milestoneAmountUnlockableRevertTooManyMilestonesInitilized,
//                 arbitratorExtraData,
//                 RECEIVER_WITHDRAW_TIMEOUT,
//                 erc20Contract.address,
//                 metaEvidenceUri,
//                 {
//                   value: CREATE_TRANSACTION_FEE,
//                 }
//               )
//           ).to.be.revertedWith("FundMe__TooManyMilestonesInitilized")
//         })

//         it("creating a transaction with milestoneAmountUnlockable array does not totaling to 1 ether should revert", async () => {
//           const milestoneAmountUnlockableRevertPercentageNot100 = [
//             ethers.utils.parseEther("0.2"),
//             ethers.utils.parseEther("0.3"),
//             ethers.utils.parseEther("0.4"),
//           ]

//           // should revert if milestoneAmountUnlockable array does not total to 100
//           await expect(
//             fundMeContract
//               .connect(receiver)
//               .createTransaction(
//                 milestoneAmountUnlockableRevertPercentageNot100,
//                 arbitratorExtraData,
//                 RECEIVER_WITHDRAW_TIMEOUT,
//                 erc20Contract.address,
//                 metaEvidenceUri,
//                 {
//                   value: CREATE_TRANSACTION_FEE,
//                 }
//               )
//           ).to.be.revertedWith("FundMe__MilestoneAmountUnlockablePercentageNot1")
//         })

//         it("user should not be able to pass a non compliant erc20 token", async () => {
//           await expect(
//             fundMeContract
//               .connect(receiver)
//               .createTransaction(
//                 milestoneAmountUnlockable,
//                 arbitratorExtraData,
//                 RECEIVER_WITHDRAW_TIMEOUT,
//                 nonCompliantErc20Mock.address,
//                 metaEvidenceUri,
//                 {
//                   value: CREATE_TRANSACTION_FEE,
//                 }
//               )
//           ).to.be.revertedWith("FundMe__NonCompliantERC20")
//         })

//         it(
//           "creating a transaction should emit two events and all transaction parameters" +
//             " should hold a particular initilization value",
//           async () => {
//             // should successfully create transaction and emit events
//             await expect(
//               fundMeContract
//                 .connect(receiver)
//                 .createTransaction(
//                   milestoneAmountUnlockable,
//                   arbitratorExtraData,
//                   RECEIVER_WITHDRAW_TIMEOUT,
//                   erc20Contract.address,
//                   metaEvidenceUri,
//                   {
//                     value: CREATE_TRANSACTION_FEE,
//                   }
//                 )
//             )
//               .to.emit(fundMeContract, "MetaEvidence")
//               .withArgs(mainTransactionId, "My evidence")
//               .to.emit(fundMeContract, "TransactionCreated")
//               .withArgs(mainTransactionId, receiver.address, erc20Contract.address)

//             const transaction = await fundMeContract.getTransaction(mainTransactionId)

//             assert(transaction.receiver == receiver.address, "transaction receiver address is not correct")
//             assert(transaction.totalFunded.toNumber() == 0, "transaction amount does not equal the amount sent")
//             assert(
//               transaction.crowdfundToken == erc20Contract.address,
//               "transaction erc20 token does not match the address passed in the transaction"
//             )

//             // check all milestones for the transaction are properly initilized
//             for (let idx in transaction.milestones) {
//               const {
//                 amountUnlockablePercentage,
//                 arbitratorExtraData,
//                 amountClaimable,
//                 disputeFeeReceiver,
//                 disputeFeeFunders,
//                 disputeId,
//                 disputePayerForFunders,
//                 status,
//               } = await fundMeContract.getTransactionMilestone(mainTransactionId, idx)

//               assert(
//                 amountUnlockablePercentage.toString() == milestoneAmountUnlockable[idx].toString(),
//                 `amountUnlockable for milestoneId ${idx} does not match expected. Expected: ${milestoneAmountUnlockable[idx]}. Actual: ${amountUnlockablePercentage}`
//               )
//               assert(
//                 arbitratorExtraData == ARBITRATOR_EXTRA_DATA,
//                 "transaction arbitrator data sent with transaction" +
//                   " does not equal transaction arbitrator data fetched"
//               )
//               assert(amountClaimable.toNumber() == 0, "amountClaimable is not initilized to 0")
//               assert(disputeFeeReceiver.toNumber() == 0, "disputeFeeReceiver is not initilized to 0")
//               assert(disputeFeeFunders.toNumber() == 0, "disputeFeeFunders is not initilized to 0")
//               assert(disputeId.toNumber() == 0, "disputeId is not initilized to 0")
//               assert(
//                 disputePayerForFunders == ZERO_ADDRESS,
//                 "disputePayerForFunders is not initilized to the zero address"
//               )
//               assert(status == ArbitrableStatus.Created, "status is not initilized to Created")
//             }
//           }
//         )
//       })
