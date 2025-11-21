global class CaseEmailQuickActionDefaultsHandler implements QuickAction.QuickActionDefaultsHandler {
    private static final Map<String, String> QUEUE_EMAILS = new Map<String, String>{
        'Trading Check'         => 'trading-sis@soundincomestrategies.com',
        'SIS Account services'  => 'accountservices-sis@soundincomestrategies.com',
        'SIS Allocations'       => 'allocations-sis@soundincomestrategies.com',
        'SIS Billing'           => 'billing-sis@soundincomestrategies.com',
        'SIS Liquidations'      => 'liquidations-sis@soundincomestrategies.com',
        'IT HELP DESK'          => 'tech-sis@soundincomegroup.com',
        'SIS OPERATIONS'        => 'operations-sis@soundincomestrategies.com'
    };

    global CaseEmailQuickActionDefaultsHandler() {}

    global void onInitDefaults(QuickAction.QuickActionDefaults[] defaults) {
        for (QuickAction.QuickActionDefaults actionDefault : defaults) {
            if (actionDefault instanceof QuickAction.SendEmailQuickActionDefaults) {
                QuickAction.SendEmailQuickActionDefaults sendEmailDefaults = 
                    (QuickAction.SendEmailQuickActionDefaults)actionDefault;
                handleEmailDefaults(sendEmailDefaults.getContextId(), 
                                    (EmailMessage)sendEmailDefaults.getTargetSObject());
            }
        }
    }

    // NEW testable method
    @testVisible
    static void handleEmailDefaults(Id caseId, EmailMessage emailMsg) {
        User currentUser = [SELECT Profile.Name FROM User WHERE Id = :UserInfo.getUserId()];
        Case c = [SELECT Id, OwnerId, Contact.Email, Owner.Type, Owner.Name, Owner.Email 
                  FROM Case WHERE Id = :caseId LIMIT 1];

        //Boolean isSysAdmin = currentUser.Profile.Name == 'System Administrator';
        Boolean isPA = currentUser.Profile.Name == 'Primary Agent';

        String queueEmail = null;

        if (c.Owner.Type == 'Queue' && c.Owner.Name != null && QUEUE_EMAILS.containsKey(c.Owner.Name)) {
            queueEmail = QUEUE_EMAILS.get(c.Owner.Name);
        } else if (c.Owner.Type == 'User' && c.Owner.Email != null) {
            queueEmail = c.Owner.Email;
        }

        String contactEmail = c.Contact != null ? c.Contact.Email : null;

          if (isPA) {
            if (contactEmail != null) emailMsg.ValidatedFromAddress = UserInfo.getUserEmail();
            if (queueEmail != null) emailMsg.ToAddress = queueEmail;
        }
        else {
            if (queueEmail != null) emailMsg.ValidatedFromAddress = queueEmail;
            if (contactEmail != null) emailMsg.ToAddress = contactEmail;
        }
    }
}