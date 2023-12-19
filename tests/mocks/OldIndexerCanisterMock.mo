import Principal "mo:base/Principal";

import T "../../src/Types";
import TestUtil "../utils/TestUtil";

shared actor class OldIndexerMock() : async T.OldIndexerInterface = {

    public func get_account_transactions(account : Text) : async [T.OldTransaction] {

        let acct : T.Account = {
            owner = Principal.fromText(account);
            subaccount = null;
        };
        let dapp : T.Account = {
            owner = Principal.fromText("czysu-eaaaa-aaaag-qcvdq-cai");
            subaccount = null;
        };

        if (account == Principal.toText(TestUtil.get_test_account(0).owner)) {
            return [];
        };

        if (account == Principal.toText(TestUtil.get_test_account(1).owner)) {
            return [ TestUtil.get_old_tx(100, 1000000000000, acct, dapp) ]; // 1 old token
        };

        if (account == Principal.toText(TestUtil.get_test_account(2).owner)) {
            return [ 
                TestUtil.get_old_tx(100, 1000000000000, acct, dapp), // 1 old token
                TestUtil.get_old_tx(105, 2000000000000, acct, dapp)  // 2 old tokens
            ];
        };

        if (account == Principal.toText(TestUtil.get_test_account(3).owner)) {
            return [ 
                TestUtil.get_old_tx(100, 1000000000000, acct, dapp), // 1 old token
                TestUtil.get_old_tx(105, 2000000000000, acct, dapp),  // 2 old tokens
                TestUtil.get_old_tx(110, 500000000000, dapp, acct)  // 0.5 old tokens
            ];
        };

        if (account == Principal.toText(TestUtil.get_test_account(4).owner)) {
            return [ 
                TestUtil.get_old_tx(100, 1000000000000, acct, dapp), // 1 old token
                TestUtil.get_old_tx(105, 2000000000000, acct, dapp)  // 2 old tokens
            ];
        };

        if (account == Principal.toText(TestUtil.get_test_account(5).owner)) {
            return [ 
                TestUtil.get_old_tx(100, 1000000000000, acct, dapp), // 1 old token
                TestUtil.get_old_tx(105, 2000000000000, acct, dapp),  // 2 old tokens
                TestUtil.get_old_tx(110, 500000000000, dapp, acct)  // 0.5 old tokens
            ];
        };

        if (account == Principal.toText(TestUtil.get_test_account(6).owner)) {
            return [ 
                TestUtil.get_old_tx(100, 1000000000000, acct, dapp), // 1 old token
                TestUtil.get_old_tx(105, 2000000000000, acct, dapp),  // 2 old tokens
                TestUtil.get_old_tx(110, 500000000000, dapp, acct)  // 0.5 old tokens
            ];
        };

        if (account == Principal.toText(TestUtil.get_test_account(7).owner)) {
            return [ TestUtil.get_old_tx(100, 1234567891234, acct, dapp) ]; // 1 old token
        };

        if (account == Principal.toText(TestUtil.get_test_account(8).owner)) {
            return [ 
                TestUtil.get_old_tx(100, 1000000000000, acct, dapp), // 1 old token
                TestUtil.get_old_tx(195, 2000000000000, dapp, acct)  // 2 old tokens
            ];
        };

        [];
    };

    public func synch_archive_full(token: Text) : async T.OldSynchStatus {
        {
            tx_total = 1234;
            tx_synched = 1233;
        };
    };

}