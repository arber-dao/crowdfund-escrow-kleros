/* Autogenerated file. Do not edit manually. */
/* tslint:disable */
/* eslint-disable */
import { Signer, utils, Contract, ContractFactory, Overrides } from "ethers";
import type { Provider, TransactionRequest } from "@ethersproject/providers";
import type { PromiseOrValue } from "../../../common";
import type {
  NonCompliantERC20Mock,
  NonCompliantERC20MockInterface,
} from "../../../contracts/mock/NonCompliantERC20Mock";

const _abi = [
  {
    inputs: [],
    stateMutability: "nonpayable",
    type: "constructor",
  },
  {
    anonymous: false,
    inputs: [
      {
        indexed: true,
        internalType: "address",
        name: "owner",
        type: "address",
      },
      {
        indexed: true,
        internalType: "address",
        name: "approved",
        type: "address",
      },
      {
        indexed: true,
        internalType: "uint256",
        name: "tokenId",
        type: "uint256",
      },
    ],
    name: "Approval",
    type: "event",
  },
  {
    anonymous: false,
    inputs: [
      {
        indexed: true,
        internalType: "address",
        name: "owner",
        type: "address",
      },
      {
        indexed: true,
        internalType: "address",
        name: "operator",
        type: "address",
      },
      {
        indexed: false,
        internalType: "bool",
        name: "approved",
        type: "bool",
      },
    ],
    name: "ApprovalForAll",
    type: "event",
  },
  {
    anonymous: false,
    inputs: [
      {
        indexed: true,
        internalType: "address",
        name: "from",
        type: "address",
      },
      {
        indexed: true,
        internalType: "address",
        name: "to",
        type: "address",
      },
      {
        indexed: true,
        internalType: "uint256",
        name: "tokenId",
        type: "uint256",
      },
    ],
    name: "Transfer",
    type: "event",
  },
  {
    inputs: [
      {
        internalType: "address",
        name: "to",
        type: "address",
      },
      {
        internalType: "uint256",
        name: "tokenId",
        type: "uint256",
      },
    ],
    name: "approve",
    outputs: [],
    stateMutability: "nonpayable",
    type: "function",
  },
  {
    inputs: [
      {
        internalType: "address",
        name: "owner",
        type: "address",
      },
    ],
    name: "balanceOf",
    outputs: [
      {
        internalType: "uint256",
        name: "",
        type: "uint256",
      },
    ],
    stateMutability: "view",
    type: "function",
  },
  {
    inputs: [
      {
        internalType: "uint256",
        name: "tokenId",
        type: "uint256",
      },
    ],
    name: "getApproved",
    outputs: [
      {
        internalType: "address",
        name: "",
        type: "address",
      },
    ],
    stateMutability: "view",
    type: "function",
  },
  {
    inputs: [],
    name: "getTokenCounter",
    outputs: [
      {
        internalType: "uint256",
        name: "",
        type: "uint256",
      },
    ],
    stateMutability: "view",
    type: "function",
  },
  {
    inputs: [
      {
        internalType: "address",
        name: "owner",
        type: "address",
      },
      {
        internalType: "address",
        name: "operator",
        type: "address",
      },
    ],
    name: "isApprovedForAll",
    outputs: [
      {
        internalType: "bool",
        name: "",
        type: "bool",
      },
    ],
    stateMutability: "view",
    type: "function",
  },
  {
    inputs: [],
    name: "name",
    outputs: [
      {
        internalType: "string",
        name: "",
        type: "string",
      },
    ],
    stateMutability: "view",
    type: "function",
  },
  {
    inputs: [
      {
        internalType: "uint256",
        name: "tokenId",
        type: "uint256",
      },
    ],
    name: "ownerOf",
    outputs: [
      {
        internalType: "address",
        name: "",
        type: "address",
      },
    ],
    stateMutability: "view",
    type: "function",
  },
  {
    inputs: [
      {
        internalType: "address",
        name: "from",
        type: "address",
      },
      {
        internalType: "address",
        name: "to",
        type: "address",
      },
      {
        internalType: "uint256",
        name: "tokenId",
        type: "uint256",
      },
    ],
    name: "safeTransferFrom",
    outputs: [],
    stateMutability: "nonpayable",
    type: "function",
  },
  {
    inputs: [
      {
        internalType: "address",
        name: "from",
        type: "address",
      },
      {
        internalType: "address",
        name: "to",
        type: "address",
      },
      {
        internalType: "uint256",
        name: "tokenId",
        type: "uint256",
      },
      {
        internalType: "bytes",
        name: "data",
        type: "bytes",
      },
    ],
    name: "safeTransferFrom",
    outputs: [],
    stateMutability: "nonpayable",
    type: "function",
  },
  {
    inputs: [
      {
        internalType: "address",
        name: "operator",
        type: "address",
      },
      {
        internalType: "bool",
        name: "approved",
        type: "bool",
      },
    ],
    name: "setApprovalForAll",
    outputs: [],
    stateMutability: "nonpayable",
    type: "function",
  },
  {
    inputs: [
      {
        internalType: "bytes4",
        name: "interfaceId",
        type: "bytes4",
      },
    ],
    name: "supportsInterface",
    outputs: [
      {
        internalType: "bool",
        name: "",
        type: "bool",
      },
    ],
    stateMutability: "view",
    type: "function",
  },
  {
    inputs: [],
    name: "symbol",
    outputs: [
      {
        internalType: "string",
        name: "",
        type: "string",
      },
    ],
    stateMutability: "view",
    type: "function",
  },
  {
    inputs: [
      {
        internalType: "uint256",
        name: "tokenId",
        type: "uint256",
      },
    ],
    name: "tokenURI",
    outputs: [
      {
        internalType: "string",
        name: "",
        type: "string",
      },
    ],
    stateMutability: "view",
    type: "function",
  },
  {
    inputs: [
      {
        internalType: "address",
        name: "from",
        type: "address",
      },
      {
        internalType: "address",
        name: "to",
        type: "address",
      },
      {
        internalType: "uint256",
        name: "tokenId",
        type: "uint256",
      },
    ],
    name: "transferFrom",
    outputs: [],
    stateMutability: "nonpayable",
    type: "function",
  },
];

