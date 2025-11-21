@isTest (SeeAllData=true) // Allows access to existing Record Types & Custom Metadata
private class ConvertProspectAccountControllerNewTest {

    // Helper to get RecordTypeId by DeveloperName
    public static Id getRecordTypeId(String objectName, String developerName) {
        Map<String, Schema.SObjectType> gd = Schema.getGlobalDescribe();
        if (!gd.containsKey(objectName)) return null;

        Map<String, Schema.RecordTypeInfo> recordTypes =
            gd.get(objectName).getDescribe().getRecordTypeInfosByDeveloperName();

        if (recordTypes.containsKey(developerName)) {
            return recordTypes.get(developerName).getRecordTypeId();
        }

        return null;
    }

    @isTest
    static void testMissingSSN() {
        Account prospect = new Account(
            FirstName = 'Test',
            LastName = 'User',
            RecordTypeId = getRecordTypeId('Account', 'PersonAccount')
        );

        ConvertProspectAccountControllerNew.saveAccountData(prospect);
    }

    @isTest
    static void testDuplicateSSNInd() {
        String duplicateSSN = '1234567';
        List<Contact> conList = [Select Id, Name from Contact where Account.RecordType.Name ='SIG Advisors, Agents and their affiliated staff' limit 1];

        Account existing = new Account(
            FirstName = 'Existing',
            LastName = 'User',
            FinServ__TaxId__pc = duplicateSSN,
            RecordTypeId = getRecordTypeId('Account', 'PersonAccount') // Use any non-Prospect type
        );
        insert existing;

        Account prospect = new Account(
            FirstName = 'New',
            LastName = 'User',
            RepAdvisor__c = conList[0].Id,
            FinServ__TaxId__pc = duplicateSSN,
            RecordTypeId = getRecordTypeId('Account', 'PersonAccount'),
            Employer_Address__CountryCode__s = 'United States'
        );

        ConvertProspectAccountControllerNew.saveAccountData(prospect);
    }


    @isTest
    static void testDuplicateSSNlJointFlow1() {
        Test.startTest();
         String duplicateSSN = '1234567';

        Account existing = new Account(
            FirstName = 'Existing',
            LastName = 'User',
            FinServ__TaxId__pc = duplicateSSN,
            RecordTypeId = getRecordTypeId('Account', 'PersonAccount') // Use any non-Prospect type
        );
        insert existing;

        List<Contact> conList = [Select Id, Name from Contact where Account.RecordType.Name ='SIG Advisors, Agents and their affiliated staff' limit 1];
        List<Account> accList = new List<Account>();
        accList.add(new Account(
            FirstName = 'Fn1',
            LastName = 'LN1',
            FinServ__TaxId__pc = duplicateSSN,
            PersonBirthdate = Date.newInstance(1990, 1, 1),
            Employer_Address__City__s = 'Austin',
            Employer_Address__StateCode__s = 'TX',
            Employer_Address__CountryCode__s = 'United States',
            Employer_Address__Street__s = '123 Main St',
            Employer_Address__PostalCode__s = '73301',
            PersonMailingStreet = '123 Main St',
            RecordTypeId = getRecordTypeId('Account', 'PersonAccount'),
            RepAdvisor__c = conList[0].Id
        ));
        accList.add(new Account(
            FirstName = 'FN2',
            LastName = 'LN2',
            FinServ__TaxId__pc = '987654322',
            PersonBirthdate = Date.newInstance(1990, 1, 1),
            Employer_Address__City__s = 'Austin',
            Employer_Address__StateCode__s = 'TX',
            Employer_Address__CountryCode__s = 'United States',
            Employer_Address__Street__s = '123 Main St',
            Employer_Address__PostalCode__s = '73301',
            PersonMailingStreet = '123 Main St',
            RecordTypeId = getRecordTypeId('Account', 'PersonAccount'),
            RepAdvisor__c = conList[0].Id
        ));
        ConvertProspectAccountControllerNew.processJointAccounts(accList);

        Test.stopTest();
    }
    
