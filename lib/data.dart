import 'dart:async';

import 'package:flutter/widgets.dart';
import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';

var database;
class Dog {
  final int id;
  final String name;
  final int age;

  const Dog({
      required this.id,
      required this.name,
      required this.age,
  });

  // Convert a Dog into a Map. The keys must correspond to the names of the
  // columns in the database.
  Map<String, Object?> toMap() {
    return <String, Object?>{
      'id': id,
      'name': name,
      'age': age,
    };
  }

  // Implement toString to make it easier to see information about
  // each dog when using the print statement.
  @override
  String toString() {
    return 'Dog{id: $id, name: $name, age: $age}';
  }
}
// Define a function that inserts dogs into the database
Future<void> insertDog(Database db, Dog dog) async {
  // Insert the Dog into the correct table. You might also specify the
  // `conflictAlgorithm` to use in case the same dog is inserted twice.
  //
  // In this case, replace any previous data.
  await db.insert(
    'dogs',
    dog.toMap(),
    conflictAlgorithm: ConflictAlgorithm.replace,
  );
}
Future<Database> init_database() async{
  final db = await openDatabase(
    // Set the path to the database. Note: Using the `join` function from the
    // `path` package is best practice to ensure the path is correctly
    // constructed for each platform.
    join(await getDatabasesPath(), 'the_database.db'),
    onCreate: (db, version) {
      // Run the CREATE TABLE statement on the database.
      return db.execute(
        'CREATE TABLE dogs(id INTEGER PRIMARY KEY, name TEXT, age INTEGER)',
      );
    },
    // Set the version. This executes the onCreate function and provides a
    // path to perform database upgrades and downgrades.
    version: 1,
  );
  //await insertDog(db, Dog(id: 1, name: "Doggo", age: 2));
  //await insertDog(db, Dog(id: 2, name: "Froggo", age: 5));
  //await insertDog(db, Dog(id: 7, name: "Mouso", age: 1));
  return db;
}

Future<List<String>> get_dogs() async{
  final db = await database;
  // Query the table for all the dogs.
  final List<Map<String, Object?>> dogMaps = await db.query('dogs');

  // Convert the list of each dog's fields into a list of `Dog` objects.
  return [
    for (final {
          'id': id as int,
          'name': name as String,
          'age': age as int,
        } in dogMaps)
        //item.toString()
        "id = ${id as int}, name = ${name as String}, age = ${age as int}"
  ];
}

// Dogs stream thing, will have to be a global object
class DogStore {
  DogStore({required this.db}){
    _notify_subscribers();
    // db.execute(
    //   'CREATE TABLE dogs(id INTEGER PRIMARY KEY, name TEXT, age INTEGER)'
    // );
  }
  final Future<Database> db;
  final StreamController<List<Dog>> _controller = StreamController.broadcast();

  Stream<List<Dog>> subscribe(){
    _notify_subscribers();
    return _controller.stream;
  }
  Future<void> remove(int id) async{

    await (await db).delete(
      'dogs',
      // Use a `where` clause to delete a specific dog.
      where: 'id = ?',
      // Pass the Dog's id as a whereArg to prevent SQL injection.
      whereArgs: [id],
    );
    
    await _notify_subscribers();
    print("Hello, just removed a dog");
  }

  Future<void> _notify_subscribers() async{
    // Query the table for all the dogs.
    final List<Map<String, Object?>> dogMaps = await (await db).query('dogs');
    // Convert the list of each dog's fields into a list of `Dog` objects.
    _controller.add([
        for (final {
            'id': id as int,
            'name': name as String,
            'age': age as int,
        } in dogMaps)
        //item.toString()
        Dog(id: id as int,name: name as String,age: age as int)
        //"id = ${id as int}, name = ${name as String}, age = ${age as int}"
    ]);
    print("Hello, just notified subscribers");
  }
  
  Future<void> insert(Dog dog) async{
    await insertDog(await db, dog);
    await _notify_subscribers();
    print("Hello, just inserted a dog");
  }

  void dispose(){
    _controller.close();
  }
}

var dogstore;



