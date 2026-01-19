/**
* @File Name          : Arc_Gen_Tables_controller.cls
* @Description        : Return formated JSON String to be used on table component
* @Author             : ARCE Team
* @Group              : ARCE
* @Last Modified By   : manuelhugo.castillo.contractor@bbva.com
* @Last Modified On   : 23/06/2020
* @Modification Log   :
*==============================================================================
* Ver         Date                     Author                   Modification
*==============================================================================
* 1.0    8/5/2019 0:08:52   diego.miguel.contractor@bbva.com     Added comments
* 1.1    23/06/2020			manuelhugo.castillo.contractor@bbva.com Added logic to BottomUp
* 1.1    23/09/2020     saimassimilianno.jordana.contractor@bbva.com Added arce. namespace to all classes that are now in the arce-dependencies package
* 1.2    26/10/2020     joseluis.garcia4.contractor@bbva.com     Handle empty TDBU indicator for historical ARCEs.
**/
public with sharing class Arc_Gen_Tables_controller {
  /**
  *-------------------------------------------------------------------------------
  * @description Retuns formated JSON String with the given collectionType and recordId
  *--------------------------------------------------------------------------------
  * @date 7/5/2019
  * @author ARCE Team
  * @param String collectionType data collection type for tables
  * @param String record Id from account has analisis
  * @return String
  */
  public String getTableJsonComponent(String collectionType, String recordId) {
    String table = '';
    switch on collectionType {
      when 'Main_affiliates' {
        String BOTTOM_UP = '1';
        final List<arce__Account_has_Analysis__c> ahaTDBU = arce.Arc_Gen_AccHasAnalysis_Data.getAccHasAnalysis(new List<String>{recordId});
        if (ahaTDBU[0].arce__anlys_wkfl_cnsld_ffss_type__c == BOTTOM_UP || String.isEmpty(ahaTDBU[0].arce__anlys_wkfl_cnsld_ffss_type__c)) {
          table = '{"name":"dwp_dv:Configurable_Table_Display_cmp","attributes":{"recordId":"'+ recordId +'","configurationId":"Arc_Gen_'+collectionType+'_BU_MA","tableId":"'+collectionType+'","refreshOnRefreshViewEvent":true,"showTitle":true}},';
        } else {
          table = '{"name":"dwp_dv:Configurable_Table_Display_cmp","attributes":{"recordId":"'+ recordId +'","configurationId":"Arc_Gen_'+collectionType+'_MA","tableId":"'+collectionType+'","refreshOnRefreshViewEvent":true,"showTitle":true}},';
        }
      }
      when else {
        table = '{"name":"dwp_dv:Configurable_Table_Display_cmp","attributes":{"recordId":"'+ recordId +'","configurationId":"Arc_Gen_'+collectionType+'_MA","tableId":"'+collectionType+'","refreshOnRefreshViewEvent":true,"showTitle":true}},';
      }
    }
    return table;
  }
}