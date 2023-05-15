import TrieMap "mo:base/TrieMap";
import Trie "mo:base/Trie";
import Result "mo:base/Result";
import Text "mo:base/Text";
import Option "mo:base/Option";
import Debug "mo:base/Debug";

import Account "Account";
// NOTE: only use for local dev,
// when deploying to IC, import from "rww3b-zqaaa-aaaam-abioa-cai"
import BootcampLocalActor "BootcampLocalActor";
import Principal "mo:base/Principal";

actor class MotoCoin() {
  public type Account = Account.Account;
  var ledger = TrieMap.TrieMap<Account, Nat>(Account.accountsEqual, Account.accountsHash);
  // Returns the name of the token
  public query func name() : async Text {
    return "MotoCoin";
  };

  // Returns the symbol of the token
  public query func symbol() : async Text {
    return "MOC";
  };

  // Returns the the total number of tokens on all accounts
  public func totalSupply() : async Nat {
    var supply : Nat = 0;
    for (balance in ledger.vals()) {
      supply += balance;
    };
    supply;
  };

  // Returns the default transfer fee
  public query func balanceOf(account : Account) : async (Nat) {
    let balance = ledger.get(account);
    switch (balance) {
      case (?value) {
        return value;
      };
      case (null) {
        return 0;
      };
    };
  };

  // Transfer tokens to another account
  public shared ({ caller }) func transfer(
    from : Account,
    to : Account,
    amount : Nat,
  ) : async Result.Result<(), Text> {
    let fromBalance = ledger.get(from);
    switch (fromBalance) {
      case (?fromValue) {
        if (amount > fromValue) {
          return #err("Not enough balance");
        } else {
          ledger.put(from, fromValue - amount);
          let toBalance = ledger.get(to);
          switch (toBalance) {
            case (?toValue) {
              #ok(ledger.put(to, toValue + amount));
            };
            case (null) {
              #ok(ledger.put(to, amount));
            };
          };
        };
      };
      case (null) {
        return #err("Account with zero balance");
      };
    };
  };

  // Airdrop 1000 MotoCoin to any student that is part of the Bootcamp.
  public func airdrop() : async Result.Result<(), Text> {
    let localActor = actor ("rww3b-zqaaa-aaaam-abioa-cai") : actor {
      getAllStudentsPrincipal : shared () -> async [Principal];
    };
    let wallets = await localActor.getAllStudentsPrincipal();
    for (wallet in wallets.vals()) {
      let account : Account = {
        owner = wallet;
        subaccount = null;
      };
      ledger.put(account, 100);
    };
    return #ok();
  };
};
