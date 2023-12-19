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

        if (Converter.CompareAccounts(account, TestUtil.get_test_account(4))) {
            return #Ok({
                transactions = [TestUtil.get_new_tx(115, 50000000, dapp, account)]; // 0.5 new tokens
                oldest_tx_id = ?115;
            });            
        };

        if (Converter.CompareAccounts(account, TestUtil.get_test_account(5))) {
            return #Ok({
                transactions = [TestUtil.get_new_tx(115, 50000000, dapp, account)]; // 0.5 new tokens
                oldest_tx_id = ?115;
            });            
        };

        if (Converter.CompareAccounts(account, TestUtil.get_test_account(6))) {
            return #Ok({
                transactions = [
                    TestUtil.get_new_tx(115, 50000000, dapp, account), // 0.5 new tokens
                    TestUtil.get_new_tx(125, 25000000, account, dapp) // 0.25 new tokens
                ]; 
                oldest_tx_id = ?115;
            });            
        };

        if (Converter.CompareAccounts(account, TestUtil.get_test_account(9))) {
            return #Ok({
                transactions = [
                    TestUtil.get_new_tx(115, 200000000, dapp, account), // 1 new tokens
                    TestUtil.get_new_tx(185, 100000000, account, dapp), // 1 new tokens
                ]; 
                oldest_tx_id = ?115;
            });            
        };

        #Ok({
            transactions = [];
            oldest_tx_id = null;
        })
    };

}