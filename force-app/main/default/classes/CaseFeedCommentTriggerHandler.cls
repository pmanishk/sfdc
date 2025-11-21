Public class CaseFeedCommentTriggerHandler{
    
    public static void afterInsert(List<FeedComment> FeedCommentListNew ,Map<Id,FeedComment> FeedCommentMapOld){
        Id profileId=userinfo.getProfileId();
        String profileName = [Select Id,Name from Profile where Id=:profileId].Name;
        Set<Id> feedItemIds = New Set<Id>();
        List<Case> CaseList = New List<Case>();
        if(profileName == 'Primary Agent'){
            for (FeedComment comment : FeedCommentListNew) {
                feedItemIds.add(comment.FeedItemId);
            }           
            for(FeedItem feedItemVar : [SELECT Id, ParentId, CreatedById, CreatedBy.Name, Parent.Type
                                           FROM FeedItem WHERE Id IN: feedItemIds]){
                                           
                if (feedItemVar.Parent.Type == 'Case') {
                    Case caseVar = New Case();
                    caseVar.Id = feedItemVar.ParentId;
                    caseVar.Override_Status__c = 'Customer Responded';
                    CaseList.add(caseVar);
                }
            }
            
            if(CaseList.size() > 0){
                update CaseList;
            }
        }
    }

}