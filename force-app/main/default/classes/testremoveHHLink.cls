@istest
public class testremoveHHLink {
    
    public static testMethod void testMyController() {
        Account acct = new Account(Name = 'test');
        insert acct;

        Id rtId = Schema.SObjectType.Account.getRecordTypeInfosByDeveloperName().get('PersonAccount').getRecordTypeId();        
        Account pa = new Account(LastName = 'test', RecordTypeId = rtId);
        insert pa;
        
        Id pcId = [select PersonContactId from Account where Id = :pa.Id].PersonContactId;
        
        AccountContactRelation acr = new AccountContactRelation(FinServ__PrimaryGroup__c = true, ContactId = pcId, AccountId = acct.Id);
        insert acr;
        delete acr;
    }
}