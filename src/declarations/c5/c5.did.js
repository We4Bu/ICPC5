export const idlFactory = ({ IDL }) => {
  const Wasm_module = IDL.Vec(IDL.Nat8);
  const OperationType = IDL.Variant({
    'stop' : IDL.Null,
    'delete' : IDL.Null,
    'removeMember' : IDL.Null,
    'start' : IDL.Null,
    'install' : IDL.Null,
    'addMember' : IDL.Null,
  });
  const OperationDirect = IDL.Variant({
    'add' : IDL.Null,
    'remove' : IDL.Null,
  });
  const Proposal = IDL.Record({
    'wasm_module' : IDL.Opt(Wasm_module),
    'proposal_refusers' : IDL.Vec(IDL.Principal),
    'operation_type' : OperationType,
    'proposal_approvers' : IDL.Vec(IDL.Principal),
    'canister_id' : IDL.Principal,
    'proposal_refuse_num' : IDL.Nat,
    'proposal_maker' : IDL.Principal,
    'proposal_approve_num' : IDL.Nat,
    'proposal_completed' : IDL.Bool,
    'proposal_id' : IDL.Nat,
    'operation_direct' : OperationDirect,
  });
  const anon_class_15_1 = IDL.Service({
    'create_canister' : IDL.Func([], [IDL.Opt(IDL.Principal)], []),
    'delete_canister' : IDL.Func([IDL.Principal], [], []),
    'getCanister' : IDL.Func(
        [],
        [IDL.Vec(IDL.Tuple(IDL.Principal, IDL.Nat))],
        [],
      ),
    'getMember' : IDL.Func([], [IDL.Vec(IDL.Principal)], []),
    'getProposal' : IDL.Func([], [IDL.Vec(IDL.Tuple(IDL.Nat, Proposal))], []),
    'install_code' : IDL.Func([IDL.Principal, IDL.Opt(Wasm_module)], [], []),
    'make_proposal' : IDL.Func(
        [OperationDirect, OperationType, IDL.Principal, IDL.Opt(Wasm_module)],
        [],
        [],
      ),
    'make_proposal_member' : IDL.Func([OperationDirect, IDL.Principal], [], []),
    'make_proposal_warp' : IDL.Func(
        [IDL.Text, IDL.Text, IDL.Principal, IDL.Opt(Wasm_module)],
        [],
        [],
      ),
    'start_canister' : IDL.Func([IDL.Principal], [], []),
    'stop_canister' : IDL.Func([IDL.Principal], [], []),
    'vote_proposal' : IDL.Func([IDL.Nat, IDL.Bool, IDL.Bool], [], []),
  });
  return anon_class_15_1;
};
export const init = ({ IDL }) => { return []; };
