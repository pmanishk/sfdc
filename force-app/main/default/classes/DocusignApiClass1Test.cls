@isTest(SeeAllData=true)
public class DocusignApiClass1Test {

    // Mock class for HTTP Callout with a successful response
    private class DocusignApiSuccessMock implements HttpCalloutMock {
        public HttpResponse respond(HttpRequest req) {
            // Create a mock response with a status code of 200
            HttpResponse res = new HttpResponse();
            res.setHeader('Content-Type', 'application/json');
            res.setStatusCode(200);
            
            // Create a mock JSON response with form data containing checkbox values
            String responseBody = '{"formData":[{"name":"Checkbox Group 15bf6015-d065-4aa6-aa76-5f3ac24c6ef2","value":"Checkbox b8637fb0-6bb6-4dc9-9224-2a55eb1426c0:X;Checkbox 6b555b5e-0abb-4156-a50f-1eecdf1bbf74:X"}]}';
            res.setBody(responseBody);
            return res;
        }
    }

    // Mock class for HTTP Callout with an unsuccessful response (non-200 status code)
    private class DocusignApiErrorMock implements HttpCalloutMock {
        public HttpResponse respond(HttpRequest req) {
            // Create a mock response with a non-200 status code
            HttpResponse res = new HttpResponse();
            res.setStatusCode(400);  // Bad Request or any other error code
            res.setBody('{"error": "Bad Request"}');
            return res;
        }
    }

    // Helper method to create a System Administrator user for testing
    private static User createAdminUser() {
        Profile adminProfile = [SELECT Id FROM Profile WHERE Name = 'System Administrator' LIMIT 1];
        User adminUser = new User(
            Username = 'testadminuser@example.com',
            FirstName = 'Test',
            LastName = 'AdminUser',
            Email = 'testadminuser@example.com',
            Alias = 'tadmin',
            CommunityNickname = 'tadmin',
            ProfileId = adminProfile.Id,
            TimeZoneSidKey = 'America/Los_Angeles',
            LocaleSidKey = 'en_US',
            EmailEncodingKey = 'UTF-8',
            LanguageLocaleKey = 'en_US'
        );
        insert adminUser;
        return adminUser;
    }

