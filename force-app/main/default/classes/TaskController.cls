public with sharing class TaskController {
    @AuraEnabled
    public static List<Id> getTaskIdsByLeadId(Id leadId) {
        List<Task> tasks = [SELECT Id FROM Task WHERE WhoId = :leadId];
        List<Id> taskIds = new List<Id>();
        for (Task task : tasks) {
            taskIds.add(task.Id);
        }
        return taskIds;
    }
    
    @AuraEnabled
    public static String updateTaskDescription(String taskId, String description, String status) {
        Task taskToUpdate = [SELECT Id FROM Task WHERE Id = :taskId LIMIT 1];
        Id userId = UserInfo.getUserId();
        taskToUpdate.Description = description;
        taskToUpdate.Status = status;
        update taskToUpdate;
        String previousTaskSubject = [SELECT Subject FROM Task WHERE Id = :taskId].Subject;
        String recordIdWithoutPrefix = previousTaskSubject.substringAfter('701');
        String recordId = '701' + recordIdWithoutPrefix;
        List<Task> nextTask = new List<Task>();
        List<Task> nextTasks = [SELECT Id, WhoId, Subject FROM Task WHERE OwnerId = :userId AND Status != 'Completed' ORDER BY ActivityDate ASC LIMIT 1];
        for(Task tsk : nextTasks){
            if(tsk.Subject.contains(recordId)){
                nextTask.add(tsk);
            }
        }
        if (!nextTasks.isEmpty()) {
            String result = nextTasks[0].WhoId;
            return result;
        } else {
            return null;
        }
    }
}