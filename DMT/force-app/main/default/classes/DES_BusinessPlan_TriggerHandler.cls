/**
* @author       Global Desktop
* @date         17/10/2019
* @description  Handler del trigger de Business Plan con los métodos que aplican sólo a funcionalidad dentro de Global Desktop
* @Revision
* 
* Version   Date            Author          Summary of changes
*
*/
public without sharing class DES_BusinessPlan_TriggerHandler {
    
    /*instance*/
    public static DES_BusinessPlan_TriggerHandler instance;


    /*
    * @author       Global Desktop
    * @Description  Constructor
    */
    private DES_BusinessPlan_TriggerHandler() {
        System.debug('CONSTRUCTOR');
    }

    /*
    * @author       Global Desktop
    * @Description  getInstance
    */
    public static DES_BusinessPlan_TriggerHandler getInstance() { //NOSONAR
        if (instance == null) {
            instance = new DES_BusinessPlan_TriggerHandler();
        }
        return instance;
    }




    /*
    * @author       Global Desktop
    * @Description  Create the BPversion related to the Business Plan
    */
    public void initRelatedBPversion(List<bupl__BusinessPlan__c> triggerNew) {
        final List<bupl__BusinessPlan_Version__c> listBPv = new List<bupl__BusinessPlan_Version__c>();
        for (bupl__BusinessPlan__c bp : triggerNew) {
            //Integer bpiVersion = bp.AAA_Counter_of_Business_Plan_Versions__c.intValue() + 1;
            final bupl__BusinessPlan_Version__c newBPv = new bupl__BusinessPlan_Version__c(
            //    Name = bp.Name + ' v' + bpiVersion, -> El Name se rellena en el trigger BPVersion y así se cubren todas las casuisticas de creación
                bupl__gf_business_plan_id__c = bp.Id,
                CurrencyIsoCode = bp.CurrencyIsoCode,
                bupl__gf_business_plan_act_ind_type__c = 'Yes'
            );
            listBPv.add(newBPv);

        }

        if (!listBPv.isEmpty()) {
            insert listBPv;
        }
    }    

}