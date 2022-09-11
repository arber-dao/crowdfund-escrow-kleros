/* Autogenerated file. Do not edit manually. */
/* tslint:disable */
/* eslint-disable */

import { Contract, Signer, utils } from "ethers";
import type { Provider } from "@ethersproject/providers";
import type {
  IArbitrable,
  IArbitrableInterface,
} from "../../../contracts/interfaces/IArbitrable";

const _abi = [
  {
    anonymous: false,
    inputs: [
      {
        indexed: true,
        internalType: "contract IArbitrator",
        name: "_arbitrator",
        type: "address",
      },
      {
        indexed: true,
        internalType: "uint256",
        name: "_disputeID",
        type: "uint256",
      },
      {
        indexed: false,
        internalType: "uint256",
        name: "_ruling",
        type: "uint256",
      },
    ],
    name: "Ruling",
    type: "event",
  },
  {
    inputs: [
      {
        internalType: "uint256",
        name: "_disputeID",
        type: "uint256",
      },
      {
        internalType: "uint256",
        name: "_ruling",
        type: "uint256",
      },
    ],
    name: "rule",
    outputs: [],
    stateMutability: "nonpayable",
    type: "function",
  },
];

export class IArbitrable__factory {
  static readonly abi = _abi;
  static createInterface(): IArbitrableInterface {
    return new utils.Interface(_abi) as IArbitrableInterface;
  }
  static connect(
    address: string,
    signerOrProvider: Signer | Provider
  ): IArbitrable {
    return new Contract(address, _abi, signerOrProvider) as IArbitrable;
  }
}
