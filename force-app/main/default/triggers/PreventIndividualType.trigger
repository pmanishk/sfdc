trigger PreventIndividualType on Account (before insert, before update) {
    for (Account acc : Trigger.new) {
        if (acc.IsPersonAccount) {
            acc.FinServ__IndividualType__c = null;
        }
    }
}