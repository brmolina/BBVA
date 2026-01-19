/**
* @File Name          : Arc_Gen_ValidateRating_data.cls
* @Description        : Class that receives the data of salesforce to the rating validation
* @Author             : eduardoefrain.hernandez.contractor@bbva.com
* @Group              : ARCE Team
* @Last Modified By   : luisruben.quinto.munoz@bbva.com
* @Last Modified On   : 24/7/2019 19:03:09
* @Changes
*==============================================================================
* Ver         Date                     Author      		      Modification
*==============================================================================
* 1.0    13/5/2019 18:00:36   eduardoefrain.hernandez.contractor@bbva.com     Initial Version
* 1.1    19/12/2019 16:51:22  manuelhugo.castillo.contractor@bbva.com         Modify 'getAccountHasAnalysis' method replace
*                                                                             arce__Account_has_Analysis__c to arce.Arc_Gen_Account_Has_Analysis_Wrapper
* 1.2    26/05/2020 14:58:30  cesaroctavio.villanueva.cebal@bbva.com          Removed unused validate persistance service call
* 1.2    23/09/2020     saimassimilianno.jordana.contractor@bbva.com          Added arce. namespace to all classes that are now in the arce-dependencies package
**/
public without sharing class Arc_Gen_ValidateRating_data {
/**
*-------------------------------------------------------------------------------
* @description Wrapper for the status and mesage for Rating
--------------------------------------------------------------------------------
* @author eduardoefrain.hernandez.contractor@bbva.com
* @date 2019-05-13
* @param void
* @example final SaveResult updateResults = new SaveResult();
**/
    public class SaveResult {
        public String status {get;set;}
        public String message {get;set;}
    }
/**
*-------------------------------------------------------------------------------
* @description Method that obtains an Account Has Analysis record
--------------------------------------------------------------------------------
* @author eduardoefrain.hernandez.contractor@bbva.com
* @date 2019-05-13
* @param String analyzedClientId Id of account
* @return arce__Account_has_Analysis__c - record
* @example public arce__Account_has_Analysis__c getAccountHasAnalysis(String analyzedClientId)
**/
    public arce.Arc_Gen_Account_Has_Analysis_Wrapper getAccountHasAnalysis(String analyzedClientId) {
        Return arce.Arc_Gen_AccHasAnalysis_Data.getAccountHasAnalysisAndCustomer(new List<String>{analyzedClientId})[0];
    }
/**
*-------------------------------------------------------------------------------
* @description Method that obtains a rating record
--------------------------------------------------------------------------------
* @author eduardoefrain.hernandez.contractor@bbva.com
* @date 2019-05-13
* @param String rating Id
* @return arce__rating__c - record
* @example public arce__rating__c getRatingData(String ratingId)
**/
    public arce__rating__c getRatingData(String ratingId) {
        Return arce.Arc_Gen_Rating_data.generalRatingData(new List<String>{ratingId})[0];
    }
/**
*-------------------------------------------------------------------------------
* @description Method that obtains a rating record
--------------------------------------------------------------------------------
* @author eduardoefrain.hernandez.contractor@bbva.com
* @date 2019-05-13
* @param String rating Id
* @return arce__rating__c - record
* @example public arce__rating__c getRatingData(String ratingId)
**/
    public List<arce__rating_variables_detail__c> getRatingVariables(String ratingId) {
        List<arce__rating__c> ratingList = [SELECT Id,(SELECT Id,arce__adj_long_rating_value_type__c,arce__adj_short_rating_value_type__c,arce__PD_per__c,arce__adj_total_rating_score_number__c FROM arce__Rating_variables_details__r) FROM arce__rating__c WHERE Id =: ratingId];
        List<arce__rating_variables_detail__c> variablesList = ratingList[0].arce__Rating_variables_details__r;
        Return variablesList;
    }
/**
*-------------------------------------------------------------------------------
* @description Method that updates an sObject record
--------------------------------------------------------------------------------
* @author eduardoefrain.hernandez.contractor@bbva.com
* @date 2019-05-13
* @param sObject recordToUpdate for rating
* @return SaveResult - A Wrapper with information of the results of the DML operation
* @example public SaveResult updateRecord(sObject recordToUpdate)
**/
    public SaveResult updateRecord(sObject recordToUpdate) {
        final SaveResult updateResults = new SaveResult();
        try {
            updateResults.status = 'true';
            update(recordToUpdate);
        } catch(DmlException e) {
            updateResults.status = 'false';
            updateResults.message = e.getMessage();
        }
        Return updateResults;
    }
}