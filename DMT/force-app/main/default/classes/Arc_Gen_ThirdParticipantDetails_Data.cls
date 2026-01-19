/**
* ------------------------------------------------------------------------------------------------
* @Name     Arc_Gen_ThirdParticipantDetails_Data
* @Author   Ricardo Almanza Angeles  ricardo.almanza.contractor@bbva.com
* @Date     Created: 2019-06-20
* @Group    ARCE
* ------------------------------------------------------------------------------------------------
* @Description Data Service for arce__Third_Participant_Details__c object
* ------------------------------------------------------------------------------------------------
* @Changes
*
* |2019-06-20 ricardo.almanza.contractor@bbva.com
*             Class creation.
* |2019-12-02 german.sanchez.perez.contractor@bbva.com | franciscojavier.bueno@bbva.com
*             Api names modified with the correct name on business glossary
* |2020-01-30 juanmanuel.perez.ortiz.contractor@bbva.com
*             Add missing custom labels
* |2020-03-12 javier.soto.carrascosa@bbva.com
*             Change query getRecordbyArcAcc method
* |2020-04-14 berthaelena.tellez.contractor@bbva.com
*    add fiel data in  query of getRecordsbyArcAcc method
* |2020-05-06 mariohumberto.ramirez.contractor@bbva.com
*             Add new method getInfoForShareHoldGpTable
* |2020-05-18 mariohumberto.ramirez.contractor@bbva.com
*             New filter in the method getInfoForShareHoldGpTable was added
* |2020-09-23 saimassimilianno.jordana.contractor@bbva.com
*             Added arce. namespace to all classes that are now in the arce-dependencies package
* |2021-01-07 eduardoefrain.hernandez.contractor@bbva.com
*             Remove field references for unused fields (namings nivelation)
* |2021-02-02 luisdavid.rivera.ortiz@bbva.com
*             Eliminated unused fields
* |2020-03-12 juanpedro.benito.contractor@bbva.com
*             Change arce__third_participant_per__c for arce__third_prtcpt_intervention_per__c
* |2021-04-30 otiliaramona.veres.contractor@bbva.com
* 			  Added an empty constructor method.
* |2021-05-04 otiliaramona.veres.contractor@bbva.com
* 			  Added annotation '@testVisible' to the empty constructor method.
* |2021-06-17 juanignacio.hita.contractor@bbva.com
*             Rollback last commit  (PR: 1231)
* |2021-06-22 juanignacio.hita.contractor@bbva.com
*             Add economic_activity_sector_desc,consolidation_method_id iRecordsbyArcAcc method
* -----------------------------------------------------------------------------------------------
*/
public with sharing class Arc_Gen_ThirdParticipantDetails_Data {
    /**
    *-------------------------------------------------------------------------------
    * @description Empty constructor method
    *-------------------------------------------------------------------------------
    *@author otiliaramona.veres.contractor@bbva.com
    *@Date   Created:2021-04-30
    */
    @TestVisible
    private Arc_Gen_ThirdParticipantDetails_Data() { }
    /**
    * -----------------------------------------------------------------------------------------------
    * @Description Wrapper that contain an error message
    * -----------------------------------------------------------------------------------------------
    * @param - void
    * @return - String with an error message
    * @example ResponseWrapperThrdPart wrapper = new ResponseWrapperThrdPart()
    * -----------------------------------------------------------------------------------------------
    **/
    public class ResponseWrapperThrdPart {
        /**
        * @Description: String with an error message
        */
        @AuraEnabled public String gblErrorResponse {get;set;}
    }
    /*------------------------------------------------------------------------------------------------------
    *@Description Insert arce__Third_Participant_Details__c
    * -----------------------------------------------------------------------------------------------------
    * @Author   Ricardo Almanza
    * @Date     2019-06-20
    * @param    toIns array of objects to insert
    * @return   ResponseWrapperThrdPart object with string in case of error
    * @example  insertTableContent(toIns)
    * */
    public static ResponseWrapperThrdPart insertTableContent(arce__Third_Participant_Details__c[] toIns) {
        final ResponseWrapperThrdPart wrapper = new ResponseWrapperThrdPart();
        try{
            if(toIns.isEmpty()) {
                throw new DMLException(System.Label.Arc_Gen_NotElements);
            }
            Insert toIns;
        } catch (DmlException exep) {
            wrapper.gblErrorResponse = exep.getMessage();
        }
        return wrapper;
    }
    /*------------------------------------------------------------------------------------------------------
    *@Description Update arce__Third_Participant_Details__c
    * -----------------------------------------------------------------------------------------------------
    * @Author   Ricardo Almanza
    * @Date     2019-06-20
    * @param    toUpd array of objects to Update
    * @return   ResponseWrapperThrdPart object with string in case of error
    * @example  updateTableContent(toUpd)
    * */
    public static ResponseWrapperThrdPart updateTableContent(arce__Third_Participant_Details__c[] toUpd) {
        final ResponseWrapperThrdPart wrapper = new ResponseWrapperThrdPart();
        try{
            if(toUpd.isEmpty()) {
                throw new DMLException(System.Label.Arc_Gen_NotElements);
            }
            Update toUpd;
        } catch (DmlException exep) {
            wrapper.gblErrorResponse = exep.getMessage();
        }
        return wrapper;
    }
    /*------------------------------------------------------------------------------------------------------
    *@Description Delete arce__Third_Participant_Details__c
    * -----------------------------------------------------------------------------------------------------
    * @Author   Ricardo Almanza
    * @Date     2019-06-20
    * @param    toDel array of objects to Delete
    * @return   ResponseWrapperThrdPart object with string in case of error
    * @example  deleteTableContent(toDel)
    * */
    public static ResponseWrapperThrdPart deleteTableContent(arce__Third_Participant_Details__c[] toDel) {
        final ResponseWrapperThrdPart wrapper = new ResponseWrapperThrdPart();
        try{
            if(toDel.isEmpty()) {
                throw new DMLException(System.Label.Arc_Gen_NotElements);
            }
            Delete toDel;
        } catch (DMLException exep) {
            wrapper.gblErrorResponse = exep.getMessage();
        }
        return wrapper;
    }
    /*------------------------------------------------------------------------------------------------------
    *@Description Get arce__Third_Participant_Details__c related to arce__account_has_analysis_id__c
    * -----------------------------------------------------------------------------------------------------
    * @Author   Ricardo Almanza
    * @Date     2019-06-20
    * @param    rid id related to arce__account_has_analysis_id__c
    * @return   arce__Third_Participant_Details__c[] array with arce__Third_Participant_Details__c related
    * @example  getThirdParticipantDetails(rid)
    * */
    public static arce__Third_Participant_Details__c[] getThirdParticipantDetails(Id rid) {
        return [Select Id, Name, arce__third_participant_desc__c, arce__third_participant_per__c, arce__shrhldr_financial_sponsor_type__c, arce__shareholder_sponsor_year_id__c from arce__Third_Participant_Details__c where arce__account_has_analysis_id__c=:rid and arce__third_participant_role_type__c = '03'];
    }
/**
*-------------------------------------------------------------------------------
* @description getRecordsYears gets the info to build charts in the front.
*--------------------------------------------------------------------------------
* @author  ricardo.almanza.contractor@bbva.com
* @date     21/01/2020
* @param collectionType type of collection.
* @param  recordId Id of the record.
* @return List<arce__Table_Content_per_Analysis__c>
**/
  public static List<arce__Third_Participant_Details__c> getRecordsbyArcAcc(String collectionType,List<String> recordId) {
    Id idRT = arce.Arc_Gen_GenericUtilities.getRecType('arce__Third_Participant_Details__c', collectionType);
    return [SELECT Id,Name,arce__third_participant_desc__c,arce__third_participant_per__c,
    arce__non_customer_type__c,arce__shareholder_sponsor_year_id__c,arce__Third_Participant_id__r.Name,
    arce__shrhldr_financial_sponsor_type__c,arce__economic_activity_sector_desc__c,arce__consolidation_method_id__c
    FROM arce__Third_Participant_Details__c WHERE arce__account_has_analysis_id__c = :recordId AND recordTypeId =: idRT];
  }
    /**
    *---------------------------------------------------------------------------------------------------
    * @Description get shareHolders info to build the shareholder group table
    *---------------------------------------------------------------------------------------------------
    * @Author  mariohumberto.ramirez.contractor@bbva.com
    * @Date    2020-05-06
    * @param   accHasIdLts - type of collection.
    * @return List<arce__Table_Content_per_Analysis__c> with info to build the shareholder group table
    * --------------------------------------------------------------------------------------------------
    **/
    public static List<arce__third_participant_details__c> getInfoForShareHoldGpTable(List<String> accHasIdLts) {
        return [SELECT Id, arce__account_has_analysis_id__c,arce__account_has_analysis_id__r.arce__participant_name__c, arce__Third_Participant_id__c, arce__Third_Participant_id__r.Name,arce__third_participant_per__c
                FROM arce__third_participant_details__c
                WHERE arce__account_has_analysis_id__c = :accHasIdLts AND arce__third_participant_role_type__c  = '03'
                ORDER BY arce__account_has_analysis_id__r.arce__participant_name__c ASC];
    }
}