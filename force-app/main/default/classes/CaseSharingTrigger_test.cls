@isTest (SeeAllData=true) 
private class CaseSharingTrigger_test {
     @isTest
    static void testCaseSharingTriggerUpdateAccount1() {
       	test.startTest();
        Account acc = [Select id, repAdvisor__r.repAdvisorEntity__c from Account where isPersonAccount=true and repAdvisor__r.repAdvisorEntity__c !='' limit 1];
        Case c = [Select id, AccountId from case where accountId !='' and accountId != :acc.id and account.repAdvisor__r.repAdvisorEntity__c != :acc.repAdvisor__r.repAdvisorEntity__c limit 1];
        if(acc != null && c !=null){
            c.accountId = acc.id;
        	Update c;
        }
        
        test.stopTest();
    }
    
    @isTest
    static void testCaseSharingTriggerUpdateHouseHold() {
       	test.startTest();
        Account acc = [Select id, repAdvisor__r.repAdvisorEntity__c from Account where isPersonAccount=false and repAdvisor__r.repAdvisorEntity__c !='' limit 1];
        Case c = [Select id, AccountId from case where accountId !='' and Household_Account__c != :acc.id and Household_Account__r.repAdvisor__r.repAdvisorEntity__c != :acc.repAdvisor__r.repAdvisorEntity__c limit 1];
        if(acc != null && c !=null){
            c.Household_Account__c = acc.id;
        	Update c;
        }
        test.stopTest();
    }
    
    @isTest
    static void testCaseSharingTriggerUpdateContact() {
       	test.startTest();
        Contact con = [Select id, repAdvisorEntity__c from Contact where repAdvisorEntity__c !='' limit 1];
        Case c = [Select id, ContactId from case where ContactId !='' and ContactId != :con.id and contact.repAdvisorEntity__c != :con.repAdvisorEntity__c limit 1];
        if(con != null && c !=null){
            c.ContactId = con.id;
        	Update c;
        }
        test.stopTest();
    }
}