    @isTest
    static void testDuplicateSSNlJointFlow2() {
        Test.startTest();
         String duplicateSSN = '1234567';

        Account existing = new Account(
            FirstName = 'Existing',
            LastName = 'User',
            FinServ__TaxId__pc = duplicateSSN,
            RecordTypeId = getRecordTypeId('Account', 'PersonAccount') // Use any non-Prospect type
        );
        insert existing;

        List<Contact> conList = [Select Id, Name from Contact where Account.RecordType.Name ='SIG Advisors, Agents and their affiliated staff' limit 1];
        List<Account> accList = new List<Account>();
        accList.add(new Account(
            FirstName = 'Fn1',
            LastName = 'LN1',
            FinServ__TaxId__pc = '987654321',
            PersonBirthdate = Date.newInstance(1990, 1, 1),
            Employer_Address__City__s = 'Austin',
            Employer_Address__StateCode__s = 'TX',
            Employer_Address__CountryCode__s = 'United States',
            Employer_Address__Street__s = '123 Main St',
            Employer_Address__PostalCode__s = '73301',
            PersonMailingStreet = '123 Main St',
            RecordTypeId = getRecordTypeId('Account', 'PersonAccount'),
            RepAdvisor__c = conList[0].Id
        ));
        accList.add(new Account(
            FirstName = 'FN2',
            LastName = 'LN2',
            FinServ__TaxId__pc = duplicateSSN,
            PersonBirthdate = Date.newInstance(1990, 1, 1),
            Employer_Address__City__s = 'Austin',
            Employer_Address__StateCode__s = 'TX',
            Employer_Address__CountryCode__s = 'United States',
            Employer_Address__Street__s = '123 Main St',
            Employer_Address__PostalCode__s = '73301',
            PersonMailingStreet = '123 Main St',
            RecordTypeId = getRecordTypeId('Account', 'PersonAccount'),
            RepAdvisor__c = conList[0].Id
        ));
        ConvertProspectAccountControllerNew.processJointAccounts(accList);

        Test.stopTest();
    }

    
    @isTest
    static void testDuplicateSSNlJointFlow3() {
        Test.startTest();
         String duplicateSSN = '1234567';

        Account existing = new Account(
            FirstName = 'Existing',
            LastName = 'User',
            FinServ__TaxId__pc = duplicateSSN,
            RecordTypeId = getRecordTypeId('Account', 'PersonAccount') // Use any non-Prospect type
        );
        insert existing;

        List<Contact> conList = [Select Id, Name from Contact where Account.RecordType.Name ='SIG Advisors, Agents and their affiliated staff' limit 1];
        List<Account> accList = new List<Account>();
        accList.add(new Account(
            FirstName = 'Fn1',
            LastName = 'LN1',
            FinServ__TaxId__pc = duplicateSSN,
            PersonBirthdate = Date.newInstance(1990, 1, 1),
            Employer_Address__City__s = 'Austin',
            Employer_Address__StateCode__s = 'TX',
            Employer_Address__CountryCode__s = 'United States',
            Employer_Address__Street__s = '123 Main St',
            Employer_Address__PostalCode__s = '73301',
            PersonMailingStreet = '123 Main St',
            RecordTypeId = getRecordTypeId('Account', 'PersonAccount'),
            RepAdvisor__c = conList[0].Id
        ));
        accList.add(new Account(
            FirstName = 'FN2',
            LastName = 'LN2',
            FinServ__TaxId__pc = duplicateSSN,
            PersonBirthdate = Date.newInstance(1990, 1, 1),
            Employer_Address__City__s = 'Austin',
            Employer_Address__StateCode__s = 'TX',
            Employer_Address__CountryCode__s = 'United States',
            Employer_Address__Street__s = '123 Main St',
            Employer_Address__PostalCode__s = '73301',
            PersonMailingStreet = '123 Main St',
            RecordTypeId = getRecordTypeId('Account', 'PersonAccount'),
            RepAdvisor__c = conList[0].Id
        ));
        ConvertProspectAccountControllerNew.processJointAccounts(accList);

        Test.stopTest();
    }

