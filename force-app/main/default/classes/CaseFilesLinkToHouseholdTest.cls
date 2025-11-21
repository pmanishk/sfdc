@IsTest(SeeAllData=true)
public class CaseFilesLinkToHouseholdTest {
    static Id householdId;
    static Id caseId;
    static Id docId;
    static Id emailMsgId;
    static Id contentDocId;
    
    @IsTest 
    public static void setupTestData() {       
        RecordType accountRecType = [SELECT Id FROM RecordType WHERE DeveloperName = 'SIG_Advisors_Agents_and_their_affiliated_staff' AND SObjectType = 'Account' and IsPersonType = true  LIMIT 1];
        System.assertNotEquals(null, accountRecType, 'Record Type SIG_Advisors_Agents_and_their_affiliated_staff should exist.');
        
        RecordType accountRecType1 = [SELECT Id FROM RecordType WHERE DeveloperName = 'IndustriesHousehold' AND SObjectType = 'Account' and IsPersonType = false LIMIT 1];
        System.assertNotEquals(null, accountRecType1, 'Record Type IndustriesHousehold should exist.');
        
        Account acc1 = new Account(
            Name = 'TestEntity', 
            RecordTypeId = accountRecType1.Id, // Ensure this record type is valid for the user profile
            Industry = 'Engineering',
            SIS_Advisor_Affiliation__c='Sub-Advisor',
            RIA_Firm__c ='TestEntity',
            HHCurrentCash__c =5000,
            HHCurrentMktVal__c = 5000
        );
        insert acc1;
        
        RecordType accountRecType2 = [SELECT Id FROM RecordType WHERE DeveloperName = 'SIG_Advisors_Agents_Business_Name' AND SObjectType = 'Account' and IsPersonType = false LIMIT 1];
        System.assertNotEquals(null, accountRecType2, 'Record Type SIG_Advisors_Agents_Business_Name should exist.');
        Account acc2 = new Account(
            Name = 'TestEntity SIG', // This should match the User's CompanyName
            RecordTypeId = accountRecType2.Id,
            Industry = 'Test Industry',
            HHCurrentCash__c =5000,
            HHCurrentMktVal__c = 5000
        );
        insert acc2;
        
        Account account1 = new Account(
            LastName = 'Test Account 1',
            FirstName = 'Test Account 1',
            Industry = 'Test Industry',
            RecordTypeId = accountRecType.Id, // Ensure this record type is valid for the user profile
            RepAdvisorEntity__pc = acc1.Id // Ensure this matches the entityName parameter
        );
        insert account1;
        
        Account account2 = new Account(
            LastName = 'Test Account 2',
            FirstName = 'Test Account 2',
            Industry = 'Test Industry',
            RecordTypeId = accountRecType.Id, // Ensure this record type is valid for the user profile
            RepAdvisorEntity__pc = acc2.Id // Ensure this matches the entityName parameter
        );
        insert account2;
        User testUser = new User(
            Username = 'testuser_' + System.currentTimeMillis() + '@example.com',
            Email = 'testuser@example.com',
            Alias = 'tuser',
            LastName = 'Test User',
            TimeZoneSidKey = 'America/Los_Angeles',
            LocaleSidKey = 'en_US',
            EmailEncodingKey = 'UTF-8',
            LanguageLocaleKey = 'en_US',
            ProfileId = [SELECT Id FROM Profile WHERE Name='System Administrator' LIMIT 1].Id,
            CompanyName='Sound Income Strategies LLC',
            RepAdvisorId__c =acc1.Id
        );
        insert testUser;
        
        Contact cont = new Contact(FirstName='Test', LastName='Contact', Email='testcontact@example.com', AccountId=acc2.Id);
		insert cont;
        
        // Create Cases
        Case case1 = new Case(Status='Working', Household_Account__c=acc1.Id, ContactId=cont.Id);
        Case case2 = new Case(Status='Closed', Household_Account__c=acc1.Id, ContactId=cont.Id);
        Case case3 = new Case(Status='New', Household_Account__c=acc1.Id, ContactId=cont.Id);
        insert new List<Case>{case1, case2, case3};
            
            // Create a ContentVersion (this creates a ContentDocument)
            ContentVersion cv = new ContentVersion(
                Title = 'Test File',
                PathOnClient = 'TestFile.txt',
                VersionData = Blob.valueOf('Test file content')
            );
        insert cv;
        
        // Query the ContentDocumentId
        cv = [SELECT Id, ContentDocumentId FROM ContentVersion WHERE Id = :cv.Id];
        
        // Link the file to the Case
        ContentDocumentLink cdl = new ContentDocumentLink(
            ContentDocumentId = cv.ContentDocumentId,
            LinkedEntityId = case1.Id,
            ShareType = 'V',
            Visibility = 'AllUsers'
        );
        insert cdl;
        
        // Store Ids for use in test method
        householdId = acc1.Id;
        caseId = case1.Id;
        docId = cv.ContentDocumentId;
    
        
        // EmailMessage related to that Case
        EmailMessage em = new EmailMessage(
            Subject = 'Test Email',
            FromAddress = 'test@example.com',
            ToAddress = 'to@example.com',
            ParentId = case1.Id,
            Status = '0'
        );
        insert em;
        

        ContentVersion insertedCV = [
            SELECT ContentDocumentId FROM ContentVersion WHERE Id = :cv.Id LIMIT 1
        ];
        
        // Link the file to the EmailMessage (not to Case yet)
        ContentDocumentLink cdl1 = new ContentDocumentLink(
            ContentDocumentId = insertedCV.ContentDocumentId,
            LinkedEntityId = em.Id,
            ShareType = 'V'
        );
        insert cdl1;
        
        emailMsgId = em.Id;
        contentDocId = insertedCV.ContentDocumentId;
    }
    
