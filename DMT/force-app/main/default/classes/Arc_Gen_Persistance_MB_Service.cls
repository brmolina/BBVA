/**
* ------------------------------------------------------------------------------------------------
* @Name     Arc_Gen_Persistance_MB_Service
* @Author   Bertha Elena Téllez Lira
* @Date     Created: 18/02/2020
* @Group    ARCE Team
* -----------------------------------------------------------------------------------------------
* @Description Class that manages dyanmic form save for main and bureau
* -----------------------------------------------------------------------------------------------
* @Changes
*
* |2020 berthaelena.tellez.contractor@bbva.com
*             Class creation.
* |2020/05/06 brthaelena.tellez.contractor@bbva.com
* @Changes : get value oj account_has_Analisys table
* |2020-09-23 saimassimilianno.jordana.contractor@bbva.com
*             Added arce. namespace to all classes that are now in the arce-dependencies package
* ------------------------------------------------------------------------------------------------
*/
public without sharing class Arc_Gen_Persistance_MB_Service {
    /**
    * @Description: Empty constructor
    */
        @testVisible
        private Arc_Gen_Persistance_MB_Service() {

        }
    /**
    * @Description: ASO service name
    */
        Static Final String SERVICE_NAME = 'mainBureauPersist';

    /**
    * -----------------------------------------------------------------------------------------------
    * @Description - Method that returns a Boolean value to notify if the execution of the bureau and main banks
    * persistence service was successful.
    * -----------------------------------------------------------------------------------------------
    * @Author   Bertha Elena Téllez Lira  berthaelena.tellez.contractor@bbva.com
    * @Date     Created: 18/02/2020
    * @param ids - List of ids of the account has analisys object
    * @param objDinaForm - List of properties of the account has analisys object
    * @return true/false
    * @example persistenceMB (ids, objDinaForm)
    * -----------------------------------------------------------------------------------------------
    **/
        public Static Boolean persistenceMB(List<String> ids, List<Arc_Gen_SaveMainBuroHelper.DataMainBuro>objDinaForm, List<sObject> listObject) {
            Boolean res = false;
            final List<Id> idAccounts = new List<Id>();
            final arce.Arc_Gen_ServiceAndSaveResponse serviceAndSaveResp = new arce.Arc_Gen_ServiceAndSaveResponse();
            arce.Arc_Gen_getIASOResponse.serviceResponse iasoResponse = new arce.Arc_Gen_getIASOResponse.serviceResponse();
            final List<arce__Account_has_Analysis__c> datosBasicos = arce.Arc_Gen_AccHasAnalysis_Data.getAccHasAnalysis(Ids);
            for(arce__Account_has_Analysis__c dato : datosBasicos) {
                idAccounts.add(dato.arce__Customer__c);
            }
            final Map<Id,arce.Arc_Gen_Account_Wrapper> listacc = arce.Arc_Gen_Account_Locator.getAccountInfoById(idAccounts);
            for(arce__Account_has_Analysis__c dato : datosBasicos) {
                final String riskAssessmentIid = dato.Name;
                final String participantId = listacc.get(dato.arce__Customer__c).accNumber;
                final String nbanks = dato.arce__number_entity_type__c == null ? '0':dato.arce__number_entity_type__c;
                final String nWl = String.valueOf(dato.arce__hats_risk_qualification_number__c);
                String strAuxjson = '';
                String jsonBankingEG = '';
                String jsonCreditBurEG = '';
                String jsonOtherBanks = '';
                String jsonConcentration = '';
                String jsonFinSystem = '';

                for(Arc_Gen_SaveMainBuroHelper.DataMainBuro variables: objDinaForm) {
                    if(dato.Id == variables.idDF) {
                        jsonBankingEG = createBankingEGTable(variables.idDF, listacc, dato);
                        jsonCreditBurEG = Arc_Gen_PersistanceMB_Locator.createBureauTable(variables.idDF);
                        jsonFinSystem = Arc_Gen_PersistanceMB_Locator.createfinacialSystem(variables.idDF, listObject);
                        jsonOtherBanks = createMainBanksTable(variables.idDF);
                        jsonConcentration = createConcenTable();
                        strAuxjson = '"hasSummaryComm" :"' + changeValue(variables.hasSummaryComm) +'","commentsRisk" : "' + variables.commentsRisk +'","numOfBanks": "' + nbanks +'","othersProducs":"' + changeValue(variables.othersProducs) + '","othersProdComm":"'+ variables.othersProdComm + '","otherOperations":"' + changeValue(variables.otherOperations) +'","otherOprDesc": "' + variables.otherOprDesc + '","rarRentab": "' + variables.rarRentab +'","rarComm": "' + variables.rarComm
                        +'","nivelWL": "' + nWl +'","stageColl": "' + changeValue(variables.stageColl) + '","stageCollDesc": "' + variables.stageCollDesc + '","custProductUsage": "' + variables.custProductUsage + '","bankPool": "' + variables.bankPool + '","capProvTyp": "' + variables.capProvTyp+ '","capProvDesc": "' + variables.capProvDesc + '","covenBreach": "' + changeValue(variables.covenBreach) + '","covenBreachDesc": "' + variables.covenBreachDesc +'",';
                        break;
                    }
                }
                iasoResponse = arce.Arc_Gen_getIASOResponse.calloutIASO(SERVICE_NAME,'{"risk-assessment-id" : "' + riskAssessmentIid +'","participant-id" : "' + participantId +'",' + strAuxjson + '"jsonBankingEG" :"' + jsonBankingEG +'","jsonCreditBurEG":"'+jsonCreditBurEG+'","jsonOtherBanks":"'+jsonOtherBanks+'","jsonConcentration":"'+jsonConcentration+'","jsonFinSystem":"'+jsonFinSystem+'"}');
                serviceAndSaveResp.serviceCode = iasoResponse.serviceCode;
                serviceAndSaveResp.serviceMessage = iasoResponse.serviceMessage;
                if(serviceAndSaveResp.serviceCode == '200' || serviceAndSaveResp.serviceCode == '201') {
                    res = true;
                }
            }
            return res;
        }
    /**
    * -----------------------------------------------------------------------------------------------
    * @Description - Method that returns a jason boolean  value
    * -----------------------------------------------------------------------------------------------
    * @Author   Bertha Elena Téllez Lira  berthaelena.tellez.contractor@bbva.com
    * @Date     Created: 18/03/2020
    * @param value - String with value of picklist
    * @return boolean
    * @example changeValue(value)
    * -----------------------------------------------------------------------------------------------
    **/
        public Static String changeValue(string value) {
            String result = 'false';
            if(!String.isEmpty(value)&& value == '1') { result = 'true';}
            return result;
        }
    /**
    * -----------------------------------------------------------------------------------------------
    * @Description - Method that returns a jason string  value
    * -----------------------------------------------------------------------------------------------
    * @Author   Bertha Elena Téllez Lira  berthaelena.tellez.contractor@bbva.com
    * @Date     Created: 19/02/2020
    * @param idArce - Identifier Arce
    * @param listacc - List of properties of the account object
    * @param dato - List of properties of the third Participant object
    * @return String
    * @example createBankingEGTable(idArce, listacc, dato)
    * -----------------------------------------------------------------------------------------------
    **/
        public Static String createBankingEGTable(String idArce, Map<Id,arce.Arc_Gen_Account_Wrapper> listacc, arce__Account_has_Analysis__c dato) {
            String strJson = '';
            List<id>idsArce = new List<id>();
            idsArce.add(idArce);
            final List<arce__risk_position_summary__c> datPosRiesgo = Arc_Gen_Risk_Position_summary_Data.getPositionSummaryData(idsArce);
            List<id> idsAccounts = new List<id> ();
            for(arce__risk_position_summary__c datorp :datPosRiesgo) {
                idsAccounts.add(datorp.arce__account_Id__c);
            }
            final String participantType = listacc.get(dato.arce__Customer__c).participantType;
            final Map<Id,arce.Arc_Gen_Account_Wrapper> listaccAcc = arce.Arc_Gen_Account_Locator.getAccountInfoById(idsAccounts);
            if(participantType == 'GROUP') {
                for(arce__risk_position_summary__c datorp :datPosRiesgo) {
                    String valueAcount = '';
                    String valueNam = '';
                    if(listaccAcc != null && listaccAcc.size() > 0 ) {
                        valueAcount = listaccAcc.get(datorp.arce__account_Id__c).accNumber;
                        valueNam = listaccAcc.get(datorp.arce__account_Id__c).name;
                    }
                    strJson += '{\\"id\\":\\"'+ valueAcount +'\\",\\"participantType\\":\\"G\\",\\"fullName\\":\\"'+ valueNam +'\\",\\"comments\\":\\"'+ datorp.arce__banrel_comments_desc__c+'\\",\\"riskAmounts\\": [{\\"id\\":\\"CURRENT_LIMIT\\", \\"amount\\":'+datorp.arce__banrel_current_limit_name__c+'},{\\"id\\":\\"COMMITED\\", \\"amount\\":'+datorp.arce__banrel_commitment_name__c +'},{\\"id\\":\\"UNCOMMITED\\", \\"amount\\":'+datorp.arce__banrel_uncommitment_name__c+'},{\\"id\\":\\"OUTSTANDING\\", \\"amount\\":'+datorp.arce__banrel_outstanding_name__c +'}]},';
                }
                final integer caracter = strJson.length();
                final String aux3 = strJson.substring(0, (caracter-1));
                strJson = aux3;
            }
            else {
                for(arce__risk_position_summary__c datorp :datPosRiesgo) {
                    strJson += '{\\"id\\":\\"'+ datorp.arce__Product_id__r.ExternalId +'\\",\\"participantType\\":\\"F\\",\\"fullName\\":\\"'+datorp.arce__Product_id__r.Name+'\\",\\"comments\\":\\"'+ datorp.arce__banrel_comments_desc__c+'\\",\\"riskAmounts\\": [{\\"id\\":\\"CURRENT_LIMIT\\", \\"amount\\":'+datorp.arce__banrel_current_limit_name__c+'},{\\"id\\":\\"COMMITED\\", \\"amount\\":'+datorp.arce__banrel_commitment_name__c +'},{\\"id\\":\\"UNCOMMITED\\", \\"amount\\":'+datorp.arce__banrel_uncommitment_name__c+'},{\\"id\\":\\"OUTSTANDING\\", \\"amount\\":'+datorp.arce__banrel_outstanding_name__c +'}]},';
                }
            }

            return strJson;
        }
    /**
    * -----------------------------------------------------------------------------------------------
    * @Description - Method that returns a jason string  value
    * -----------------------------------------------------------------------------------------------
    * @Author   Bertha Elena Téllez Lira  berthaelena.tellez.contractor@bbva.com
    * @Date     Created: 19/02/2020
    * @param idArce - Identifier Arce
    * @return String
    * @example createMainBanksTable(idArce)
    * -----------------------------------------------------------------------------------------------
    **/
        public Static String createMainBanksTable(String idArce) {
            String strJson = '';
            final List<arce__main_banks__c> datosMainBanks = Arc_Gen_MainBanks_Data.getMainBanks(idArce);
            if(datosMainBanks != null && datosMainBanks.size()>0) {
                for(arce__main_banks__c datorp :datosMainBanks) {
                    strJson += '{\\"id\\":\\"'+ datorp.name +'\\",\\"name\\":\\"'+ datorp.arce__entity_name__c +'\\",\\"percentage\\":' + datorp.arce__entity_quota_share_per__c + '},';
                }
            }
            else {
                strJson += '{\\"id\\":\\"'+ null +'\\",\\"name\\":\\"'+ null +'\\",\\"percentage\\":' + null+ '},';
            }
            final integer caracter = strJson.length();
                final string aux = strJson.substring(0, (caracter-1));
                strJson = aux;
            return strJson;
        }
    /**
    * -----------------------------------------------------------------------------------------------
    * @Description - Method that returns a jason string  value
    * -----------------------------------------------------------------------------------------------
    * @Author   Bertha Elena Téllez Lira  berthaelena.tellez.contractor@bbva.com
    * @Date     Created: 19/02/2020
    * @param
    * @return String
    * @example createConcenTable()
    * -----------------------------------------------------------------------------------------------
    **/
        public Static String createConcenTable() {
            String strJson = '';
            strJson = '{\\"id\\":\\"INDIVIDUALLY\\",\\"hasConcentration\\":\\"null\\",\\"comments\\":\\"null\\"},{\\"id\\":\\"GEOGRAPHY\\",\\"hasConcentration\\":\\"null\\",\\"comments\\":\\"null\\"},{\\"id\\":\\"COUNTRY\\",\\"hasConcentration\\":\\"null\\",\\"comments\\":\\"null\\"}';
            return strJson;
        }
    }