@isTest
public class CaseFileSharingBatchTest {
	@testSetup
    static void setupTestData() {
        // Create a test EmailMessage record
        EmailMessage testEmail = new EmailMessage(
            Subject = 'Test Email',
            FromAddress = 'test@example.com',
            ToAddress = 'recipient@example.com',
            Status = '3' // Sent
        );
        insert testEmail;
        
        // Create a ContentVersion (this automatically creates a ContentDocument)
        ContentVersion testVersion = new ContentVersion(
            Title = 'Test Document',
            VersionData = Blob.valueOf('Test File Content'),
            PathOnClient = 'test.txt',
            FirstPublishLocationId = testEmail.Id
        );
        insert testVersion;

        // Query the ContentDocument safely
        List<ContentDocument> docList = [SELECT Id FROM ContentDocument WHERE Id = :testVersion.ContentDocumentId LIMIT 1];

        if (!docList.isEmpty()) {
            ContentDocument testDocument = docList[0];

            // **Step 1: Create a ContentDocumentLink for the Organization (00D)**
            ContentDocumentLink orgCDL = new ContentDocumentLink(
                ContentDocumentId = testDocument.Id,
                LinkedEntityId = UserInfo.getOrganizationId(), // Linking to Org (00D)
                ShareType = 'I',
                Visibility = 'AllUsers'
            );
            insert orgCDL; // This will trigger the condition: LinkedEntity.Type == '00D'

            // **Step 2: Create a ContentDocumentLink for the EmailMessage**
            ContentDocumentLink emailCDL = new ContentDocumentLink(
                ContentDocumentId = testDocument.Id,
                LinkedEntityId = testEmail.Id,
                ShareType = 'I',
                Visibility = 'AllUsers'
            );
            insert emailCDL;
        }
    }

    @isTest
    static void testContentDocumentLinkTrigger() {
        // Query ContentDocument safely
        List<ContentDocument> docList = [SELECT Id FROM ContentDocument LIMIT 1];
        Test.StartTest();
        	DataBase.executeBatch(new CaseFileSharingBatch());
        Test.StopTest();
    }
}