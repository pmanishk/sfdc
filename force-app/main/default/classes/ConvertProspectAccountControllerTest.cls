@isTest(SeeAllData=true) // Allows access to existing Record Types & Custom Metadata
public class ConvertProspectAccountControllerTest {

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

        String result = ConvertProspectAccountController.saveAccountData(prospect);
        System.assertEquals('ssnDoesNotExist', result, 'Should return ssnDoesNotExist when SSN is missing');
    }

    @isTest
    static void testDuplicateSSN() {
        String duplicateSSN = '123456789';

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
            FinServ__TaxId__pc = duplicateSSN,
            RecordTypeId = getRecordTypeId('Account', 'PersonAccount'),
            Employer_Address__CountryCode__s = 'United States'
        );

        String result = ConvertProspectAccountController.saveAccountData(prospect);
        System.assertEquals('duplicateSSN', result, 'Should return duplicateSSN for existing SSN');
    }

    @isTest
    static void testSuccessfulFlow() {
        Test.startTest();

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
        ConvertProspectAccountController.getStateMappings();
        ConvertProspectAccountController.getRandomAccountId();
        String result = ConvertProspectAccountController.saveAccountData(prospect);

        System.debug('Result: ' + result);
        System.assertNotEquals('ssnDoesNotExist', result);
        System.assertNotEquals('duplicateSSN', result);
        System.assert(result != null && result.startsWith('001'), 'Expected returned ID to be a valid Account Id');
        Test.stopTest();
    }
}