    // === Tests for linkEmailAttachmentsFilesToCase ===
    @isTest
    static void testNullInput() {
        // Should not throw
        Test.startTest();
        CaseFilesLinkToHousehold.linkEmailAttachmentsFilesToCase(null);
        Test.stopTest();
    }
    
    @isTest
    static void testEmptyList() {
        // Should not throw
        Test.startTest();
        CaseFilesLinkToHousehold.linkEmailAttachmentsFilesToCase(new List<Case>());
        Test.stopTest();
    }
    
    @isTest
    static void testNoHouseholdOnCase() {
        setupTestData();
        Case c = [SELECT Id , Household_Account__c FROM Case LIMIT 1];
        ContentDocumentLink cdl = new ContentDocumentLink(
            ContentDocumentId = contentDocId, LinkedEntityId = c.Id, ShareType = 'V');
        insert cdl;
        List<Case> cases = new List<Case>{c};
        Test.startTest();
        CaseFilesLinkToHousehold.linkEmailAttachmentsFilesToCase(cases);
        Test.stopTest();
        // Should not have created any ContentDocumentLinks for this case
        System.assertEquals(1, [SELECT COUNT() FROM ContentDocumentLink WHERE LinkedEntityId = :c.Id]);
    }
    
    @isTest
    static void testNoEmailMessages() { 
        setupTestData();
        Case c = [SELECT Id , Household_Account__c FROM Case LIMIT 1];
        ContentDocumentLink cdl = new ContentDocumentLink(
            ContentDocumentId = contentDocId, LinkedEntityId = c.Id, ShareType = 'V');
        insert cdl;
        List<Case> cases = new List<Case>{c};
        Test.startTest();
        CaseFilesLinkToHousehold.linkEmailAttachmentsFilesToCase(cases);
        Test.stopTest();
        System.assertEquals(1, [SELECT COUNT() FROM ContentDocumentLink WHERE LinkedEntityId = :c.Id]);
    }
    
