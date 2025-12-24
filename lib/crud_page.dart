import 'package:flutter/material.dart';
import 'package:firebase_database/firebase_database.dart';

class CrudPage extends StatefulWidget {
  final String type; // "task" or "profile"
  final bool disableFirebase; // ✅ added for widget tests

  const CrudPage({
    super.key,
    required this.type,
    this.disableFirebase = false,
  });

  @override
  State<CrudPage> createState() => _CrudPageState();
}

class _CrudPageState extends State<CrudPage> {
  // Controllers
  final taskController = TextEditingController();
  final nameController = TextEditingController();
  final emailController = TextEditingController();
  final ageController = TextEditingController();

  DatabaseReference? db;
  String? editId;

  @override
  void initState() {
    super.initState();

    if (widget.disableFirebase) return; // ✅ Skip Firebase in tests

    db = widget.type == "task"
        ? FirebaseDatabase.instance.ref("tasks")
        : FirebaseDatabase.instance.ref("profiles");
  }

  @override
  void dispose() {
    taskController.dispose();
    nameController.dispose();
    emailController.dispose();
    ageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          widget.type == "task"
              ? "Task Management"
              : "Profile Management",
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            /// INPUTS
            if (widget.type == "task") ...[
              TextField(
                controller: taskController,
                decoration: const InputDecoration(
                  labelText: "Enter Task",
                  border: OutlineInputBorder(),
                ),
              ),
            ] else ...[
              TextField(
                controller: nameController,
                decoration: const InputDecoration(
                  labelText: "Name",
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 10),
              TextField(
                controller: emailController,
                decoration: const InputDecoration(
                  labelText: "Email",
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 10),
              TextField(
                controller: ageController,
                decoration: const InputDecoration(
                  labelText: "Age",
                  border: OutlineInputBorder(),
                ),
              ),
            ],

            const SizedBox(height: 15),

            /// ADD / UPDATE BUTTON
            ElevatedButton(
              child: Text(
                editId == null
                    ? "Add ${widget.type == "task" ? "Task" : "Profile"}"
                    : "Update ${widget.type == "task" ? "Task" : "Profile"}",
              ),
              onPressed: widget.disableFirebase
                  ? null
                  : () {
                if (widget.type == "task") {
                  if (taskController.text.isEmpty) return;
                  if (editId == null) {
                    db!.push().set({"title": taskController.text});
                  } else {
                    db!.child(editId!).update(
                        {"title": taskController.text});
                    editId = null;
                  }
                  taskController.clear();
                } else {
                  if (nameController.text.isEmpty) return;
                  if (editId == null) {
                    db!.push().set({
                      "name": nameController.text,
                      "email": emailController.text,
                      "age": ageController.text,
                    });
                  } else {
                    db!.child(editId!).update({
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

            const SizedBox(height: 20),

            /// LIST
            Expanded(
              child: widget.disableFirebase
                  ? Center(
                child: Text(
                  "No ${widget.type}s Found",
                ),
              )
                  : StreamBuilder<DatabaseEvent>(
                stream: db!.onValue,
                builder: (context, snapshot) {
                  if (!snapshot.hasData ||
                      snapshot.data!.snapshot.value == null) {
                    return Center(
                      child: Text("No ${widget.type}s Found"),
                    );
                  }

                  final data = snapshot.data!.snapshot.value
                  as Map<dynamic, dynamic>;
                  final items = data.entries.toList();

                  return ListView.builder(
                    itemCount: items.length,
                    itemBuilder: (context, index) {
                      final id = items[index].key;
                      final item =
                      items[index].value as Map<dynamic, dynamic>;

                      return Card(
                        child: ListTile(
                          title: Text(
                            widget.type == "task"
                                ? item['title']
                                : item['name'],
                          ),
                        ),
                      );
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
