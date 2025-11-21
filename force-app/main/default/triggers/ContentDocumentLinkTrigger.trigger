trigger ContentDocumentLinkTrigger on ContentDocumentLink (after insert) {
    if (Trigger.isAfter && Trigger.isInsert) {
        //ContentDocumentLinkTriggerHandler.shareFile(Trigger.new);
        //CaseFilesLinkToHousehold.linkCaseFilesToHousehold(Trigger.new); 
    }
}