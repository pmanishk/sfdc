trigger TriggerCreateContent on dfsle__EnvelopeStatus__c (after update) {
    DocusignContentClass.createContentDocumentLinks(Trigger.New);
    //Old process for reason for liquidation,financial planning
    for (dfsle__EnvelopeStatus__c envelopeStatus : Trigger.new) {
        
        // Check if the status is completed and the status has changed
        if (envelopeStatus.dfsle__Status__c == 'Completed' &&
            Trigger.oldMap.get(envelopeStatus.Id).dfsle__Status__c != 'Completed' ) {
           // && envelopeStatus.DocuSign_Envelope_Record__r.Envelope_Name__c == 'Liquidation Request Test 1'
            
            // Call the future method to handle the callout for each envelope
            DocusignApiClass1.processCompletedEnvelope(envelopeStatus.dfsle__DocuSignId__c);
            DocusignApiClass2.processCompletedEnvelope1(envelopeStatus.dfsle__DocuSignId__c);
        }
    }
    
    //New process with Metadata handle with multipicklist,text,picklist
    // Map to store envelope IDs and template names
    Map<String, String> envelopeIdToTemplateMap = new Map<String, String>();
    
    // Collect envelope IDs where status changed to 'Completed'
    Set<Id> parentEnvelopeIds = new Set<Id>();
    for (dfsle__EnvelopeStatus__c envelopeStatus : Trigger.new) {
        if (envelopeStatus.dfsle__Status__c == 'Completed' &&
            Trigger.oldMap.get(envelopeStatus.Id).dfsle__Status__c != 'Completed') {
            if (envelopeStatus.DocuSign_Envelope_Record__c != null) {
                parentEnvelopeIds.add(envelopeStatus.DocuSign_Envelope_Record__c);
            }
        }
    }
    
    // Query parent envelope records to get the template name
    Map<Id, dfsle__Envelope__c> parentEnvelopes = new Map<Id, dfsle__Envelope__c>(
        [SELECT Id, dfsle__DocuSignId__c ,Envelope_Name__c
         FROM dfsle__Envelope__c 
         WHERE Id IN :parentEnvelopeIds]
    );
    
    // Build the map of envelope ID to template name
    for (dfsle__EnvelopeStatus__c envelopeStatus : Trigger.new) {
        if (envelopeStatus.dfsle__Status__c == 'Completed' &&
            Trigger.oldMap.get(envelopeStatus.Id).dfsle__Status__c != 'Completed') {
            
            dfsle__Envelope__c parentEnvelope = parentEnvelopes.get(envelopeStatus.DocuSign_Envelope_Record__c);
            if (parentEnvelope != null && parentEnvelope.dfsle__DocuSignId__c != null && parentEnvelope.Envelope_Name__c != null) {
                envelopeIdToTemplateMap.put(parentEnvelope.dfsle__DocuSignId__c, parentEnvelope.Envelope_Name__c);
            }
        }
    }
    
    // Call the future method for each envelope ID and template name
    for (String envelopeId : envelopeIdToTemplateMap.keySet()) {
        String templateName = envelopeIdToTemplateMap.get(envelopeId);
        DocusignTemplateHandler1.processCompletedEnvelope(envelopeId, templateName);
        DocusignTemplateHandler2.processCompletedEnvelope(envelopeId, templateName);
    }
    
    //***********************Cancel Envelopes Trigger logic************************
    List<dfsle__EnvelopeStatus__c> statusesToCancel = new List<dfsle__EnvelopeStatus__c>();

    // Collect records where the related Cancel_Envelope__c checkbox is checked and was not previously checked
    for (dfsle__EnvelopeStatus__c status : Trigger.new) {
        dfsle__EnvelopeStatus__c oldStatus = Trigger.oldMap.get(status.Id);
        if(status.dfsle__Status__c != 'Completed'){
        // Ensure the related Cancel_Envelope__c is checked and was previously unchecked
        if (status.Cancel_Envelope__c == true &&
            oldStatus.Cancel_Envelope__c == false) {
            statusesToCancel.add(status);
        }
      }
    }

    // Perform the DocuSign voiding for the collected statuses
    if (!statusesToCancel.isEmpty()) {
        for (dfsle__EnvelopeStatus__c status : statusesToCancel) {
            try {
                String envelopeId = status.dfsle__DocuSignId__c; // Envelope ID from the related record

                if (String.isNotBlank(envelopeId)) {
                    DocuSignEnvelopeService.voidEnvelope(envelopeId);
                } else {
                    System.debug('Missing Envelope ID for status: ' + status.Id);
                }
            } catch (Exception ex) {
                System.debug('Error voiding envelope for status ID ' + status.Id + ': ' + ex.getMessage());
            }
        }
    }
}