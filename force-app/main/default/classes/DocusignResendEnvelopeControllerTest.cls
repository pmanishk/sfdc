@IsTest(SeeAllData=true)
public class DocusignResendEnvelopeControllerTest {
   @IsTest
    static void setup() {
         // Step 1: Ensure a RecordType exists
        RecordType accountRecType = [SELECT Id FROM RecordType WHERE DeveloperName = 'SIG_Advisors_Agents_and_their_affiliated_staff' AND SObjectType = 'Account' and IsPersonType = true  LIMIT 1];
        System.assertNotEquals(null, accountRecType, 'Record Type SIG_Advisors_Agents_and_their_affiliated_staff should exist.');

        RecordType accountRecType1 = [SELECT Id FROM RecordType WHERE DeveloperName = 'IndustriesHousehold' AND SObjectType = 'Account' and IsPersonType = false LIMIT 1];
        System.assertNotEquals(null, accountRecType1, 'Record Type IndustriesHousehold should exist.');
        // Create a test Account with a RepAdvisorEntity__pc value
        Account acc1 = new Account(
            Name = 'Docusign', // The value that will match the entityName parameter
            RecordTypeId = accountRecType1.Id, // Ensure this record type is valid for the user profile
            Industry = 'Engineering',
            SIS_Advisor_Affiliation__c='Sub-Advisor',
            RIA_Firm__c ='Docusign'
        );
        insert acc1;
        
		RecordType accountRecType2 = [SELECT Id FROM RecordType WHERE DeveloperName = 'SIG_Advisors_Agents_Business_Name' AND SObjectType = 'Account' and IsPersonType = false LIMIT 1];
        System.assertNotEquals(null, accountRecType1, 'Record Type SIG_Advisors_Agents_Business_Name should exist.');
        // Create a test Account with a RepAdvisorEntity__pr value
        Account acc2 = new Account(
            Name = 'Docusign', // This should match the User's CompanyName
            RecordTypeId = accountRecType2.Id,
            Industry = 'Test Industry'
        );
        insert acc2;
        
        // Create Accounts that reference the above entities
        Account account1 = new Account(
            LastName = 'Test Account 1',
            FirstName = 'Test Account 1',
            Industry = 'Test Industry',
            RecordTypeId = accountRecType.Id, // Ensure this record type is valid for the user profile
            RepAdvisorEntity__pc = acc2.Id // Ensure this matches the entityName parameter
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
        
        Contact con = new Contact(
            LastName = 'Test Contact 2',
            FirstName = 'Test Contact 2',
            RepAdvisorEntity__c = acc2.Id // Ensure this matches the entityName parameter
        );
        insert con;
        
        // Create Financial Account
        FinServ__FinancialAccount__c financialAccount = new FinServ__FinancialAccount__c(
            Name = 'Test Financial Account',
            FinServ__PrimaryOwner__c = acc2.Id,
            FinServ__JointOwner__c = account1.Id,
            FinServ__Household__c = acc1.Id,
            RepAdvisor__c = con.id
        );
        insert financialAccount;	
        
        // Create Financial Account
        FinServ__FinancialAccount__c financialAccount1 = new FinServ__FinancialAccount__c(
           Name = 'Test Financial Account11',
            FinServ__PrimaryOwner__c = acc2.Id,
            FinServ__JointOwner__c = account1.Id,
            FinServ__Household__c = acc1.Id,
            RepAdvisor__c = con.id
        );
        insert financialAccount1;
        
        // Create Envelope Status records
        dfsle__EnvelopeStatus__c envelopeStatus1 = new dfsle__EnvelopeStatus__c(dfsle__Account__c=account1.Id, dfsle__Status__c='Sent');
        dfsle__EnvelopeStatus__c envelopeStatus2 = new dfsle__EnvelopeStatus__c(dfsle__Account__c=account2.Id, dfsle__Status__c='Completed');        
        dfsle__EnvelopeStatus__c envelopeStatus3 = new dfsle__EnvelopeStatus__c(dfsle__Account__c=account1.Id, dfsle__Status__c='Completed');
        
        insert new List<dfsle__EnvelopeStatus__c> { envelopeStatus1, envelopeStatus2, envelopeStatus3 };
		
             // Create Envelope records associated with these accounts
        dfsle__Envelope__c envelope1 = new dfsle__Envelope__c(
            CreatedDate = System.now(),
            Financial_Account__c = financialAccount.Id,
            DocuSign_Status_Record__c = envelopeStatus1.id
        );
        
        dfsle__Envelope__c envelope2 = new dfsle__Envelope__c(
            CreatedDate = System.now().addDays(-1),
            Financial_Account__c = financialAccount1.Id,
            DocuSign_Status_Record__c = envelopeStatus2.id
        );
        
        dfsle__Envelope__c envelope3 = new dfsle__Envelope__c(
            CreatedDate = System.now().addDays(-1),
            Financial_Account__c = financialAccount.Id,
            DocuSign_Status_Record__c = envelopeStatus3.id
        );

        insert new List<dfsle__Envelope__c> { envelope1, envelope2, envelope3 };
        // Create test envelope status records
        List<dfsle__EnvelopeStatus__c> testStatuses = new List<dfsle__EnvelopeStatus__c>{
            new dfsle__EnvelopeStatus__c(
                dfsle__DocuSignId__c = envelope1.Id,
                dfsle__Status__c = 'Sent'
            ),
            new dfsle__EnvelopeStatus__c(
                dfsle__DocuSignId__c = envelope2.Id,
                dfsle__Status__c = 'Completed'
            )
        };
        insert testStatuses;
    }

    @IsTest
    static void testResendEnvelope_Success() {
        setup();
        // Mock successful HTTP response
        Test.setMock(HttpCalloutMock.class, new HttpSuccessMock());
        
        Test.startTest();
        DocusignResendEnvelopeController controller = new DocusignResendEnvelopeController();
        controller.docuSignId = [Select dfsle__DocuSignId__c from dfsle__EnvelopeStatus__c limit 1].dfsle__DocuSignId__c;
        PageReference result = controller.resendEnvelope();
        Test.stopTest();

        System.assertEquals(null, result, 'Should not redirect');
        System.assertEquals('Envelope resent successfully.', controller.message);
    }

    @IsTest
    static void testResendEnvelope_HttpFailure() {
        setup();
        Test.setMock(HttpCalloutMock.class, new HttpFailureMock());
        
        Test.startTest();
        DocusignResendEnvelopeController controller = new DocusignResendEnvelopeController();
        controller.docuSignId = [Select dfsle__DocuSignId__c from dfsle__EnvelopeStatus__c limit 1].dfsle__DocuSignId__c;
        controller.resendEnvelope();
        Test.stopTest();

        System.assertEquals('Failed to resend the envelope.', controller.message);
    }

    private class HttpSuccessMock implements HttpCalloutMock {
        public HttpResponse respond(HttpRequest req) {
            HttpResponse res = new HttpResponse();
            res.setStatusCode(200);
            res.setBody('{"status":"sent"}');
            return res;
        }
    }

    private class HttpFailureMock implements HttpCalloutMock {
        public HttpResponse respond(HttpRequest req) {
            HttpResponse res = new HttpResponse();
            res.setStatusCode(400);
            res.setBody('{"error":"Bad request"}');
            return res;
        }
    }
}