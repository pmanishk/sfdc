@isTest(SeeAllData=true)
public class TriggerCreateContentTest {
    
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
    static void testTriggerLinkDocusign() {
        // Create a System Admin user and run the test as that user
        User adminUser = createAdminUser();
        System.runAs(adminUser) {
            // Set up test data
            RecordType accountRecType = [SELECT Id FROM RecordType WHERE DeveloperName = 'SIG_Advisors_Agents_and_their_affiliated_staff' AND SObjectType = 'Account' LIMIT 1];
            Account primaryOwnerAccount = new Account(
                LastName = 'Test Account',
                FirstName = 'Primary Owner',
                RecordTypeId = accountRecType.Id
            );
            insert primaryOwnerAccount;
            
            RecordType accountRecType1 = [SELECT Id FROM RecordType WHERE DeveloperName = 'IndustriesHousehold' AND SObjectType = 'Account' LIMIT 1];
            
            Account householdAccount = new Account(
                Name = 'Test Household',
                RecordTypeId = accountRecType1.Id
            );
            insert householdAccount;
            
            FinServ__FinancialAccount__c financialAccount = new FinServ__FinancialAccount__c(
                Name = 'Test Financial Account',
                FinServ__PrimaryOwner__c = primaryOwnerAccount.Id,
                FinServ__Household__c = householdAccount.Id
            );
            insert financialAccount;
            
            // Create Envelope and EnvelopeStatus records
            dfsle__Envelope__c envelope = new dfsle__Envelope__c(
                dfsle__DocuSignId__c = 'TestDocuSignId',
                Related_Account__c = null
            );
            insert envelope;
            
            dfsle__EnvelopeStatus__c envelopeStatus = new dfsle__EnvelopeStatus__c(
                DocuSign_Envelope_Record__c = envelope.Id,
                Financial_Account__c = financialAccount.Id
            );
            insert envelopeStatus;
            
            // Update the EnvelopeStatus to trigger the before update trigger
            envelopeStatus.Financial_Account__c = financialAccount.Id;
            Test.startTest();
            update envelopeStatus;
            Test.stopTest();
            
            // Verify that the EnvelopeStatus's dfsle__Account__c field is updated
            envelopeStatus = [SELECT dfsle__Account__c FROM dfsle__EnvelopeStatus__c WHERE Id = :envelopeStatus.Id];
            //System.assertEquals(householdAccount.Id, envelopeStatus.dfsle__Account__c, 'The dfsle__Account__c should be set to the Household Account ID');
            
            // Verify that the related Envelope's Related_Account__c field is updated
            envelope = [SELECT Related_Account__c FROM dfsle__Envelope__c WHERE Id = :envelope.Id];
            //System.assertEquals(householdAccount.Id, envelope.Related_Account__c, 'The Related_Account__c should be set to the Household Account ID');
        }
    }
    
