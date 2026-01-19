/**
* @author       Global Desktop
* @date         04/05/2020
* @description  Handler del trigger de Group Analysos con los mét0d0s que aplican sólo a funcionalidad dentro de Global Desktop
*/
public without sharing class DES_GroupAnalysisHandler {
    /*
    * instance
    */
    public static DES_GroupAnalysisHandler instance;


    /*
    * constructor
    */
    private DES_GroupAnalysisHandler() {
        System.debug('CONSTRUCTOR');
    }

	/*
    * get instance
    */
    public static DES_GroupAnalysisHandler getInstance() { //NOSONAR
        if (instance == null) {
            instance = new DES_GroupAnalysisHandler();
        }
        return instance;
    }
    
    /*
    * @author       Global Desktop
    * @Description  Updates GA lookup in its AP
    */
    public void updateGAlookupInAP(List<DES_Group_Analysis__c> triggernew) {
        
    /*
    * @author       SBT
    * @Description  Updates field Unlock Account Planning (acpl__gf_ap_indvi_lock_edit_ind_type__c)
    */

        // Primero extraemos una lista con los ID de los AP asociados a nuestros GA
        List<Id> idAccPlans = new List<Id>();

        for(DES_Group_Analysis__c groupAn :triggernew) {
            if(groupAn.gf_account_planning_id__c != null) {
                idAccPlans.add(groupAn.gf_account_planning_id__c);
            }
        }

        Map<Id,acpl__Account_Planning__c> mapaAPs = new Map<Id,acpl__Account_Planning__c>(); 
        List<acpl__Account_Planning__c> accountPlans = new List<acpl__Account_Planning__c>();

        //Hacemos una select a AP par extraer todos los AP que tengan como group analysis relacionado uno de nuestra lista
        if(!idAccPlans.isEmpty()) {
            accountPlans = [SELECT Id, acpl__gf_ap_indvi_lock_edit_ind_type__c, gf_participant_analysis_id__c FROM acpl__Account_Planning__c WHERE Id IN :idAccPlans];
        } 

        //Montamos un mapa para poder localizar luego los datos del AP que necesitemos
        if(!accountPlans.isEmpty()) {
            for(acpl__Account_Planning__c acPlan:accountPlans) {
                mapaAPs.put(acPlan.Id, acPlan);
            }
        }

        List<acpl__Account_Planning__c> apList;
        apList = new List<acpl__Account_Planning__c>();
        List<acpl__Account_Planning__c> apListLocked;
        apListLocked = new List<acpl__Account_Planning__c>();
        
        for(DES_Group_Analysis__c gaAux : triggernew) {
/*            acpl__Account_Planning__c apAux;
            apAux = new acpl__Account_Planning__c();
            apAux.Id = gaAux.gf_account_planning_id__c;
            apAux.gf_participant_analysis_id__c = gaAux.Id;
            apList.add(apAux);
*/
            acpl__Account_Planning__c apAux = mapaAPs.get(gaAux.gf_account_planning_id__c);

            if(apAux.acpl__gf_ap_indvi_lock_edit_ind_type__c == false) {
                apListLocked.add(apAux);
                apAux.acpl__gf_ap_indvi_lock_edit_ind_type__c = true;
            }
            apAux.gf_participant_analysis_id__c = gaAux.Id;
            apList.add(apAux);

        }
        update apList;

        if(!apListLocked.isEmpty()) {
            List<acpl__Account_Planning__c> apListUnlock;
            apListUnlock = new List<acpl__Account_Planning__c>();
            
            for(acpl__Account_Planning__c acPlanUnlock:apListLocked) {
                acPlanUnlock.acpl__gf_ap_indvi_lock_edit_ind_type__c = false;
                apListUnlock.add(acPlanUnlock);
            }
            update apListUnlock;
        }
    }
}