const _bytecode =
  "0x60806040523480156200001157600080fd5b506040518060400160405280600781526020017f436f6f6c4e4654000000000000000000000000000000000000000000000000008152506040518060400160405280600481526020017f434e465400000000000000000000000000000000000000000000000000000000815250816000908051906020019062000096929190620005c7565b508060019080519060200190620000af929190620005c7565b5050506000600681905550620000ce33600654620000f060201b60201c565b600160066000828254620000e39190620006b0565b9250508190555062000ae0565b620001128282604051806020016040528060008152506200011660201b60201c565b5050565b6200012883836200018460201b60201c565b6200013d60008484846200037d60201b60201c565b6200017f576040517f08c379a0000000000000000000000000000000000000000000000000000000008152600401620001769062000794565b60405180910390fd5b505050565b600073ffffffffffffffffffffffffffffffffffffffff168273ffffffffffffffffffffffffffffffffffffffff1603620001f6576040517f08c379a0000000000000000000000000000000000000000000000000000000008152600401620001ed9062000806565b60405180910390fd5b62000207816200052660201b60201c565b156200024a576040517f08c379a0000000000000000000000000000000000000000000000000000000008152600401620002419062000878565b60405180910390fd5b6200025e600083836200059260201b60201c565b6001600360008473ffffffffffffffffffffffffffffffffffffffff1673ffffffffffffffffffffffffffffffffffffffff1681526020019081526020016000206000828254620002b09190620006b0565b92505081905550816002600083815260200190815260200160002060006101000a81548173ffffffffffffffffffffffffffffffffffffffff021916908373ffffffffffffffffffffffffffffffffffffffff160217905550808273ffffffffffffffffffffffffffffffffffffffff16600073ffffffffffffffffffffffffffffffffffffffff167fddf252ad1be2c89b69c2b068fc378daa952ba7f163c4a11628f55a4df523b3ef60405160405180910390a462000379600083836200059760201b60201c565b5050565b6000620003ab8473ffffffffffffffffffffffffffffffffffffffff166200059c60201b620009be1760201c565b1562000519578373ffffffffffffffffffffffffffffffffffffffff1663150b7a02620003dd620005bf60201b60201c565b8786866040518563ffffffff1660e01b815260040162000401949392919062000994565b6020604051808303816000875af19250505080156200044057506040513d601f19601f820116820180604052508101906200043d919062000a4a565b60015b620004c8573d806000811462000473576040519150601f19603f3d011682016040523d82523d6000602084013e62000478565b606091505b506000815103620004c0576040517f08c379a0000000000000000000000000000000000000000000000000000000008152600401620004b79062000794565b60405180910390fd5b805181602001fd5b63150b7a0260e01b7bffffffffffffffffffffffffffffffffffffffffffffffffffffffff1916817bffffffffffffffffffffffffffffffffffffffffffffffffffffffff1916149150506200051e565b600190505b949350505050565b60008073ffffffffffffffffffffffffffffffffffffffff166002600084815260200190815260200160002060009054906101000a900473ffffffffffffffffffffffffffffffffffffffff1673ffffffffffffffffffffffffffffffffffffffff1614159050919050565b505050565b505050565b6000808273ffffffffffffffffffffffffffffffffffffffff163b119050919050565b600033905090565b828054620005d59062000aab565b90600052602060002090601f016020900481019282620005f9576000855562000645565b82601f106200061457805160ff191683800117855562000645565b8280016001018555821562000645579182015b828111156200064457825182559160200191906001019062000627565b5b50905062000654919062000658565b5090565b5b808211156200067357600081600090555060010162000659565b5090565b6000819050919050565b7f4e487b7100000000000000000000000000000000000000000000000000000000600052601160045260246000fd5b6000620006bd8262000677565b9150620006ca8362000677565b9250827fffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff0382111562000702576200070162000681565b5b828201905092915050565b600082825260208201905092915050565b7f4552433732313a207472616e7366657220746f206e6f6e20455243373231526560008201527f63656976657220696d706c656d656e7465720000000000000000000000000000602082015250565b60006200077c6032836200070d565b915062000789826200071e565b604082019050919050565b60006020820190508181036000830152620007af816200076d565b9050919050565b7f4552433732313a206d696e7420746f20746865207a65726f2061646472657373600082015250565b6000620007ee6020836200070d565b9150620007fb82620007b6565b602082019050919050565b600060208201905081810360008301526200082181620007df565b9050919050565b7f4552433732313a20746f6b656e20616c7265616479206d696e74656400000000600082015250565b600062000860601c836200070d565b91506200086d8262000828565b602082019050919050565b60006020820190508181036000830152620008938162000851565b9050919050565b600073ffffffffffffffffffffffffffffffffffffffff82169050919050565b6000620008c7826200089a565b9050919050565b620008d981620008ba565b82525050565b620008ea8162000677565b82525050565b600081519050919050565b600082825260208201905092915050565b60005b838110156200092c5780820151818401526020810190506200090f565b838111156200093c576000848401525b50505050565b6000601f19601f8301169050919050565b60006200096082620008f0565b6200096c8185620008fb565b93506200097e8185602086016200090c565b620009898162000942565b840191505092915050565b6000608082019050620009ab6000830187620008ce565b620009ba6020830186620008ce565b620009c96040830185620008df565b8181036060830152620009dd818462000953565b905095945050505050565b600080fd5b60007fffffffff0000000000000000000000000000000000000000000000000000000082169050919050565b62000a2481620009ed565b811462000a3057600080fd5b50565b60008151905062000a448162000a19565b92915050565b60006020828403121562000a635762000a62620009e8565b5b600062000a738482850162000a33565b91505092915050565b7f4e487b7100000000000000000000000000000000000000000000000000000000600052602260045260246000fd5b6000600282049050600182168062000ac457607f821691505b60208210810362000ada5762000ad962000a7c565b5b50919050565b6121c18062000af06000396000f3fe608060405234801561001057600080fd5b50600436106100ea5760003560e01c80636e02007d1161008c578063a22cb46511610066578063a22cb4651461025d578063b88d4fde14610279578063c87b56dd14610295578063e985e9c5146102c5576100ea565b80636e02007d146101f157806370a082311461020f57806395d89b411461023f576100ea565b8063095ea7b3116100c8578063095ea7b31461016d57806323b872dd1461018957806342842e0e146101a55780636352211e146101c1576100ea565b806301ffc9a7146100ef57806306fdde031461011f578063081812fc1461013d575b600080fd5b610109600480360381019061010491906113fa565b6102f5565b6040516101169190611442565b60405180910390f35b6101276103d7565b60405161013491906114f6565b60405180910390f35b6101576004803603810190610152919061154e565b610469565b60405161016491906115bc565b60405180910390f35b61018760048036038101906101829190611603565b6104af565b005b6101a3600480360381019061019e9190611643565b6105c6565b005b6101bf60048036038101906101ba9190611643565b610626565b005b6101db60048036038101906101d6919061154e565b610646565b6040516101e891906115bc565b60405180910390f35b6101f96106f7565b60405161020691906116a5565b60405180910390f35b610229600480360381019061022491906116c0565b610701565b60405161023691906116a5565b60405180910390f35b6102476107b8565b60405161025491906114f6565b60405180910390f35b61027760048036038101906102729190611719565b61084a565b005b610293600480360381019061028e919061188e565b610860565b005b6102af60048036038101906102aa919061154e565b6108c2565b6040516102bc91906114f6565b60405180910390f35b6102df60048036038101906102da9190611911565b61092a565b6040516102ec9190611442565b60405180910390f35b60007f80ac58cd000000000000000000000000000000000000000000000000000000007bffffffffffffffffffffffffffffffffffffffffffffffffffffffff1916827bffffffffffffffffffffffffffffffffffffffffffffffffffffffff191614806103c057507f5b5e139f000000000000000000000000000000000000000000000000000000007bffffffffffffffffffffffffffffffffffffffffffffffffffffffff1916827bffffffffffffffffffffffffffffffffffffffffffffffffffffffff1916145b806103d057506103cf826109e1565b5b9050919050565b6060600080546103e690611980565b80601f016020809104026020016040519081016040528092919081815260200182805461041290611980565b801561045f5780601f106104345761010080835404028352916020019161045f565b820191906000526020600020905b81548152906001019060200180831161044257829003601f168201915b5050505050905090565b600061047482610a4b565b6004600083815260200190815260200160002060009054906101000a900473ffffffffffffffffffffffffffffffffffffffff169050919050565b60006104ba82610646565b90508073ffffffffffffffffffffffffffffffffffffffff168373ffffffffffffffffffffffffffffffffffffffff160361052a576040517f08c379a000000000000000000000000000000000000000000000000000000000815260040161052190611a23565b60405180910390fd5b8073ffffffffffffffffffffffffffffffffffffffff16610549610a96565b73ffffffffffffffffffffffffffffffffffffffff161480610578575061057781610572610a96565b61092a565b5b6105b7576040517f08c379a00000000000000000000000000000000000000000000000000000000081526004016105ae90611ab5565b60405180910390fd5b6105c18383610a9e565b505050565b6105d76105d1610a96565b82610b57565b610616576040517f08c379a000000000000000000000000000000000000000000000000000000000815260040161060d90611b47565b60405180910390fd5b610621838383610bec565b505050565b61064183838360405180602001604052806000815250610860565b505050565b6000806002600084815260200190815260200160002060009054906101000a900473ffffffffffffffffffffffffffffffffffffffff169050600073ffffffffffffffffffffffffffffffffffffffff168173ffffffffffffffffffffffffffffffffffffffff16036106ee576040517f08c379a00000000000000000000000000000000000000000000000000000000081526004016106e590611bb3565b60405180910390fd5b80915050919050565b6000600654905090565b60008073ffffffffffffffffffffffffffffffffffffffff168273ffffffffffffffffffffffffffffffffffffffff1603610771576040517f08c379a000000000000000000000000000000000000000000000000000000000815260040161076890611c45565b60405180910390fd5b600360008373ffffffffffffffffffffffffffffffffffffffff1673ffffffffffffffffffffffffffffffffffffffff168152602001908152602001600020549050919050565b6060600180546107c790611980565b80601f01602080910402602001604051908101604052809291908181526020018280546107f390611980565b80156108405780601f1061081557610100808354040283529160200191610840565b820191906000526020600020905b81548152906001019060200180831161082357829003601f168201915b5050505050905090565b61085c610855610a96565b8383610e52565b5050565b61087161086b610a96565b83610b57565b6108b0576040517f08c379a00000000000000000000000000000000000000000000000000000000081526004016108a790611b47565b60405180910390fd5b6108bc84848484610fbe565b50505050565b60606108cd82610a4b565b60006108d761101a565b905060008151116108f75760405180602001604052806000815250610922565b8061090184611031565b604051602001610912929190611ca1565b6040516020818303038152906040525b915050919050565b6000600560008473ffffffffffffffffffffffffffffffffffffffff1673ffffffffffffffffffffffffffffffffffffffff16815260200190815260200160002060008373ffffffffffffffffffffffffffffffffffffffff1673ffffffffffffffffffffffffffffffffffffffff16815260200190815260200160002060009054906101000a900460ff16905092915050565b6000808273ffffffffffffffffffffffffffffffffffffffff163b119050919050565b60007f01ffc9a7000000000000000000000000000000000000000000000000000000007bffffffffffffffffffffffffffffffffffffffffffffffffffffffff1916827bffffffffffffffffffffffffffffffffffffffffffffffffffffffff1916149050919050565b610a5481611191565b610a93576040517f08c379a0000000000000000000000000000000000000000000000000000000008152600401610a8a90611bb3565b60405180910390fd5b50565b600033905090565b816004600083815260200190815260200160002060006101000a81548173ffffffffffffffffffffffffffffffffffffffff021916908373ffffffffffffffffffffffffffffffffffffffff160217905550808273ffffffffffffffffffffffffffffffffffffffff16610b1183610646565b73ffffffffffffffffffffffffffffffffffffffff167f8c5be1e5ebec7d5bd14f71427d1e84f3dd0314c0f7b2291e5b200ac8c7c3b92560405160405180910390a45050565b600080610b6383610646565b90508073ffffffffffffffffffffffffffffffffffffffff168473ffffffffffffffffffffffffffffffffffffffff161480610ba55750610ba4818561092a565b5b80610be357508373ffffffffffffffffffffffffffffffffffffffff16610bcb84610469565b73ffffffffffffffffffffffffffffffffffffffff16145b91505092915050565b8273ffffffffffffffffffffffffffffffffffffffff16610c0c82610646565b73ffffffffffffffffffffffffffffffffffffffff1614610c62576040517f08c379a0000000000000000000000000000000000000000000000000000000008152600401610c5990611d37565b60405180910390fd5b600073ffffffffffffffffffffffffffffffffffffffff168273ffffffffffffffffffffffffffffffffffffffff1603610cd1576040517f08c379a0000000000000000000000000000000000000000000000000000000008152600401610cc890611dc9565b60405180910390fd5b610cdc8383836111fd565b610ce7600082610a9e565b6001600360008573ffffffffffffffffffffffffffffffffffffffff1673ffffffffffffffffffffffffffffffffffffffff1681526020019081526020016000206000828254610d379190611e18565b925050819055506001600360008473ffffffffffffffffffffffffffffffffffffffff1673ffffffffffffffffffffffffffffffffffffffff1681526020019081526020016000206000828254610d8e9190611e4c565b92505081905550816002600083815260200190815260200160002060006101000a81548173ffffffffffffffffffffffffffffffffffffffff021916908373ffffffffffffffffffffffffffffffffffffffff160217905550808273ffffffffffffffffffffffffffffffffffffffff168473ffffffffffffffffffffffffffffffffffffffff167fddf252ad1be2c89b69c2b068fc378daa952ba7f163c4a11628f55a4df523b3ef60405160405180910390a4610e4d838383611202565b505050565b8173ffffffffffffffffffffffffffffffffffffffff168373ffffffffffffffffffffffffffffffffffffffff1603610ec0576040517f08c379a0000000000000000000000000000000000000000000000000000000008152600401610eb790611eee565b60405180910390fd5b80600560008573ffffffffffffffffffffffffffffffffffffffff1673ffffffffffffffffffffffffffffffffffffffff16815260200190815260200160002060008473ffffffffffffffffffffffffffffffffffffffff1673ffffffffffffffffffffffffffffffffffffffff16815260200190815260200160002060006101000a81548160ff0219169083151502179055508173ffffffffffffffffffffffffffffffffffffffff168373ffffffffffffffffffffffffffffffffffffffff167f17307eab39ab6107e8899845ad3d59bd9653f200f220920489ca2b5937696c3183604051610fb19190611442565b60405180910390a3505050565b610fc9848484610bec565b610fd584848484611207565b611014576040517f08c379a000000000000000000000000000000000000000000000000000000000815260040161100b90611f80565b60405180910390fd5b50505050565b606060405180602001604052806000815250905090565b606060008203611078576040518060400160405280600181526020017f3000000000000000000000000000000000000000000000000000000000000000815250905061118c565b600082905060005b600082146110aa57808061109390611fa0565b915050600a826110a39190612017565b9150611080565b60008167ffffffffffffffff8111156110c6576110c5611763565b5b6040519080825280601f01601f1916602001820160405280156110f85781602001600182028036833780820191505090505b5090505b60008514611185576001826111119190611e18565b9150600a856111209190612048565b603061112c9190611e4c565b60f81b81838151811061114257611141612079565b5b60200101907effffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff1916908160001a905350600a8561117e9190612017565b94506110fc565b8093505050505b919050565b60008073ffffffffffffffffffffffffffffffffffffffff166002600084815260200190815260200160002060009054906101000a900473ffffffffffffffffffffffffffffffffffffffff1673ffffffffffffffffffffffffffffffffffffffff1614159050919050565b505050565b505050565b60006112288473ffffffffffffffffffffffffffffffffffffffff166109be565b15611381578373ffffffffffffffffffffffffffffffffffffffff1663150b7a02611251610a96565b8786866040518563ffffffff1660e01b815260040161127394939291906120fd565b6020604051808303816000875af19250505080156112af57506040513d601f19601f820116820180604052508101906112ac919061215e565b60015b611331573d80600081146112df576040519150601f19603f3d011682016040523d82523d6000602084013e6112e4565b606091505b506000815103611329576040517f08c379a000000000000000000000000000000000000000000000000000000000815260040161132090611f80565b60405180910390fd5b805181602001fd5b63150b7a0260e01b7bffffffffffffffffffffffffffffffffffffffffffffffffffffffff1916817bffffffffffffffffffffffffffffffffffffffffffffffffffffffff191614915050611386565b600190505b949350505050565b6000604051905090565b600080fd5b600080fd5b60007fffffffff0000000000000000000000000000000000000000000000000000000082169050919050565b6113d7816113a2565b81146113e257600080fd5b50565b6000813590506113f4816113ce565b92915050565b6000602082840312156114105761140f611398565b5b600061141e848285016113e5565b91505092915050565b60008115159050919050565b61143c81611427565b82525050565b60006020820190506114576000830184611433565b92915050565b600081519050919050565b600082825260208201905092915050565b60005b8381101561149757808201518184015260208101905061147c565b838111156114a6576000848401525b50505050565b6000601f19601f8301169050919050565b60006114c88261145d565b6114d28185611468565b93506114e2818560208601611479565b6114eb816114ac565b840191505092915050565b6000602082019050818103600083015261151081846114bd565b905092915050565b6000819050919050565b61152b81611518565b811461153657600080fd5b50565b60008135905061154881611522565b92915050565b60006020828403121561156457611563611398565b5b600061157284828501611539565b91505092915050565b600073ffffffffffffffffffffffffffffffffffffffff82169050919050565b60006115a68261157b565b9050919050565b6115b68161159b565b82525050565b60006020820190506115d160008301846115ad565b92915050565b6115e08161159b565b81146115eb57600080fd5b50565b6000813590506115fd816115d7565b92915050565b6000806040838503121561161a57611619611398565b5b6000611628858286016115ee565b925050602061163985828601611539565b9150509250929050565b60008060006060848603121561165c5761165b611398565b5b600061166a868287016115ee565b935050602061167b868287016115ee565b925050604061168c86828701611539565b9150509250925092565b61169f81611518565b82525050565b60006020820190506116ba6000830184611696565b92915050565b6000602082840312156116d6576116d5611398565b5b60006116e4848285016115ee565b91505092915050565b6116f681611427565b811461170157600080fd5b50565b600081359050611713816116ed565b92915050565b600080604083850312156117305761172f611398565b5b600061173e858286016115ee565b925050602061174f85828601611704565b9150509250929050565b600080fd5b600080fd5b7f4e487b7100000000000000000000000000000000000000000000000000000000600052604160045260246000fd5b61179b826114ac565b810181811067ffffffffffffffff821117156117ba576117b9611763565b5b80604052505050565b60006117cd61138e565b90506117d98282611792565b919050565b600067ffffffffffffffff8211156117f9576117f8611763565b5b611802826114ac565b9050602081019050919050565b82818337600083830152505050565b600061183161182c846117de565b6117c3565b90508281526020810184848401111561184d5761184c61175e565b5b61185884828561180f565b509392505050565b600082601f83011261187557611874611759565b5b813561188584826020860161181e565b91505092915050565b600080600080608085870312156118a8576118a7611398565b5b60006118b6878288016115ee565b94505060206118c7878288016115ee565b93505060406118d887828801611539565b925050606085013567ffffffffffffffff8111156118f9576118f861139d565b5b61190587828801611860565b91505092959194509250565b6000806040838503121561192857611927611398565b5b6000611936858286016115ee565b9250506020611947858286016115ee565b9150509250929050565b7f4e487b7100000000000000000000000000000000000000000000000000000000600052602260045260246000fd5b6000600282049050600182168061199857607f821691505b6020821081036119ab576119aa611951565b5b50919050565b7f4552433732313a20617070726f76616c20746f2063757272656e74206f776e6560008201527f7200000000000000000000000000000000000000000000000000000000000000602082015250565b6000611a0d602183611468565b9150611a18826119b1565b604082019050919050565b60006020820190508181036000830152611a3c81611a00565b9050919050565b7f4552433732313a20617070726f76652063616c6c6572206973206e6f7420746f60008201527f6b656e206f776e6572206e6f7220617070726f76656420666f7220616c6c0000602082015250565b6000611a9f603e83611468565b9150611aaa82611a43565b604082019050919050565b60006020820190508181036000830152611ace81611a92565b9050919050565b7f4552433732313a2063616c6c6572206973206e6f7420746f6b656e206f776e6560008201527f72206e6f7220617070726f766564000000000000000000000000000000000000602082015250565b6000611b31602e83611468565b9150611b3c82611ad5565b604082019050919050565b60006020820190508181036000830152611b6081611b24565b9050919050565b7f4552433732313a20696e76616c696420746f6b656e2049440000000000000000600082015250565b6000611b9d601883611468565b9150611ba882611b67565b602082019050919050565b60006020820190508181036000830152611bcc81611b90565b9050919050565b7f4552433732313a2061646472657373207a65726f206973206e6f74206120766160008201527f6c6964206f776e65720000000000000000000000000000000000000000000000602082015250565b6000611c2f602983611468565b9150611c3a82611bd3565b604082019050919050565b60006020820190508181036000830152611c5e81611c22565b9050919050565b600081905092915050565b6000611c7b8261145d565b611c858185611c65565b9350611c95818560208601611479565b80840191505092915050565b6000611cad8285611c70565b9150611cb98284611c70565b91508190509392505050565b7f4552433732313a207472616e736665722066726f6d20696e636f72726563742060008201527f6f776e6572000000000000000000000000000000000000000000000000000000602082015250565b6000611d21602583611468565b9150611d2c82611cc5565b604082019050919050565b60006020820190508181036000830152611d5081611d14565b9050919050565b7f4552433732313a207472616e7366657220746f20746865207a65726f2061646460008201527f7265737300000000000000000000000000000000000000000000000000000000602082015250565b6000611db3602483611468565b9150611dbe82611d57565b604082019050919050565b60006020820190508181036000830152611de281611da6565b9050919050565b7f4e487b7100000000000000000000000000000000000000000000000000000000600052601160045260246000fd5b6000611e2382611518565b9150611e2e83611518565b925082821015611e4157611e40611de9565b5b828203905092915050565b6000611e5782611518565b9150611e6283611518565b9250827fffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff03821115611e9757611e96611de9565b5b828201905092915050565b7f4552433732313a20617070726f766520746f2063616c6c657200000000000000600082015250565b6000611ed8601983611468565b9150611ee382611ea2565b602082019050919050565b60006020820190508181036000830152611f0781611ecb565b9050919050565b7f4552433732313a207472616e7366657220746f206e6f6e20455243373231526560008201527f63656976657220696d706c656d656e7465720000000000000000000000000000602082015250565b6000611f6a603283611468565b9150611f7582611f0e565b604082019050919050565b60006020820190508181036000830152611f9981611f5d565b9050919050565b6000611fab82611518565b91507fffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff8203611fdd57611fdc611de9565b5b600182019050919050565b7f4e487b7100000000000000000000000000000000000000000000000000000000600052601260045260246000fd5b600061202282611518565b915061202d83611518565b92508261203d5761203c611fe8565b5b828204905092915050565b600061205382611518565b915061205e83611518565b92508261206e5761206d611fe8565b5b828206905092915050565b7f4e487b7100000000000000000000000000000000000000000000000000000000600052603260045260246000fd5b600081519050919050565b600082825260208201905092915050565b60006120cf826120a8565b6120d981856120b3565b93506120e9818560208601611479565b6120f2816114ac565b840191505092915050565b600060808201905061211260008301876115ad565b61211f60208301866115ad565b61212c6040830185611696565b818103606083015261213e81846120c4565b905095945050505050565b600081519050612158816113ce565b92915050565b60006020828403121561217457612173611398565b5b600061218284828501612149565b9150509291505056fea26469706673582212209e537f15b7fd660201429fecd0f8828838e1bf7c1704e7665511d73187bbaa4264736f6c634300080d0033";

