/**-------------------------------------------------------------------------------------------
* @Name     PAWIF Service
* @Date     Created: 2024-11-25
* ------------------------------------------------------------------------------------------------
* @Description Wrapper Class for pawif service
* ------------------------------------------------------------------------------------------------
*/
public with sharing class PAW_Pawif {

    //PAWIF
    public static final String PAWIF_OPPORTUNITY_STAGE_CLOSE_WON ='CW';
    public static final String PAWIF_OPPORTUNITY_STAGE_CLOSE_LOST ='CL';
    public static final String PAWIF_DECISION_TAKEN_NBC_RECOMMENDED ='AD';
    public static final String PAWIF_DECISION_TAKEN_NBC_NOT_RECOMMENDED ='NA';
    public static final String PAWIF_SALESFORCE_CONNECTIONS = 'PAWIF_SalesforceConnections';
    public static final String ENDPOINT_PAWIF = 'https://aso-int-global.work-01.platform.bbva.com/pawif/v0/';
    public static final String ENDPOINT_AUTH = 'https://aso-int-global.work-01.platform.bbva.com/TechArchitecture/grantingTickets/V02';

    public static Wrapper setPawifInformation(Map<String, Object> request) {
        Wrapper res = new Wrapper();
        final HttpResponse response = PAW_PawifHelper.callService(PAWIF_SALESFORCE_CONNECTIONS, request);
        switch on response.getStatusCode() {
            when 200, 201 {
                final Object obj = System.JSON.deserialize(response.getBody(), Wrapper.class);
                res = (Wrapper)obj;
                res.success = true;
            }
            when else {
                res.errorMessage = String.valueOf(response.getBody());
                res.success = false;
            }
        }
        return res;
    }

    public class Wrapper {
        public Data data {get;set;}
        public Boolean success {get;set;}
        public String errorMessage {get;set;}
    }

    public class Data {
        public String opportunityId {get;set;}
        public String urlOpportunity {get;set;}
        public String urlSimulation {get;set;}
        public String simulationStatus {get;set;}
    }
}