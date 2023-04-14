const { dirname } = require("path")
const path = require("path")
const fsPromises = require("fs/promises")
import { network } from "hardhat"

export const getProjectRoot = dirname(__dirname, "..")

export const sleep = async (time: number) => {
  return new Promise((res) => {
    setTimeout(() => {
      res(undefined)
    }, time)
  })
}

export const moveBlocks = async (amount: number, sleepAmount: number = 0): Promise<void> => {
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

export const moveTime = async (timeToIncrease: number): Promise<void> => {
  await network.provider.request({
    method: "evm_increaseTime",
    params: [timeToIncrease],
  })
}

import { run } from "hardhat"

export const verify = async (contractAddress: string, args: any[]) => {
  console.log("Verifying contract...")
  try {
    await run("verify:verify", {
      address: contractAddress,
      constructorArguments: args,
    })
  } catch (e) {
    if ((e as Error).message.toLowerCase().includes("already verified")) {
      console.log("Already verified!")
    } else {
      console.log(e)
    }
  }
}

export const readJson = async (filePath: string) => {
  try {
    const file = path.resolve(filePath)

    // Get the content of the JSON file
    const data = await fsPromises.readFile(file)

    // Turn it to an object
    const obj = JSON.parse(data)

    return obj
  } catch (err) {
    console.error(err)
  }
}