    @isTest
    static void testAccountMissing() {
        Test.startTest();
        List<Account> accList = new List<Account>();
        Account acc;
        ConvertProspectAccountControllerNew.saveAccountData(acc);
        ConvertProspectAccountControllerNew.processJointAccounts(accList);

        Test.stopTest();
    }

    @isTest
    static void testRepMissingIndividualFlow() {
        Test.startTest();
        List<Contact> conList = [Select Id, Name from Contact where Account.RecordType.Name ='SIG Advisors, Agents and their affiliated staff' limit 1];
        Account prospect = new Account(
            FirstName = 'Jane',
            LastName = 'Doe',
            FinServ__TaxId__pc = '987654321',
            PersonBirthdate = Date.newInstance(1990, 1, 1),
            Employer_Address__City__s = 'Austin',
            Employer_Address__StateCode__s = 'TX',
            Employer_Address__CountryCode__s = 'United States',
            Employer_Address__Street__s = '123 Main St',
            Employer_Address__PostalCode__s = '73301',
            PersonMailingStreet = '123 Main St',
            RecordTypeId = getRecordTypeId('Account', 'PersonAccount')
        );
        ConvertProspectAccountControllerNew.getStateMappings();
        ConvertProspectAccountControllerNew.getRandomAccountId();
        ConvertProspectAccountControllerNew.saveAccountData(prospect);

        Test.stopTest();
    }

    @isTest
    static void testRepMissingJointFlow1() {
        Test.startTest();
        List<Contact> conList = [Select Id, Name from Contact where Account.RecordType.Name ='SIG Advisors, Agents and their affiliated staff' limit 1];
        List<Account> accList = new List<Account>();
        accList.add(new Account(
            FirstName = 'Fn1',
            LastName = 'LN1',
            FinServ__TaxId__pc = '987654321',
            PersonBirthdate = Date.newInstance(1990, 1, 1),
            Employer_Address__City__s = 'Austin',
            Employer_Address__StateCode__s = 'TX',
            Employer_Address__CountryCode__s = 'United States',
            Employer_Address__Street__s = '123 Main St',
            Employer_Address__PostalCode__s = '73301',
            PersonMailingStreet = '123 Main St',
            RecordTypeId = getRecordTypeId('Account', 'PersonAccount')
        ));
        accList.add(new Account(
            FirstName = 'FN2',
            LastName = 'LN2',
            FinServ__TaxId__pc = '987654322',
            PersonBirthdate = Date.newInstance(1990, 1, 1),
            Employer_Address__City__s = 'Austin',
            Employer_Address__StateCode__s = 'TX',
            Employer_Address__CountryCode__s = 'United States',
            Employer_Address__Street__s = '123 Main St',
            Employer_Address__PostalCode__s = '73301',
            PersonMailingStreet = '123 Main St',
            RecordTypeId = getRecordTypeId('Account', 'PersonAccount')
        ));
        ConvertProspectAccountControllerNew.processJointAccounts(accList);

        Test.stopTest();
    }


     @isTest
    static void testRepMissingJointFlow2() {
        Test.startTest();
        List<Contact> conList = [Select Id, Name from Contact where Account.RecordType.Name ='SIG Advisors, Agents and their affiliated staff' limit 1];
        List<Account> accList = new List<Account>();
        accList.add(new Account(
            FirstName = 'Fn1',
            LastName = 'LN1',
            FinServ__TaxId__pc = '987654321',
            PersonBirthdate = Date.newInstance(1990, 1, 1),
            Employer_Address__City__s = 'Austin',
            Employer_Address__StateCode__s = 'TX',
            Employer_Address__CountryCode__s = 'United States',
            Employer_Address__Street__s = '123 Main St',
            Employer_Address__PostalCode__s = '73301',
            PersonMailingStreet = '123 Main St',
            RecordTypeId = getRecordTypeId('Account', 'PersonAccount'),
            RepAdvisor__c = conList[0].Id
        ));
        accList.add(new Account(
            FirstName = 'FN2',
            LastName = 'LN2',
            FinServ__TaxId__pc = '987654322',
            PersonBirthdate = Date.newInstance(1990, 1, 1),
            Employer_Address__City__s = 'Austin',
            Employer_Address__StateCode__s = 'TX',
            Employer_Address__CountryCode__s = 'United States',
            Employer_Address__Street__s = '123 Main St',
            Employer_Address__PostalCode__s = '73301',
            PersonMailingStreet = '123 Main St',
            RecordTypeId = getRecordTypeId('Account', 'PersonAccount')
        ));
        ConvertProspectAccountControllerNew.processJointAccounts(accList);

        Test.stopTest();
    }

