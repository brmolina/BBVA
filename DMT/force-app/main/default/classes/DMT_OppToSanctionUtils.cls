public with sharing class DMT_OppToSanctionUtils {

    @InvocableMethod(label='Create Risk Lines and Warranties')
    public static void createRiskLinesAndWarranties(List<OpportunityLineItemWrapper> wrappers) {
        System.debug(wrappers);
        // Listas para insertar
        List<DMT_Risk_Line_Term__c> riskLinesToInsert = new List<DMT_Risk_Line_Term__c>();
        List<DMT_Warranty__c> warrantiesToInsert = new List<DMT_Warranty__c>();
        Map<Id,DMT_Risk_Line_Term__c> mapIdOppToRisk = new Map<Id,DMT_Risk_Line_Term__c>();
        List<String> listIdOppLineItems = new List<String>();
        List<String> listIdProducts = new List<String>();

        for (OpportunityLineItemWrapper wrapper : wrappers) {
            for(OpportunityLineItem oli: wrapper.listOli){
                listIdProducts.add(oli.Product2Id);
            }
        }
        Map<Id,Product2> mapIdToProduct = DMT_Opportunity_Selector.getProduct2(listIdProducts);

        for (OpportunityLineItemWrapper wrapper : wrappers) {
            for(OpportunityLineItem oli: wrapper.listOli){
            
                // Crear un DMT_Risk_Line_Term__c por cada OpportunityLineItem
                DMT_Risk_Line_Term__c riskLine = new DMT_Risk_Line_Term__c();
                riskLine.DMT_Line__c = wrapper.idLine;
                riskLine.DMT_Product__c =  oli.Product2Id;
                riskLine.DMT_LastLevelId__c =  oli.DMT_Risk_Type__c;
                riskLine.DMT_Risk_Type__c =  oli.opportunity_risk_name__c;
                riskLine.DMT_Max_Date__c =  oli.gf_maturity_date__c;
                riskLine.g_global_product_id__c =  mapIdToProduct.get(oli.Product2Id).DMT_Global_Product_Id__c;
                riskLine.g_global_product_category_id__c =  mapIdToProduct.get(oli.Product2Id).DMT_Product_category__c;
                riskLine.g_global_product_family_id__c =  mapIdToProduct.get(oli.Product2Id).DMT_Product_family__c;
                riskLine.g_gbl_product_subcategory_id__c =  mapIdToProduct.get(oli.Product2Id).DMT_Product_Subcategory__c;
                riskLine.g_global_product_subfamily_id__c =  mapIdToProduct.get(oli.Product2Id).DMT_Product_Subfamily__c;
                riskLine.Name =  mapIdToProduct.get(oli.Product2Id).Name;
                riskLine.DMT_Comments__c =  oli.DMT_TXA_Comentarios__c;
                // Se añade traduccion para el campo de amortization Type
                if(oli.gf_amortization_type__c == 'Linear'){
                    riskLine.g_amortization_type__c = '3';
                }else if(oli.gf_amortization_type__c == 'Bullet'){
                    riskLine.g_amortization_type__c = '4';
                }else if(oli.gf_amortization_type__c == 'User-Defined'){
                    if(oli.DMT_balloon_amortization_indicator__c == true){
                        riskLine.g_amortization_type__c = '5';
                    }else if(oli.DMT_bullet_amortization_indicator__c == true){
                        riskLine.g_amortization_type__c = '4';
                    }else{
                        riskLine.g_amortization_type__c = '9';
                    }
                }

                // Agrega aquí los demás campos que necesites copiar o inicializar
                listIdOppLineItems.add(oli.Id);
                mapIdOppToRisk.put(oli.Id,riskLine);
                riskLinesToInsert.add(riskLine);
            }
           
        }
        
        if (!riskLinesToInsert.isEmpty()) {
            insert riskLinesToInsert;
            List<DMT_Opportunity_Mitigant__c> listMitigants = [SELECT Id,DMT_Opportunity_Product__c,Mitigant_Type__c, DMT_Opportunity_Product__r.ProductCode FROM DMT_Opportunity_Mitigant__c WHERE DMT_Opportunity_Product__c IN :listIdOppLineItems];
            // Crear DMT_Warranty__c por cada Risk Line creado
            for (DMT_Opportunity_Mitigant__c mitigant : listMitigants) {
                DMT_Warranty__c warranty = new DMT_Warranty__c();
                warranty.DMT_Risk_Line_Term__c = mapIdOppToRisk.get(mitigant.DMT_Opportunity_Product__c).Id;
                warranty.Name = mitigant.Mitigant_Type__c;
                warranty.gf_group_priority_line_id__c = mitigant.DMT_Opportunity_Product__r.ProductCode ;
                warranty.g_limits_grid_guarantee_type__c = 'O3';
                warranty.gf_origin_application_type__c = '04' ;
                // Agrega aquí los demás campos que necesites
                warrantiesToInsert.add(warranty);
            }
            
            if (!warrantiesToInsert.isEmpty()) {
                insert warrantiesToInsert;
            }
        }
    }
    
    // Wrapper para recibir OpportunityLineItem desde Flow
    public class OpportunityLineItemWrapper {
        @InvocableVariable(required=true)
        public List<OpportunityLineItem> listOli;
        @InvocableVariable(required=true)
        public String idLine;
    }
}