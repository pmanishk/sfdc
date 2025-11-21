trigger XfilesProcessFiles on ContentDocumentLink (after insert) {
    
    Set<String> caseIds = new Set<String>();
    Map<String, List<String>> linkedEntityIdVsContentDocumentId = new Map<String, List<String>>();
    
    for(ContentDocumentLink cdl : trigger.new){
        if(!linkedEntityIdVsContentDocumentId.containsKey(cdl.LinkedEntityId)){
            linkedEntityIdVsContentDocumentId.put(cdl.LinkedEntityId, new List<String>());
        }
        linkedEntityIdVsContentDocumentId.get(cdl.LinkedEntityId).add(cdl.ContentDocumentId);
    }
    
    for(String linkedEntityId :linkedEntityIdVsContentDocumentId.keyset()){
        if(linkedEntityId.startsWith('500')){
            caseIds.add(linkedEntityId);
        }
    }
    
    if(!caseIds.IsEmpty()){
        List<Case> cases = [SELECT Id
                            FROM Case
                            WHERE Id IN: caseIds
                            AND Household_Account__c != null];
        
        XFP_CaseFilesExportHandler.XFP_ExportCaseFiles(cases);
    }
}