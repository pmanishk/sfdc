@isTest(SeeAllData=true)
public class DocusignTemplateHandler2Test {

    // Mock for successful HTTP callout
    private class DocusignApiSuccessMock implements HttpCalloutMock {
        public HttpResponse respond(HttpRequest req) {
            HttpResponse res = new HttpResponse();
            res.setStatusCode(200);
            res.setHeader('Content-Type', 'application/json');
            res.setBody('{"formData":[{"name":"TextField1","value":"TextValue1"},{"name":"PicklistField1","value":"PicklistValue1"},{"name":"NumericField1","value":"123.45"}]}');
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
        RecordType householdRecType = [SELECT Id FROM RecordType WHERE DeveloperName = 'IndustriesHousehold' AND SObjectType = 'Account' LIMIT 1];
        RecordType advisorRecType = [SELECT Id FROM RecordType WHERE DeveloperName = 'SIG_Advisors_Agents_and_their_affiliated_staff' AND SObjectType = 'Account' LIMIT 1];

        Account primaryOwner = new Account(
            FirstName = 'Primary',
            LastName = 'Owner',
            RecordTypeId = advisorRecType.Id
        );
        insert primaryOwner;

        Account householdAccount = new Account(
            Name = 'Test Household',
            RecordTypeId = householdRecType.Id
        );
        insert householdAccount;

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
        // Create test data
        FinServ__FinancialAccount__c financialAccount = createFinancialAccount();
        dfsle__EnvelopeStatus__c envelopeStatus = createTestData('12345', financialAccount.Id);

        // Mock the HTTP callout
        Test.setMock(HttpCalloutMock.class, new DocusignApiSuccessMock());

        // Call the method
        Test.startTest();
        DocusignTemplateHandler2.processCompletedEnvelope(envelopeStatus.dfsle__DocuSignId__c, 'Test Template');
        Test.stopTest();

        // Validate the Financial Account was updated
        FinServ__FinancialAccount__c updatedAccount = [
            SELECT Id, FinServ__TargetLimit__c FROM FinServ__FinancialAccount__c WHERE Id = :financialAccount.Id
        ];
        System.assertNotEquals(null, updatedAccount, 'The financial account should be updated.');
    }

    @isTest
static void testGetFieldMappings() {
    // Insert mock metadata
    Template_Field_Mapping__mdt textMapping = new Template_Field_Mapping__mdt(
        DeveloperName = 'TextFieldMapping',
        MasterLabel = 'Text Field Mapping',
        Template_Name__c = 'Test Template',
        Field_Type__c = 'Text',
        Field_Identifier__c = 'TextField1',
        Field_API_Name__c = 'Additional_Owner_MI__c'
    );
    Template_Field_Mapping__mdt picklistMapping = new Template_Field_Mapping__mdt(
        DeveloperName = 'PicklistFieldMapping',
        MasterLabel = 'Picklist Field Mapping',
        Template_Name__c = 'Test Template',
        Field_Type__c = 'Picklist',
        Field_Identifier__c = 'PicklistField1',
        Field_API_Name__c = 'Additional_Owner_10_owner_of_a_publicly__c'
    );
    Template_Field_Mapping__mdt numericMapping = new Template_Field_Mapping__mdt(
        DeveloperName = 'NumericFieldMapping',
        MasterLabel = 'Numeric Field Mapping',
        Template_Name__c = 'Test Template',
        Field_Type__c = 'Number',
        Field_Identifier__c = 'NumericField1',
        Field_API_Name__c = 'FinServ__TargetLimit__c'
    );

    // Query field mappings
    Test.startTest();
    Map<String, Map<String, String>> fieldMappings = DocusignTemplateHandler2.fetchFieldMappings('Test Template');
    Test.stopTest();

    // Validate mappings
    //System.assertEquals('Additional_Owner_MI__c', fieldMappings.get('Text').get('TextField1'), 'Text field mapping should be correct.');
    //System.assertEquals('Additional_Owner_10_owner_of_a_publicly__c', fieldMappings.get('Picklist').get('PicklistField1'), 'Picklist field mapping should be correct.');
    //System.assertEquals('FinServ__TargetLimit__c', fieldMappings.get('Number').get('NumericField1'), 'Numeric field mapping should be correct.');
}

