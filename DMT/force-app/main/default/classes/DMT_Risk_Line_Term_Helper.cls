// Helper class for DMT_Risk_Line_Term__c trigger logic
public with sharing class DMT_Risk_Line_Term_Helper {

    public static void updateLastModifiedByHuman(List<SObject> records) {
        DMT_HPG_Utils.updateLastModifiedByHuman(records);
    }

}