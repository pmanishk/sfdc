public class DocusignApiClass2 {
    
    //refer current prod account id
    private static final String DOCUSIGN_ENDPOINT = 'callout:Docusign_API/v2.1/accounts/10866685/envelopes/{envelopeId}/form_data';
    
    @future(callout=true)
    public static void processCompletedEnvelope1(String envelopeId) {
        try {
            HttpRequest req = new HttpRequest();
            req.setEndpoint(DOCUSIGN_ENDPOINT.replace('{envelopeId}', envelopeId));
            req.setMethod('GET');
            req.setHeader('Content-Type', 'application/json');
            
            Http http = new Http();
            HttpResponse res = http.send(req);
            
            if (res.getStatusCode() == 200) {
                System.debug('Successfully retrieved form data: ' + res.getBody());
                
                Map<String, Object> formData = (Map<String, Object>) JSON.deserializeUntyped(res.getBody());
                Map<String, List<String>> selectedCheckboxGroups = new Map<String, List<String>>();
                
                List<Object> formFields = (List<Object>) formData.get('formData');
                for (Object fieldObj : formFields) {
                    Map<String, Object> field = (Map<String, Object>) fieldObj;
                    String fieldLabel = (String) field.get('name');
                    String fieldValue = (String) field.get('value');
                    
                    // Use independent if conditions for each checkbox group
                    /*if (fieldLabel.contains('Checkbox Group a3f4e10a-9420-4360-94c0-8786e4a3ca95')) {
                        addCheckboxValue('Reason_for_Liquidation_test__c', fieldLabel, fieldValue, selectedCheckboxGroups);
                    }*/
                    if (fieldLabel.contains('Checkbox Group 60d1ad9f-0df2-4701-a0d1-1770d5794166')) {
                        addCheckboxValue('Income_Tax_Planning_Topics_to_Address__c', fieldLabel, fieldValue, selectedCheckboxGroups);
                    }
                    if (fieldLabel.contains('Checkbox Group ee6c737f-1cac-40cd-baeb-7d8d7db858a5')) {
                        addCheckboxValue('Insurance_Planning_Topics_to_Address__c', fieldLabel, fieldValue, selectedCheckboxGroups);
                    }
                    if (fieldLabel.contains('Checkbox Group 3166d618-03e8-4839-8c24-4f7075749c73')) {
                        addCheckboxValue('Retirement_Planning_Topics_to_Address__c', fieldLabel, fieldValue, selectedCheckboxGroups);
                    }
                    if (fieldLabel.contains('Checkbox Group c8259c13-f67d-4394-8c19-04c72e229d21')) {
                        addCheckboxValue('EP_WT_Topics_Addressed__c', fieldLabel, fieldValue, selectedCheckboxGroups);
                    }
                    if (fieldLabel.contains('Checkbox Group dbfbe24c-8018-4a04-935e-aadb2cd1004c')) {
                        addCheckboxValue('Special_Needs_Topics_to_be_Addressed__c', fieldLabel, fieldValue, selectedCheckboxGroups);
                    }
                    if (fieldLabel.contains('Checkbox Group a3704fd7-f6fe-4dd4-a30c-8b41de013ddf')) {
                        addCheckboxValue('Personal_financial_statement_analysis__c', fieldLabel, fieldValue, selectedCheckboxGroups);
                    }
                    if (fieldLabel.contains('Checkbox Group c2608024-e2f2-42cb-bcf8-118919ded825')) {
                        addCheckboxValue('Debt_Management_Restructuring__c', fieldLabel, fieldValue, selectedCheckboxGroups);
                    }
                    if (fieldLabel.contains('Checkbox Group 178477d8-0e3e-4f2b-ba85-2ccefa15a22a')) {
                        addCheckboxValue('Cash_Flow__c', fieldLabel, fieldValue, selectedCheckboxGroups);
                    }
                    if (fieldLabel.contains('Checkbox Group 5b924a25-37dd-4f5c-88ed-a8a554fc1eca')) {
                        addCheckboxValue('Current_Portfolio_Analysis__c', fieldLabel, fieldValue, selectedCheckboxGroups);
                    }
                    if (fieldLabel.contains('Checkbox Group 3107481e-e702-4e8b-932f-69139e4f5353')) {
                        addCheckboxValue('Pros_Cons_of_Investing_for_Income_or_Gro__c', fieldLabel, fieldValue, selectedCheckboxGroups);
                    }
                    if (fieldLabel.contains('Checkbox Group 52f7ce5d-751a-42d2-87f4-e8a02cea0e86')) {
                        addCheckboxValue('Pre_retirement_Investment_Advice__c', fieldLabel, fieldValue, selectedCheckboxGroups);
                    }
                }
                
                System.debug('Selected Topics by Group: ' + selectedCheckboxGroups);
                
                updateFinancialAccount(envelopeId, selectedCheckboxGroups);
                
            } else {
                System.debug('Failed to retrieve envelope form data. Status Code: ' + res.getStatusCode());
                System.debug('Response: ' + res.getBody());
            }
            
        } catch (Exception e) {
            System.debug('Error in processCompletedEnvelope: ' + e.getMessage());
        }
    }
    
    private static void addCheckboxValue(String fieldName, String fieldLabel, String fieldValue, Map<String, List<String>> selectedCheckboxGroups) {
        System.debug('Processing addCheckboxValue: fieldName=' + fieldName + ', fieldLabel=' + fieldLabel + ', fieldValue=' + fieldValue);
        
        if (!selectedCheckboxGroups.containsKey(fieldName)) {
            selectedCheckboxGroups.put(fieldName, new List<String>());
        }
        
        if (!String.isEmpty(fieldValue) && fieldValue.contains('X')) {
            String mappedValue = getMappedValue(fieldName, fieldLabel);
            if (mappedValue != null && !String.isEmpty(mappedValue)) {
                selectedCheckboxGroups.get(fieldName).add(mappedValue);
                System.debug('Added value: ' + mappedValue + ' to selectedCheckboxGroups for fieldName: ' + fieldName);
            } else {
                System.debug('No mapped value found for fieldLabel: ' + fieldLabel);
            }
        } else {
            System.debug('FieldValue is empty or does not contain "X": ' + fieldValue);
        }
    }
    
    private static String getMappedValue(String fieldName, String fieldLabel) {
        System.debug('Mapping fieldName: ' + fieldName + ' with fieldLabel: ' + fieldLabel);
        String cleanedLabel = fieldLabel.split('\\|')[0].trim();
        System.debug('Mapping fieldName: ' + fieldName + ' with cleanedLabel: ' + cleanedLabel);
        
        /*if (fieldName == 'Reason_for_Liquidation_test__c') {
if (cleanedLabel == 'Systematic Withdrawal per month') return 'Systematic Withdrawal per month';
if (cleanedLabel == 'Client Request') return 'Client Request';
if (cleanedLabel == 'Hold Cash') return 'Hold Cash';
if (cleanedLabel == 'Other') return 'Other';
if (cleanedLabel == 'One Time Distribution/Withdrawal') return 'One Time Distribution/Withdrawal';
}
System.debug('No mapped value found for cleanedLabel: ' + cleanedLabel);*/
        
        if (fieldName == 'Income_Tax_Planning_Topics_to_Address__c') {
            if (cleanedLabel == 'RMD Calculations') return 'RMD Calculations';
            if (cleanedLabel == 'Tax treatment for current investments') return 'Tax treatment for current investments';
            if (cleanedLabel == 'Contribution limits and tax treatment of various retirement accounts(Trad. IRA, 401k,403b,ROTH IRA)') return 'Contribution limits and tax treatment of various retirement accounts(Trad. IRA, 401k,403b,ROTH IRA)';
            if (cleanedLabel == 'Estimated tax on social security earnings, passive income, and other sources of retirement income') return 'Estimated tax on social security earnings, passive income, and other sources of retirement income';
            if (cleanedLabel == 'ROTH IRA conversions') return 'ROTH IRA conversions';
            if (cleanedLabel == 'Tax treatment for annuities') return 'Tax treatment for annuities';
            if (cleanedLabel == 'Strategies to lower taxes') return 'Strategies to lower taxes';
        }
        
        if (fieldName == 'Insurance_Planning_Topics_to_Address__c') {
            if (cleanedLabel == 'Review current insurance policies(Life, disability, LTC)') return 'Review current insurance policies(Life, disability, LTC)';
            if (cleanedLabel == 'Options to your current policies') return 'Options to your current policies';
            if (cleanedLabel == 'Survivor income needs analysis') return 'Survivor income needs analysis';
            if (cleanedLabel == 'Pension maximization utilizing life insurance') return 'Pension maximization utilizing life insurance';
            if (cleanedLabel == 'Understanding ILITs(Irrevocable life Insurance Trusts)') return 'Understanding ILITs(Irrevocable life Insurance Trusts)';
            if (cleanedLabel == 'Life Insurance as an investment vehicle') return 'Life Insurance as an investment vehicle';
        }
        
        if (fieldName == 'Retirement_Planning_Topics_to_Address__c') {
            if (cleanedLabel == 'Analysis of retirement goals in relation to current retirement savings plan') return 'Analysis of retirement goals in relation to current retirement savings plan';
            if (cleanedLabel == 'Alternative retirement investment options') return 'Alternative retirement investment options';
            if (cleanedLabel == 'Estimated retirement cash flow') return 'Estimated retirement cash flow';
            if (cleanedLabel == 'Estimated retirement income and taxes') return 'Estimated retirement income and taxes';
            if (cleanedLabel == 'Estimated retirement expenses') return 'Estimated retirement expenses';
            if (cleanedLabel == 'Early retirement analysis') return 'Early retirement analysis';
            if (cleanedLabel == 'Pensions and survivorship options') return 'Pensions and survivorship options';
            if (cleanedLabel == 'Characteristics of Individual Retirement Accounts(Traditional IRA, Roth IRA, SEP, SIMPLE)') return 'Characteristics of Individual Retirement Accounts(Traditional IRA, Roth IRA, SEP, SIMPLE)';
        }
        
        if (fieldName == 'EP_WT_Topics_Addressed__c') {
            if (cleanedLabel == 'Review of assets/finances to determine if estate planning is necessary(minimum fee applies)') return 'Review of assets/finances to determine if estate planning is necessary(minimum fee applies)';
            if (cleanedLabel == 'Review of current estate planning documents to determine current planning') return 'Review of current estate planning documents to determine current planning';
            if (cleanedLabel == 'Complete Estate Planning Package(3rd party - additional fees apply)') return 'Complete Estate Planning Package(3rd party - additional fees apply)';
            if (cleanedLabel == 'Discussion of estate planning goals and desires') return 'Discussion of estate planning goals and desires';
            if (cleanedLabel == 'Estate/death tax estimate including general techniques to reduce tax impact, probate and transfer costs') return 'Estate/death tax estimate including general techniques to reduce tax impact, probate and transfer costs';
            if (cleanedLabel == 'Estate Liquidity and survivor income analysis') return 'Estate Liquidity and survivor income analysis';
            if (cleanedLabel == 'Gifting/Charitable strategies') return 'Gifting/Charitable strategies';
            if (cleanedLabel == 'Estate Planning strategies for protecting a person with a disability') return 'Estate Planning strategies for protecting a person with a disability';
            if (cleanedLabel == 'Estate Planning for minor children or special needs dependents') return 'Estate Planning for minor children or special needs dependents';
            if (cleanedLabel == 'Use and types of trusts for Estate planning, power of Attorney options, Healthcare & advance directives') return 'Use and types of trusts for Estate planning, power of Attorney options, Healthcare & advance directives';
            if (cleanedLabel == 'Work with an attorney to establish estate documents that may include Wills, family trusts, ILITs, and more.') return 'Work with an attorney to establish estate documents that may include Wills, family trusts, ILITs, and more.';
            if (cleanedLabel == 'Assists special needs families with updating beneficiaries in outside financial accounts accordingly and train those appointed on their financial responsibilities.') return 'Assists special needs families with updating beneficiaries in outside financial accounts accordingly and train those appointed on their financial responsibilities.';
            if (cleanedLabel == 'Work with an attorney to establish power of attorney and medical directives') return 'Work with an attorney to establish power of attorney and medical directives';
        }
        
        if (fieldName == 'Special_Needs_Topics_to_be_Addressed__c') {
            if (cleanedLabel == 'Funding assessments related to potential costs to care for the person(s) with a disability - both annually and lifelong, with/without government benefits') return 'Funding assessments related to potential costs to care for the person(s) with a disability - both annually and lifelong, with/without government benefits';
            if (cleanedLabel == 'Financial planning that may include multigenerational funding needs, including parents, as well as the lifelong needs of the person with a disability') return 'Financial planning that may include multigenerational funding needs, including parents, as well as the lifelong needs of the person with a disability';
            if (cleanedLabel == 'Thorough look at all available tools such as ABLE accounts, and funding of special needs trusts.') return 'Thorough look at all available tools such as ABLE accounts, and funding of special needs trusts.';
            if (cleanedLabel == 'Thorough discussion of financial decision-making options and protections needed') return 'Thorough discussion of financial decision-making options and protections needed';
            if (cleanedLabel == 'Discussions of trustee, guardians, custodians, supported decision-makers, micro board appointees, and more as applicable.') return 'Discussions of trustee, guardians, custodians, supported decision-makers, micro board appointees, and more as applicable.';
            if (cleanedLabel == 'Access need and eligibility for government benefits. Assist family in applying for benefits, assist in completing paperwork, and act as liaison and advocate where needed.') return 'Access need and eligibility for government benefits. Assist family in applying for benefits, assist in completing paperwork, and act as liaison and advocate where needed.';
        }
        
        if (fieldName == 'Personal_financial_statement_analysis__c') {
            if (cleanedLabel == 'Assets and Liabilities') return 'Assets and Liabilities';
            if (cleanedLabel == 'Net Worth Analysis') return 'Net Worth Analysis';
            if (cleanedLabel == 'Asset and Liability ownership') return 'Asset and Liability ownership';
            if (cleanedLabel == 'Inventory of personal property') return 'Inventory of personal property';
        }
        
        if (fieldName == 'Debt_Management_Restructuring__c') {
            if (cleanedLabel == 'Home purchase, Refinance, or Home Equity line of credit analysis') return 'Home purchase, Refinance, or Home Equity line of credit analysis';
            if (cleanedLabel == 'Mortgage amortization and payment acceleration analysis') return 'Mortgage amortization and payment acceleration analysis';
            if (cleanedLabel == 'Credit card and other debt analysis') return 'Credit card and other debt analysis';
            if (cleanedLabel == 'Analysis of debt pay off options') return 'Analysis of debt pay off options';
        }
        
        if (fieldName == 'Cash_Flow__c') {
            if (cleanedLabel == 'Calculation of cash flows, liquidity, and cash reserve needs') return 'Calculation of cash flows, liquidity, and cash reserve needs';
            if (cleanedLabel == 'Budget & Spending analysis') return 'Budget & Spending analysis';
            if (cleanedLabel == 'Other factors affecting cash flow') return 'Other factors affecting cash flow';
        }
        
        if (fieldName == 'Current_Portfolio_Analysis__c') {
            if (cleanedLabel == 'In-depth analysis of all current investments') return 'In-depth analysis of all current investments';
            if (cleanedLabel == 'Risk/Reward discussion of various classes of securities and other investment options') return 'Risk/Reward discussion of various classes of securities and other investment options';
            if (cleanedLabel == 'Portfolio re-allocation recommendations to achieve financial goals') return 'Portfolio re-allocation recommendations to achieve financial goals';
            if (cleanedLabel == 'Projected values of current accounts over a specific timeframe and an assumed rate of return') return 'Projected values of current accounts over a specific timeframe and an assumed rate of return';
        }
        
        if (fieldName == 'Pros_Cons_of_Investing_for_Income_or_Gro__c') {
            if (cleanedLabel == 'Discussion on which type of securities to use to achieve income, growth, or both') return 'Discussion on which type of securities to use to achieve income, growth, or both';
            if (cleanedLabel == 'Risk/Reward factors to consider before deciding which method is best for you') return 'Risk/Reward factors to consider before deciding which method is best for you';
            if (cleanedLabel == 'Inflation – how might it affect your decision on income, growth, or both') return 'Inflation – how might it affect your decision on income, growth, or both';
        }
        
        if (fieldName == 'Pre_retirement_Investment_Advice__c') {
            if (cleanedLabel == 'Evaluation of your current retirement investment strategy') return 'Evaluation of your current retirement investment strategy';
            if (cleanedLabel == 'Alternatives to your current plan') return 'Alternatives to your current plan';
            if (cleanedLabel == 'Calculation of how much of a “Nest Egg” you will have in retirement, based on your current plan') return 'Calculation of how much of a “Nest Egg” you will have in retirement, based on your current plan';
            if (cleanedLabel == 'Calculate how much of a “Nest Egg” you’ll need based on your retirement “vision”') return 'Calculate how much of a “Nest Egg” you’ll need based on your retirement “vision”';
        }
        
        System.debug('No mapped value found for cleanedLabel: ' + cleanedLabel);
        return '';
    }
    
    private static void updateFinancialAccount(String envelopeId, Map<String, List<String>> selectedTopics) {
        List<dfsle__EnvelopeStatus__c> envelopeStatusList = [
            SELECT Id, Financial_Account__c,DocuSign_Envelope_Record__r.Envelope_Name__c FROM dfsle__EnvelopeStatus__c 
            WHERE dfsle__DocuSignId__c = :envelopeId AND DocuSign_Envelope_Record__r.Envelope_Name__c = 'Financial Planning Consulting Agreement' LIMIT 1
        ];
        if (envelopeStatusList.isEmpty()) {
            System.debug('No Envelope Status found for the given envelope ID');
            return;
        }
        
        dfsle__EnvelopeStatus__c envelopeStatus = envelopeStatusList[0];
        if (envelopeStatus.Financial_Account__c == null) {
            System.debug('No Financial Account found for the given envelope status');
            return;
        }
        
        FinServ__FinancialAccount__c financialAccount = [
            SELECT Id, Reason_for_Liquidation_test__c, Income_Tax_Planning_Topics_to_Address__c, 
            Insurance_Planning_Topics_to_Address__c, Retirement_Planning_Topics_to_Address__c,
            EP_WT_Topics_Addressed__c, Special_Needs_Topics_to_be_Addressed__c,Personal_financial_statement_analysis__c,
            Debt_Management_Restructuring__c,Cash_Flow__c,Current_Portfolio_Analysis__c,Pros_Cons_of_Investing_for_Income_or_Gro__c,
            Pre_retirement_Investment_Advice__c
            FROM FinServ__FinancialAccount__c 
            WHERE Id = :envelopeStatus.Financial_Account__c 
            LIMIT 1
        ];
        
        // Update multi-picklist fields with joined values
        /*if (selectedTopics.containsKey('Reason_for_Liquidation_test__c')) {
            System.debug('Reason_for_Liquidation_test__c values: ' + selectedTopics.get('Reason_for_Liquidation_test__c'));
            financialAccount.Reason_for_Liquidation_test__c = String.join(selectedTopics.get('Reason_for_Liquidation_test__c'), ';');
            //financialAccount.Reason_for_Liquidation_test__c = 'test1';
            
        }*/
        if (selectedTopics.containsKey('Income_Tax_Planning_Topics_to_Address__c')) {
            financialAccount.Income_Tax_Planning_Topics_to_Address__c = String.join(selectedTopics.get('Income_Tax_Planning_Topics_to_Address__c'), ';');
        }
        if (selectedTopics.containsKey('Insurance_Planning_Topics_to_Address__c')) {
            financialAccount.Insurance_Planning_Topics_to_Address__c = String.join(selectedTopics.get('Insurance_Planning_Topics_to_Address__c'), ';');
        }
        if (selectedTopics.containsKey('Retirement_Planning_Topics_to_Address__c')) {
            financialAccount.Retirement_Planning_Topics_to_Address__c = String.join(selectedTopics.get('Retirement_Planning_Topics_to_Address__c'), ';');
        }
        if (selectedTopics.containsKey('EP_WT_Topics_Addressed__c')) {
            financialAccount.EP_WT_Topics_Addressed__c = String.join(selectedTopics.get('EP_WT_Topics_Addressed__c'), ';');
        }
        if (selectedTopics.containsKey('Special_Needs_Topics_to_be_Addressed__c')) {
            financialAccount.Special_Needs_Topics_to_be_Addressed__c = String.join(selectedTopics.get('Special_Needs_Topics_to_be_Addressed__c'), ';');
        }
        if (selectedTopics.containsKey('Personal_financial_statement_analysis__c')) {
            financialAccount.Personal_financial_statement_analysis__c = String.join(selectedTopics.get('Personal_financial_statement_analysis__c'), ';');
        }
        if (selectedTopics.containsKey('Debt_Management_Restructuring__c')) {
            financialAccount.Debt_Management_Restructuring__c = String.join(selectedTopics.get('Debt_Management_Restructuring__c'), ';');
        }
        if (selectedTopics.containsKey('Cash_Flow__c')) {
            financialAccount.Cash_Flow__c = String.join(selectedTopics.get('Cash_Flow__c'), ';');
        }
        if (selectedTopics.containsKey('Current_Portfolio_Analysis__c')) {
            financialAccount.Current_Portfolio_Analysis__c = String.join(selectedTopics.get('Current_Portfolio_Analysis__c'), ';');
        }
        if (selectedTopics.containsKey('Pros_Cons_of_Investing_for_Income_or_Gro__c')) {
            financialAccount.Pros_Cons_of_Investing_for_Income_or_Gro__c = String.join(selectedTopics.get('Pros_Cons_of_Investing_for_Income_or_Gro__c'), ';');
        }
        if (selectedTopics.containsKey('Pre_retirement_Investment_Advice__c')) {
            financialAccount.Pre_retirement_Investment_Advice__c = String.join(selectedTopics.get('Pre_retirement_Investment_Advice__c'), ';');
        }
        
        update financialAccount;
        System.debug('Updated Financial Account with selected topics: ' + selectedTopics);
        
    }
}