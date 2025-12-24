import 'package:flutter/material.dart';
import 'package:firebase_database/firebase_database.dart';

class CrudPage extends StatefulWidget {
  final String type; // "task" or "profile"
  final bool disableFirebase; // ✅ for tests

  const CrudPage({
    super.key,
    required this.type,
    this.disableFirebase = false,
  });

  @override
  State<CrudPage> createState() => _CrudPageState();
}

class _CrudPageState extends State<CrudPage> {
  final taskController = TextEditingController();
  final nameController = TextEditingController();
  final emailController = TextEditingController();
  final ageController = TextEditingController();

  DatabaseReference? db;
  String? editId;

  @override
  void initState() {
    super.initState();
    if (!widget.disableFirebase) {
      db = widget.type == "task"
          ? FirebaseDatabase.instance.ref("tasks")
          : FirebaseDatabase.instance.ref("profiles");
    }
  }

  @override
  void dispose() {
    taskController.dispose();
    nameController.dispose();
    emailController.dispose();
    ageController.dispose();
    super.dispose();
  }

  void addOrUpdateItem() {
    if (widget.type == "task") {
      if (taskController.text.isEmpty) return;
      if (editId == null) {
        db!.push().set({"title": taskController.text});
        ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text("Task added successfully")));
      } else {
        db!.child(editId!).update({"title": taskController.text});
        ScaffoldMessenger.of(context)
            .showSnackBar(const SnackBar(content: Text("Task updated")));
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
        ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text("Profile added successfully")));
      } else {
        db!.child(editId!).update({
          "name": nameController.text,
          "email": emailController.text,
          "age": ageController.text,
        });
        ScaffoldMessenger.of(context)
            .showSnackBar(const SnackBar(content: Text("Profile updated")));
        editId = null;
      }
      nameController.clear();
      emailController.clear();
      ageController.clear();
    }
  }

  void populateForEdit(String id, Map<dynamic, dynamic> item) {
    setState(() {
      editId = id;
      if (widget.type == "task") {
        taskController.text = item['title'] ?? '';
      } else {
        nameController.text = item['name'] ?? '';
        emailController.text = item['email'] ?? '';
        ageController.text = item['age'] ?? '';
      }
    });
  }

  void deleteItem(String id) {
    db!.child(id).remove();
    ScaffoldMessenger.of(context)
        .showSnackBar(const SnackBar(content: Text("Deleted successfully")));
    if (editId == id) {
      editId = null;
      taskController.clear();
      nameController.clear();
      emailController.clear();
      ageController.clear();
    }
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
              onPressed: widget.disableFirebase ? null : addOrUpdateItem,
              child: Text(editId == null
                  ? "Add ${widget.type == "task" ? "Task" : "Profile"}"
                  : "Update ${widget.type == "task" ? "Task" : "Profile"}"),
            ),
            const SizedBox(height: 20),

            /// LIST
            Expanded(
              child: widget.disableFirebase
                  ? Center(child: Text("No ${widget.type}s Found"))
                  : StreamBuilder<DatabaseEvent>(
                stream: db!.onValue,
                builder: (context, snapshot) {
                  if (!snapshot.hasData ||
                      snapshot.data!.snapshot.value == null) {
                    return Center(child: Text("No ${widget.type}s Found"));
                  }

                  final data = Map<String, dynamic>.from(
                      snapshot.data!.snapshot.value as Map);
                  final items = data.entries.toList();

                  return ListView.builder(
                    itemCount: items.length,
                    itemBuilder: (context, index) {
                      final id = items[index].key!;
                      final item =
                      Map<String, dynamic>.from(items[index].value);

                      return Card(
                        child: ListTile(
                          title: Text(
                            widget.type == "task" ? item['title'] ?? '' : item['name'] ?? '',
                          ),
                          subtitle: widget.type == "profile"
                              ? Text(item['email'] ?? '')
                              : null,
                          trailing: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              IconButton(
                                icon: const Icon(Icons.edit),
                                onPressed: () => populateForEdit(id, item),
                              ),
                              IconButton(
                                icon: const Icon(Icons.delete),
                                onPressed: () => deleteItem(id),
                              ),
                            ],
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
