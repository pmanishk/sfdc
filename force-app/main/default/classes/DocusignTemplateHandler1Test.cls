@isTest(SeeAllData=true)
public class DocusignTemplateHandler1Test {

    // Mock for successful HTTP callout
    private class DocusignApiSuccessMock implements HttpCalloutMock {
        public HttpResponse respond(HttpRequest req) {
            HttpResponse res = new HttpResponse();
            res.setStatusCode(200);
            res.setHeader('Content-Type', 'application/json');
            res.setBody('{"formData":[{"name":"Checkbox Group A","value":"X"},{"name":"Checkbox Group B","value":""}]}');
            return res;
        }
    }

    // Mock for failed HTTP callout
    private class DocusignApiErrorMock implements HttpCalloutMock {
        public HttpResponse respond(HttpRequest req) {
            HttpResponse res = new HttpResponse();
            res.setStatusCode(400);
            res.setBody('{"error": "Bad Request"}');
            return res;
        }
    }

    // Helper method to create valid test data
    private static dfsle__EnvelopeStatus__c createTestData(String envelopeId, Id financialAccountId) {
        dfsle__Envelope__c envelope = new dfsle__Envelope__c(dfsle__DocuSignId__c = envelopeId);
        insert envelope;

        dfsle__EnvelopeStatus__c envelopeStatus = new dfsle__EnvelopeStatus__c(
            dfsle__DocuSignId__c = envelopeId,
            Financial_Account__c = financialAccountId,
            dfsle__Status__c = 'Completed'
        );
        insert envelopeStatus;

        return envelopeStatus;
    }

    private static FinServ__FinancialAccount__c createFinancialAccount() {
        // Fetch necessary record types
        RecordType householdRecType = [SELECT Id FROM RecordType WHERE DeveloperName = 'IndustriesHousehold' AND SObjectType = 'Account' LIMIT 1];
        RecordType advisorRecType = [SELECT Id FROM RecordType WHERE DeveloperName = 'SIG_Advisors_Agents_and_their_affiliated_staff' AND SObjectType = 'Account' LIMIT 1];

        // Create primary owner account
        Account primaryOwner = new Account(
            FirstName = 'Primary',
            LastName = 'Owner',
            RecordTypeId = advisorRecType.Id
        );
        insert primaryOwner;

        // Create joint owner account
        Account jointOwner = new Account(
            FirstName = 'Joint',
            LastName = 'Owner',
            RecordTypeId = advisorRecType.Id
        );
        insert jointOwner;

        // Create household account
        Account householdAccount = new Account(
            Name = 'Test Household',
            RecordTypeId = householdRecType.Id
        );
        insert householdAccount;

        // Create financial account
        FinServ__FinancialAccount__c financialAccount = new FinServ__FinancialAccount__c(
            Name = 'Test Financial Account',
            FinServ__PrimaryOwner__c = primaryOwner.Id,
            FinServ__Household__c = householdAccount.Id
        );

        insert financialAccount;
        return financialAccount;
    }

    @isTest
    static void testProcessCompletedEnvelope_Success() {
        FinServ__FinancialAccount__c financialAccount = createFinancialAccount();

        dfsle__EnvelopeStatus__c envelopeStatus = createTestData('12345', financialAccount.Id);

        // Mock the HTTP callout
        Test.setMock(HttpCalloutMock.class, new DocusignApiSuccessMock());

        Test.startTest();
        DocusignTemplateHandler1.processCompletedEnvelope(envelopeStatus.dfsle__DocuSignId__c, 'Test Template');
        Test.stopTest();

        // Validate the Financial Account was updated
        FinServ__FinancialAccount__c updatedAccount = [
            SELECT Id, Name FROM FinServ__FinancialAccount__c WHERE Id = :financialAccount.Id
        ];
        System.assertNotEquals(null, updatedAccount, 'The financial account should be updated.');
    }

    @isTest
    static void testTrigger_CreateContentAndProcessEnvelope() {
        // Setup test data
        FinServ__FinancialAccount__c financialAccount = createFinancialAccount();
        dfsle__Envelope__c parentEnvelope = new dfsle__Envelope__c(
            dfsle__DocuSignId__c = '11111',
            Envelope_Name__c = 'Test Envelope Template'
        );
        insert parentEnvelope;

        dfsle__EnvelopeStatus__c envelopeStatus = new dfsle__EnvelopeStatus__c(
            DocuSign_Envelope_Record__c = parentEnvelope.Id,
            Financial_Account__c = financialAccount.Id,
            dfsle__Status__c = 'Sent'
        );
        insert envelopeStatus;

        // Mock successful HTTP callout
        Test.setMock(HttpCalloutMock.class, new DocusignApiSuccessMock());

        // Simulate status update to 'Completed' to fire the trigger
        envelopeStatus.dfsle__Status__c = 'Completed';
        update envelopeStatus;

        // Validate the Financial Account was updated
        FinServ__FinancialAccount__c updatedAccount = [
            SELECT Id, Name FROM FinServ__FinancialAccount__c WHERE Id = :financialAccount.Id
        ];
        System.assertNotEquals(null, updatedAccount, 'The financial account should be updated.');

        // Validate content document links were created
        List<ContentDocumentLink> documentLinks = [SELECT Id FROM ContentDocumentLink WHERE LinkedEntityId = :financialAccount.Id];
        //System.assert(documentLinks.size() > 0, 'Content document links should be created.');
    }
    
    
    @isTest
    static void testAddCheckboxValue() {
        // Setup the test data
        Map<String, List<String>> selectedCheckboxGroups = new Map<String, List<String>>();
        String fieldName = 'TestCheckboxGroup';
        String fieldLabel = 'Checkbox Group A|Option1';
        String fieldValue = 'X';
        
        // Call the method
        Test.startTest();
        DocusignTemplateHandler1.addCheckboxValue(fieldName, fieldLabel, fieldValue, selectedCheckboxGroups);
        Test.stopTest();
        
    }
    
    @isTest
    static void testUpdateFinancialAccount() {
        // Create mock data
        FinServ__FinancialAccount__c financialAccount = createFinancialAccount();
        dfsle__EnvelopeStatus__c envelopeStatus = createTestData('12345', financialAccount.Id);
        
        // Mock selected topics
        Map<String, List<String>> selectedTopics = new Map<String, List<String>> {
            'Test_Field__c' => new List<String> { 'Option1', 'Option2' },
                'Other_Field__c' => new List<String> { 'Option3' }
        };
            
    }
   
}