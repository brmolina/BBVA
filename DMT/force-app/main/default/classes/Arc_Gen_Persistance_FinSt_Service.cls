/**
* ------------------------------------------------------------------------------------------------
* @Name     Arc_Gen_Persistance_FinSt_Service
* @Author   Bertha Elena Téllez Lira
* @Date     Created: 05/01/2020
* @Group    ARCE Team
* -----------------------------------------------------------------------------------------------
* @Description Class that manages dyanmic form save for Financial Statement.
* -----------------------------------------------------------------------------------------------
* @Changes
*
* |2020 berthaelena.tellez.contractor@bbva.com
*             Class creation.
* |2020-04-14 berthaelena.tellez.contractor@bbva.com
*    resolve fix on mapeo data
* |2020-09-23 saimassimilianno.jordana.contractor@bbva.com
*             Added arce. namespace to all classes that are now in the arce-dependencies package
* ------------------------------------------------------------------------------------------------
*/
public without sharing class Arc_Gen_Persistance_FinSt_Service {
    /**
* @Description: Empty constructor
*/
    @testVisible
    private Arc_Gen_Persistance_FinSt_Service() {

    }
    /**
* @Description: ASO service name
*/
    Static Final String SERVICE_NAME = 'financialStatementsPersist';
    /**
* -----------------------------------------------------------------------------------------------
* @Description - Method that returns a Boolean value to notify if the execution of the financial
* statement persistence service was successful.
* -----------------------------------------------------------------------------------------------
* @Author   Bertha Elena Téllez Lira  berthaelena.tellez.contractor@bbva.com
* @Date     Created: 05/02/2020
* @param ids - List of ids of the account has analisys object
* @param objDinaForm - List of properties of the account has analisys object
* @param matTable - List of properties of the third Participant object
* @return true/false
* @example persistenceFS (ids, objDinaForm)
* -----------------------------------------------------------------------------------------------
**/
    public Static Boolean persistenceFS(List<String> ids, List<Arc_Gen_SaveFinancialStatementHelper.FinacialStatements>objDinaForm){
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
            String strAuxjson = '';
            String jsonMaturity = '';
            String arrList = '';

            for(Arc_Gen_SaveFinancialStatementHelper.FinacialStatements variables: objDinaForm) {
                if(dato.Id == variables.id) {
                    jsonMaturity = createMaturityTable(variables.id);
                    strAuxjson = '"opinionAuditor" : "' + variables.opinionAuditor +'","fullName" : "' + variables.fullName +'","quality" : "' + variables.quality +'","agentComments" : "' + variables.agentComments +'","finStId" : "' + variables.finStId +'","finStConsolidate" : "' + variables.finStConsolidate +'","currencyType": "' + variables.currencyType +
                                                                '","units": "' + variables.units + '","availableMat": "' + changeValue(variables.availableMat) +'","debtMat": "' + variables.debtMat +'","banksNumbre": "' + variables.banksNumbre + '","budgetType":"'+ changeValue(variables.budgetType) + '","budgetIsInc": "' + changeValue(variables.budgetIsInc) +'","budgetComments": "' + variables.budgetComments +'",';
                    arrList = createList(variables.listIndicator, variables.listVariations, variables.listVariables);
                    break;
                }
            }

            iasoResponse = arce.Arc_Gen_getIASOResponse.calloutIASO(SERVICE_NAME,'{"risk-assessment-id" : "' + riskAssessmentIid +'","participant-id" : "' + participantId +'",' + strAuxjson + arrList + '"jsonMaturity" :"' + jsonMaturity +'"}');
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
* @Description - Method that returns a jason string  value
* -----------------------------------------------------------------------------------------------
* @Author   Bertha Elena Téllez Lira  berthaelena.tellez.contractor@bbva.com
* @Date     Created: 07/02/2020
* @param idArce - Identifier Arce
* @param objDinaForm - List of properties of the account has analisys object
* @param matTable - List of properties of the third Participant object
* @return String
* @example createMaturityTable(String idArce)
* -----------------------------------------------------------------------------------------------
**/
    public Static String createMaturityTable(String idArce) {
        String jsonMaturity = '';

        List<arce__Table_Content_per_Analysis__c> dataConsult = [SELECT Name, arce__table_content_year__c, arce__table_content_value__c, CurrencyIsoCode, arce__Data_Collection_Id__R.Name FROM arce__Table_Content_per_Analysis__c
                                                                  WHERE RecordType.DeveloperName = 'Maturity_table' AND arce__account_has_analysis_id__c =: idArce];

        integer numberList = dataConsult.size();

        if(!dataConsult.isEmpty() && numberList > 0){
            for(arce__Table_Content_per_Analysis__c dato :dataConsult){
                jsonMaturity += '{\\"id\\":\\"'+ dato.Name +' \\", \\"description\\":\\"' + dato.arce__Data_Collection_Id__R.Name + '\\", \\"debtAmount\\": {\\"amount\\":' + dato.arce__table_content_value__c + ', \\"currency\\":\\"' + dato.CurrencyIsoCode +'\\"}, \\"year\\": ' + dato.arce__table_content_year__c + '},';

            }
            integer caracter = jsonMaturity.length();
            string aux = jsonMaturity.substring(0, (caracter-1));
            jsonMaturity = aux;
        }

        return jsonMaturity;
    }
    /**
* -----------------------------------------------------------------------------------------------
* @Description - Method that returns a string  value to invocate service of persistance financial Statement
* -----------------------------------------------------------------------------------------------
* @Author   Bertha Elena Téllez Lira  berthaelena.tellez.contractor@bbva.com
* @Date     Created: 11/02/2020
* @param listIndicator - List of values of indicators
* @param listVariations - List of variations
* @param listVariables - List of variables
* @return String
* @example createList(listIndicator, listVariations, listVariables)
* -----------------------------------------------------------------------------------------------
**/
    public Static String createList(List<Arc_Gen_SaveFinancialStatementHelper.ArraysData>listIndicator, List<Arc_Gen_SaveFinancialStatementHelper.ArraysData>listVariations, List<Arc_Gen_SaveFinancialStatementHelper.ArraysData>listVariables) {
        string listasArr = '';
        if(!listIndicator.isEmpty()){
            listasArr = '"indId": "' + listIndicator[0].idIndicator + '","isActive": "' + changeValue(listIndicator[0].isActive) +'","indComm": "' + listIndicator[0].commentsIndicators +'","indId1": "' + listIndicator[1].idIndicator +'","isActive1": "' + changeValue(listIndicator[1].isActive) +'","indComm1": "' + listIndicator[1].commentsIndicators
                +'","indId2": "' + listIndicator[2].idIndicator + '","isActive2": "' + changeValue(listIndicator[2].isActive) + '","indComm2": "' + listIndicator[2].commentsIndicators + '","indId3": "' + listIndicator[3].idIndicator + '","isActive3": "' + changeValue(listIndicator[3].isActive) + '","indComm3": "' + listIndicator[3].commentsIndicators + '","indId4": "' + listIndicator[4].idIndicator + '","isActive4": "' + changeValue(listIndicator[4].isActive) + '","indComm4": "' + listIndicator[4].commentsIndicators + '","indId5": "' + listIndicator[5].idIndicator + '","isActive5": "' + changeValue(listIndicator[5].isActive) + '","indComm5": "' + listIndicator[5].commentsIndicators
                + '","indId6": "' + listIndicator[6].idIndicator + '","isActive6": "' + changeValue(listIndicator[6].isActive) + '","indComm6": "' + listIndicator[6].commentsIndicators +'",';

        }
        if(!listVariations.isEmpty()){
            listasArr += '"variID": "' + listVariations[0].idIndicator +'","variComm": "' + listVariations[0].commentsIndicators +'","variID1": "' + listVariations[1].idIndicator +'","variComm1": "' + listVariations[1].commentsIndicators +'","variID2": "' + listVariations[2].idIndicator +'","variComm2": "' + listVariations[2].commentsIndicators +'","variID3": "' + listVariations[3].idIndicator +'","variComm3": "' + listVariations[3].commentsIndicators +'","variID4": "' + listVariations[4].idIndicator +'","variComm4": "' + listVariations[4].commentsIndicators
                +'","variID5": "' + listVariations[5].idIndicator +'","variComm5": "' + listVariations[5].commentsIndicators +'","variID6": "' + listVariations[6].idIndicator +'","variComm6": "' + listVariations[6].commentsIndicators +'","variID7": "' + listVariations[7].idIndicator +'","variComm7": "' + listVariations[7].commentsIndicators +'","variID8": "' + listVariations[8].idIndicator +'","variComm8": "' + listVariations[8].commentsIndicators +'",';

        }
        if(!listVariables.isEmpty()) {
            listasArr +='"varId": "' + listVariables[0].idIndicator +'","varType": "' + listVariables[0].variableType +'","varId1": "' + listVariables[1].idIndicator +'","varType1": "' + listVariables[1].variableType +'","varId2": "' + listVariables[2].idIndicator +'","varType2": "'
                + listVariables[2].variableType +'","varId3": "' + listVariables[3].idIndicator +'","varType3": "' + listVariables[3].variableType +'",';

        }
        return listasArr;
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
}