    @isTest
    static void testRepMissingJointFlow3() {
        Test.startTest();
        List<Contact> conList = [Select Id, Name from Contact where Account.RecordType.Name ='SIG Advisors, Agents and their affiliated staff' limit 1];
        List<Account> accList = new List<Account>();
        accList.add(new Account(
            FirstName = 'Fn1',
            LastName = 'LN1',
            FinServ__TaxId__pc = '987654321',
            PersonBirthdate = Date.newInstance(1990, 1, 1),
            Employer_Address__City__s = 'Austin',
            Employer_Address__StateCode__s = 'TX',
            Employer_Address__CountryCode__s = 'United States',
            Employer_Address__Street__s = '123 Main St',
            Employer_Address__PostalCode__s = '73301',
            PersonMailingStreet = '123 Main St',
            RecordTypeId = getRecordTypeId('Account', 'PersonAccount')
        ));
        accList.add(new Account(
            FirstName = 'FN2',
            LastName = 'LN2',
            FinServ__TaxId__pc = '987654322',
            PersonBirthdate = Date.newInstance(1990, 1, 1),
            Employer_Address__City__s = 'Austin',
            Employer_Address__StateCode__s = 'TX',
            Employer_Address__CountryCode__s = 'United States',
            Employer_Address__Street__s = '123 Main St',
            Employer_Address__PostalCode__s = '73301',
            PersonMailingStreet = '123 Main St',
            RecordTypeId = getRecordTypeId('Account', 'PersonAccount'),
            RepAdvisor__c = conList[0].Id
        ));
        ConvertProspectAccountControllerNew.processJointAccounts(accList);

        Test.stopTest();
    }

     @isTest
    static void testRepMismatchJointFlow() {
        Test.startTest();
        List<Contact> conList = [Select Id, Name from Contact limit 2];
        List<Account> accList = new List<Account>();
        accList.add(new Account(
            FirstName = 'Fn1',
            LastName = 'LN1',
            FinServ__TaxId__pc = '987654321',
            PersonBirthdate = Date.newInstance(1990, 1, 1),
            Employer_Address__City__s = 'Austin',
            Employer_Address__StateCode__s = 'TX',
            Employer_Address__CountryCode__s = 'United States',
            Employer_Address__Street__s = '123 Main St',
            Employer_Address__PostalCode__s = '73301',
            PersonMailingStreet = '123 Main St',
            RecordTypeId = getRecordTypeId('Account', 'PersonAccount'),
            RepAdvisor__c = conList[0].Id
        ));
        accList.add(new Account(
            FirstName = 'FN2',
            LastName = 'LN2',
            FinServ__TaxId__pc = '987654322',
            PersonBirthdate = Date.newInstance(1990, 1, 1),
            Employer_Address__City__s = 'Austin',
            Employer_Address__StateCode__s = 'TX',
            Employer_Address__CountryCode__s = 'United States',
            Employer_Address__Street__s = '123 Main St',
            Employer_Address__PostalCode__s = '73301',
            PersonMailingStreet = '123 Main St',
            RecordTypeId = getRecordTypeId('Account', 'PersonAccount'),
            RepAdvisor__c = conList[1].Id
        ));
        ConvertProspectAccountControllerNew.processJointAccounts(accList);

        Test.stopTest();
    }