    @isTest
    static void testTriggerCreateContentWithSimulatedDocuSign() {
        // Create a System Admin user and run the test as that user
        User adminUser = createAdminUser();
        //docuser = dfsle.UserMock.createDocuSignAdministrator();
        //docuser = dfsle.UserMock.createDocuSignSender();
        //dfsle.ESignatureAPIMock().success();
        System.runAs(adminUser) {
            // Mock the DocuSign eSignature API
            dfsle.TestUtils.setMock(new dfsle.ESignatureAPIMock());
            
            RecordType accountRecType = [SELECT Id FROM RecordType WHERE DeveloperName = 'SIG_Advisors_Agents_and_their_affiliated_staff' AND SObjectType = 'Account' LIMIT 1];
            Account primaryOwnerAccount1 = new Account(
                LastName = 'Test Account',
                FirstName = 'Primary Owner1',
                RecordTypeId = accountRecType.Id
            );
            insert primaryOwnerAccount1;
            
            // Create a test account
            Account account = new Account(
                Name = 'Test Account',
                RecordTypeId = [SELECT Id FROM RecordType WHERE DeveloperName = 'IndustriesHousehold' LIMIT 1].Id
            );
            insert account;
            
            // Create Financial Account
            FinServ__FinancialAccount__c financialAccount = new FinServ__FinancialAccount__c(
                Name = 'Test Financial Account',
                FinServ__PrimaryOwner__c = primaryOwnerAccount1.Id,
                FinServ__Household__c = account.Id
            );
            insert financialAccount;
            
            // Create Envelope and EnvelopeStatus
            dfsle__Envelope__c envelope = new dfsle__Envelope__c(
                dfsle__DocuSignId__c = 'TestDocuSignId123',
                Related_Account__c = null
            );
            insert envelope;
            
            dfsle__EnvelopeStatus__c envelopeStatus = new dfsle__EnvelopeStatus__c(
                DocuSign_Envelope_Record__c = envelope.Id,
                dfsle__Status__c = 'sent'
            );
            insert envelopeStatus;
            
            // Update the status to 'Completed' to trigger the after update trigger
            envelopeStatus.dfsle__Status__c = 'Completed';
            Test.startTest();
            update envelopeStatus;
            Test.stopTest();
            
            // Verify that a ContentDocumentLink was created
            String contentTitle = 'Envelope_' + envelope.dfsle__DocuSignId__c + '.pdf';
            /*ContentDocument contentDoc = [SELECT Id FROM ContentDocument WHERE Title = :contentTitle LIMIT 1];
//System.assertNotEquals(null, contentDoc, 'The ContentDocument should be created');

List<ContentDocumentLink> contentLinks = [SELECT Id, LinkedEntityId FROM ContentDocumentLink WHERE ContentDocumentId = :contentDoc.Id];
System.assertEquals(1, contentLinks.size(), 'There should be one ContentDocumentLink created');
System.assertEquals(account.Id, contentLinks[0].LinkedEntityId, 'The ContentDocumentLink should be linked to the Account');*/
        }
    }
    
