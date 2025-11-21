global class CaseFileSharingBatch implements Database.Batchable<SObject> {

    
    global Database.QueryLocator start(Database.BatchableContext BC) {
        return Database.getQueryLocator(
            [SELECT Id  FROM contentdocument where CreatedDate <= TODAY]
        );
    }

    global void execute(Database.BatchableContext BC, List<ContentDocument> cdRecords) {
        List<Id> cdIdSet = new List<Id>();
        for(ContentDocument cd : cdRecords){
            cdIdSet.add(cd.Id);
        }
        List<ContentDocumentLink> cdlRecordsTemp = [SELECT Id, ContentDocumentId, LinkedEntityId FROM ContentDocumentLink WHERE ContentDocumentId IN :cdIdSet Order By ContentDocumentId];
        List<ContentDocumentLink> cdlRecords = New List<ContentDocumentLink>();
        for(ContentDocumentLink cdl : cdlRecordsTemp){
            if(String.valueOf(cdl.LinkedEntityId).startsWith('02s') || String.valueOf(cdl.LinkedEntityId).startsWith('500')){
                cdlRecords.add(cdl);
            }
        }
        Set<Id> contentDocIds = new Set<Id>();
        List<ContentDocumentLink> cdlList = New List<ContentDocumentLink>();
        Map<Id,Set<Id>> cdSetSharedMap = New Map<Id,Set<Id>>();
        List<User> usersWithProfile = [SELECT Id FROM User WHERE IsActive = True AND Profile.Name IN ('Sound Income Operations User', 'Sound Income Trading and Allocation users')];
        for (ContentDocumentLink cdl : cdlRecords) {
            if (cdl != null && cdl.ContentDocumentId != null && cdl.LinkedEntityId != null) {
                contentDocIds.add(cdl.ContentDocumentId);
            }
            
        }
        
        for(ContentDocumentLink cdl : [SELECT LinkedEntityId,LinkedEntity.Name, ContentDocumentId FROM ContentDocumentLink WHERE ContentDocumentId IN:contentDocIds]){
            if(!cdSetSharedMap.containsKey(cdl.ContentDocumentId)){
                cdSetSharedMap.put(cdl.ContentDocumentId, New Set<Id>());
            }
            cdSetSharedMap.get(cdl.ContentDocumentId).add(cdl.LinkedEntityId);
        }

        
        for(ContentDocumentLink cdl : cdlRecords){
            for(user u : usersWithProfile){
                if(cdSetSharedMap.containsKey(cdl.ContentDocumentId) && !cdSetSharedMap.get(cdl.ContentDocumentId).contains(u.Id)){
                    ContentDocumentLink cdlVar = new ContentDocumentLink(ContentDocumentId = cdl.ContentDocumentId , LinkedEntityId = u.Id, ShareType = 'C', Visibility = 'AllUsers');
                    cdSetSharedMap.get(cdl.ContentDocumentId).add(u.Id);
                    cdlList.add(cdlVar);
                }
            }
        }
        system.debug('cdlList=='+cdlList);
        if(cdlList.size() > 0){
            Insert cdlList;
        }
      
    }

    global void finish(Database.BatchableContext BC) {
        System.debug('Batch completed successfully.');
    }
}