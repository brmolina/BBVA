/******************************************************************************************************************************************************************
Name:            DES_DenormalizeVisitsUtils
Description:     Class with custom methods for DES_Denorm_AccountVisits__c object
Test Class:      -

Version        Date            Author            Summary of changes
-------------------------------------------------------------------------------------------------------------------------------------------------------------------
0.1            08/05/2018      Accenture         Class creation    
0.2            10/05/2018      Accenture         Update -> se añade campo y se rellena en la tabla Denorm con la fecha VisitStartDate    
0.3            22/06/2018      Accenture         Update -> se añade modificación en los dos métodos denormalize para que funcione también con Visitas relacionadas con Prospects (Lead)
*******************************************************************************************************************************************************************/
global without sharing class DES_DenormalizeVisitsUtils {
    //--------------------------------------- PRIVATE ATTRIBUTES ------------------------------------
    private Set<DES_Denorm_AccountVisits__c> setAccVisit = new Set<DES_Denorm_AccountVisits__c>(); //Set used to avoid duplicate relationships

    //--------------------------------------- PUBLIC METHODS ----------------------------------------
    //Clears all relationships in the Denormalization table by invoking the DeleteBatchable class
    global void clear(){
        //DESCOMENTAR CUANDO CREE LA CLASE DES_DenormalizeVisitsDelete
        Id batchInstanceId = Database.executeBatch (new DES_DenormalizeVisitsDelete(),5000);
    }

    //Clears all the relationships in the Denormalization table for a given dwp_kitv.dwp_kitv__Visit__c Id
    global void clear(String visitId){
        List<DES_Denorm_AccountVisits__c> pListAccVisit = [SELECT Id FROM DES_Denorm_AccountVisits__c WHERE DES_Visit_new__c = :visitId];

        if (pListAccVisit.size() > 0)
            delete pListAccVisit;
    }

    //Clears and then Creates all relationships
    global void restore(){
        //DESCOMENTAR CUANDO CREE LA CLASE DES_DenormalizeVisitsDelete
        Id batchInstanceId = Database.executeBatch (new DES_DenormalizeVisitsDelete(true),5000);
    }

    //Deletes and then Creates the relationships in the Denormalization Table for a given dwp_kitv.dwp_kitv__Visit__c Id
    global void restore(String visitId){
        this.clear(visitId);
        this.denormalize(visitId);
    }

    //Creates the relationships in the Denormalization Table for a given dwp_kitv.dwp_kitv__Visit__c Id
    global void denormalize(String visitId){
        List<dwp_kitv__Visit__c> visitsList = [SELECT Id, dwp_kitv__account_id__c, Name, dwp_kitv__visit_start_date__c, dwp_kitv__lead_id__c, dwp_kitv__lead_id__r.DES_Group__c FROM dwp_kitv__Visit__c WHERE Id=:visitId LIMIT 1];
        for (dwp_kitv__Visit__c v : visitsList){
            this.denormalize(v);
        }
    }

    //Creates the relationships in the Denormalization Table for a given dwp_kitv.dwp_kitv__Visit__c
    //Returns the number of relationships added for the given dwp_kitv.dwp_kitv__Visit__c
    global Integer denormalize(dwp_kitv__Visit__c vis){
        setAccVisit.clear();
        if (vis.dwp_kitv__account_id__c != null){
            recursiveFxn(vis.dwp_kitv__account_id__c,vis.Id, vis.Name, vis.dwp_kitv__visit_start_date__c); //Create all relationships
        }else if (vis.dwp_kitv__lead_id__c != null && vis.dwp_kitv__lead_id__r.DES_Group__c != null){
            recursiveFxn(vis.dwp_kitv__lead_id__r.DES_Group__c,vis.Id, vis.Name, vis.dwp_kitv__visit_start_date__c); //Create all relationships
        }        

        //finally insert relationships in database
        if (setAccVisit.size() > 0) {
            List<DES_Denorm_AccountVisits__c> pListAccVisit = new List<DES_Denorm_AccountVisits__c>();
            pListAccVisit.addAll(setAccVisit);
            insert pListAccVisit;
        }
        return setAccVisit.size();
    }

    //Updates the VisitStartDate in the Denormalization Table for a given dwp_kitv__Visit__c Id and dwp_kitv__visit_start_date__c
    global void updateVisitStartDate(String visitId, DateTime newStartDate){
        List<dwp_kitv__Visit__c> visitsList = [SELECT Id, dwp_kitv__account_id__c, Name, dwp_kitv__visit_start_date__c FROM dwp_kitv__Visit__c WHERE Id=:visitId LIMIT 1];

        //Retrieve all records from the Denormalization Table for the visit passed
        List<DES_Denorm_AccountVisits__c> pListAccVisit = [SELECT Id, DES_Start_Date__c FROM DES_Denorm_AccountVisits__c WHERE DES_Visit_new__c = :visitId];
        for (DES_Denorm_AccountVisits__c denormVisit : pListAccVisit)
            denormVisit.DES_Start_Date__c = newStartDate;
        update pListAccVisit;
    }
    

    //--------------------------------------- PRIVATE METHODS ---------------------------------------
    //Recursive function to add the relationships for a given dwp_kitv.dwp_kitv__Visit__c by analyzing the  dwp_kitv.dwp_kitv__Visit__c Hierarchy
    //starting from dwp_kitv.dwp_kitv__Visit__c.dwp_kitv__account_id__c
    private void recursiveFxn(string accId, string visitId, String visName, DateTime visStartDate) {
        Account acc = new Account();
        if (accId != null) {
            //If Account exists, check if the relationship is already in the denormalized table
            //List<DES_Denorm_AccountVisits__c> pListAccVisit = [SELECT Id FROM DES_Denorm_AccountVisits__c WHERE DES_Client__c=:accId AND DES_Visit_new__c=:visitId LIMIT 1];
            //if (pListAccVisit.size() == 0) {
                system.debug('>>>>> Adding Relationship >> A:' + accId + '/O:' + visitId);
                //If not found, add the relationship to the denormalized table
                DES_Denorm_AccountVisits__c accVisit = new DES_Denorm_AccountVisits__c(/*Name=visName,*/ DES_Client__c=accId, DES_Visit_new__c=visitId,DES_Start_Date__c=visStartDate);
                setAccVisit.add(accVisit);
            //}
            //else {
            //  system.debug('Relationship Already Exists >> A:' + accId + '/O:' + visitId);
            //}
            acc = [SELECT Id, DES_Main_Parent__c, Name, gf_cust_orig_prospect_ind_type__c FROM Account WHERE Id =:accId];
            System.debug('acc MainParent:_ '+acc.DES_Main_Parent__c);
            System.debug(acc.gf_cust_orig_prospect_ind_type__c);
        }
        if(acc.gf_cust_orig_prospect_ind_type__c ) {
            RecursiveFxn(acc.DES_Main_Parent__c, visitId, visName, visStartDate);
        }else{
            //Retrieve the parents for the account passed
            //List<AMHI__GBL_Account_Relationship__c> listAccRel = [SELECT Id, AMHI__Parent_Account__c FROM AMHI__GBL_Account_Relationship__c WHERE AMHI__Child_Account__c = :accId];
            List<AMH_GBL_Account_Relationship__c> listAccRel = [SELECT ID, AMH_Parent_Account__c FROM AMH_GBL_Account_Relationship__c WHERE AMH_Child_Account__c =: accId and AMH_Vision__c = 'Negocio' FOR UPDATE];
            
            //iterate to recursively add the dwp_kitv.dwp_kitv__Visit__c to each parent in the hierarchy
            //Boolean bol = false;
            /*for (AMHI__GBL_Account_Relationship__c accRel : listAccRel) {
                
                RecursiveFxn(accRel.AMHI__Parent_Account__c, visitId, visName, visStartDate);
                //bol = true;
            }*/
            for (AMH_GBL_Account_Relationship__c accRel : listAccRel) {
                
                RecursiveFxn(accRel.AMH_Parent_Account__c, visitId, visName, visStartDate);
                //bol = true;    
            }
        }
        
    }
}//Fin DES_DenormalizeVisitsUtils