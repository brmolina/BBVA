public with sharing class DMT_LaunchDealManagementIPService {

    public class InputDTO {
        @AuraEnabled public String originId;
        @AuraEnabled public String currentTab;
        @AuraEnabled public String viewTab;
        @AuraEnabled public String oppSelected;
        @AuraEnabled public String productSelected;
        @AuraEnabled public String originGroup;
    }

    @AuraEnabled(cacheable=true)
    public static Map<String, Object> execute(
        String originId,
        String currentTab,
        String viewTab,
        String oppSelected,
        String productSelected,
        String originGroup
    ) {
        Map<String, Object> result = new Map<String, Object>();
        system.debug('input.get'+originId);
            Map<String, Object> input = new Map<String, Object>{
        'originId' => originId,
        'currentTab' => currentTab,
        'viewTab' => viewTab,
        'oppSelected' => oppSelected,
        'productSelected' => productSelected,
        'originGroup' => originGroup
    };

        Map<String, Object> params = new Map<String, Object>();
        DMT_DealManagement_Handler handler = new DMT_DealManagement_Handler();
        Map<String, Object> inputs = new Map<String, Object>();
        Map<String, Object> output = new Map<String, Object>();
        Map<String, Object> options = new Map<String, Object>();

        Map<String, Object> argsDeal = new Map<String, Object>();
        Map<String, Object> args = new Map<String, Object>();
        argsDeal.put('input', inputs);
        argsDeal.put('output', output);
        argsDeal.put('options', options);

        Map<String, Object> argsLastDate = new Map<String, Object>{
            'input' => new Map<String, Object>(),
            'output' => new Map<String, Object>(),
            'options' => new Map<String, Object>()
        };
        Map<String, Object> lastDateResult = (Map<String, Object>) handler.call(
            'lastDate',
            argsLastDate
        );

        String returnedDate = (String) lastDateResult.get('returnedDate');system.debug('returnedDate'+returnedDate);

        // GET GROUP
        Map<String, Object> argsGroup = new Map<String, Object>{
            'input' => new Map<String, Object>{
                'originId' => originId
            },
            'output' => new Map<String, Object>(),
            'options' => new Map<String, Object>()
        };
        Map<String, Object> groupResult = (Map<String, Object>) handler.call(
            'getGroup',
            argsGroup
        );
        String groupCode = (String) groupResult.get('groupCode');system.debug('groupCode'+groupCode);

        String nonDisclosedCode = null;
        if (originGroup == 'GXXXXXXXXXXXXXX') {
            nonDisclosedCode = 'GXXXXXXXXXXXXXX';
        }

        Map<String, Object> userData = DMT_UserDataApexService.getUserData();
        List<Object> rolesConverted = new List<Object>();
        List<String> roles = (List<String>) userData.get('roles');
        for (String r : roles) {
            rolesConverted.add(r);
        }
        Map<String, Object> drInput = new Map<String, Object>{
            'returnedDate' => returnedDate,
            'originId' => originId,
            'currentTab' => currentTab,
            'groupCode' => groupCode,
            'viewTab' => viewTab,
            'oppSelected' => oppSelected,
            'productSelected' => productSelected,
            'nonDisclosedCode' => nonDisclosedCode
        };

        Map<String, Object> drOutput = DMT_ExtractOpportunityByClientApex.execute(drInput);

        Map<String, Object> creationParamsInput = new Map<String, Object>{
            'roles' => roles,
            'RecordTypeName' => 'DMT Opportunity',
            'groupId' => drOutput.get('groupCode'),
            'ClientId' => drOutput.get('ClientId')
        };

        DMT_GetCreationParameters creationHandler = new DMT_GetCreationParameters();
        Map<String, Object> argsCreation = new Map<String, Object>{
            'input' => creationParamsInput,
            'output' => new Map<String, Object>(),
            'options' => new Map<String, Object>()
        };

        Object creationParams = creationHandler.call(
            'getCreationParametersList',
            argsCreation
        );
        Boolean oppAccess = creationParams != null && String.valueOf(creationParams) != '[]';

                // Datos base del DR
        result.putAll(drOutput);

        // 🔥 CAMPOS QUE NO VIENEN DEL DR (pero el LWC espera)
        result.put('returnedDate', returnedDate);
        result.put('originId', originId);
        result.put('originGroup', originGroup);
        result.put('viewTab', viewTab);

        // Access + user info
        result.put('OppAccess', oppAccess);
        result.put('hasWriteAccessUser', userData.get('hasWriteAccessUser'));
        result.put('hasLineGodAccess', userData.get('hasLineGodAccess'));

        // ⚠️ MUY IMPORTANTE → UserInfo completo (el LWC lo usa mucho)
        Map<String, Object> userInfo = new Map<String, Object>{
            'hasAccessActions' => true,
            'hasAccessWrite' => userData.get('hasWriteAccessUser'),
            'groupCode' => groupCode,
            'DMT_User_Role__c' => String.join((List<String>) userData.get('roles'), ';')
        };

        result.put('UserInfo', userInfo);

        return result;
    }

    private static String asString(Object value) {
        return value == null ? '' : String.valueOf(value);
    }

    private static String defaultIfBlank(String value, String fallback) {
        return String.isBlank(value) ? fallback : value;
    }
}