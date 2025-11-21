public without sharing class ConvertProspectAccountController {

    public static Id householdAccountId;
    //@InvocableVariable
    //public List<Account> accList = new List<Account>();

    @AuraEnabled
    public static String saveAccountData(Account prospectAccount) {
        System.debug('prospectAccount:'+prospectAccount);

        // SSN Check
        if (prospectAccount.FinServ__TaxId__pc == null) {
            return 'ssnDoesNotExist';
        } else if (isSSNExists(prospectAccount.FinServ__TaxId__pc)) {
            return 'duplicateSSN';
        }
        List<Country_Code_Mapping__mdt> mcList = [Select Id, Country_Code__c From Country_Code_Mapping__mdt Where MasterLabel =:prospectAccount.Employer_Address__CountryCode__s];

        try {
            // Set record type for prospectAccount
            prospectAccount.RecordTypeId = Schema.SObjectType.Account.getRecordTypeInfosByDeveloperName().get('PersonAccount').getRecordTypeId();
            if(mcList.size() > 0){
                prospectAccount.Employer_Address__CountryCode__s = mcList[0].Country_Code__c;
            }
            insert prospectAccount; // Insert the prospect account

            // Create Household Account
            Account householdAccount = new Account(
                RecordTypeId = Schema.SObjectType.Account.getRecordTypeInfosByDeveloperName().get('IndustriesHousehold').getRecordTypeId(),
                Name = prospectAccount.LastName + ', ' + prospectAccount.FirstName,
                RepAdvisor__c = prospectAccount.RepAdvisor__c,
                Employer_Address__City__s = prospectAccount.Employer_Address__City__s,
                Employer_Address__StateCode__s = prospectAccount.Employer_Address__StateCode__s,
                Employer_Address__Street__s = prospectAccount.Employer_Address__Street__s,
                Employer_Address__CountryCode__s = prospectAccount.Employer_Address__CountryCode__s,
                Employer_Address__PostalCode__s = prospectAccount.Employer_Address__PostalCode__s,
                FinServ__IndividualType__c = 'Group'
            );

            Database.SaveResult[] householdInsertResult = Database.insert(new List<Account>{householdAccount}, false);
            
            if (!householdInsertResult[0].isSuccess()) {
                return 'Household creation failed';
            }

            // Update Household Id on Prospect Account
            householdAccountId = householdInsertResult[0].getId();
            prospectAccount.HouseholdAC__pc = householdAccountId;

            if (prospectAccount.Id != null) {
                Database.SaveResult[] updateResults = Database.update(new List<Account>{prospectAccount}, false);
                if (!updateResults[0].isSuccess()) {
                    System.debug('Person Account update failed: ' + updateResults[0].getErrors()[0].getMessage());
                    return 'Person Account update failed';
                }
            }

            // Create ACR
            List<Account> accountList = [SELECT Id, PersonContactId FROM Account WHERE Id = :prospectAccount.Id LIMIT 1];
            System.debug(prospectAccount.PersonContactId);
            AccountContactRelation acr = new AccountContactRelation(
                AccountId = householdAccountId,
                ContactId = accountList[0].PersonContactId,
                FinServ__PrimaryGroup__c = true,
                FinServ__Primary__c = true,
                FinServ__Rollups__c = 'Tasks;Events;Financial Accounts;Assets and Liabilities;Financial Goals;All;Referrals;Opportunities',
                Roles = 'Client'
            );
            List<AccountContactRelation> oldAcr = [SELECT Id FROM AccountContactRelation WHERE AccountId = :householdAccountId AND ContactId = :prospectAccount.PersonContactId];
            if (oldAcr.size() > 0) {
                acr.Id = oldAcr[0].Id;
            }
            Database.UpsertResult[] acrInsertResult = Database.Upsert(new List<AccountContactRelation>{acr}, false);
            if (!acrInsertResult[0].isSuccess()) {
                return 'ACR creation failed';
            }

            // Create Financial Account
            FinServ__FinancialAccount__c finAcc = new FinServ__FinancialAccount__c(
                RecordTypeId = Schema.SObjectType.FinServ__FinancialAccount__c.getRecordTypeInfosByDeveloperName().get('InvestmentAccount').getRecordTypeId(),
                FinServ__Household__c = householdAccountId,
                FinServ__PrimaryOwner__c = prospectAccount.Id,
                FinServ__TaxID__c = prospectAccount.FinServ__TaxId__pc,
                SSN_TIN_c__c = Integer.valueOf(prospectAccount.FinServ__TaxId__pc),
                FABirthday__c = prospectAccount.PersonBirthdate,
                FinServ__Address1__c = prospectAccount.PersonMailingStreet
            );
            Database.SaveResult[] finAccInsertResult = Database.insert(new List<FinServ__FinancialAccount__c>{finAcc}, false);
            if (!finAccInsertResult[0].isSuccess()) {
                System.debug('*********'+finAccInsertResult[0].errors[0].message);
                System.debug('*********'+finAccInsertResult[0].errors[0]);
                return 'Financial Account creation failed';
            }

            return householdAccountId;
        } catch (DmlException e) {
            return e.getMessage();
        }
    }

    // Helper method to check if SSN already exists in Account or FinancialAccount using SOQL
    public static Boolean isSSNExists(String ssn) {
        if (String.isEmpty(ssn)) {
            return false;
        }

        try {
            // Use SOQL instead of SOSL to improve performance and query specific fields
            List<FinServ__FinancialAccount__c> finAccList = [SELECT Id FROM FinServ__FinancialAccount__c WHERE SSN_TIN_c__c = :Integer.valueOf(ssn)];
            List<Account> accList = [SELECT Id FROM Account WHERE FinServ__TaxId__pc = :ssn AND RecordType.name != 'Prospect'];

            // Check if any records exist with the SSN
            return finAccList.size() > 0 || accList.size() > 0;

        } catch (Exception e) {
            System.debug('Error occurred during SSN check: ' + e.getMessage());
            return false;
        }
    }

    public class StateWrapper {
        @AuraEnabled public String label;  
        @AuraEnabled public String code; 

        public StateWrapper(String label, String code) {
            this.label = label;
            this.code = code;
        }
    }

    @AuraEnabled(cacheable=true)
    public static List<StateWrapper> getStateMappings() {
        List<StateWrapper> result = new List<StateWrapper>();
        for (State_Code_Mapping__mdt stateCodeMdt : State_Code_Mapping__mdt.getAll().values()) {
            result.add(new StateWrapper(stateCodeMdt.MasterLabel, stateCodeMdt.State_Code__c));
        }
        return result;
    }

    @AuraEnabled(cacheable=true)
    public static Id getRandomAccountId() {
        // Query a set of Account records
        List<Account> accounts = [SELECT Id FROM Account WITH User_mode LIMIT 1];
        
        // Check if there are any records
        if (accounts.isEmpty()) {
            return null;
        }

        // Return the Id
        return accounts[0].Id;
    }

}