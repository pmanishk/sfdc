global class DeleteFilesLinkedToAccountsBatch implements Database.Batchable<SObject> {

    global Database.QueryLocator start(Database.BatchableContext bc) {
        // Only query Account records — as per your requirement
        return Database.getQueryLocator([SELECT Id FROM Account Where Recordtype.DeveloperName = 'IndustriesHousehold' AND Id ='001Dn0000054bhVIAQ']);
    }

    global void execute(Database.BatchableContext bc, List<Account> acctList) {
        Map<Id,Account> acctMap = New Map<Id,Account>( acctList);
        Set<Id> contentDocIds = new Set<Id>();

        // Find related ContentDocumentLinks
        List<ContentDocumentLink> docLinks = [ SELECT ContentDocumentId FROM ContentDocumentLink WHERE LinkedEntityId IN :acctMap.Keyset()];

        for (ContentDocumentLink link : docLinks) {
            contentDocIds.add(link.ContentDocumentId);
        }
        
        List<ContentDocument> docsToDelete = [SELECT Id FROM ContentDocument WHERE Id IN :contentDocIds];
        
        if (!docsToDelete.isEmpty()){
            delete docsToDelete;
        }
    }

    global void finish(Database.BatchableContext bc) {
        System.debug('Finished deleting files related to Account records.');
    }
}