    @isTest
    static void testMissingSSNIndividualFlow() {
        Test.startTest();
        List<Contact> conList = [Select Id, Name from Contact where Account.RecordType.Name ='SIG Advisors, Agents and their affiliated staff' limit 1];
        Account prospect = new Account(
            FirstName = 'Jane',
            LastName = 'Doe',
            PersonBirthdate = Date.newInstance(1990, 1, 1),
            Employer_Address__City__s = 'Austin',
            Employer_Address__StateCode__s = 'TX',
            Employer_Address__CountryCode__s = 'United States',
            Employer_Address__Street__s = '123 Main St',
            Employer_Address__PostalCode__s = '73301',
            PersonMailingStreet = '123 Main St',
            RecordTypeId = getRecordTypeId('Account', 'PersonAccount'),
            RepAdvisor__c = conList[0].Id
        );
        ConvertProspectAccountControllerNew.getStateMappings();
        ConvertProspectAccountControllerNew.getRandomAccountId();
        ConvertProspectAccountControllerNew.saveAccountData(prospect);

        Test.stopTest();
    }

    @isTest
    static void testMissingSSNJointFlow1() {
        Test.startTest();
        List<Contact> conList = [Select Id, Name from Contact where Account.RecordType.Name ='SIG Advisors, Agents and their affiliated staff' limit 1];
        List<Account> accList = new List<Account>();
        accList.add(new Account(
            FirstName = 'Fn1',
            LastName = 'LN1',
            PersonBirthdate = Date.newInstance(1990, 1, 1),
            Employer_Address__City__s = 'Austin',
            Employer_Address__StateCode__s = 'TX',
            Employer_Address__CountryCode__s = 'United States',
            Employer_Address__Street__s = '123 Main St',
            Employer_Address__PostalCode__s = '73301',
            PersonMailingStreet = '123 Main St',
            RecordTypeId = getRecordTypeId('Account', 'PersonAccount'),
            RepAdvisor__c = conList[0].Id
        ));
        accList.add(new Account(
            FirstName = 'FN2',
            LastName = 'LN2',
            PersonBirthdate = Date.newInstance(1990, 1, 1),
            Employer_Address__City__s = 'Austin',
            Employer_Address__StateCode__s = 'TX',
            Employer_Address__CountryCode__s = 'United States',
            Employer_Address__Street__s = '123 Main St',
            Employer_Address__PostalCode__s = '73301',
            PersonMailingStreet = '123 Main St',
            RecordTypeId = getRecordTypeId('Account', 'PersonAccount'),
            RepAdvisor__c = conList[0].Id
        ));
        ConvertProspectAccountControllerNew.processJointAccounts(accList);

        Test.stopTest();
    }

    @isTest
    static void testMissingSSNJointFlow2() {
        Test.startTest();
        List<Contact> conList = [Select Id, Name from Contact where Account.RecordType.Name ='SIG Advisors, Agents and their affiliated staff' limit 1];
        List<Account> accList = new List<Account>();
        accList.add(new Account(
            FirstName = 'Fn1',
            LastName = 'LN1',
            FinServ__TaxId__pc = '987654322',
            PersonBirthdate = Date.newInstance(1990, 1, 1),
            Employer_Address__City__s = 'Austin',
            Employer_Address__StateCode__s = 'TX',
            Employer_Address__CountryCode__s = 'United States',
            Employer_Address__Street__s = '123 Main St',
            Employer_Address__PostalCode__s = '73301',
            PersonMailingStreet = '123 Main St',
            RecordTypeId = getRecordTypeId('Account', 'PersonAccount'),
            RepAdvisor__c = conList[0].Id
        ));
        accList.add(new Account(
            FirstName = 'FN2',
            LastName = 'LN2',
            PersonBirthdate = Date.newInstance(1990, 1, 1),
            Employer_Address__City__s = 'Austin',
            Employer_Address__StateCode__s = 'TX',
            Employer_Address__CountryCode__s = 'United States',
            Employer_Address__Street__s = '123 Main St',
            Employer_Address__PostalCode__s = '73301',
            PersonMailingStreet = '123 Main St',
            RecordTypeId = getRecordTypeId('Account', 'PersonAccount'),
            RepAdvisor__c = conList[0].Id
        ));
        ConvertProspectAccountControllerNew.processJointAccounts(accList);

        Test.stopTest();
    }


