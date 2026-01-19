/**
* ____________________________________________________________________________
* Utilities class
* ____________________________________________________________________________
* @author      
* @modifiedBy
* @version     1.0
* @created     2022-08-23
* @modified
* @systemLayer 
* ____________________________________________________________________________
* @changes
*
* ____________________________________________________________________________
*/
public with sharing class DPMX_Utils {
    
    /**
    * @description prevent instantiation
    */
    private DPMX_Utils() {}

    /**
    * @description method to invoke service
    * @param serviceName Service Name
    * @return HttpResponse HttpResponse
    */
    public static HttpResponse callWebService(String serviceName, Map<String, Object> request) {
        HttpResponse response;
        System.debug('INIT: '+serviceName);
        //final iaso__GBL_integration_service__mdt service = [SELECT iaso__Mock_LTA__c, iaso__Http_Method__c FROM iaso__GBL_integration_service__mdt WHERE DeveloperName =:serviceName LIMIT 1];
        final iaso__GBL_integration_service__mdt service = iaso__GBL_integration_service__mdt.getInstance(serviceName);
        System.debug('service: '+service);
        if(Test.isRunningTest() || service.iaso__Retrieve_Mock_LTA__c) {
            //response.setHeader('Content-Type','application/json');
            //response.setBody(service.iaso__Mock_LTA__c);
            //response.setStatusCode(service.iaso__Http_Method__c == 'POST' ? 201 : 200);
            system.debug('Mock');
            response = getMock(serviceName);
        } else{
            system.debug('NO Mock - serviceName: ' + serviceName);
            system.debug('NO Mock - request: ' + request);
            //System.debug(''+iaso.GBL_Integration_GenericService.invoke(serviceName, request));
            response = iaso.GBL_Integration_GenericService.invoke(serviceName, request);
        }
        system.debug('NO Mock - response: ' + response);
        return response;
    }

    /**
    * @description Retrieves mock configuration from IASO metadata
    * @param serviceName: Name of the metadata record
    * @param statusCode: Status code to add to response (If needed)
    * @return HttpResponse HttpResponse
    */
    public static HttpResponse getMock(String serviceName) {
        final iaso__GBL_integration_service__mdt service = [SELECT iaso__Mock_LTA__c, iaso__Http_Method__c FROM iaso__GBL_integration_service__mdt WHERE DeveloperName =:serviceName LIMIT 1];
        final HttpResponse response = new HttpResponse();
        response.setHeader('Content-Type','application/json');
        response.setBody(service.iaso__Mock_LTA__c);
        response.setStatusCode(service.iaso__Http_Method__c == 'POST' ? 201 : 200);
        return response;
    }

    /**
    * @description Get data from services
    * @param recordId : Dynamic Pricing Id
    * @return dynamicPricing
    */
    @AuraEnabled
    public static DPMX_Dynamic_Pricing__c dynamicPricingSelector (String recordId) {
        DPMX_Dynamic_Pricing__c dynamicPricing = [SELECT Id,
                                                  		name,
                                                        Company_Name__c,
                                                        Company_Name__r.Name,
                                                        Company_Name__r.DES_AGGR_Sector__c,
                                                        Client_Information__c,
                                                        NumeroCliente__c,
                                                        Client__r.name,
                                                        Devices__c,
                                                        Simulation_Result__c,
                                                        Sim_Transaction_Debit_Own__c,
                                                        Sim_Billing_Debit_Own_Amount__c,
                                                        Sim_Billing_Debit_Own_Currency__c,
                                                        Sim_Tickets_Debit_Own_Amount__c,
                                                        Sim_Tickets_Debit_Own_Currency__c,
                                                        Sim_Percentage_Debit_MixOwn__c,
                                                        Sim_Transaction_Debit_ThirdParty__c,
                                                        Sim_Billing_Debit_ThirdParty_Amount__c,
                                                        Sim_Billing_Debit_ThirdParty_Currency__c,
                                                        Sim_Tickets_Debit_ThirdParty_Amount__c,
                                                        Sim_Tickets_Debit_ThirdParty_Currency__c,
                                                        Sim_Percentage_Debit_MixExternal__c,
                                                        Sim_Transaction_Credit_Own__c,
                                                        Sim_Billing_Credit_Own_Amount__c,
                                                        Sim_Billing_Credit_Own_Currency__c,
                                                        Sim_Tickets_Credit_Own_Amount__c,
                                                        Sim_Tickets_Credit_Own_Currency__c,
                                                        Sim_Percentage_Credit_MixOwn__c,
                                                        Sim_Transaction_Credit_ThirdParty__c,
                                                        Sim_Billing_Credit_ThirdParty_Amount__c,
                                                        Sim_Billing_Credit_ThirdParty_Currency__c,
                                                        Sim_Tickets_Credit_ThirdParty_Amount__c,
                                                        Sim_Tickets_Credit_ThirdParty_Currency__c,
                                                        Sim_Percentage_Credit_MixExternal__c,
                                                        Sim_Transaction_International__c,
                                                        Sim_Billing_International_Amount__c,
                                                        Sim_Billing_International_Currency__c,
                                                        Sim_Tickets_International_Amount__c,
                                                        Sim_Tickets_International_Currency__c,
                                                        Sim_Percentage_MixInternational__c,
                                                        Sim_Transaction_AcquirerAffiliation__c,
                                                        Sim_Billing_TotalAmount_Amount__c,
                                                        Sim_Billing_TotalAmount_Currency__c,
                                                        Sim_Tickets_TotalAmount_Amount__c,
                                                        Sim_Tickets_TotalAmount_Currency__c,
                                                        Sim_Percentage_Total__c,
                                                        Sim_Terminal_Id__c,
                                                        Sim_PinPadsInfo_PinPads__c,
                                                        Sim_Ecommerce__c,
                                                        Sim_DevicesInfo_Devices__c,
                                                        Sim_Fees_ExtraBilling_Amount__c,
                                                        Sim_Fees_ExtraBilling_Currency__c,
                                                        Sim_Fees_Cellnet_Amount__c,
                                                        Sim_Fees_Cellnet_Currency__c,
                                                        Sim_Fees_Billing_Amount__c,
                                                        Sim_Fees_Billing_Currency__c,
                                                        CustomAcquiredFeesCredit__c,
                                                        CustomAcquiredFeesDebit__c,
                                                        CustomAcquiredFeesInternational__c,
                                                        CustomSimulatedCredit__c,
                                                        CustomSimulatedDebit__c,
                                                        CustomSimulatedInternational__c,
                                                        flagBool__c,
                                                        familia__c,
                                                        familia_AcquiererCategories_Id__c,
                                                  		OwnerId,
                                                  		Owner.Name, 
                                                  		Owner.Email,
                                                        CreatedDate,
                                                        isCustom__c,
                                                        isCustomCliEdt__c,
                                                        isCustomDisEdt__c,
                                                        gastoTotal__c,
                                                        gastMit__c,
                                                        basisPoint__c,
                                                        isCustomDebitTsMax__c,
                                                        isCustomCreditTsMax__c,
                                                        isCustomInterTsMax__c,
                                                        isCustomDebitTs__c,
                                                        isCustomCreditTs__c,
                                                        isCustomIntTs__c,
                                                        isCustomAmountTs__c,
                                                        acquiererActy_JSON__c,
                                                        acquirerFees_JSON__c,
                                                        corporateRates_JSON__c,
                                                  		isLastMonthTab__c,
                                                  		isSimulationTab__c,
                                                  		sendConditionLst__c,
                                                  		sendSimulationLst__c,
                                                  		debitLastMonth__c,
                                                  		CreditLastMonth__c,
                                                  		IntLastMonth__c,
                                                        baiLastMonth__c,
                                                        RentabildiadLastMonth__c,
                                                  		debitSim__c,
                                                  		creditSim__c,
                                                  		interSim__c,
                                                        resultLastMonth__c,
                                                        resultSim__c,
                                                        CustomAcquiredFeesRent__c,
                                                        CustomAcquiredFeesBai__c,
                                                        CustomSimulatedRent__c,
                                                        CustomSimulatedBai__c,
                                                        CreatedById,
                                                        validate_JSON__c,
                                                        Sim_Fees_ExtraBilling_Checkbox__c,
                                                        Sim_Fees_Cellnet_Checkbox__c,
                                                        Sim_Fees_Billing_Checkbox__c,
                                                  		Product__c,
                                                        LastModifiedById,
                                                        TAMAccepted__c,
                                                        initDateFormalize__c,
                                                        revisionDateFormalize__c,
                                                        Stage__c,
                                                        posCheckbox__c,
                                                        pinPadsInfo_withoutPinPads__c,
                                                        Sim_Recurring_Charges__c,
                                                        withOutPinPadsCheckbox__c,
                                                        formalizeTab__c,
                                                        firstCheckTaxes__c,
                                                        firstCheckTaxesSimulated__c,
                                                        baiSim__c,
                                                        RentabildiadSim__c,
                                                        resultTasaEditSim__c,
                                                        resultTasaEdit__c,
                                                        folioGetStatus__c,
                                                        rateBreakEvenOutLimits__c
                                                    FROM DPMX_Dynamic_Pricing__c
                                                    WHERE Id = :recordId];
        return dynamicPricing;
    }

    /**
    * @description Get data from services
    * @param recordId : Dynamic Pricing Id
    * @return dynamicPricing
    */
    @AuraEnabled
    public static List<DPMX_Dynamic_Pricing__c> dynamicPricingDateSelector (String revisionDate) {
        List<DPMX_Dynamic_Pricing__c> dynamicPricingLst = new List<DPMX_Dynamic_Pricing__c>();
        System.debug(revisionDate);
        try{
            dynamicPricingLst = [SELECT Id,
                                    	name,
                                        revisionDateFormalize__c,
                                        CreatedById
                                    FROM DPMX_Dynamic_Pricing__c
                                    WHERE revisionDateFormalize__c = :revisionDate];
            
        }catch(Exception ex){
            System.debug('Nothing to send');
        }
        System.debug(dynamicPricingLst);
        return dynamicPricingLst;
    }

    /**
    * @description Get data from services
    * @param recordId : Dynamic Pricing Id
    * @return user
    */
    @AuraEnabled
    public static user userSelector (String userId) {
        user userOwner = new User(ID_User__c='');
        try{
            userOwner = [SELECT ID_User__c
                            FROM user
                            WHERE Id = :userId];
        }catch(Exception e){
            System.debug('Error--'+e.getMessage());
        } 
        
        return userOwner;
    }

    /**
    * @description Get data from services
    * @param recordId : Dynamic Pricing Id
    * @return user
    */
    @AuraEnabled
    public static user userSelectorByIdExtUser (String userId) {
        user userOwner = new User();
        try{
            userOwner = [SELECT id, Name
                            FROM user
                            WHERE ID_User__c = :userId];
        }catch(Exception e){
            System.debug('Error--'+e.getMessage());
        }
        return userOwner;
    }

    /**
    * @description Get data from services
    * @param recordId : Dynamic Pricing Id
    * @return DPMX_Formalize__c
    */
    @AuraEnabled
    public static DPMX_Formalize__c formalizeDPMXSelector (String recordId) {
        DPMX_Formalize__c formalize = new DPMX_Formalize__c();
            formalize = [SELECT Id,
            Name,
            Dynamic_Pricing__c,
            Dynamic_Pricing__r.Name,
            lkp_AssignedTo__c,
            lkp_AssignedTo__r.name,
            FirmOdtClient__c,
            FirmODTUser__c,
            NewODT__c,
            archRespaldo__c,
            ScanODT__c,
            debit__c,
            credit__c,
            international__c,
            CreatedById,
            ENU_BaseBAI__c,
            ENU_BaseRent__c,
            ENU_BaseCredit__c,
            ENU_BaseDebit__c,
            ENU_BaseIntern__c,
            rentabilidad__c,
            BAI__c,
            Status__c,
            Date_AuthorizerDate__c,
            deniedCheck__c,
            denyComments__c,
            deniedDate__c,
            formalizeAccepted__c,
            OdtCheck__c,
            resultado__c
        FROM DPMX_Formalize__c
        WHERE Dynamic_Pricing__c = :recordId];
               
        return formalize;
    }

    /**
    * @description Get data from services
    * @param recordId : formalize Id
    * @return DPMX_Formalize__c
    */
    @AuraEnabled
    public static DPMX_Formalize__c formalizeSelector (String recordId) {
        DPMX_Formalize__c formalize = new DPMX_Formalize__c();
        try{
            formalize = [SELECT Id,
            Name,
            Dynamic_Pricing__c,
            Dynamic_Pricing__r.Name,
            lkp_AssignedTo__c,
            lkp_AssignedTo__r.name,
            FirmOdtClient__c,
            FirmODTUser__c,
            NewODT__c,
            ScanODT__c,
            debit__c,
            credit__c,
            international__c,
            CreatedById,
            ENU_BaseBAI__c,
            ENU_BaseRent__c,
            ENU_BaseCredit__c,
            ENU_BaseDebit__c,
            ENU_BaseIntern__c,
            rentabilidad__c,
            BAI__c,
            Status__c,
            Date_AuthorizerDate__c,
            deniedCheck__c,
            denyComments__c,
            deniedDate__c,
            formalizeAccepted__c,
            OdtCheck__c,
            resultado__c,
            archRespaldo__c
        FROM DPMX_Formalize__c
        WHERE Id = :recordId];
        }catch(Exception e){
            System.debug('Error--'+e.getMessage());
        }                  
        return formalize;
    }

    /**
    * @description Get data from services
    * @return DPMX_Formalize__c
    */
    @AuraEnabled
    public static List<DPMX_Formalize__c> formalizeNameSelector () {
        List<DPMX_Formalize__c> formalizeLst = new List<DPMX_Formalize__c>();
        try{
            formalizeLst = [SELECT Name
            FROM DPMX_Formalize__c];
        }catch(Exception e){
            System.debug('Error--'+e.getMessage());
        }                  
        return formalizeLst;
    }

    /**
    * @description Get data from services
    * @return DPMX_authorization__c
    */
    @AuraEnabled
    public static DPMX_authorization__c AuthSelector (string autId) {
        DPMX_authorization__c auth = new DPMX_authorization__c();
        try{
            auth = [SELECT id,
                            Name,
                            OwnerId,
                            Comentario__c,
                            DATE_SolicitudeDate__c,
                            CreatedDate,
                            Date_AuthorizerDate__c,
                            LKP_Dynamic_Pricing__c,
                            lkp_AssignedTo__c, 
                            STR_AuthBai__c, 
                            STR_AuthCredit__c, 
                            STR_AuthDebit__c, 
                            STR_AuthInternational__c, 
                            STR_AuthProfitability__c, 
                            STR_AuthResult__c,
                            commentAuthorizer__c,
                            STR_AuthFamily__c, 
                            STR_BaseBai__c, 
                            STR_BaseCredit__c, 
                            STR_BaseDebit__c, 
                            STR_BaseInter__c, 
                            STR_BaseRenta__c, 
                            clientName__c, 
                            isGs__c,
                            CreatedById,
                            Status__c
            FROM DPMX_authorization__c
            WHERE id = :autId];
        }catch(Exception e){
            System.debug('Error--'+e.getMessage());
        }                  
        return auth;
    }

    public static Boolean returnAuthIsAccepted (string recordId, string debit, string credit, string international) {
        Boolean authIsAccepted = false;
        System.debug(debit);
        System.debug(credit);
        System.debug(international);
        
        list<DPMX_authorization__c> authLst = [SELECT Name, LKP_Dynamic_Pricing__r.Name, OwnerFullName__c, STR_AuthBai__c, 
        STR_AuthCredit__c, STR_AuthDebit__c, STR_AuthInternational__c, STR_AuthProfitability__c, STR_AuthResult__c, isGs__c, Status__c
        FROM DPMX_authorization__c
        WHERE LKP_Dynamic_Pricing__c =:recordId
        AND STR_AuthDebit__c =: debit.replace(',', '.')
        AND STR_AuthCredit__c =: credit.replace(',', '.')
        AND STR_AuthInternational__c =: international.replace(',', '.')
        AND Status__c = 'Aceptado'
        LIMIT 1
        ];
        if(authLst.size() > 0 ){
            authIsAccepted = true;
        }
        return authIsAccepted;
    }

    public static Boolean returnAuthIsCreated (string recordId, string debit, string credit, string international) {
        Boolean authIsAccepted = false;
        
        list<DPMX_authorization__c> authLst = [SELECT Name, LKP_Dynamic_Pricing__r.Name, OwnerFullName__c, STR_AuthBai__c, 
        STR_AuthCredit__c, STR_AuthDebit__c, STR_AuthInternational__c, STR_AuthProfitability__c, STR_AuthResult__c, isGs__c, Status__c
        FROM DPMX_authorization__c
        WHERE LKP_Dynamic_Pricing__c =:recordId
        AND STR_AuthDebit__c =: debit
        AND STR_AuthCredit__c =: credit
        AND STR_AuthInternational__c =: international
        AND Status__c = 'Pendiente'
        LIMIT 1
        ];
        if(authLst.size() > 0 ){
            authIsAccepted = true;
        }
        return authIsAccepted;
    }

    public static list<DPMX_authorization__c> returnAuthIfFormalize (string recordId, string debit, string credit, string international) {

        list<DPMX_authorization__c> authLst = [SELECT Name, LKP_Dynamic_Pricing__r.Name, OwnerFullName__c, STR_AuthBai__c, 
        STR_AuthCredit__c, STR_AuthDebit__c, STR_AuthInternational__c, STR_AuthProfitability__c, STR_AuthResult__c, isGs__c, Status__c
        FROM DPMX_authorization__c
        WHERE LKP_Dynamic_Pricing__c =:recordId
        AND STR_AuthDebit__c =: debit
        AND STR_AuthCredit__c =: credit
        AND STR_AuthInternational__c =: international
        AND Status__c = 'Aceptado'
        LIMIT 1
        ];
        return authLst;
    }

    public static EmailTemplate returnEmailTemp(string templateName){
        EmailTemplate emailTemp = [Select id, Subject, Body, HtmlValue From EmailTemplate Where DeveloperName =:templateName];
        return emailTemp;
    }

    public static DPMX_Formalize__c returnIdFormalize(string recordId){
        DPMX_Formalize__c formalize = [Select id From DPMX_Formalize__c Where Dynamic_Pricing__c =:recordId];
        return formalize;
    }

    public static string returnCurrency (decimal value) {
        string strReturn = value.setscale(2) + ' MXN';
        return strReturn;
    }

    public static string returnIsPercent (decimal value) {
        string strReturn = value.setscale(2) + '%';
        return strReturn;
    }

    public static string returnIsPercent (string value) {
        value = value + '%';
        return value;
    }

    public static string returnIsPercent2 (decimal value) {
        string strReturn = ((value.setscale(2))*100) + '%';
        return strReturn;
    }

    /**
    * @description Get users
    * @param permisionSet : PermisionSet Name
    * @return user
    */
    @AuraEnabled
    public static List<PermissionSetAssignment> userSelectorPermisionSet (String permisionSetName) {
        List<PermissionSetAssignment> usersToODTLst = [SELECT Id, PermissionSetId, PermissionSet.Name, AssigneeId, Assignee.Name, Assignee.Email
                            FROM PermissionSetAssignment
                            WHERE PermissionSet.Name = :permisionSetName];
        return usersToODTLst;
    }
    
    /**
    * @description Get DPMX_UpdtRatesxDynPric__c
    * @param id dynamic prrcing : 
    * @return DPMX_UpdtRatesxDynPric__c
    */
    @AuraEnabled
    public static List<DPMX_UpdtRatesxDynPric__c> DPMX_UpdtRatesxDynPricSelector (String recordId, string folioUpdateRates) {
        List<DPMX_UpdtRatesxDynPric__c> permissionSetAssignmentLst = new List<DPMX_UpdtRatesxDynPric__c>();
        try{
            permissionSetAssignmentLst = [SELECT Id, DPMX__c, folioUpdateRates__c, initDateFormalize__c, revisionDateFormalize__c, CreatedDate
                            FROM DPMX_UpdtRatesxDynPric__c
                            WHERE DPMX__c = :recordId
                            AND folioUpdateRates__c = :folioUpdateRates];
        }catch(Exception ex){
            system.debug(ex);
        }
        System.debug(permissionSetAssignmentLst);
        return permissionSetAssignmentLst;
    }

    /**
    * @description Get DPMX_UpdtRatesxDynPric__c
    * @param id dynamic prrcing : 
    * @return DPMX_UpdtRatesxDynPric__c
    */
    @AuraEnabled
    public static List<DPMX_UpdtRatesxDynPric__c> DPMX_UpdtRatesxAllDynPricSelector (string folioUpdateRates) {
        List<DPMX_UpdtRatesxDynPric__c> permissionSetAssignmentLst = new List<DPMX_UpdtRatesxDynPric__c>();
        try{
            permissionSetAssignmentLst = [SELECT Id, DPMX__c, folioUpdateRates__c, initDateFormalize__c, revisionDateFormalize__c, CreatedDate
                            FROM DPMX_UpdtRatesxDynPric__c
                            WHERE folioUpdateRates__c = :folioUpdateRates];
        }catch(Exception ex){
            system.debug(ex);
        }
        System.debug(permissionSetAssignmentLst);
        return permissionSetAssignmentLst;
    }

    /**
    * @description Get Local_Client id
    * @param name dynamic prrcing : 
    * @return Local_Client__c
    */
    @AuraEnabled
    public static Local_Client__c Local_ClientSelector (String dpmxComapnyName) {
        Local_Client__c localClient = new Local_Client__c();
        try{
            localClient = [SELECT Id, unique_id__c FROM Local_Client__c WHERE Cib_Client__c =:dpmxComapnyName LIMIT 1];
        }catch(Exception ex){
            system.debug(ex);
        }
        return localClient;
    }

}