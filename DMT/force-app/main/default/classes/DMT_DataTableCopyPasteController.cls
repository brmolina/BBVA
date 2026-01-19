public with sharing class DMT_DataTableCopyPasteController {
    @AuraEnabled(cacheable=true)
    public static Map<String, Id> getUserIdsByUsernames(List<String> userNames) {
        Map<String, Id> result = new Map<String, Id>();

        for (User user : [SELECT Id, Username, Name FROM User WHERE Username IN :userNames WITH SECURITY_ENFORCED]) {
            result.put(user.Username, user.Id);
        }

        return result;
    }
}