@IsTest
global class DMT_Integration_MockGenerator implements HttpCalloutMock {
    global HttpResponse respond(HttpRequest req) {
        HttpResponse res = new HttpResponse();
        String endpoint = req.getEndpoint();
        String method = req.getMethod();

        if (endpoint.contains('service/ko')) {
            res.setBody('Error');
            res.setStatusCode(403);
            return res;
        }

        // Outer map: endpoint -> inner map
        Map<String, Map<String, String>> endpointToMethodDevName = new Map<String, Map<String, String>>{
            'assumption' => new Map<String, String>{
                'POST' => 'DMT_ProfitabilityMatrix'
            },
            'consumption' => new Map<String, String>{
                'POST' => 'DMT_HPG_GetConsumption'
            },
            'lines' => new Map<String, String>{
                'POST' => 'DMTO_RiskPositionLine'
            },
            'consumptionlimits' => new Map<String, String>{
                'GET' => 'DMT_Engines'
            },
            'consumptions-reassign' => new Map<String, String>{
                'POST' => 'DMT_consumptionsReassign'
            },
            'opportunity-consumption-limits' => new Map<String, String>{
                'PUT' => 'DMT_PUT_OpportunityConsumptionLimit'
            },
            'snapshot-evaluation-versions' => new Map<String, String>{
                'GET' => 'DMT_GetSnapshotEvaluationVersions',
                'POST' => 'DMT_PostSnapshotEvaluationVersions'
            },
            'group-positions' => new Map<String, String>{
                'GET' => 'DMT_HPG_GetGroupPositions'
            },
            'global-position' => new Map<String, String>{
                'POST' => 'DMT_HPG_GlobalPosition'
            },
            'used-tables' => new Map<String, String>{
                'GET' => 'DMT_HPG_GetUsedTables'
            },
            'opportunities-codes' => new Map<String, String>{
                'POST' => 'DMT_OpportunityCodes'
            },
            'capital-provision' => new Map<String, String>{
                'POST' => 'DMT_HPG_GetCapitalProvision'
            },
            'connected-customers' => new Map<String, String>{
                'GET' => 'DMT_HPG_ConnectedCustomers'
            },
            'evaluation-line' => new Map<String, String>{
                'GET' => 'DMTO_EvaluationLine'
            },
            'evaluation-opportunity' => new Map<String, String>{
                'POST' => 'DMTO_EvaluationOpportunity'
            },
            'eca-customers' => new Map<String, String>{
                'GET' => 'DMT_GetEcaCustomers'
            },
            'risk-proposals' => new Map<String, String>{
                'GET' => 'GDT_BlockStudiesProposal'
            },
            'override-consumption' => new Map<String, String>{
                'POST' => 'DMT_HPG_CreateOverrideConsumption',
                'PATCH' => 'DMT_HPG_UpdateOverrideConsumption'
            }
        };

        // --- Sort endpoints by length descending ---
        List<String> sortedEndpoints = new List<String>();
        sortedEndpoints.addAll(endpointToMethodDevName.keySet());
        sortedEndpoints.sort();
        sortedEndpoints = sortByLengthDesc(sortedEndpoints);

        // Find matching Custom Metadata record
        // --- Loop through endpoints from longest to shortest ---
        for (String keyEndpoint : sortedEndpoints) {
            System.debug(logginglevel.INFO, 'endpoint key to check: ' + keyEndpoint);
            if (endpoint.contains(keyEndpoint)) {
                Map<String, String> methodMap = endpointToMethodDevName.get(keyEndpoint);
                if (methodMap.containsKey(method)) {
                    String devName = methodMap.get(method);

                    System.debug(logginglevel.INFO,'DMT_Integration_MockGenerator integration service devName: ' + devName);

                    // Query the MDT for the mock body
                    iaso__GBL_integration_service__mdt mdt = [SELECT iaso__Mock_LTA__c FROM iaso__GBL_integration_service__mdt WHERE DeveloperName = :devName LIMIT 1];

                    res.setBody(mdt.iaso__Mock_LTA__c);
                    if(devName == 'DMT_consumptionsReassign'){
                        // Special case for consumptions-reassign to return 204 No Content
                        res.setStatusCode(204);
                        return res;
                    }
                    res.setStatusCode(method == 'GET' ? 200 : 201);
                    return res;
                }
            }
        }

        // Default fallback
        res.setBody('{"error": "No mock defined for this endpoint"}');
        res.setStatusCode(500);
        return res;

        // ***************************** POSSIBLE FALLBACK THAT CAN BE ADDED LATER *****************************************

      /* if (endpoint.contains('validation.ok') || endpoint.contains('service.ok')) {
            res.setStatusCode(200);
            res.setBody('{"foo": "bar"}');
            return res;
        } */

    }

    // Helper method: Sort list by string length descending
    private static List<String> sortByLengthDesc(List<String> input) {
        List<String> output = new List<String>();
        while (!input.isEmpty()) {
            Integer longestIndex = 0;
            for (Integer i = 1; i < input.size(); i++) {
                if (input[i].length() > input[longestIndex].length()) {
                    longestIndex = i;
                }
            }
            output.add(input[longestIndex]);
            input.remove(longestIndex);
        }
        return output;
    }
}