/**BBVA_SBS_Classification
*  object.
* <p /><p />
* Modification log:<p />
* -------------------------------------------------------------------
* Developer                    Date                Description<p />
* -------------------------------------------------------------------
* Julio Medellin               21/03/2018          Original version.<p />
*
* @author Julio Medellin
*/
@IsTest
public class BBVA_SBS_Classification_Test {

@testSetup static void setup() {
// Create common test accounts
    List<Local_Client__c> testAccts = new List<Local_Client__c>();
    list<Account_Banking_System_Classification__c> testSBS = new list<Account_Banking_System_Classification__c>();
    list<Account_BBVA_Classification__c> BBVAC = new list<Account_BBVA_Classification__c>();
    for(Integer i=0;i<5;i++) {
        Local_Client__c acc = TestFactory.createLocalClient();
        testAccts.add(acc);
    }


    for(Integer i=0;i<5;i++) {
        testSBS.add(new Account_Banking_System_Classification__c(
        local_client_id__c=testAccts[i].Id,
        banking_system_classification_desc__c=String.valueOf(i),
        banking_system_classification_quota_per__c=Decimal.valueOf(i),
        banking_system_classification_type__c=String.valueOf((i+1)*10),
        Unique_Id__c=String.valueOf(i),
        year_month_day_date__c=System.date.today()));
        BBVAC.add(new Account_BBVA_Classification__c(
        local_client_id__c=testAccts[i].Id,
        bbva_classification_type__c=String.valueOf((i+1)*10),
        Unique_Id__c=string.valueOf(i),
        year_month_day_date__c=System.date.today()));
    }
    insert testSBS;
    insert BBVAC;
}

@isTest static void positiveMethod() {
    ID accid = [SELECT ID From Local_Client__c limit 1].Id;
    BBVA_SBS_Classification_cls sbs =  new BBVA_SBS_Classification_cls();
    system.assertNotEquals(null,BBVA_SBS_Classification_cls.getJSON(accid));
}

}