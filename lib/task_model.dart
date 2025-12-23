class TaskModel {
  String id;
  String title;

  TaskModel({required this.id, required this.title});

  Map<String, dynamic> toMap() {
    return {"title": title};
  }

  factory TaskModel.fromMap(String id, Map data) {
    return TaskModel(
      id: id,
      title: data["title"] ?? "",
    );
  }
}
