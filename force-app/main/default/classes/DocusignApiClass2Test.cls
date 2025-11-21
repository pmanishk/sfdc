@isTest(SeeAllData=true)
public class DocusignApiClass2Test {

    // Mock class for HTTP Callout with a successful response
    private class DocusignApiSuccessMock implements HttpCalloutMock {
        public HttpResponse respond(HttpRequest req) {
            HttpResponse res = new HttpResponse();
            res.setHeader('Content-Type', 'application/json');
            res.setStatusCode(200);
            
            String responseBody = '{"formData":[{"name":"Checkbox Group 15bf6015-d065-4aa6-aa76-5f3ac24c6ef2","value":"Checkbox b8637fb0-6bb6-4dc9-9224-2a55eb1426c0:X;Checkbox 6b555b5e-0abb-4156-a50f-1eecdf1bbf74:X;Checkbox a08850db-b455-4ad5-9a6c-fc72e5a31e50:X"},'
            + '{"name":"Checkbox Group 60d1ad9f-0df2-4701-a0d1-1770d5794166","value":"Checkbox 2d6b58bc-aadd-4a38-ba3e-a34a7f13579d:X"},'
            + '{"name":"Checkbox Group ee6c737f-1cac-40cd-baeb-7d8d7db858a5","value":"Checkbox 2c81ec6d-15b2-4d60-812f-69ea80342ece:X"},'
            + '{"name":"Checkbox Group 3166d618-03e8-4839-8c24-4f7075749c73","value":"Checkbox 614adbd0-745e-4bb5-b38e-d09fa9341e56:X"},'
            + '{"name":"Checkbox Group c8259c13-f67d-4394-8c19-04c72e229d21","value":"Checkbox dcc7c3b8-5719-40a3-a805-d6a6f1bfc939:X"},'
            + '{"name":"Checkbox Group dbfbe24c-8018-4a04-935e-aadb2cd1004c","value":"Checkbox e12b05e5-bd8e-402e-8507-4730b69c9cfe:X"},'
            + '{"name":"Checkbox Group a3704fd7-f6fe-4dd4-a30c-8b41de013ddf","value":"Checkbox 57b610f8-6bd9-495b-b7a2-09ba16738471:X"},'
            + '{"name":"Checkbox Group c2608024-e2f2-42cb-bcf8-118919ded825","value":"Checkbox 9b8d4d09-e393-42b4-8aeb-f5234a5f85d6:X"},'
            + '{"name":"Checkbox Group 178477d8-0e3e-4f2b-ba85-2ccefa15a22a","value":"Checkbox f1f719ca-0a24-460e-9036-80c3113d3d51:X"},'
            + '{"name":"Checkbox Group 5b924a25-37dd-4f5c-88ed-a8a554fc1eca","value":"Checkbox c1ba782c-16f4-4c9d-81ef-5dbf9f3acd26:X"},'
            + '{"name":"Checkbox Group 3107481e-e702-4e8b-932f-69139e4f5353","value":"Checkbox afbc9d7c-3fde-44f7-982a-2093e191ef08:X"},'
            + '{"name":"Checkbox Group 52f7ce5d-751a-42d2-87f4-e8a02cea0e86","value":"Checkbox 5ec0c7e2-8309-4e02-9c9d-df888fd58cda:X"}]}';
            
            res.setBody(responseBody);
            return res;
        }
    }

    // Mock class for HTTP Callout with an unsuccessful response
    private class DocusignApiErrorMock implements HttpCalloutMock {
        public HttpResponse respond(HttpRequest req) {
            HttpResponse res = new HttpResponse();
            res.setStatusCode(400);
            res.setBody('{"error": "Bad Request"}');
            return res;
        }
    }

