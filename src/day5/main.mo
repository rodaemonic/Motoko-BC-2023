import HashMap "mo:base/HashMap";
import Principal "mo:base/Principal";
import Hash "mo:base/Hash";
import Error "mo:base/Error";
import Result "mo:base/Result";
import Array "mo:base/Array";
import Text "mo:base/Text";
import Nat "mo:base/Nat";
import Int "mo:base/Int";
import Timer "mo:base/Timer";
import Debug "mo:base/Debug";
import Buffer "mo:base/Buffer";
import Utils "Utils";
import IC "Ic";
import HTTP "Http";
import Type "Types";
import Calculator "Calculator";

actor class Verifier() {
  type StudentProfile = Type.StudentProfile;
  var studentProfileStore = HashMap.HashMap<Principal, StudentProfile>(1, Principal.equal, Principal.hash);
  // STEP 1 - BEGIN
  public shared ({ caller }) func addMyProfile(profile : StudentProfile) : async Result.Result<(), Text> {
    #ok(studentProfileStore.put(caller, profile));
  };

  public shared ({ caller }) func seeAProfile(p : Principal) : async Result.Result<StudentProfile, Text> {
    let targetProfile = studentProfileStore.get(p);
    switch (targetProfile) {
      case (?profile) {
        return #ok(profile);
      };
      case (null) {
        #err("Profile don't exist");
      };
    };
  };

  public shared ({ caller }) func updateMyProfile(profile : StudentProfile) : async Result.Result<(), Text> {
    let targetProfile = studentProfileStore.get(caller);
    switch (targetProfile) {
      case (?profile) {
        return #ok(studentProfileStore.put(caller, profile));
      };
      case (null) {
        #err("Profile don't exist");
      };
    };
  };

  public shared ({ caller }) func deleteMyProfile() : async Result.Result<(), Text> {
    let targetProfile = studentProfileStore.get(caller);
    switch (targetProfile) {
      case (?profile) {
        return #ok(studentProfileStore.delete(caller));
      };
      case (null) {
        #err("Profile don't exist");
      };
    };
  };
  // STEP 1 - END

  // STEP 2 - BEGIN
  type calculatorInterface = Type.CalculatorInterface;
  public type TestResult = Type.TestResult;
  public type TestError = Type.TestError;

  public func test(canisterId : Principal) : async TestResult {
    try {
      let calculatorInterface = actor (Principal.toText(canisterId)) : Type.CalculatorInterface;
      let x1 : Int = await calculatorInterface.reset();
      if (x1 != 0) {
        return #err(#UnexpectedValue("After a reset, 0 expected, " # Int.toText(x1) # " received!"));
      };
      let x2 : Int = await calculatorInterface.add(2);
      if (x2 != 2) {
        return #err(#UnexpectedValue("Error on add 0 + 2, 2 expected, " # Int.toText(x2) # " received!"));
      };
      let x3 : Int = await calculatorInterface.sub(2);
      if (x3 != 0) {
        return #err(#UnexpectedValue("error on sub 2 - 2, 0 expected, " # Int.toText(x3) # " received!"));
      };
      return #ok();
    } catch (e) {
      return #err(#UnexpectedError("Something went wrong when calling the canister " # Error.message(e)));
    };
  };
  // STEP - 2 END

  // STEP 3 - BEGIN
  // NOTE: Not possible to develop locally,
  // as actor "aaaaa-aa" (aka the IC itself, exposed as an interface) does not exist locally
  public func verifyOwnership(canisterId : Principal, p : Principal) : async Bool {
    let managementCanister : IC.ManagementCanisterInterface = actor ("aaaaa-aa");
    try {
      let statusCanister = await managementCanister.canister_status({
        canister_id = canisterId;
      });
      let controllers = statusCanister.settings.controllers;
      let controllers_text = Array.map<Principal, Text>(controllers, func x = Principal.toText(x));
      switch (Array.find<Principal>(controllers, func x = p == x)) {
        case (?_) { return true };
        case null { return false };
      };
    } catch (e) {
      let message = Error.message(e);
      let controllers = await Utils.parseControllersFromCanisterStatusErrorIfCallerNotController(message);
      let controllers_text = Array.map<Principal, Text>(controllers, func x = Principal.toText(x));
      switch (Array.find<Principal>(controllers, func x = p == x)) {
        case (?_) { return true };
        case null { return false };
      };
    };
  };
  // STEP 3 - END

  // STEP 4 - BEGIN
  public shared ({ caller }) func verifyWork(canisterId : Principal, p : Principal) : async Result.Result<(), Text> {
    let ownership : Bool = await verifyOwnership(canisterId, caller);
    switch (ownership) {
      case (true) {};
      case (false) {
        return #err("Wrong validator");
      };
    };
    let testResult = await test(canisterId);
    switch (testResult) {
      case (#ok(value)) {
        #ok();
      };
      case (#err(error)) {
        return #err("Wrong results");
      };
    };
  };
  // STEP 4 - END
};
