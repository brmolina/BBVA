/**
* @File Name          : Arc_Gen_CallableFromCore_Mock.cls
* @Description        : callable Mockup class for Arc_Gen_CallableFromCore.cls
* @Author             : aleksandar.dinkov.contractor@bbva.com
* @Group              : ARCE Team
* @Last Modified By   : aleksandar.dinkov.contractor@bbva.com
* @Last Modified On   : 22/07/2024
* @Changes
*========================================================================================
* Ver         Date                     Author                 Modification
*========================================================================================
* 1.0         22/07/2024    aleksandar.dinkov.contractor@bbva.com     Initial Version
**/
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
}