/**
* ------------------------------------------------------------------------------------------------
* @Name     Arc_Gen_ModRen_Interface
* @Author   Mario Humberto Ramirez Lio mariohumberto.ramirez.contractor@bbva.com
* @Date     Created: 2020-08-04
* @Group    ARCE
* -----------------------------------------------------------------------------------------------
* @Description Interface "Arc_Gen_ModRen_Interface"
* -----------------------------------------------------------------------------------------------
* @Changes
*
* |2020-08-04 mariohumberto.ramirez.contractor@bbva.com
*             Interface creation.
* |2020-09-24 eduardoefrain.hernandez.contractor@bbva.com
*             Update associateAccHasAn2Arce method parameters
* |2020-10-14 eduardoefrain.hernandez.contractor@bbva.com
*             Update associateAccHasAn2Arce method to remove emptyFFSS param
* |2021-03-11 juanmanuel.perez.ortiz.contractor@bbva.com
*             Update associateAccHasAn2Arce method to add data param
* |2021-12-23 francisco.munoz.torres.contractor@bbva.com
*             Create associateRecordsFFSS2AHA
* -----------------------------------------------------------------------------------------------
*/public interface Arc_Gen_ModRen_Interface {
    /**
    *
    * @Description : retrieves a wrapper (Arc_Gen_CloneWrapper) with all the objects copied from the ARCE to renew or modify.
    */
    Arc_Gen_CloneWrapper getRelatedRecordsArce(String analysisId, String modRenVar);
    /**
    *
    * @Description : clone all the information stored in Arc_Gen_CloneWrapper and retrieves the cloned records
    */
    Arc_Gen_CloneWrapper cloneRecords(Arc_Gen_CloneWrapper records, String modRenVar);
    /**
    *
    * @Description :  sets and associates all account has analysis records that were previously cloned to the object Analysis
    */
    List<arce__Account_has_Analysis__c> associateAccHasAn2Arce(Arc_Gen_CloneWrapper response, String customerRelation, Boolean persistanceStatus, Map<String, String> data);
    /**
    *
    * @Description :  associates all previously cloned objects to all new account has analysis objects
    */
    String associateRecords2AccHasAn(Arc_Gen_CloneWrapper response, Map<String,arce__Account_has_Analysis__c> mapaha, String modRenVar);
    /**
    *
    * @Description :  manage the traceability messagge
    */
    void manageTraceability(String arceId, String modRenVar);
    /**
    *
    * @Description :  associates all previously cloned FFSS objects to correct AHA
    */
    void associateRecordsFFSS2AHA(Arc_Gen_CloneWrapper response, Map<String,arce__Account_has_Analysis__c> mapaha, String modRenVar);
}