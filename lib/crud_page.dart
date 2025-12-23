import 'package:flutter/material.dart';
import 'package:firebase_database/firebase_database.dart';

class CrudPage extends StatefulWidget {
  final String type; // "task" or "profile"

  CrudPage({required this.type});

  @override
  _CrudPageState createState() => _CrudPageState();
}

class _CrudPageState extends State<CrudPage> {

  // Controllers
  final taskController = TextEditingController();
  final nameController = TextEditingController();
  final emailController = TextEditingController();
  final ageController = TextEditingController();

  late DatabaseReference db;
  String? editId;

  @override
  void initState() {
    super.initState();
    db = widget.type == "task"
        ? FirebaseDatabase.instance.ref("tasks")
        : FirebaseDatabase.instance.ref("profiles");
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.type == "task" ? "Task Management" : "Profile Management"),
      ),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [

            /// INPUTS
            if (widget.type == "task") ...[
              TextField(
                controller: taskController,
                decoration: InputDecoration(
                  labelText: "Enter Task",
                  border: OutlineInputBorder(),
                ),
              ),
            ] else ...[
              TextField(
                controller: nameController,
                decoration: InputDecoration(
                  labelText: "Name",
                  border: OutlineInputBorder(),
                ),
              ),
              SizedBox(height: 10),
              TextField(
                controller: emailController,
                decoration: InputDecoration(
                  labelText: "Email",
                  border: OutlineInputBorder(),
                ),
              ),
              SizedBox(height: 10),
              TextField(
                controller: ageController,
                decoration: InputDecoration(
                  labelText: "Age",
                  border: OutlineInputBorder(),
                ),
              ),
            ],

            SizedBox(height: 15),

            /// ADD / UPDATE BUTTON
            ElevatedButton(
              child: Text(editId == null
                  ? "Add ${widget.type == "task" ? "Task" : "Profile"}"
                  : "Update ${widget.type == "task" ? "Task" : "Profile"}"),
              onPressed: () {
                if (widget.type == "task") {
                  if (taskController.text.isEmpty) return;
                  if (editId == null) {
                    db.push().set({"title": taskController.text});
                  } else {
                    db.child(editId!).update({"title": taskController.text});
                    editId = null;
                  }
                  taskController.clear();
                } else {
                  if (nameController.text.isEmpty) return;
                  if (editId == null) {
                    db.push().set({
                      "name": nameController.text,
                      "email": emailController.text,
                      "age": ageController.text,
                    });
                  } else {
                    db.child(editId!).update({
                      "name": nameController.text,
                      "email": emailController.text,
                      "age": ageController.text,
                    });
                    editId = null;
                  }
                  nameController.clear();
                  emailController.clear();
                  ageController.clear();
                }
              },
            ),

            SizedBox(height: 20),

            /// LIST
            Expanded(
              child: StreamBuilder(
                stream: db.onValue,
                builder: (context, snapshot) {
                  if (!snapshot.hasData ||
                      snapshot.data == null ||
                      (snapshot.data! as DatabaseEvent).snapshot.value == null) {
                    return Center(child: Text("No ${widget.type}s Found"));
                  }

                  final data = (snapshot.data! as DatabaseEvent).snapshot.value as Map;
                  final items = data.entries.toList();

                  return ListView.builder(
                    itemCount: items.length,
                    itemBuilder: (context, index) {
                      final id = items[index].key;
                      final item = items[index].value;

                      return Card(
                        child: ListTile(
                          leading: widget.type == "task"
                              ? Icon(Icons.task_alt)
                              : CircleAvatar(
                            child: Text(item['name'][0].toUpperCase()),
                          ),
                          title: Text(widget.type == "task" ? item['title'] : item['name']),
                          subtitle: widget.type == "task"
                              ? null
                              : Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(item['email']),
                              Text("Age: ${item['age']}"),
                            ],
                          ),
                          trailing: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              IconButton(
                                icon: Icon(Icons.edit, color: Colors.blue),
                                onPressed: () {
                                  editId = id;
                                  if (widget.type == "task") {
                                    taskController.text = item['title'];
                                  } else {
                                    nameController.text = item['name'];
                                    emailController.text = item['email'];
                                    ageController.text = item['age'];
                                  }
                                },
                              ),
                              IconButton(
                                icon: Icon(Icons.delete, color: Colors.red),
                                onPressed: () {
                                  db.child(id).remove();
                                },
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  );
                },
              ),
            )
          ],
        ),
      ),
    );
  }
}