 @isTest
    static void testMissingSSNJointFlow3() {
        Test.startTest();
        List<Contact> conList = [Select Id, Name from Contact where Account.RecordType.Name ='SIG Advisors, Agents and their affiliated staff' limit 1];
        List<Account> accList = new List<Account>();
        accList.add(new Account(
            FirstName = 'Fn1',
            LastName = 'LN1',
            PersonBirthdate = Date.newInstance(1990, 1, 1),
            Employer_Address__City__s = 'Austin',
            Employer_Address__StateCode__s = 'TX',
            Employer_Address__CountryCode__s = 'United States',
            Employer_Address__Street__s = '123 Main St',
            Employer_Address__PostalCode__s = '73301',
            PersonMailingStreet = '123 Main St',
            RecordTypeId = getRecordTypeId('Account', 'PersonAccount'),
            RepAdvisor__c = conList[0].Id
        ));
        accList.add(new Account(
            FirstName = 'FN2',
            LastName = 'LN2',
            FinServ__TaxId__pc = '987654322',
            PersonBirthdate = Date.newInstance(1990, 1, 1),
            Employer_Address__City__s = 'Austin',
            Employer_Address__StateCode__s = 'TX',
            Employer_Address__CountryCode__s = 'United States',
            Employer_Address__Street__s = '123 Main St',
            Employer_Address__PostalCode__s = '73301',
            PersonMailingStreet = '123 Main St',
            RecordTypeId = getRecordTypeId('Account', 'PersonAccount'),
            RepAdvisor__c = conList[0].Id
        ));
        ConvertProspectAccountControllerNew.processJointAccounts(accList);

        Test.stopTest();
    }


    @isTest
    static void testIncorrectSSNIndividualFlow() {
        Test.startTest();
        List<Contact> conList = [Select Id, Name from Contact where Account.RecordType.Name ='SIG Advisors, Agents and their affiliated staff' limit 1];
        Account prospect = new Account(
            FirstName = 'Jane',
            LastName = 'Doe',
            FinServ__TaxId__pc = '9876543210',
            PersonBirthdate = Date.newInstance(1990, 1, 1),
            Employer_Address__City__s = 'Austin',
            Employer_Address__StateCode__s = 'TX',
            Employer_Address__CountryCode__s = 'United States',
            Employer_Address__Street__s = '123 Main St',
            Employer_Address__PostalCode__s = '73301',
            PersonMailingStreet = '123 Main St',
            RecordTypeId = getRecordTypeId('Account', 'PersonAccount'),
            RepAdvisor__c = conList[0].Id
        );
        ConvertProspectAccountControllerNew.getStateMappings();
        ConvertProspectAccountControllerNew.getRandomAccountId();
        ConvertProspectAccountControllerNew.saveAccountData(prospect);

        Test.stopTest();
    }

    @isTest
    static void testIncorrectSSNlJointFlow1() {
        Test.startTest();
        List<Contact> conList = [Select Id, Name from Contact where Account.RecordType.Name ='SIG Advisors, Agents and their affiliated staff' limit 1];
        List<Account> accList = new List<Account>();
        accList.add(new Account(
            FirstName = 'Fn1',
            LastName = 'LN1',
            FinServ__TaxId__pc = '9876543211',
            PersonBirthdate = Date.newInstance(1990, 1, 1),
            Employer_Address__City__s = 'Austin',
            Employer_Address__StateCode__s = 'TX',
            Employer_Address__CountryCode__s = 'United States',
            Employer_Address__Street__s = '123 Main St',
            Employer_Address__PostalCode__s = '73301',
            PersonMailingStreet = '123 Main St',
            RecordTypeId = getRecordTypeId('Account', 'PersonAccount'),
            RepAdvisor__c = conList[0].Id
        ));
        accList.add(new Account(
            FirstName = 'FN2',
            LastName = 'LN2',
            FinServ__TaxId__pc = '987654322',
            PersonBirthdate = Date.newInstance(1990, 1, 1),
            Employer_Address__City__s = 'Austin',
            Employer_Address__StateCode__s = 'TX',
            Employer_Address__CountryCode__s = 'United States',
            Employer_Address__Street__s = '123 Main St',
            Employer_Address__PostalCode__s = '73301',
            PersonMailingStreet = '123 Main St',
            RecordTypeId = getRecordTypeId('Account', 'PersonAccount'),
            RepAdvisor__c = conList[0].Id
        ));
        ConvertProspectAccountControllerNew.processJointAccounts(accList);

        Test.stopTest();
    }

