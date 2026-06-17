public with sharing class DMT_ProfitabilityAxisSelectorController {
    public class OptionDTO {
        @AuraEnabled public Id id;
        @AuraEnabled public String label;
        @AuraEnabled public String value;
        @AuraEnabled public String dataType;
    }

    public class ComboDTO {
        @AuraEnabled public Id xId;
        @AuraEnabled public Id yId;
        @AuraEnabled public Id centerId;
    }
    
    public class InitialOptionsResponse {
        @AuraEnabled public List<OptionDTO> xOptions = new List<OptionDTO>();
        @AuraEnabled public List<OptionDTO> yOptions = new List<OptionDTO>();
        @AuraEnabled public List<OptionDTO> centralOptions = new List<OptionDTO>();
        @AuraEnabled public List<ComboDTO> combinations = new List<ComboDTO>();
    }
    
    /**
     * Devuelve las opciones iniciales para los combobox X, Y y Central.
     * Incluye únicamente los DMT_Profitability_Axis__c que aparecen en alguna combinación:
     *  - en gf_x_axis_value_number__c para X
     *  - en gf_y_axis_value_number__c para Y
     *  - en gf_center_axis_value_number__c para Central
     */
    @AuraEnabled(cacheable=true)
    public static InitialOptionsResponse getInitialOptions() {
        InitialOptionsResponse res = new InitialOptionsResponse();
        
        // Traer combinaciones activas
        List<DMT_Profitability_Axis_Combination__c> combos = [
            SELECT gf_x_axis_value_number__c, gf_y_axis_value_number__c, gf_center_axis_value_number__c
            FROM DMT_Profitability_Axis_Combination__c
            WHERE g_active_ind_type__c = TRUE
        ];
        
        Set<Id> xIds = new Set<Id>();
        Set<Id> yIds = new Set<Id>();
        Set<Id> centerIds = new Set<Id>();
        Set<Id> allIds = new Set<Id>();
        
        for (DMT_Profitability_Axis_Combination__c c : combos) {
            if (c.gf_x_axis_value_number__c != null) {
                xIds.add(c.gf_x_axis_value_number__c);
                allIds.add(c.gf_x_axis_value_number__c);
            }
            if (c.gf_y_axis_value_number__c != null) {
                yIds.add(c.gf_y_axis_value_number__c);
                allIds.add(c.gf_y_axis_value_number__c);
            }
            if (c.gf_center_axis_value_number__c != null) {
                centerIds.add(c.gf_center_axis_value_number__c);
                allIds.add(c.gf_center_axis_value_number__c);
            }
        }
        
        if (!allIds.isEmpty()) {
            // Traer sólo axes activos que participan en combinaciones
            for (DMT_Profitability_Axis__c a : [
                SELECT Id, Name,gf_incremental_axis_type_number__c,gf_axis_data_type_desc__c,gf_percentage_1_sign_type__c,gf_data_type__c
                FROM DMT_Profitability_Axis__c
                WHERE Id IN :allIds AND g_active_ind_type__c = TRUE
                ORDER BY Name
            ]) {
                OptionDTO opt = new OptionDTO();
                opt.id = a.Id;
                opt.label = a.gf_axis_data_type_desc__c;
                opt.value = a.gf_incremental_axis_type_number__c;
                opt.dataType = a.gf_data_type__c;
                
                if (xIds.contains(a.Id)){
                    res.xOptions.add(opt);
                }
                if (yIds.contains(a.Id)){
                    res.yOptions.add(opt);
                }
                if (centerIds.contains(a.Id)){
                    res.centralOptions.add(opt);
                }
            }
            // also return the active combinations so the client can filter dependent selects
            for (DMT_Profitability_Axis_Combination__c c : combos) {
                ComboDTO cd = new ComboDTO();
                cd.xId = c.gf_x_axis_value_number__c;
                cd.yId = c.gf_y_axis_value_number__c;
                cd.centerId = c.gf_center_axis_value_number__c;
                res.combinations.add(cd);
            }
        }
        
        return res;
    }
}