/**
* ____________________________________________________________________________
* Controller class for DPMX_AuthorizationDetails.cmp aura Component
* ____________________________________________________________________________
* @author      David Otero <david.otero.carcia.contractor@bbva.com>
* @modifiedBy
* @version     1.0
* @created     2025-04-01
* @modified
* @systemLayer Sample
* ____________________________________________________________________________
* @changes
*
* ____________________________________________________________________________
*/

public class DPMX_AuthorizationHighlight_ctrl {
    /**
    * @description Private constructor to avoid sonar err
    */
    public DPMX_AuthorizationHighlight_ctrl() {
		Map<String, Object> retMap = new Map<String, Object>();
    }
    /**
    * @description Get data from services
    * @param recordId : 
    * @return retMap ??????
    */
    @AuraEnabled
    public static Map<String,Object> getInitialData (String recordId) {
        Map<String, Object> retMap = new Map<String, Object>();
        boolean isCorrectUSer = false;
        DPMX_authorization__c coments = DPMX_Utils.AuthSelector(recordId);
        if(coments.lkp_AssignedTo__c == UserInfo.getUserId() && coments.Status__c == 'Pendiente'){
            isCorrectUSer = true;
        }

        retMap.put('name', coments.name);
        retMap.put('disableBtn', isCorrectUSer);

        return retMap;
    }
}