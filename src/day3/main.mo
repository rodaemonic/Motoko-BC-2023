import Type "Types";
import Buffer "mo:base/Buffer";
import Result "mo:base/Result";
import Array "mo:base/Array";
import Iter "mo:base/Iter";
import HashMap "mo:base/HashMap";
import Nat "mo:base/Nat";
import Nat32 "mo:base/Nat32";
import Text "mo:base/Text";
import Hash "mo:base/Hash";
import Option "mo:base/Option";
import Int "mo:base/Int";
import Order "mo:base/Order";
import Debug "mo:base/Debug";

actor class StudentWall() {
  type Message = Type.Message;
  type Content = Type.Content;
  type Survey = Type.Survey;
  type Answer = Type.Answer;

  var messageId : Nat = 0;
  let wall = HashMap.HashMap<Nat, Message>(1, Nat.equal, Hash.hash);

  // Add a new message to the wall
  public shared ({ caller }) func writeMessage(c : Content) : async Nat {
    let id = messageId;
    let msg : Message = {
      content = c;
      vote = 0;
      creator = caller;
    };
    wall.put(messageId, msg);
    messageId += 1;
    return id;
  };

  // Get a specific message by ID
  public shared query func getMessage(_messageId : Nat) : async Result.Result<Message, Text> {
    let messRes : ?Message = wall.get(_messageId);
    switch (messRes) {
      case (null) {
        #err("This message don't exist");
      };
      case (?currentMessage) {
        #ok(currentMessage);
      };
    };
  };

  // Update the content for a specific message by ID
  public shared ({ caller }) func updateMessage(_messageId : Nat, c : Content) : async Result.Result<(), Text> {
    let messRes : ?Message = wall.get(_messageId);
    switch (messRes) {
      case (null) {
        #err("This message don't exist");
      };
      case (?currentMessage) {
        let updatedMessage : Message = {
          content = c;
          vote = currentMessage.vote;
          creator = currentMessage.creator;
        };
        wall.put(_messageId, updatedMessage);
        #ok();
      };
    };
  };

  // Delete a specific message by ID
  public shared ({ caller }) func deleteMessage(_messageId : Nat) : async Result.Result<(), Text> {
    let messRes : ?Message = wall.get(_messageId);
    switch (messRes) {
      case (null) {
        #err("This message don't exist");
      };
      case (_) {
        ignore wall.remove(_messageId);
        #ok();
      };
    };
  };

  // Voting
  public func upVote(_messageId : Nat) : async Result.Result<(), Text> {
    let messRes : ?Message = wall.get(_messageId);
    switch (messRes) {
      case (null) {
        #err("This message don't exist");
      };
      case (?currentMessage) {
        let updatedMessage : Message = {
          content = currentMessage.content;
          vote = currentMessage.vote + 1;
          creator = currentMessage.creator;
        };
        wall.put(_messageId, updatedMessage);
        #ok();
      };
    };
  };

  public func downVote(_messageId : Nat) : async Result.Result<(), Text> {
    let messRes : ?Message = wall.get(_messageId);
    switch (messRes) {
      case (null) {
        #err("This message don't exist");
      };
      case (?currentMessage) {
        let updatedMessage : Message = {
          content = currentMessage.content;
          vote = currentMessage.vote - 1;
          creator = currentMessage.creator;
        };
        wall.put(_messageId, updatedMessage);
        #ok();
      };
    };
  };

  // Get all messages
  public func getAllMessages() : async [Message] {
    let allMessages = wall.vals();
    var result : [Message] = Iter.toArray(allMessages);
    result;
  };

  // Get all messages ordered by votes
  public func getAllMessagesRanked() : async [Message] {
    let allMessages = wall.vals();
    var result : [Message] = Iter.toArray(allMessages);
    result := Array.sort<Message>(
      result,
      func(m1 : Message, m2 : Message) : Order.Order {
        if (Order.isGreater(Int.compare(m1.vote, m2.vote))) {
          return Int.compare(m2.vote, m1.vote);
        } else {
          return Int.compare(m1.vote, m2.vote);
        };
      },
    );
    for (i in result.vals()) {
      Debug.print(Int.toText(i.vote));
    };
    result;
  };
};
