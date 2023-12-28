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


    public func verify_indexed_account_invariants(context : T.ConverterContext, indexed_account : T.IndexedAccount) : Bool {
        let settings = context.state.persistent.settings;

        if (indexed_account.old_sent_dapp_to_acct_d12 > indexed_account.old_sent_acct_to_dapp_d12) {
            if (indexed_account.old_balance_d12 != 0) { return false; };
            if (indexed_account.old_balance_underflow_d12 != indexed_account.old_sent_dapp_to_acct_d12 - indexed_account.old_sent_acct_to_dapp_d12) { return false; };
        } else {
            if (indexed_account.old_balance_d12 != indexed_account.old_sent_acct_to_dapp_d12 - indexed_account.old_sent_dapp_to_acct_d12) { return false; };
            if (indexed_account.old_balance_underflow_d12 != 0) { return false; };
        };

        if (indexed_account.new_sent_dapp_to_acct_d8 * settings.d8_to_d12 > indexed_account.old_balance_d12 
                                                                            + (indexed_account.new_sent_acct_to_dapp_d8 * settings.d8_to_d12)) {
            if (indexed_account.new_total_balance_underflow_d8 * settings.d8_to_d12 != indexed_account.new_sent_dapp_to_acct_d8 * settings.d8_to_d12
                                                            - (indexed_account.new_sent_acct_to_dapp_d8 * settings.d8_to_d12)
                                                            - (indexed_account.old_balance_d12)) { return false; };
            if (indexed_account.new_total_balance_d8 != 0) { return false; };
        } else {
            if (indexed_account.new_total_balance_d8 * settings.d8_to_d12 != indexed_account.old_balance_d12 
                                                            + (indexed_account.new_sent_acct_to_dapp_d8 * settings.d8_to_d12)
                                                            - (indexed_account.new_sent_dapp_to_acct_d8 * settings.d8_to_d12)) { return false; };
            if (indexed_account.new_total_balance_underflow_d8 != 0) { return false; };
        };

        true;
    };

    public func verify_convert_log_item_invariants(context : T.ConverterContext, convert_log_item : T.ConvertLogItem) : Bool {
        let settings = context.state.persistent.settings;
        let indexedAccount = convert_log_item.account;

        if (convert_log_item.args.amount * settings.d8_to_d12 != indexedAccount.new_total_balance_d8 * settings.d8_to_d12 
                                                                - (settings.new_fee_d8 * settings.d8_to_d12)) { return false };

        true;
    };

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
        "k6dka-zyaaa-aaaaj-aafla-cai", 
        "owdog-wiaaa-aaaad-qaaaq-cai",
        "ujkeo-2rcd5-pew4p-pkvrt-gpxo3-gmr7j-rssd3-jgk44-aq6dg-snvsw-mqe", 
        "eholc-klqlf-ru6kf-k5jv6-3gzhb-wxq53-tkyt4-flq3r-i7fuh-fzwwq-mqe", 
        "fhzp2-mb4kr-hm4io-32js7-oketg-gdi73-4pqb4-6jyxp-ajbhd-tuiwt-bqe", 
        "cb53b-qsf7f-isr4v-tco56-pu475-66ehq-cfkko-doax3-xrnjh-pdo57-zae", 
        "3zjeh-xtbtx-mwebn-37a43-7nbck-qgquk-xtrny-42ujn-gzaxw-ncbzw-kqe", 
        "o2ivq-5dsz3-nba5d-pwbk2-hdd3i-vybeq-qfz35-rqg27-lyesf-xghzc-3ae", 
        "5oynr-yl472-mav57-c2oxo-g7woc-yytib-mp5bo-kzg3b-622pu-uatef-uqe",
        "bdgzk-yzuhn-fa7uj-m6eu4-gyaxu-acj7k-3da6u-nsmqk-ylm55-xdpyx-2qe",
        "cdc3u-tzbte-m7kkb-itpbd-n6fci-ddby6-cwchd-uf5in-fgyq7-fcd3k-iqe",
        "h73t4-psgji-yzq63-mkoc5-pueva-zsu72-jwyl6-emflw-eqvsi-n7szy-lqe",
        "rzzfa-kyclu-choc6-i3bta-dmqhb-uwpah-wodwd-aoowy-rqx4b-bsfrq-wqe",
        "sbmbj-iieo2-orclf-ezqk7-6sa7m-xzays-m2bqs-dvxrm-keccv-4sqpb-xae",
        "f2kky-adefd-td7wi-oidzc-jfvf3-4jxop-4etiu-cpfrj-dshjw-sefhl-nae",
        "bkdfi-fsxtm-4bsgx-3mpaf-p72sg-h7niq-e2ojd-m7tam-4sotv-v25wz-uae",
        "ktuy7-f3zj3-hj5bk-z2a6v-fdpdy-puxww-mnyby-awzxd-wltxh-lhsr3-2qe",
        "u5boh-egjgy-766jt-jktcw-wefto-pbbli-uv6ws-qqxl2-c7vml-jwk64-wqe",
        "pr4sx-mnchz-e5g7k-bm3cv-sgldn-hyoce-krvhb-zh2i3-65zq5-wpxxd-wqe",
        "qt4zj-xkllb-go2g7-uiyrx-hu2wd-cghjq-6yrts-h45fx-efbk3-gkb2c-oae",
        "razbm-ydsn3-nyxdm-hebp6-rj5y2-ullnv-wu3yz-z5n5x-pbflj-rnz3s-nae"
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
        let waste = Converter.set_canister_ids(
            context, 
            Principal.fromText("czysu-eaaaa-aaaag-qcvdq-cai"), 
            Principal.fromText("czysu-eaaaa-aaaag-qcvdq-cai"), 
            Principal.fromText("czysu-eaaaa-aaaag-qcvdq-cai"), 
            Principal.fromText("czysu-eaaaa-aaaag-qcvdq-cai"));

        return context;
    };

    private func set_mocks(context : T.ConverterContext) {

        let waste = Converter.set_canister_ids(
            context, 
            Principal.fromText("b77ix-eeaaa-aaaaa-qaada-cai"), 
            Principal.fromText("bw4dl-smaaa-aaaaa-qaacq-cai"), 
            Principal.fromText("br5f7-7uaaa-aaaaa-qaaca-cai"), 
            Principal.fromText("be2us-64aaa-aaaaa-qaabq-cai"));

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
    
    public func is_ok_convert_result(result : ?T.ConvertResult) : Bool {
        switch (result) {
            case (null) { false };
            case (?res) { 
                switch (res) {
                    case (#Err(err)) { false };
                    case (#Ok(tx_index)) { tx_index == 1234; };
                };                
             };
        };
    };
    
    public func is_ok_burn_result(result : ?T.BurnOldTokensResult) : Bool {
        switch (result) {
            case (null) { false };
            case (?res) { 
                switch (res) {
                    case (#Err(err)) { false };
                    case (#Ok(tx_index)) { tx_index == 5678; };
                };                
             };
        };
    };

    public func log_last_seen_old(context : T.ConverterContext, index : T.TxIndex) : () {
        context.state.ephemeral.old_latest_sent_txids.put(context.account.owner, index);
    };

    public func log_last_seen_new(context : T.ConverterContext, index : T.TxIndex) : () {
        context.state.ephemeral.new_latest_sent_txids.put(context.account.owner, index);
    };

    public func must_get_latest_log_item(log : [T.LogItem], offset : Nat) : T.LogItem {
        switch (get_latest_log_item(log, offset)) {
            case (null) { Debug.trap("Expected log item"); };
            case (?item) { item; };
        };
    };

    public func get_latest_log_item(log : [T.LogItem], offset : Nat) : ?T.LogItem {
        if (log.size() < 1) { return null; };
        if (log.size() < offset) { return null; };
        ?log.get(log.size() - 1 - offset);
    };

    public func must_get_convert_log_item(log_item : ?T.LogItem) : T.ConvertLogItem {
        switch (get_convert_log_item(log_item)) {
            case (null) { Debug.trap("Expected convert log item"); };
            case (?convert) { convert; };
        };
    };

    public func get_convert_log_item(log_item : ?T.LogItem) : ?T.ConvertLogItem {
        switch (log_item) {
            case (null) { null; };
            case (?item) {
                item.convert;
            };
        };
    };

    public func must_get_burn_log_item(log_item : ?T.LogItem) : T.BurnLogItem {
        switch (get_burn_log_item(log_item)) {
            case (null) { Debug.trap("Expected burn log item"); };
            case (?burn) { burn; };
        };
    };

    public func get_burn_log_item(log_item : ?T.LogItem) : ?T.BurnLogItem {
        switch (log_item) {
            case (null) { null; };
            case (?item) {
                item.burn;
            };
        };
    };

    public func must_get_set_settings_log_item(log_item : ?T.LogItem) : T.SetSettingsLogItem {
        switch (get_set_settings_log_item(log_item)) {
            case (null) { Debug.trap("Expected set_settings log item"); };
            case (?set_settings) { set_settings; };
        };
    };

    public func get_set_settings_log_item(log_item : ?T.LogItem) : ?T.SetSettingsLogItem {
        switch (log_item) {
            case (null) { null; };
            case (?item) {
                item.set_settings;
            };
        };
    };

    public func must_get_set_canisters_log_item(log_item : ?T.LogItem) : T.SetCanistersLogItem {
        switch (get_set_canisters_log_item(log_item)) {
            case (null) { Debug.trap("Expected set_canister_ids log item"); };
            case (?set_canisters) { set_canisters; };
        };
    };

    public func get_set_canisters_log_item(log_item : ?T.LogItem) : ?T.SetCanistersLogItem {
        switch (log_item) {
            case (null) { null; };
            case (?item) {
                item.set_canisters;
            };
        };
    };

    public func must_get_exit_log_item(log_item : ?T.LogItem) : T.ExitLogItem {
        switch (get_exit_log_item(log_item)) {
            case (null) { Debug.trap("Expected exit log item"); };
            case (?exit) { exit; };
        };
    };

    public func get_exit_log_item(log_item : ?T.LogItem) : ?T.ExitLogItem {
        switch (log_item) {
            case (null) { null; };
            case (?item) {
                item.exit;
            };
        };
    };

    public func print_log_item(log_item : ?T.LogItem) : () {
        switch (log_item) {
            case (null) { Debug.print("log_item: null"); };
            case (?item) { 
                Debug.print("message: " # item.message);
                Debug.print("timestamp: " # Nat64.toText(item.timestamp));
                switch (item.convert) {
                    case null { };
                    case (?convert) { print_convert_log_item(convert); };
                };
            };
        };
    };

    public func print_convert_log_item(convert : T.ConvertLogItem) : () {
        switch (convert.result) {
            case (#Ok(tx_index)) { Debug.print("convert.result: #Ok(" # Nat.toText(tx_index) # ")"); };
            case _ { Debug.print("convert.result: Error."); };
        };
        Debug.print("convert.args.amount: " # Nat.toText(convert.args.amount));
        print_indexed_account(convert.account);
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
        Debug.print("is_burner: " # Bool.toText(indexed.is_burner));
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
        Debug.print("is_burner: " # Bool.toText(indexed.is_burner));
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