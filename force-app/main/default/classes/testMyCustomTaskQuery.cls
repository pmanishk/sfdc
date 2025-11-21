@isTest
public class testMyCustomTaskQuery {
   public static testMethod void testMyController() {        
        Task tsk = new Task(Subject = 'Test');
        insert tsk;
        
        ApexPages.currentPage().getParameters().put('id', tsk.id);
        ApexPages.StandardController sc = new ApexPages.StandardController(tsk);
        myCustomTaskQuery mctq = new myCustomTaskQuery(sc);
        mctq.getMyTask();
    }
}