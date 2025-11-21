trigger CaseEmailMessageTrigger on EmailMessage (after insert, after update) {
    if (Trigger.isAfter && (Trigger.isInsert || Trigger.isUpdate)) {
        CaseEmailMessageTriggerHandler.process(Trigger.new);
    }
}