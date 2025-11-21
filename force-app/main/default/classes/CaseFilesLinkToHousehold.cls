public  class CaseFilesLinkToHousehold {
    //Update case files owner when houshold is attached based on logged-in user
    public static void linkCaseFilesToHouseholdViaCase(List<Case> cases) {
        Map<Id, Id> caseToHousehold = new Map<Id, Id>();
        for (Case c : cases) {
            if (c.Household_Account__c != null) {
                caseToHousehold.put(c.Id, c.Household_Account__c);
            }
        }
        if (caseToHousehold.isEmpty()) return;
        
        // Query all ContentDocumentLinks linked to these Cases
        List<ContentDocumentLink> caseLinks = [
            SELECT ContentDocumentId, LinkedEntityId
            FROM ContentDocumentLink
            WHERE LinkedEntityId IN :caseToHousehold.keySet()
        ];
        
        Set<Id> docIds = new Set<Id>();
        for (ContentDocumentLink cdl : caseLinks) {
            docIds.add(cdl.ContentDocumentId);
        }
        if (docIds.isEmpty()) return;
        
        // Query ContentDocuments to update the owner
        List<ContentDocument> docsToUpdate = [
            SELECT Id, OwnerId
            FROM ContentDocument
            WHERE Id IN :docIds
        ];
        
        Id newOwnerId = UserInfo.getUserId(); 
        for (ContentDocument doc : docsToUpdate) {
            doc.OwnerId = newOwnerId;
        }
        
        update docsToUpdate;
    }
    public static void linkEmailAttachmentsFilesToCase(List<Case> cases) {
        if (cases == null || cases.isEmpty()) return;
        
        Set<Id> caseIds = new Set<Id>();
        for (Case c : cases) {
            if (c.Household_Account__c != null) {
                caseIds.add(c.Id);
            }
        }
        if (caseIds.isEmpty()) return;
        
        List<EmailMessage> emailMessages = [
            SELECT Id, ParentId
            FROM EmailMessage
            WHERE ParentId IN :caseIds
        ];
        
        if (emailMessages.isEmpty()) return;
        
        Set<Id> emailMessageIds = new Set<Id>();
        Map<Id, Id> emailToCaseMap = new Map<Id, Id>(); // EmailMessage Id to Case Id
        for (EmailMessage em : emailMessages) {
            emailMessageIds.add(em.Id);
            emailToCaseMap.put(em.Id, em.ParentId);
        }
        
        List<ContentDocumentLink> emailMessageAttachments = [
            SELECT ContentDocumentId, LinkedEntityId
            FROM ContentDocumentLink
            WHERE LinkedEntityId IN :emailMessageIds
        ];
        
        if (emailMessageAttachments.isEmpty()) return;
        
        Set<Id> contentDocIds = new Set<Id>();
        for (ContentDocumentLink cdl : emailMessageAttachments) {
            contentDocIds.add(cdl.ContentDocumentId);
        }
        
        List<ContentDocumentLink> existingCaseLinks = [
            SELECT ContentDocumentId, LinkedEntityId
            FROM ContentDocumentLink
            WHERE LinkedEntityId IN :caseIds
            AND ContentDocumentId IN :contentDocIds
        ];
        
        Set<String> existingKeys = new Set<String>();
        for (ContentDocumentLink cdl : existingCaseLinks) {
            existingKeys.add(cdl.ContentDocumentId + '_' + cdl.LinkedEntityId);
        }
        
        List<ContentDocumentLink> newLinks = new List<ContentDocumentLink>();
        Set<Id> newDocIds = new Set<Id>();
        for (ContentDocumentLink cdl : emailMessageAttachments) {
            Id emailId = cdl.LinkedEntityId;
            Id caseId = emailToCaseMap.get(emailId);
            String compoundKey = cdl.ContentDocumentId + '_' + caseId;
            
            if (caseId != null && !existingKeys.contains(compoundKey)) {
                ContentDocumentLink newLink = new ContentDocumentLink(
                    ContentDocumentId = cdl.ContentDocumentId,
                    LinkedEntityId = caseId,
                    ShareType = 'V'   // Viewer access on Case
                );
                newLinks.add(newLink);
                newDocIds.add(cdl.ContentDocumentId);
                existingKeys.add(compoundKey);
            }
        }
        
        if (!newLinks.isEmpty()) {
            List<ContentDocument> docsToUpdate = [SELECT Id, OwnerId FROM ContentDocument WHERE Id IN :newDocIds];
            
            Id newOwnerId = UserInfo.getUserId(); 
            for (ContentDocument doc : docsToUpdate) {
                doc.OwnerId = newOwnerId;
            }
            update docsToUpdate;
            
            insert newLinks;
            
        }
    }
}