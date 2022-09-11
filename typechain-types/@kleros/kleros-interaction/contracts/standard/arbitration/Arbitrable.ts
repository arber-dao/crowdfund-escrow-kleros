/* Autogenerated file. Do not edit manually. */
/* tslint:disable */
/* eslint-disable */
import type {
  BaseContract,
  BigNumber,
  BigNumberish,
  BytesLike,
  CallOverrides,
  ContractTransaction,
  Overrides,
  PopulatedTransaction,
  Signer,
  utils,
} from "ethers";
import type {
  FunctionFragment,
  Result,
  EventFragment,
} from "@ethersproject/abi";
import type { Listener, Provider } from "@ethersproject/providers";
import type {
  TypedEventFilter,
  TypedEvent,
  TypedListener,
  OnEvent,
  PromiseOrValue,
} from "../../../../../common";

export interface ArbitrableInterface extends utils.Interface {
  functions: {
    "arbitratorExtraData()": FunctionFragment;
    "rule(uint256,uint256)": FunctionFragment;
    "arbitrator()": FunctionFragment;
  };

  getFunction(
    nameOrSignatureOrTopic: "arbitratorExtraData" | "rule" | "arbitrator"
  ): FunctionFragment;

  encodeFunctionData(
    functionFragment: "arbitratorExtraData",
    values?: undefined
  ): string;
  encodeFunctionData(
    functionFragment: "rule",
    values: [PromiseOrValue<BigNumberish>, PromiseOrValue<BigNumberish>]
  ): string;
  encodeFunctionData(
    functionFragment: "arbitrator",
    values?: undefined
  ): string;

  decodeFunctionResult(
    functionFragment: "arbitratorExtraData",
    data: BytesLike
  ): Result;
  decodeFunctionResult(functionFragment: "rule", data: BytesLike): Result;
  decodeFunctionResult(functionFragment: "arbitrator", data: BytesLike): Result;

  events: {
    "MetaEvidence(uint256,string)": EventFragment;
    "Dispute(address,uint256,uint256,uint256)": EventFragment;
    "Evidence(address,uint256,address,string)": EventFragment;
    "Ruling(address,uint256,uint256)": EventFragment;
  };

  getEvent(nameOrSignatureOrTopic: "MetaEvidence"): EventFragment;
  getEvent(nameOrSignatureOrTopic: "Dispute"): EventFragment;
  getEvent(nameOrSignatureOrTopic: "Evidence"): EventFragment;
  getEvent(nameOrSignatureOrTopic: "Ruling"): EventFragment;
}

export interface MetaEvidenceEventObject {
  _metaEvidenceID: BigNumber;
  _evidence: string;
}
export type MetaEvidenceEvent = TypedEvent<
  [BigNumber, string],
  MetaEvidenceEventObject
>;

export type MetaEvidenceEventFilter = TypedEventFilter<MetaEvidenceEvent>;

export interface DisputeEventObject {
  _arbitrator: string;
  _disputeID: BigNumber;
  _metaEvidenceID: BigNumber;
  _evidenceGroupID: BigNumber;
}
export type DisputeEvent = TypedEvent<
  [string, BigNumber, BigNumber, BigNumber],
  DisputeEventObject
>;

export type DisputeEventFilter = TypedEventFilter<DisputeEvent>;

export interface EvidenceEventObject {
  _arbitrator: string;
  _evidenceGroupID: BigNumber;
  _party: string;
  _evidence: string;
}
export type EvidenceEvent = TypedEvent<
  [string, BigNumber, string, string],
  EvidenceEventObject
>;

export type EvidenceEventFilter = TypedEventFilter<EvidenceEvent>;

export interface RulingEventObject {
  _arbitrator: string;
  _disputeID: BigNumber;
  _ruling: BigNumber;
}
export type RulingEvent = TypedEvent<
  [string, BigNumber, BigNumber],
  RulingEventObject
>;

export type RulingEventFilter = TypedEventFilter<RulingEvent>;

export interface Arbitrable extends BaseContract {
  connect(signerOrProvider: Signer | Provider | string): this;
  attach(addressOrName: string): this;
  deployed(): Promise<this>;

  interface: ArbitrableInterface;

  queryFilter<TEvent extends TypedEvent>(
    event: TypedEventFilter<TEvent>,
    fromBlockOrBlockhash?: string | number | undefined,
    toBlock?: string | number | undefined
  ): Promise<Array<TEvent>>;

