trigger removeHHLink on AccountContactRelation (before delete) {
    List<Id> cons = new List<Id>();
    for (AccountContactRelation acr : Trigger.old) {
        if (acr.FinServ__PrimaryGroup__c) {
           cons.add(acr.ContactId);
        }
    }
    if (cons.size() > 0) {
        List<Contact> consToRemoveHHLink = [select AccountId from Contact where Id in :cons];
        List<Account> acctsToUpdate = new List<Account>();
        
        for (Contact con : consToRemoveHHLink) {
           Account acct = new Account(Id = con.AccountId);
           acct.HouseholdAC__c = null;
           acctsToUpdate.add(acct);
        }
        update acctsToUpdate;
    }
}