public class GenerateDocuSign {
    public String signatures { get; set; }
    public String advisorType {get; set;}
    public String selectedOption { get; set; }
    public List<SelectOption> options { get; set; }
    public Id recordId { get; set; }
    public Map<String, dfsle__EnvelopeConfiguration__c> envelopeMap = new Map<String, dfsle__EnvelopeConfiguration__c>();
    
    // Added to manage display logic
    public String displayFinAccList { get; set; }
    public String displayRadioButtons { get; set; }
    public String displayGenDoc { get; set; }
    public List<SelectOption> financialAccountOptions { get; set; } 
    public Id selectedFinancialAccountId { get; set; }
    
    // Constructor
    public GenerateDocuSign() {  
        recordId = ApexPages.currentPage().getParameters().get('id');
        displayFinAccList = 'none';
        displayRadioButtons = 'none';
        displayGenDoc = 'none';
        financialAccountOptions = new List<SelectOption>();
        financialAccountOptions.add(new SelectOption('', '--None--'));
        signatures = 'E-Sign';
       
        List<FinServ__FinancialAccount__c> financialAccList  = [SELECT Id, Name, FinServ__PrimaryOwner__r.Name, RegistrationName__c FROM FinServ__FinancialAccount__c WHERE FinServ__Household__c = :recordId];
        for (FinServ__FinancialAccount__c finAcc : financialAccList) {             
           financialAccountOptions.add(new SelectOption(finAcc.Id, finAcc.FinServ__PrimaryOwner__r.name + ((finAcc.RegistrationName__c !='' && finAcc.RegistrationName__c != null)?(' - ' + finAcc.RegistrationName__c):'') + ' - ' + finAcc.Name ));
        }
        
        if (financialAccList.size() == 0) {
            viewEnvelopes(recordId);
            displayGenDoc = 'block';
        } else {
            displayFinAccList = 'block';
        }
    }
    
    public void finAccSelect() {
        if (String.isNotBlank(selectedFinancialAccountId)) { 
            displayGenDoc = 'block';
            recordId = selectedFinancialAccountId;
            viewEnvelopes(selectedFinancialAccountId);
        } else {
            displayGenDoc = 'none';
        }
    }
    
    public void viewEnvelopes(Id financialAccId) {
        User currentUser = [SELECT Profile.Name, Advisor_Type__c FROM User WHERE Id = :UserInfo.getUserId() AND IsActive = TRUE LIMIT 1];
        //profile = currentUser.Profile.Name;
        
        options = new List<SelectOption>(); 
        options.add(new SelectOption('', '--None--'));
        
        if( currentUser.Profile.Name == 'System Administrator'){       // System Administrator Profile Users           
            displayRadioButtons = 'block';
            
            // Logic to handle updates based on selected radio button
            if (String.isNotBlank(signatures) && (signatures == 'In-Person' )) {
                options.clear(); // Clear existing options
                options.add(new SelectOption('', '----None----'));
                
                // Populate options based on the selected signature type
                List<dfsle__EnvelopeConfiguration__c> docuTemplateList = [SELECT Id, Name FROM dfsle__EnvelopeConfiguration__c WHERE Name LIKE '%In-Person%'  ORDER BY Name];
                for (dfsle__EnvelopeConfiguration__c temp : docuTemplateList) {
                    options.add(new SelectOption(temp.Id, temp.Name));
                    envelopeMap.put(temp.Id, temp);
                }
            } else if (String.isNotBlank(signatures) && (signatures == 'E-Sign' )) {
                options.clear(); // Clear existing options
                options.add(new SelectOption('', '----None----'));
                // Populate options based on the selected signature type
                List<dfsle__EnvelopeConfiguration__c> docuTemplateList = [SELECT Id, Name FROM dfsle__EnvelopeConfiguration__c WHERE NOT (Name LIKE '%In-Person%') ORDER BY Name];
                for (dfsle__EnvelopeConfiguration__c temp : docuTemplateList) {
                    options.add(new SelectOption(temp.Id, temp.Name));
                    envelopeMap.put(temp.Id, temp);
                } 
            }
        }
        else { // Primary Agent Profile Users      
            String advisorType = 'User_Advisor_Type_' + currentUser.Advisor_Type__c;
            
            // Fetch accessible form names based on the Advisor_Type__c and signingType
            List<String> accessibleFormNames = advisorType != '' ? System.Label.get('', advisorType).split(';') : new List<String>();
            
            // Query to get DocuSign template configurations
            List<dfsle__EnvelopeConfiguration__c> docuTemplateList = [SELECT Id, Name FROM dfsle__EnvelopeConfiguration__c WHERE ( NOT (Name LIKE '%In-Person%') ) AND Name IN :accessibleFormNames ORDER BY Name];
            for (dfsle__EnvelopeConfiguration__c temp : docuTemplateList) {
                options.add(new SelectOption(temp.Id, temp.Name));
                envelopeMap.put(temp.Id, temp);
            }
        }
    }
    public List<SelectOption> getItems() {
        List<SelectOption> options = new List<SelectOption>(); 
        options.add(new SelectOption('E-Sign', 'E-Signature')); 
        options.add(new SelectOption('In-Person', 'In-Person Signature')); 
        return options; 
    }
    
