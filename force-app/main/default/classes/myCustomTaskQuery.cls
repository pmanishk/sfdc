public with sharing class myCustomTaskQuery {
   
    Task myTask;
   
    public myCustomTaskQuery(ApexPages.StandardController con) {       
        Id myTaskId = (Id) System.currentPageReference().getParameters().get('id');   
        myTask = [SELECT Id, WhoId, WhatId, AccountId, Account.HouseholdAC__c FROM Task WHERE IsDeleted = false AND Id = :myTaskId LIMIT 1 ALL ROWS];
    }
    public Task getMyTask() {
        return myTask;
    } 
}