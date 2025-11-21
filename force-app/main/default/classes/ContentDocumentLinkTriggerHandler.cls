public class ContentDocumentLinkTriggerHandler {
    public static void shareFile(List<ContentDocumentLink> cdlListNew){
        set<Id> cdSet = New set<Id>();
        Map<Id,Set<Id>> cdSetSharedMap = New Map<Id,Set<Id>>();
        List<User> usersWithProfile = [SELECT Id FROM User WHERE IsActive = True AND Profile.Name IN ('Sound Income Operations User', 'Sound Income Trading and Allocation users')];
        List<ContentDocumentLink> cdlList = New List<ContentDocumentLink>();
        for(ContentDocumentLink cdl : cdlListNew){
            cdSet.add(cdl.ContentDocumentId);
        }
        for(ContentDocumentLink cdl : [SELECT LinkedEntityId,LinkedEntity.Name,LinkedEntity.Type, ContentDocumentId FROM ContentDocumentLink WHERE ContentDocumentId IN:cdSet ]){
            if(!cdSetSharedMap.containsKey(cdl.ContentDocumentId)){
                cdSetSharedMap.put(cdl.ContentDocumentId, New Set<Id>());
            }
            cdSetSharedMap.get(cdl.ContentDocumentId).add(cdl.LinkedEntityId);
        }
        for(ContentDocumentLink cdl : cdlListNew){
            String objName = cdl.LinkedEntityId.getSObjectType().getDescribe().getName();
            if(cdSet.contains(cdl.ContentDocumentId) && (objName =='EmailMessage' || objName =='Case')){
                for(user u : usersWithProfile){
                    if(cdSetSharedMap.containsKey(cdl.ContentDocumentId) && !cdSetSharedMap.get(cdl.ContentDocumentId).contains(u.Id)){
                        ContentDocumentLink cdlVar = new ContentDocumentLink(ContentDocumentId = cdl.ContentDocumentId , LinkedEntityId = u.Id, ShareType = 'C', Visibility = 'AllUsers');
                        cdlList.add(cdlVar);
                    }
                }
            }
        }
        if(cdlList.size() > 0) Insert cdlList; 
    }
}