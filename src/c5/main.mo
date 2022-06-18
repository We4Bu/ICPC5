import Principal "mo:base/Principal";
import TrieSet "mo:base/TrieSet";
import Trie "mo:base/Trie";
import Hash "mo:base/Hash";
import Nat "mo:base/Nat";
import Text "mo:base/Text";
import Array "mo:base/Array";
import Iter "mo:base/Iter";
import Option "mo:base/Option";

import IC "./ic";
import Types "./types";


actor class (threshold: Nat, members: [Principal]) = self {
    // ith bits of Nat means the state of ith operation: 
    // 1 for restricted and 0 for not restricted
    
    // stable var threshold: Nat = 2;
    // stable var members: [Principal] = [Principal.fromText("rrkah-fqaaa-aaaaa-aaaaq-cai")];

    stable var canisters: Trie.Trie<Principal, Nat> = Trie.empty<Principal, Nat>();    
    stable var memberSet : TrieSet.Set<Principal> = TrieSet.fromArray<Principal>(members, Principal.hash, Principal.equal);
    // let N = TrieSet.size<Principal>(memberSet);
    stable var proposals : Trie.Trie<Nat, Types.Proposal> = Trie.empty<Nat, Types.Proposal>();
    stable var proposalId : Nat = 0;
    
    public func getMember(): async [Principal] { members };

    public func getCanister(): async [(Principal, Nat)] { Iter.toArray(Trie.iter(canisters)) };

    public func getProposal(): async [(Nat, Types.Proposal)] { Iter.toArray(Trie.iter(proposals)) };

    public shared ({caller}) func create_canister() : async ?Principal {
        assert (checkMember(caller));
        let settings = {
            freezing_threshold = null;
            controllers = ?[Principal.fromActor(self)];
            memory_allocation = null;
            compute_allocation = null;
        };

        let ic : IC.Self =  actor("aaaaa-aa");
        let create_result  = await ic.create_canister({settings = ? settings});

        canisters := Trie.put(
            canisters, 
            {hash = Principal.hash(create_result.canister_id); key = create_result.canister_id}, 
            Principal.equal, 
            15 // 1111, default restricted
        ).0;
        return ?create_result.canister_id;
    };

    public shared ({caller}) func make_proposal (operation_direct: Types.OperationDirect, operation_type: Types.OperationType,
        canister_id : Principal, wasm_module: ?Types.Wasm_module) : async () {
        assert (checkMember(caller));
        assert (checkCanisterExist(canister_id));
        
        switch (operation_direct) {
            case (#add) assert (not checkRestricted(canister_id, operation_type));
            case (#remove) assert (checkRestricted(canister_id, operation_type));
        };
        pushProposal(caller, operation_direct, operation_type, canister_id, wasm_module);
    };

    public shared ({caller}) func make_proposal_warp (operation_direct: Text, operation_type: Text,
        canister_id : Principal, wasm_module: ?Types.Wasm_module) : async () {
        var o_direct : Types.OperationDirect = #add;
        if (operation_direct == "remove") o_direct := #remove;
        var o_type : Types.OperationType = #start;
        switch (operation_type) {
            case ("stop") o_type := #stop;
            case ("delete") o_type := #delete;
            case ("install_code") o_type := #install;
            case (_) {};
        };
        await make_proposal(o_direct, o_type, canister_id, wasm_module);
    };

    public shared ({caller}) func make_proposal_member(operation_direct: Types.OperationDirect, 
        canister_id : Principal) : async () {
        switch (operation_direct) {
            case (#add) {
                assert (not checkMember(canister_id));
                pushProposal(caller, #add, #addMember, canister_id, null);
            };
            case (#remove) {
                assert (checkMember(canister_id));
                pushProposal(caller, #remove, #removeMember, canister_id, null);
            };
        };
    };

    public shared ({caller}) func vote_proposal (proposal_id: Nat, approve: Bool, is_member: Bool) : async () {
        switch (Trie.get(proposals, {hash = Hash.hash(proposal_id); key = proposal_id}, Nat.equal)) {
            case (?proposal){
                var proposal_approvers = proposal.proposal_approvers;
                var proposal_approve_num = proposal.proposal_approve_num;
                var proposal_refusers = proposal.proposal_refusers;
                var proposal_refuse_num = proposal.proposal_refuse_num;
                if(approve){
                    proposal_approvers := Array.append([caller], proposal_approvers);
                    proposal_approve_num += 1;
                } else {
                    proposal_refusers := Array.append([caller], proposal_refusers);
                    proposal_refuse_num += 1;
                };
                let new_proposal = {
                    proposal_id = proposal.proposal_id;
                    proposal_maker = proposal.proposal_maker;
                    operation_direct = proposal.operation_direct;
                    operation_type = proposal.operation_type;
                    canister_id = proposal.canister_id;
                    wasm_module = proposal.wasm_module;
                    proposal_approve_num = proposal_approve_num;
                    proposal_approvers = proposal_approvers;
                    proposal_refuse_num = proposal_refuse_num;
                    proposal_refusers = proposal_refusers;
                    proposal_completed = false;
                };

                proposals := Trie.replace(proposals, {hash = Hash.hash(proposal_id); key =  proposal_id}, Nat.equal, ?new_proposal).0;

                if (proposal_approve_num >= threshold and (not proposal.proposal_completed)) {
                    // auto execute proposal
                    if (is_member) {
                        await execute_proposal_member(new_proposal);
                    } else {
                        await execute_proposal(new_proposal);
                    };
                };
            };
            case (_) { };
        }
    };

    // if restricted, make a proposal; else run operation.
    public func start_canister(canister_id : Principal) : async () {
        assert (checkCanisterExist(canister_id));
        if (checkRestricted(canister_id, #start)) {
            await make_proposal(#remove, #start, canister_id, null);
        } else {
            let ic: IC.Self = actor("aaaaa-aa");
            await ic.start_canister ({ canister_id = canister_id});
        }
    };

    public func stop_canister(canister_id : Principal) : async () {
        assert (checkCanisterExist(canister_id));
        if (checkRestricted(canister_id, #stop)) {
            await make_proposal(#remove, #stop, canister_id, null);
        } else {
            let ic: IC.Self = actor("aaaaa-aa");
            await ic.stop_canister ({ canister_id = canister_id });
        }
    };

    public func delete_canister(canister_id : Principal) : async () {
        assert (checkCanisterExist(canister_id));
        if (checkRestricted(canister_id, #delete)) {
            await make_proposal(#remove, #delete, canister_id, null);
        } else {
            let ic: IC.Self = actor("aaaaa-aa");
            await ic.delete_canister({ canister_id = canister_id });
        }
    };

    public func install_code(canister_id : Principal, wasm_module : ?Types.Wasm_module) : async () {
        assert (checkCanisterExist(canister_id));
        if (checkRestricted(canister_id, #install)) {
            await make_proposal(#remove, #install, canister_id, null);
        } else {
            let ic: IC.Self = actor("aaaaa-aa");
            await ic.install_code ({
                arg = [];
                wasm_module = Option.unwrap(wasm_module);
                mode = #install;
                canister_id = canister_id;
            });
        }
    };

    private func add_member(member: Principal) : async () {
        memberSet := TrieSet.put(memberSet, member, Principal.hash(member), Principal.equal);
    };

    private func remove_member(member: Principal) : async () {
        memberSet := TrieSet.delete(memberSet, member, Principal.hash(member), Principal.equal);
    };

    private func execute_proposal (proposal : Types.Proposal) : async () {
        if (proposal.operation_direct == #add) {
            add_restricted(proposal.canister_id, proposal.operation_type);
            // do not need to execute operation_type when restricted
        } else {
            remove_restricted(proposal.canister_id, proposal.operation_type);
            switch (proposal.operation_type) {
                case (#start) {
                    await start_canister(proposal.canister_id);
                };
                case (#stop) {
                    await stop_canister(proposal.canister_id);
                };
                 case (#delete) {
                    await delete_canister(proposal.canister_id);
                };
                case (#install) {
                    await install_code(proposal.canister_id, proposal.wasm_module);
                };
                case (_) {};
            };
        };
        let new_proposal = {
            proposal_id = proposal.proposal_id;
            proposal_maker = proposal.proposal_maker;
            operation_direct = proposal.operation_direct;
            operation_type = proposal.operation_type;
            canister_id = proposal.canister_id;
            wasm_module = proposal.wasm_module;
            proposal_approve_num = proposal.proposal_approve_num;
            proposal_approvers = proposal.proposal_approvers;
            proposal_refuse_num = proposal.proposal_refuse_num;
            proposal_refusers = proposal.proposal_refusers;
            proposal_completed = true;
        };
        proposals := Trie.replace(proposals, {hash = Hash.hash(proposal.proposal_id); key =  proposal.proposal_id}, Nat.equal, ?new_proposal).0;
    };

    private func execute_proposal_member (proposal : Types.Proposal) : async () {
        switch (proposal.operation_type) {
            case (#addMember) {
                await add_member(proposal.canister_id);
            };
            case (#removeMember) {
                await remove_member(proposal.canister_id);
            };
            case (_) {};
        };
        let new_proposal = {
            proposal_id = proposal.proposal_id;
            proposal_maker = proposal.proposal_maker;
            operation_direct = proposal.operation_direct;
            operation_type = proposal.operation_type;
            canister_id = proposal.canister_id;
            wasm_module = proposal.wasm_module;
            proposal_approve_num = proposal.proposal_approve_num;
            proposal_approvers = proposal.proposal_approvers;
            proposal_refuse_num = proposal.proposal_refuse_num;
            proposal_refusers = proposal.proposal_refusers;
            proposal_completed = true;
        };
        proposals := Trie.replace(proposals, {hash = Hash.hash(proposal.proposal_id); key =  proposal.proposal_id}, Nat.equal, ?new_proposal).0;
    };

    private func pushProposal (caller: Principal, operation_direct: Types.OperationDirect, operation_type: Types.OperationType, 
        canister_id: Principal, wasm_module: ?Types.Wasm_module) {
        proposalId += 1;
        proposals := Trie.put(proposals, {hash = Hash.hash(proposalId); key =  proposalId}, Nat.equal, {
            proposal_id = proposalId;
            proposal_maker = caller;
            operation_direct = operation_direct;
            operation_type = operation_type;
            canister_id = canister_id;
            wasm_module = wasm_module;
            proposal_approve_num = 0;
            proposal_approvers = [];
            proposal_refuse_num = 0;
            proposal_refusers = [];
            proposal_completed = false;
        }).0;
    };

    private func checkMember(member: Principal) : Bool {
        TrieSet.mem(memberSet, member, Principal.hash(member), Principal.equal);
    };

    private func checkCanisterExist(canister_id: Principal) : Bool {
        switch (Trie.get(canisters, {hash = Principal.hash(canister_id); key = canister_id}, Principal.equal)) {
            case null return false;
            case _ return true;
        };
    };

    private func checkRestricted (canister_id : Principal, operation_type: Types.OperationType) : Bool {
        switch(Trie.get(canisters, {hash = Principal.hash(canister_id); key = canister_id}, Principal.equal)) {
            case (?num) {
                switch (operation_type) {
                    // TODO: bit shift
                    case (#start) return ((num / 1) % 2 == 1);
                    case (#stop) return ((num / 2) % 2 == 1);
                    case (#delete) return ((num / 4) % 2 == 1);
                    case (#install) return ((num / 8) % 2 == 1);
                    case (_) return false;
                };
            };
            case null return false;
        };
    };

    private func add_restricted(canister_id : Principal, operation_type: Types.OperationType) : () {
        switch (Trie.get(canisters, {hash = Principal.hash(canister_id); key = canister_id}, Principal.equal)) {
            case (?num) {
                switch (operation_type) {
                    case (#start) canisters := Trie.replace(canisters, {hash = Principal.hash(canister_id); key = canister_id}, Principal.equal, ?(num + 1)).0;
                    case (#stop) canisters := Trie.replace(canisters, {hash = Principal.hash(canister_id); key = canister_id}, Principal.equal, ?(num + 2)).0;
                    case (#delete) canisters := Trie.replace(canisters, {hash = Principal.hash(canister_id); key = canister_id}, Principal.equal, ?(num + 4)).0;
                    case (#install) canisters := Trie.replace(canisters, {hash = Principal.hash(canister_id); key = canister_id}, Principal.equal, ?(num + 8)).0;
                    case (_) {};
                };
            };
            case null {};
        }
    };

    private func remove_restricted(canister_id : Principal, operation_type: Types.OperationType) : () {
        switch (Trie.get(canisters, {hash = Principal.hash(canister_id); key = canister_id}, Principal.equal)) {
            case (?num) {
                switch (operation_type) {
                    case (#start) canisters := Trie.replace(canisters, {hash = Principal.hash(canister_id); key = canister_id}, Principal.equal, ?(num - 1)).0;
                    case (#stop) canisters := Trie.replace(canisters, {hash = Principal.hash(canister_id); key = canister_id}, Principal.equal, ?(num - 2)).0;
                    case (#delete) canisters := Trie.replace(canisters, {hash = Principal.hash(canister_id); key = canister_id}, Principal.equal, ?(num - 4)).0;
                    case (#install) canisters := Trie.replace(canisters, {hash = Principal.hash(canister_id); key = canister_id}, Principal.equal, ?(num - 8)).0;
                    case (_) {};
                };
            };
            case null {};
        }
    };
};

