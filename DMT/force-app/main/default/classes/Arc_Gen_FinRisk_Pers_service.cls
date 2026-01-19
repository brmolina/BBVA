/**
* ------------------------------------------------------------------------------------------------
* @Name     Arc_Gen_FinRisk_Pers_service
* @Author   Javier Soto Carrascosa
* @Date     Created: 08/04/2020
* @Group    ARCE
* -----------------------------------------------------------------------------------------------
* @Description Class that manages save for Basic Data
* -----------------------------------------------------------------------------------------------
* @Changes
*
* |2020-04-08 Javier Soto Carrascosa
*             Class creation.
* |2020-09-23 saimassimilianno.jordana.contractor@bbva.com
*             Added arce. namespace to all classes that are now in the arce-dependencies package
* |2021-08-02 jose.hijar.contractor@bbva.com
*             Moves financialInfoJSON method and its dependencies to Arc_Gen_FinRisk_Pers_Helper class
* |2022-06-06 juanignacio.hita.contractor@bbva.com
*             Add checkChangesQualQuestion validation
* -----------------------------------------------------------------------------------------------
*/
global class Arc_Gen_FinRisk_Pers_service implements dyfr.Save_Interface {//NOSONAR
    /**
    * -----------------------------------------------------------------------------------------------
    * @Description - Method that is responsible for invoking the classes to save the
      business riks information
    * -----------------------------------------------------------------------------------------------
    * @Author  Javier Soto Carrascosa
    * @Date     Created: 08/04/2020
    * @param listObject - List of the account has analisys object
    * @return String with the execution message
    * @example save (listObject)
    * -----------------------------------------------------------------------------------------------
    **/
    public static String save(List<sObject> listObject) {
        Boolean hasPermission = Arc_Gen_TabSet_service.hasPermissionToEdit(listObject);

        String retValue;
        if (hasPermission) {
            Map<String, Object> financialRiskMap = new Map<String, Object>();
            final arce__Account_has_Analysis__c ahaData = Arc_Gen_Persistence_Utils.getAhaFromSobject(listObject);
            final arce__Account_has_Analysis__c accHasAnalysis = arce.Arc_Gen_AccHasAnalysis_Data.getAccHasAnalysis(new List<String>{(String)ahaData.Id})[0];
            financialRiskMap = Arc_Gen_FinRisk_Pers_Helper.financialInfoJSON(ahaData, accHasAnalysis);
            final Map<Id,arce.Arc_Gen_Account_Wrapper> listacc = arce.Arc_Gen_Account_Locator.getAccountInfoById(new List<String>{accHasAnalysis.arce__Customer__c});
            final String participantId = arce.Arc_Gen_CallEncryptService.getEncryptedClient(listacc.get(accHasAnalysis.arce__Customer__c).accNumber);
            final boolean financialInfo = Arc_Gen_OraclePers_service.financialRiskWS(participantId, accHasAnalysis.Name, financialRiskMap);
            Arc_Gen_FieldConfig_Data.checkChangesQualQuestion(ahaData, accHasAnalysis, String.valueOf(Arc_Gen_FinRisk_Pers_service.class.getName()));
            retValue = JSON.serialize(new arce.Arc_Gen_wrpSave(financialInfo,'',listObject));
        } else {
            retValue = JSON.serialize(new arce.Arc_Gen_wrpSave(false, Label.Arc_Gen_Generic_NotAllowed, listObject));
        }
        return retValue;
    }
}