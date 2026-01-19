/**
* @File Name          : Arc_Gen_TriageService_data.cls
* @Description        : Class that receives the data of salesforce to the triage service
* @Author             : eduardoefrain.hernandez.contractor@bbva.com
* @Group              : ARCE Team
* @Last Modified By   : eduardoefrain.hernandez.contractor@bbva.com
* @Last Modified On   : 12/8/2019 18:16:47
* @Changes
*==============================================================================
* Ver         Date                     Author      		      Modification
*==============================================================================
* 1.0    12/8/2019 18:00:36   eduardoefrain.hernandez.contractor@bbva.com     Initial Version
* 1.0    23/09/2020     saimassimilianno.jordana.contractor@bbva.com          Added arce. namespace to all classes that are now in the arce-dependencies package
**/
public class Arc_Gen_Triage_data {
    /**
    *-------------------------------------------------------------------------------
    * @description Web service service
    --------------------------------------------------------------------------------
    * @author ricardo.almanza.contractor@bbva.com
    * @date 03/04/2020
    * @param void
    * @return void
    * @example Arc_Gen_Triage_data()
    **/
    @TestVisible
    private Arc_Gen_Triage_data() {}
    /**
*-------------------------------------------------------------------------------
* @description Method that calls a service using the iaso component
--------------------------------------------------------------------------------
* @author eduardoefrain.hernandez.contractor@bbva.com
* @date 12/8/2019
* @param String analysisId
* @param String customerId
* @return arce.Arc_Gen_getIASOResponse.serviceResponse - Wrapper that contains the response of the called service
* @example public arce.Arc_Gen_getIASOResponse.serviceResponse callRatingService(String analysisId,String customerId)
**/
    public static arce.Arc_Gen_getIASOResponse.serviceResponse callTriageService(String parameters, String serviceName) {
        arce.Arc_Gen_getIASOResponse.serviceResponse response = new arce.Arc_Gen_getIASOResponse.serviceResponse();
        response = arce.Arc_Gen_getIASOResponse.calloutIASO(serviceName, parameters);
        system.debug('response triage**'+response);
        Return response;
    }
}