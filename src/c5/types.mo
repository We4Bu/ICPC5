import Principal "mo:base/Principal";

module {
    public type Wasm_module = [Nat8];

    public type OperationDirect = {
        #add;
        #remove;
    };

    public type OperationType = {
        #start;
        #stop;
        #delete;
        #install;
        #addMember;
        #removeMember;
    };

    public type Proposal = {
        proposal_id : Nat;
        proposal_maker : Principal;
        operation_direct : OperationDirect;
        operation_type : OperationType;
        canister_id : Principal;
        wasm_module : ?Wasm_module;
        proposal_approve_num : Nat;
        proposal_approvers : [Principal];
        proposal_refuse_num : Nat;
        proposal_refusers: [Principal];
        proposal_completed: Bool;
    };
};