    public void updateSelectList() { 
        // Logic to handle updates based on selected radio button
        if (String.isNotBlank(signatures) && (signatures == 'In-Person' )) {
            options.clear(); // Clear existing options
            options.add(new SelectOption('', '----None----'));
            
            // Populate options based on the selected signature type
            List<dfsle__EnvelopeConfiguration__c> docuTemplateList = [SELECT Id, Name FROM dfsle__EnvelopeConfiguration__c WHERE Name LIKE '%In-Person%'  ORDER BY Name];
            for (dfsle__EnvelopeConfiguration__c temp : docuTemplateList) {
                options.add(new SelectOption(temp.Id, temp.Name));
                envelopeMap.put(temp.Id, temp);
            }
        } else if (String.isNotBlank(signatures) && (signatures == 'E-Sign' )) {
            options.clear(); // Clear existing options
            options.add(new SelectOption('', '----None----'));
            // Populate options based on the selected signature type
            List<dfsle__EnvelopeConfiguration__c> docuTemplateList = [SELECT Id, Name FROM dfsle__EnvelopeConfiguration__c WHERE NOT (Name LIKE '%In-Person%') ORDER BY Name];
            for (dfsle__EnvelopeConfiguration__c temp : docuTemplateList) {
                options.add(new SelectOption(temp.Id, temp.Name));
                envelopeMap.put(temp.Id, temp);
            }
        }
    }
    public PageReference navigate() {
        if (String.isNotBlank(selectedOption)) {
            String url = '/apex/dfsle__sending';
            dfsle__EnvelopeConfiguration__c template = envelopeMap.get(selectedOption);
            PageReference pageRef = new PageReference(url);
            pageRef.getParameters().put('sId', recordId);
            pageRef.getParameters().put('sendingExperience', 'null');
            pageRef.getParameters().put('isEmbedded', 'false');
            pageRef.getParameters().put('templateId', template.Id);
            pageRef.getParameters().put('recordId', recordId);
            pageRef.getParameters().put('title', template.Name);
            pageRef.setRedirect(true);
            return pageRef;
        }
        return null;
    }
    public PageReference refresh() {
        recordId = ApexPages.currentPage().getParameters().get('id');
        // Reset display properties
        displayFinAccList = 'none';
        displayRadioButtons = 'none';
        displayGenDoc = 'none';
        selectedFinancialAccountId = null;
        selectedOption = null;
        signatures = 'E-Sign'; // Or your default signature value
        
        // Re-fetch Financial Accounts
        financialAccountOptions = new List<SelectOption>();
        financialAccountOptions.add(new SelectOption('', '--None--'));
        List<FinServ__FinancialAccount__c> financialAccList  = [SELECT Id, Name FROM FinServ__FinancialAccount__c WHERE FinServ__Household__c = :recordId];
        for (FinServ__FinancialAccount__c finAcc : financialAccList) {
            financialAccountOptions.add(new SelectOption(finAcc.Id, finAcc.Name));
        }
        
        // Determine visibility based on the re-fetched financial accounts
        if (financialAccList.size() == 0) {
            viewEnvelopes(recordId);
            displayGenDoc = 'block';
        } else {
            displayFinAccList = 'block';
        }
        
        // Refresh the available DocuSign templates
        viewEnvelopes(recordId);
        
        return null;
    }
    
}