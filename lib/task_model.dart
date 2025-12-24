class TaskModel {
  final String id;
  final String title;

  TaskModel({required this.id, required this.title});

  /// Convert TaskModel to a Map (for saving to Firebase)
  Map<String, dynamic> toMap() {
    return {
      "title": title,
    };
  }

  /// Create a TaskModel from Firebase data
  factory TaskModel.fromMap(String id, Map<String, dynamic> data) {
    return TaskModel(
      id: id,
      title: data["title"] ?? "",
    );
  }
}