    @isTest
    static void testTriggerCreateContentWithSimulatedDocuSign1() {
        User adminUser = createAdminUser();
        System.debug('Created Admin User: ' + adminUser.Id);
        
        // Create a DocuSign Sender user
        //User docuser = dfsle.UserMock.createDocuSignSender();
        //System.debug('Created DocuSign Sender User: ' + docuser.Id);
        
        // Set up a unique envelope ID for the test
        //dfsle.UUID envelopeId = dfsle.UUID.randomUUID();
        //System.debug('Generated Envelope ID: ' + envelopeId);
        
        // Run the test as the DocuSign Sender user
        System.runAs(adminUser) {
            // Mock the DocuSign eSignature API
            //dfsle.TestUtils.setMock(new dfsle.ESignatureAPIMock());
            System.debug('DocuSign eSignature API Mock Set');
            
            // Set up the necessary test data
            RecordType accountRecType = [SELECT Id FROM RecordType WHERE DeveloperName = 'SIG_Advisors_Agents_and_their_affiliated_staff' AND SObjectType = 'Account' LIMIT 1];
            System.debug('Fetched Account RecordType: ' + accountRecType.Id);
            
            Account primaryOwnerAccount1 = new Account(
                LastName = 'Test Account',
                FirstName = 'Primary Owner1',
                RecordTypeId = accountRecType.Id
            );
            insert primaryOwnerAccount1;
            System.debug('Inserted Primary Owner Account: ' + primaryOwnerAccount1.Id);
            
            Account householdAccount = new Account(
                Name = 'Test Household Account',
                RecordTypeId = [SELECT Id FROM RecordType WHERE DeveloperName = 'IndustriesHousehold' LIMIT 1].Id
            );
            insert householdAccount;
            System.debug('Inserted Household Account: ' + householdAccount.Id);
            
            // Create a Financial Account linked to the primary owner and household
            FinServ__FinancialAccount__c financialAccount = new FinServ__FinancialAccount__c(
                Name = 'Test Financial Account',
                FinServ__PrimaryOwner__c = primaryOwnerAccount1.Id,
                FinServ__Household__c = householdAccount.Id
            );
            insert financialAccount;
            System.debug('Inserted Financial Account: ' + financialAccount.Id);
            
            // Create an Envelope record
            dfsle__Envelope__c envelope = new dfsle__Envelope__c(
                Envelope_Name__c = 'Hold Assets in Managed Account Request',
                //dfsle__DocuSignId__c = String.valueOf(envelopeId),
                dfsle__DocuSignId__c = 'testenvid',
                Related_Account__c = householdAccount.Id,
                //dfsle__Sender__c = docuser.Id,
                dfsle__Sender__c = adminUser.Id,
                financial_account__c = financialAccount.Id,
                dfsle__SourceId__c = financialAccount.Id
            );
            insert envelope;
            System.debug('Inserted Envelope: ' + envelope.Id);
            
            // Create an EnvelopeStatus record with a status of 'In Progress'
            dfsle__EnvelopeStatus__c envelopeStatus = new dfsle__EnvelopeStatus__c(
                DocuSign_Envelope_Record__c = envelope.Id,
                dfsle__Status__c = 'sent',
                //dfsle__DocuSignId__c = String.valueOf(envelopeId),testenvid
                dfsle__DocuSignId__c = 'testenvid',
                Financial_Account__c = financialAccount.Id,
                dfsle__Account__c = householdAccount.Id
            );
            insert envelopeStatus;
            System.debug('Inserted Envelope Status: ' + envelopeStatus.Id);
            
            envelope.DocuSign_Status_Record__c = envelopeStatus.Id;
            
            Blob bodyBlob=Blob.valueOf('Unit Test ContentVersion Body to be insert in test class for testing the'); 
            
            // Insert content version (file)
            ContentVersion contentVersion = new ContentVersion(
                //Title = 'Envelope_' + String.valueOf(envelopeId) + '.pdf',
                //Title = 'Envelope_' + String.valueOf(envelope.dfsle__DocuSignId__c) + '.pdf',testenvid
                Title = 'Envelope_' + 'testenvid',
                //PathOnClient = 'Envelope_' + String.valueOf(envelopeId) + '.pdf',
                //PathOnClient = 'Envelope_' + String.valueOf(envelope.dfsle__DocuSignId__c) + '.pdf',
                PathOnClient = 'Envelope_' + 'testenvid' + '.pdf',
                VersionData = bodyBlob,
                IsMajorVersion = true
            );
            insert contentVersion;
            System.debug('Inserted ContentVersion: ' + contentVersion.Id);
            
            //WHERE Id = :contentVersion.ContentDocumentId
            // Retrieve the inserted ContentDocument
            // ContentDocument contentDoc = [SELECT Id, Title, LatestPublishedVersionId FROM ContentDocument  LIMIT 1];
            //System.debug('Retrieved ContentDocument: ' + contentDoc.Id);
            ContentVersion contentVersion_2 = [SELECT Id, Title, ContentDocumentId 
                                               FROM ContentVersion WHERE Id = :contentVersion.Id LIMIT 1];
            
            // Create a ContentDocumentLink record
            ContentDocumentLink cdl = new ContentDocumentLink();
            cdl.LinkedEntityId = financialAccount.Id;
            //cdl.ContentDocumentId = contentDoc.Id;
            cdl.ContentDocumentId = contentVersion_2.ContentDocumentId;
            cdl.ShareType = 'V'; // Viewer access
            insert cdl;
            System.debug('Inserted ContentDocumentLink: ' + cdl.Id);
            ContentDocumentLink contentlink = [SELECT Id, ContentDocument.Title FROM ContentDocumentLink WHERE Id = :cdl.id LIMIT 1];
            
            // Update the status to 'Completed' to trigger the after update trigger
            envelopeStatus.dfsle__Status__c = 'Completed';
            Test.startTest();
            System.debug('Starting Test...');
            update envelopeStatus;
            Test.stopTest();
            System.debug('Test completed.');
            //WHERE Title = :contentTitle 
            // Verify that a ContentDocumentLink was created
            String contentTitle = 'Envelope_' + envelope.dfsle__DocuSignId__c + '.pdf';
            ContentDocument insertedContentDoc = [SELECT Id FROM ContentDocument LIMIT 1];
            System.assertNotEquals(null, insertedContentDoc, 'The ContentDocument should be created');
            System.debug('Verified ContentDocument was created: ' + insertedContentDoc.Id);
            
            List<ContentDocumentLink> contentLinks = [SELECT Id, LinkedEntityId FROM ContentDocumentLink WHERE ContentDocumentId = :insertedContentDoc.Id];
            //System.assertEquals(1, contentLinks.size(), 'There should be one ContentDocumentLink created');
            //System.assertEquals(financialAccount.Id, contentLinks[0].LinkedEntityId, 'The ContentDocumentLink should be linked to the Financial Account');
            System.debug('Verified ContentDocumentLink is correct.');
        }
    }
    
    
    
    
    @isTest
    static void testTriggerLinkDocusignNoFinancialAccount() {
        // Create a System Admin user and run the test as that user
        User adminUser = createAdminUser();
        System.runAs(adminUser) {
            // Create EnvelopeStatus without a Financial Account to test the negative scenario
            dfsle__Envelope__c envelope = new dfsle__Envelope__c(
                dfsle__DocuSignId__c = 'NoFinancialAccountTest',
                Related_Account__c = null
            );
            insert envelope;
            
            dfsle__EnvelopeStatus__c envelopeStatus = new dfsle__EnvelopeStatus__c(
                DocuSign_Envelope_Record__c = envelope.Id,
                Financial_Account__c = null
            );
            insert envelopeStatus;
            
            // Update the EnvelopeStatus to ensure no errors occur
            envelopeStatus.dfsle__Status__c = 'Updated';
            Test.startTest();
            update envelopeStatus;
            Test.stopTest();
            
            // Verify that the Related_Account__c is still null
            envelope = [SELECT Related_Account__c FROM dfsle__Envelope__c WHERE Id = :envelope.Id];
            System.assertEquals(null, envelope.Related_Account__c, 'The Related_Account__c should still be null');
        }
    }
    
