@isTest
private class CaseReviewerTabControllerTest {

    @testSetup
    static void setupTestData() {
        // Create a test Case
        Case testCase = new Case(
            Subject = 'Test Case',
            Status = 'New'
        );
        insert testCase;

        // Simulate field history tracking - can't insert CaseHistory directly
        // Instead, we update the field to generate history in orgs with tracking enabled
        testCase.Householding_Complete__c = true;
        update testCase;
    }

    @isTest
    static void testGetFieldSetFields() {
        // This test assumes the existence of a Field Set named 'Case_Reivewer_Tab_Fields' on Case object
        Test.startTest();
        List<String> fields = CaseReviewerTabController.getFieldSetFields();
        Test.stopTest();

        System.assertNotEquals(null, fields, 'Field list should not be null');
    }

    @isTest
    static void testGetFieldHistoryRecord() {
        Case testCase = [SELECT Id FROM Case LIMIT 1];

        Test.startTest();
        Id historyId = CaseReviewerTabController.getFieldHistoryRecord(testCase.Id);
        Test.stopTest();

        // Since CaseHistory can't be inserted in test, this may return null unless
        // field history tracking is enabled in org
        System.assertEquals(null, historyId, 'History ID should be null in test context without history tracking');
    }
}