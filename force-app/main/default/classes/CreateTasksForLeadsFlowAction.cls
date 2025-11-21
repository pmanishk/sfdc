public class CreateTasksForLeadsFlowAction {
    public Static Integer taskCreated;
    public Static Integer existingCallTask;
    public Static Integer existingEmailTask;
    
    public class InputWrapper {
        @InvocableVariable(label='Campaign ID' required=true)
        public String campaignId;
        
        @InvocableVariable(label='Type' required=true)
        public String type;
        
        @InvocableVariable(label='Due Date' required=true)
        public Date dueDate;
        
        @InvocableVariable(label='Subject' required=true)
        public String subject;
        
        @InvocableVariable(label='Count' required=true)
        public Integer count;
    }
    
    public class OutputWrapper {
        @InvocableVariable(label='Success' required=true)
        public Boolean isSuccess;
        @InvocableVariable(label='Lead ID' required=true)
        public String leadId;
        @InvocableVariable(label='Actual Count' required=true)
        public Integer actualCount;
        @InvocableVariable(label='Task for email' required=true)
        public Integer emailCount;
        @InvocableVariable(label='Task for Call' required=true)
        public Integer callCount;
    }
    
    @InvocableMethod(label='Create Tasks for Leads')
    public static List<OutputWrapper> createTasksForLeads(List<InputWrapper> inputWrappers) {
        List<OutputWrapper> outputWrappers = new List<OutputWrapper>();
        
        for (InputWrapper inputWrapper : inputWrappers) {
            OutputWrapper outputWrapper = new OutputWrapper();
            
            // Call the method to create tasks for leads
            outputWrapper.leadId = createTasksForLeads(inputWrapper.campaignId, inputWrapper.type, inputWrapper.dueDate, inputWrapper.subject, inputWrapper.count);
            if(outputWrapper.leadId == null){
                List<CampaignMember> cm = [Select ID, Task_Type__c, LeadId From CampaignMember Where Lead_Last_Contacted__c = null AND Bulk_Task_Created__c = TRUE AND Lead.OwnerId = :UserInfo.getUserId() AND CampaignId = :inputWrapper.campaignId];
                if(cm.size()>0){
                    outputWrapper.leadId = cm[0].LeadId;
                }
            }
            outputWrapper.isSuccess = (outputWrapper.leadId != null);
            outputWrapper.actualCount = taskCreated;
            outputWrapper.emailCount = existingEmailTask;
            outputWrapper.callCount = existingCallTask;
            outputWrappers.add(outputWrapper);
        }
        
        return outputWrappers;
    }
    
    public static String createTasksForLeads(String campaignId, String type, Date dueDate, String subject, Integer count) {
        Integer actualCount = getActualCount(campaignId, type, count);
        String selectedLeadId;
        updateExistingTaskSubjects(subject, campaignId, dueDate);
        System.debug('@@@@'+actualCount);
        System.debug('@@@@type'+type);
        //if condition for the actualcount should be here
        if(actualCount > 0){
            List<Lead> leads = [SELECT Id, OwnerId FROM Lead WHERE OwnerId = :UserInfo.getUserId() AND Id IN (
                SELECT LeadId FROM CampaignMember WHERE CampaignId = :campaignId
            ) LIMIT :actualCount];
            
            System.debug('@@@leadsize'+leads.size());
            
            List<Task> tasksToInsert = new List<Task>();
            Map<String, CampaignMember> leadIdToCampaignMemberMap = new Map<String, CampaignMember>();
            
            if (!leads.isEmpty()) { // You can change this to leads[leads.size() - 1].Id; if you want the last lead ID
                Set<String> existingTaskSubjects = new Set<String>();
                for (CampaignMember cm : [SELECT Id, LeadId, Bulk_Task_Created__c,Task_Type__c  FROM CampaignMember WHERE CampaignId = :campaignId]) {
                    leadIdToCampaignMemberMap.put(cm.LeadId, cm);
                }
                
                List<CampaignMember> campaignMembersToUpdate = new List<CampaignMember>();
                
                for (Task existingTask : [SELECT Subject FROM Task WHERE WhoId IN :leads]) {
                    String recordIdWithoutPrefix = existingTask.subject.substringAfter('701');
                    String recordId = '701' + recordIdWithoutPrefix;
                    existingTaskSubjects.add(recordId);
                }
                System.debug('@@@@existingTaskSubjects'+existingTaskSubjects);
                
                for (Lead lead : leads) {
                    String taskSubject = subject + ' ' + campaignId;
                    System.debug('@@@leadsinside'+taskSubject);
                    if (!existingTaskSubjects.contains(campaignId)) {
                        System.debug('Inside major If');
                        Task newTask = new Task();
                        newTask.Subject = taskSubject;
                        newTask.Description = 'Bulk task';
                        newTask.WhoId = lead.Id;
                        newTask.Status = 'Not Started';
                        newTask.Priority = 'Low';
                        newTask.Type = type;
                        newTask.ActivityDate = dueDate;
                        newTask.OwnerId = UserInfo.getUserId();
                        System.debug('@@@new Task'+newTask);
                        selectedLeadId = lead.Id;
                        tasksToInsert.add(newTask);          
                    } 
                    System.debug('@@@tasksToInsert'+tasksToInsert.size());
                    CampaignMember cm = leadIdToCampaignMemberMap.get(lead.Id);
                    System.debug('@@cm'+cm);
                    if (cm != null) {
                        cm.Bulk_Task_Created__c =  TRUE;
                        cm.Task_Type__c = type;
                        campaignMembersToUpdate.add(cm);
                    }System.debug('@@@campaignMembersToUpdatecampaignMembersToUpdate'+campaignMembersToUpdate.size());
                }
                
                if (!tasksToInsert.isEmpty()) {
                    insert tasksToInsert;
                    
                    if (!campaignMembersToUpdate.isEmpty()) {
                        update campaignMembersToUpdate;
                    }
                    return selectedLeadId;
                }
            }
        }
        return null;
    }
    
    public static void updateExistingTaskSubjects(String subject, String campaignId, Date dueDate){
        List<Lead> notContactedLead = new List<Lead>();
        List<Task> existingTaskList = new List<Task>();
        List<Task> taskToUpdate = new List<Task>();
        notContactedLead =  [SELECT Id, OwnerId FROM Lead WHERE OwnerId = :UserInfo.getUserId() AND Id IN (SELECT LeadId FROM CampaignMember WHERE Lead_Last_Contacted__c = null AND Bulk_Task_Created__c = TRUE AND CampaignId = :campaignId)];
        existingTaskList = [SELECT Id, Subject, ActivityDate FROM Task WHERE WhoId IN :notContactedLead];
        for(Task tsk : existingTaskList){
            tsk.Subject = subject + ' ' + campaignId;
            tsk.ActivityDate = dueDate;
            taskToUpdate.add(tsk);
        }
         database.update(taskToUpdate);
    }
    
    public static Integer getActualCount(String campaignId, String type, Integer count){
        List<CampaignMember> cm = [Select Id From CampaignMember Where Lead.OwnerId = :UserInfo.getUserId() AND CampaignId = :campaignId];
        List<CampaignMember> totalBlkTask = [Select Id From CampaignMember Where Bulk_Task_Created__c = TRUE AND Lead.OwnerId = :UserInfo.getUserId() AND CampaignId = :campaignId];
        Integer totalSize = cm.size();
        Integer actualCount = 0;
        Integer existingCount;
        Integer existingEmailCount = getExistingEmailCount(campaignId);
        Integer existingCallCount = getExistingCallCount(campaignId);
        System.debug('@@@existingEmailCount'+existingEmailCount);
        System.debug('@@@existingCallCount'+existingCallCount);
        System.debug('@@@@@@@@@@@type '+type);
        if (type.contains('Call')){
            System.debug('inside call');
            existingCount = existingCallCount;
        }
        if (type.contains('Email')){
            System.debug('inside email');
            System.debug('@@@@@@1'+existingCount);
            existingCount = existingEmailCount;
            System.debug('@@@@@@2'+existingCount);
        }
        System.debug('@@@@@@'+existingCount);
        if((existingCount > count || existingCount == count) && existingCount != totalSize){
            if((50 - existingCount) > count){
                actualCount = count;
            }else{
                actualCount = count - (50 - existingCount - count);
            }  
        }
        if(existingCount < count && (count < 50 || count == 50) && existingCount != totalSize){
            If(existingCount == 0){
                actualCount = count;
            }else{    
                actualCount = count - existingCount; 
            }
        }
        if(totalBlkTask.size() == totalSize){
            actualCount = 0;
        }
        
        System.debug('@@@actualcount'+actualCount);
        taskCreated = actualCount;
        existingCallTask = existingCallCount;
        existingEmailTask = existingEmailCount;
        return actualCount;
    }
    
    public static Integer getExistingEmailCount(String campaignId){
        List<CampaignMember> cmNotContacted = [Select ID, Task_Type__c From CampaignMember Where Lead_Last_Contacted__c = null AND Bulk_Task_Created__c = TRUE AND Task_Type__c = 'Outbound Email' AND Lead.OwnerId = :UserInfo.getUserId() AND CampaignId = :campaignId]; 
        System.debug('@@@size'+cmNotContacted.size());
        return cmNotContacted.size();
    }
    
    public static Integer getExistingCallCount(String campaignId){
        List<CampaignMember> cmNotContacted = [Select ID, Task_Type__c From CampaignMember Where Lead_Last_Contacted__c = null AND Bulk_Task_Created__c = TRUE AND Task_Type__c = 'Call' AND Lead.OwnerId = :UserInfo.getUserId() AND CampaignId = :campaignId]; 
        System.debug('@@@size'+cmNotContacted.size());
        return cmNotContacted.size();
    }
    
}