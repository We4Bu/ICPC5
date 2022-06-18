import type { Principal } from '@dfinity/principal';
import type { ActorMethod } from '@dfinity/agent';

export type OperationDirect = { 'add' : null } |
  { 'remove' : null };
export type OperationType = { 'stop' : null } |
  { 'delete' : null } |
  { 'removeMember' : null } |
  { 'start' : null } |
  { 'install' : null } |
  { 'addMember' : null };
export interface Proposal {
  'wasm_module' : [] | [Wasm_module],
  'proposal_refusers' : Array<Principal>,
  'operation_type' : OperationType,
  'proposal_approvers' : Array<Principal>,
  'canister_id' : Principal,
  'proposal_refuse_num' : bigint,
  'proposal_maker' : Principal,
  'proposal_approve_num' : bigint,
  'proposal_completed' : boolean,
  'proposal_id' : bigint,
  'operation_direct' : OperationDirect,
}
export type Wasm_module = Array<number>;
export interface anon_class_15_1 {
  'create_canister' : ActorMethod<[], [] | [Principal]>,
  'delete_canister' : ActorMethod<[Principal], undefined>,
  'getCanister' : ActorMethod<[], Array<[Principal, bigint]>>,
  'getMember' : ActorMethod<[], Array<Principal>>,
  'getProposal' : ActorMethod<[], Array<[bigint, Proposal]>>,
  'install_code' : ActorMethod<[Principal, [] | [Wasm_module]], undefined>,
  'make_proposal' : ActorMethod<
    [OperationDirect, OperationType, Principal, [] | [Wasm_module]],
    undefined,
  >,
  'make_proposal_member' : ActorMethod<[OperationDirect, Principal], undefined>,
  'make_proposal_warp' : ActorMethod<
    [string, string, Principal, [] | [Wasm_module]],
    undefined,
  >,
  'start_canister' : ActorMethod<[Principal], undefined>,
  'stop_canister' : ActorMethod<[Principal], undefined>,
  'vote_proposal' : ActorMethod<[bigint, boolean, boolean], undefined>,
}
export interface _SERVICE extends anon_class_15_1 {}
