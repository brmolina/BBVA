/**
* ------------------------------------------------------------------------------------------------
* @Name     Arc_Gen_MainBanks_Data
* @Author   Ricardo Almanza Angeles  ricardo.almanza.contractor@bbva.com
* @Date     Created: 2019-06-20
* @Group    ARCE
* ------------------------------------------------------------------------------------------------
* @Description Data Service for arce__main_banks__c object
* ------------------------------------------------------------------------------------------------
* @Changes
*
* |2019-06-20 ricardo.almanza.contractor@bbva.com
*             Class creation.
* |2020-01-30 juanmanuel.pere.ortiz.contractor@bbva.com
*             Add missing custom labels.
*|2020-02.24 Add id, Name, fields to query get data of main banks
* |2021-04-30 otiliaramona.veres.contractor@bbva.com
* 			  Added an empty constructor method.
* |2021-05-04 otiliaramona.veres.contractor@bbva.com
* 			  Added anotation '@testVisible' to the empty constructor method.
* -----------------------------------------------------------------------------------------------
*/
public with sharing class Arc_Gen_MainBanks_Data {
    /**
    *-------------------------------------------------------------------------------
    * @description Empty constructor method
    *-------------------------------------------------------------------------------
    *@author otiliaramona.veres.contractor@bbva.com
    *@date 2021-04-30
    */
    @TestVisible
    private Arc_Gen_MainBanks_Data() { }
    /**
    * -----------------------------------------------------------------------------------------------
    * @Description Wrapper that contain an error message
    * -----------------------------------------------------------------------------------------------
    * @param - void
    * @return - String with an error message
    * @example ResponseWrapperMnBanks wrapper = new ResponseWrapperMnBanks()
    * -----------------------------------------------------------------------------------------------
    **/
    public class ResponseWrapperMnBanks {
        /**
        * @Description: String with an error message
        */
        @AuraEnabled public String gblErrorResponse {get;set;}
    }
    /*------------------------------------------------------------------------------------------------------
    *@Description Insert arce__main_banks__c
    * -----------------------------------------------------------------------------------------------------
    * @Author   Ricardo Almanza
    * @Date     2019-06-20
    * @param    toIns array of objects to insert
    * @return   ResponseWrapperMnBanks object with string in case of error
    * @example  insertTableContent(toIns)
    * */
    public static ResponseWrapperMnBanks insertTableContent(arce__main_banks__c[] toIns) {
        final ResponseWrapperMnBanks wrapper = new ResponseWrapperMnBanks();
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
    *@Description Update arce__main_banks__c
    * -----------------------------------------------------------------------------------------------------
    * @Author   Ricardo Almanza
    * @Date     2019-06-20
    * @param    toUpd array of objects to insert
    * @return   ResponseWrapperMnBanks object with string in case of error
    * @example  updateTableContent(toUpd)
    * */
    public static ResponseWrapperMnBanks updateTableContent(arce__main_banks__c[] toUpd) {
        final ResponseWrapperMnBanks wrapper = new ResponseWrapperMnBanks();
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
    *@Description Get arce__main_banks__c related to arce__account_has_analysis_id__c
    * -----------------------------------------------------------------------------------------------------
    * @Author   Ricardo Almanza
    * @Date     2019-06-20
    * @param    rid id related to arce__account_has_analysis_id__c
    * @return   arce__main_banks__c[] array with arce__main_banks__c related
    * @example  getMainBanks(rid)
    * */
    public static arce__main_banks__c[] getMainBanks(Id rid) {
        return [Select ID,NAME,arce__entity_name__c,arce__entity_quota_share_per__c from arce__main_banks__c where arce__account_has_analysis_id__c = :rid];
    }
}