/**
* ------------------------------------------------------------------------------------------------
* @Name     Arc_Gen_PersistanceArceId_service
* @Author  Ricardo Almanza Angeles  ricardo.almanza.contractor@bbva.com
* @Date     Created: 03/09/2019
* @Group    ARCE
* ------------------------------------------------------------------------------------------------
* @Description Uses IASO to conect to Risk Assesment service
* ------------------------------------------------------------------------------------------------
* @Changes
* 28/07/2019 ricardo.almanza.contractor@bbva.com
* Class creation.
* 4/11/2019 juanmanuel.perez.ortiz.contractor@bbva.com
* Add boolean parameter hasFinancialSponsor.
* 4/11/2019 juanmanuel.perez.ortiz.contractor@bbva.com
* Modified value in analysisId parameter.
* 6/12/2019 jhovanny.delacruz.cruz@bbva.com
* Encryption funcionality enabled
* 18/12/2019 franciscojavier.bueno@bbva.com
* Service Restructuring
* 13/01/2020 franciscojavier.bueno@bbva.com
* Risk Assessment Call Correction
* 29/01/2020 javier.soto.carrascosa@bbva.com
* Add fixes and manage risk assessment error
* 01/04/2020 javier.soto.carrascosa@bbva.com
* Modified methods 'riskAssHeaderCallout,riskAssCallout'to convert eventType parameter to dynamic
* 01/04/2020 javier.soto.carrascosa@bbva.com
* Support for local id
* 25/05/2020 cesaroctavio.villanueva.cebal@bbva.com
* Modified value of financial sponsor to get it from the method before being updated in Salesforce
* 23/06/2020 joseluis.garcia4.contractor@bbva.com
* Modify persistence of financialSponsor.
* 15/07/2020 javier.soto.carrascosa@bbva.com
* Add bank id and branch id
* 21/01/202 saimassimilianno.jordana.contractor@bbva.com
* Modified getAccountInfoById call in riskAssHeaderCallout meth0d to return the correct accountWrapper
* if customAccount exists.
* 2020-09-23 saimassimilianno.jordana.contractor@bbva.com
* Added arce. namespace to all classes that are now in the arce-dependencies package
* 2021-02-12 mariohumberto.ramirez.contractor@bbva.com
* Added new param to riskassessment persistence service 'assessmentType'
* 2021-02-22 joseluis.garcia4.contractor@bbva.com
* Adds 'assessmentType' in group persistence callout.
* 2022-04-26 francisco.munoz.torres.contractor@bbva.com
* Make location header field case insensitive
* -----------------------------------------------------------------------------------------------
*/
public with sharing class Arc_Gen_PersistanceArceId_service {
    /**
        * @Description: string with the service name
    */
        Static Final String SERVICE_NAME = 'riskassessments';
    /**
        * @Description: string with created resource response code (change to 200 if in scratch with mocks)
    */
        Static Final String COD_CREATED = '201';
    /**
        * @Description: string with a type of assessment
    */
        Static Final String RED_RAT = 'REDUCED_RATING_ASSESSMENT';
    /**
        * @Description: string with a type of assessment
    */
        Static Final String STD_ASSES = 'STANDARD_ASSESSMENT';
    /**
        * @Description: string with location
    */
        Static Final String LOCATION = 'location';
    /**
    *-------------------------------------------------------------------------------
    * @description Method that sets the parameters to the persistance service
    --------------------------------------------------------------------------------
    * @author ricardo.almanza.contractor@bbva.com
    * @date 03/09/2019
    * @param String clientNumber
    * @param String financialSponsor
    * @return arce.Arc_Gen_ServiceAndSaveResponse - Wrapper that contains the response of the called service and the DML operation
    * @example public static arce.Arc_Gen_ServiceAndSaveResponse setupRiskAssessments(String analysisId,String clientNumber)
    **/
    public arce.Arc_Gen_ServiceAndSaveResponse setupRiskAssHeader(String analysisId, String financialSponsor) {
        arce.Arc_Gen_ServiceAndSaveResponse serviceAndSaveResp = new arce.Arc_Gen_ServiceAndSaveResponse();
        final arce__Account_has_Analysis__c header = Arc_Gen_PersistanceArceId_data.persistanceDataAcc(analysisId);
        if (header.arce__risk_assessment_persisted__c == false) {
            serviceAndSaveResp = riskAssHeaderCallout(analysisId, header, financialSponsor);
            serviceAndSaveResp = processRiskAss(serviceAndSaveResp, true, header.Id);
        } else {
            serviceAndSaveResp.serviceCode = COD_CREATED;
            serviceAndSaveResp.serviceMessage = 'Resource has already been created in Oracle';
            serviceAndSaveResp.updatefields = new Map<String,Object>();
            serviceAndSaveResp.updatefields.put('arce__risk_assessment_persisted__c', true);
        }
        return serviceAndSaveResp;
    }
    /**
    *-------------------------------------------------------------------------------
    * @description Method that sets the parameters to the persistance service
    --------------------------------------------------------------------------------
    * @author ricardo.almanza.contractor@bbva.com
    * @date 03/09/2019
    * @param String clientNumber
    * @return arce.Arc_Gen_ServiceAndSaveResponse - Wrapper that contains the response of the called service and the DML operation
    * @example public static arce.Arc_Gen_ServiceAndSaveResponse setupRiskAssessments(String analysisId,String clientNumber)
    **/
    public arce.Arc_Gen_ServiceAndSaveResponse setupRiskAssessments(String analysisId, String customer) {
        arce.Arc_Gen_ServiceAndSaveResponse serviceAndSaveResp = new arce.Arc_Gen_ServiceAndSaveResponse();
        final arce__Account_has_Analysis__c accSubs = Arc_Gen_PersistanceArceId_data.persistanceDataS(analysisId,customer);
        if (accSubs.arce__risk_assessment_persisted__c == false) {
            serviceAndSaveResp = riskAssCallout(analysisId, customer, accSubs);
            serviceAndSaveResp = processRiskAss(serviceAndSaveResp, false, accSubs.Id);
        } else {
            serviceAndSaveResp.serviceCode = COD_CREATED;
            serviceAndSaveResp.serviceMessage = 'Resource has already been created in Oracle';
            serviceAndSaveResp.updatefields = new Map<String,Object>();
            serviceAndSaveResp.updatefields.put('arce__risk_assessment_persisted__c', true);
        }
        return serviceAndSaveResp;
    }
    /**
    *-------------------------------------------------------------------------------
    * @description Method that sets the parameters to the persistance service
    --------------------------------------------------------------------------------
    * @author ricardo.almanza.contractor@bbva.com
    * @date 03/09/2019
    * @param String analysisId
    * @param String clientNumber
    * @param arce__Account_has_Analysis__c accHas
    * @return arce.Arc_Gen_ServiceAndSaveResponse - Wrapper that contains the response of the called service and the DML operation
    * @example riskAssCallout (String analysisId, String customer, arce__Account_has_Analysis__c accHas)
    **/
    public arce.Arc_Gen_ServiceAndSaveResponse riskAssCallout (String analysisId, String customer, arce__Account_has_Analysis__c accSubs) {
        final arce.Arc_Gen_ServiceAndSaveResponse serviceAndSaveResp = new arce.Arc_Gen_ServiceAndSaveResponse();
        arce.Arc_Gen_getIASOResponse.serviceResponse iasoResponse = new arce.Arc_Gen_getIASOResponse.serviceResponse();
        final arce__Account_has_Analysis__c header = Arc_Gen_PersistanceArceId_data.persistanceDataAcc(analysisId);
        final Map<Id,arce.Arc_Gen_Account_Wrapper> mapWrap = arce.Arc_Gen_Account_Locator.getAccountInfoById(new List<Id>{accSubs.arce__Customer__c});
        final arce__Analysis__c analysis = arce.Arc_Gen_ArceAnalysis_Data.getArceAnalysisData(new List<Id>{analysisId})[0];
        final String subprocessType = analysis.arce__anlys_wkfl_sub_process_type__c;
        final String eventType = subprocessType == '4' ? 'NEW' : arce.Arc_Gen_GenericUtilities.getEventTypeValue(subprocessType);
        final String encryptedClient = arce.Arc_Gen_CallEncryptService.getEncryptedClient(mapWrap.get(accSubs.arce__Customer__c).accNumber);
        final String ChildARCE = accSubs.Name;
        final String ParentARCE = header.Name;
        final String NumClient = encryptedClient;
        String typeArc = mapWrap.get(accSubs.arce__Customer__c).participantType;
        if(accSubs.arce__RAR_rating_tool_id__c.contains('RTC')) {
            typeArc = arce.Arc_gen_Util.getFilialSubsidiaryByAha(new List<String>{(String) accSubs.id});
        }

        final String NameClient = mapWrap.get(accSubs.arce__Customer__c).name;
        final String docNumber = mapWrap.get(accSubs.arce__Customer__c).docNumber;
        final String docType = mapWrap.get(accSubs.arce__Customer__c).docType;
        final String branchId = mapWrap.get(accSubs.arce__Customer__c).branchId;
        final String bankId = mapWrap.get(accSubs.arce__Customer__c).bankId;
        final String assType = getAssessmentType(subprocessType);
        final String finSponsor = analysis.arce__controlled_by_sponsor_type__c == Arc_Gen_SetFinancialSponsor_Service.FINANCIAL_SPONSOR_YES ? 'true' : 'false';
        iasoResponse = arce.Arc_Gen_getIASOResponse.calloutIASO(SERVICE_NAME,'{"ChildARCE" : "' + ChildARCE +'","assType" : "' + assType +'","ParentARCE" : "' + ParentARCE +'","branchId" : "' + branchId +'","bankId" : "' + bankId +'","docNumber" : "' + docNumber +'","docType" : "' + docType +'","NumClient" : "' + NumClient +'","TypeArc" : "' + typeArc +'","NameClient" : "' +  NameClient +'","FS" : "' + finSponsor +'","eventType" : "' + eventType +'"}');
        serviceAndSaveResp.serviceCode = iasoResponse.serviceCode;
        serviceAndSaveResp.serviceMessage = iasoResponse.serviceMessage;
        serviceAndSaveResp.serviceHeaders = iasoResponse.serviceHeaders;
        return serviceAndSaveResp;
    }
    /**
    *-------------------------------------------------------------------------------
    * @description Method that returns the assesstype
    --------------------------------------------------------------------------------
    * @author mariohumberto.ramirez.contractor@bbva.com
    * @date 02/12/2021
    * @param String subprocess - subprocess type
    * @return REDUCED_RATING_ASSESSMENT or STANDARD_ASSESSMENT
    * @example getAssessmentType(subprocess)
    **/
    private static String getAssessmentType(String subprocess) {
        return subprocess == '4' ? RED_RAT : STD_ASSES;
    }
    /**
    *-------------------------------------------------------------------------------
    * @description Method that sets the parameters to the persistance service
    --------------------------------------------------------------------------------
    * @author ricardo.almanza.contractor@bbva.com
    * @date 03/09/2019
    * @param String analysisId
    * @param arce__Account_has_Analysis__c header
    * @param String financialSponsor
    * @return arce.Arc_Gen_ServiceAndSaveResponse - Wrapper that contains the response of the called service and the DML operation
    **/
    public arce.Arc_Gen_ServiceAndSaveResponse riskAssHeaderCallout(String analysisId, arce__Account_has_Analysis__c header, String financialSponsor) {
        final arce.Arc_Gen_ServiceAndSaveResponse serviceAndSaveResp = new arce.Arc_Gen_ServiceAndSaveResponse();
        arce.Arc_Gen_getIASOResponse.serviceResponse iasoResponse = new arce.Arc_Gen_getIASOResponse.serviceResponse();
        final String customerId = arce.Arc_Gen_AccHasAnalysis_Data.getCorrectIdWAhas(header);
        final Map<Id, arce.Arc_Gen_Account_Wrapper> mapWrap = arce.Arc_Gen_Account_Locator.getAccountInfoById(new List<Id>{customerId});
        final String subprocessType = arce.Arc_Gen_ArceAnalysis_Data.getArceAnalysisData(new List<Id>{analysisId})[0].arce__anlys_wkfl_sub_process_type__c;
        final String eventType = subprocessType == '4' ? 'NEW' : arce.Arc_Gen_GenericUtilities.getEventTypeValue(subprocessType);
        final String encryptedClient = arce.Arc_Gen_CallEncryptService.getEncryptedClient(mapWrap.get(customerId).accNumber);
        final String ChildARCE = header.Name;
        final String ParentARCE = header.Name;
        final String NumClient = encryptedClient;
        final String typeArc = mapWrap.get(customerId).participantType;
        final String NameClient = mapWrap.get(customerId).name;
        final String docNumber = mapWrap.get(customerId).docNumber;
        final String docType = mapWrap.get(customerId).docType;
        final String branchId = mapWrap.get(customerId).branchId;
        final String bankId = mapWrap.get(customerId).bankId;
        final String assType = getAssessmentType(subprocessType);
        final String finSponsor = financialSponsor == Arc_Gen_SetFinancialSponsor_Service.FINANCIAL_SPONSOR_YES ? 'true' : 'false';
        iasoResponse = arce.Arc_Gen_getIASOResponse.calloutIASO(SERVICE_NAME,'{"ChildARCE" : "' + ChildARCE +'","assType" : "' + assType +'","ParentARCE" : "' + ParentARCE +'","branchId" : "' + branchId +'","bankId" : "' + bankId +'","docNumber" : "' + docNumber +'","docType" : "' + docType +'","NumClient" : "' + NumClient +'","TypeArc" : "' + typeArc +'","NameClient" : "' +  NameClient +'","FS" : "' + finSponsor +'","eventType" : "' + eventType +'"}');
        serviceAndSaveResp.serviceCode = iasoResponse.serviceCode;
        serviceAndSaveResp.serviceMessage = iasoResponse.serviceMessage;
        serviceAndSaveResp.serviceHeaders = iasoResponse.serviceHeaders;
        return serviceAndSaveResp;
    }
    /**
    *-------------------------------------------------------------------------------
    * @description Method that sets the parameters to the persistance service
    --------------------------------------------------------------------------------
    * @author ricardo.almanza.contractor@bbva.com
    * @date 03/09/2019
    * @param String clientNumber
    * @return arce.Arc_Gen_ServiceAndSaveResponse - Wrapper that contains the response of the called service and the DML operation
    * @example public static arce.Arc_Gen_ServiceAndSaveResponse setupRiskAssessments(String analysisId,String clientNumber)
    **/
    public arce.Arc_Gen_ServiceAndSaveResponse processRiskAss (arce.Arc_Gen_ServiceAndSaveResponse riskAss, boolean updateData, Id ahaId) {
        final String localField = arce.Arc_Gen_Arceconfigs_locator.getConfigurationInfo('LocalIdentifier')[0].arce__Value1__c;
        if (riskAss.serviceCode == COD_CREATED && updateData) {
            arce__account_has_analysis__c upAha = new arce__account_has_analysis__c(Id = ahaId);
            upAha.arce__risk_assessment_persisted__c = true;
            upAha = updateAhaLocalId(upAha, localField, riskAss);
            arce.Arc_Gen_AccHasAnalysis_Data.updateAccHasAnalysis(new List<arce__account_has_analysis__c>{upAha});
        } else if (riskAss.serviceCode == COD_CREATED && !updateData) {
            riskAss.updatefields = new Map<String,Object>();
            riskAss.updatefields.put('arce__risk_assessment_persisted__c', true);
            updateMapLocalId(localField, riskAss);
        } else {
            CalloutException e = new CalloutException();
            e.setMessage(System.Label.Arc_Gen_OraclePersistenceError);
            throw e;
        }
        return riskAss;
    }
    /**
    *-------------------------------------------------------------------------------
    * @description Method that update account_has_analysis with local field
    --------------------------------------------------------------------------------
    * @author javier.soto.carrascosa@bbva.com
    * @date 01/04/2020
    * @param arce__account_has_analysis__c aha
    * @param String localField
    * @param arce.Arc_Gen_ServiceAndSaveResponse riskAss
    * @return arce__account_has_analysis__c -updated account has analysis
    * @example private arce__account_has_analysis__c updateAhaLocalId (aha,localField,riskAss)
    **/
    private arce__account_has_analysis__c updateAhaLocalId (arce__account_has_analysis__c aha, string localField, arce.Arc_Gen_ServiceAndSaveResponse riskAss) {
        if (arce.Arc_Gen_ValidateInfo_utils.isFilled(localField)) {
            aha.put(localField,getIdFromHeader(riskAss));
        }
        return aha;
    }
    /**
    *-------------------------------------------------------------------------------
    * @description Method that updates Map with local field
    --------------------------------------------------------------------------------
    * @author javier.soto.carrascosa@bbva.com
    * @date 01/04/2020
    * @param String localField
    * @param arce.Arc_Gen_ServiceAndSaveResponse riskAss
    * @return arce.Arc_Gen_ServiceAndSaveResponse - Wrapper that contains the response of the called service and the DML operation
    * @example private arce.Arc_Gen_ServiceAndSaveResponse updateMapLocalId (string localField, arce.Arc_Gen_ServiceAndSaveResponse riskAss)
    **/
    private arce.Arc_Gen_ServiceAndSaveResponse updateMapLocalId (string localField, arce.Arc_Gen_ServiceAndSaveResponse riskAss) {
        if (arce.Arc_Gen_ValidateInfo_utils.isFilled(localField)) {
            riskAss.updatefields.put(localField,getIdFromHeader(riskAss));
        }
        return riskAss;
    }
    /**
    *-------------------------------------------------------------------------------
    * @description Method that retrieves local Id from risk assessment header
    --------------------------------------------------------------------------------
    * @author javier.soto.carrascosa@bbva.com
    * @date 01/04/2020
    * @param arce.Arc_Gen_ServiceAndSaveResponse riskAss
    * @return String
    * @example private String getIdFromHeader (arce.Arc_Gen_ServiceAndSaveResponse riskAss)
    **/
    private String getIdFromHeader (arce.Arc_Gen_ServiceAndSaveResponse riskAss) {
        final Map<String, String> header = riskAss.serviceHeaders;

        String localId = '';
        if(arce.Arc_Gen_ValidateInfo_utils.hasInfoMap(header)) {

            string locationKeyName = LOCATION;
            for(String key : header.keySet()) {
              if(key.toLowerCase() == LOCATION) {
                locationKeyName = key;
                break;
              }
            }

            final String riskAssLocation = header.get(locationKeyName);
            if (arce.Arc_Gen_ValidateInfo_utils.isFilled(riskAssLocation)) {
                localId = riskAssLocation.substringAfterLast('/');
            }
        }
        return localId;
    }
}