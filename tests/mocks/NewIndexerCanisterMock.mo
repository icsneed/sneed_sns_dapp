import Principal "mo:base/Principal";

import Converter "../../src/";
import T "../../src/Types";
import TestUtil "../utils/TestUtil";

shared actor class NewIndexerMock() : async T.NewIndexerInterface = {

    public func get_account_transactions(request : T.NewIndexerRequest) : async T.GetNewTransactionsResult {

        let account = request.account;

        let dapp : T.Account = {
            owner = Principal.fromText("czysu-eaaaa-aaaag-qcvdq-cai");
            subaccount = null;
        };

        if (Converter.CompareAccounts(account, TestUtil.get_test_account(3))) {
            return #Ok({
                transactions = [TestUtil.get_new_tx(115, 50000000, dapp, account)]; // 0.5 new tokens
                oldest_tx_id = ?115;
            });            
        };


        #Ok({
            transactions = [];
            oldest_tx_id = null;
        })
    };

}