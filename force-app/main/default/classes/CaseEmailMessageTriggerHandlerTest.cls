@IsTest
public class CaseEmailMessageTriggerHandlerTest {

    static Profile primaryAgentProfile;
    static User primaryAgentUser;
    
    @TestSetup
    static void setupTestData() {
        // Query existing Primary Agent profile or create mock (usually standard profiles exist)
        primaryAgentProfile = [SELECT Id, Name FROM Profile WHERE Name = 'Primary Agent' LIMIT 1];
        
        // Create Primary Agent User for runAs context
        primaryAgentUser = new User(
            Username = 'primary.agent.' + DateTime.now().getTime() + '@test.com',
            Email = 'primary.agent@test.com',
            Alias = 'pagent',
            ProfileId = primaryAgentProfile.Id,
            TimeZoneSidKey = 'America/Los_Angeles',
            LocaleSidKey = 'en_US',
            EmailEncodingKey = 'UTF-8',
            LanguageLocaleKey = 'en_US',
            LastName = 'PrimaryAgent'
        );
        insert primaryAgentUser;
        
        // Create Household Account
        Account householdAccount = new Account(Name = 'Test Household Account');
        insert householdAccount;
        
        // Create open Case with Household Account for attachments linking
        Case caseWithHousehold = new Case(
            Subject = 'Open Case with Household',
            Status = 'New',
            Origin = 'Email',
            OwnerId = primaryAgentUser.Id,
            Household_Account__c = householdAccount.Id
        );
        insert caseWithHousehold;
        
        // Create open Case without Household Account
        Case caseWithoutHousehold = new Case(
            Subject = 'Open Case no Household',
            Status = 'New',
            Origin = 'Email',
            OwnerId = primaryAgentUser.Id
        );
        insert caseWithoutHousehold;
    }
    
    @IsTest
    static void testProcess_updatesCasesOnlyForPrimaryAgent() {
        System.runAs(primaryAgentUser) {
            // Query cases created by TestSetup
            List<Case> cases = [SELECT Id, IsClosed FROM Case WHERE OwnerId = :primaryAgentUser.Id LIMIT 2];
            
            // Create EmailMessages related to cases
            List<EmailMessage> emails = new List<EmailMessage>();
            for (Case c : cases) {
                emails.add(new EmailMessage(
                    ParentId = c.Id,
                    Subject = 'Test Email',
                    FromAddress = 'test@example.com',
                    ToAddress = 'agent@example.com'
                ));
            }
            insert emails;
            
            Test.startTest();
            CaseEmailMessageTriggerHandler.process(emails);
            Test.stopTest();
        }
    }
    
    @IsTest
    static void testProcess_doesNotUpdateForOtherProfiles() {
        // Use Standard User profile for negative test
        Profile standardUserProfile = [SELECT Id FROM Profile WHERE Name = 'Standard User' LIMIT 1];
        User stdUser = new User(
            Username = 'std.user.' + DateTime.now().getTime() + '@test.com',
            Email = 'std.user@test.com',
            Alias = 'stdu',
            ProfileId = standardUserProfile.Id,
            TimeZoneSidKey = 'America/Los_Angeles',
            LocaleSidKey = 'en_US',
            EmailEncodingKey = 'UTF-8',
            LanguageLocaleKey = 'en_US',
            LastName = 'StandardUser'
        );
        insert stdUser;
        
        System.runAs(stdUser) {
            List<Case> cases = [SELECT Id FROM Case LIMIT 1];
            EmailMessage em = new EmailMessage(
                ParentId = cases[0].Id,
                Subject = 'Test Email'
            );
            insert em;
            
            Test.startTest();
            CaseEmailMessageTriggerHandler.process(new List<EmailMessage>{em});
            Test.stopTest();
            
            Case c = [SELECT Override_Status__c FROM Case WHERE Id = :cases[0].Id];
            System.assertNotEquals('Customer Responded', c.Override_Status__c, 'Case status should not be updated for non Primary Agent');
        }
    }
    