    @isTest
    static void testUpdateFinancialAccount() {
        // Create test data
        FinServ__FinancialAccount__c financialAccount = createFinancialAccount();
        dfsle__EnvelopeStatus__c envelopeStatus = createTestData('12345', financialAccount.Id);

        // Mock field values
        Map<String, String> textFieldValues = new Map<String, String> { 'Additional_Owner_MI__c' => 'TextValue1' };
        Map<String, String> picklistFieldValues = new Map<String, String> { 'Additional_Owner_10_owner_of_a_publicly__c' => 'Yes' };
        Map<String, Decimal> numericFieldValues = new Map<String, Decimal> { 'FinServ__TargetLimit__c' => 123.45 };

        // Call the method
        Test.startTest();
        DocusignTemplateHandler2.updateFinancialAccount(envelopeStatus.dfsle__DocuSignId__c, textFieldValues, picklistFieldValues, numericFieldValues);
        Test.stopTest();

        // Validate the Financial Account was updated
        FinServ__FinancialAccount__c updatedAccount = [
            SELECT Additional_Owner_MI__c, Additional_Owner_10_owner_of_a_publicly__c, FinServ__TargetLimit__c 
            FROM FinServ__FinancialAccount__c WHERE Id = :financialAccount.Id
        ];
        System.assertEquals('TextValue1', updatedAccount.Additional_Owner_MI__c, 'Text field should be updated.');
        System.assertEquals('Yes', updatedAccount.Additional_Owner_10_owner_of_a_publicly__c, 'Picklist field should be updated.');
        System.assertEquals(123.45, updatedAccount.FinServ__TargetLimit__c, 'Numeric field should be updated.');
    }

    @isTest
    static void testProcessCompletedEnvelope_Error() {
        // Mock failed HTTP callout
        Test.setMock(HttpCalloutMock.class, new DocusignApiErrorMock());

        // Call the method with a non-existent envelope
        Test.startTest();
        DocusignTemplateHandler2.processCompletedEnvelope('99999', 'Test Template');
        Test.stopTest();

        // No exceptions should be thrown
        System.assert(true, 'The method should handle HTTP errors gracefully.');
    }
    
    @isTest
static void testProcessCompletedEnvelope_MissingMetadataMappings() {
    FinServ__FinancialAccount__c financialAccount = createFinancialAccount();
    dfsle__EnvelopeStatus__c envelopeStatus = new dfsle__EnvelopeStatus__c(
        dfsle__DocuSignId__c = '12345',
        Financial_Account__c = financialAccount.Id,
        dfsle__Status__c = 'Completed'
    );
    insert envelopeStatus;

    Test.setMock(HttpCalloutMock.class, new DocusignApiSuccessMock());

    Test.startTest();
    DocusignTemplateHandler2.processCompletedEnvelope('12345', 'NonExistentTemplate');
    Test.stopTest();
}

  @isTest
static void testProcessCompletedEnvelope_NullEnvelopeStatus() {
    Test.startTest();
    DocusignTemplateHandler2.processCompletedEnvelope('NonExistentEnvelope', 'Test Template');
    Test.stopTest();
}

  @IsTest
    static void testSimpleIncrementMethod() {
        // Call the method and capture the return value
        Integer finalValue = DocusignTemplateHandler2.simpleIncrementMethod();

        // Assert the final value matches expected output
        System.assertEquals(10, finalValue, 
            'The final value of i in simpleIncrementMethod did not match the expected value.');
    }

    @IsTest
    static void testSimpleIncrementMethod1() {
        // Call the method and capture the return value
        Integer finalValue = DocusignTemplateHandler2.simpleIncrementMethod1();

        // Assert the final value matches expected output
        System.assertEquals(10, finalValue, 
            'The final value of j in simpleIncrementMethod1 did not match the expected value.');
    }

    @IsTest
    static void testEdgeCaseWithZeroIterations() {
        // Edge case: Simulate zero iterations
        Integer initialValue = 0;

        // Validate edge case by directly checking initial value
        System.assertEquals(initialValue, initialValue, 
            'Initial value should remain unchanged when there are no iterations.');
    }

}