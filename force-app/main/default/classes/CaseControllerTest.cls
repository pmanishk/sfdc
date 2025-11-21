@isTest
public class CaseControllerTest {
    @testSetup
    static void setupTestData() {
        // Create a Test Queue
        Group testQueue = new Group(Name = 'Test Queue', Type = 'Queue');
        insert testQueue;

        // Create a Parent Record (e.g., Account or any other parent object)
        //Account parentAccount = new Account(Name = 'Test Parent Account');
        //insert parentAccount;

        // Create Test File (ContentDocument and ContentVersion)
        ContentVersion contentVersion = new ContentVersion(
            Title = 'Test File',
            PathOnClient = 'testFile.txt',
            VersionData = Blob.valueOf('Test data for file upload')
        );
        insert contentVersion;

        // No need to query ContentDocument here; it's used later in the test
    }

    @isTest
    static void testGetQueueIdsByNames() {
        // Prepare test data for queue names
        String queueNames = 'Dynamic_case_queues';

        Test.startTest();
        Map<String, Id> queueIds = CaseController.getQueueIdsByNames(queueNames);
        Test.stopTest();
    }

    @isTest
    static void testCreateCaseAndLinkFile() {
        // Prepare test data
        //Account parentAccount = [SELECT Id FROM Account WHERE Name = 'Test Parent Account' LIMIT 1];
        List<ContentVersion> contentVersions = [SELECT Id, ContentDocumentId FROM ContentVersion LIMIT 1];
        ContentVersion contentVersion = contentVersions[0];

        Map<String, Object> caseFields = new Map<String, Object>{
            'Subject' => 'Test Case',
            'Description' => 'Test case for linking files.'
        };
        List<Id> fileIds = new List<Id>{contentVersion.ContentDocumentId};

        Test.startTest();
        Id caseId = CaseController.createCaseAndLinkFile(caseFields, fileIds, 'case', null);
        Test.stopTest();

        // Assert that Case is created
        Case createdCase = [SELECT Id, AccountId FROM Case WHERE Id = :caseId];
        System.assertNotEquals(null, createdCase, 'Case should be created.');
        //System.assertEquals(parentAccount.Id, createdCase.AccountId, 'Parent Account ID should be linked correctly.');

        // Assert that file is linked to Case
        List<ContentDocumentLink> linkedFiles = [SELECT ContentDocumentId FROM ContentDocumentLink WHERE LinkedEntityId = :caseId];
        System.assertEquals(1, linkedFiles.size(), 'One file should be linked to the Case.');

        // Assert that file is also present in the FeedItem
        List<FeedItem> feedItems = [SELECT Id, RelatedRecordId FROM FeedItem WHERE ParentId = :caseId];
        System.assertEquals(1, feedItems.size(), 'One feed item should be created.');
    }

    @isTest
    static void testGetDynamicFieldLabels() {
        // Prepare custom label directly in the test class
        String customLabelName = 'CaseFieldLabels';
        String customLabelValue = 'Subject:Case Subject,Description:Case Description';
        
        // Set the custom label value in a static way; this is just illustrative.
        // You might have to create the label via Setup instead.
        // System.Label.get(customLabelName).setValue(customLabelValue); // Not possible; custom labels cannot be set at runtime.

        // You can define the custom label manually for testing.
        // Note: This part assumes you've created a label named `CaseFieldLabels` with appropriate value beforehand.
        Map<String, String> expectedLabels = new Map<String, String>{
            'Subject' => 'Subject',
            'Description' => 'Description'
        };

        Test.startTest();
        Map<String, String> fieldLabels = CaseController.getDynamicFieldLabels('Dynamic_case_Fields'); // Pass the custom label name directly
        Test.stopTest();

        System.assertEquals(expectedLabels.get('Subject'), fieldLabels.get('Subject'), 'Field label for Subject should be retrieved correctly.');
        System.assertEquals(expectedLabels.get('Description'), fieldLabels.get('Description'), 'Field label for Description should be retrieved correctly.');
    }

    @isTest
    static void testDeleteUploadedFiles() {
        // Prepare test data for file deletion
        List<ContentVersion> contentVersions = [SELECT Id, ContentDocumentId FROM ContentVersion LIMIT 1];
        Id contentDocumentId = contentVersions[0].ContentDocumentId;
        List<Id> fileIds = new List<Id>{contentDocumentId};

        Test.startTest();
        CaseController.deleteUploadedFiles(fileIds);
        Test.stopTest();

        // Assert that the file is deleted
        List<ContentDocument> deletedFiles = [SELECT Id FROM ContentDocument WHERE Id IN :fileIds];
        System.assertEquals(0, deletedFiles.size(), 'File should be deleted successfully.');
    }
}