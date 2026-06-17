/**
 * @description       : 
 * @author            : ChangeMeIn@UserSettingsUnder.SFDoc
 * @group             : 
 * @last modified on  : 08-08-2025
 * @last modified by  : ChangeMeIn@UserSettingsUnder.SFDoc
**/
trigger UserAmbitUpdate on UO_Management__c (after insert, after update) {
    List<User> ambitUsers = new List<User>();
    Set<String> userNames = new Set<String>();
    Map<String, String> mapUo = new Map<String, String>();
    List<User> recordsToUpdate = new List<User>();

    for (UO_Management__c a : Trigger.new){
        if (a.GDT_User_Name__c != null) {
            mapUo.put(a.GDT_User_Name__c, a.Ambit__c);
            userNames.add(a.GDT_User_Name__c);
        }
    }

    ambitUsers = [
        SELECT Id, Name, gf_user_operation_ambit_name__c
        FROM User
        WHERE Name IN :userNames
    ];

    for (User obj : ambitUsers ){
        obj.gf_user_operation_ambit_name__c = mapUo.get(obj.Name);
        recordsToUpdate.add(obj);
    }

    if (!recordsToUpdate.isEmpty()) {
        update recordsToUpdate;
    }
}