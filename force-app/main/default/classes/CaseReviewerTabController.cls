public with sharing class CaseReviewerTabController {
    @AuraEnabled(cacheable=true)
    public static List<String> getFieldSetFields() {
        List<String> fieldNames = new List<String>();
        
        // Describe the field set
        Schema.FieldSet fieldSet = Schema.SObjectType.Case.FieldSets.getMap().get('Case_Reivewer_Tab_Fields');
        
        // Iterate through field set fields and get the field API names
        for (Schema.FieldSetMember field : fieldSet.getFields()) {
            fieldNames.add(field.getFieldPath());
        }
        
        return fieldNames;
    }

    
    @AuraEnabled(cacheable=true)
    public static Id getFieldHistoryRecord(String caseId) {
        for(CaseHistory ch : [SELECT Id, Field, NewValue, OldValue FROM CaseHistory WHERE CaseId = :caseId AND Field = 'Householding_Complete__c' order by createddate asc LIMIT 1 ]){
            if(String.valueOf(ch.newValue).equalsIgnoreCase('true')){
                return ch.Id;
            }
        }
        return null; 
    }

}