    @isTest
    static void testEmailMessageNoAttachment() {  setupTestData();
        Account acc = [SELECT Id  FROM Account LIMIT 1];
        Case c = new Case(Status = 'Working', Household_Account__c = acc.Id);
        insert c;
        EmailMessage em = new EmailMessage(
            Subject = 'NoAttachment',
            FromAddress = 'noreply@fake.com',
            ToAddress = 'to@fake.com',
            ParentId = c.Id,
            Status = '0'
        );
        insert em;
        List<Case> cases = new List<Case>{c};
        Test.startTest();
        CaseFilesLinkToHousehold.linkEmailAttachmentsFilesToCase(cases);
        Test.stopTest();
        // No ContentDocumentLink should be created for the case.
        System.assertEquals(0, [SELECT COUNT() FROM ContentDocumentLink WHERE LinkedEntityId = :c.Id]);
    }
    
    @isTest
    static void testContentDocumentAlreadyLinked() { setupTestData();
        // If the Case already has the ContentDocumentLink, should not create duplicate
        Case c = [SELECT Id , Household_Account__c FROM Case LIMIT 1];
        // Artificially link the ContentDocument to the Case directly already
        ContentDocumentLink cdl = new ContentDocumentLink(
            ContentDocumentId = contentDocId, LinkedEntityId = c.Id, ShareType = 'V');
        insert cdl;
        List<Case> cases = new List<Case>{c};
        Test.startTest();
        CaseFilesLinkToHousehold.linkEmailAttachmentsFilesToCase(cases);
        Test.stopTest();
        // Still only 1 link should be present (not duplicated)
        List<ContentDocumentLink> links =
            [SELECT Id FROM ContentDocumentLink WHERE LinkedEntityId = :c.Id AND ContentDocumentId = :contentDocId];
        System.assertEquals(1, links.size(), 'Should not duplicate existing ContentDocumentLink');
    }
    
    @isTest
    static void testHappyPath() { setupTestData();
        // Fresh case from testSetup
        Case c = [SELECT Id, Household_Account__c FROM Case LIMIT 1];
        List<Case> cases = new List<Case>{c};
        
        Test.startTest();
        CaseFilesLinkToHousehold.linkEmailAttachmentsFilesToCase(cases);
        Test.stopTest();
    }
    
    // Optional: bulk/multi-case scenario
    @isTest
    static void testMultipleCasesBulk() { setupTestData();
        // Case 1 with HH and EmailAttachment (already present from setup)
        Case c1 = [SELECT Id, Household_Account__c FROM Case LIMIT 1];
        
        Account acc = [SELECT Id  FROM Account LIMIT 1];
        Case c2 = new Case(Status = 'Working', Household_Account__c = acc.Id);
        insert c2;
        EmailMessage em2 = new EmailMessage(
            Subject = 'Another Email',
            FromAddress = 'a@b.com',
            ToAddress = 'b@a.com',
            ParentId = c2.Id,
            Status = '0'
        );
        insert em2;
        ContentVersion cv2 = new ContentVersion(Title = 'AnotherFile.txt', PathOnClient='AnotherFile.txt', VersionData = Blob.valueOf('File2'));
        insert cv2;
        ContentVersion cv2db = [SELECT ContentDocumentId FROM ContentVersion WHERE Id = :cv2.Id];
        ContentDocumentLink cdl2 = new ContentDocumentLink(ContentDocumentId=cv2db.ContentDocumentId, LinkedEntityId=em2.Id, ShareType='V');
        insert cdl2;
        
        List<Case> cases = new List<Case>{c1, c2};
        Test.startTest();
        CaseFilesLinkToHousehold.linkEmailAttachmentsFilesToCase(cases);
        Test.stopTest();
    }
    @isTest
    static void testInsertCaseWithoutHousehold() {
        // Insert a Case without Household_Account__c
        Case c = new Case(Status='Working');
        insert c;
        // No ContentDocumentLink should be created for a household
        // (You can assert this if you want)
    }
    
