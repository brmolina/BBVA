/**
* @File Name          : Arc_Gen_CallableFromSp2.cls
* @Description        : callable class called from corporate classes
* @Author             : alberto.martinez.carrero.tech@bbva.com
* @Group              : ARCE Team
* @Last Modified By   : alberto.martinez.carrero.tech@bbva.com
* @Last Modified On   : 04/06/2024
* @Changes
*========================================================================================
* Ver         Date                     Author                 Modification
*========================================================================================
* 1.0         04/06/2024    alberto.martinez.carrero.tech@bbva.com     Initial Version
**/
@SuppressWarnings('PMD.AvoidGlobalModifier')
global with sharing class Arc_Gen_CallableFromSp2 implements Callable {
    /** @description ahaId Literal */
    private final static string AHAID_LIT = 'ahaId';
    /** @description ratingType Literal */
    private static final String RATINGTYPE_LIT = 'ratingType';
    /**
    * @description Utilizes the callable interface to call another methods of actual class.
    * @author aleksandar.dinkov.contractor@bbva.com | 02-02-2024
    * @param String action
    * @param Map<String,Object> args
    * @return Object
    **/
    @SuppressWarnings('sf:DUDataflowAnomalyAnalysis')
    global Object call(String action, Map<String, Object> args) {
        Object result;
        switch on action {
            when 'buildFFSS' {
                result = callBuildFFSS(args);
            }
            when 'validateFSForRating' {
                result = callValidateFSForRating(args);
            }
            when 'getFfssValidType' {
                result = callGetFfssValidType(args);
            }
            when 'callSetAnalysis2021RTC' {
                result = callSetAnalysis2021RTC(args);
            }
            when 'createModifier2021RTC' {
                result = createModifier2021RTC(args);
            }
            when 'callPersistence2021RTC' {
                result = callPersistence2021RTC(args);
            }
            when 'callEngineFFSS2021RTC' {
                result = callEngineFFSS2021RTC(args);
            }
            when 'callEngineFFSSDet2021RTC' {
                result = callEngineFFSSDet2021RTC(args);
            }
            when 'callSalesEngine' {
                result = callSalesEngine(args);
            }
            when 'callPersistRating2021RTC' {
                result = callPersistRating2021RTC(args);
            }
            when 'fetchAnalysisRTC' {
                result = callFetchAnalysisRTC(args);
            }
            when 'callCloneARCE' {
                result = callCloneARCE(args);
            }
            when 'callCloneFFSS' {
                result = callCloneFFSS(args);
            }
            when 'callNewFFSSWAhas' {
                result = callNewFFSSWAhas(args);
            }
            when 'getRatiosResponse' {
                result = getRatiosResponse(args);
            }
            when 'processRatiosResponse' {
                result = processRatiosResponse(args);
            }
            when 'updateArceName' {
                result = updateArceName(args);
            }
            when else {
                throw new ExtensionMalformedCallException('Method not implemented!');
            }
        }
        return result;
    }
    /**
    * @description ExtensionMalformedCallException
    **/
    global class ExtensionMalformedCallException extends Exception {}
    /**
    *-------------------------------------------------------------------------------
    * @description get map info that will be used to call buildFFSS method.
    *--------------------------------------------------------------------------------
    * @author  alberto.martinez.carrero.tech@bbva.com
    * @date    04/06/2024
    * @param Map<String, Object> mapInfo
    * @return Object
    */
    private Object callBuildFFSS(Map<String, Object> mapInfo) {
        final String callFrom = (String) mapInfo.get('callFrom');
        switch on callFrom {
            when 'proposal' {
                final Map<String, Object> servResp = (Map<String, Object>) mapInfo.get('servResp');
                final Integer auditorOp = (Integer) mapInfo.get('auditorOp');
                return Arc_Gen_Balance_Tables_helper.buildFFSS(null, servResp, auditorOp, null, null, null);
            }
            when else {
                throw new ExtensionMalformedCallException('Error: invalid callFrom method');
            }
        }
    }
    /**
    *------------------------------------------------------------------------------------------------------------------------------
    * @description callValidateFSForRating method call validateFSForRating method of Arc_Gen_Balance_Tables_helper class
    *-------------------------------------------------------------------------------------------------------------------------------
    * @author  alberto.martinez.carrero.tech@bbva.com
    * @date    04/06/2024
    * @param Map<String, Object> mapInfo
    * @return Object
    */
    private Object callValidateFSForRating(Map<String, Object> mapInfo) {
        final arce__Financial_Statements__c ffss = (arce__Financial_Statements__c) mapInfo.get('ffss');
        return Arc_Gen_Balance_Tables_helper.validateFSForRating(ffss);
    }
    /**
    *------------------------------------------------------------------------------------------------------------------------------
    * @description callGetFfssValidType method call getFfssValidType method of Arc_Gen_Balance_Tables_helper class
    *-------------------------------------------------------------------------------------------------------------------------------
    * @author  alberto.martinez.carrero.tech@bbva.com
    * @date    04/06/2024
    * @param Map<String, Object> mapInfo
    * @return Object
    */
    private Object callGetFfssValidType(Map<String, Object> mapInfo) {
        final Boolean ffssValidRating = (Boolean) mapInfo.get('ffssValidForRating');
        return Arc_Gen_Balance_Tables_helper.getFfssValidType(ffssValidRating);
    }
    /**
    *------------------------------------------------------------------------------------------------------------------------------
    * @description Call Arc_Gen_RatingAsIndepProcess_controller.setAnalysis method
    *-------------------------------------------------------------------------------------------------------------------------------
    * @author  francisco.munoz.torres.tech@bbva.com
    * @date    23/07/2025
    * @param Map<String, Object> mapInfo
    * @return Object
    */
    private Object callSetAnalysis2021RTC(Map<String, Object> mapInfo) {
        final Map<String,String> data = new Map<String,String>();
        data.put('isorphan', 'false');
        data.put('orphanNumber', '');
        data.put('accounts', '[]');
        data.put('analysisType', '4');
        data.put('actualClient', (String) mapInfo.get('accNumber'));
        data.put('typeSelected', 'sp2Analysis');
        data.put('isCorp', 'true');
        return Arc_Gen_RatingAsIndepProcess_controller.setAnalysis(data);
    }

    /**
    *------------------------------------------------------------------------------------------------------------------------------
    * @description Call Arc_Gen_RatingAsIndepProcess_controller.createModifier method
    *-------------------------------------------------------------------------------------------------------------------------------
    * @author  francisco.munoz.torres.tech@bbva.com
    * @date    23/07/2025
    * @param Map<String, Object> mapInfo
    * @return Object
    */
    private Object createModifier2021RTC(Map<String, Object> mapInfo) {
        Arc_Gen_RatingAsIndepProcess_controller.createModifier(mapInfo.get(AHAID_LIT).ToString());
        return null;
    }

    /**
    *------------------------------------------------------------------------------------------------------------------------------
    * @description Call Arc_Gen_RatingAsIndepProcess_controller.callPersistence method
    *-------------------------------------------------------------------------------------------------------------------------------
    * @author  francisco.munoz.torres.tech@bbva.com
    * @date    23/07/2025
    * @param Map<String, Object> mapInfo
    * @return Object
    */
    private Object callPersistence2021RTC(Map<String, Object> mapInfo) {
        return Arc_Gen_RatingAsIndepProcess_controller.callPersistence(
            mapInfo.get('analysisId').ToString(),
            mapInfo.get('clientId').ToString());
    }

    /**
    *------------------------------------------------------------------------------------------------------------------------------
    * @description Call Arc_Gen_RatingAsIndepProcess_controller.callEngineFinancialState method
    *-------------------------------------------------------------------------------------------------------------------------------
    * @author  francisco.munoz.torres.tech@bbva.com
    * @date    23/07/2025
    * @param Map<String, Object> mapInfo
    * @return Object
    */
    private Object callEngineFFSS2021RTC(Map<String, Object> mapInfo) {
        return JSON.serialize(Arc_Gen_RatingAsIndepProcess_controller.callEngineFinancialState(
            mapInfo.get('recordId').ToString(),
            (List<arce__Financial_Statements__c>) mapInfo.get('updatedEEFF'),
            (List<String>) mapInfo.get('financialIdList'),
            (Boolean) mapInfo.get('isRAIP'),
            (Boolean) mapInfo.get('isFinancialRAIP'),
            mapInfo.get('ratingToolSelect')?.ToString()
        ));
    }

    /**
    *------------------------------------------------------------------------------------------------------------------------------
    * @description Call Arc_Gen_RatingAsIndepProcess_controller.consultFSdetails method
    *-------------------------------------------------------------------------------------------------------------------------------
    * @author  francisco.munoz.torres.tech@bbva.com
    * @date    23/07/2025
    * @param Map<String, Object> mapInfo
    * @return Object
    */
    private Object callEngineFFSSDet2021RTC(Map<String, Object> mapInfo) {
        return JSON.serialize(Arc_Gen_RatingAsIndepProcess_controller.consultFSdetails(
            mapInfo.get(AHAID_LIT).ToString(),
            mapInfo.get('ffssId').ToString()
        ));
    }

    /**
    *------------------------------------------------------------------------------------------------------------------------------
    * @description Call Arc_Gen_RatingAsIndepProcess_controller.consultFSdetails method
    *-------------------------------------------------------------------------------------------------------------------------------
    * @author  francisco.munoz.torres.tech@bbva.com
    * @date    23/07/2025
    * @param Map<String, Object> mapInfo
    * @return Object
    */
    private Object callSalesEngine(Map<String, Object> mapInfo) {
        final Boolean isSalesActive = Arc_Gen_ConfigUtils.isSalesEngineConfig();
        final Map<String, Object> response = new Map<String, Object>();
        if(isSalesActive) {
            final Arc_gen_Sales_Service.ResponseWrapper responseWrapper = Arc_Gen_RatingAsIndepProcess_controller.getSalesEngine(
                mapInfo.get(AHAID_LIT).ToString(),
                mapInfo.get(RATINGTYPE_LIT).ToString()
            );
            response.put('success', responseWrapper.success);
            response.put('message', responseWrapper.message);
            response.put('calculationResult', responseWrapper.calculationResult);
            response.put('code', responseWrapper.code);
        } else {
            response.put('success', 'true');
            response.put('message', 'Deactive');
            response.put('calculationResult', '');
        }

        return JSON.serialize(response);
    }

    /**
    *------------------------------------------------------------------------------------------------------------------------------
    * @description Call Arc_Gen_RatingAsIndepProcess_controller.persistRatingModel method
    *-------------------------------------------------------------------------------------------------------------------------------
    * @author  francisco.munoz.torres.tech@bbva.com
    * @date    29/07/2025
    * @param Map<String, Object> mapInfo
    * @return Object
    */
    private Object callPersistRating2021RTC(Map<String, Object> mapInfo) {
        return Arc_Gen_RatingAsIndepProcess_controller.persistRatingModel(
            mapInfo.get(AHAID_LIT).ToString(),
            mapInfo.get('rarRatingTool').ToString(),
            mapInfo.get(RATINGTYPE_LIT).ToString(),
            mapInfo.get('triageConfig').ToString()
        );
    }

    /**
    * @description Call Arc_Gen_.Arc_Gen_ModalFinanStatemController method
    *-------------------------------------------------------------------------------------------------------------------------------
    * @author  francisco.munoz.torres.tech@bbva.com
    * @date    01/09/2025
    * @param Map<String, Object> mapInfo
    * @return Object
    */
    private Object getRatiosResponse(Map<String, Object> mapInfo) {
        return JSON.serialize(
            Arc_Gen_Balance_Tables_Service.getRatiosResponse(
                (arce__Account_has_Analysis__c) mapInfo.get('aha'),
                (List<arce__Financial_Statements__c>) mapInfo.get('selectedFfssList'),
                (Boolean) mapInfo.get('isRAIP')
            )
        );
    }

    /**
    *------------------------------------------------------------------------------------------------------------------------------
    * @description Call Arc_Gen_RatingAsIndepProcess_controller.persistRatingModel method
    *-------------------------------------------------------------------------------------------------------------------------------
    * @author  francisco.munoz.torres.tech@bbva.com
    * @date    29/07/2025
    * @param Map<String, Object> mapInfo
    * @return Object
    */
    private Object callFetchAnalysisRTC(Map<String, Object> mapInfo) {
        return Arc_Gen_CorpRenewAnalysis.fetchAnalysisRTC(
            mapInfo.get('type').ToString(),
            mapInfo.get('clientId').ToString(),
            mapInfo.get('ratingTool').ToString()
        );
    }

    /**
    * @description Call Arc_Gen_.Arc_Gen_ModalFinanStatemController method
    *-------------------------------------------------------------------------------------------------------------------------------
    * @author  francisco.munoz.torres.tech@bbva.com
    * @date    01/09/2025
    * @param Map<String, Object> mapInfo
    * @return Object
    */
    @SuppressWarnings('sf:NullAssignment')
    private Object processRatiosResponse(Map<String, Object> mapInfo) {
        return JSON.serialize(
            Arc_Gen_Balance_Tables_Service.processRatiosResponse(
                (arce__Account_has_Analysis__c) mapInfo.get('aha'),
                (Boolean) mapInfo.get('isFinancialRAIP'),
                (String) mapInfo.get('proposalFolderArceId'),
                (Arc_Gen_Balance_Tables_Service.RatiosResponse) JSON.deserialize(mapInfo.get('response').ToString(), Arc_Gen_Balance_Tables_Service.RatiosResponse.class),
                mapInfo.containsKey(RATINGTYPE_LIT) ? (String) mapInfo.get(RATINGTYPE_LIT) : null
            )
        );
    }
    /**
    *------------------------------------------------------------------------------------------------------------------------------
    * @description Call Arc_Gen_CorpRenewAnalysis.getAllToClon method
    *-------------------------------------------------------------------------------------------------------------------------------
    * @author  francisco.munoz.torres.tech@bbva.com
    * @date    29/07/2025
    * @param Map<String, Object> mapInfo
    * @return Object
    */
    private Object callCloneARCE(Map<String, Object> mapInfo) {
        Arc_Gen_CorpRenewAnalysis.getAllToClone(
            mapInfo.get('currAha').ToString(),
            mapInfo.get('data').ToString(),
            mapInfo.get('ratingTool').ToString()
        );
        return null;
    }

    /**
    *------------------------------------------------------------------------------------------------------------------------------
    * @description Call Arc_Gen_CorpRenewAnalysis.createEEFF method
    *-------------------------------------------------------------------------------------------------------------------------------
    * @author  francisco.munoz.torres.tech@bbva.com
    * @date    29/07/2025
    * @param Map<String, Object> mapInfo
    * @return Object
    */
    private Object callCloneFFSS(Map<String, Object> mapInfo) {
        Arc_Gen_CorpRenewAnalysis.createEEFF(
            mapInfo.get('currAha').ToString(),
            mapInfo.get('data').ToString(),
            mapInfo.get('ratingTool').ToString()
        );
        return null;
    }

    /**
    *------------------------------------------------------------------------------------------------------------------------------
    * @description Call Arc_Gen_RatingAsIndepProcess_controller.newFFSSWAhas method
    *-------------------------------------------------------------------------------------------------------------------------------
    * @author  francisco.munoz.torres.tech@bbva.com
    * @date    07/10/2025
    * @param Map<String, Object> mapInfo
    * @return Object
    */
    private Object callNewFFSSWAhas(Map<String, Object> mapInfo) {
        Arc_Gen_RatingAsIndepProcess_controller.newFFSSWAhas(
            mapInfo.get(AHAID_LIT).ToString(),
            mapInfo.get('analysisId').ToString(),
            mapInfo.get('flowSelected').ToString(),
            mapInfo.get('rarRatingTool').ToString()
        );
        return null;
    }
    /**
    *------------------------------------------------------------------------------------------------------------------------------
    * @description Call Arc_Gen_RatingAsIndepProcess_controller.newFFSSWAhas method
    *-------------------------------------------------------------------------------------------------------------------------------
    * @author  francisco.munoz.torres.tech@bbva.com
    * @date    07/10/2025
    * @param Map<String, Object> mapInfo
    * @return Object
    */
    private Object updateArceName(Map<String, Object> mapInfo) {
        Arc_Gen_NewAnalysis_data.updateArceName(
            mapInfo.get('analysisId').ToString()
        );
        return null;
    }
}