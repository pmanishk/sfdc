@IsTest(SeeAllData=true)
public class Test_XFPRenamingFeature {
     @isTest
    static void setupTestData(){
        // Create Cloud Storage Provider
        XFILES__Cloud_Storage_Provider__c csp = new XFILES__Cloud_Storage_Provider__c();
        csp.Name = 'Corporate SharePoint';
        csp.XFILES__Password__c = XFILES.XfileCryptoController.encrypt('wjfUKkaNiCiu9bk5kKdnIuavMlxmjs2n9jb7ZrLjZNZDlp5MdmGjkfXZcCi9BJxpL5e1SBHUz2Z/0SQO09Yhmg==');
        csp.XFILES__Service_Endpoint_URL__c = 'https://soundincomegroup--sis.sandbox.my.salesforce.com';        
        csp.XFILES__Username__c = XFILES.XfileCryptoController.encrypt('AKIAI3DX547EUHK3KW7A');
        csp.XFILES__Root_Folder_Name__c = 'Soundincome';
        csp.XFILES__Provider_Type__c = 'SharePoint';
        csp.XFILES__API_Auth_Token__c = XFILES.XfileCryptoController.encrypt('1/nYxDFH6JyXayC_KRcyL2ihrcMhcQ7mIEBnP9sejDQhw');
        csp.XFILES__Prefix__c = 'soundincome.sharepoint.com,3abb73e4-53d1-445f-8577-c3fa989edf14,c86ebf15-1e18-4564-94c4-c1e4267f5368';
        insert csp;
          
        // Step 1: Ensure a RecordType exists
        RecordType accountRecType = [SELECT Id FROM RecordType WHERE DeveloperName = 'SIG_Advisors_Agents_and_their_affiliated_staff' AND SObjectType = 'Account' and IsPersonType = true  LIMIT 1];
        System.assertNotEquals(null, accountRecType, 'Record Type SIG_Advisors_Agents_and_their_affiliated_staff should exist.');
        
        RecordType accountRecType1 = [SELECT Id FROM RecordType WHERE DeveloperName = 'SIG_Advisors_Agents_Business_Name' AND SObjectType = 'Account' and IsPersonType = false LIMIT 1];
        System.assertNotEquals(null, accountRecType1, 'Record Type SIG_Advisors_Agents_Business_Name should exist.');
        // Create a test Account with a RepAdvisorEntity__pc value
        Account acc1 = new Account(
            Name = 'TestEntity', // The value that will match the entityName parameter
            RecordTypeId = accountRecType1.Id, // Ensure this record type is valid for the user profile
            Industry = 'Engineering',
            SIS_Advisor_Affiliation__c='Sub-Advisor',
            RIA_Firm__c ='TestEntity'
        );
        insert acc1;
        
        
        // Create Accounts that reference the above entities
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
            RepAdvisorEntity__pc = acc1.Id // Ensure this matches the entityName parameter
        );
        insert account2;
        Contact con = new Contact(
            LastName = 'Test Contact 2',
            FirstName = 'Test Contact 2',
            Email = 'test@gmail.com',
            RepAdvisorEntity__c = account1.Id // Ensure this matches the entityName parameter
        );
        insert con;      
        // Create Cases associated with the accounts
        Case testCase = new Case(Subject = 'Test Case 1', Status = 'New', Priority = 'High', AccountId = account1.Id, ContactId = con.Id);
        insert new List<Case> { testCase };
        
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