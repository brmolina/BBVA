/**
* ────────────────────────────────────────────────────────────────────
* Cuco PAActionsStatus CIB
* Implementation of the DynamicButtonsStatusInterface
* ────────────────────────────────────────────────────────────────────
* @author     
* @modifiedBy
* @version     1.0
* @created     2021-06-01
* @modified
* ────────────────────────────────────────────────────────────────────
* @changes
*
* ────────────────────────────────────────────────────────────────────
*/
@SuppressWarnings('PMD.AvoidGlobalModifier')
global class PAActionsStatus implements dwp_dbpn.DynamicButtonsStatusInterface {
    global Set<String> getDynamicButtonStatus(String recordId, String sObjectName) {
        Set<String> buttonsStatusSet = new Set<String>();
        if (recordId != null && recordId != '') {
            final List<Id> lstIds = new List<Id>();
            lstIds.add(recordId);
            Map<String,Set<String>> actionsMap = dwp_dace.DynamicActionsEngine_helper.getAvailableActions(lstIds,sObjectName,'PA_Actions_Sample');
            if (actionsMap.get(recordId) != null) {
                buttonsStatusSet.addAll(actionsMap.get(recordId));
            }
        }
        return buttonsStatusSet;
    }
}