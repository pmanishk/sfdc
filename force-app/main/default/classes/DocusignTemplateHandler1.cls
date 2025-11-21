public class DocusignTemplateHandler1 {
    // Replace {envelopeId} dynamically with the actual envelope ID
    private static final String DOCUSIGN_ENDPOINT = 'callout:Docusign_API/v2.1/accounts/30407774/envelopes/{envelopeId}/form_data';
    
    @future(callout=true)
    public static void processCompletedEnvelope(String envelopeId, String templateName) {
        try {
            // Call DocuSign API to get form data
            HttpRequest req = new HttpRequest();
            req.setEndpoint(DOCUSIGN_ENDPOINT.replace('{envelopeId}', envelopeId));
            req.setMethod('GET');
            req.setHeader('Content-Type', 'application/json');
            
            Http http = new Http();
            HttpResponse res = http.send(req);
            
            if (res.getStatusCode() == 200) {
                System.debug('Successfully retrieved form data: ' + res.getBody());
                
                Map<String, Object> formData = (Map<String, Object>) JSON.deserializeUntyped(res.getBody());
                List<Object> formFields = (List<Object>) formData.get('formData');
                
                // Fetch mappings for the template
                Map<String, String> checkboxToFieldMap = getCheckboxMappings(templateName);
                
                // Process form data
                Map<String, List<String>> selectedCheckboxGroups = new Map<String, List<String>>();
                for (Object fieldObj : formFields) {
                    Map<String, Object> field = (Map<String, Object>) fieldObj;
                    String fieldLabel = (String) field.get('name');
                    String fieldValue = (String) field.get('value');
                    
                    for (String checkboxGroupId : checkboxToFieldMap.keySet()) {
                        if (fieldLabel.contains(checkboxGroupId)) {
                            String fieldApiName = checkboxToFieldMap.get(checkboxGroupId);
                            addCheckboxValue(fieldApiName, fieldLabel, fieldValue, selectedCheckboxGroups);
                        }
                    }
                }
                
                // Update Financial Account with selected values
                updateFinancialAccount(envelopeId, selectedCheckboxGroups);
            } else {
                System.debug('Failed to retrieve envelope form data. Status Code: ' + res.getStatusCode());
                System.debug('Response: ' + res.getBody());
            }
        } catch (Exception e) {
            System.debug('Error in processCompletedEnvelope: ' + e.getMessage());
        }
    }
    @testvisible
    private static Map<String, String> getCheckboxMappings(String templateName) {
        Map<String, String> checkboxToFieldMap = new Map<String, String>();
        
        // Query Custom Metadata for the template-specific mappings
        List<Template_Checkbox_Mapping__mdt> mappings = [
            SELECT Checkbox_Group_Identifier__c, Field_API_Name__c 
            FROM Template_Checkbox_Mapping__mdt 
            WHERE Template_Name__c = :templateName
        ];
        
        for (Template_Checkbox_Mapping__mdt mapping : mappings) {
            checkboxToFieldMap.put(mapping.Checkbox_Group_Identifier__c, mapping.Field_API_Name__c);
        }
        
        return checkboxToFieldMap;
    }
    
   /* private static void addCheckboxValue(String fieldName, String fieldLabel, String fieldValue, Map<String, List<String>> selectedCheckboxGroups) {
        if (!selectedCheckboxGroups.containsKey(fieldName)) {
            selectedCheckboxGroups.put(fieldName, new List<String>());
        }
        
        if (!String.isEmpty(fieldValue) && fieldValue.contains('X')) {
            selectedCheckboxGroups.get(fieldName).add(fieldLabel.split('\\|')[0].trim());
        }
    }*/
    
    @testvisible
    private static void addCheckboxValue(String fieldName, String fieldLabel, String fieldValue, Map<String, List<String>> selectedCheckboxGroups) {
    // Ensure the map has a list for the field
    if (!selectedCheckboxGroups.containsKey(fieldName)) {
        selectedCheckboxGroups.put(fieldName, new List<String>());
    }
    
    // Add valid checkbox values to the list
    if (!String.isEmpty(fieldValue) && fieldValue.contains('X')) {
        // Exclude group identifiers from being treated as field labels
        if (!fieldLabel.startsWith('Checkbox Group')) {
            selectedCheckboxGroups.get(fieldName).add(fieldLabel.split('\\|')[0].trim());
        }
    }
}

    @testvisible
    private static void updateFinancialAccount(String envelopeId, Map<String, List<String>> selectedTopics) {
        List<dfsle__EnvelopeStatus__c> envelopeStatusList = [
            SELECT Id, Financial_Account__c 
            FROM dfsle__EnvelopeStatus__c 
            WHERE dfsle__DocuSignId__c = :envelopeId LIMIT 1
        ];
        
        if (envelopeStatusList.isEmpty()) {
            System.debug('No Envelope Status found for the given envelope ID');
            return;
        }
        
        dfsle__EnvelopeStatus__c envelopeStatus = envelopeStatusList[0];
        if (envelopeStatus.Financial_Account__c == null) {
            System.debug('No Financial Account found for the given envelope status');
            return;
        }
        
        FinServ__FinancialAccount__c financialAccount = [
            SELECT Id FROM FinServ__FinancialAccount__c 
            WHERE Id = :envelopeStatus.Financial_Account__c LIMIT 1
        ];
        
        // Update fields with selected values
        for (String fieldName : selectedTopics.keySet()) {
            financialAccount.put(fieldName, String.join(selectedTopics.get(fieldName), ';'));
        }
        
        update financialAccount;
        System.debug('Updated Financial Account with selected topics: ' + selectedTopics);
    }
    
}