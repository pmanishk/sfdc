public with sharing class DocusignObjController {
   /* public DocusignObjController() {

    }*/
    @AuraEnabled(cacheable=true)
    public static List<dfsle__RecipientStatus__c> getRelatedListRecords(Id parentRecordId) {
        return [SELECT Id, Name,dfsle__RoutingOrder__c,dfsle__Status__c,dfsle__Email__c  FROM dfsle__RecipientStatus__c 
                WHERE dfsle__EnvelopeStatus__r.DocuSign_Envelope_Record__c = :parentRecordId];
    }
   
}