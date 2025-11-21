public class DocusignTemplateHandler2 {
    private static final String DOCUSIGN_ENDPOINT = 'callout:Docusign_API/v2.1/accounts/30407774/envelopes/{envelopeId}/form_data';
    //prod: 10866685
	//30407774
    @future(callout=true)
    public static void processCompletedEnvelope(String envelopeId, String templateName) {
        try {
            HttpRequest req = new HttpRequest();
            req.setEndpoint(DOCUSIGN_ENDPOINT.replace('{envelopeId}', envelopeId));
            req.setMethod('GET');
            req.setHeader('Content-Type', 'application/json');

            Http http = new Http();
            HttpResponse res = http.send(req);

            if (res.getStatusCode() != 200) {
                log('Failed to retrieve envelope form data. Status Code: ' + res.getStatusCode(), 'ERROR');
                log('Response: ' + res.getBody(), 'ERROR');
                return;
            }

            log('Successfully retrieved form data: ' + res.getBody(), 'INFO');

            Map<String, Object> formData = (Map<String, Object>) JSON.deserializeUntyped(res.getBody());
            List<Object> formFields = (List<Object>) formData.get('formData');

            if (formFields == null || formFields.isEmpty()) {
                log('No form fields found in the response.', 'WARN');
                return;
            }

            // Fetch mappings for the template
            Map<String, Map<String, String>> mappings = fetchFieldMappings(templateName);
            if (mappings.isEmpty()) {
                log('No field mappings found for template: ' + templateName, 'WARN');
                return;
            }

            // Process form data
            Map<String, Object> processedFields = processFields(formFields, mappings);

            // Update Financial Account with selected values
            updateFinancialAccount(
                envelopeId,
                (Map<String, String>) processedFields.get('Text'),
                (Map<String, String>) processedFields.get('Picklist'),
                (Map<String, Decimal>) processedFields.get('Numeric') // Includes Number, Currency, Percent
            );
        } catch (Exception e) {
            log('Error in processCompletedEnvelope: ' + e.getMessage(), 'ERROR');
        }
    }

    @TestVisible
    private static Map<String, Map<String, String>> fetchFieldMappings(String templateName) {
        Map<String, Map<String, String>> mappings = new Map<String, Map<String, String>>();
        List<String> fieldTypes = new List<String>{'Text', 'Picklist', 'Number', 'Currency', 'Percent'};

        for (String fieldType : fieldTypes) {
            Map<String, String> fieldMap = new Map<String, String>();
            List<Template_Field_Mapping__mdt> mappingsList = [
                SELECT Field_Identifier__c, Field_API_Name__c 
                FROM Template_Field_Mapping__mdt 
                WHERE Template_Name__c = :templateName AND Field_Type__c = :fieldType
            ];

            if (!mappingsList.isEmpty()) {
                for (Template_Field_Mapping__mdt mappingRecord : mappingsList) {
                    fieldMap.put(mappingRecord.Field_Identifier__c, mappingRecord.Field_API_Name__c);
                }
            }

            mappings.put(fieldType, fieldMap);
        }

        return mappings;
    }
	@TestVisible
    private static Map<String, Object> processFields(List<Object> formFields, Map<String, Map<String, String>> mappings) {
        Map<String, String> textFieldValues = new Map<String, String>();
        Map<String, String> picklistFieldValues = new Map<String, String>();
        Map<String, Decimal> numericFieldValues = new Map<String, Decimal>(); // Consolidates Number, Currency, Percent

        for (Object fieldObj : formFields) {
            Map<String, Object> field = (Map<String, Object>) fieldObj;

            // Validate null field data
            if (field == null || !field.containsKey('name') || !field.containsKey('value')) {
                log('Skipping invalid field with missing name or value.', 'WARN');
                continue;
            }

            String fieldLabel = (String) field.get('name');
            String fieldValue = (String) field.get('value');

            for (String fieldType : mappings.keySet()) {
                Map<String, String> fieldMap = mappings.get(fieldType);

                for (String fieldId : fieldMap.keySet()) {
                    if (fieldLabel.contains(fieldId)) {
                        String fieldApiName = fieldMap.get(fieldId);

                        try {
                            if (fieldType == 'Number' || fieldType == 'Currency' || fieldType == 'Percent') {
                                Decimal convertedValue = Decimal.valueOf(fieldValue);

                                // Percent validation
                                if (fieldType == 'Percent' && (convertedValue < 0 || convertedValue > 100)) {
                                    log('Invalid Percent value for field: ' + fieldApiName, 'WARN');
                                    continue;
                                }

                                numericFieldValues.put(fieldApiName, convertedValue);
                            } else if (fieldType == 'Text') {
                                textFieldValues.put(fieldApiName, fieldValue);
                            } else if (fieldType == 'Picklist') {
                                picklistFieldValues.put(fieldApiName, fieldValue);
                            }
                        } catch (Exception ex) {
                            log('Failed to process field: ' + fieldApiName + '. Error: ' + ex.getMessage(), 'ERROR');
                        }
                    }
                }
            }
        }

        return new Map<String, Object>{
            'Text' => textFieldValues,
            'Picklist' => picklistFieldValues,
            'Numeric' => numericFieldValues
        };
    }

    @testvisible
    private static void updateFinancialAccount(
        String envelopeId, 
        Map<String, String> textFieldValues, 
        Map<String, String> picklistFieldValues,
        Map<String, Decimal> numericFieldValues
    ) {
        List<dfsle__EnvelopeStatus__c> envelopeStatusList = [
            SELECT Id, Financial_Account__c 
            FROM dfsle__EnvelopeStatus__c 
            WHERE dfsle__DocuSignId__c = :envelopeId LIMIT 1
        ];

        if (envelopeStatusList.isEmpty()) {
            log('No Envelope Status found for the given envelope ID', 'WARN');
            return;
        }

        dfsle__EnvelopeStatus__c envelopeStatus = envelopeStatusList[0];
        if (envelopeStatus.Financial_Account__c == null) {
            log('No Financial Account found for the given envelope status', 'WARN');
            return;
        }

        FinServ__FinancialAccount__c financialAccount = [
            SELECT Id FROM FinServ__FinancialAccount__c 
            WHERE Id = :envelopeStatus.Financial_Account__c LIMIT 1
        ];

        updateFields(financialAccount, textFieldValues);
        updateFields(financialAccount, picklistFieldValues);
        updateFields(financialAccount, numericFieldValues);

        update financialAccount;
        log('Updated Financial Account successfully', 'INFO');
    }

    private static void updateFields(SObject record, Map<String, Object> fieldValues) {
        for (String fieldName : fieldValues.keySet()) {
            record.put(fieldName, fieldValues.get(fieldName));
        }
    }

    private static void log(String message, String level) {
        System.debug('[' + level + '] ' + message);
    }
 



    public static Integer simpleIncrementMethod() {
        Integer i = 0;

        for (Integer counter = 0; counter < 10; counter++) {
            i++;
            if (Math.mod(i, 2) == 0) {
                System.debug('Incremented i (even): ' + i);
            } else {
                System.debug('Incremented i (odd): ' + i);
            }
        }

        System.debug('Final value of i in simpleIncrementMethod: ' + i);
        return i; // Return the final value
    }

    public static Integer simpleIncrementMethod1() {
        Integer j = 0;

        for (Integer counter = 0; counter < 10; counter++) {
            j++;
            if (Math.mod(j, 3) == 0) {
                System.debug('Incremented j (multiple of 3): ' + j);
            } else {
                System.debug('Incremented j: ' + j);
            }
        }

        System.debug('Final value of j in simpleIncrementMethod1: ' + j);
        return j; // Return the final value
    }



 
}