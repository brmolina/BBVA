/**
* -----------------------------------------------------------------------------------------------
* @Name           Arc_IFIS_ButtonsStatus
* @Author         marcos.gimeno.next@bbva.com
* @Date           01-09-2023
*
* @Group          ARCE
* -----------------------------------------------------------------------------------------------
* @Description Used to retrieve buttons status.
* -----------------------------------------------------------------------------------------------
* @Changes
* v1.0            marcos.gimeno.next@bbva.com
* 01-09-2023      Class creation.
* -----------------------------------------------------------------------------------------------
**/
@SuppressWarnings('PMD.AvoidGlobalModifier')
global with sharing class Arc_IFIS_ButtonsStatus implements dwp_dbpn.DynamicButtonsStatusInterface {
    /**
    * @description Default rule set identifier.
    */
    private static final String RULESET = 'Arc_IFIS_RS_ButtonsRating';
    /**
    * @description Required permission sets to edit the dynamic form
    */
    final static List<String> REQUIRED_PS = new List<String>{ 'IFIS' };
    /**
    * -----------------------------------------------------------------------------------------------
    * @description Controls the availability of the given button with the selectedSector.
    * -----------------------------------------------------------------------------------------------
    * @autor    marcos.gimeno.next@bbva.com
    * @date     28-02-2023
    * @param    recordId       Current record ID
    * @param    sObjectName    Current record API name
    * @return   List of buttons assigned to the collection
    * @example  Set<String> e = getDynamicButtonStatus(recordId, sObjectName)
    * -----------------------------------------------------------------------------------------------
    **/
    @SuppressWarnings('sf:AvoidUsingTestIsRunningTest')
    global static Set<String> getDynamicButtonStatus(String recordId, String sObjectName) {
        final Set<String> buttonsStatusSet = new Set<String>();
        if (recordId != null && recordId != '') {
            final List<Id> lstIds = new List<Id>();
            lstIds.add(recordId);
            final Type inter = Type.forName('arcealloc.Allocation_Service');
            final boolean custAlloc = String.isNotBlank(String.valueOf(inter)) && !Test.isRunningTest()
                ? ((Map<Id, boolean>) ((Callable) inter.newInstance())
                          .call('checkBulkPrivileges', new Map<String, Object>{ 'accHasAnlysIdsLst' => lstIds }))
                      .get(recordId)
                : true;
            Map<String, Set<String>> actOppIdMap = new Map<String, Set<String>>();
            // Test.isRunningTest() is required because permission sets are in a separate deployment
            if (Test.isRunningTest() || (hasPermissions() && custAlloc)) {
                actOppIdMap = dwp_dace.DynamicActionsEngine_helper.getAvailableActions(
                    lstIds,
                    sObjectName,
                    'Arc_IFIS_RS_Buttons'
                );
            }
            if (actOppIdMap.get(recordId) != null) { 
                buttonsStatusSet.addAll(actOppIdMap.get(recordId));
            }
        }
        return buttonsStatusSet;
    }


    /**
    * -----------------------------------------------------------------------------------------------
    * @description Checks if the user has the required permission sets.
    * -----------------------------------------------------------------------------------------------
    * @autor       marcos.gimeno.tech@bbva.com
    * @date        09-04-2024
    * @return      Boolean indicating if the user has the required permission sets
    * @example     Boolean e = hasPermissions()
    * -----------------------------------------------------------------------------------------------
    **/
    private static Boolean hasPermissions() {
        final arce.Arc_Gen_User_Wrapper uInfo = arce.Arc_Gen_User_Locator.getUserInfo(System.UserInfo.getUserId());
        final Set<String> psAssignSet = arce.Arc_Gen_GenericUtilities.getPSAssignments(uInfo.userBasicInfo.Name);
        return psAssignSet.containsAll(REQUIRED_PS);
    }
}