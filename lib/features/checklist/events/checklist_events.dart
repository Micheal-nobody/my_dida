class ChecklistDeletedEvent {
  ChecklistDeletedEvent({
    required this.checklistId,
    required this.affectedTaskIds,
  });
  final int checklistId;
  final List<int> affectedTaskIds;
}

class ChecklistRestoredEvent {
  ChecklistRestoredEvent({
    required this.checklistId,
    required this.affectedTaskIds,
  });
  final int checklistId;
  final List<int> affectedTaskIds;
}
