trigger XFPProcessCaseFiles on Case (after update) {
    Map<Id,String> contentDocumentIdVsLinkId = new Map<Id,String>();
    Map<String,List<String>> objNameVsIdMap = new Map<String,List<String>>();
    Map<String,String> keyPrefixVsObjNameMap = new Map<String,String>{'500'=>'Case'};
   	Map<String, List<String>> accvscdl = new Map<String, List<String>>(); 
    List<Id> caseList= new List<Id>(); 
    
    String householdrectype = [SELECT Id FROM RecordType WHERE SobjectType = 'Account' AND Name = 'Household'].Id;
    
    for(Case cs: Trigger.new){
        Case oldcs = Trigger.oldMap.get(cs.Id);
        if(cs.Household_Account__c  != NULL && oldcs.Household_Account__c  == NULL){
            caseList.add(cs.Id);  
        }
    }
    
    if(caseList.size()>0){
        for(ContentDocumentLink cdl : [SELECT Id, LinkedEntityId, ContentDocumentId from ContentDocumentLink where LinkedEntityId IN: caseList]){
            contentDocumentIdVsLinkId.put(cdl.ContentDocumentId,cdl.LinkedEntityId);
        }
    }
    
    Set<Id> contentDocumentIdSet = contentDocumentIdVsLinkId.keySet();
    
    if(contentDocumentIdSet.size()>0){
        for(ContentDocumentLink cdl :[SELECT Id, LinkedEntityId, ContentDocumentId
                                      FROM ContentDocumentLink
                                      WHERE ContentDocumentId IN: contentDocumentIdSet])
        {
            if(String.ValueOf(cdl.LinkedEntityId).startswith('001')) {
                if(!accvscdl.containsKey(cdl.LinkedEntityId) ){
                    accvscdl.put(cdl.LinkedEntityId,new List<String>());
                }
                accvscdl.get(cdl.LinkedEntityId).add(cdl.ContentDocumentId);           
            }
        }
    }
    Set<String> accl = accvscdl.keyset();
    if(accl.size()>0){
    for(Account acc: [SELECT Id, RecordTypeId from Account where Id IN: accl]){
        if(acc.RecordTypeId != householdrectype){
            accvscdl.remove(acc.Id);
        }
    }
    }
    
    List<Id> contentDocumentIds = new List<Id>();
    
    for(Id accId : accvscdl.keyset()){
        contentDocumentIds.addAll(accvscdl.get(accId));
    }
    if(!contentDocumentIds.isEmpty()){
        for(ContentDocumentLink cdl :[SELECT Id, ContentDocumentId, LinkedEntityId, ContentDocument.ContentSize, ContentDocument.FileType
                                      FROM ContentDocumentLink
                                      WHERE ContentDocumentId IN :contentDocumentIds])
        {
            String objPrefix = String.valueOf(cdl.LinkedEntityId).substring(0,3);
            if(!keyPrefixVsObjNameMap.containsKey(objPrefix)
               || cdl.ContentDocument.ContentSize <= 200
               || cdl.ContentDocument.FileType == 'SNOTE'
               || cdl.ContentDocument.ContentSize > 6000000) 
            {
                continue;
            }
            
            if(!objNameVsIdMap.containsKey(keyPrefixVsObjNameMap.get(objPrefix)) ){
                objNameVsIdMap.put(keyPrefixVsObjNameMap.get(objPrefix),new List<String>());
            }
            objNameVsIdMap.get(keyPrefixVsObjNameMap.get(objPrefix)).add(cdl.Id);
        }
        
        if(!objNameVsIdMap.isEmpty()){
            
            for(String objName :objNameVsIdMap.keySet()){
                
                if(String.isNotBlank(objName)){
                    XFILES.XfilesExportController.ExportParams exportParams = new XFILES.XfilesExportController.ExportParams();
                    exportParams.objectName = objName;
                    exportParams.fileOrAttIdsList = objNameVsIdMap.get(objName);
                    exportParams.replaceFiles = true;
                    if(!Test.isRunningTest()) {
                        XFILES.XfilesExportController.invokeExportBatchJob(exportParams);
                    }
                }
            }
        }
    }
}