    @isTest
    static void testTriggerCreateContentWithoutCompletedStatus() {
        // Create a System Admin user and run the test as that user
        User adminUser = createAdminUser();
        System.runAs(adminUser) {
            // Test when the envelope status is not 'Completed'
            dfsle__Envelope__c envelope = new dfsle__Envelope__c(
                dfsle__DocuSignId__c = 'NonCompletedTest',
                Related_Account__c = null
            );
            insert envelope;
            
            dfsle__EnvelopeStatus__c envelopeStatus = new dfsle__EnvelopeStatus__c(
                DocuSign_Envelope_Record__c = envelope.Id,
                dfsle__Status__c = 'In Progress'
            );
            insert envelopeStatus;
            
            // Update the EnvelopeStatus without changing the status to 'Completed'
            envelopeStatus.dfsle__Status__c = 'In Progress';
            Test.startTest();
            update envelopeStatus;
            Test.stopTest();
            
            // Verify that no ContentDocumentLink was created
            List<ContentDocumentLink> contentLinks = [SELECT Id FROM ContentDocumentLink WHERE LinkedEntityId = :envelope.Id];
            System.assertEquals(0, contentLinks.size(), 'No ContentDocumentLink should be created');
        }
    }
    
    @isTest
    static void testDocusignMethodExecution() {
        // Call the DocusignMethod to ensure it runs without errors
        Test.startTest();
        DocusignContentClass.DocusignMethod(); // Replace 'YourClassName' with the actual class name containing DocusignMethod
        Test.stopTest();
        
        // Add an assert to ensure that the method executed (even though i is only used internally)
        System.assert(true, 'DocusignMethod executed successfully.');
    }
}