 @isTest
    static void testIncorrectSSNlJointFlow2() {
        Test.startTest();
        List<Contact> conList = [Select Id, Name from Contact where Account.RecordType.Name ='SIG Advisors, Agents and their affiliated staff' limit 1];
        List<Account> accList = new List<Account>();
        accList.add(new Account(
            FirstName = 'Fn1',
            LastName = 'LN1',
            FinServ__TaxId__pc = '987654321',
            PersonBirthdate = Date.newInstance(1990, 1, 1),
            Employer_Address__City__s = 'Austin',
            Employer_Address__StateCode__s = 'TX',
            Employer_Address__CountryCode__s = 'United States',
            Employer_Address__Street__s = '123 Main St',
            Employer_Address__PostalCode__s = '73301',
            PersonMailingStreet = '123 Main St',
            RecordTypeId = getRecordTypeId('Account', 'PersonAccount'),
            RepAdvisor__c = conList[0].Id
        ));
        accList.add(new Account(
            FirstName = 'FN2',
            LastName = 'LN2',
            FinServ__TaxId__pc = '9876543222',
            PersonBirthdate = Date.newInstance(1990, 1, 1),
            Employer_Address__City__s = 'Austin',
            Employer_Address__StateCode__s = 'TX',
            Employer_Address__CountryCode__s = 'United States',
            Employer_Address__Street__s = '123 Main St',
            Employer_Address__PostalCode__s = '73301',
            PersonMailingStreet = '123 Main St',
            RecordTypeId = getRecordTypeId('Account', 'PersonAccount'),
            RepAdvisor__c = conList[0].Id
        ));
        ConvertProspectAccountControllerNew.processJointAccounts(accList);

        Test.stopTest();
    }
 @isTest
    static void testIncorrectSSNlJointFlow3() {
        Test.startTest();
        List<Contact> conList = [Select Id, Name from Contact where Account.RecordType.Name ='SIG Advisors, Agents and their affiliated staff' limit 1];
        List<Account> accList = new List<Account>();
        accList.add(new Account(
            FirstName = 'Fn1',
            LastName = 'LN1',
            FinServ__TaxId__pc = '9876543211',
            PersonBirthdate = Date.newInstance(1990, 1, 1),
            Employer_Address__City__s = 'Austin',
            Employer_Address__StateCode__s = 'TX',
            Employer_Address__CountryCode__s = 'United States',
            Employer_Address__Street__s = '123 Main St',
            Employer_Address__PostalCode__s = '73301',
            PersonMailingStreet = '123 Main St',
            RecordTypeId = getRecordTypeId('Account', 'PersonAccount'),
            RepAdvisor__c = conList[0].Id
        ));
        accList.add(new Account(
            FirstName = 'FN2',
            LastName = 'LN2',
            FinServ__TaxId__pc = '9876543222',
            PersonBirthdate = Date.newInstance(1990, 1, 1),
            Employer_Address__City__s = 'Austin',
            Employer_Address__StateCode__s = 'TX',
            Employer_Address__CountryCode__s = 'United States',
            Employer_Address__Street__s = '123 Main St',
            Employer_Address__PostalCode__s = '73301',
            PersonMailingStreet = '123 Main St',
            RecordTypeId = getRecordTypeId('Account', 'PersonAccount'),
            RepAdvisor__c = conList[0].Id
        ));
        ConvertProspectAccountControllerNew.processJointAccounts(accList);

        Test.stopTest();
    }


