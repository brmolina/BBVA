public with sharing class Util_PickList {

    private static Map<String, Map<String, String>> mapaApiLabel; // Label -> API Value
    private static Map<String, Map<String, String>> mapaLabelApi; // API Value -> Label

    /**
     * Retrieves the label for each picklist value of a given object field.
     *
     * @param objeto Name of the SObject.
     * @param campoDelObjeto Name of the field on the SObject.
     * @return Map of API value to label.
     */
    public static Map<String, String> getLabelFromAPI(String objeto, String campoDelObjeto) {
        Map<String, String> mapaLabel = new Map<String, String>();
        try {
            if (objeto != null && campoDelObjeto != null) {
                if (mapaLabelApi == null) {
                    mapaLabelApi = new Map<String, Map<String, String>>();
                }
                if (!mapaLabelApi.containsKey(campoDelObjeto)) {
                    DescribeSObjectResult objDescribe = Schema.getGlobalDescribe().get(objeto).getDescribe();
                    DescribeFieldResult campoDescribe = objDescribe.fields.getMap().get(campoDelObjeto).getDescribe();
                    for (Schema.PicklistEntry entry : campoDescribe.getPicklistValues()) {
                        mapaLabel.put(entry.getValue(), entry.getLabel());
                    }
                    mapaLabelApi.put(campoDelObjeto, mapaLabel);
                }
                mapaLabel = mapaLabelApi.get(campoDelObjeto);
            }
        } catch (Exception ex) {
            throw new AuraHandledException('Error in getLabelFromAPI: ' + ex.getMessage());
        }
        return mapaLabel;
    }

    /**
     * Retrieves the API value of a picklist given its label.
     *
     * @param objeto Name of the SObject.
     * @param campoDelObjeto Name of the field on the SObject.
     * @param valor The label to lookup.
     * @return The corresponding API value.
     */
    public static String getAPIFromLabel(String objeto, String campoDelObjeto, String valor) {
        String valorApi;
        try {
            if (objeto != null && campoDelObjeto != null && valor != null) {
                if (mapaApiLabel == null) {
                    mapaApiLabel = new Map<String, Map<String, String>>();
                }
                if (!mapaApiLabel.containsKey(campoDelObjeto)) {
                    Map<String, String> labelToApiMap = new Map<String, String>();
                    DescribeSObjectResult objDescribe = Schema.getGlobalDescribe().get(objeto).getDescribe();
                    DescribeFieldResult campoDescribe = objDescribe.fields.getMap().get(campoDelObjeto).getDescribe();
                    for (Schema.PicklistEntry entry : campoDescribe.getPicklistValues()) {
                        labelToApiMap.put(entry.getLabel(), entry.getValue());
                    }
                    mapaApiLabel.put(campoDelObjeto, labelToApiMap);
                }
                valorApi = mapaApiLabel.get(campoDelObjeto).get(valor);
            }
        } catch (Exception ex) {
            throw new AuraHandledException('Error in getAPIFromLabel: ' + ex.getMessage());
        }
        return valorApi;
    }

    /**
     * Retrieves filtered picklist options depending on segmentation rules.
     *
     * @param objObject SObject to describe.
     * @param fld Picklist field to analyze.
     * @param lookupObject Id of the Account to use for segmentation.
     * @return Map of Label -> Value pairs filtered according to segmentation.
     */
    @AuraEnabled
    public static Map<String, String> getselectOptions(SObject objObject, String fld, String lookupObject) {
        Map<String, String> allOpts = new Map<String, String>();
        try {
            String segmentation = '';
            List<Account> lAcc = [SELECT Id, DES_BBVA_Segmentation__c FROM Account WHERE Id = :lookupObject LIMIT 1];
            if (!lAcc.isEmpty()) {
                segmentation = lAcc[0].DES_BBVA_Segmentation__c;
            }

            Schema.sObjectType objType = objObject.getSObjectType();
            Schema.DescribeSObjectResult objDescribe = objType.getDescribe();
            Map<String, Schema.SObjectField> fieldMap = objDescribe.fields.getMap();
            List<Schema.PicklistEntry> values = fieldMap.get(fld).getDescribe().getPickListValues();

            for (Schema.PicklistEntry entry : values) {
                if (segmentation != null && segmentation != '' && segmentation == Label.DES_Segmentation_C_CIB) {
                    if (entry.getLabel() == Label.DES_ROLE_SECONDARY_GB) {
                        allOpts.put(entry.getLabel(), entry.getValue());
                    }
                } else {
                    if (entry.getLabel() == Label.DES_SCOPE_GLOBAL) {
                        allOpts.put(entry.getLabel(), entry.getValue());
                    }
                }
            }

        } catch (Exception ex) {
            throw new AuraHandledException('Error in getselectOptions: ' + ex.getMessage());
        }
        return allOpts;
    }
}