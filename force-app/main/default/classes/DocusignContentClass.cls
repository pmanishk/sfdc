public class DocusignContentClass {
     public static void createContentDocumentLinks(List<dfsle__EnvelopeStatus__c> updatedEnvelopeStatuses) {
        // Filter only completed DocuSign status records
        List<dfsle__EnvelopeStatus__c> completedEnvStatus = [SELECT Id, DocuSign_Envelope_Record__c 
                                                             FROM dfsle__EnvelopeStatus__c 
                                                             WHERE Id IN :updatedEnvelopeStatuses 
                                                             AND dfsle__Status__c = 'Completed' 
                                                             AND DocuSign_Envelope_Record__c != null];

        // Create ContentDocumentLinks for completed envelopes
        List<ContentDocumentLink> contentDocumentLinks = new List<ContentDocumentLink>();
        for (dfsle__EnvelopeStatus__c envStatus : completedEnvStatus) {
            // Get the related Envelope record
            dfsle__Envelope__c envelope = [SELECT Id, dfsle__DocuSignId__c, Related_Account__c 
                                           FROM dfsle__Envelope__c 
                                           WHERE Id = :envStatus.DocuSign_Envelope_Record__c LIMIT 1];
            system.debug('envelope details'+envelope);
            // Create the title based on the dfsle__DocuSignId__c
            String title = 'Envelope_' + envelope.dfsle__DocuSignId__c + '.pdf';

            // Query the ContentDocument based on the title
            List<ContentDocument> contentDocuments = [SELECT Id, Title, FileExtension, FileType 
                                                      FROM ContentDocument 
                                                      WHERE Title = :title 
                                                      LIMIT 1];

            // If the ContentDocument exists, create a ContentDocumentLink
            if (!contentDocuments.isEmpty()) {
                ContentDocument contentDocument = contentDocuments[0];
                
                // Check if a ContentDocumentLink already exists for this document and entity
                List<ContentDocumentLink> existingLinks = [SELECT Id 
                                                           FROM ContentDocumentLink 
                                                           WHERE LinkedEntityId = :envelope.Related_Account__c 
                                                           AND ContentDocumentId = :contentDocument.Id 
                                                           LIMIT 1];
                if (existingLinks.isEmpty()) {
                    // Create a new ContentDocumentLink
                    ContentDocumentLink contentDocumentLink = new ContentDocumentLink();
                    contentDocumentLink.LinkedEntityId = envelope.Related_Account__c;  // Link to the related Account
                    contentDocumentLink.ContentDocumentId = contentDocument.Id;  // Link to the Content Document
                    contentDocumentLink.ShareType = 'V';  // Viewer permission
                    contentDocumentLink.Visibility = 'AllUsers';  // Set visibility

                    // Add to list of ContentDocumentLinks to insert later
                    contentDocumentLinks.add(contentDocumentLink);
                }
            }
        }

        // Insert the ContentDocumentLinks if there are any to insert
        if (!contentDocumentLinks.isEmpty()) {
            insert contentDocumentLinks;
        }
    }
    

    // Method to link DocuSign Envelope with Financial Account's Primary Owner
    public static void linkDocuSignToFinancialAccount(List<dfsle__EnvelopeStatus__c> newEnvelopeStatuses) {
        // Set to store the Financial_Account__c IDs to query the primary owners
        Set<Id> financialAccountIds = new Set<Id>();
        Map<Id, Id> envelopeToFinancialAccountMap = new Map<Id, Id>(); // Map to store envelope IDs and corresponding financial accounts

        // Loop through EnvelopeStatus records to collect Financial Account IDs
        for (dfsle__EnvelopeStatus__c envStatus : newEnvelopeStatuses) {
            if (envStatus.DocuSign_Envelope_Record__c != null && envStatus.Financial_Account__c != null) {
                // Collect the Financial_Account__c and map it to the Envelope's DocuSign_Envelope_Record__c
                financialAccountIds.add(envStatus.Financial_Account__c);
                envelopeToFinancialAccountMap.put(envStatus.DocuSign_Envelope_Record__c, envStatus.Financial_Account__c);
            }
        }

        // Query the Financial Account records and get their Primary Owners
        Map<Id, FinServ__FinancialAccount__c> financialAccounts = new Map<Id, FinServ__FinancialAccount__c>([
            SELECT Id, FinServ__PrimaryOwner__c, FinServ__Household__c 
            FROM FinServ__FinancialAccount__c 
            WHERE Id IN :financialAccountIds
        ]);

        // Query related Envelope records using the envelopeToFinancialAccountMap
        Map<Id, dfsle__Envelope__c> envelopeRecords = new Map<Id, dfsle__Envelope__c>([
            SELECT Id, dfsle__DocuSignId__c, Related_Account__c 
            FROM dfsle__Envelope__c 
            WHERE Id IN :envelopeToFinancialAccountMap.keySet()
        ]);

        // Update EnvelopeStatus and Envelope records
        for (dfsle__EnvelopeStatus__c envStatus : newEnvelopeStatuses) {
            // Get the Financial Account ID from the map
            Id financialAccountId = envelopeToFinancialAccountMap.get(envStatus.DocuSign_Envelope_Record__c);

            if (financialAccountId != null && financialAccounts.containsKey(financialAccountId)) {
                // Get the Financial Account's Household
                Id householdAccount = financialAccounts.get(financialAccountId).FinServ__Household__c;

                // Update EnvelopeStatus's dfsle__Account__c field with the Household Account
                envStatus.dfsle__Account__c = householdAccount;

                // Get the related Envelope record and update its Related_Account__c field
                dfsle__Envelope__c envelope = envelopeRecords.get(envStatus.DocuSign_Envelope_Record__c);
                if (envelope != null) {
                    envelope.Related_Account__c = householdAccount; // Set the Household Account in the related envelope
                }
            }
        }

        // Update envelopes if changes were made
        if (!envelopeRecords.isEmpty()) {
            update envelopeRecords.values(); // Updating all changed envelope records
        }
    }
    
    public static void DocusignMethod(){
    Integer i = 0;
    i++;
    //repeat the i++ hundred of times

   }

}