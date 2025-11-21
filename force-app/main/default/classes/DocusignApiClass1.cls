public class DocusignApiClass1 {

    // Define the Named Credential as an endpoint for retrieving envelope status and tab information
    private static final String DOCUSIGN_ENDPOINT = 'callout:Docusign_API/v2.1/accounts/10866685/envelopes/{envelopeId}/form_data';

    // Future method to perform the callout after DML operations
    @future(callout=true)
    public static void processCompletedEnvelope(String envelopeId) {
        // Labels for 30407774 - docusignaccount, Checkbox Group a3f4e10a-9420-4360-94c0-8786e4a3ca95
        /*Prod Account id: 10866685
        **Checkbox Group: Checkbox Group 15bf6015-d065-4aa6-aa76-5f3ac24c6ef2
        checkbox values: doesnt matter
        **data labels:
        Checkbox b8637fb0-6bb6-4dc9-9224-2a55eb1426c0
        Checkbox 6b555b5e-0abb-4156-a50f-1eecdf1bbf74
        Checkbox a08850db-b455-4ad5-9a6c-fc72e5a31e50
        Checkbox ab0768c2-b18e-4eaa-b0ae-84f2b156840e
        Checkbox 66fd70a4-b7f1-4531-bf61-9b4c9a2cf73c*/
        try {
            // Construct the HTTP request
            HttpRequest req = new HttpRequest();
            req.setEndpoint(DOCUSIGN_ENDPOINT.replace('{envelopeId}', envelopeId)); // Insert envelopeId dynamically
            req.setMethod('GET');
            req.setHeader('Content-Type', 'application/json');

            // Send the HTTP request to get envelope form data
            Http http = new Http();
            HttpResponse res = http.send(req);

            // Handle the response
            if (res.getStatusCode() == 200) {
                System.debug('Successfully retrieved form data: ' + res.getBody());

                // Parse the JSON response body
                Map<String, Object> formData = (Map<String, Object>) JSON.deserializeUntyped(res.getBody());

                // Initialize checkbox values and reason for liquidation field
                List<String> selectedCheckboxValues = new List<String>();
                String reasonForLiquidation = '';

                // Extract checkbox and reason for liquidation values from the form data
                List<Object> formFields = (List<Object>) formData.get('formData');
                for (Object fieldObj : formFields) {
                    Map<String, Object> field = (Map<String, Object>) fieldObj;
                    String fieldLabel = (String) field.get('name');
                    String fieldValue = (String) field.get('value');

                    // Extract checkbox group values
                    if (fieldLabel.contains('Checkbox Group 15bf6015-d065-4aa6-aa76-5f3ac24c6ef2')) {
                        String[] checkboxValues = fieldValue.split(';');
                        for (String checkbox : checkboxValues) {
                            String[] parts = checkbox.split(':');
                            if (parts.size() == 2 && parts[1] == 'X') {
                                // Add relevant test values to the selectedCheckboxValues list based on checkbox group
                                if (parts[0] == 'Checkbox b8637fb0-6bb6-4dc9-9224-2a55eb1426c0') selectedCheckboxValues.add('Client Request');
                                if (parts[0] == 'Checkbox 6b555b5e-0abb-4156-a50f-1eecdf1bbf74') selectedCheckboxValues.add('One Time Distribution/Withdrawal');
                                if (parts[0] == 'Checkbox a08850db-b455-4ad5-9a6c-fc72e5a31e50') selectedCheckboxValues.add('Systematic Withdrawal per month');
                                if (parts[0] == 'Checkbox ab0768c2-b18e-4eaa-b0ae-84f2b156840e') selectedCheckboxValues.add('Hold Cash');
                                if (parts[0] == 'Checkbox 66fd70a4-b7f1-4531-bf61-9b4c9a2cf73c') selectedCheckboxValues.add('Other');
                            }
                        }
                    }
                }

                // Log checkbox values and reason for liquidation for debugging
                System.debug('Selected Checkbox Values: ' + selectedCheckboxValues);
                System.debug('Reason for Liquidation: ' + reasonForLiquidation);

                // Join selected checkbox values into a semicolon-separated string for the multi-picklist format
                String updatedPicklist = String.join(selectedCheckboxValues, ';');
                System.debug('Updated Picklist Values: ' + updatedPicklist);

                // Query the Envelope Status to get the associated Financial Account
                List<dfsle__EnvelopeStatus__c> envelopeStatusList = [
                    SELECT Id, Financial_Account__c,DocuSign_Envelope_Record__r.Envelope_Name__c
                    FROM dfsle__EnvelopeStatus__c 
                    WHERE dfsle__DocuSignId__c = :envelopeId AND DocuSign_Envelope_Record__r.Envelope_Name__c = 'Liquidation Request'
                    LIMIT 1
                ];
                //DocuSign_Envelope_Record__r.Envelope_Name__c == 'Liquidation Request Test 1'

                if (envelopeStatusList.isEmpty()) {
                    System.debug('No Envelope Status found for the given envelope ID');
                    return;
                }

                dfsle__EnvelopeStatus__c envelopeStatus = envelopeStatusList[0];
                System.debug('Envelope Status ID: ' + envelopeStatus.Id);

                // Ensure the Financial Account is linked to the Envelope Status
                if (envelopeStatus.Financial_Account__c  == null) {
                    System.debug('No Financial Account found for the given envelope status');
                    return;
                }

                // Query and update the Financial Account with the selected picklist values and Reason for Liquidation
                FinServ__FinancialAccount__c financialAccount = [
                    SELECT Id, Reason_for_Liquidation_test__c
                    FROM FinServ__FinancialAccount__c 
                    WHERE Id = :envelopeStatus.Financial_Account__c 
                    LIMIT 1
                ];

                System.debug('Financial Account ID: ' + financialAccount.Id);

                // Update multi-picklist field Reason_for_Liquidation_test__c
                financialAccount.Reason_for_Liquidation_test__c = updatedPicklist;

                // Update the financial account record in Salesforce
                update financialAccount;

                System.debug('Updated Financial Account with new Reason for Liquidation (Picklist): ' + updatedPicklist);

                // Update the Reason_for_Liquidation__c field on the EnvelopeStatus object with the same value
                //envelopeStatus.Reason_for_Liquidation__c = updatedPicklist;  // Setting to same value as multi-picklist
                //update envelopeStatus;

                //System.debug('Updated EnvelopeStatus with Reason for Liquidation: ' + updatedPicklist);

            } else {
                System.debug('Failed to retrieve envelope form data. Status Code: ' + res.getStatusCode());
                System.debug('Response: ' + res.getBody());
            }

        } catch (Exception e) {
            System.debug('Error in processCompletedEnvelope: ' + e.getMessage());
        }
    }
}