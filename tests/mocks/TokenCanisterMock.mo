import Principal "mo:base/Principal";
import Debug "mo:base/Debug";

import Converter "../../src/";

import T "../../src/Types";
import TestUtil "../utils/TestUtil";

shared actor class TokenMock() : async T.TokenInterface = {

    public func icrc1_transfer(args : T.TransferArgs) : async T.TransferResult {

        let acct = args.to;

        let dapp : T.Account = {
            owner = Principal.fromText("czysu-eaaaa-aaaag-qcvdq-cai");
            subaccount = null;
        };

        if (Converter.CompareAccounts(acct, TestUtil.get_test_account(26))) {
            Debug.trap("New ledger canister mock trapped.");            
        };

        #Ok(1234)
    };

    public func burn(args : T.BurnArgs) : async T.TransferResult {

        if (args.amount == 42000000000000) {
            Debug.trap("Old ledger canister mock trapped.");            
        };

        #Ok(5678)
    };

}