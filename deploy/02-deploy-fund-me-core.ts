import { HardhatRuntimeEnvironment } from "hardhat/types"
import { DeployFunction } from "hardhat-deploy/types"
import { network, ethers } from "hardhat"
import { networkConfig } from "../helper-hardhat-config"
import { developmentChains } from "../helper-hardhat-config"
import { verify } from "../test/utils/helpers"
import { CREATE_TRANSACTION_COST, ALLOWED_NUMBER_OF_MILESTONES } from "../test/utils/constants"

const deployArbitrable: DeployFunction = async (hre: HardhatRuntimeEnvironment) => {
  const { getNamedAccounts, deployments, network } = hre
  const { deploy, log } = deployments
  const { deployer } = await getNamedAccounts()

  const arbitratorContract = await ethers.getContract("CentralizedArbitrator")

  log("----------------------------------------------------")
  const arbitratorAddress = arbitratorContract.address

  let args: any[] = [arbitratorAddress, ALLOWED_NUMBER_OF_MILESTONES, CREATE_TRANSACTION_COST]
  const fundMeContract = await deploy("FundMeCore", {
    from: deployer,
    args: args,
    log: true,
    waitConfirmations: networkConfig[network.name].blockConfirmations || 1,
  })

  // Verify the deployment
  if (!developmentChains.includes(network.name) && process.env.ETHERSCAN_API_KEY) {
    log("Verifying...")
    await verify(fundMeContract.address, args)
  }
}

export default deployArbitrable
deployArbitrable.tags = ["all", "main", "fund-me-core"]
