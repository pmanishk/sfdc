@IsTest(SeeAllData=true)
public class Test_DocusignObjController {

    @isTest
    static void testGetRelatedListRecords() {
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
            CompanyName='Sound Income Strategies LLC' // This should match the entity name in the Account (acc1)
        );
        insert testUser;
        
        // Step 1: Ensure a RecordType exists
        RecordType accountRecType = [SELECT Id FROM RecordType WHERE DeveloperName = 'SIG_Advisors_Agents_and_their_affiliated_staff' AND SObjectType = 'Account' and IsPersonType = true  LIMIT 1];
        System.assertNotEquals(null, accountRecType, 'Record Type SIG_Advisors_Agents_and_their_affiliated_staff should exist.');
        
        RecordType accountRecType1 = [SELECT Id FROM RecordType WHERE DeveloperName = 'IndustriesHousehold' AND SObjectType = 'Account' and IsPersonType = false LIMIT 1];
        System.assertNotEquals(null, accountRecType1, 'Record Type IndustriesHousehold should exist.');
        
        // Create a test Account with a RepAdvisorEntity__pc value
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
        // Create a test Account with a RepAdvisorEntity__pr value
        Account acc2 = new Account(
            Name = 'Sound Income Group', // This should match the User's CompanyName
            RecordTypeId = accountRecType2.Id,
            Industry = 'Test Industry',
            HHCurrentCash__c =5000,
            HHCurrentMktVal__c = 5000
        );
        insert acc2;
        
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
            RepAdvisorEntity__pc = acc2.Id // Ensure this matches the entityName parameter
        );
        insert account2;
        
        Contact con = new Contact(
            LastName = 'Test Contact 2',
            FirstName = 'Test Contact 2',
            RepAdvisorEntity__c = account1.Id // Ensure this matches the entityName parameter
        );
        insert con;        
        
        EAST_RepID__c repIDManagedTrue = new EAST_RepID__c(Name='Managed True', Unique_Name__c ='Managed True', Custodian__c='Fidelity', Managed__c=true, Primary_Rep_User__c=testUser.Id, Total_AUM__c =3.00);
        EAST_RepID__c repIDManagedFalse = new EAST_RepID__c(Name='Managed False', Unique_Name__c ='Managed False', Custodian__c='Schwab', Managed__c=false, Primary_Rep_User__c=testUser.Id, Total_AUM__c = 3.00);
        
        insert new List<EAST_RepID__c> { repIDManagedTrue, repIDManagedFalse };
            
            // Create Financial Account
            FinServ__FinancialAccount__c financialAccount = new FinServ__FinancialAccount__c(
                Name = 'Test Financial Account',
                FinServ__PrimaryOwner__c = acc2.Id,
                FinServ__JointOwner__c = account1.Id,
                FinServ__Household__c = acc1.Id,
                RepAdvisor__c = con.id,
                RepIDLink__c = repIDManagedFalse.id,
                RepID__c = repIDManagedFalse.Name,
                FinServ__Balance__c =5000
            );
        insert financialAccount;	
        
        // Create Financial Account
        FinServ__FinancialAccount__c financialAccount1 = new FinServ__FinancialAccount__c(
            Name = 'Test Financial Account11',
            FinServ__PrimaryOwner__c = acc2.Id,
            FinServ__JointOwner__c = account1.Id,
            FinServ__Household__c = acc1.Id,
            RepAdvisor__c = con.id,
            RepIDLink__c = repIDManagedTrue.id,            
            RepID__c = repIDManagedTrue.Name,
            FinServ__Balance__c =5000
        );
        insert financialAccount1;
        
        dfsle__Envelope__c parentRecord = new dfsle__Envelope__c(Envelope_Name__c = 'Test Parent', Financial_Account__c = financialAccount1.Id );
        insert parentRecord;
		
        dfsle__EnvelopeStatus__c dES = new dfsle__EnvelopeStatus__c(DocuSign_Envelope_Record__c=parentRecord.Id);
        insert dES;
        
        // Create related dfsle__RecipientStatus__c records
        dfsle__RecipientStatus__c recipientStatus1 = new dfsle__RecipientStatus__c(
            Name = 'Recipient 1',
            dfsle__RoutingOrder__c = 1,
            dfsle__Status__c = 'Sent',
            dfsle__Email__c = 'recipient1@example.com',
            dfsle__EnvelopeStatus__c = dES.Id // Assuming this is a valid relationship
        );

        dfsle__RecipientStatus__c recipientStatus2 = new dfsle__RecipientStatus__c(
            Name = 'Recipient 2',
            dfsle__RoutingOrder__c = 2,
            dfsle__Status__c = 'Completed',
            dfsle__Email__c = 'recipient2@example.com',
            dfsle__EnvelopeStatus__c = dES.Id // Assuming this is a valid relationship
        );

        insert new List<dfsle__RecipientStatus__c> { recipientStatus1, recipientStatus2 };

        // Step 2: Execute the method under test
        Test.startTest();
        List<dfsle__RecipientStatus__c> results = DocusignObjController.getRelatedListRecords(parentRecord.Id);
        Test.stopTest();

        // Step 3: Verify the results
        System.assertNotEquals(null, results, 'The result should not be null.');
        System.assertEquals(2, results.size(), 'There should be two recipient status records returned.');
        
        // Additional assertions to verify specific values can be added here
        System.assertEquals('Recipient 1', results[0].Name, 'The first recipient name should match.');
        System.assertEquals('recipient1@example.com', results[0].dfsle__Email__c, 'The email of the first recipient should match.');
    }

}