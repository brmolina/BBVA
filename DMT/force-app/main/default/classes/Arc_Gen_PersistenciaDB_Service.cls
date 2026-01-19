/**
* ------------------------------------------------------------------------------------------------
* @Name     Arc_Gen_PersistenciaDB_Service
* @Author   Bertha Elena Téllez Lira
* @Date     Created: 15/01/2020
* @Group    ARCE Team
* -----------------------------------------------------------------------------------------------
* @Description Class that manages dyanmic form save for Basic Data.
* -----------------------------------------------------------------------------------------------
* @Changes
*
* |2020 berthaelena.tellez.contractor@bbva.com
*             Class creation.
* |2020-09-23 saimassimilianno.jordana.contractor@bbva.com
*             Added arce. namespace to all classes that are now in the arce-dependencies package
* -----------------------------------------------------------------------------------------------
*/
public class Arc_Gen_PersistenciaDB_Service {
    /**
        * @Description: Empty constructor
    */
    @testVisible
    private Arc_Gen_PersistenciaDB_Service() {

    }
    /**
        * @Description: ASO service name
    */
    Static Final String SERVICE_NAME = 'bassicData';
    /**
    * -----------------------------------------------------------------------------------------------
    * @Description - Method that returns a Boolean value to notify if the execution of the basic
    * data persistence service was successful.
    * -----------------------------------------------------------------------------------------------
    * @Author   Bertha Elena Téllez Lira  berthaelena.tellez.contractor@bbva.com
    * @Date     Created: 23/01/2020
    * @param ids - List of ids of the account has analisys object
    * @param datEnv - List of properties of the account has analisys object
    * @return true/false
    * @example persistenceBD (ids, datEnv)
    * -----------------------------------------------------------------------------------------------
    **/
    public Static Boolean persistenceBD (List<String> ids, List<Arc_Gen_SaveBasicData.DataBasic> datEnv) {
        Boolean res = false;
        List<Id> idAccounts = new List<Id>();
        final arce.Arc_Gen_ServiceAndSaveResponse serviceAndSaveResp = new arce.Arc_Gen_ServiceAndSaveResponse();
        arce.Arc_Gen_getIASOResponse.serviceResponse iasoResponse = new arce.Arc_Gen_getIASOResponse.serviceResponse();
        final List<arce__Account_has_Analysis__c> datosBasicos = arce.Arc_Gen_AccHasAnalysis_Data.getAccHasAnalysis(Ids);
        for(arce__Account_has_Analysis__c dato : datosBasicos) {
            idAccounts.add(dato.arce__Customer__c);
        }
        final Map<Id,arce.Arc_Gen_Account_Wrapper> listacc = arce.Arc_Gen_Account_Locator.getAccountInfoById(idAccounts);

        for(arce__Account_has_Analysis__c dato : datosBasicos) {
            String riskAssessmentIid = dato.Name;
            String participantId = listacc.get(dato.arce__Customer__c).accNumber;
            String grupo = '';
            String refinanced = '';
            String refinanceDesc = '';
            String sector = '';
            String subSector = '';
            String actividad = '';
            String template = '';
            String empleados = '';
            for(Arc_Gen_SaveBasicData.dataBasic variables : datEnv) {
                if(dato.Id == variables.id) {
                    grupo = variables.grupo;
                    refinanced = variables.refinanced;
                    refinanceDesc = variables.refinanceDesc;
                    sector = variables.sector;
                    subSector = variables.subSector;
                    actividad = variables.actividad;
                    template = variables.template;
                    empleados = variables.empleados;
                    break;
                }
            }
            iasoResponse = arce.Arc_Gen_getIASOResponse.calloutIASO(SERVICE_NAME,'{"risk-assessment-id" : "' + riskAssessmentIid +'","participant-id" : "' + participantId +'","grupo" : "' + grupo +'","refinanced" : "' + refinanced +'","refinanceDesc" : "' + refinanceDesc +'","sector" : "' + sector +'","subSector" : "' + subSector +'","actividad" : "' + actividad +'","template": "' + template + '","empleados": "' + empleados +'"}');
            serviceAndSaveResp.serviceCode = iasoResponse.serviceCode;
            serviceAndSaveResp.serviceMessage = iasoResponse.serviceMessage;
            if(serviceAndSaveResp.serviceCode == '200' || serviceAndSaveResp.serviceCode == '201') {
                res = true;
            }

        }
        return res;
    }

}