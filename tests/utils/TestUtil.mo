import Time "mo:base/Time";
import Array "mo:base/Array";
import Debug "mo:base/Debug";
import Iter "mo:base/Iter";
import Bool "mo:base/Bool";
import Blob "mo:base/Blob";
import Int "mo:base/Int";
import Nat "mo:base/Nat";
import Nat8 "mo:base/Nat8";
import Nat64 "mo:base/Nat64";
import Principal "mo:base/Principal";
import Cycles "mo:base/ExperimentalCycles";

import Converter "../../src/";
import T "../../src/Types";

import ActorSpec "ActorSpec";

module {

    let test_ids : [Text] = [
        "cpi23-5qaaa-aaaag-qcs5a-cai",
        "rkf6t-7iaaa-aaaag-qco6a-cai",
        "auzum-qe7jl-z2f6l-rwp3r-wkr4f-3rcz3-l7ejm-ltcku-c45fw-w7pi4-hqe",        
        "ehi5s-vxa47-cjckw-4dnt2-3kxk4-shngz-thwy2-5umya-2rij2-rllds-wqe",
        "ltnvn-spenv-hileg-coyda-gclul-yqibf-pr3q6-vndkr-p5tdi-6ypip-cqe",
        "l2wou-xtapz-wfatn-ptq6w-v6yek-qshs5-qsy5a-tuixw-xbhq6-cimdp-xae",
        "akbcy-jszkp-z6zfd-4md7k-xmdgr-p5stn-enzhm-47hpo-sxhps-aoyxt-bae",
        "3scjg-z33zr-ll3bt-hdsov-kkitm-3tsml-tvgkt-d6jwa-onz35-hkfq5-zae",
        "3xwpq-ziaaa-aaaah-qcn4a-cai",
        "jw7or-laaaa-aaaag-qctca-cai",
        "objst-kqaaa-aaaag-qcumq-cai",
        "suaf3-hqaaa-aaaaf-bfyoa-cai",
        "aboy3-giaaa-aaaar-aaaaq-cai",
        "ciual-vyaaa-aaaan-qcywa-cai",
        "k6dka-zyaaa-aaaaj-aafla-cai,", 
        "2222s-4iaaa-aaaaf-ax2uq-cai", 
        "2226x-viaaa-aaaaj-aab3q-cai", 
        "2227b-baaaa-aaaao-abd6a-cai", 
        "222ew-7aaaa-aaaar-akaia-cai", 
        "222jd-4aaaa-aaaan-qc2oq-cai", 
        "222l7-eqaaa-aaaar-aghea-cai", 
        "222qi-2qaaa-aaaao-anesa-cai", 
        "222r6-oyaaa-aaaaj-amgxq-cai", 
        "222v3-hyaaa-aaaaf-a35yq-cai", 
        "222yf-myaaa-aaaad-qfjiq-cai"

    ];

    public func get_context() : T.ConverterContext {

        let caller = Principal.fromText("2vxsx-fae"); // anon
        get_caller_context(caller);

    };

    public func get_caller_context(caller : Principal) : T.ConverterContext {

        get_caller_account_context(caller, get_test_account(0))

    };

    public func get_caller_account_context(caller : Principal, account : T.Account) : T.ConverterContext {

        let converter : T.Account = { 
            owner = Principal.fromText("czysu-eaaaa-aaaag-qcvdq-cai");
            subaccount = null;
        };

        let state = Converter.init();

        return {
            caller = caller;
            state = state;
            account = account;
            converter = converter;
        };
    };

    public func get_caller_active_context(caller : Principal) : T.ConverterContext {

        let context = get_caller_context(caller);
        Converter.set_canister_ids(
            context, 
            "czysu-eaaaa-aaaag-qcvdq-cai", 
            "czysu-eaaaa-aaaag-qcvdq-cai", 
            "czysu-eaaaa-aaaag-qcvdq-cai", 
            "czysu-eaaaa-aaaag-qcvdq-cai");

        return context;
    };

    private func set_mocks(context : T.ConverterContext) {

        Converter.set_canister_ids(
            context, 
            "cgpjn-omaaa-aaaaa-qaakq-cai", 
            "cbopz-duaaa-aaaaa-qaaka-cai", 
            "cuj6u-c4aaa-aaaaa-qaajq-cai", 
            "ctiya-peaaa-aaaaa-qaaja-cai");

    };

    public func get_context_with_mocks(caller : Principal) : T.ConverterContext {

        let context = get_caller_context(caller);
        set_mocks(context);
        return context;
    };

    public func get_account_context_with_mocks(caller : Principal, account : T.Account) : T.ConverterContext {

        let context = get_caller_account_context(caller, account);
        set_mocks(context);
        return context;
    };

    public func get_test_account(index : Nat) : T.Account {
        {
            owner = Principal.fromText(test_ids[index]);
            subaccount = null;
        }
    };

    public func get_converter_subaccount() : T.Account {
        {
            owner = Principal.fromText("czysu-eaaaa-aaaag-qcvdq-cai");
            subaccount = ?Blob.fromArray([1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15, 16, 17, 18, 19, 20, 21, 22, 23, 24, 25, 26, 27, 28, 29, 30, 31, 32]);
        };
    };

    public func get_converter_zeroes_subaccount() : T.Account {
        {
            owner = Principal.fromText("czysu-eaaaa-aaaag-qcvdq-cai");
            subaccount = ?Blob.fromArray([0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0]);
        };
    };

    public func get_test_subaccount() : T.Account {
        {
            owner = Principal.fromText("cpi23-5qaaa-aaaag-qcs5a-cai");
            subaccount = ?Blob.fromArray([1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15, 16, 17, 18, 19, 20, 21, 22, 23, 24, 25, 26, 27, 28, 29, 30, 31, 32]);
        };
    };

    public func get_test_zeroes_subaccount() : T.Account {
        {
            owner = Principal.fromText("cpi23-5qaaa-aaaag-qcs5a-cai");
            subaccount = ?Blob.fromArray([0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0]);
        };
    };

    public func get_old_acct_to_dapp_tx(context : T.ConverterContext, index : T.TxIndex, amount : T.Balance) 
        : T.OldTransaction { get_old_tx(index, amount, context.account, context.converter); };

    public func get_old_dapp_to_acct_tx(context : T.ConverterContext, index : T.TxIndex, amount : T.Balance) 
        : T.OldTransaction { 
        get_old_tx(index, amount, context.converter, context.account); 
    };

    public func get_old_tx(index : T.TxIndex, amount : T.Balance, from : T.Account, to : T.Account) : T.OldTransaction {
        let timestamp : T.Timestamp = Nat64.fromNat(Int.abs(Time.now()));

        return {
            kind = "TRANSFER";
            mint = null;
            burn = null;
            transfer = ?{
                from = from;
                to = to;
                amount = amount;
                fee = null;
                memo = null;
                created_at_time = ?timestamp;
            };
            index = index;
            timestamp = timestamp;
        };
    };

    public func get_new_acct_to_dapp_tx(context : T.ConverterContext, index : T.TxIndex, amount : T.Balance) 
        : T.NewTransactionWithId { get_new_tx(index, amount, context.account, context.converter); };

    public func get_new_dapp_to_acct_tx(context : T.ConverterContext, index : T.TxIndex, amount : T.Balance) 
        : T.NewTransactionWithId {     
        get_new_tx(index, amount, context.converter, context.account); 
    };

    public func get_new_tx(index : T.TxIndex, amount : T.Balance, from : T.Account, to : T.Account) : T.NewTransactionWithId {
        let timestamp : T.Timestamp = Nat64.fromNat(Int.abs(Time.now()));

        return {
            id = index;
            transaction = {
                kind = "TRANSFER";
                mint = null;
                burn = null;
                transfer = ?{
                    from = from;
                    to = to;
                    amount = amount;
                    spender = null;
                    fee = null;
                    memo = null;
                    created_at_time = ?timestamp;
                };
                approve = null;
                timestamp = timestamp;
            }
        };
    };

    public func log_last_seen_old(context : T.ConverterContext, index : T.TxIndex) : () {
        context.state.ephemeral.old_latest_sent_txids.put(context.account.owner, index);
    };

    public func log_last_seen_new(context : T.ConverterContext, index : T.TxIndex) : () {
        context.state.ephemeral.new_latest_sent_txids.put(context.account.owner, index);
    };


    public func verify_indexed_account_invariants(context : T.ConverterContext, indexed_account : T.IndexedAccount) : Bool {
        let settings = context.state.persistent.settings;

        if (indexed_account.old_sent_dapp_to_acct_d12 > indexed_account.old_sent_acct_to_dapp_d12) {
            if (indexed_account.old_balance_d12 != 0) { return false; };
            if (indexed_account.old_balance_underflow_d12 != indexed_account.old_sent_dapp_to_acct_d12 - indexed_account.old_sent_acct_to_dapp_d12) { return false; };
        } else {
            if (indexed_account.old_balance_d12 != indexed_account.old_sent_acct_to_dapp_d12 - indexed_account.old_sent_dapp_to_acct_d12) { return false; };
            if (indexed_account.old_balance_underflow_d12 != 0) { return false; };
        };

        if (indexed_account.new_total_balance_d8 * settings.d12_to_d8 != indexed_account.old_balance_d12 
                                                        + (indexed_account.new_sent_acct_to_dapp_d8 * settings.d12_to_d8)
                                                        - (indexed_account.new_sent_dapp_to_acct_d8 * settings.d12_to_d8)) { return false; };

        true;
    };


    public func print_indexed_account(indexed : T.IndexedAccount) : () {
        Debug.print("new_total_balance_d8: " # Nat.toText(indexed.new_total_balance_d8));
        Debug.print("old_balance_d12: " # Nat.toText(indexed.old_balance_d12));
        Debug.print("new_total_balance_underflow_d8: " # Nat.toText(indexed.new_total_balance_underflow_d8));
        Debug.print("old_balance_underflow_d12: " # Nat.toText(indexed.old_balance_underflow_d12));
        Debug.print("new_sent_acct_to_dapp_d8: " # Nat.toText(indexed.new_sent_acct_to_dapp_d8));
        Debug.print("new_sent_dapp_to_acct_d8: " # Nat.toText(indexed.new_sent_dapp_to_acct_d8));
        Debug.print("old_sent_acct_to_dapp_d12: " # Nat.toText(indexed.old_sent_acct_to_dapp_d12));
        Debug.print("old_sent_dapp_to_acct_d12: " # Nat.toText(indexed.old_sent_dapp_to_acct_d12));
        Debug.print("is_seeder: " # Bool.toText(indexed.is_seeder));
        Debug.print("old_latest_send_found: " # Bool.toText(indexed.old_latest_send_found));
        switch (indexed.old_latest_send_txid) {
            case (null) { Debug.print("old_latest_send_txid: null"); };
            case (?old_latest_send_txid) { Debug.print("old_latest_send_txid: " # Nat.toText(old_latest_send_txid)); };
        };
        Debug.print("new_latest_send_found: " # Bool.toText(indexed.new_latest_send_found));
        switch (indexed.new_latest_send_txid) {
            case (null) { Debug.print("new_latest_send_txid: null"); };
            case (?new_latest_send_txid) { Debug.print("new_latest_send_txid: " # Nat.toText(new_latest_send_txid)); };
        };
    };

    public func print_old_indexed_account(indexed : T.IndexOldBalanceResult) : () {
        Debug.print("old_balance_d12: " # Nat.toText(indexed.old_balance_d12));
        Debug.print("old_balance_underflow_d12: " # Nat.toText(indexed.old_balance_underflow_d12));
        Debug.print("old_sent_acct_to_dapp_d12: " # Nat.toText(indexed.old_sent_acct_to_dapp_d12));
        Debug.print("old_sent_dapp_to_acct_d12: " # Nat.toText(indexed.old_sent_dapp_to_acct_d12));
        Debug.print("old_latest_send_found: " # Bool.toText(indexed.old_latest_send_found));
        switch (indexed.old_latest_send_txid) {
            case (null) { Debug.print("old_latest_send_txid: null"); };
            case (?old_latest_send_txid) { Debug.print("old_latest_send_txid: " # Nat.toText(old_latest_send_txid)); };
        }
    };

    public func print_new_indexed_account(indexed : T.IndexNewBalanceResult) : () {
        Debug.print("new_sent_acct_to_dapp_d8: " # Nat.toText(indexed.new_sent_acct_to_dapp_d8));
        Debug.print("new_sent_dapp_to_acct_d8: " # Nat.toText(indexed.new_sent_dapp_to_acct_d8));
        Debug.print("is_seeder: " # Bool.toText(indexed.is_seeder));
        Debug.print("new_latest_send_found: " # Bool.toText(indexed.new_latest_send_found));
        switch (indexed.new_latest_send_txid) {
            case (null) { Debug.print("new_latest_send_txid: null"); };
            case (?new_latest_send_txid) { Debug.print("new_latest_send_txid: " # Nat.toText(new_latest_send_txid)); };
        }
    };

};