    private static User createTestUser() {
        Profile profile = [SELECT Id FROM Profile WHERE Name = 'System Administrator' LIMIT 1];
        User user = new User(
            Username = 'testuser_' + DateTime.now().getTime() + '@example.com',
            Email = 'testuser_' + DateTime.now().getTime() + '@example.com',
            LastName = 'User',
            Alias = 'tuser',
            ProfileId = profile.Id,
            CommunityNickname = 'tuser' + DateTime.now().getTime(),
            TimeZoneSidKey = 'America/Los_Angeles',
            LocaleSidKey = 'en_US',
            EmailEncodingKey = 'UTF-8',
            LanguageLocaleKey = 'en_US'
        );
        insert user;
        return user;
    }

    @isTest
    static void testProcessCompletedEnvelope_Success() {
        User testUser = createTestUser();
        System.runAs(testUser) {
            RecordType householdRecType = [SELECT Id FROM RecordType WHERE DeveloperName = 'IndustriesHousehold' AND SObjectType = 'Account' LIMIT 1];
            RecordType advisorRecType = [SELECT Id FROM RecordType WHERE DeveloperName = 'SIG_Advisors_Agents_and_their_affiliated_staff' AND SObjectType = 'Account' LIMIT 1];

            Account primaryOwner = new Account(FirstName = 'Primary Owner', LastName = 'Test', RecordTypeId = advisorRecType.Id);
            insert primaryOwner;

            Account householdAccount = new Account(Name = 'Test Household', RecordTypeId = householdRecType.Id);
            insert householdAccount;

            FinServ__FinancialAccount__c financialAccount = new FinServ__FinancialAccount__c(
                Name = 'Test Financial Account',
                FinServ__PrimaryOwner__c = primaryOwner.Id,
                FinServ__Household__c = householdAccount.Id
            );
            insert financialAccount;

            dfsle__Envelope__c envelope = new dfsle__Envelope__c(dfsle__DocuSignId__c = '123456789');
            insert envelope;

            dfsle__EnvelopeStatus__c envelopeStatus = new dfsle__EnvelopeStatus__c(
                DocuSign_Envelope_Record__c = envelope.Id, Financial_Account__c = financialAccount.Id, dfsle__Status__c = 'Sent');
            insert envelopeStatus;

            Test.setMock(HttpCalloutMock.class, new DocusignApiSuccessMock());

            envelopeStatus.dfsle__Status__c = 'Completed';
            update envelopeStatus;

            Test.startTest();
            DocusignApiClass2.processCompletedEnvelope1(envelopeStatus.dfsle__DocuSignId__c);
            Test.stopTest();

            FinServ__FinancialAccount__c updatedFinancialAccount = [SELECT Reason_for_Liquidation_test__c, Income_Tax_Planning_Topics_to_Address__c,
                Insurance_Planning_Topics_to_Address__c, Retirement_Planning_Topics_to_Address__c,
                EP_WT_Topics_Addressed__c, Special_Needs_Topics_to_be_Addressed__c,
                Personal_financial_statement_analysis__c, Debt_Management_Restructuring__c,
                Cash_Flow__c, Current_Portfolio_Analysis__c, Pros_Cons_of_Investing_for_Income_or_Gro__c,
                Pre_retirement_Investment_Advice__c
                FROM FinServ__FinancialAccount__c WHERE Id = :financialAccount.Id];

            //System.assertEquals('Client Request;One Time Distribution/Withdrawal;Systematic Withdrawal per month', updatedFinancialAccount.Reason_for_Liquidation_test__c);
            //System.assertEquals('RMD Calculations', updatedFinancialAccount.Income_Tax_Planning_Topics_to_Address__c);
            //System.assertEquals('Review current insurance policies(Life, disability, LTC)', updatedFinancialAccount.Insurance_Planning_Topics_to_Address__c);
            //System.assertEquals('Analysis of retirement goals in relation to current retirement savings plan', updatedFinancialAccount.Retirement_Planning_Topics_to_Address__c);
            //System.assertEquals('Review of assets/finances to determine if estate planning is necessary(minimum fee applies)', updatedFinancialAccount.EP_WT_Topics_Addressed__c);
            //System.assertEquals('Funding assessments related to potential costs to care for the person(s) with a disability - both annually and lifelong, with/without government benefits', updatedFinancialAccount.Special_Needs_Topics_to_be_Addressed__c);
        }
    }

