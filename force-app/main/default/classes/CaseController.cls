public with sharing class CaseController {

    @AuraEnabled
    public static Map<String, Id> getQueueIdsByNames(String queueNames) {
        Map<String, Id> queueMap = new Map<String, Id>();
    
        // Fetch queue names from the custom label
        List<String> queueNameList = new List<String>();
        for(String queueName : System.label.get('',queueNames).split(';')) {
            queueNameList.add(queueName.trim()); // Trim any extra spaces
        }
        
        // Perform SOQL query
        List<Group> groups = [SELECT Id, Name FROM Group WHERE name IN :queueNameList AND Type = 'Queue'];
        
        // Populate map with queue names and IDs
        for (Group grp : groups) {
            queueMap.put(grp.Name, grp.Id);
        }
        return queueMap;
    }
    
    @AuraEnabled
    public static String createCaseAndLinkFile(Map<String, Object> caseFields, List<Id> fileIds, String lookupField, Id parentRecordId) {
        try{
            // Create a new Case
            Case newCase = new Case();
                    system.debug('caseFields=='+caseFields);
            // Populate Case fields from passed values
            for (String fieldName : caseFields.keySet()) {
                newCase.put(fieldName, caseFields.get(fieldName));
            }

            // Dynamically set the lookup field to link Case to parent record
            if (lookupField != 'case') {
                newCase.put(lookupField, parentRecordId);
            }
            system.debug('newCase=='+newCase);
            insert newCase;
            if (!fileIds.isEmpty()) {
                // Link uploaded files to the new Case using ContentDocumentLink and create FeedItem
                List<ContentDocumentLink> cdlList = new List<ContentDocumentLink>();
                
                for (Id fileId : fileIds) {
                    System.debug('Processing File ID: ' + fileId);
                    ContentDocumentLink cdl = new ContentDocumentLink();
                    cdl.ContentDocumentId = fileId;
                    cdl.LinkedEntityId = newCase.Id; // Ensure newCase is created successfully
                    cdl.ShareType = 'V'; // Viewer access
                    cdlList.add(cdl);
                    if(newcase.AccountId != null){
                        ContentDocumentLink cdlAcc = new ContentDocumentLink();
                        cdlAcc.ContentDocumentId = fileId;
                        cdlAcc.LinkedEntityId = newCase.AccountId;
                        cdlAcc.ShareType = 'V'; // Viewer access
                        cdlList.add(cdlAcc);
                    }
                }
                
                if (!cdlList.isEmpty()) {
                    try {
                        insert cdlList;
                        System.debug('Successfully inserted ContentDocumentLinks');
                    } catch (DmlException e) {
                        System.debug('Error inserting ContentDocumentLink: ' + e.getMessage());
                        // Handle exception as needed
                    }
                }
            
                // Add the uploaded file as a Feed Item to the Case
                List<ContentVersion> contentVersionList = [SELECT Id, ContentDocumentId FROM ContentVersion WHERE ContentDocumentId IN :fileIds];
                Map<Id, Id> cvIdMap = new Map<Id, Id>();
                
                // Log content versions retrieved
                System.debug('Content Versions: ' + contentVersionList);
                
                for (ContentVersion cv : contentVersionList) {
                    cvIdMap.put(cv.ContentDocumentId, cv.Id);
                }
                
                List<FeedItem> feedItemList = new List<FeedItem>();
                for (Id fileId : fileIds) {
                    Id relatedId = cvIdMap.get(fileId);
                    
                    // Check if related record ID is valid
                    if (relatedId == null) {
                        System.debug('No related ContentVersion found for file ID: ' + fileId);
                        continue; // Skip this iteration if there's no related ContentVersion
                    }
                
                    FeedItem feedItem = new FeedItem();
                    feedItem.ParentId = newCase.Id; // Ensure newCase is created successfully
                    feedItem.Body = 'Uploaded file';
                    feedItem.RelatedRecordId = relatedId; // Correct property name is RelatedRecordId
                    feedItemList.add(feedItem);
                }
                
                if (!feedItemList.isEmpty()) {
                    try {
                        insert feedItemList;
                        System.debug('Successfully inserted FeedItems');
                    } catch (DmlException e) {
                        System.debug('Error inserting FeedItems: ' + e.getMessage());
                        // Handle exception as needed
                    }
                }
            }

            return newCase.Id;
        }catch(Exception e){
            System.debug(e);
            return e.getmessage();
        }
        
    }

    @AuraEnabled(cacheable=true)
    public static Map<String, String> getDynamicFieldLabels(String customLabelName) {
        // Fetch the custom label value
        String customLabelValue = System.Label.get('', customLabelName);
        Map<String, String> fieldMap = new Map<String, String>();

        // Parse the custom label to populate field API names and labels
        if (customLabelValue != null) {
            String[] fieldsArray = customLabelValue.split(',');
            for (String field : fieldsArray) {
                String[] parts = field.split(':');
                if (parts.size() == 2) {
                    fieldMap.put(parts[0].trim(), parts[1].trim());
                }
            }
        }
        return fieldMap;
    }

    @AuraEnabled
    public static void deleteUploadedFiles(List<Id> fileIds) {
        if (fileIds == null || fileIds.isEmpty()) {
            return; // No files to delete
        }
        
        List<ContentDocument> documentsToDelete = [SELECT Id FROM ContentDocument WHERE Id IN :fileIds];
        
        if(documentsToDelete.size() > 0){
            delete documentsToDelete; // Delete documents from Salesforce
        }
    }
}