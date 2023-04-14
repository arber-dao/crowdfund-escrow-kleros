import { HardhatRuntimeEnvironment } from "hardhat/types"
import { DeployFunction } from "hardhat-deploy/types"
import { networkConfig } from "../../helper-hardhat-config"
import { developmentChains } from "../../helper-hardhat-config"
import { verify } from "../../test/utils/helpers"

const deployErc20Mock: DeployFunction = async (hre: HardhatRuntimeEnvironment) => {
  const { getNamedAccounts, deployments, network } = hre
  const { deploy, log } = deployments
  const { deployer } = await getNamedAccounts()

  log("----------------------------------------------------")
  let args: any[] = []
  const basicToken = await deploy("NonCompliantERC20Mock", {
    from: deployer,
    args: args,
    log: true,
    waitConfirmations: networkConfig[network.name].blockConfirmations || 1,
  })

  // Verify the deployment
  if (!developmentChains.includes(network.name) && process.env.ETHERSCAN_API_KEY) {
    log("Verifying...")
    await verify(basicToken.address, args)
  }
}

export default deployErc20Mock
deployErc20Mock.tags = ["all", "mock", "non-compliant-erc20"]
