trigger TriggerLinkDocusign on dfsle__EnvelopeStatus__c (before update) {
   DocusignContentClass.linkDocuSignToFinancialAccount(Trigger.New);
}