/* Autogenerated file. Do not edit manually. */
/* tslint:disable */
/* eslint-disable */
import type {
  BaseContract,
  BigNumber,
  BigNumberish,
  Signer,
  utils,
} from "ethers";
import type { EventFragment } from "@ethersproject/abi";
import type { Listener, Provider } from "@ethersproject/providers";
import type {
  TypedEventFilter,
  TypedEvent,
  TypedListener,
  OnEvent,
  PromiseOrValue,
} from "../../common";

export interface IMetaEvidenceInterface extends utils.Interface {
  functions: {};

  events: {
    "Dispute(address,uint256,uint256,uint256)": EventFragment;
    "Evidence(address,uint256,address,string)": EventFragment;
    "MetaEvidence(uint256,string)": EventFragment;
  };

  getEvent(nameOrSignatureOrTopic: "Dispute"): EventFragment;
  getEvent(nameOrSignatureOrTopic: "Evidence"): EventFragment;
  getEvent(nameOrSignatureOrTopic: "MetaEvidence"): EventFragment;
}

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

export interface MetaEvidenceEventObject {
  _metaEvidenceID: BigNumber;
  _evidence: string;
}
export type MetaEvidenceEvent = TypedEvent<
  [BigNumber, string],
  MetaEvidenceEventObject
>;

export type MetaEvidenceEventFilter = TypedEventFilter<MetaEvidenceEvent>;

export interface IMetaEvidence extends BaseContract {
  connect(signerOrProvider: Signer | Provider | string): this;
  attach(addressOrName: string): this;
  deployed(): Promise<this>;

  interface: IMetaEvidenceInterface;

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

  functions: {};

  callStatic: {};

  filters: {
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

    "MetaEvidence(uint256,string)"(
      _metaEvidenceID?: PromiseOrValue<BigNumberish> | null,
      _evidence?: null
    ): MetaEvidenceEventFilter;
    MetaEvidence(
      _metaEvidenceID?: PromiseOrValue<BigNumberish> | null,
      _evidence?: null
    ): MetaEvidenceEventFilter;
  };

  estimateGas: {};

  populateTransaction: {};
}