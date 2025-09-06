
//TODO: 这是一个用于生成详细的 todo 任务weight的类，也许我应该把他放进 TodosProvider 中去？
class TodoDetails {
  String title;
  String description;
  String date;
  String time;
  bool isCompleted;

  TodoDetails({
    required this.title,
    required this.description,
    required this.date,
    required this.time,
    this.isCompleted = false,
  });

  Map<String, dynamic> toMap() {
    return {
      'title': title,
      'description': description,
      'date': date,
      'time': time,
      'isCompleted': isCompleted ? 1 : 0,
    };
  }

  @override
  String toString() {
    return 'TodoDeatils{title: $title, description: $description, date: $date, time: $time, isCompleted: $isCompleted}';
  }
}