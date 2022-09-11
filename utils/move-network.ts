import { network } from "hardhat"
import { sleep } from "./helpers"

export const moveBlocks = async (amount: number, sleepAmount: number = 0): Promise<void> => {
  console.log(`Moving ${amount} blocks...`)
  for (let index = 0; index < amount; index++) {
    await network.provider.request({
      method: "evm_mine",
      params: [],
    })
    if (sleepAmount) {
      console.log(`Sleeping for ${sleepAmount}`)
      await sleep(sleepAmount)
    }
  }
}

export const moveTime = async (timeToIncrease: number, sleepAmount: number = 0): Promise<void> => {
  console.log(`Moving Time by ${timeToIncrease} seconds...`)
  await network.provider.request({
    method: "evm_increaseTime",
    params: [timeToIncrease],
  })
  if (sleepAmount) {
    console.log(`Sleeping for ${sleepAmount}`)
    await sleep(sleepAmount)
  }
}
