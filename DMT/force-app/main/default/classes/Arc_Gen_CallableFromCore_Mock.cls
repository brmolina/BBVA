/**
* @File Name          : Arc_Gen_CallableFromCore_Mock.cls
* @Description        : callable Mockup class for Arc_Gen_CallableFromCore.cls
* @Author             : aleksandar.dinkov.contractor@bbva.com
* @Group              : ARCE Team
* @Last Modified By   : ChangeMeIn@UserSettingsUnder.SFDoc
* @Last Modified On   : 03-31-2026
* @Changes
*========================================================================================
* Ver         Date                     Author                 Modification
*========================================================================================
* 1.0         22/07/2024    aleksandar.dinkov.contractor@bbva.com     Initial Version
* 1.1         23/06/2025    isabel.ascaso.tech@bbva.com               Añadir invocableGroupStructurePS method
**/
@SuppressWarnings('sf:OnlyOneReturn, sf:UnusedFormalParameter')
public with sharing class Arc_Gen_CallableFromCore_Mock implements Callable {
    /**
    * @description Utilizes the callable interface to call another methods of actual class.
    * @author aleksandar.dinkov.contractor@bbva.com | 22/07/2024
    * @param String action
    * @param Map<String,Object> args
    * @return Object
    **/
    public Object call(String action, Map<String, Object> args) {
        switch on action {
            when 'recalculateUnits' {
                return recalculateUnits(args);
            }
            when 'recalculateCurrency' {
                return recalculateCurrency(args);
            }
            when 'invocableGroupStructurePS' {
                return invocableGroupStructurePS(args);
            }
            when 'rollback2021RTC' {
                return rollback2021RTC(args);
            }
            when 'sendNotifications'{
                return sendNotifications(args);
            }
            when else {
                throw new ExtensionMalformedCallException('Method not implemented!');
            }
        }
    }
    /**
    * @description ExtensionMalformedCallException
    **/
    public class ExtensionMalformedCallException extends Exception {}
    /**
    *-------------------------------------------------------------------------------
    * @description get map info that will be used to call buildFFSS method.
    *--------------------------------------------------------------------------------
    * @author  aleksandar.dinkov.contractor@bbva.com
    * @date    22/07/2024
    * @param Map<String, Object> mapInfo
    * @return Object
    */
    private String recalculateUnits(Map<String, Object> mapInfo) {
        return '{\\"state\\":\\"OK\\"}';
    }
    /**
    *-------------------------------------------------------------------------------
    * @description get map info that will be used to call buildFFSS method.
    *--------------------------------------------------------------------------------
    * @author  aleksandar.dinkov.contractor@bbva.com
    * @date    22/07/2024
    * @param Map<String, Object> mapInfo
    * @return Object
    */
    private String recalculateCurrency(Map<String, Object> mapInfo) {
        return '{\\"state\\":\\"OK\\"}';
    }
    /**
    *-------------------------------------------------------------------------------
    * @description get map info that will be used to call buildFFSS method.
    *--------------------------------------------------------------------------------
    * @author  isabel.ascaso.tech@bbva.com
    * @date   23/06/2025
    * @param Map<String, Object> mapInfo
    * @return Object
    */
    private String invocableGroupStructurePS(Map<String, Object> mapInfo) {
        return '{\\"state\\":\\"OK\\"}';
    }

    /**
    *-------------------------------------------------------------------------------
    * @description Rollback and delete the defined analysisId
    *--------------------------------------------------------------------------------
    * @author  francisco.munoz.torres.tech@bbva.com
    * @date    29/09/2025
    * @param Map<String, Object> mapInfo
    * @return Object
    */
    private String rollback2021RTC(Map<String, Object> mapInfo) {
        return null;
    }

    /**
    * @description Mock method sendNotifications
    * @param mapInfo with necessary information to send notifications
    * @return String with the result of the operation
    */
    private String sendNotifications(Map<String, Object> mapInfo) {
        return null;
    }
}