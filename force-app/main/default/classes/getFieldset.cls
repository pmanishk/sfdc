@RestResource(urlMapping='/getFieldset')
 global class getFieldset{

global class fieldsetmainwrapper{

  public List<fieldsetwrapper> fsetwrap;
  public string name;

}

 public class fieldsetwrapper{

 public string fieldname;
 public string fieldlabel;
 public string fieldtype;
 public string fieldpath;
 public boolean isrequired;
 public boolean isDBrequired;

}

 @HttpPost
 global static List<fieldsetmainwrapper> readFieldSet(String objectName, String fieldSetName)
{
    Map<String, Schema.SObjectType> GlobalDescribeMap = Schema.getGlobalDescribe();
    try { 
        Schema.SObjectType SObjectTypeObj = GlobalDescribeMap.get(objectName);
        Schema.DescribeSObjectResult DescribeSObjectResultObj = SObjectTypeObj.getDescribe();
       
        //system.debug('====>' + DescribeSObjectResultObj.FieldSets.getMap().get(fieldSetName));
        
        List<fieldsetmainwrapper> fwrap=new List<fieldsetmainwrapper>();
        List<fieldsetwrapper> fieldwrappers=new  List<fieldsetwrapper>();
        if (fieldSetName != '') {
           fieldsetmainwrapper fmain=new fieldsetmainwrapper();
           fmain.name = fieldSetName;
           for(Schema.FieldSetMember fieldSetMemberObj:DescribeSObjectResultObj.FieldSets.getMap().get(fieldSetName).getFields()){
                 fieldsetwrapper fwrap1=new fieldsetwrapper();
                // fwrap1.fieldname=fieldSetMemberObj.getName();
                 fwrap1.fieldpath=fieldSetMemberObj.getFieldPath(); //api name
                 fwrap1.fieldlabel=fieldSetMemberObj.getLabel();
                 fwrap1.isrequired=fieldSetMemberObj.getRequired();
                 fwrap1.isDBrequired=fieldSetMemberObj.getDbRequired();
                 fwrap1.fieldtype=String.valueof(fieldSetMemberObj.getType());   //type - STRING,PICKLIST
                 fieldwrappers.add(fwrap1);
                 
           }
           fmain.fsetwrap=fieldwrappers;
           fwrap.add(fmain);
        }
        else {
            for(string s:DescribeSObjectResultObj.FieldSets.getMap().keyset()){
                fieldsetmainwrapper fmain=new fieldsetmainwrapper();
                fmain.name=s;              
                for(Schema.FieldSetMember fieldSetMemberObj:DescribeSObjectResultObj.fieldSets.getMap().get(s).getFields()){
                     fieldsetwrapper fwrap1=new fieldsetwrapper();
                    // fwrap1.fieldname=fieldSetMemberObj.getName();
                     fwrap1.fieldpath=fieldSetMemberObj.getFieldPath(); //api name
                     fwrap1.fieldlabel=fieldSetMemberObj.getLabel();
                     fwrap1.isrequired=fieldSetMemberObj.getRequired();
                     fwrap1.isDBrequired=fieldSetMemberObj.getDbRequired();
                     fwrap1.fieldtype=String.valueof(fieldSetMemberObj.getType());   //type - STRING,PICKLIST
                     fieldwrappers.add(fwrap1);
                }
                fmain.fsetwrap=fieldwrappers;
                fwrap.add(fmain);
                fieldwrappers = new List<fieldsetwrapper>();
            }
        }
        //List<Schema.FieldSetMember> fieldSetMemberList =  fieldSetObj.getFields();
        //system.debug('fieldSetMemberList ====>' + fieldSetMemberList);  
        return fwrap;
    }
    catch (System.NullPointerException npe) {
       List<fieldsetmainwrapper> fwrap=new List<fieldsetmainwrapper>();
       List<fieldsetwrapper> fieldwrappers=new List<fieldsetwrapper>();
       fieldsetwrapper fwrap1=new fieldsetwrapper();
       fieldsetmainwrapper fmain=new fieldsetmainwrapper();
       fmain.name = 'Error finding fieldset ' + fieldsetName + ' on ' + objectName + ' object, please contact AppCrown support';

       fieldwrappers.add(fwrap1);
       fmain.fsetwrap=fieldwrappers;
       fwrap.add(fmain);
       return fwrap;
    }
}  

static testMethod void testDoPost() {

RestRequest req = new RestRequest(); 
RestResponse res = new RestResponse();

req.requestURI = 'https://' + System.URL.getSalesforceBaseUrl().getHost() + '.salesforce.com/services/apexrest/getFieldset';  
req.httpMethod = 'POST';
RestContext.request = req;
RestContext.response = res;

List<fieldsetmainwrapper> results = getFieldset.readFieldSet( 'Contact', 'InvestorProfile');
List<fieldsetmainwrapper> results2 = getFieldset.readFieldSet( 'Contat', 'InvestorProfile');
List<fieldsetmainwrapper> results3 = getFieldset.readFieldSet( 'Contact', '');

}
}