type NonCompliantERC20MockConstructorParams =
  | [signer?: Signer]
  | ConstructorParameters<typeof ContractFactory>;

const isSuperArgs = (
  xs: NonCompliantERC20MockConstructorParams
): xs is ConstructorParameters<typeof ContractFactory> => xs.length > 1;

export class NonCompliantERC20Mock__factory extends ContractFactory {
  constructor(...args: NonCompliantERC20MockConstructorParams) {
    if (isSuperArgs(args)) {
      super(...args);
    } else {
      super(_abi, _bytecode, args[0]);
    }
  }

  override deploy(
    overrides?: Overrides & { from?: PromiseOrValue<string> }
  ): Promise<NonCompliantERC20Mock> {
    return super.deploy(overrides || {}) as Promise<NonCompliantERC20Mock>;
  }
  override getDeployTransaction(
    overrides?: Overrides & { from?: PromiseOrValue<string> }
  ): TransactionRequest {
    return super.getDeployTransaction(overrides || {});
  }
  override attach(address: string): NonCompliantERC20Mock {
    return super.attach(address) as NonCompliantERC20Mock;
  }
  override connect(signer: Signer): NonCompliantERC20Mock__factory {
    return super.connect(signer) as NonCompliantERC20Mock__factory;
  }

  static readonly bytecode = _bytecode;
  static readonly abi = _abi;
  static createInterface(): NonCompliantERC20MockInterface {
    return new utils.Interface(_abi) as NonCompliantERC20MockInterface;
  }
  static connect(
    address: string,
    signerOrProvider: Signer | Provider
  ): NonCompliantERC20Mock {
    return new Contract(
      address,
      _abi,
      signerOrProvider
    ) as NonCompliantERC20Mock;
  }
}