    @isTest
    static void testSuccessfulIndividualFlow() {
        Test.startTest();
        List<Contact> conList = [Select Id, Name from Contact where Account.RecordType.Name ='SIG Advisors, Agents and their affiliated staff' limit 1];
        Account prospect = new Account(
            FirstName = 'Jane',
            LastName = 'Doe',
            FinServ__TaxId__pc = '987654321',
            PersonBirthdate = Date.newInstance(1990, 1, 1),
            Employer_Address__City__s = 'Austin',
            Employer_Address__StateCode__s = 'TX',
            Employer_Address__CountryCode__s = 'United States',
            Employer_Address__Street__s = '123 Main St',
            Employer_Address__PostalCode__s = '73301',
            PersonMailingStreet = '123 Main St',
            RecordTypeId = getRecordTypeId('Account', 'PersonAccount'),
            RepAdvisor__c = conList[0].Id
        );
        ConvertProspectAccountControllerNew.getStateMappings();
        ConvertProspectAccountControllerNew.getRandomAccountId();
        ConvertProspectAccountControllerNew.saveAccountData(prospect);

        Test.stopTest();
    }

    @isTest
    static void testSuccessfulJointFlow1() {
        Test.startTest();
        List<Contact> conList = [Select Id, Name from Contact where Account.RecordType.Name ='SIG Advisors, Agents and their affiliated staff' limit 1];
        List<Account> accList = new List<Account>();
        accList.add(new Account(
            FirstName = 'Fn1',
            LastName = 'LN1',
            FinServ__TaxId__pc = '987654321',
            PersonBirthdate = Date.newInstance(1990, 1, 1),
            Employer_Address__City__s = 'Austin',
            Employer_Address__StateCode__s = 'TX',
            Employer_Address__CountryCode__s = 'United States',
            Employer_Address__Street__s = '123 Main St',
            Employer_Address__PostalCode__s = '73301',
            PersonMailingStreet = '123 Main St',
            RecordTypeId = getRecordTypeId('Account', 'PersonAccount'),
            RepAdvisor__c = conList[0].Id
        ));
        accList.add(new Account(
            FirstName = 'FN2',
            LastName = 'LN2',
            FinServ__TaxId__pc = '987654322',
            PersonBirthdate = Date.newInstance(1990, 1, 1),
            Employer_Address__City__s = 'Austin',
            Employer_Address__StateCode__s = 'TX',
            Employer_Address__CountryCode__s = 'United States',
            Employer_Address__Street__s = '123 Main St',
            Employer_Address__PostalCode__s = '73301',
            PersonMailingStreet = '123 Main St',
            RecordTypeId = getRecordTypeId('Account', 'PersonAccount'),
            RepAdvisor__c = conList[0].Id
        ));
       ConvertProspectAccountControllerNew.SaveAccountResult houseHoldAccId = ConvertProspectAccountControllerNew.processJointAccounts(accList);

        Test.stopTest();
    }

      @isTest
    static void testSuccessfulJointFlow2() {
        Test.startTest();
        List<Contact> conList = [Select Id, Name from Contact where Account.RecordType.Name ='SIG Advisors, Agents and their affiliated staff' limit 1];
        List<Account> accList = new List<Account>();
        accList.add(new Account(
            FirstName = 'Fn1',
            LastName = 'LN',
            FinServ__TaxId__pc = '987654321',
            PersonBirthdate = Date.newInstance(1990, 1, 1),
            Employer_Address__City__s = 'Austin',
            Employer_Address__StateCode__s = 'TX',
            Employer_Address__CountryCode__s = 'United States',
            Employer_Address__Street__s = '123 Main St',
            Employer_Address__PostalCode__s = '73301',
            PersonMailingStreet = '123 Main St',
            RecordTypeId = getRecordTypeId('Account', 'PersonAccount'),
            RepAdvisor__c = conList[0].Id
        ));
        accList.add(new Account(
            FirstName = 'FN2',
            LastName = 'LN',
            FinServ__TaxId__pc = '987654322',
            PersonBirthdate = Date.newInstance(1990, 1, 1),
            Employer_Address__City__s = 'Austin',
            Employer_Address__StateCode__s = 'TX',
            Employer_Address__CountryCode__s = 'United States',
            Employer_Address__Street__s = '123 Main St',
            Employer_Address__PostalCode__s = '73301',
            PersonMailingStreet = '123 Main St',
            RecordTypeId = getRecordTypeId('Account', 'PersonAccount'),
            RepAdvisor__c = conList[0].Id
        ));
        ConvertProspectAccountControllerNew.processJointAccounts(accList);

        Test.stopTest();
    }
}