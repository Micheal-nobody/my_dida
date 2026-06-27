class ChecklistDeletedEvent {
  final int checklistId;
  final List<int> affectedTaskIds;

  ChecklistDeletedEvent({
    required this.checklistId,
    required this.affectedTaskIds,
  });
}

class ChecklistRestoredEvent {
  final int checklistId;
  final List<int> affectedTaskIds;

  ChecklistRestoredEvent({
    required this.checklistId,
    required this.affectedTaskIds,
  });
}
