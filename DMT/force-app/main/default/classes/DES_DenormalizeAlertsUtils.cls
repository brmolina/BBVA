/******************************************************************************************************************************************************************
Name:            DES_DenormalizeAlertsUtils
Description:     Class with custom methods for DES_Denorm_AccountAlert__c object
Test Class:      -

Version        Date            Author            Summary of changes
-------------------------------------------------------------------------------------------------------------------------------------------------------------------
0.1            31/10/2018      Accenture         Class creation
*******************************************************************************************************************************************************************/
global without sharing class DES_DenormalizeAlertsUtils {
    //--------------------------------------- PRIVATE ATTRIBUTES -------------------------------------
    private Set<DES_Denorm_AccountAlert__c> setAccAlert = new Set<DES_Denorm_AccountAlert__c>(); //Set used to avoid duplicate relationships

    //--------------------------------------- PUBLIC METHODS ----------------------------------------
    //Clears all relationships in the Denormalization table by invoking the DeleteBatchable class
    global void clear(){
        //DESCOMENTAR CUANDO CREE LA CLASE DES_DenormalizeAlertsDelete
        Id batchInstanceId = Database.executeBatch (new DES_DenormalizeAlertsDelete(),5000);
    }

    //Clears all the relationships in the Denormalization table for a given DES_Commercial_Alert__c Id
    global void clear(String alertId){
        List<DES_Denorm_AccountAlert__c> pListAccAlert = [SELECT Id FROM DES_Denorm_AccountAlert__c WHERE commercial_alert_id__c = :alertId];

        if (pListAccAlert.size() > 0)
            delete pListAccAlert;
    }

    //Clears and then Creates all relationships
    global void restore(){
        //DESCOMENTAR CUANDO CREE LA CLASE DES_DenormalizeAlertsDelete
        Id batchInstanceId = Database.executeBatch (new DES_DenormalizeAlertsDelete(true),5000);
    }

    //Deletes and then Creates the relationships in the Denormalization Table for a given almd__Commercial_Alert__c Id
    global void restore(String alertId){
        this.clear(alertId);
        this.denormalize(alertId);
    }

    //Creates the relationships in the Denormalization Table for a given almd__Commercial_Alert__c Id
    global void denormalize(String alertId){
        List<altm__Commercial_Alert__c> alertsList = [SELECT Id, altm__participant_id__c, Name FROM altm__Commercial_Alert__c WHERE Id=:alertId LIMIT 1];
        for (altm__Commercial_Alert__c a : alertsList)
            this.denormalize(a);
    }

    //Creates the relationships in the Denormalization Table for a given almd__Commercial_Alert__c
    //Returns the number of relationships added for the given almd__Commercial_Alert__c
    global Integer denormalize(altm__Commercial_Alert__c al){
        setAccAlert.clear();
        if (al.altm__participant_id__c != null){
            recursiveFxn(al.altm__participant_id__c,al.Id, al.Name); //Create all relationships
        }

        //finally insert relationships in database
        if (setAccAlert.size() > 0) {
            List<DES_Denorm_AccountAlert__c> pListAccAlert = new List<DES_Denorm_AccountAlert__c>();
            pListAccAlert.addAll(setAccAlert);
            
            if(!pListAccAlert.isEmpty()) {
                system.debug('::::: objList A INSERTAR : ' + pListAccAlert);
                Desktop_Utils utils = Desktop_Utils.getInstance();
                utils.upsertWithRetry(pListAccAlert, 'insert');
            }
        }
        return setAccAlert.size();
    }

    //--------------------------------------- PRIVATE METHODS ---------------------------------------
    //Recursive function to add the relationships for a given almd__Commercial_Alert__c by analyzing the almd__Commercial_Alert__c Hierarchy
    //starting from almd__Commercial_Alert__c.participant_id__c
    private void recursiveFxn(string accId, string alertId, String alertName) {
        if (accId != null) {
            //If Account exists, check if the relationship is already in the denormalized table
            //List<DES_Denorm_AccountAlert__c> pListAccAlert = [SELECT Id FROM DES_Denorm_AccountAlert__c WHERE participant_id__c=:accId AND commercial_alert_id__c=:alertId LIMIT 1];
            //if (pListAccAlert.size() == 0) {
                system.debug('>>>>> Adding Relationship >> A:' + accId + '/O:' + alertId);
                //If not found, add the relationship to the denormalized table
                DES_Denorm_AccountAlert__c accAlert = new DES_Denorm_AccountAlert__c(participant_id__c=accId, commercial_alert_id__c=alertId);
                setAccAlert.add(accAlert);
            //}
            //else {
            //  system.debug('Relationship Already Exists >> A:' + accId + '/O:' + alertId);
            //}
        }

        //Retrieve the parents for the account passed
        //List<AMHI__GBL_Account_Relationship__c> listAccRel = [SELECT Id, AMHI__Parent_Account__c FROM AMHI__GBL_Account_Relationship__c WHERE AMHI__Child_Account__c = :accId];
        List<AMH_GBL_Account_Relationship__c> listAccRel = [SELECT ID, AMH_Parent_Account__c FROM AMH_GBL_Account_Relationship__c WHERE AMH_Child_Account__c =: accId];

        //iterate to recursively add the dwp_kitv.dwp_kitv__Visit__c to each parent in the hierarchy
        //Boolean bol = false;
        /*for (AMHI__GBL_Account_Relationship__c accRel : listAccRel) {

            RecursiveFxn(accRel.AMHI__Parent_Account__c, visitId, visName, visStartDate);
            //bol = true;
        }*/
        for (AMH_GBL_Account_Relationship__c accRel : listAccRel) {

            RecursiveFxn(accRel.AMH_Parent_Account__c, alertId, alertName);
            //bol = true;
        }

    }
}//Fin DES_DenormalizeAlertsUtils