    @isTest
    static void testUpdateCaseWithoutChangingHousehold() {
        setupTestData();
        Case c = [SELECT Id , Household_Account__c FROM Case LIMIT 1];
        // Update the case, but don't change Household_Account__c
        c.Status = 'Closed';
        update c;
        // Nothing new should happen; you can assert no extra links are created
    }
    @isTest
    static void testCaseSharingTriggerUpdateAccount1() {
       	test.startTest();
        Account acc = [Select id, repAdvisor__r.repAdvisorEntity__c from Account where isPersonAccount=true and repAdvisor__r.repAdvisorEntity__c !='' limit 1];
        Case c = [Select id, AccountId from case where accountId !='' and accountId != :acc.id and account.repAdvisor__r.repAdvisorEntity__c != :acc.repAdvisor__r.repAdvisorEntity__c limit 1];
        if(acc != null && c !=null){
            c.accountId = acc.id;
        	Update c;
        }
        
        test.stopTest();
    }
    
    @isTest
    static void testCaseSharingTriggerUpdateHouseHold() {
       	test.startTest();
        Account acc = [Select id, repAdvisor__r.repAdvisorEntity__c from Account where isPersonAccount=false and repAdvisor__r.repAdvisorEntity__c !='' limit 1];
        Case c = [Select id, AccountId from case where accountId !='' and Household_Account__c != :acc.id and Household_Account__r.repAdvisor__r.repAdvisorEntity__c != :acc.repAdvisor__r.repAdvisorEntity__c limit 1];
        if(acc != null && c !=null){
            c.Household_Account__c = acc.id;
        	Update c;
        }
        test.stopTest();
    }
    
    @isTest
    static void testCaseSharingTriggerUpdateContact() {
       	test.startTest();
        Contact con = [Select id, repAdvisorEntity__c from Contact where repAdvisorEntity__c !='' limit 1];
        Case c = [Select id, ContactId from case where ContactId !='' and ContactId != :con.id and contact.repAdvisorEntity__c != :con.repAdvisorEntity__c limit 1];
        if(con != null && c !=null){
            c.ContactId = con.id;
        	Update c;
        }
        test.stopTest();
    }
    
   	@isTest
    static void testXFP_ExportCaseFiles() {
        Account account1 = [SELECT Id FROM Account LIMIT 1];
        Contact con = [SELECT Id FROM Contact LIMIT 1];
        // Create test Cases
        List<Case> testCases = new List<Case>();
        for (Integer i = 0; i < 3; i++) {
            testCases.add(new Case(Subject = 'Test Case ' + i, Status = 'New', Priority = 'High', AccountId = account1.Id, ContactId = con.Id));
        }
        insert testCases;

        // Insert ContentVersion records which automatically create ContentDocument
        List<ContentDocumentLink> cdlList = new List<ContentDocumentLink>();

        for (Integer i = 0; i < 3; i++) {
            ContentVersion cv = new ContentVersion();
            cv.VersionData = Blob.valueOf('a'.repeat(5282));
            cv.Title = 'Test Document ' + i;
            cv.PathOnClient = 'TestDocument' + i + '.txt';
            insert cv;

            // Query the ContentDocumentId from the inserted ContentVersion
            ContentVersion insertedCv = [SELECT ContentDocumentId, ContentSize, FileType FROM ContentVersion WHERE Id = :cv.Id LIMIT 1];

            // Insert ContentDocumentLink linking file to Case
            cdlList.add(new ContentDocumentLink(
                LinkedEntityId = testCases[i].Id,
                ContentDocumentId = insertedCv.ContentDocumentId,
                ShareType = 'V',
                Visibility = 'AllUsers'
            ));
        }
        
		insert cdlList;
        
        // Clear the exportedCDLs static set before test
        XFP_CaseFilesExportHandler.exportedCDLs.clear();

        Test.startTest();
        // Call method under test
        XFP_CaseFilesExportHandler.XFP_ExportCaseFiles(testCases);
        
        Test.stopTest();
    }
    
    @IsTest
    static void updateAccout(){
        Account account1 = [SELECT Id FROM Account LIMIT 1];
        account1.AccountNumber = 'sfdsd';
        
        Test.startTest();
        update account1;
        Test.stopTest();
    }
}