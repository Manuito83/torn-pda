import 'dart:developer';

import 'package:get/get.dart';
import 'package:torn_pda/utils/shared_prefs.dart';

class PeriodicExecutionController extends GetxController {
  final Map<String, _TaskDetails> _tasks = {};

  /// Registers a task with a unique name for periodic execution
  /// [taskName] (unique)
  /// [task] method to execute
  /// [intervalInHours] interval in hours
  /// [executeImmediately] if true, the task will execute as soon as it is registered
  /// [overwrite] if true, it will remove any existing task with the same name
  Future<void> registerTask(
    String taskName,
    Function task, {
    required int intervalInHours,
    bool executeImmediately = false,
    bool overwrite = false,
  }) async {
    try {
// If overwrite is enabled, remove the existing task
      if (_tasks.containsKey(taskName) && overwrite) {
        await cancelTask(taskName); // Remove the existing task
      }

      // Ensure the taskName is unique
      if (_tasks.containsKey(taskName)) {
        throw Exception('Task with name "$taskName" already exists');
      }

      _tasks[taskName] = _TaskDetails(task, intervalInHours);

      if (executeImmediately) {
        await task();
        await _updateLastExecutionTime(taskName);
      }
    } catch (e) {
      log("$e", name: "Periodic Execution Controller");
    }
  }

  /// Checks and executes tasks if the interval has passed since the last execution
  Future<void> checkAndExecuteTasks() async {
    final prefs = Prefs();
    final now = DateTime.now().millisecondsSinceEpoch;

    for (var taskName in _tasks.keys) {
      final taskDetails = _tasks[taskName]!;

      final lastExecution = await prefs.getLastExecutionTime(taskName);
      final intervalInMs = taskDetails.intervalInHours * 3600000;

      // Check if the interval has passed
      if (now - lastExecution >= intervalInMs) {
        // Execute the task and update the last execution time
        await taskDetails.task();
        await _updateLastExecutionTime(taskName);
      }
    }
  }

  /// Cancels a task by its name and removes its execution state
  Future<void> cancelTask(String taskName) async {
    try {
      if (!_tasks.containsKey(taskName)) {
        throw Exception('Task "$taskName" is not registered');
      }

      _tasks.remove(taskName);

      await Prefs().removeLastExecutionTime(taskName);
    } catch (e) {
      log("$e", name: "Periodic Execution Controller");
    }
  }

  /// Updates the last execution time for a given task
  Future<void> _updateLastExecutionTime(String taskName) async {
    final now = DateTime.now().millisecondsSinceEpoch;
    await Prefs().setLastExecutionTime(taskName, now);
  }
}

class _TaskDetails {
  final Function task;
  final int intervalInHours;

  _TaskDetails(this.task, this.intervalInHours);
}
