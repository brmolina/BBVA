/** ********************************************************************************
* @author       JSS
* @date         22/01/2020
* @description  Controlador del componente lighning PRC_PriceMatrixBrowser
* @Revision
********************************************************************************* */
@SuppressWarnings('sf:CommentedOutCode,sf:CommentSize,sf:AvoidUsingTestIsRunningTest')
public with sharing class PrcPriceMatrixBrowser_Ctrl {
    // ---------------
    // Public Methods
    // ---------------
     //CONSTRUCTOR
     private PrcPriceMatrixBrowser_Ctrl() {
    }


    /*
    * @author       JSS
    * @description  Méthod que invoca al ws de amiweb y dependiendo de la respuesta si es OK se guardan thods los datos del SelectedPrice
    */
    @auraEnabled
    public static String callWsRegisterAmiweb(String oppId, PRC_PFS_Response priceFullResponse, PRC_PFS_Scenario selectedPrice) {
        final String respMsg = 'success#Pricing simulation successful';

        final PRCPricingUtils pricingLogic = PRCPricingUtils.getInstance();
        pricingLogic.saveSelectedPrice (oppId, priceFullResponse, selectedPrice,'','');
        /*
        final String userCode = pricingLogic.getFederationId();
        final list<Integer> STATUS_CODE_OK_LIST = pricingLogic.getResponseStatusCodeOKList();
        final String jsonInput = '{"userCode":"' + userCode + '","riskProfitabilitiesCalculation":"' + priceFullResponse.data.id + '","scenario-id":"' + selectedPrice.id + '"}';// jsonInput: Placeholders values for the replacement in json string
        // PARA TESTEAR: final String jsonInput = '{"userCode":"XE58953","riskProfitabilitiesCalculation":"2d3e22b3-7f74-48dc-8","scenario-id":"498fbf9e-7252-4786-9"}';
        System.debug('>>>>>>> callWsRegisterAmiweb. jsonInput: ' + jsonInput);
        try {
            HttpResponse resp = ( Test.isRunningTest() ? PRC_MockHttpResponseGenerator.respond_WsRegisterAmiweb() : iaso.GBL_Integration_GenericService.invoke(pricingLogic.getServiceRegisterAmiweb(), jsonInput));
            System.debug('>>>>>>>> respuesta de amiweb - Body: '+resp.getBody() + '\n\r>>>>>>>> respuesta de amiweb - tostring: ' + resp.toString()  + '\n\r>>>>>>>> respuesta de amiweb - headers : '+resp.getHeaderKeys());
            if (STATUS_CODE_OK_LIST.contains(resp.getStatusCode())) {
                final Map <String,Object> mapResp = (Map<String, Object>) JSON.deserializeUntyped(resp.getBody());
                final Map<String, Object> mapRespL1 = (Map<String, Object>) mapResp.get('data');
                //final Map<String, Object> mapRespL2 = (Map<String, Object>) mapRespL1.get('investmentBankingProposal');
                final String amiwebId = (String) mapRespL1.get('webPricingCode');
                final String proposalId = (String) mapRespL1.get('id');
                if (!String.isBlank(amiwebId) && !String.isBlank(proposalId)) {
                    pricingLogic.saveSelectedPrice (oppId, priceFullResponse, selectedPrice,amiwebId,proposalId);
                    respMsg = 'success#The proposal had been registered in Amiweb with the ID ' + amiwebId;
                } else {
                    respMsg = 'error#Error retrieving Amiweb ID. The proposal could not been registered in Amiweb';
                }
            } else {
                respMsg = 'error#Amiweb service call failed: ' + resp.getStatus();
                String respDescription = pricingLogic.getResponseWarningDescription(resp.getBody());
                System.debug('>>>>>>>>>>>> El WS respondió un error: ' + resp.getStatusCode() + ' --- Mensaje Completo: ' + resp.toString() + '\r\n >>>>>>>>> responsewarningdescription: '+ respDescription);

                respMsg += '\n' + respDescription;
            }

        } catch (Exception e) {
            system.debug('Error en el registro de amiweb : '+e.getMessage());
            system.debug('Error en el registro de amiweb-stacktrace : '+e.getStackTraceString());
            respMsg = 'error#An internal error occurred while connecting to Amiweb Service: ' + e.getMessage() + '\nIf the problem persists, contact your administrator';
        }
        */

        return respMsg;
    }



    /*
    * @author       JSS
    * @description  Méthod que invoca al ws de workflow y dependiendo de la respuesta si es OK se guardan los datos de workflow
    */
    @auraEnabled
    public static String callWsRegisterWorkflow(String oppId) {
        String respMsg = '';
        final PRCPricingUtils pricingLogic = PRCPricingUtils.getInstance();
        final String userCode = pricingLogic.getFederationId();
        final String matrixProposalId  = pricingLogic.getMatrixProposalId(oppId);
        final list<Integer> S_COD_OK_LT = pricingLogic.getResponseStatusCodeOKList();
        //para TESTEAR: matrixProposalId  ea2236b0-1aef-48a4-8      9db376e0-a49d-4641-9 ; y userCode=E055654  --  final String userCode = 'E055654';
        final String jsonInput = '{"userCode":"' + userCode + '","investmentBankingProposalId":"' + matrixProposalId + '"}';// jsonInput: Placeholders values for the replacement in json string
        try {
            final HttpResponse resp = ( Test.isRunningTest() ? PRC_MockHttpResponseGenerator.respond_WsRegisterWorkflow() : iaso.GBL_Integration_GenericService.invoke(pricingLogic.getServiceRegisterWorkflow(), jsonInput) ); //NOSONAR
            system.debug('>>>>>>>>>> respuesta ws callWsRegisterWorkflow: ' + resp.getBody() );
            if (S_COD_OK_LT.contains(resp.getStatusCode())) {
                final Map <String,Object> mapResp = (Map<String, Object>) JSON.deserializeUntyped(resp.getBody());
                final Map<String, Object> mapRespL1 = (Map<String, Object>) mapResp.get('data');
                //final Map<String, Object> mapRespL2 = (Map<String, Object>) mapRespL1.get('investmentBankingProposal');
                final Map<String, Object> mapRespL3 = (Map<String, Object>) mapRespL1.get('status');
                final String workflowId = (String) mapRespL1.get('workflowCode');//mapRespL2.get('workflowCode');
                final String workflowStatus = (String) mapRespL3.get('id');
                if (String.isBlank(workflowId) && String.isBlank(workflowStatus)) {
                    respMsg = 'error#Error retrieving Workflow ID. The proposal could not been sent to Workflow';
                } else {
                    pricingLogic.saveWorkflowData(oppId,workflowId,workflowStatus);
                    respMsg = 'success#The proposal had been sent to Workflow with the ID ' + workflowId;
                }
            } else { respMsg = 'error#Workflow service call failed: ' + resp.getStatus(); }
        } catch (Exception e) {
            respMsg = 'error#An internal error occurred while connecting to Workflow Service: ' + e.getMessage() + '\nIf the problem persists, contact your administrator';
        }

        system.debug('>>>>>>>>>> respuesta ws callWsRegisterWorkflow: ' + respMsg );
       return respMsg;
    }


    /*
    * @author       JSS
    * @description  Méthod que recupera los datos actuales de workflow y después invoca al ws de workflow y dependiendo de la respuesta si es OK se actualiza el estado de workflow
    */
    @auraEnabled
    public static String getStatusWorkflow(String oppId) {
        system.debug('>>>>>>>>>> getStatusWorkflow: oppId  ' + oppId );
        final Opportunity opp = [SELECT Id, IsClosed, gf_workflow_opportunity_id__c, gf_workflow_oppy_status_type__c, gf_proposal_id__c FROM Opportunity where Id = :oppId LIMIT 1];
        String toReturn = 'OK#' + (string.isBlank(opp.gf_workflow_opportunity_id__c) ? '' : opp.gf_workflow_opportunity_id__c) + '#' +  (string.isBlank(opp.gf_workflow_oppy_status_type__c) ? '' : opp.gf_workflow_oppy_status_type__c);

        if (!opp.isClosed && !string.isBlank(opp.gf_workflow_opportunity_id__c)) {
            toReturn = callWsGetStatusWorkflow(oppId, opp.gf_proposal_id__c, opp.gf_workflow_oppy_status_type__c);
        }
        return toReturn;
    }


    /*
    * @author       JSS
    * @description  Méthod que invoca al ws de workflow y dependiendo de la respuesta si es OK se actualiza el estado de workflow
    */
    @auraEnabled
    public static String callWsGetStatusWorkflow(String oppId, String proposalId, String currentWfStatus) {
        String respMsg = '';
        final PRCPricingUtils pricingLogic = PRCPricingUtils.getInstance();
        //final String userCode = pricingLogic.getFederationId(); -> de momento no se envía porque en las peticiones GET de ws no se envían nada en la request
        final list<Integer> S_COD_OK_LT = pricingLogic.getResponseStatusCodeOKList();
        final String jsonInput = '{"investmentBankingProposalId":"' + proposalId + '"}'; // '{"userCode":"' + userCode + '","investmentBankingProposalId":"' + proposalId + '"}'
        try {
            HttpResponse resp = ( Test.isRunningTest() ? PRC_MockHttpResponseGenerator.respond_WsGetStatusWorkflow() : iaso.GBL_Integration_GenericService.invoke(pricingLogic.getServiceStatusWorkflow(), jsonInput) );
            if (S_COD_OK_LT.contains(resp.getStatusCode())) {
                final Map <String,Object> mapResp = (Map<String, Object>) JSON.deserializeUntyped(resp.getBody());
                final Map<String, Object> mapRespL1 = (Map<String, Object>) mapResp.get('data');
                //final Map<String, Object> mapRespL2 = (Map<String, Object>) mapRespL1.get('investmentBankingProposal');
                final Map<String, Object> mapRespL3 = (Map<String, Object>) mapRespL1.get('status');
                final String workflowId = (String) mapRespL1.get('workflowCode'); //mapRespL2.get('workflowCode');
                final String workflowStatus = (String) mapRespL3.get('id');
                if (!String.isBlank(workflowStatus) && currentWfStatus != workflowStatus) {
                    pricingLogic.saveWorkflowData(oppId,workflowId,workflowStatus);
                }
                respMsg = 'OK#' + workflowId + '#' + workflowStatus;
            } else { respMsg = 'error#Workflow service call failed: ' + resp.getStatusCode() + '\r\n' + resp.toString(); }

        } catch (Exception e) {
            respMsg = 'error#An internal error occurred while connecting to Workflow Service: ' + e.getMessage() + '\nIf the problem persists, contact your administrator';
        }

        return respMsg;
    }

}