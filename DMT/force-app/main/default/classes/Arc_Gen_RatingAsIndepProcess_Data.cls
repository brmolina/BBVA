/**
* ------------------------------------------------------------------------------------------------
* @Name     Arc_Gen_RatingAsIndepProcess_Data
* @Author   saimassimilianno.jordana.contractor@bbva.com
* @Date     Created: 2021-04-09
* @Group    ARCE
* ------------------------------------------------------------------------------------------------
* @Description Data class of the new rating as independent process
* ------------------------------------------------------------------------------------------------
* @Changes
*
* |2020-01-08 saimassimilianno.jordana.contractor@bbva.com
*             Class creation.setFFSSWAhasName
* |2020-05-05 saimassimilianno.jordana.contractor@bbva.com
*             Parameter Deleted and added new one in setFFSSWAhasName meth0d.
* |2021-12-22 saimassimilianno.jordana.contractor@bbva.com
*             Info added to ffss related in setFFSSWAhasName meth0d.
* -----------------------------------------------------------------------------------------------
*/
public  with sharing class Arc_Gen_RatingAsIndepProcess_Data {

    /**
    * @description: Empty constructor
    **/
    @TestVisible
    private Arc_Gen_RatingAsIndepProcess_Data() {

    }

    /**
    *---------------------------------------------------------------------------------------
    * @Description  Method  that inserts the ffss with Ahas Name and relate an empty rating
    *---------------------------------------------------------------------------------------
    * @Author   Sai Jordana  saimassimilianno.jordana.contractor@bbva.com
    * @Date     Created: 2021-02-24
    * @param String rarRatingTool - Rar Rating Tool selected by the user.
    * @return   arce__Financial_Statements__c
    * @example  setFFSSWAhasName()
    * -------------------------------------------------------------------------------
    */
    public static arce__Financial_Statements__c setFFSSWAhasName(String rarRatingTool, String ahasId) {
        final arce__rating__c emptyRating = new arce__rating__c();
        if (String.isNotBlank(rarRatingTool)) {
            emptyRating.arce__rar_rating_tool_id__c = rarRatingTool;
        }
        insert emptyRating;

        final arce__Financial_Statements__c ffss = new arce__Financial_Statements__c(arce__rating_id__c = emptyRating.Id);
        if (String.isNotBlank(rarRatingTool)) {
            final Boolean isCons = rarRatingTool.left(11) == '00110009091';
            ffss.arce__account_has_analysis_id__c = ahasId;
            ffss.arce__ffss_submitted_type__c = isCons ? '1' : '2';
            ffss.arce__ffss_valid_type__c = isCons ? '1' : '';
        }
        insert ffss;

        return ffss;
    }

    /**
    *-------------------------------------------------------------------------------
    * @Description Return the default settings for EEFF Corp Setting
    *-------------------------------------------------------------------------------
    * @Date    2022-04-21
    * @Author  andres.rodriguez.munoz.contractor@bbva.com
    * @return  Boolean
    * @example Boolean retVal = invokeRatiosEngine(recordId, ratingToolSelect);
    *-------------------------------------------------------------------------------
    */
    public static EEFF_Corp_Setting__mdt getEFFCorpDefaultSettings() {
        EEFF_Corp_Setting__mdt defaultSettings = [SELECT DeveloperName, Show_EEFF_Message__c FROM EEFF_Corp_Setting__mdt WHERE DeveloperName = 'Default_Settings' WITH SECURITY_ENFORCED]; // NOSONAR
        return defaultSettings;
    }
}