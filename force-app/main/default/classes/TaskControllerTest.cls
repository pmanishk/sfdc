@isTest
public class TaskControllerTest {
    @isTest
    static void testGetTaskIdsByLeadId() {
        // Test data setup
        Lead testLead = new Lead(FirstName = 'Test', LastName = 'Lead', Status = 'New');
        insert testLead;

        Task testTask = new Task(Subject = 'Test Task', WhoId = testLead.Id, Status = 'Not Started', Priority = 'Low');
        insert testTask;

        // Call the method to test
        List<Id> taskIds = TaskController.getTaskIdsByLeadId(testLead.Id);

        // Assert the results
        System.assertEquals(1, taskIds.size());
        System.assertEquals(testTask.Id, taskIds[0]);
    }

    @isTest
    static void testUpdateTaskDescription() {
        // Test data setup
        Task testTask = new Task(Subject = 'Test Task', Description = 'Old Description', Status = 'Not Started');
        insert testTask;

        // Call the method to test
        String nextTaskWhoId = TaskController.updateTaskDescription(testTask.Id, 'New Description', 'In Progress');

        // Assert the results
        Task updatedTask = [SELECT Id, Description, Status FROM Task WHERE Id = :testTask.Id LIMIT 1];
        System.assertEquals('New Description', updatedTask.Description);
        System.assertEquals('In Progress', updatedTask.Status);
        System.assertEquals(testTask.WhoId, nextTaskWhoId); // Assuming the next task has the same WhoId
    }
}