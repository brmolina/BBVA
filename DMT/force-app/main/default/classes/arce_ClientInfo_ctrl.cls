/**
* ____________________________________________________________________________
* Controller class for arce_ClientInfo.cmp aura Component
* ____________________________________________________________________________
* @author      DAvid Otero <david.otero.carcia.contractor@bbva.com>
* @modifiedBy
* @version     1.0
* @created     2024-10-10
* @modified
* @systemLayer Sample
* ____________________________________________________________________________
* @changes
*
* ____________________________________________________________________________
*/
global with sharing class arce_ClientInfo_ctrl {

    /**
    * @description Private constructor to avoid sonar err
    */
    /* public arce_ClientInfo_ctrl() {

    } */

    /**
    * @description Get data from services
    * @param 
    * @return retMap accountLst
    */
    /* @AuraEnabled
    public static Map<String,Object> getInitialData () {
        Map<String, Object> retMap = new Map<String, Object>();
        List<Account> accountLst = new List<Account>();
        boolean succes = true;
        accountLst = ARC_utils.accountList();

        retMap.put('succes', succes);
        retMap.put('groupAccLst', accountLst);

        return retMap;
    } */

    /**
    * @description Get data from services
    * @param 
    * @return retMap accountLst
    */
    /* @AuraEnabled
    public static Map<String,Object> getSearchData (string field, string name) {
        Map<String, Object> retMap = new Map<String, Object>();
        List<Account> accountLst = new List<Account>();
        boolean succes = true;
        string msgError = '';

        if(name == null || name == ''){
            accountLst = ARC_utils.accountList();
        }else{
            if(field == 'Group Name'){
                accountLst =ARC_utils.accountGroupSoslList(name);
            }else if(field == 'Group Id'){
                accountLst =ARC_utils.accountGroupCodeSoslList(name);
            }else if(field == 'country'){
                accountLst =ARC_utils.accountCountrySoslList(name);
            }else if(field == '' || field == null){
                accountLst = ARC_utils.accountList();
            }else {
                accountLst =ARC_utils.accountSoslList(name);
            }
        }

        retMap.put('succes', succes);
        retMap.put('msgError', msgError);
        retMap.put('groupAccLst', accountLst);

        return retMap;
    } */
}