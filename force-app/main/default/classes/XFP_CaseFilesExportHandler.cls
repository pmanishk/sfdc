public class XFP_CaseFilesExportHandler {
    
    public static set<String> exportedCDLs = new Set<String>();
    
    public static void XFP_ExportCaseFiles(List<Case> caseList){
        List<String> caseIds = new List<String>();
        List<String> cdlIds = new List<String>();
        
        for (Case cs: caseList) {
            caseIds.add(cs.Id);
        }
        
        if (!caseIds.IsEmpty()) {
            for(ContentDocumentLink cdl : [SELECT Id, LinkedEntityId, ContentDocumentId
                                           FROM ContentDocumentLink 
                                           WHERE LinkedEntityId IN: caseIds
                                           AND ContentDocument.ContentSize > 200
                                           AND ContentDocument.ContentSize < 6000000 
                                           AND ContentDocument.FileType != 'SNOTE'])
            {
                if (!exportedCDLs.contains(cdl.Id)) {
                    cdlIds.add(cdl.Id);
                }
            }
            
            if (!cdlIds.IsEmpty()) {
                exportedCDLs.addAll(cdlIds);
                if(!Test.isRunningTest()) {
                    XFILES.XfilesExportController.invokeExportBatchJob('Case', cdlIds);
                }  
            }
        }
    }
}