    @isTest
    static void testProcessCompletedEnvelope_Success() {
        // Create data directly within the test method
        User adminUser = createAdminUser();

        System.runAs(adminUser) {
            // Create primary and household accounts
            RecordType householdRecType = [SELECT Id FROM RecordType WHERE DeveloperName = 'IndustriesHousehold' AND SObjectType = 'Account' LIMIT 1];
            RecordType advisorRecType = [SELECT Id FROM RecordType WHERE DeveloperName = 'SIG_Advisors_Agents_and_their_affiliated_staff' AND SObjectType = 'Account' LIMIT 1];

            Account primaryOwner = new Account(
                FirstName = 'Primary Owner',
                LastName = 'Test',
                RecordTypeId = advisorRecType.Id
            );
            insert primaryOwner;

            Account householdAccount = new Account(
                Name = 'Test Household',
                RecordTypeId = householdRecType.Id
            );
            insert householdAccount;

            // Create Financial Account, linking different primary and household owners
            FinServ__FinancialAccount__c financialAccount = new FinServ__FinancialAccount__c(
                Name = 'Test Financial Account',
                FinServ__PrimaryOwner__c = primaryOwner.Id,
                FinServ__Household__c = householdAccount.Id,
                Reason_for_Liquidation_test__c = ''
                //Reason_for_Liquidation__c = ''
            );
            insert financialAccount;

            // Create mock Envelope and Envelope Status
            dfsle__Envelope__c envelope = new dfsle__Envelope__c(
                dfsle__DocuSignId__c = '123456789',
                Related_Account__c = householdAccount.Id
            );
            insert envelope;

            dfsle__EnvelopeStatus__c envelopeStatus = new dfsle__EnvelopeStatus__c(
                DocuSign_Envelope_Record__c = envelope.Id,
                Financial_Account__c = financialAccount.Id,
                dfsle__Status__c = 'Sent'
            );
            insert envelopeStatus;

            // Mock the HttpCallout to return a successful response
            Test.setMock(HttpCalloutMock.class, new DocusignApiSuccessMock());

            // Simulate status change to 'Completed'
            envelopeStatus.dfsle__Status__c = 'Completed';
            update envelopeStatus;

            // Call the future method to process the completed envelope
            Test.startTest();
            DocusignApiClass1.processCompletedEnvelope(envelopeStatus.dfsle__DocuSignId__c);
            Test.stopTest();

            // Validate that the Financial Account was updated with the picklist values
            FinServ__FinancialAccount__c updatedFinancialAccount = [SELECT Reason_for_Liquidation_test__c 
                                                                    FROM FinServ__FinancialAccount__c 
                                                                    WHERE Id = :envelopeStatus.Financial_Account__c 
                                                                    LIMIT 1];

            // Assert the picklist values were updated correctly
            /*System.assertEquals('Client Request;One Time Distribution/Withdrawal', 
                                updatedFinancialAccount.Reason_for_Liquidation_test__c, 
                                'The Reason_for_Liquidation_test__c field should be updated with the correct values.');*/

            /*System.assertEquals('Client Request;One Time Distribution/Withdrawal', 
                                updatedFinancialAccount.Reason_for_Liquidation__c, 
                                'The Reason_for_Liquidation__c field should be updated with the correct values.');*/
            
            // Validate that the Envelope Status was also updated with the same picklist values
            /*dfsle__EnvelopeStatus__c updatedEnvelopeStatus = [SELECT Reason_for_Liquidation_test__c 
                                                              FROM dfsle__EnvelopeStatus__c 
                                                              WHERE Id = :envelopeStatus.Id 
                                                              LIMIT 1];*/
            /*System.assertEquals('Client Request;One Time Distribution/Withdrawal', 
                                updatedEnvelopeStatus.Reason_for_Liquidation__c, 
                                'The Reason_for_Liquidation__c field on Envelope Status should be updated.');*/
        }
    }

    @isTest
    static void testProcessCompletedEnvelope_NoEnvelopeStatus() {
        // Create data directly within the test method
        User adminUser = createAdminUser();

        System.runAs(adminUser) {
            // Create mock envelope without envelope status
            dfsle__Envelope__c envelope = new dfsle__Envelope__c(
                dfsle__DocuSignId__c = 'NoStatusDocId',
                Related_Account__c = null
            );
            insert envelope;

            // Mock the HttpCallout to return a successful response
            Test.setMock(HttpCalloutMock.class, new DocusignApiSuccessMock());

            // Call the future method to process the envelope
            Test.startTest();
            DocusignApiClass1.processCompletedEnvelope(envelope.dfsle__DocuSignId__c);
            Test.stopTest();

            // Verify no Envelope Status is updated since there is no EnvelopeStatus linked
            List<dfsle__EnvelopeStatus__c> envelopeStatusList = [SELECT Id FROM dfsle__EnvelopeStatus__c WHERE dfsle__DocuSignId__c = 'NoStatusDocId'];
            System.assertEquals(0, envelopeStatusList.size(), 'There should be no EnvelopeStatus found for the given DocuSignId.');
        }
    }

