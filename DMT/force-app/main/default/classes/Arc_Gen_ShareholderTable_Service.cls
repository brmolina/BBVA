/**
* ------------------------------------------------------------------------------------------------
* @Name     Arc_Gen_ShareholderTable_Service
* @Author   Mario Humberto Ramirez Lio  mariohumberto.ramirez.contractor@bbva.com
* @Date     Created: 2020-05-06
* @Group    ARCE
* ------------------------------------------------------------------------------------------------
* @Description Service class for Arc_Gen_ShareholderTable_Ctr
* ------------------------------------------------------------------------------------------------
* @Changes
*
* |2020-05-06 mariohumberto.ramirez.contractor@bbva.com
*             Class creation.
* |2020-09-23 saimassimilianno.jordana.contractor@bbva.com
*             Added arce. namespace to all classes that are now in the arce-dependencies package
* -----------------------------------------------------------------------------------------------
*/
public without sharing class Arc_Gen_ShareholderTable_Service {
    /*
        @Description code for subsidiary
    */
    static final String SUBSIDIARY = '2';
    /**
    * ----------------------------------------------------------------------------------------------------
    * @Description Void Constructor to avoid warning in sonar qube
    * ----------------------------------------------------------------------------------------------------
    * @Author   mariohumberto.ramirez.contractor@bbva.com
    * @Date     2020-05-06
    * @param void
    * @return void
    * @example Arc_Gen_ShareholderTable_Service service = new Arc_Gen_ShareholderTable_Service()
    * ----------------------------------------------------------------------------------------------------
    **/
    @TestVisible
    private Arc_Gen_ShareholderTable_Service() {

    }
    /**
    *---------------------------------------------------------------------------------------------------
    * @Description get the shareholder group table info needed to build the table
    *---------------------------------------------------------------------------------------------------
    * @Author  mariohumberto.ramirez.contractor@bbva.com
    * @Date    2020-05-06
    * @param   recordId - id of the account has analysis
    * @param   columns2Show - names of the columns to show
    * @return  Arc_Gen_ShareholderTable_Ctr.ShareHoldTableWp wrapper with the structure needed to build
    *          the table
    * @example getData(recordId, columns2Show)
    * --------------------------------------------------------------------------------------------------
    **/
    public static Arc_Gen_ShareholderTable_Ctr.ShareHoldTableWp getData(String recordId, List<String> columns2Show) {
        Arc_Gen_ShareholderTable_Ctr.ShareHoldTableWp shareHoldWrapper = new Arc_Gen_ShareholderTable_Ctr.ShareHoldTableWp();
        List<String> accHasIdLts = new List<String>();
        List<arce__Account_has_Analysis__c> accHasLts = arce.Arc_Gen_AccHasAnalysis_Data.getAccHasAnalysis(new List<String>{recordId});
        List<arce__Account_has_Analysis__c> allAccHasAn = arce.Arc_Gen_AccHasAnalysis_Data.accHasAnByArce(new List<String>{(String)accHasLts[0].arce__Analysis__c});
        for (arce__Account_has_Analysis__c accHas: allAccHasAn) {
            if (accHas.arce__InReview__c == true && accHas.arce__group_asset_header_type__c == SUBSIDIARY) {
                accHasIdLts.add((String)accHas.Id);
            }
        }
        shareHoldWrapper = Arc_Gen_ShareholderTable_Helper.buildTableStructure(accHasIdLts, columns2Show);
        if (shareHoldWrapper.hasInfo) {
            shareHoldWrapper.rowData = Arc_Gen_ShareholderTable_Helper.getRowInfo(shareHoldWrapper);
        }
        return shareHoldWrapper;
    }
}