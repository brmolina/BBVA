/**
* @File Name          : Arc_Gen_ConnectedClients_Controller.cls
* @Description        : Controller class for Arc_Gen_ConnectedClients.cmp
* @Author             : aleksandar.dinkov.contractor@bbva.com
* @Group              : ARCE Team
* @Last Modified By   : aleksandar.dinkov.contractor@bbva.com
* @Last Modified On   : 03-02-2023
* @Changes
*==============================================================================
* Ver         Date                     Author                 Modification
*==============================================================================
* 1.0    03-02-2023  aleksandar.dinkov.contractor@bbva.com     Initial Version
*------------------------------------------------------------------------------
**/
@SuppressWarnings('sf:UseSingleton, sf:AvoidHardCodedError')
public with sharing class GDT_ConnectedClient_Controller {
    /**
    *-------------------------------------------------------------------------------
    * @Description method getConnClients
    *--------------------------------------------------------------------------------
    * @ Author aleksandar.dinkov.contractor@bbva.com
    * @ Date   Created: 03-02-2023
    *--------------------------------------------------------------------------------
    **/
    @AuraEnabled
    public static Map<String, Object> getConnClients(Id recordId, String srcEvtId) {
        // RETURN
        System.debug('REVISAR ' + recordId);
        final Map<String, Object> ret = new Map<String, Object>();
        try {
            // OBTENCION DEL AHA ASOCIADO
            final String ahaId = getAhaIdFromActSplit(recordId);
            final arce__Account_has_Analysis__c aha = arce.Arc_Gen_AccHasAnalysis_Data.getAccHasAnalysis(new List<String>{ahaId})[0];

            // OBTENCION DEL WRAPPER DE ACCOUNT
            final String correctId = arce.Arc_Gen_AccHasAnalysis_Data.getCorrectIdWAhas(aha);
            final Map<Id, arce.Arc_Gen_Account_Wrapper> accountWrpMap = arce.Arc_Gen_Account_Locator.getAccountInfoById(new List<Id>{correctId});

            if (srcEvtId == 'refreshButton' || aha.arce__Analysis__r.arce__reload_connected_clients__c) {
                // OBTENCION DE LOS CONNECTED CLIENTS EN BASE AL GLOBAL ID (ALPHA CODE)
                final Map<Id, arce.Arc_Gen_ConnectedClients_Wrapper> connClientsMap = arce.Arc_Gen_ConnectedClients_Locator.getConnClients(accountWrpMap.values()[0].globalId);
                fillReturnMap(ret, connClientsMap);

                // SE ELIMINAN LOS REGISTROS EXISTENTES DE arce__Analysis_has_Connected_Clients__c
                final List<arce__Analysis_has_Connected_Clients__c> toBeDeleted = arce.Arc_Gen_ConnectedClients_Data.getAnalysisHasConnCliByAnalysisId(aha.arce__Analysis__c);
                arce.Arc_Gen_ConnectedClients_Data.deleteRecords(toBeDeleted);

                // SE INSERTAN LOS REGISTROS NUEVOS DE arce__Analysis_has_Connected_Clients__c
                final List<arce__Analysis_has_Connected_Clients__c> toBeInserted = new List<arce__Analysis_has_Connected_Clients__c>();
                for (Id key : connClientsMap.keySet()) {
                    final arce__Analysis_has_Connected_Clients__c obj = new arce__Analysis_has_Connected_Clients__c();
                    obj.arce__Analysis__c = aha.arce__Analysis__c;
                    obj.arce__Connected_Client__c = key;
                    toBeInserted.add(obj);
                }
                arce.Arc_Gen_ConnectedClients_Data.insertRecords(toBeInserted);

                // SE MARCA EL CAMPO arce__reload_connected_clients__c A FALSE PARA QUE NO SE VUELVA A REFRESCAR LA TABLA AUTOMATICAMENTE.
                arce__Analysis__c toBeUpdated = arce.Arc_Gen_ArceAnalysis_Data.gerArce(ahaId);
                toBeUpdated.arce__reload_connected_clients__c = false;
                arce.Arc_Gen_ArceAnalysis_Data.updateArce(new List<arce__Analysis__c> {toBeUpdated});
            } else {
                final List<arce__Analysis_has_Connected_Clients__c> toBeShown = arce.Arc_Gen_ConnectedClients_Data.getAnalysisHasConnCliByAnalysisId(aha.arce__Analysis__c);
                final Set<Id> connCliIds = new Set<Id>();
                for (arce__Analysis_has_Connected_Clients__c aHCC : toBeShown) {
                    connCliIds.add(aHCC.arce__Connected_Client__c);
                }
                final Map<Id, arce.Arc_Gen_ConnectedClients_Wrapper> connClientsMap = arce.Arc_Gen_ConnectedClients_Locator.getConnClientsByIds(connCliIds);
                fillReturnMap(ret, connClientsMap);
            }
        } catch (Exception ex) {
            throw new AuraHandledException(String.valueOf(ex));
        }
        return ret;
    }
    /**
    *-------------------------------------------------------------------------------
    * @Description method persistAnswer
    *--------------------------------------------------------------------------------
    * @ Author aleksandar.dinkov.contractor@bbva.com
    * @ Date   Created: 03-02-2023
    *--------------------------------------------------------------------------------
    **/
    @AuraEnabled
    public static void persistAnswer(Id recordId, String option) {
        try {
            final String ahaId = getAhaIdFromActSplit(recordId);
            final arce__Analysis__c toBeUpdated = arce.Arc_Gen_ArceAnalysis_Data.gerArce(ahaId);
            toBeUpdated.arce__connected_clients_answer__c = option;
            arce.Arc_Gen_ArceAnalysis_Data.updateArce(new List<arce__Analysis__c> {toBeUpdated});
        } catch (Exception ex) {
            throw new AuraHandledException(String.valueOf(ex));
        }
    }
    /**
    *-------------------------------------------------------------------------------
    * @Description method getAnswer
    *--------------------------------------------------------------------------------
    * @ Author aleksandar.dinkov.contractor@bbva.com
    * @ Date   Created: 03-02-2023
    *--------------------------------------------------------------------------------
    **/
    @AuraEnabled
    public static String getAnswer(Id recordId) {
        String ret = '';
        final String ahaId = getAhaIdFromActSplit(recordId);
        arce__Analysis__c arceObj = arce.Arc_Gen_ArceAnalysis_Data.gerArce(ahaId);
        ret = arceObj.arce__connected_clients_answer__c;
        return ret;
    }

    /**
    *-------------------------------------------------------------------------------
    * @Description method getAhaIdFromActSplit
    *--------------------------------------------------------------------------------
    * @ Author aleksandar.dinkov.contractor@bbva.com
    * @ Date   Created: 03-02-2023
    *--------------------------------------------------------------------------------
    **/
    private static String getAhaIdFromActSplit(Id recordId) {
        String ahaId = recordId;
        final String objectType = String.valueOf(recordId.getSobjectType());
        if (objectType.contains('arce__Activity_Split__c')) {
           // ahaId = Arc_Gen_Activities_Util.getAllActivitiesById(new Set<Id>{recordId})[0].arce__Account_has_Analysis__c;
        } else if (objectType.contains('arce__Activity_Split_2012__c')) {
           // ahaId = Arc_Gen_Activities_Util.getAllActByParent2012ById(new Set<String>{recordId})[0].arce__Account_has_Analysis__c;
        }
        return ahaId;
    }

    /**
    *-------------------------------------------------------------------------------
    * @Description method fillReturnMap
    *--------------------------------------------------------------------------------
    * @ Author aleksandar.dinkov.contractor@bbva.com
    * @ Date   Created: 03-02-2023
    *--------------------------------------------------------------------------------
    **/
    private static void fillReturnMap(Map<String, Object> ret, Map<Id, arce.Arc_Gen_ConnectedClients_Wrapper> connClientsMap) {
        if (connClientsMap.isEmpty()) {
            //ret.put('retObj', new List<Arc_Gen_ConnectedClients_Wrapper>());
        } else {
            if (connClientsMap.values()[0].errorMessage == null) {
                ret.put('retObj', connClientsMap.values());
            } else {
                throw new AuraHandledException(connClientsMap.values()[0].errorMessage);
            }
        }
    }
}