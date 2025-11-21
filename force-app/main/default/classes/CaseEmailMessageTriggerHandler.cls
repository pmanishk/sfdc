public class CaseEmailMessageTriggerHandler {
    public static void process(List<EmailMessage> emails) {
        // Safe way to query Profile
        List<Profile> profiles = [SELECT Name FROM Profile WHERE Id = :UserInfo.getProfileId()];
        if (profiles.isEmpty() || profiles[0].Name != 'Primary Agent') return;
        
        Set<Id> caseIds = new Set<Id>();
        for (EmailMessage em : emails)
            if (em.ParentId != null && em.ParentId.getSObjectType() == Case.SObjectType)
                caseIds.add(em.ParentId);
        
        if (caseIds.isEmpty()) return;
        
        // Already safe: query into a list
        List<Case> casesToUpdate = [
            SELECT Id FROM Case WHERE Id IN :caseIds AND IsClosed = false
        ];
        
        for (Case c : casesToUpdate)
            //c.Status = 'Customer Responded';
            c.Override_Status__c = 'Customer Responded';
        
        if (!casesToUpdate.isEmpty())
            update casesToUpdate;
    }  
    
}