  listeners<TEvent extends TypedEvent>(
    eventFilter?: TypedEventFilter<TEvent>
  ): Array<TypedListener<TEvent>>;
  listeners(eventName?: string): Array<Listener>;
  removeAllListeners<TEvent extends TypedEvent>(
    eventFilter: TypedEventFilter<TEvent>
  ): this;
  removeAllListeners(eventName?: string): this;
  off: OnEvent<this>;
  on: OnEvent<this>;
  once: OnEvent<this>;
  removeListener: OnEvent<this>;

  functions: {
    arbitratorExtraData(overrides?: CallOverrides): Promise<[string]>;

    rule(
      _disputeID: PromiseOrValue<BigNumberish>,
      _ruling: PromiseOrValue<BigNumberish>,
      overrides?: Overrides & { from?: PromiseOrValue<string> }
    ): Promise<ContractTransaction>;

    arbitrator(overrides?: CallOverrides): Promise<[string]>;
  };

  arbitratorExtraData(overrides?: CallOverrides): Promise<string>;

  rule(
    _disputeID: PromiseOrValue<BigNumberish>,
    _ruling: PromiseOrValue<BigNumberish>,
    overrides?: Overrides & { from?: PromiseOrValue<string> }
  ): Promise<ContractTransaction>;

  arbitrator(overrides?: CallOverrides): Promise<string>;

  callStatic: {
    arbitratorExtraData(overrides?: CallOverrides): Promise<string>;

    rule(
      _disputeID: PromiseOrValue<BigNumberish>,
      _ruling: PromiseOrValue<BigNumberish>,
      overrides?: CallOverrides
    ): Promise<void>;

    arbitrator(overrides?: CallOverrides): Promise<string>;
  };

  filters: {
    "MetaEvidence(uint256,string)"(
      _metaEvidenceID?: PromiseOrValue<BigNumberish> | null,
      _evidence?: null
    ): MetaEvidenceEventFilter;
    MetaEvidence(
      _metaEvidenceID?: PromiseOrValue<BigNumberish> | null,
      _evidence?: null
    ): MetaEvidenceEventFilter;

    "Dispute(address,uint256,uint256,uint256)"(
      _arbitrator?: PromiseOrValue<string> | null,
      _disputeID?: PromiseOrValue<BigNumberish> | null,
      _metaEvidenceID?: null,
      _evidenceGroupID?: null
    ): DisputeEventFilter;
    Dispute(
      _arbitrator?: PromiseOrValue<string> | null,
      _disputeID?: PromiseOrValue<BigNumberish> | null,
      _metaEvidenceID?: null,
      _evidenceGroupID?: null
    ): DisputeEventFilter;

    "Evidence(address,uint256,address,string)"(
      _arbitrator?: PromiseOrValue<string> | null,
      _evidenceGroupID?: PromiseOrValue<BigNumberish> | null,
      _party?: PromiseOrValue<string> | null,
      _evidence?: null
    ): EvidenceEventFilter;
    Evidence(
      _arbitrator?: PromiseOrValue<string> | null,
      _evidenceGroupID?: PromiseOrValue<BigNumberish> | null,
      _party?: PromiseOrValue<string> | null,
      _evidence?: null
    ): EvidenceEventFilter;

    "Ruling(address,uint256,uint256)"(
      _arbitrator?: PromiseOrValue<string> | null,
      _disputeID?: PromiseOrValue<BigNumberish> | null,
      _ruling?: null
    ): RulingEventFilter;
    Ruling(
      _arbitrator?: PromiseOrValue<string> | null,
      _disputeID?: PromiseOrValue<BigNumberish> | null,
      _ruling?: null
    ): RulingEventFilter;
  };

  estimateGas: {
    arbitratorExtraData(overrides?: CallOverrides): Promise<BigNumber>;

    rule(
      _disputeID: PromiseOrValue<BigNumberish>,
      _ruling: PromiseOrValue<BigNumberish>,
      overrides?: Overrides & { from?: PromiseOrValue<string> }
    ): Promise<BigNumber>;

    arbitrator(overrides?: CallOverrides): Promise<BigNumber>;
  };

  populateTransaction: {
    arbitratorExtraData(
      overrides?: CallOverrides
    ): Promise<PopulatedTransaction>;

    rule(
      _disputeID: PromiseOrValue<BigNumberish>,
      _ruling: PromiseOrValue<BigNumberish>,
      overrides?: Overrides & { from?: PromiseOrValue<string> }
    ): Promise<PopulatedTransaction>;

    arbitrator(overrides?: CallOverrides): Promise<PopulatedTransaction>;
  };
}
