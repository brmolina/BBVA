/*
* DMT Main Table Callable
* @author BBVA DMT
* @date 2024
*/

global with sharing class DMT_MainTableCallableClass {

    @AuraEnabled
    public static Object callExtension(String action,  String auxiliarClass, Map<String,Object> args) {
        try {
            Callable extension = (Callable) Type.forName(auxiliarClass).newInstance();
            Object res = extension.call(action, args);
            return res;
        } catch(Exception e){
            System.debug(e.getMessage());
            DES_Exception_Utils.logException(e,'DMT_MainTableCallableClass', 'callExtension', 'DMT', '');
            return e.getTypeName();
        }
    }

    @AuraEnabled(cacheable=true)
    public static Object callExtensionImperative(String action, String auxiliarClass, Map<String,Object> args) {system.debug('en call imp');
        return callExtension(action, auxiliarClass, args);
    }
}