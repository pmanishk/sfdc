trigger CaseFeedCommentTrigger on FeedComment (after insert, before insert, before update, after update) {
    if(Trigger.IsAfter && Trigger.IsInsert){
        CaseFeedCommentTriggerHandler.afterInsert(Trigger.New, Trigger.OldMap);
    }  
}