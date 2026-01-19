/**
* ────────────────────────────────────────────────────────────────────
* Picasso Response Dispatcher Sample
* Sample implementation of the multiple methods from PicasoResponseDispatcher_itf
* ────────────────────────────────────────────────────────────────────
* @author
* @modifiedBy
* @version     1.0
* @created     2021-02-09
* @modified
* @systemLayer Sample
* ────────────────────────────────────────────────────────────────────
* @changes
*
* ────────────────────────────────────────────────────────────────────
*/
global with sharing class CucoPicassoResponseDispatcherCIB implements cuco.PicasoResponseDispatcher_itf {

    /**
    * @description Process the Picasso response
    * @param response : Picasso response details
    * @return PicassoResponseError_Wrapper result of the Picasso response processing
    */
    global cuco.PicassoResponseError_Wrapper setPicassoResponse(cuco.PicassoResponse_Wrapper response) {

        cuco.PicassoResponseError_Wrapper result;

        Id recordsId = (Id)response.externalId;
        String recordObject = recordsId.getSObjectType().getDescribe().getName();

        switch on recordObject {
            when 'cuco__profitability_analysis__c' {
                result = CucoProfitabilityAnalysisRespCIB.setPicassoProfAnalysisResponse(response);
            }
            when else {
                result = new cuco.PicassoResponseError_Wrapper();
                result.statusCode = 409;
                cuco.PicassoResponseError_Wrapper.ErrorDetail errorDetail = new cuco.PicassoResponseError_Wrapper.ErrorDetail();
                errorDetail.errorCode = Label.cuco.picasso_response_not_found_code;
                errorDetail.message = Label.cuco.picasso_response_not_found_sample;
                result.errorDetail = errorDetail;
            }
        }

        return result;
    }
}