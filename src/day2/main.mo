import Buffer "mo:base/Buffer";
import Result "mo:base/Result";
import Array "mo:base/Array";

import Type "Types";
import Text "mo:base/Text";
import Iter "mo:base/Iter";
import Debug "mo:base/Debug";
import Bool "mo:base/Bool";
import Int "mo:base/Int";
import Nat "mo:base/Nat";

actor class Homework() {
  type Homework = Type.Homework;
  var homeworkDiary = Buffer.Buffer<Homework>(0);
  // Add a new homework task
  public shared func addHomework(homework : Homework) : async Nat {
    homeworkDiary.add(homework);
    homeworkDiary.size() - 1;
  };

  // Get a specific homework task by id
  public shared query func getHomework(id : Nat) : async Result.Result<Homework, Text> {
    if (id > homeworkDiary.size()) {
      return #err("This id don't exist");
    } else {
      return #ok(homeworkDiary.get(id));
    };
  };

  // Update a homework task's title, description, and/or due date
  public shared func updateHomework(id : Nat, homework : Homework) : async Result.Result<(), Text> {
    if (id > homeworkDiary.size()) {
      return #err("This id don't exist");
    } else {
      homeworkDiary.put(id, homework);
      return #ok();
    };
  };

  // Mark a homework task as completed
  public shared func markAsCompleted(id : Nat) : async Result.Result<(), Text> {
    if (id > homeworkDiary.size()) {
      return #err("This id don't exist");
    } else {
      let homeworkConsulted : Homework = homeworkDiary.get(id);
      let homeworkUpdated : Homework = {
        title = homeworkConsulted.title;
        description = homeworkConsulted.description;
        dueDate = homeworkConsulted.dueDate;
        completed = true;
      };
      homeworkDiary.put(id, homeworkUpdated);
      return #ok();
    };
  };

  // Delete a homework task by id
  public shared func deleteHomework(id : Nat) : async Result.Result<(), Text> {
    if (id > homeworkDiary.size()) {
      return #err("This id don't exist");
    } else {
      ignore homeworkDiary.remove(id);
      return #ok();
    };
  };

  // Get the list of all homework tasks
  public shared query func getAllHomework() : async [Homework] {
    return Buffer.toArray(homeworkDiary);
  };

  // Get the list of pending (not completed) homework tasks
  public shared query func getPendingHomework() : async [Homework] {
    var result = Buffer.Buffer<Homework>(0);
    for (work in homeworkDiary.vals()) {
      Debug.print(Bool.toText(work.completed));
      if (not work.completed) {
        result.add(work);
      };
    };
    Debug.print(Nat.toText(result.size()));
    Buffer.toArray(result);
  };

  // Search for homework tasks based on a search terms
  public shared query func searchHomework(searchTerm : Text) : async [Homework] {
    var result = Buffer.Buffer<Homework>(0);
    for (item in homeworkDiary.vals()) {
      if (Text.contains(item.title, #text searchTerm)) {
        result.add(item);
      };
    };
    Buffer.toArray(result);
  };
};
