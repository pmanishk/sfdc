@isTest(SeeAllData=true)
public class AdvisorMatrixPageControllerTest {
    @isTest
   public static void setupTestData() {
        // Step 1: Ensure a RecordType exists
        RecordType accountRecType = [SELECT Id FROM RecordType WHERE DeveloperName = 'SIG_Advisors_Agents_and_their_affiliated_staff' AND SObjectType = 'Account' and IsPersonType = true  LIMIT 1];
        System.assertNotEquals(null, accountRecType, 'Record Type SIG_Advisors_Agents_and_their_affiliated_staff should exist.');

        RecordType accountRecType1 = [SELECT Id FROM RecordType WHERE DeveloperName = 'IndustriesHousehold' AND SObjectType = 'Account' and IsPersonType = false LIMIT 1];
        System.assertNotEquals(null, accountRecType1, 'Record Type IndustriesHousehold should exist.');        
        
		RecordType accountRecType2 = [SELECT Id FROM RecordType WHERE DeveloperName = 'SIG_Advisors_Agents_Business_Name' AND SObjectType = 'Account' and IsPersonType = false LIMIT 1];
        System.assertNotEquals(null, accountRecType2, 'Record Type SIG_Advisors_Agents_Business_Name should exist.');
        
        // Create a test Account with a RepAdvisorEntity__pc value
        Account acc1 = new Account(
            Name = 'Sound Income Strategies LLC', 
            RecordTypeId = accountRecType2.Id, // Ensure this record type is valid for the user profile
            Industry = 'Engineering',
            SIS_Advisor_Affiliation__c='Sub-Advisor',
            RIA_Firm__c ='TestEntity',
            HHCurrentCash__c =5000,
            HHCurrentMktVal__c = 5000
        );
        insert acc1;
        
        // Create a test Account with a RepAdvisorEntity__pr value
        Account acc2 = new Account(
            Name = 'Sound Income Strategies LLC', // This should match the User's CompanyName
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
         User testUser = new User(
            Username = 'testuser_' + System.currentTimeMillis() + '@example.com',
            Email = 'testuser11@example.com',
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
        Contact con = new Contact(
            LastName = 'Test Contact 2',
            FirstName = 'Test Contact 2',
            RepAdvisorEntity__c = account1.Id
            //AccountId = account1.Id // Ensure this matches the entityName parameter
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
            FinServ__Balance__c =5000,
            FinServ__FinancialAccountNumber__c = '50005000',
            AccountType__c ='Individual',
            RepID__c = repIDManagedFalse.Name
        );
        insert financialAccount;	
        
       // Create Financial Account
            FinServ__FinancialAccount__c financialAccount1 = new FinServ__FinancialAccount__c(
                Name = 'Test Financial Account',
                FinServ__PrimaryOwner__c = acc2.Id,
                FinServ__JointOwner__c = account1.Id,
                FinServ__Household__c = acc1.Id,
                RepAdvisor__c = con.id,
                RepIDLink__c = repIDManagedFalse.id,
                RepID__c = repIDManagedFalse.Name,
                FinServ__Balance__c =5000
            );
        insert financialAccount1;	
        

	}

    @isTest
    static void testFetchDetailedData() {
        // Call the setup method to create test data
        setupTestData();
        FinServ__FinancialAccount__c financialAccount1 = [SELECT Id,RepAdvisor__r.RepAdvisorEntity__c FROM FinServ__FinancialAccount__c LIMIT 1];
        // Set up parameters for the controller
        Test.setCurrentPageReference(new PageReference('/apex/AdvisorMatrixReport'));
        ApexPages.currentPage().getParameters().put('entityName', 'Sound Income Strategies LLC');
        ApexPages.currentPage().getParameters().put('accountId', financialAccount1.RepAdvisor__r.RepAdvisorEntity__c);
        
        AdvisorMatrixPageController controller = new AdvisorMatrixPageController();
        
        controller.fetchDetailedData('Sound Income Strategies LLC');
        System.assertNotEquals(null, controller.companyInvestmentRecordMatrix[0], 'Investment record matrix should not be null.');
        System.assertEquals(5, controller.companyInvestmentRecordMatrix[0].size(), 'Investment record matrix should contain one record.');        
        List<String> row = controller.companyInvestmentRecordMatrix[0];        
        System.assertEquals('48549062', row[0], 'The account number should match.');
            
    }

    @isTest
    static void testFetchDetailedAdvisorData() {
        setupTestData();
        FinServ__FinancialAccount__c financialAccount1 = [SELECT Id, RepAdvisor__r.RepAdvisorEntity__c, RepAdvisor__c FROM FinServ__FinancialAccount__c LIMIT 1];
        
        Test.setCurrentPageReference(new PageReference('/apex/AdvisorMatrixReport'));
        ApexPages.currentPage().getParameters().put('entityName', 'Sound Income Strategies LLC');
        ApexPages.currentPage().getParameters().put('accountId', financialAccount1.RepAdvisor__r.RepAdvisorEntity__c);
        
         AdvisorMatrixPageController controller = new AdvisorMatrixPageController();
       		controller.fetchDetailedAdvisorData(financialAccount1.RepAdvisor__c);        
        System.assertNotEquals(null, controller.companyInvestmentRecordMatrix[1], 'Investment record matrix should not be null.');            
        System.assertEquals(5, controller.companyInvestmentRecordMatrix[1].size(), 'Investment record matrix should contain one record.');   
        List<String> row1 = controller.companyInvestmentRecordMatrix[1];        
        System.assertEquals('N/A', row1[0], 'The account number should match.');
    }

    @isTest
    static void testFetchDetailedCustodianData() {
        setupTestData();
        EAST_RepID__c repName =[Select Name, Custodian__c from EAST_RepID__c limit 1];
        FinServ__FinancialAccount__c financialAccount1 = [SELECT Id, RepIDLink__r.Custodian__c FROM FinServ__FinancialAccount__c where RepID__c =:repName.Name LIMIT 1];
        
        Test.setCurrentPageReference(new PageReference('/apex/AdvisorMatrixReport'));
        ApexPages.currentPage().getParameters().put('entityName', 'Sound Income Strategies LLC');
        ApexPages.currentPage().getParameters().put('custodian', repName.Custodian__c);
        
         AdvisorMatrixPageController controller = new AdvisorMatrixPageController();
        controller.fetchDetailedCustodianData(repName.Custodian__c);        
        System.assertNotEquals(null, controller.companyInvestmentRecordMatrix, 'Investment record matrix should not be null.');             
        List<String> row2 = controller.companyInvestmentRecordMatrix[2];         
        //System.assertEquals('50005000', row2[0], 'The account number should match.');
        //System.assertEquals('Sound Income Strategies LLC', row2[1], 'The name should match.');
    }

    @isTest
    static void testFetchDetailedManagedData() {  
        setupTestData();
        EAST_RepID__c repName =[Select Name, Managed__c from EAST_RepID__c limit 1];
        FinServ__FinancialAccount__c financialAccount1 = [SELECT Id, RepIDLink__r.Custodian__c FROM FinServ__FinancialAccount__c where RepID__c =:repName.Name LIMIT 1];
       
        Test.setCurrentPageReference(new PageReference('/apex/AdvisorMatrixReport'));
        ApexPages.currentPage().getParameters().put('entityName', 'Sound Income Strategies LLC');
        ApexPages.currentPage().getParameters().put('managed', String.valueOf(repName.Managed__c));
        
         AdvisorMatrixPageController controller = new AdvisorMatrixPageController();
        controller.fetchDetailedManagedData(String.valueOf(repName.Managed__c));        
        System.assertNotEquals(null, controller.companyInvestmentRecordMatrix, 'Investment record matrix should not be null.');  
        //List<String> row3 = controller.companyInvestmentRecordMatrix[3];         
        //System.assertEquals('50005000', row3[0], 'The account number should match.');   
    }

    @isTest
    static void testFetchDetailedacData() {
          setupTestData();
        EAST_RepID__c repName =[Select Name, Custodian__c from EAST_RepID__c limit 1];
        FinServ__FinancialAccount__c financialAccount = [SELECT Id, RepAdvisor__r.RepAdvisorEntity__c, RepAdvisor__c FROM FinServ__FinancialAccount__c LIMIT 1];
        
        Test.setCurrentPageReference(new PageReference('/apex/AdvisorMatrixReport'));
        ApexPages.currentPage().getParameters().put('entityName', 'Sound Income Strategies LLC');
        ApexPages.currentPage().getParameters().put('accountId', financialAccount.RepAdvisor__r.RepAdvisorEntity__c);        
        ApexPages.currentPage().getParameters().put('custodian', repName.Custodian__c);
        
         AdvisorMatrixPageController controller = new AdvisorMatrixPageController();
        controller.fetchDetailedacData(financialAccount.RepAdvisor__c,repName.Custodian__c);        
        System.assertNotEquals(null, controller.companyInvestmentRecordMatrix, 'Investment record matrix should not be null.');            
        //List<String> row4 = controller.companyInvestmentRecordMatrix[4];        
        //System.assertEquals('40620681', row4[0], 'The account number should match.');  
    }

    @isTest
    static void testFetchDetailedamData() {
       setupTestData();
        EAST_RepID__c repName =[Select Name, Managed__c from EAST_RepID__c limit 1];
        FinServ__FinancialAccount__c financialAccount = [SELECT Id, RepAdvisor__r.RepAdvisorEntity__c, RepAdvisor__c FROM FinServ__FinancialAccount__c LIMIT 1];
               
        Test.setCurrentPageReference(new PageReference('/apex/AdvisorMatrixReport'));
        ApexPages.currentPage().getParameters().put('entityName', 'Sound Income Strategies LLC');
        ApexPages.currentPage().getParameters().put('accountId', financialAccount.RepAdvisor__r.RepAdvisorEntity__c);
        ApexPages.currentPage().getParameters().put('managed', String.valueOf(repName.Managed__c));
        
         AdvisorMatrixPageController controller = new AdvisorMatrixPageController();
        controller.fetchDetailedamData(financialAccount.RepAdvisor__c, String.valueOf(repName.Managed__c));        
        System.assertNotEquals(null, controller.companyInvestmentRecordMatrix, 'Investment record matrix should not be null.');            
        //List<String> row5 = controller.companyInvestmentRecordMatrix[5];        
        //System.assertEquals('54939908', row5[0], 'The account number should match.');
    }

    @isTest
    static void testFetchDetailedcmData() {
       setupTestData();
        EAST_RepID__c repName =[Select Name, Managed__c,Custodian__c from EAST_RepID__c limit 1];
        FinServ__FinancialAccount__c financialAccount = [SELECT Id, RepAdvisor__r.RepAdvisorEntity__c, RepAdvisor__c, RepID__c FROM FinServ__FinancialAccount__c LIMIT 1];
        
        Test.setCurrentPageReference(new PageReference('/apex/AdvisorMatrixReport'));
        ApexPages.currentPage().getParameters().put('entityName', 'Sound Income Strategies LLC');      
        ApexPages.currentPage().getParameters().put('custodian', repName.Custodian__c);
        ApexPages.currentPage().getParameters().put('managed', String.valueOf(repName.Managed__c));
        
         AdvisorMatrixPageController controller = new AdvisorMatrixPageController();
        controller.fetchDetailedcmData(repName.Custodian__c,String.valueOf(repName.Managed__c));        
        System.assertNotEquals(null, controller.companyInvestmentRecordMatrix, 'Investment record matrix should not be null.');            
        //List<String> row6 = controller.companyInvestmentRecordMatrix[6];        
        //System.assertEquals('35242652', row6[0], 'The account number should match.'); 
        
    }

    @isTest
    static void testFetchDetailedacmData() {
      setupTestData();
        EAST_RepID__c repName =[Select Name, Managed__c,Custodian__c from EAST_RepID__c limit 1];
        FinServ__FinancialAccount__c financialAccount1 = [SELECT Id, RepAdvisor__r.RepAdvisorEntity__c, RepAdvisor__c FROM FinServ__FinancialAccount__c LIMIT 1];
        
        Test.setCurrentPageReference(new PageReference('/apex/AdvisorMatrixReport'));
        ApexPages.currentPage().getParameters().put('entityName', 'Sound Income Strategies LLC');
        ApexPages.currentPage().getParameters().put('accountId', financialAccount1.RepAdvisor__r.RepAdvisorEntity__c);      
        ApexPages.currentPage().getParameters().put('custodian', repName.Custodian__c);
        ApexPages.currentPage().getParameters().put('managed', String.valueOf(repName.Managed__c));
        
         AdvisorMatrixPageController controller = new AdvisorMatrixPageController();
        controller.fetchDetailedacmData(financialAccount1.RepAdvisor__c,repName.Custodian__c,String.valueOf(repName.Managed__c));        
        System.assertNotEquals(null, controller.companyInvestmentRecordMatrix, 'Investment record matrix should not be null.');  
        //List<String> row7 = controller.companyInvestmentRecordMatrix[7];       
        //System.assertEquals('43790903', row7[0], 'The account number should match.');
    }
}