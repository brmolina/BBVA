/**-------------------------------------------------------------------------------------------
* @Name     PAWIF Controller
* @Date     Created: 2024-11-25
* ------------------------------------------------------------------------------------------------
* @Description Call PAWIF service and update Oportunity and NBC status.
* ------------------------------------------------------------------------------------------------
*/
public with sharing class PAW_PawifHelper {

    @InvocableMethod(label='setPawifInformation' description='Update Opportunity in PAWIF')
    public static List<Boolean> setPawifInformationOpportunity(List<sObject> objectTypeList) {

        System.debug('START FLOW');
        System.debug(objectTypeList);

        final Map<String, Object> request = new Map<String, Object>();
        final Map<String, Object> input = new Map<String, Object>();
        final Opportunity opportunity = getOpportunity(objectTypeList.get(0).Id);

        input.put('simulationId', opportunity.PAW_simulation_Id__c);
        input.put('urlOpportunity', URL.getOrgDomainURL().toExternalForm() + '/lightning/r/Opportunity/' + opportunity.Id + '/view');
        input.put('urlSimulation', opportunity.PAW_simulation_url__c);
        input.put('simulationStatus', opportunity.StageName.contains('Closed') ? getSimulationStatusOpportunity(opportunity.StageName) : getSimulationStatusPawif(opportunity.NBC_Decision_Taken_type__c));
        request.put('jsonInput', JSON.Serialize(input));

        System.debug('REQUEST');
        System.debug(request);

        final PAW_Pawif.Wrapper responsePawif = PAW_Pawif.setPawifInformation(request);
        final List<Boolean> responseListStatus = new List<Boolean>();
        responseListStatus.add(responsePawif.success);

        System.debug('RESPONSE');
        System.debug(responsePawif);

        return responseListStatus;
    }

    public static String getSimulationStatusOpportunity(String stageName) {
        String pawifStageName;
        if(stageName == Label.DES_Closed_Won) {
            pawifStageName = PAW_Pawif.PAWIF_OPPORTUNITY_STAGE_CLOSE_WON;
        } else {
            pawifStageName = PAW_Pawif.PAWIF_OPPORTUNITY_STAGE_CLOSE_LOST;
        }
        return pawifStageName;
    }

    public static String getSimulationStatusPawif(String decisionTaken) {
        String decisionTakenNbc;
        if(decisionTaken == Label.NBC_Decision_Recommended) {
            decisionTakenNbc = PAW_Pawif.PAWIF_DECISION_TAKEN_NBC_RECOMMENDED;
        } else {
            decisionTakenNbc = PAW_Pawif.PAWIF_DECISION_TAKEN_NBC_NOT_RECOMMENDED;
        }
        return decisionTakenNbc;
    }

    public static Opportunity getOpportunity(Id opportunityId) {
        return [SELECT Id, StageName, PAW_simulation_url__c, PAW_simulation_Id__c, NBC_Decision_Taken_type__c FROM Opportunity WHERE Id =: opportunityId WITH SECURITY_ENFORCED LIMIT 1];
    }

    public static HttpResponse callService(String serviceName, Map<String, Object> request) {
        request.put('userId', getFederationIdentifier());
        final String requestStr = JSON.serialize(request);
        HttpResponse response;
        if (Test.isRunningTest()) {
            response = getMock(serviceName);
        } else {
            response = iaso.GBL_Integration_GenericService.invoke(serviceName, requestStr);
        }
        return response;
    }

    public static HttpResponse getMock(String serviceName) {
        final HttpResponse response = new HttpResponse();
        final iaso__GBL_integration_service__mdt serviceDetails = [SELECT iaso__Mock_LTA__c , iaso__Http_Method__c FROM iaso__GBL_integration_service__mdt WHERE DeveloperName =:serviceName LIMIT 1];
        final String responseBody = (String)serviceDetails.get('iaso__Mock_LTA__c');
        final String requestMethod = (String)serviceDetails.get('iaso__Http_Method__c');
        response.setStatus('OK');
        response.setStatusCode(requestMethod == 'GET' ? 200 : 201);
        response.setBody(responseBody);
        return response;
    }

    public static String getFederationIdentifier() {
        final Id userId = UserInfo.getUserId();
        return [SELECT FederationIdentifier FROM User WHERE Id = :userId LIMIT 1].FederationIdentifier;
    }

}