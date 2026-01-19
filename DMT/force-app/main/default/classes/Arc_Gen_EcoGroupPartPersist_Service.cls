/**
* ------------------------------------------------------------------------------------------------
* @Name     Arc_Gen_EcoGroupPartPersist_Service
* @Author   Mario Humberto Ramirez Lio mariohumberto.ramirez.contractor@bbva.com
* @Date     Created: 24/04/2020
* @Group    ARCE
* -----------------------------------------------------------------------------------------------
* @Description Service class for economic group participant persistance service
* -----------------------------------------------------------------------------------------------
* @Changes
*
* |2020-04-24 mariohumberto.ramirez.contractor@bbva.com
*             Class creation.
* |2020-09-14 mariohumberto.ramirez.contractor@bbva.com
*             Modified callPersistence method in order to manage errors.
* |2020-09-23 saimassimilianno.jordana.contractor@bbva.com
*             Added arce. namespace to all classes that are now in the arce-dependencies package
* |2020-09-29 joseluis.garcia4.contractor@bbva.com
*             Provide group account number in 'economicGpId' parameter.
* |2021-06-14 juanignacio.hita.contractor@bbva.com
*             Add EcoGroupPartWrapper and save data fields of Account object.
* -----------------------------------------------------------------------------------------------
*/
public without sharing class Arc_Gen_EcoGroupPartPersist_Service {
    /**
        * @Description: Codes accepted by service
    */
    private static final List<String> CODES_ACCEPT = new List<String> {'200', '201', '202', '204'};
    /**
        * @Description: Name service constant
    */
    private static final String NAME_SERVICE = 'economicGpParticipantPersist';
    /**
    * @Description: Remove reason when arce is revoked.
    */
    static final String REMOVE_REASON = '2';
    /**
    * @Description: Custom exception for EcoGroupPartPersist class
    */
    public class SetEcoGroupPersException extends Exception { }
    /**
        * @Description: void constrctor
    */
    private Arc_Gen_EcoGroupPartPersist_Service() {

    }
    /**
    *------------------------------------------------------------------------------------------------------------
    * @description Method that calls the economic group participant persitance service.
    *------------------------------------------------------------------------------------------------------------
    * @Author mariohumberto.ramirez.contractor@bbva.com
    * @Date 24/04/2020
    * @param Arc_Gen_CallListParticipant.innertoreturnlistp listparticipant - list participant wrapper
    * @param List<arce.Arc_Gen_Account_Wrapper> accountsParticipants - accounts participants info
    * @param String analysisId - Analysis Id
    * @return arce.Arc_Gen_ServiceAndSaveResponse - Wrapper that contains the response of the called service
    * @example callEcoGroupParticipantsPer(listparticipant, accPartWrapLts, analysisId)
    * -----------------------------------------------------------------------------------------------------------
    */
    public static arce.Arc_Gen_ServiceAndSaveResponse callPersistence(Arc_Gen_CallListParticipant.innertoreturnlistp listparticipants, List<arce.Arc_Gen_Account_Wrapper> accPartWrapLts, String analysisId) {
        final arce.Arc_Gen_ServiceAndSaveResponse returnResponse = new arce.Arc_Gen_ServiceAndSaveResponse();
        arce__Account_has_Analysis__c accHasAnGp = new arce__Account_has_Analysis__c();
        try {
            final List<arce__Account_has_Analysis__c> allAccHasAn = arce.Arc_Gen_AccHasAnalysis_Data.accHasAnByArce(new List<String>{analysisId});
            for (arce__Account_has_Analysis__c accHasAn: allAccHasAn) {
                if (accHasAn.arce__group_asset_header_type__c == arce.Arc_Gen_Constants.GROUP_ASSET_HEADER_TYPE_HEADER) {
                    accHasAnGp = accHasAn;
                }
            }
            if (accHasAnGp.arce__Customer__c == null) {
                final arce.Arc_Gen_CustomServiceMessages serviceMessage = new arce.Arc_Gen_CustomServiceMessages();
                Arc_Gen_Remove_Service.updateRemoveInfo(allAccHasAn[0].Id, REMOVE_REASON, System.Label.Arc_Gen_RevokeArceByChangesStrucGroup, '');
                throw new SetEcoGroupPersException(String.valueOf(serviceMessage.CODE_204));
            }
            final Map<Id,arce.Arc_Gen_Account_Wrapper> accWrapGp = arce.Arc_Gen_Account_Locator.getAccountInfoById(new List<Id>{accHasAnGp.arce__Customer__c});
            final String participantId = arce.Arc_Gen_CallEncryptService.getEncryptedClient(accWrapGp.get(accHasAnGp.arce__Customer__c).accNumber);
            final String dynJson = Arc_Gen_EcoGroupPartPersist_Helper.buildJson(listparticipants, accPartWrapLts).escapeJava();
            final String jsonInput = '{"riskId":' + '"' + accHasAnGp.Name + '",' + '"participantId":' + '"' + participantId + '",' + '"economicGpId":' + '"' + participantId + '",' + '"dynJSON":' + '"' + dynJson + '"}';
            final arce.Arc_Gen_getIASOResponse.serviceResponse iasoResponse = arce.Arc_Gen_getIASOResponse.calloutIASO(NAME_SERVICE, jsonInput);
            returnResponse.serviceCode = iasoResponse.serviceCode;
            returnResponse.serviceMessage = iasoResponse.serviceMessage;
            if (CODES_ACCEPT.contains(iasoResponse.serviceCode)) {
                final Map<String, Arc_Gen_EcoGroupPartPersist_Helper.EcoGroupPartWrapper> mapEcoGroupPart = Arc_Gen_EcoGroupPartPersist_Helper.fillWrapperServices(listparticipants, accPartWrapLts);
                final arce.Arc_Gen_ServiceAndSaveResponse serviceAndSave = Arc_Gen_EcoGroupPartPersist_Helper.saveDataAcc(mapEcoGroupPart);
                returnResponse.saveStatus = serviceAndSave.saveStatus;
                returnResponse.saveMessage = serviceAndSave.saveMessage;
            }
        } catch (Exception e) {
            returnResponse.serviceCode = '500';
            returnResponse.saveStatus = 'false';
            returnResponse.serviceMessage = e.getMessage();
            returnResponse.saveMessage = e.getTypeName() + ' : ' + e.getMessage() + ' : ' + e.getStackTraceString();
        }
        return returnResponse;
    }
}