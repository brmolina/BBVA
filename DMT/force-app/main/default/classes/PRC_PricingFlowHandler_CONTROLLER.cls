/**
* @author       JSS
* @date         02/06/2020
* @description  Controlador del componente lighning PRC_PricingFlowHandler
* @Revision
*/
@SuppressWarnings('sf:ExcessiveMethodLength,sf:NPathComplexity,sf:ConfusingTernary')
public with sharing class PRC_PricingFlowHandler_CONTROLLER {
    /**
    * @author       JCT
    * @description  Clases para controlar el mensaje de error que lanzamos en las validaciones
    */
    //public virtual class BaseException extends Exception {}
    //public class CustomException extends BaseException {}

    /**
    * @author       JCT
    * @description  Método que devuelve el estado del formulario en el flujo de Pricing
    */
    @AuraEnabled
    public static String getstate(String opportunityid) {
        String result;
        System.debug('>>>>>>>> ' + opportunityid);
        final Opportunity opp = [select Id,(select Id, gf_pricing_risk_product_name__c from Pricing_Details__r) from Opportunity where Id = :opportunityid][0];
        if(opp.Pricing_Details__r.size() == 0) {
            //product selector
            result = 'Product Selector';
        } else { //siempre debería ser = 1
            //priceform
            result = 'Price Form';
        }
        return result;
    }


    /**
    * @author       JCT
    * @description  Método que realiza la llamada al servicio calculo de matriz de precios
    */
    @AuraEnabled
    public static PRC_PFS_Response callWS(String opportunityid) {
        final PRCPricingUtils pricingLogic = PRCPricingUtils.getInstance();
        final list<Integer> STATUS_CODE_OK_LIST = pricingLogic.getResponseStatusCodeOKList();
        PRC_PFS_Response respObject = new PRC_PFS_Response();

        // mock //
        //String reqJson = '{"engineWorksWith":{"valueDate":"2020-02-25T12:25:23.286Z","participant":{"totalSells":{"currenc_y":null,"amount":0},"rating":null,"id":null,"groupType":null,"economicGroupRating":null},"operations":[{"userLossGivenDefault":null,"underlyingOperationsNumber":0,"taxRate":null,"startDate":null,"currenc_y":null,"rating":{"shortScaleValue":null,"longScaleValue":null},"productType":{"id":"Loans"},"productModality":"","paymentType":null,"order":0,"mitigants":[{"mitigantType":null,"maturityType":null,"maturityDate":null,"isInLocalCurrency":null,"isCountryRiskCoverage":null,"guarantorRating":null,"countryRisk":null,"commercialRisk":null,"belongsSameGroup":null}],"maturityDate":null,"isFundingCalculatedByTerm":false,"funding":{"userFunding":{"onBalance":null,"offBalance":null},"fundingType":null},"financingType":null,"fees":[{"value":0,"id":"id"}],"costToIncome":null,"booking":null,"amortization":{"paymentFrequency":null,"notional":{"onBalance":null,"offBalance":null},"margin":{"onBalance":null,"offBalance":null},"installments":[],"amortizationType":null}}],"matrices":[{"id":"MARGIN","axis":[{"numberOfEntries":5,"id":"MARGIN"},{"numberOfEntries":5,"id":"FEES"}]}],"investmentBankingProposalId":"investmentBankingProposalId","engineWorksWithType":"OPPORTUNITY","crossSellAmounts":[{"currenc_y":"EUR","id":"x","amount":0}]}}"}';
        //Map<String,String> jsonInputMap = new Map<String,String>();
        //jsonInputMap.put('whole-request',reqJson.replaceAll('currenc_y','currency'));
        /////////
        //

        try {
            String reqString = getSerializedRequestBody(opportunityid);
            Map<String,String> jsonInputMap = new Map<String,String>();
            jsonInputMap.put('whole-request',reqString);
            jsonInputMap.put('Accept','application/json');
            HttpResponse response = ( Test.isRunningTest() ? PRC_MockHttpResponseGenerator.respond_WsPrcCalculateMatrix() : iaso.GBL_Integration_GenericService.invoke('PrcCalculateMatrix',jsonInputMap) );
            if (STATUS_CODE_OK_LIST.contains(response.getStatusCode())) {
                System.debug('>>>>>>>>>>>> El WS codeResponse: ' + response.getStatusCode() + ' --- Mensaje Completo: ' + response.toString());
                String respuesta;respuesta = response.getBody();

                respObject = (PRC_PFS_Response) Json.deserialize(respuesta, PRC_PFS_Response.class);

            } else {
                final String respDescription = pricingLogic.getResponseWarningDescription(response.getBody());
                System.debug('>>>>>>>>>>>> El WS respondió un error: ' + response.getStatusCode() + ' --- Mensaje Completo: ' + response.toString() + '\r\n >>>>>>>>> responsewarningdescription: '+ respDescription);

                //throw new CustomException(Label.PRC_MatrixServiceConnectError + response.toString());
                throw new CalloutException(Label.PRC_MatrixServiceConnectError + ' ' + response.getStatus() +  '\n' + respDescription);
            }

        } catch (Exception e) {
            respObject.wsErrorMsg = e.getMessage();
        }

        return respObject;
    }


    /**
    * @author       JSS
    * @description  Método que elimina la info del objeto de salesforce de amortizaciones PRC_Price_Amortization_Data__c
    */
    @AuraEnabled
    public static void deleteAmortizationData(String opportunityId) {
        System.debug('>>>>>>>> deleteAmortizationData: ' + opportunityid);
        final list<PRC_Price_Amortization_Data__c> amortToDelete = [select Id from PRC_Price_Amortization_Data__c where PRC_Opportunity__c = :opportunityid];
        if(!amortToDelete.isEmpty()) {
            delete amortToDelete;
        }

    }



    /* -----------------------
    ------ PRIVATE METHODS ---
     -----------------------*/

     private static String getSerializedRequestBody(String opportunityid) {
       final PRCPricingUtils pricingLogic = PRCPricingUtils.getInstance();
       PRC_Pricing_Detail__c pricingDetails = pricingLogic.getPricingDetailsDataFromOpp(opportunityid);
        final PRC_PFS_Request request = new PRC_PFS_Request();
         		Map<String, PRC_Combo_Validation__mdt> combosVal =new Map<String, PRC_Combo_Validation__mdt>();
         combosVal= pricingLogic.getCombosVal();
        final String product = combosVal.get(pricingDetails.business_area_desc__c).Product__c;
         final String apikey = combosVal.get(pricingDetails.business_area_desc__c).API_key__c;
         String operationarating ;
         if( combosVal.get(pricingDetails.gf_ope_agency_rating_type__c)!=null) {
            operationarating = combosVal.get(pricingDetails.gf_ope_agency_rating_type__c).DeveloperName;
         }
         request.engineWorksWith.currenc_y = 'EUR';
        request.engineWorksWith.participant.economicGroupRating = pricingDetails.gf_cust_group_rating_type__c;
        request.engineWorksWith.participant.rating = pricingDetails.rating_scale_type__c;
        request.engineWorksWith.participant.Id = pricingDetails.PRC_Opportunity__r.Account.SER_CClient__c != null ? pricingDetails.PRC_Opportunity__r.Account.SER_CClient__c : pricingDetails.PRC_Opportunity__r.AccountId ;
        request.engineWorksWith.participant.sector.id = pricingDetails.economic_activity_sector_desc__c;
        request.engineWorksWith.originationBranch = new PRC_PFS_Request.originationBranch((String) pricingDetails.branch_name__c);

        request.engineWorksWith.participant.grouptype = pricingDetails.gf_scope_type__c;

        request.engineWorksWith.participant.country = new PRC_PFS_Participant.country(pricingDetails.transaction_country_name__c);


         if((pricingDetails.agency_rating_value_type__c == null) == false) {
            request.engineWorksWith.operations[0].rating.shortScaleValue = pricingDetails.agency_rating_value_type__c;
        }
        request.engineWorksWith.participant.totalSells.currenc_y = pricingDetails.opportunity_currency_id__c;
        request.engineWorksWith.operations[0].productType.id = pricingDetails.gf_pricing_risk_product_id__c;
        request.engineWorksWith.operations[0].productModality = 'PRODUCT';
        request.engineWorksWith.operations[0].booking = pricingDetails.gf_ope_booking_entity_name__c;
        request.engineWorksWith.operations[0].financingType = pricingDetails.gf_financing_type_name__c;
        request.engineWorksWith.valueDate = Datetime.now();
         request.engineWorksWith.operations[0].businessArea= new PRC_PFS_Operation.businessArea(apikey, product);
        request.engineWorksWith.operations[0].IsRegulationCapitalRequired = pricingDetails.gf_ope_cpt_25_pct_red_ind_type__c;
        request.engineWorksWith.operations[0].startDate = pricingDetails.opportunity_start_date__c;
        request.engineWorksWith.operations[0].maturityDate = pricingDetails.current_expiry_date__c;
         if(operationarating=='GROUP') {
            request.engineWorksWith.operations[0].ratingModalityType= operationarating;
             request.engineWorksWith.operations[0].rating.longScaleValue = pricingDetails.gf_cust_group_rating_type__c;
         } else if(operationarating=='CLIENT') {
         	request.engineWorksWith.operations[0].ratingModalityType= operationarating;
             request.engineWorksWith.operations[0].rating.longScaleValue = pricingDetails.rating_scale_type__c;
         } else {
            request.engineWorksWith.operations[0].ratingModalityType= 'DEAL';
            request.engineWorksWith.operations[0].rating.longScaleValue = pricingDetails.gf_ope_agency_rating_type__c;
         }

        request.engineWorksWith.operations[0].mitigants = new List<PRC_PFS_Operation_Mitigant>();

        request.engineWorksWith.operations[0].funding.fundingType  = pricingDetails.gf_funding_curve_type__c;///**************Cambiar**********************
        request.engineWorksWith.operations[0].userLossGivenDefault = (pricingDetails.lgd_per__c == null) == false?pricingDetails.lgd_per__c : null;
        if(pricingDetails.gf_funding_curve_type__c == 'BBVA SA') {
            request.engineWorksWith.operations[0].funding.userFunding.onBalance = 0;
            request.engineWorksWith.operations[0].funding.userfunding.offBalance = 0;
        } else {
            request.engineWorksWith.operations[0].funding.userFunding.onBalance = pricingDetails.gf_on_balance_funding_per__c != null? pricingDetails.gf_on_balance_funding_per__c:0;
            request.engineWorksWith.operations[0].funding.userfunding.offBalance = pricingDetails.gf_off_balance_funding_per__c != null? pricingDetails.gf_off_balance_funding_per__c:0;
        }

        request.engineWorksWith.operations[0].amortization.amortizationType = pricingDetails.amortization_desc__c;///**************Cambiar**********************

        if(pricingDetails.amortization_desc__c == 'USER_DEFINED') {
           PRC_PriceForm_HELPER.setUserDefinedAmortization(request,opportunityid);
        }
        request.engineWorksWith.operations[0].paymentType = pricingDetails.payment_type__c;///**************Cambiar**********************
       // request.engineWorksWith.operations[0].paymentType = 'FIXED';///**************Cambiar**********************
        request.engineWorksWith.operations[0].amortization.paymentFrequency = pricingDetails.frequency_type__c !=null ? pricingDetails.frequency_type__c: null;
        request.engineWorksWith.operations[0].currenc_y = pricingDetails.currency_id__c;
        system.debug('gf_on_bal_mrgn_gen_amount__c : '+pricingDetails.Id);
        system.debug('gf_on_bal_mrgn_gen_amount__c : '+pricingDetails.gf_on_bal_mrgn_gen_amount__c);
         system.debug('gf_off_bal_mrgn_gen_amount__c : '+pricingDetails.gf_off_bal_mrgn_gen_amount__c);
         system.debug('gf_ope_on_balance_margin_per__c : '+pricingDetails.gf_ope_on_balance_margin_per__c);
         system.debug('gf_ope_off_balance_margin_per__c : '+pricingDetails.gf_ope_off_balance_margin_per__c);
        request.engineWorksWith.operations[0].amortization.notional.onBalance = pricingDetails.gf_on_bal_mrgn_gen_amount__c != null?pricingDetails.gf_on_bal_mrgn_gen_amount__c:0;
        request.engineWorksWith.operations[0].amortization.notional.offBalance = pricingDetails.gf_off_bal_mrgn_gen_amount__c != null?pricingDetails.gf_off_bal_mrgn_gen_amount__c:0;
        request.engineWorksWith.operations[0].amortization.margin.onBalance = pricingDetails.gf_ope_on_balance_margin_per__c != null? pricingDetails.gf_ope_on_balance_margin_per__c : 0;
        request.engineWorksWith.operations[0].amortization.margin.offBalance = pricingDetails.gf_ope_off_balance_margin_per__c != null? pricingDetails.gf_ope_off_balance_margin_per__c : 0;
        request.engineWorksWith.operations[0].amortization.fee.accrual = (pricingDetails.gf_accrual_per__c == null) == false? pricingDetails.gf_accrual_per__c : 0;
        request.engineWorksWith.operations[0].amortization.fee.nonAccrual = (pricingDetails.gf_non_accrual_comission_per__c == null) == false? pricingDetails.gf_non_accrual_comission_per__c : 0;
        request.engineWorksWith.operations[0].countryRisk        =pricingDetails.transaction_country_name__c;
        request.engineWorksWith.operations[0].taxRate = pricingDetails.gf_tax_rate_per__c != null?pricingDetails.gf_tax_rate_per__c:0;
        request.engineWorksWith.operations[0].costToIncome = pricingDetails.gf_cost_income_ratio_per__c != null? pricingDetails.gf_cost_income_ratio_per__c: 0;
        request.engineWorksWith.operations[0].isFundingCalculatedByTerm= Boolean.valueOf(pricingDetails.gf_operation_term_number__c);///**************Cambiar**********************
        if(request.engineWorksWith.valueDate >= request.engineWorksWith.operations[0].startDate.addDays(7)) {
           throw new CalloutException(Label.PRC_MatrixServiceDateValidationError);
           //throw new CustomException(Label.PRC_MatrixServiceDateValidationError);
        }
        //ACCRUAL FEES
        /* Obsoleto en V3.0   PRC_PriceForm_HELPER.setFees(request,pricingDetails); */
        PRC_PriceForm_HELPER.setMatrix(request);
        //Mitigantes
        List<PRC_PFS_Operation_Mitigant> mitigantes = completeMitigants(pricingDetails.Id);
        if (mitigantes != null && !mitigantes.isEmpty()) {
          request.engineWorksWith.operations[0].mitigants = mitigantes;
        }

        System.debug('>>>>>>>>>>> request object: ' + request);
         CIB_Log__c log = new CIB_Log__c();
        log.CIB_ErrorMessage__c= JSON.serialize(request).replaceAll('currenc_y','currency');
         System.debug('>>>>>>>>>>>>> Request serializada: ' + JSON.serialize(request).replaceAll('currenc_y','currency'));
         final String serializedRequest = log.CIB_ErrorMessage__c;
         for (Integer i = 0; i < serializedRequest.length(); i=i+200) {
             final Integer iEffectiveEnd = (i+200 > (serializedRequest.length()-1) ? serializedRequest.length()-1 : i+200);
             System.debug(serializedRequest.substring(i,iEffectiveEnd));
         }

        log.CIB_Subject__c = 'JCT TEST 22/03/2020';
        //insert log;
        //return JSON.serialize(request).replaceAll('currenc_y','currency');

		return JSON.serialize(request,true);
        //return '{     "engineWorksWith": {         "engineWorksWithType": "OPPORTUNITY",         "valueDate": "2019-01-01T16:41:41.090Z",         "matrices": [             {                 "axis": [                     {                         "id": "MARGIN",                         "numberOfEntries": 5                     },                     {                         "id": "TERM",                         "numberOfEntries": 5                     }                 ]             },             {                 "axis": [                     {                         "id": "MARGIN",                         "numberOfEntries": 5                     },                     {                         "id": "FEES",                         "numberOfEntries": 5                     }                 ]             }         ],         "crossSellAmounts": [             {                 "id": "CROSS_SELL_AMOUNT",                 "amount": 50000,                 "currency": "EUR"             }         ],         "participant": {             "id": "9385u84",             "groupType": "CORPORATE",             "rating": "BBB+2",             "economicGroupRating": "BBB+2",             "totalSells": {                 "amount": 120000,                 "currency": "EUR"             }         },         "operations": [             {                 "startDate": "2019-07-01T16:41:41.090Z",                 "maturityDate": "2021-11-01T16:41:41.090Z",                 "rating": {                     "shortScaleValue": "A-2",                     "longScaleValue": "BBB+"                 },                 "paymentType": "EURIBOR",                 "isFundingCalculatedByTerm": true,                 "fees": [                     {                         "id": "ACCRUAL",                         "value": 0                     },                     {                         "id": "NON_ACCRUAL",                         "value": 10                     }                 ],                 "amortization": {                     "amortizationType": "BULLET",                     "paymentFrequency": "ANNUAL",                     "notional": {                         "onBalance": 100,                         "offBalance": 67                     },                     "margin": {                         "onBalance": 75,                         "offBalance": 20                     }                 },                 "taxRate": 30,                 "costToIncome": 31.78,                 "productType": {                     "id": "LOAN"                 },                 "productModality": "PRODUCT",                 "order": 1,                 "underlyingOperationsNumber": 0,                 "booking": "BBVA S.A SPAIN",                 "financingType": "STANDARD_FUNDING",                 "userLossGivenDefault": 0,                 "mitigants": [                     {                         "mitigantType": "EQUITY",                         "commercialRisk": 1,                         "countryRisk": 1,                         "maturityType": "DEAL_MATURITY",                         "maturityDate": "2019-01-01T16:41:41.090Z",                         "isCountryRiskCoverage": true,                         "belongsSameGroup": false,                         "guarantorRating": {                             "longScaleValue": "B2"                         },                         "isInLocalCurrency": true                     }                 ],                 "currency": "EUR",                 "funding": {                     "fundingType": "BBVA_FUNDING"                 },                 "ratingModalityType": "GROUP"             }         ]     } }';
     }

    /**
    * @description
    * @author Global Desktop | 03-04-2021
    * @param mitiType
    * @return String
    **/
    private static String convertMitigantType(String mitiType) {
      String tipo = '';
      if(mitiType.contains('_BANKING')) {
        tipo = 'BANKING';
      } else if (mitiType.contains('_ECA')) {
        tipo = 'ECA';
      } else if (mitiType.contains('_PETROLEUM')) {
        tipo = 'PETROLEUM';
      } else {
        tipo = mitiType;
      }
      return tipo;
    }

    /**
    * @description
    * @author Global Desktop | 03-04-2021
    * @param pickString
    * @return Boolean
    **/
    private static Boolean pickConvert(String pickString) {
      Boolean pickBool = false;
      if(pickString == 'Yes') {
        pickBool = true;
      }
      return pickBool;
    }

    private static List<PRC_PFS_Operation_Mitigant> completeMitigants (String pricingDetailsId) {
      final List<PRC_PFS_Operation_Mitigant> listServMitigants = new List<PRC_PFS_Operation_Mitigant> ();
      final List<PRC_Mitigant__c> listaMitigantes = PRC_PricingDetails_CONTROLLER.getMitigants(pricingDetailsId);
      if(listaMitigantes != null && !listaMitigantes.isEmpty()) {
        for(PRC_Mitigant__c miti : listaMitigantes) {
          final PRC_PFS_Operation_Mitigant servMiti = new PRC_PFS_Operation_Mitigant();
          servMiti.guarantor = new PRC_PFS_Operation_Mitigant.guarantor();
          servMiti.belongsSameGroup = pickConvert(miti.gf_gtr_debtor_group_ind_type__c);
          servMiti.commercialRisk = miti.gf_mit_rk_rqst_warranty_per__c;
          servMiti.countryRisk = miti.gf_cty_rqst_wrrnty_risk_per__c;
          servMiti.description = miti.gf_mitigating_comment_desc__c;
          servMiti.guarantor.id = miti.gf_providing_warranty_ent_id__c;
          servMiti.guarantor.rating.longScaleValue = miti.gf_warranty_ptt_rating_type__c;
          servMiti.guarantor.rating.shortScaleValue = miti.gf_external_rating_agncy_type__c;
          servMiti.isCountryRiskCoverage = pickConvert(miti.gf_cvr_rk_cty_wrrnty_ind_type__c);
          servMiti.isEuropeanExportCreditAgency = pickConvert(miti.gf_exprt_cr_eur_agncy_ind_type__c);
          servMiti.isInLocalCurrency = !pickConvert(miti.gf_oppy_mit_dif_ccy_ind_type__c);
          servMiti.maturityDate = miti.gf_end_guarantee_date__c;
          servMiti.maturityType = miti.gf_expir_wrrnty_operation_name__c;
          servMiti.mitigantType = convertMitigantType(miti.gf_subwarranty_name__c);
          listServMitigants.add(servMiti);
        }
      }
      return listServMitigants;
    }
}