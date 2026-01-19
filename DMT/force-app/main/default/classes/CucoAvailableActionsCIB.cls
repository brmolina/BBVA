/**
* ────────────────────────────────────────────────────────────────────────────────────
* CucoAvailableActionsCIB
* implements AvailableActions_itf interface
* ────────────────────────────────────────────────────────────────────────────────────
* @author      Torcuato Tejada <torcuato.tejada.contractor@bbva.com>
* @modifiedBy
* @version     1.0
* @created     2021-05-21
* @modified
* @systemLayer Sample
* ────────────────────────────────────────────────────────────────────────────────────
* @changes
*
* ────────────────────────────────────────────────────────────────────────────────────
*/
@SuppressWarnings('PMD.AvoidGlobalModifier, sf:UseSingleton, sf:CyclomaticComplexity')
global class CucoAvailableActionsCIB implements cuco.AvailableActions_itf {

    global static Map<String,Object> checkAvailableAction(String action, Id profanalysisId) {

        final Map<String,object> mapResp = new Map<String,object>();
        final Set<Id> ids = new Set<Id>{profanalysisId};
        final cuco.ProfitabilityAnalysis_Selector profAnSelector = new cuco.ProfitabilityAnalysis_Selector(true);
        final List<cuco__profitability_analysis__c> currentpa = profAnSelector.selectById(ids);

        switch on action {
            when 'PA_Dismiss' {
                final List<String> paDismissStatusLst = new List<String>{'Restudy', 'Price Approved', 'Price Authorized', 'Price Returned', 'Analysis'};
                if((currentpa[0].cuco__gf_pa_management_type_name__c == 'Cancellation' && currentpa[0].cuco__gf_pa_mgmt_status_type_name__c == 'Analysis')
                    || (currentpa[0].cuco__gf_pa_management_type_name__c  != 'Cancellation' && paDismissStatusLst.contains(currentpa[0].cuco__gf_pa_mgmt_status_type_name__c) && currentpa[0].cuco__gf_auto_formalization_req_id__c == null)) {
                    mapResp.put('success', true);
                } else {
                    mapResp.put('success', false);
                    mapResp.put('message', Label.cuco.action_not_available_sample);
                }
            }
            when 'PA_Restudy' {
                mapResp.put('success', true);
                final List<String> paRestudyStatus = new List<String>{'Price Approved', 'Price Authorized', 'Price Returned', 'Formalization Returned'};
                if (currentpa[0].cuco__gf_pa_management_type_name__c == 'Cancellation' || !paRestudyStatus.contains(currentpa[0].cuco__gf_pa_mgmt_status_type_name__c)) {
                    mapResp.put('success', false);
                    mapResp.put('message', Label.cuco.action_not_available_sample);
                }
            }
            when 'PA_Formalization' {
                if (currentpa[0].cuco__gf_pa_management_type_name__c == 'Cancellation' && currentpa[0].cuco__gf_pa_mgmt_status_type_name__c != 'Analysis') {
                    mapResp.put('success', false);
                    mapResp.put('message', Label.cuco.action_not_available_sample);
                } else {
                    mapResp.put('success', true);
                }
            }
            when 'PA_Notification' {
                if(currentpa[0].cuco__gf_pa_mgmt_status_type_name__c == 'Sent for Formalization') {
                    mapResp.put('success', true);
                } else {
                    mapResp.put('success', false);
                    mapResp.put('message', Label.cuco.action_not_available_sample);
                }
            }
        }
        return mapResp;
    }
}