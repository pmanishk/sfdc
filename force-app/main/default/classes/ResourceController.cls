public class ResourceController {
    public List<ResourceWrapper> sisResourceList { get; set; }
    public List<ResourceWrapper> complianceResourceList { get; set; }
    public Id recordId { get; set; }

    public ResourceController() {
        sisResourceList = new List<ResourceWrapper>();
        complianceResourceList = new List<ResourceWrapper>();

        // Fetch the current user and their advisor type
        User usr = [SELECT Id, Profile.Name, Advisor_Type__c FROM User WHERE Id = :UserInfo.getUserId() AND IsActive = TRUE LIMIT 1];

        if (usr.Profile.Name == 'System Administrator') {
            // If the user is a System Administrator, show all resources
            sisResourceList = getAllAdminResources('SIS');
            complianceResourceList = getAllAdminResources('Compliance');
        } else if (usr.Advisor_Type__c != null) {
            // For other users, dynamically fetch resources based on their Advisor_Type__c
            sisResourceList = getResourcesForAdvisorType(usr.Advisor_Type__c, 'SIS');
            complianceResourceList = getResourcesForAdvisorType(usr.Advisor_Type__c, 'Compliance');
        }

        // Get the current recordId from the URL (if applicable)
        recordId = ApexPages.currentPage().getParameters().get('id');
    }

    // Method to fetch all resources for System Administrator by aggregating all labels
    private List<ResourceWrapper> getAllAdminResources(String formType) {
        List<ResourceWrapper> allResources = new List<ResourceWrapper>();

        // Fetch picklist values dynamically from the Advisor_Type__c field
        List<String> allAdvisorTypes = getPicklistValues('User', 'Advisor_Type__c');
        Set<String> resourceNames = new Set<String>();
        for (String advisorType : allAdvisorTypes) {
            String dynamicLabelName = advisorType != ''? formType + '_Forms_' + advisorType : '';

            // Dynamically fetch the label if it exists
            String resourceLabel = dynamicLabelName != '' ? (String) Label.get('', dynamicLabelName):''; // Use get() to retrieve dynamic label value
            if (!String.isBlank(resourceLabel)) {
                for(String str :resourceLabel.split(';')){
                    resourceNames.add(str);
                }

                // Add each resource to the list
               
            }
        }
         for (String resourceName : resourceNames) {
                    allResources.add(new ResourceWrapper(resourceName.trim(), getResourceUrl(resourceName.trim().replaceAll(' ', '_').replaceAll('[()]', ''))));
                }

        return allResources;
    }

    // Method to fetch resources specific to an advisor type
    private List<ResourceWrapper> getResourcesForAdvisorType(String advisorType, String formType) {
        List<ResourceWrapper> advisorResources = new List<ResourceWrapper>();

        // Dynamically get the label name for the user's advisor type
        String dynamicLabelName = advisorType != ''? formType + '_Forms_' + advisorType : '';

        // Dynamically fetch the label if it exists
        String resourceLabel = dynamicLabelName != '' ? (String) Label.get('', dynamicLabelName):'';  // Use get() to retrieve dynamic label value
        if (!String.isBlank(resourceLabel)) {
            List<String> resourceNames = resourceLabel.split(';');

            // Add each resource to the list
            for (String resourceName : resourceNames) {
                advisorResources.add(new ResourceWrapper(resourceName.trim(), getResourceUrl(resourceName.trim().replaceAll(' ', '_').replaceAll('[()]', ''))));
            }
        }

        return advisorResources;
    }

    // Helper method to construct the URL for static resources
    public String getResourceUrl(String resourceName) {
        return '/resource/' + EncodingUtil.urlEncode(resourceName, 'UTF-8');
    }

    // Helper method to get picklist values from a field on an sObject
    public static List<String> getPicklistValues(String objectName, String fieldName) {
        List<String> picklistValues = new List<String>();

        Schema.SObjectType sObjectType = Schema.getGlobalDescribe().get(objectName);
        Schema.DescribeSObjectResult describeResult = sObjectType.getDescribe();
        Schema.DescribeFieldResult fieldResult = describeResult.fields.getMap().get(fieldName).getDescribe();
        List<Schema.PicklistEntry> picklistEntries = fieldResult.getPicklistValues();

        for (Schema.PicklistEntry entry : picklistEntries) {
            picklistValues.add(entry.getValue());
        }

        return picklistValues;
    }

    // Wrapper class to hold resource name and URL
    public class ResourceWrapper {
        public String name { get; set; }
        public String url { get; set; }

        public ResourceWrapper(String name, String url) {
            this.name = name;
            this.url = url;
        }
    }
}