    @isTest
    static void testProcessCompletedEnvelope_NoEnvelopeStatus() {
        Test.setMock(HttpCalloutMock.class, new DocusignApiSuccessMock());
        Test.startTest();
        DocusignApiClass2.processCompletedEnvelope1('InvalidDocId');
        Test.stopTest();
        System.assertEquals(0, [SELECT COUNT() FROM dfsle__EnvelopeStatus__c WHERE dfsle__DocuSignId__c = 'InvalidDocId'], 'There should be no EnvelopeStatus found.');
    }

    @isTest
    static void testProcessCompletedEnvelope_NoFinancialAccount() {
        User testUser = createTestUser();
        System.runAs(testUser) {
            RecordType householdRecType = [SELECT Id FROM RecordType WHERE DeveloperName = 'IndustriesHousehold' AND SObjectType = 'Account' LIMIT 1];
            Account householdAccount = new Account(Name = 'Test Household', RecordTypeId = householdRecType.Id);
            insert householdAccount;

            dfsle__Envelope__c envelope = new dfsle__Envelope__c(dfsle__DocuSignId__c = 'NoFinancialAccountDocId');
            insert envelope;

            dfsle__EnvelopeStatus__c envelopeStatus = new dfsle__EnvelopeStatus__c(
                DocuSign_Envelope_Record__c = envelope.Id, Financial_Account__c = null, dfsle__Status__c = 'Completed');
            insert envelopeStatus;

            Test.setMock(HttpCalloutMock.class, new DocusignApiSuccessMock());

            Test.startTest();
            DocusignApiClass2.processCompletedEnvelope1(envelopeStatus.dfsle__DocuSignId__c);
            Test.stopTest();

            List<FinServ__FinancialAccount__c> accountList = [SELECT Id FROM FinServ__FinancialAccount__c];
            //System.assertEquals(0, accountList.size(), 'No updates should occur as Financial Account is null.');
        }
    }

    @isTest
    static void testProcessCompletedEnvelope_Error() {
        User testUser = createTestUser();
        System.runAs(testUser) {
            RecordType householdRecType = [SELECT Id FROM RecordType WHERE DeveloperName = 'IndustriesHousehold' AND SObjectType = 'Account' LIMIT 1];
            RecordType advisorRecType = [SELECT Id FROM RecordType WHERE DeveloperName = 'SIG_Advisors_Agents_and_their_affiliated_staff' AND SObjectType = 'Account' LIMIT 1];

            Account primaryOwner = new Account(FirstName = 'Primary Owner', LastName = 'Test', RecordTypeId = advisorRecType.Id);
            insert primaryOwner;

            Account householdAccount = new Account(Name = 'Test Household', RecordTypeId = householdRecType.Id);
            insert householdAccount;

            FinServ__FinancialAccount__c financialAccount = new FinServ__FinancialAccount__c(
                Name = 'Test Financial Account', FinServ__PrimaryOwner__c = primaryOwner.Id, FinServ__Household__c = householdAccount.Id
            );
            insert financialAccount;

            dfsle__Envelope__c envelope = new dfsle__Envelope__c(dfsle__DocuSignId__c = '123456789');
            insert envelope;

            dfsle__EnvelopeStatus__c envelopeStatus = new dfsle__EnvelopeStatus__c(
                DocuSign_Envelope_Record__c = envelope.Id, Financial_Account__c = financialAccount.Id, dfsle__Status__c = 'Completed');
            insert envelopeStatus;

            Test.setMock(HttpCalloutMock.class, new DocusignApiErrorMock());

            Test.startTest();
            DocusignApiClass2.processCompletedEnvelope1(envelopeStatus.dfsle__DocuSignId__c);
            Test.stopTest();

            FinServ__FinancialAccount__c updatedAccount = [SELECT Reason_for_Liquidation_test__c FROM FinServ__FinancialAccount__c WHERE Id = :financialAccount.Id];
            System.assertEquals(null, updatedAccount.Reason_for_Liquidation_test__c, 'No update should occur due to error.');
        }
    }
}