/*
* @author Global Desktop
* @description Clase de Test de NewOppFormGroupsCnt
*/
@isTest
public class NewOppFormGroupsCntTest {

    /*Variables globales*/
    final static String GROUPNAME = 'Group';
    /*Variables globales*/
    final static String FILIALNAME = 'Subsidiary';
    /*
    * @author Global Desktop
    * @description Method principal de la clase de test
    */
    @isTest
    public static void newOppFormGroupsController() {
        final DES_UtilTestClass utilTestClass = new DES_UtilTestClass();
        final list<Recordtype> rtList = [SELECT id, DeveloperName FROM Recordtype WHERE DeveloperName = 'Group' OR DeveloperName = 'Subsidiary'];
        id accountGroupRT;
        id accountFilialRT;

        for(Recordtype i : rtList) {
            if(i.DeveloperName == GROUPNAME) {
                accountGroupRT = i.Id;
            } else if(i.DeveloperName == FILIALNAME) {
                accountFilialRT = i.Id;
            }
        }
        final list<Account> accList = new list<Account>();
        final Account accGroup = utilTestClass.createClient();
        accGroup.RecordTypeId = accountGroupRT;
        accGroup.DES_Structure_Type__c = 'Group';
        accGroup.DES_BBVA_Segmentation__c = 'C';
        accGroup.gf_prtcpt_act_status_ind_type__c = true;
        accList.add(accGroup);
        final Account accFilial = utilTestClass.createClient();
        accFilial.Des_Main_Parent__c = accGroup.Id;
        accFilial.DES_Entity_Hierarchy__c = 'S';
        accFilial.RecordTypeId = accountFilialRT;
        accFilial.gf_prtcpt_act_status_ind_type__c = true;
        accList.add(accFilial);
        insert accList;

        final DES_Subsidiary_Group_Relation__c gsm = new DES_Subsidiary_Group_Relation__c();
        gsm.participant_parent_id__c = accGroup.Id;
        gsm.participant_child_id__c = accFilial.Id;
        gsm.main_subsidiary_ind_type__c = true;
        insert gsm;

        Test.StartTest();
        NewOppFormGroupsCnt.getRelatedCountries(accGroup.Id);
        NewOppFormGroupsCnt.getRecords(accGroup.Id,'Spain');

        try{
             NewOppFormGroupsCnt.getRelatedMatrix(accGroup.Id);
        }catch(Exception ex){
            system.debug(ex.getMessage());
        }

        NewOppFormGroupsCnt.getInstance();
        final DES_Subsidiary_Group_Relation__c objSubsi= new DES_Subsidiary_Group_Relation__c(participant_parent_id__c=accFilial.id,participant_child_id__c=accFilial.id,participant_child_id__r=accFilial);
        insert objSubsi;
        final NewOppFormGroupsCnt.WrapperClass objWraper=new NewOppFormGroupsCnt.WrapperClass(objSubsi.participant_child_id__r.Name,objSubsi.participant_child_id__c);

        NewOppFormGroupsCnt.getRelatedMatrix(accFilial.id);
        NewOppFormGroupsCnt.getRelatedCountries(accFilial.id);
        Id rtSupraGrupo = Schema.SObjectType.Account.getRecordTypeInfosByName().get('SupraGroup').getRecordTypeId();
        Id rtSubGrupo   = Schema.SObjectType.Account.getRecordTypeInfosByName().get('SubGroup').getRecordTypeId();
        Id rtGrupo      = Schema.SObjectType.Account.getRecordTypeInfosByName().get('Group').getRecordTypeId();
        accFilial.recordtypeid=rtSupraGrupo;
        update accFilial;
        NewOppFormGroupsCnt.getRelatedMatrix(accFilial.id);
        NewOppFormGroupsCnt.getRelatedCountries(accFilial.id);
         accFilial.recordtypeid=rtSubGrupo;
        update accFilial;
        NewOppFormGroupsCnt.getRelatedMatrix(accFilial.id);
        NewOppFormGroupsCnt.getRelatedCountries(accFilial.id);
        System.assertEquals(accGroup.RecordTypeId, accountGroupRT, 'OK');
        Test.StopTest();

    }


}