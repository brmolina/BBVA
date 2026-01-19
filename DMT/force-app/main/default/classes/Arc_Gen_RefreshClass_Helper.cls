/**
* @File Name          : Arc_Gen_RefreshClass_Helper.cls
* @Description        : Helper methods for Refresh Class
* @Author             : Mauricio Esquivel mauricio.esquivel.contractor@bbva.com
* @Group              : ARCE Team
* @Controller Class   : Arc_Gen_Refresh_controller
* @Data Class         : Arc_Gen_RefreshClass_data
* @Test Class         : Arc_Gen_RefreshClass_test
* @Last Modified By   :  mauricio.esquivel.contractor@bbva.com
* @Last Modified On   : 24/06/2019
* @Modification Log   :
*==========================================================================================
* Ver         Date                     Author      		                 Modification
*==========================================================================================
* 1.0         24/06/2019              mauricio.esquivel.contractor@bbva.com       Initial Version
**/
public with sharing class Arc_Gen_RefreshClass_Helper {
    /**
    *-------------------------------------------------------------------------------
    * @description empty constructor to sonar validations
    *--------------------------------------------------------------------------------
    * @date		25/06/2019
    * @author	mauricio.esquivel.contractor@bbva.com
    */
    @TestVisible
    private Arc_Gen_RefreshClass_Helper() {
    }
    /**
    *-------------------------------------------------------------------------------
    * @description Create string of comments traceability from new ids
    *--------------------------------------------------------------------------------
    * @date     07/02/2020
    * @author   juanignacio.hita.contractor@bbva.com
    * @param    setIds - list of string with the ids of the element deleted
    * @return   String
    * @example  String ret = Arc_Gen_RefreshClass_service.createCommentTrace(setIds);
    */
    public static String createCommentTrace(List<String> setIds) {
        String strRet = '';
        Integer ite = 0;
        for (String str : setIds) {
            ite++;
            strRet += str;
            if (ite < setIds.size()) {
                strRet += ', ';
            }
        }
        return strRet;
    }
}