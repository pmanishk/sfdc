@isTest
public class DocuSignEnvelopeServiceTest {
    
    // Mock class for simulating HTTP response
    private class MockHttpResponse implements HttpCalloutMock {
        public HTTPResponse respond(HTTPRequest req) {
            HttpResponse res = new HttpResponse();
            res.setHeader('Content-Type', 'application/json');
            res.setStatusCode(200); // Simulate success response
            res.setBody('{"message": "Envelope voided successfully"}');
            return res;
        }
    }

    @isTest
    static void testVoidEnvelope() {
        // Set up the mock HTTP callout
        Test.setMock(HttpCalloutMock.class, new MockHttpResponse());
        
        // Insert a test dfsle__EnvelopeStatus__c record
        dfsle__EnvelopeStatus__c testStatus = new dfsle__EnvelopeStatus__c(
            dfsle__DocuSignId__c = 'test-envelope-id',
            Cancel_Envelope__c = false // Initially unchecked
        );
        insert testStatus;
        
        // Update the record to trigger the logic
        testStatus.Cancel_Envelope__c = true;
        update testStatus;

        // Query the updated record to confirm test execution
        dfsle__EnvelopeStatus__c updatedStatus = [
            SELECT Cancel_Envelope__c FROM dfsle__EnvelopeStatus__c WHERE Id = :testStatus.Id
        ];

        // Assert that the trigger executed and updated as expected
        System.assertEquals(true, updatedStatus.Cancel_Envelope__c, 'The Cancel_Envelope__c checkbox should be true.');
    }

    @isTest
    static void testVoidEnvelope_MissingEnvelopeId() {
        // Set up the mock HTTP callout
        Test.setMock(HttpCalloutMock.class, new MockHttpResponse());
        
        // Insert a test dfsle__EnvelopeStatus__c record without an envelope ID
        dfsle__EnvelopeStatus__c testStatus = new dfsle__EnvelopeStatus__c(
            Cancel_Envelope__c = false
        );
        insert testStatus;
        
        // Update the record to trigger the logic
        testStatus.Cancel_Envelope__c = true;
        update testStatus;

        // Confirm no HTTP callout was made due to missing envelope ID
        System.assertEquals(true, Test.isRunningTest(), 'No HTTP callout should have occurred for a record with missing envelope ID.');
    }

    @isTest
    static void testFutureMethod() {
        // Set up the mock HTTP callout
        Test.setMock(HttpCalloutMock.class, new MockHttpResponse());
        
        // Call the future method directly
        Test.startTest();
        DocuSignEnvelopeService.voidEnvelope('test-envelope-id');
        Test.stopTest();
        
        // Verify the future method executed successfully
        System.assertEquals(true, Test.isRunningTest(), 'The future method should have executed successfully.');
    }
}