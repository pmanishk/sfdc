public without sharing class ConvertProspectAccountControllerNew {
    public static Id householdAccountId;

    public class SaveAccountResult {
        @AuraEnabled public Boolean success;
        @AuraEnabled public String message;
        @AuraEnabled public Id householdId;
    }

    @AuraEnabled(cacheable=true)
    public static Id getRandomAccountId() {
        Account r = [SELECT Id, Name, FirstName,lastname FROM Account where name ='test convert button Do not delete' limit 1];
        return r != null ? r.Id : null;
    }

    @AuraEnabled
    public static SaveAccountResult saveAccountData(Account prospectAccount) {
        System.debug('prospectAccount:'+prospectAccount);
        SaveAccountResult res = new SaveAccountResult();
        
        if (prospectAccount == null) {
            res.success = false;
            res.message = 'Individual account details are required.';
            return res;
        }

        if(prospectAccount.RepAdvisor__c == null){
            res.success = false;
            res.message = 'Rep advisor on Individual Account required';
            return res;
        }
      
        if(prospectAccount.FinServ__TaxId__pc != null && !Pattern.matches('\\d{9}', prospectAccount.FinServ__TaxId__pc)){
            res.success = false;
            res.message = 'SSN/Tax ID provided on Individual Account must be 9 numeric digits.';
            return res;
        }       
                
        if(isSSNExists(prospectAccount.FinServ__TaxId__pc)){
            res.success = false;
            res.message = 'SSN/Tax ID provided on Individual account is already in use.';
            return res;
        }

        List<Country_Code_Mapping__mdt> mcList = [Select Id,MasterLabel, Country_Code__c From Country_Code_Mapping__mdt Where MasterLabel =:prospectAccount.Employer_Address__CountryCode__s];

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
                res.success = false;
                res.message = 'Household creation of Individual account failed';
                return res;
            }

            // Update Household Id on Prospect Account
            householdAccountId = householdInsertResult[0].getId();
            prospectAccount.HouseholdAC__pc = householdAccountId;

            if (prospectAccount.Id != null) {
                Database.SaveResult[] updateResults = Database.update(new List<Account>{prospectAccount}, false);
                if (!updateResults[0].isSuccess()) {
                    System.debug('Person Account update failed: ' + updateResults[0].getErrors()[0].getMessage());
                    res.success = false;
                    res.message = 'Person Account update failed';
                    return res;
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
                res.success = false;
                res.message = 'Account Contact Relationship creation on Individual account failed';
                return res;
            }

            // Create Financial Account
            FinServ__FinancialAccount__c finAcc = new FinServ__FinancialAccount__c(
                RecordTypeId = Schema.SObjectType.FinServ__FinancialAccount__c.getRecordTypeInfosByDeveloperName().get('InvestmentAccount').getRecordTypeId(),
                FinServ__Household__c = householdAccountId,
                FinServ__PrimaryOwner__c = prospectAccount.Id,
                FinServ__TaxID__c = prospectAccount.FinServ__TaxId__pc??'',
                SSN_TIN_c__c = prospectAccount.FinServ__TaxId__pc != null?  Integer.valueOf(prospectAccount.FinServ__TaxId__pc): null,
                FABirthday__c = prospectAccount.PersonBirthdate,
                FinServ__Address1__c = prospectAccount.PersonMailingStreet
            );
            Database.SaveResult[] finAccInsertResult = Database.insert(new List<FinServ__FinancialAccount__c>{finAcc}, false);
            if (!finAccInsertResult[0].isSuccess()) {
                System.debug('*********'+finAccInsertResult[0].errors[0].message);
                System.debug('*********'+finAccInsertResult[0].errors[0]);
                res.success = false;
                res.message = 'Financial Account creation on Individual account failed';
                return res;
            }
            res.success = true;
            res.householdId = householdAccountId;
            return res;
        } catch (DmlException e) {
            res.success = false;
            res.message = e.getMessage();
            return res;
        }
    }

    @AuraEnabled
    public static SaveAccountResult processJointAccounts(List<Account> accounts) {

        SaveAccountResult res = new SaveAccountResult();
        if (accounts.size() != 2) {
            res.success = false;
            res.message = 'Primary and Secondary account details are required.';
            return res;
        }
        
        if(accounts[0].RepAdvisor__c == null && accounts[1].RepAdvisor__c == null){
            res.success = false;
            res.message = 'Rep advisor details on Primary and secondary Accounts required';
            return res;
        }
         
        if(accounts[0].RepAdvisor__c == null){
            res.success = false;
            res.message = 'Rep advisor on Primary Account required';
            return res;
        }
         
        if( accounts[1].RepAdvisor__c == null){
            res.success = false;
            res.message = 'Rep advisor on secondary Account required';
            return res;
        }

        if(accounts[0].RepAdvisor__c != accounts[1].RepAdvisor__c) {
            res.success = false;
            res.message = 'Primary and Secondary accounts should be associated to the same Rep Advisor.';
            return res;
        }

        if(accounts[0].FinServ__TaxId__pc != null && !Pattern.matches('\\d{9}', accounts[0].FinServ__TaxId__pc) && accounts[1].FinServ__TaxId__pc != null && !Pattern.matches('\\d{9}', accounts[1].FinServ__TaxId__pc)){
            res.success = false;
            res.message = 'SSN/Tax ID provided on Primary and Secondary Accounts must be 9 numeric digits.';
            return res;
        }

        if(accounts[0].FinServ__TaxId__pc != null && !Pattern.matches('\\d{9}', accounts[0].FinServ__TaxId__pc)){
            res.success = false;
            res.message = 'SSN/Tax ID provided on Primary Account must be 9 numeric digits.';
            return res;
        }

        if(accounts[1].FinServ__TaxId__pc != null && !Pattern.matches('\\d{9}', accounts[1].FinServ__TaxId__pc)){
            res.success = false;
            res.message = 'SSN/Tax ID provided on Secondary Account must be 9 numeric digits.';
            return res;
        }

        if(accounts[0].FinServ__TaxId__pc != null && accounts[1].FinServ__TaxId__pc != null && accounts[0].FinServ__TaxId__pc.equalsIgnoreCase(accounts[1].FinServ__TaxId__pc)){
            res.success = false;
            res.message = 'Primary and Secondary accounts cannot have same SSN.';
            return res;
        }
        if(isSSNExists(accounts[0].FinServ__TaxId__pc) && isSSNExists(accounts[1].FinServ__TaxId__pc)){
            res.success = false;
            res.message = 'SSN/Tax ID provided on Primary and Secondary accounts are already in use.';
            return res;
        }
        
        if(isSSNExists(accounts[0].FinServ__TaxId__pc)){
            res.success = false;
            res.message = 'SSN/Tax ID provided on Primary account is already in use.';
            return res;
        }

        if(isSSNExists(accounts[1].FinServ__TaxId__pc)){
            res.success = false;
            res.message = 'SSN/Tax ID provided on Secondary account is already in use.';
            return res;
        }          
      
        try {
           String hhName = '';

            if(accounts[0].LastName.equalsIgnoreCase(accounts[1].LastName)){
                hhName =  accounts[0].LastName + ', ' + accounts[0].FirstName + ' & '  + accounts[1].FirstName;

            } else {
                hhName =  accounts[0].LastName + ', ' + accounts[0].FirstName + ' & ' + accounts[1].LastName + ', ' + accounts[1].FirstName;
            }

            List<Country_Code_Mapping__mdt> mcList = [Select Id,MasterLabel, Country_Code__c From Country_Code_Mapping__mdt Where MasterLabel =:accounts[0].Employer_Address__CountryCode__s OR MasterLabel =:accounts[1].Employer_Address__CountryCode__s];
            Map<String, String> countryCodeMap = new Map<String, String>();
            for (Country_Code_Mapping__mdt mc : mcList) {
                countryCodeMap.put(mc.MasterLabel, mc.Country_Code__c);
            }
            if(mcList.size() > 0){
                if(countryCodeMap.get(accounts[0].Employer_Address__CountryCode__s) != null) {
                    accounts[0].Employer_Address__CountryCode__s = countryCodeMap.get(accounts[0].Employer_Address__CountryCode__s);
                } else {
                    accounts[0].Employer_Address__CountryCode__s = null;
                }

                if(countryCodeMap.get(accounts[1].Employer_Address__CountryCode__s) != null) {
                    accounts[1].Employer_Address__CountryCode__s = countryCodeMap.get(accounts[1].Employer_Address__CountryCode__s);
                } else {
                    accounts[1].Employer_Address__CountryCode__s = null;
                }
            }
            Account hh = new Account(
                Name = hhName,
                RecordTypeId = Schema.SObjectType.Account.getRecordTypeInfosByDeveloperName().get('IndustriesHousehold').getRecordTypeId(),
                RepAdvisor__c = accounts[0].RepAdvisor__c,
                Employer_Address__City__s = accounts[0].Employer_Address__City__s,
                Employer_Address__StateCode__s = accounts[0].Employer_Address__StateCode__s,
                Employer_Address__Street__s = accounts[0].Employer_Address__Street__s,
                Employer_Address__CountryCode__s = accounts[0].Employer_Address__CountryCode__s,
                Employer_Address__PostalCode__s = accounts[0].Employer_Address__PostalCode__s,
                FinServ__IndividualType__c = 'Group'
            );
            insert hh;
            Id hhId = hh.Id;
            Boolean primaryFlag = true;
            for (Account p : accounts) {
                List<Country_Code_Mapping__mdt> mc = [
                    SELECT Country_Code__c
                      FROM Country_Code_Mapping__mdt
                     WHERE MasterLabel = :p.Employer_Address__CountryCode__s
                     LIMIT 1
                ];
                if (!mc.isEmpty()) p.Employer_Address__CountryCode__s = mc[0].Country_Code__c;
                p.RecordTypeId = Schema.SObjectType.Account.getRecordTypeInfosByDeveloperName().get('PersonAccount').getRecordTypeId();
                insert p;
                Id contactId = [
                    SELECT PersonContactId FROM Account WHERE Id = :p.Id LIMIT 1
                ].PersonContactId;
                upsert new AccountContactRelation(
                    AccountId = hhId,
                    ContactId = contactId,
                    FinServ__PrimaryGroup__c = true,
                    FinServ__Primary__c = primaryFlag,
                    FinServ__Rollups__c = 'Tasks;Events;Financial Accounts;Assets and Liabilities;Financial Goals;All;Referrals;Opportunities',
                    Roles = 'Client'
                );
                
                if(primaryFlag){
                    insert new FinServ__FinancialAccount__c(
                    RecordTypeId = Schema.SObjectType.FinServ__FinancialAccount__c.getRecordTypeInfosByDeveloperName().get('InvestmentAccount').getRecordTypeId(),
                    FinServ__Household__c = hhId,
                    FinServ__PrimaryOwner__c = p.Id,
                    FinServ__TaxID__c = p.FinServ__TaxId__pc != null ?p.FinServ__TaxId__pc:'',
                    SSN_TIN_c__c = p.FinServ__TaxId__pc != null ?Integer.valueOf(p.FinServ__TaxId__pc):null,
                    FABirthday__c = p.PersonBirthdate,
                    FinServ__Address1__c = p.PersonMailingStreet
                    );
                    primaryFlag = false;
                }
            }
            res.success = true;
            res.householdId = hhId;
            return res;
        } catch (DmlException e) {
            res.success = false;
            res.message = e.getMessage();
            return res;
        }
    }

    private static Boolean isSSNExists(String ssn) {
        if (String.isEmpty(ssn)) return false;
        Integer ssnVal = Integer.valueOf(ssn);
        return [
            SELECT Id FROM FinServ__FinancialAccount__c WHERE SSN_TIN_c__c = :ssnVal
        ].size() > 0 || [
            SELECT Id FROM Account WHERE FinServ__TaxId__pc = :ssn AND RecordType.Name != 'Prospect'
        ].size() > 0;
    }

    @AuraEnabled(cacheable=true)
    public static List<StateWrapper> getStateMappings() {
        List<StateWrapper> result = new List<StateWrapper>();
        for (State_Code_Mapping__mdt sm : State_Code_Mapping__mdt.getAll().values()) {
            result.add(new StateWrapper(sm.MasterLabel, sm.State_Code__c));
        }
        return result;
    }

    public class StateWrapper {
        @AuraEnabled public String label;
        @AuraEnabled public String code;
        public StateWrapper(String l, String c) { label = l; code = c; }
    }
}