    @IsTest
    static void testLinkEmailAttachmentsFilesToCase_linksContentDocuments() {
        System.runAs(primaryAgentUser) {
            // Query Case with Household Account created in setup
            Case caseWithHousehold = [SELECT Id FROM Case WHERE Household_Account__c != null LIMIT 1];
            
            EmailMessage em = new EmailMessage(
                ParentId = caseWithHousehold.Id,
                Subject = 'Email With Attachment',
                FromAddress = 'sender@example.com',
                ToAddress = 'recipient@example.com'
            );
            insert em;
            
            // Create ContentVersion (file) to produce ContentDocument and ContentDocumentLink
            ContentVersion cv = new ContentVersion(
                Title = 'TestFile.txt',
                PathOnClient = 'TestFile.txt',
                VersionData = Blob.valueOf('Test file contents')
            );
            insert cv;
            cv = [SELECT Id, ContentDocumentId FROM ContentVersion WHERE Id = :cv.Id];
            
            // Attach file to EmailMessage
            ContentDocumentLink cdlEmail = new ContentDocumentLink(
                ContentDocumentId = cv.ContentDocumentId,
                LinkedEntityId = em.Id,
                ShareType = 'V'
            );
            insert cdlEmail;
            
            // Call method to link attachments to Case
            List<EmailMessage> emails = [SELECT Id, ParentId FROM EmailMessage WHERE Id = :em.Id];
            
            Test.startTest();
            CaseEmailMessageTriggerHandler.linkEmailAttachmentsFilesToCase(emails);
            Test.stopTest();
            
            // Verify ContentDocumentLink now created to Case as well
            List<ContentDocumentLink> caseLinks = [
                SELECT ContentDocumentId, LinkedEntityId FROM ContentDocumentLink
                WHERE LinkedEntityId = :caseWithHousehold.Id AND ContentDocumentId = :cv.ContentDocumentId
            ];
            System.assert(!caseLinks.isEmpty(), 'ContentDocumentLink to Case should be created from EmailMessage attachment');
        }
    }
    
    @IsTest
    static void testLinkEmailAttachmentsFilesToCase_noHouseholdCase_noLinkCreated() {
        System.runAs(primaryAgentUser) {
            Case caseWithoutHousehold = [SELECT Id FROM Case WHERE Household_Account__c = null LIMIT 1];
            
            EmailMessage em = new EmailMessage(
                ParentId = caseWithoutHousehold.Id,
                Subject = 'Email Without Household',
                FromAddress = 'sender@example.com',
                ToAddress = 'recipient@example.com'
            );
            insert em;
            
            List<EmailMessage> emails = [SELECT Id, ParentId FROM EmailMessage WHERE Id = :em.Id];
            
            Test.startTest();
            CaseEmailMessageTriggerHandler.linkEmailAttachmentsFilesToCase(emails);
            Test.stopTest();
            
            // No ContentDocumentLink should be created for Case without Household
            List<ContentDocumentLink> caseLinks = [
                SELECT Id FROM ContentDocumentLink WHERE LinkedEntityId = :caseWithoutHousehold.Id
            ];
            System.assert(caseLinks.isEmpty(), 'No ContentDocumentLink should be created for cases without Household Account');
        }
    }
    
    @IsTest
    static void testProcess_emptyEmailList_noError() {
        System.runAs(primaryAgentUser) {
            Test.startTest();
            CaseEmailMessageTriggerHandler.process(new List<EmailMessage>());
            Test.stopTest();
        }
    }
    
    @IsTest
    static void testLinkEmailAttachmentsFilesToCase_emptyEmailList_noError() {
        System.runAs(primaryAgentUser) {
            Test.startTest();
            CaseEmailMessageTriggerHandler.linkEmailAttachmentsFilesToCase(new List<EmailMessage>());
            Test.stopTest();
        }
    }
}