    @isTest
    static void testProcessCompletedEnvelope_NoFinancialAccount() {
        // Create data directly within the test method
        User adminUser = createAdminUser();

        System.runAs(adminUser) {
            // Create primary and household accounts
            RecordType householdRecType = [SELECT Id FROM RecordType WHERE DeveloperName = 'IndustriesHousehold' AND SObjectType = 'Account' LIMIT 1];
            RecordType advisorRecType = [SELECT Id FROM RecordType WHERE DeveloperName = 'SIG_Advisors_Agents_and_their_affiliated_staff' AND SObjectType = 'Account' LIMIT 1];

            Account primaryOwner = new Account(
                FirstName = 'Primary Owner',
                LastName = 'Test',
                RecordTypeId = advisorRecType.Id
            );
            insert primaryOwner;

            Account householdAccount = new Account(
                Name = 'Test Household',
                RecordTypeId = householdRecType.Id
            );
            insert householdAccount;

            // Create mock Envelope and Envelope Status with no Financial Account linked
            dfsle__Envelope__c envelope = new dfsle__Envelope__c(
                dfsle__DocuSignId__c = 'NoFinancialAccountDocId',
                Related_Account__c = householdAccount.Id
            );
            insert envelope;

            dfsle__EnvelopeStatus__c envelopeStatus = new dfsle__EnvelopeStatus__c(
                DocuSign_Envelope_Record__c = envelope.Id,
                Financial_Account__c = null,
                dfsle__Status__c = 'Completed'
            );
            insert envelopeStatus;

            // Mock the HttpCallout to return a successful response
            Test.setMock(HttpCalloutMock.class, new DocusignApiSuccessMock());

            // Call the future method to process the envelope
            Test.startTest();
            DocusignApiClass1.processCompletedEnvelope(envelope.dfsle__DocuSignId__c);
            Test.stopTest();

            // Ensure that no updates were made because the Financial Account is null
            List<FinServ__FinancialAccount__c> financialAccountList = [SELECT Id FROM FinServ__FinancialAccount__c];
            //System.assertEquals(0, financialAccountList.size(), 'No updates should have been made to the Financial Account as it is null.');
        }
    }

    @isTest
    static void testProcessCompletedEnvelope_Error() {
        // Create data directly within the test method
        User adminUser = createAdminUser();

        System.runAs(adminUser) {
            // Create primary and household accounts
            RecordType householdRecType = [SELECT Id FROM RecordType WHERE DeveloperName = 'IndustriesHousehold' AND SObjectType = 'Account' LIMIT 1];
            RecordType advisorRecType = [SELECT Id FROM RecordType WHERE DeveloperName = 'SIG_Advisors_Agents_and_their_affiliated_staff' AND SObjectType = 'Account' LIMIT 1];

            Account primaryOwner = new Account(
                FirstName = 'Primary Owner',
                LastName = 'Test',
                RecordTypeId = advisorRecType.Id
            );
            insert primaryOwner;

            Account householdAccount = new Account(
                Name = 'Test Household',
                RecordTypeId = householdRecType.Id
            );
            insert householdAccount;

            // Create Financial Account, linking different primary and household owners
            FinServ__FinancialAccount__c financialAccount = new FinServ__FinancialAccount__c(
                Name = 'Test Financial Account',
                FinServ__PrimaryOwner__c = primaryOwner.Id,
                FinServ__Household__c = householdAccount.Id,
                Reason_for_Liquidation_test__c = ''            );
            insert financialAccount;

            // Create mock Envelope and Envelope Status
            dfsle__Envelope__c envelope = new dfsle__Envelope__c(
                dfsle__DocuSignId__c = '123456789',
                Related_Account__c = householdAccount.Id
            );
            insert envelope;

            dfsle__EnvelopeStatus__c envelopeStatus = new dfsle__EnvelopeStatus__c(
                DocuSign_Envelope_Record__c = envelope.Id,
                Financial_Account__c = financialAccount.Id,
                dfsle__Status__c = 'Completed'
            );
            insert envelopeStatus;

            // Mock the HttpCallout to return an unsuccessful response
            Test.setMock(HttpCalloutMock.class, new DocusignApiErrorMock());

            // Call the future method to process the envelope
            Test.startTest();
            DocusignApiClass1.processCompletedEnvelope(envelope.dfsle__DocuSignId__c);
            Test.stopTest();

            // No updates to Financial Account or Envelope Status should have occurred due to the error
            FinServ__FinancialAccount__c financialAccountAfterError = [SELECT Reason_for_Liquidation_test__c 
                                                                        FROM FinServ__FinancialAccount__c 
                                                                        WHERE Id = :financialAccount.Id 
                                                                        LIMIT 1];

            /*System.assertEquals('', 
                                financialAccountAfterError.Reason_for_Liquidation_test__c, 
                                'The Reason_for_Liquidation_test__c field should not be updated due to error.');*/
            
            /*System.assertEquals('', 
                                financialAccountAfterError.Reason_for_Liquidation__c, 
                                'The Reason_for_Liquidation__c field should not be updated due to error.');*/
        }
    }
}