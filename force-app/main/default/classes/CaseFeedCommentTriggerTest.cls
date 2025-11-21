@isTest
public class CaseFeedCommentTriggerTest {
    
    @isTest
    static void testAfterInsert() {
        // Step 1: Create a Profile and assign it to the current User
        Profile p = [SELECT Id FROM Profile WHERE Name='Primary Agent' LIMIT 1];
        User u = new User(
            Username = 'testuser789@domain.com',
            Email = 'testuser@domain.com.test',
            Alias = 'test',
            ProfileId = p.Id,
            TimeZoneSidKey = 'America/Los_Angeles',
            EmailEncodingKey = 'UTF-8',
            LanguageLocaleKey = 'en_US',
            LocaleSidKey = 'en_US',
            LastName = 'Test',
            FirstName= 'User'
        );
        insert u;
        // Step 2: Create a Case
        Case caseRecord = new Case(
            Subject = 'Test Case',
            Status = 'New'
        );
        insert caseRecord;

        //Step 3: Give caseShare access to the user
        CaseShare caseShareRecord = new CaseShare();
        caseShareRecord.CaseId = caseRecord.Id;
        caseShareRecord.UserOrGroupId = u.Id;
        caseShareRecord.CaseAccessLevel = 'Edit';
        caseShareRecord.RowCause = Schema.CaseShare.RowCause.Manual;
        insert caseShareRecord;
        System.runAs(u) {
             Test.startTest();
            
            // Step 4: Create a FeedItem related to the Case
            FeedItem feedItem = new FeedItem(
                ParentId = caseRecord.Id,
                Body = 'Test feed item'
            );
            insert feedItem;

            // Step 5: Create a FeedComment for the FeedItem
            FeedComment comment = new FeedComment(
                FeedItemId = feedItem.Id,
                CommentBody = 'Test feed comment'
            );
            insert comment;
           
            Test.stopTest();

            // Step 6: Verify the Case status is updated
            Case updatedCase = [SELECT Id, Status,Override_status__c FROM Case WHERE Id = :caseRecord.Id];
            System.assertEquals('Customer Responded', updatedCase.Override_status__c);
        }
    }
}