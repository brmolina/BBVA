/**
* --------------------------------------------------------------------------------------------------------
* @Name     Arc_Gen_NAHA_Service
* @Author   Mario Humberto Ramirez Lio  mariohumberto.ramirez.contractor@bbva.com
* @Date     Created: 2019-10-12
* @Group    ARCE
* --------------------------------------------------------------------------------------------------------
* @Description Service class for Arc_Gen_NAHACtrl
* --------------------------------------------------------------------------------------------------------
* @Changes
*
* |2019-10-12 mariohumberto.ramirez.contractor@bbva.com
*             Class creation.
* |2020-01-15 javier.soto.carrascosa@bbva.com
*             Add support for account update from Account Wrapper interface
* |2020-01-29 javier.soto.carrascosa@bbva.com
*             Do not allow to add element in carrusel if risk assessment fails
* |2020-04-12 javier.soto.carrascosa@bbva.com
*             Add support to retrieve local field from risk assessment location
* |2020-04-27 ricardo.almanza.contractor@bbva.com
*             added logic for arce__customer_arce_scope_type__c on triage
* |2020-05-13 cesaroctavio.villanueva.cebal@bbva.com
*             added call to setFinancialSponsor method
* |2020-05-14 joseluis.garcia4.contractor@bbva.com
*             Uses arce__customer_arce_scope_type__c picklist values instead of true/false.
* |2020-05-15 cesaroctavio.villanueva.cebal@bbva.com
*             Moved setFinancialSponsor method to avoid pending operation error
* |2020-06-23 joseluis.garcia4.contractor@bbva.com
*             Remove setFinancialSponsor call.
* |2020-07-23 ricardo.almanza.contractor@bbva.com
*             added scope and triage.
* |2020-08-13 juanignacio.hita.contractor@bbva.com
*             Added validation service code for path service
* |2020-09-23 saimassimilianno.jordana.contractor@bbva.com
*             Added arce. namespace to all classes that are now in the arce-dependencies package
* |2020-10-21 mariohumberto.ramirez.contractor@bbva.com
*             Added call to the metodo Arc_Gen_Hotel_Projection_Service.insertTableRecords(idRecord)
* |2020-11-10 juanmanuel.perez.ortiz.contractor@bbva.com
*             Added call to the method Arc_Gen_Contracts_Appraisals_Service.insertTableRecord(idRecord)
* |2020-11-12 moises.martinez.dominguez.contractor@bbva.com
*             Added call to the method Arc_Gen_AnalysisCategory_Service.insertTableRecord(idRecord)
*             Added call to the method Arc_Gen_Analysis_Date_Service.insertTableRecord(idRecord)
* |2020-12-16 antonio.munoz.perez.contractor@bbva.com
*             Added validation validateTDRating.
* |2020-12-18 juanignacio.hita.contractor@bbva.com
*             Adds call to risk filter service when adds new customer, created callRiskFilterServ method, refactor validElementInCarousel
* |2021-01-13 antonio.munoz.perez.contractor@bbva.com
*             Added updateFailResponse() method.
* |2021-06-04 joseluis.garcia4.contractor@bbva.com
*             Change return type of scopeElement to differentiate between no scope/not known yet.
* |2021-09-01 juanignacio.hita.contractor@bbva.com
*             Skip call to allocation package if running in tests
* |2021-09-27 juanignacio.hita.contractor@bbva.com
*             Add sector condition to insert records objects of the hotel sector
* --------------------------------------------------------------------------------------------------------
*/
public with sharing class Arc_Gen_NAHA_Service {
    /**
    * @Description: Constant that represents that an ARCE is in scope.
    */
    public static final String SCOPE_INSCOPE = 'inScope';

    /**
    * @Description: Constant that represents that an ARCE is not in scope.
    */
    public static final String SCOPE_NOTINSCOPE = 'notInScope';

    /**
    * @Description: Constant that represents that an ARCE has a pending triage process.
    */
    public static final String SCOPE_TRIAGEPENDING = 'triagePending';

    /**
    * @Description: Numeric value that indicates that the ARCE is in scope.
    */
    private static final String SCOPENUM_INSCOPE = '1';

    /**
    * @Description: Numeric value that indicates that the ARCE is not in scope.
    */
    private static final String SCOPENUM_NOTINSCOPE = '2';

    /**
    * @Description: Hotel sector constant
    */
    private static final String HOTEL_SECTOR = '3';

    /**
    * ----------------------------------------------------------------------------------------------------
    * @Description Void Constructor to avoid warning in sonar qube
    * ----------------------------------------------------------------------------------------------------
    * @Author   mariohumberto.ramirez.contractor@bbva.com
    * @Date     2019-10-12
    * @param void
    * @return void
    * @example Arc_Gen_NAHA_Service Service = new Arc_Gen_NAHA_Service()
    * ----------------------------------------------------------------------------------------------------
    **/
    @TestVisible
    private Arc_Gen_NAHA_Service() {

    }
    /*----------------------------------------------------------------------------------------------------
    *@Description Naha Service
    * ----------------------------------------------------------------------------------------------------
    * @Author   LUIS RUBEN QUINTO MUÑOZ
    * @Date     2019-07-28
    * @param    Id idRecord - Id of the Account has Analysis selected
    * @param    String field - Field selected
    * @param    Boolean value - If is true, the analyzed client is visible in the carousel
    * @return   qvcd.GBL_CardDetails_Ctrl.CardPagerWrapper - Wrapper that contains the response of the
    *           quick view card
    * @example  validElementInCarousel(Id idRecord, String field, boolean value)
    * ----------------------------------------------------------------------------------------------------
    **/
    public static qvcd.GBL_CardDetails_Ctrl.CardPagerWrapper validElementInCarousel(Id idRecord, String field, boolean value) {
        qvcd.GBL_CardDetails_Ctrl.CardPagerWrapper response = new qvcd.GBL_CardDetails_Ctrl.CardPagerWrapper();
        final List<arce.Arc_Gen_ServiceAndSaveResponse> results = new List<arce.Arc_Gen_ServiceAndSaveResponse>();
        final Arc_Gen_ListCustomersService_service service = new Arc_Gen_ListCustomersService_service();
        final Arc_Gen_getPathDataService_data locator = new Arc_Gen_getPathDataService_data();
        arce.Arc_Gen_ServiceAndSaveResponse listCust = new arce.Arc_Gen_ServiceAndSaveResponse();
        arce.Arc_Gen_ServiceAndSaveResponse riskAss = new arce.Arc_Gen_ServiceAndSaveResponse();
        arce.Arc_Gen_ServiceAndSaveResponse pahtEngine = new arce.Arc_Gen_ServiceAndSaveResponse();
        final Map<Id, Map<String,Object>> accUp = new Map<Id, Map<String,Object>>();
        Arc_Gen_PersistanceArceId_service servicePers = new Arc_Gen_PersistanceArceId_service();
        response.gblResultResponse = true;
        final List<String> clientNumber = idRecord == null ? null : Arc_Gen_getPathDataService_service.getCustomerData(idRecord);
        arce__account_has_analysis__c listup = new arce__account_has_analysis__c(Id = idRecord);
        final arce.Arc_Gen_CustomServiceMessages customMessages = new arce.Arc_Gen_CustomServiceMessages();
        boolean validateQual = true;
        try {
            // Fire risk assesessments service
            results.add(validateQualitative(idRecord,listup));
        } catch (Exception callEx) {
            validateQual = false;
            updateFailResponse(response, callEx);
        }
        //setupRiskAssessments
        if (validateQual) {
            try {
                riskAss = servicePers.setupRiskAssessments(clientNumber[0],clientNumber[1]);
                results.add(riskAss);
            } catch (Exception callEx) {
                updateFailResponse(response, callEx);
            }
            try {
                listCust = service.setupListCustomers(clientNumber[2], false);
                results.add(listCust);
                accUp.put((Id)clientNumber[1],listCust.updatefields);
                // Fire get path service
                pahtEngine = Arc_Gen_NAHA_Service_Helper.callPathService(idRecord);
                // Call to risk filter service for retrieve local regulatory data
                response = callRiskFilterServ(clientNumber);

            } catch (Exception callEx) {
                updateFailResponse(response, callEx);
            }

            arce.Arc_Gen_GenericUtilities.populateObjFromMap(listup, riskAss.updatefields);
            if (pahtEngine.serviceCode == String.valueOf(customMessages.CODE_200)) {
                results.add(pahtEngine);
                arce.Arc_Gen_GenericUtilities.populateObjFromMap(listup, pahtEngine.updatefields);
                locator.updateRecords(new List<arce__account_has_analysis__c>{listup});
                arce.Arc_Gen_Account_Locator.accountUpdate(accUp);
                Arc_Gen_Expandible_Table_Service.verifyTypologiesInserted(idRecord);
                Arc_Gen_PotitionBankTable_Service.verifyDataInserted(idRecord);
                final String analysisTemplateId = arce.Arc_Gen_AccHasAnalysis_Data.getAccHasRelation(idRecord).arce__analysis_template_id__c;
                if (analysisTemplateId == HOTEL_SECTOR) {
                    Arc_Gen_Hotel_Projection_Service.insertTableRecords(idRecord);
                    Arc_Gen_Contracts_Appraisals_Service.insertTableRecord(idRecord);
                    Arc_Gen_Analysis_Date_Service.insertTableRecord(idRecord);
                    Arc_Gen_Analysis_Category_Service.insertTableRecord(idRecord);
                }
            } else {
                updateFailResponse(response, null);
            }
        }
        return response;
    }
    /*----------------------------------------------------------------------------------------------------
    *@Description Updates a response with gblResultResponse=false and gblDescriptionResponse with the Exception passed.
    * ----------------------------------------------------------------------------------------------------
    * @Author   Antonio Muñoz Pérez
    * @Date     2020-01-29
    * @param    qvcd.GBL_CardDetails_Ctrl.CardPagerWrapper response - reponse to update
    * @param    Exception callEx - Exception catched. If null, general error message will be set.
    * @example  private void updateFailResponse(qvcd.GBL_CardDetails_Ctrl.CardPagerWrapper response, Exception callEx)
    * ----------------------------------------------------------------------------------------------------
    **/
    private static void updateFailResponse(qvcd.GBL_CardDetails_Ctrl.CardPagerWrapper response, Exception callEx) {
        response.gblResultResponse = false;
        if (callEx == null) {
            response.gblDescriptionResponse =  System.Label.Lc_arce_PathGeneralError;
        } else {
            response.gblDescriptionResponse = callEx.getMessage();
        }
    }
    /*----------------------------------------------------------------------------------------------------
    *@Description validates permission to add element to carrusel with arce allocation component
    * ----------------------------------------------------------------------------------------------------
    * @Author   Javier Soto Carrascosa
    * @Date     2020-01-29
    * @param    Id idRecord - Id of the Account has Analysis selected
    * @return    Boolean value - If is true, the analyzed cliente can be added or removed
    * @example  public static boolean validateAddElement(Id idRecord)
    * ----------------------------------------------------------------------------------------------------
    **/
    public static boolean validateAddElement(Id idRecord) {
        final List<ID> records = new List<ID>();
        records.add(idRecord);
        final Type inter = Type.forName('arcealloc.Allocation_Service');
        final boolean custAlloc = String.isNotBlank(String.valueOf(inter)) && !Test.isRunningTest() ? ((Map<Id,boolean>) ((Callable) inter.newInstance()).call('checkBulkPrivileges', new Map<String, Object> {'accHasAnlysIdsLst' => records})).get(idRecord) : true ;
        final boolean retval = custAlloc;
        return retval;
    }
    /*----------------------------------------------------------------------------------------------------
    *@Description validates scope to add element to carrusel
    * ----------------------------------------------------------------------------------------------------
    * @Author   Ricardo Almanza
    * @Date     2020-07-23
    * @param    Id idRecord - Id of the Account has Analysis selected
    * @return   String value - The status of the scope of the client.
    * @example  public static String scopeElement(Id idRecord)
    * ----------------------------------------------------------------------------------------------------
    **/
    public static String scopeElement(Id idRecord) {
        final List<ID> records = new List<ID>();
        records.add(idRecord);
        final List<arce__Account_has_Analysis__c> aHA = arce.Arc_Gen_AccHasAnalysis_Data.getAccHasAnalysis(records);
        final String scope = aHA[0].arce__customer_arce_scope_type__c;
        String retval;
        if (scope == SCOPENUM_INSCOPE) {
            retval = SCOPE_INSCOPE;
        } else if (scope == SCOPENUM_NOTINSCOPE) {
            retVal = SCOPE_NOTINSCOPE;
        } else {
            retVal = SCOPE_TRIAGEPENDING;
        }
        return retval;
    }
    /*----------------------------------------------------------------------------------------------------
    *@Description validates scope to add element to carrusel
    * ----------------------------------------------------------------------------------------------------
    * @Author   Ricardo Almanza
    * @Date     2020-07-23
    * @param    Id idRecord - Id of the Account has Analysis selected
    * @return    triageElement value - triage status
    * @example  public static String triageElement(Id idRecord)
    * ----------------------------------------------------------------------------------------------------
    **/
    public static String triageElement(Id idRecord) {
        final List<ID> records = new List<ID>();
        records.add(idRecord);
        final List<arce__Account_has_Analysis__c> aHA = arce.Arc_Gen_AccHasAnalysis_Data.getAccHasAnalysis(records);
        return aHA[0].arce__Analysis__r.arce__triageStatus__c;
    }
    /*----------------------------------------------------------------------------------------------------
    * @Description Method that call risk filter service retrieve local regulatory data
    * ----------------------------------------------------------------------------------------------------
    * @Author   juanignacio.hita.contractor@bbva.com
    * @Date     2020-12-18
    * @param    List<String> clientNumber
    * @return   qvcd.GBL_CardDetails_Ctrl.CardPagerWrapper
    * @example  qvcd.GBL_CardDetails_Ctrl.CardPagerWrapper resp = callRiskFilterServ(clientNumber);
    * ----------------------------------------------------------------------------------------------------
    **/
    private static qvcd.GBL_CardDetails_Ctrl.CardPagerWrapper callRiskFilterServ(List<String> clientNumber) {
        qvcd.GBL_CardDetails_Ctrl.CardPagerWrapper response = new qvcd.GBL_CardDetails_Ctrl.CardPagerWrapper();
        try {
            final arce.Arc_Gen_CustomServiceMessages customMessages = new arce.Arc_Gen_CustomServiceMessages();
            final Map<String, Object> mapObj = new Map<String, Object> {
                'customerId' => clientNumber[1],
                'analysisId' => clientNumber[0]
            };
            final arce.Arc_Gen_ServiceAndSaveResponse serviceSave = Arc_Gen_RiskFilters_Service.calloutService(mapObj);
            if (serviceSave.saveStatus == 'true' && serviceSave.serviceCode == String.valueOf(customMessages.CODE_200)) {
                response.gblResultResponse = true;
            } else {
                response.gblResultResponse = false;
                response.gblDescriptionResponse = System.Label.Arc_Gen_ErrorService;
            }
        } catch (Exception callEx) {
            response.gblResultResponse = false;
            response.gblDescriptionResponse =  System.Label.Lc_arce_PathGeneralError;
        }
        return response;
    }
    /*----------------------------------------------------------------------------------------------------
    *@Description validate qualitative
    * ----------------------------------------------------------------------------------------------------
    * @Author   Mykola Akimov
    * @Date     2020-06-09
    * @param    Id idRecord - Id of the Account has Analysis selected,arce__account_has_analysis__c listup
    * @return   Arc_Gen_ServiceAndSaveResponse
    * @example  public static Arc_Gen_ServiceAndSaveResponse validateQualitative
    * ----------------------------------------------------------------------------------------------------
    **/
    public static arce.Arc_Gen_ServiceAndSaveResponse validateQualitative (id idRecord,arce__account_has_analysis__c listup) {
        arce.Arc_Gen_ServiceAndSaveResponse ratingTD = Arc_Gen_NAHA_Service_Helper.validateTDRating(idRecord);
        if (ratingTD.updatefields != null) {
            arce.Arc_Gen_GenericUtilities.populateObjFromMap(listup, ratingTD.updatefields);
        }
        return ratingTD;
    }
}