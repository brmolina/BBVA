/**
 * @description Handler optimizado para el trigger de DES_Template__c.
 *              Cambios principales:
 *              - Uso de TriggerCacheManager para evitar queries redundantes
 *              - Eliminación de queries dentro de bucles
 *              - Bulkificación de operaciones
 * @author Optimización de triggers - BBVA
 * @date 2024
 */
public without sharing class TemplateTriggerHandler {
    
    // Usar caché en lugar de query estática
    private static String getProfileName() {
        return TriggerCacheManager.getInstance().getCurrentUserProfileName();
    }

    /**
     * @description Actualiza el estado de pending approval en Opportunities relacionadas
     */
    public static void updateOpportunityPendApp(List<DES_Template__c> triggerNew, Map<Id, DES_Template__c> triggerOldMap) {
        Map<Id, Opportunity> opps = getOpps(triggerNew);
        List<Opportunity> oppsToUpdate = new List<Opportunity>();
        List<String> lTemplateTab = new List<String>();

        for (DES_Template__c templ : triggerNew) {
            DES_Template__c oldTempl = triggerOldMap.get(templ.Id);
            
            if (templ.Pending_approval_type__c != oldTempl.Pending_approval_type__c || 
                templ.Template_approved_type__c != oldTempl.Template_approved_type__c) {
                
                Opportunity aux = opps.get(templ.opportunity_id__c);
                if (aux != null) {
                    aux.Template_pending_approval_type__c = templ.Pending_approval_type__c;
                    aux.Template_approved_type__c = templ.Template_approved_type__c;

                    if (templ.Pending_approval_type__c == false && templ.Template_approved_type__c == false) {
                        clearOpportunityFields(aux);
                    }
                    oppsToUpdate.add(aux);
                }
            }
            lTemplateTab.add(templ.Id);
        }
        
        if (!oppsToUpdate.isEmpty()) {
            update oppsToUpdate;
        }

        if (!lTemplateTab.isEmpty()) {
            TemplateTableHandler.updateListTemplate(lTemplateTab);
        }
    }
    
    /**
     * @description Limpia campos de Opportunity cuando se resetea el template
     */
    private static void clearOpportunityFields(Opportunity aux) {
        aux.GCC_Attended_type__c = '';
        aux.GCC_Supportive_type__c = '';
        aux.gcc_participant_desc__c = '';
        aux.GF_Attended_type__c = '';
        aux.GF_Supportive_type__c = '';
        aux.gf_participant_desc__c = '';
        aux.GTB_Attended_type__c = '';
        aux.gtb_participant_desc__c = '';
        aux.GTB_Supportive_type__c = '';
        aux.Risk_Attended_type__c = '';
        aux.Risk_Supportive_type__c = '';
        aux.risk_participant_desc__c = '';
        aux.NBC_Decision_Taken_type__c = '';
        aux.NBC_decision_type__c = false;
        aux.Geography_CIB_Attended_type__c = '';
        aux.Geography_CIB_Supportive_type__c = '';
        aux.CIB_Geography_participant__c = '';
        aux.x_sell_committee_type__c = false;
        aux.StageName = 'Proposal';
    }

    /**
     * @description Corrige el texto de campos para PDF - OPTIMIZADO
     *              Ahora usa caché para Custom Metadata y RecordTypes
     */
    public static void corregirTextoPdf(List<DES_Template__c> triggerNew) {
        //Solo procesar si viene 1 registro
        if (triggerNew.size() != 1 && !Test.isRunningTest()) {
            return;
        }
        
        // Usar caché para Custom Metadata
        TriggerCacheManager cache = TriggerCacheManager.getInstance();
        List<WVL_ActivateConfigPdfTemplate__mdt> lstActivate = cache.getActivateConfigPdfTemplate();

        // Solo procesar si hay configuración activa
        if (lstActivate.isEmpty()) {
            return;
        }
        
        DES_Template__c templ = triggerNew[0];
        
        // Validar fecha de activación (lógica original)
        if (!Test.isRunningTest() && lstActivate[0].ActivateDate__c > templ.CreatedDate) {
            return;
        }
        
        // Obtener nombre del RecordType desde caché (sin query SOQL)
        String strRecordtypeName = cache.getRecordTypeDevName('DES_Template__c', templ.RecordTypeId);
        
        // Corregir campos de texto
        corregirCamposTexto(templ);
        
        // Validar usando datos cacheados
        validarTexto(templ, strRecordtypeName, cache.getConfigPdfTemplate());
        validarLongitud(templ, strRecordtypeName, cache.getConfigTextLimitTemplate());
    }
        
    /**
     * @description Corrige los campos de texto del template
     */
    private static void corregirCamposTexto(DES_Template__c templ) {
        // Template_CSL
        templ.Purpose_desc__c = corregirTexto(templ.Purpose_desc__c);
        templ.Rating_Scenarios_desc__c = corregirTexto(templ.Rating_Scenarios_desc__c);
        templ.Other_Relevant_Issues_desc__c = corregirTexto(templ.Other_Relevant_Issues_desc__c);
        templ.Main_characteristics_desc__c = corregirTexto(templ.Main_characteristics_desc__c);
        templ.History_of_the_deal_desc__c = corregirTexto(templ.History_of_the_deal_desc__c);
        templ.Security_Package_desc__c = corregirTexto(templ.Security_Package_desc__c);
        templ.Competition_For_the_Deal_desc__c = corregirTexto(templ.Competition_For_the_Deal_desc__c);
        templ.Other_Relevant_Ratios_desc__c = corregirTexto(templ.Other_Relevant_Ratios_desc__c);
        templ.Geographical_Footprint_desc__c = corregirTexto(templ.Geographical_Footprint_desc__c);
        templ.Relationship_Status_desc__c = corregirTexto(templ.Relationship_Status_desc__c);
        templ.Industry_Overview_desc__c = corregirTexto(templ.Industry_Overview_desc__c);
        templ.Qual_Assessment_of_Estimate_Revenue_desc__c = corregirTexto(templ.Qual_Assessment_of_Estimate_Revenue_desc__c);
        
        // Template_PF
        templ.Other_Relevant_Information_desc__c = corregirTexto(templ.Other_Relevant_Information_desc__c);
        templ.Qualitative_Assesment_of_X_Sell_Rev_desc__c = corregirTexto(templ.Qualitative_Assesment_of_X_Sell_Rev_desc__c);
        templ.Main_Performance_Indicators_desc__c = corregirTexto(templ.Main_Performance_Indicators_desc__c);
    }

    /**
     * @description Valida el número máximo de líneas por cada texto - OPTIMIZADO
     *              Ahora recibe los datos de configuración como parámetro
     */
    public static void validarTexto(DES_Template__c templ, String recordtype, List<WVL_ConfigPdfTemplate__mdt> lstConfigTemplate) {
        for (WVL_ConfigPdfTemplate__mdt config : lstConfigTemplate) {
            Integer intMaximoLineas = Integer.valueOf(config.get(recordtype + '__c'));
            Integer intMaxCarLinea = Integer.valueOf(config.WVL_fld_NumMaxCaracteresLinea__c);
            
            Object fieldValue = templ.get(config.WVL_fld_NombreCampo__c);
            if (fieldValue == null) {
                continue;
            }
            
            String valorCampo = String.valueOf(fieldValue);
            String[] arrTest = valorCampo.split('\n');
            Integer intNumLienasTexto = arrTest.size();
            
            for (String parrafo : arrTest) {
                Integer intCaracteres = parrafo.length();
                Integer intLineas = intCaracteres / intMaxCarLinea;
                intNumLienasTexto += intLineas;
            }
            
            if (intNumLienasTexto > intMaximoLineas) {
                String fieldLabel = Schema.getGlobalDescribe()
                    .get('DES_Template__c')
                    .getDescribe()
                    .fields.getMap()
                    .get(config.WVL_fld_NombreCampo__c)
                    .getDescribe()
                    .getLabel();
                templ.addError(System.Label.WVL_lbl_TemplateTgrError + '[' + fieldLabel + ']');
            }
        }
    }

    /**
     * @description Valida el número máximo de caracteres - OPTIMIZADO
     */
    public static void validarLongitud(DES_Template__c templ, String recordtype, List<WVL_ConfigTextLimitTemplate__mdt> lstConfigTemplate) {
        for (WVL_ConfigTextLimitTemplate__mdt config : lstConfigTemplate) {
            Integer intMaxLength = Integer.valueOf(config.get(recordtype + '__c'));
            
            if (intMaxLength == 0) {
                continue;
            }
            
            Object fieldValue = templ.get(config.WVL_fld_NombreCampo__c);
            if (fieldValue == null) {
                continue;
            }
            
            String valorCampo = String.valueOf(fieldValue);
            if (valorCampo.length() > intMaxLength) {
                String fieldLabel = Schema.getGlobalDescribe()
                    .get('DES_Template__c')
                    .getDescribe()
                    .fields.getMap()
                    .get(config.WVL_fld_NombreCampo__c)
                    .getDescribe()
                    .getLabel();
                templ.addError(fieldLabel + ' (max ' + intMaxLength + ' characters)');
            }
        }
    }

    /**
     * @description Corrige el texto para PDF
     */
    public static String corregirTexto(String campo) {
        if (campo == null) {
            return null;
        }
        
        String cad = campo;
        
        // Eliminar espacios dobles
        while (cad.indexOf('  ') != -1) {
            cad = cad.replace('  ', ' ');
        }
        
        cad = cad.replace('\r', '');
        cad = cad.replace('.\n\n', '@PARRAFSALTO@');
        cad = cad.replace('.\n', '@PARRAF@');
        cad = cad.replace('. \n', '@PARRAF@');
        cad = cad.replace('\n', ' ');
        cad = cad.replace('@PARRAF@', '.\n');
        cad = cad.replace('@PARRAFSALTO@', '.\n\n');
        
        return cad;
    }

    /**
     * @description Pone pending a false cuando se elimina template
     */
    public static void oppPendingToFalse(List<DES_Template__c> triggerOld) {
        Map<Id, Opportunity> opps = getOpps(triggerOld);
        
        for (DES_Template__c templ : triggerOld) {
            Opportunity aux = opps.get(templ.opportunity_id__c);
            if (aux != null) {
                aux.Template_pending_approval_type__c = false;
                opps.put(aux.Id, aux);
            }
        }
        
        if (!opps.isEmpty()) {
            update opps.values();
        }
    }

    /**
     * @description Obtiene las Opportunities relacionadas - método centralizado
     */
    private static Map<Id, Opportunity> getOpps(List<DES_Template__c> listTemplates) {
        Set<Id> oppsId = new Set<Id>();
        for (DES_Template__c templ : listTemplates) {
            if (templ.opportunity_id__c != null) {
                oppsId.add(templ.opportunity_id__c);
            }
        }
        
        if (oppsId.isEmpty()) {
            return new Map<Id, Opportunity>();
        }
        
        return new Map<Id, Opportunity>([
            SELECT Id, Template_pending_approval_type__c, Template_approved_type__c 
            FROM Opportunity 
            WHERE Id IN :oppsId
        ]);
    }

    /**
     * @description Crea registros de Template Table
     */
    public static void searchTableTemplate(List<DES_Template__c> listTemplates) {
        List<DES_Template_Table__c> lTabTempl = new List<DES_Template_Table__c>();

        for (DES_Template__c tmp : listTemplates) {
            DES_Template_Table__c tabTempl = new DES_Template_Table__c();
            tabTempl.Parent_Template__c = tmp.Id;
            
            // PAWIF fields
            tabTempl.PAWIF_Simulation_Id__c = tmp.PAWIF_Simulation_Id__c;
            tabTempl.PAWIF_Simulation_URL__c = tmp.PAWIF_Simulation_URL__c;
            
            // ESG fields
            tabTempl.gf_paris_agreement_ind_type__c = tmp.gf_paris_agreement_ind_type__c;
            tabTempl.gf_esg_score_close_ope_name__c = tmp.gf_esg_score_close_ope_name__c;
            tabTempl.gf_co_list_tcfd_ind_type__c = tmp.gf_co_list_tcfd_ind_type__c;
            tabTempl.gf_customer_sustnbl_strg_desc__c = tmp.gf_customer_sustnbl_strg_desc__c;
            tabTempl.Reputational_Risk_type__c = tmp.Reputational_Risk_type__c;
            tabTempl.cstk_tri_engagement_plan__c = tmp.cstk_tri_engagement_plan__c;
            tabTempl.cstk_positioning__c = tmp.cstk_positioning__c;
            tabTempl.cstk_group_alignment_degree__c = tmp.cstk_group_alignment_degree__c;
            tabTempl.cstk_sector_alignment_degree__c = tmp.cstk_sector_alignment_degree__c;
            tabTempl.cstk_emissions_intensity_units__c = tmp.cstk_emissions_intensity_units__c;
            tabTempl.cstk_sust_indicators_comments__c = tmp.cstk_sust_indicators_comments__c;
            tabTempl.Sectorial_Norms_type__c = tmp.Sectorial_Norms_type__c;
            
            // Thermal coal fields
            tabTempl.cstk_g_thermal_coal_exps_ind_type__c = tmp.cstk_g_thermal_coal_exps_ind_type__c;
            tabTempl.cstk_g_thermal_coal_exps_i_src_type__c = tmp.cstk_g_thermal_coal_exps_i_src_type__c;
            tabTempl.cstk_g_coal_prgrsv_red_pl_ind_type__c = tmp.cstk_g_coal_prgrsv_red_pl_ind_type__c;
            tabTempl.cstk_gf_thermal_coal_rev_wg_per__c = tmp.cstk_gf_thermal_coal_rev_wg_per__c;
            tabTempl.cstk_gf_thermal_coal_prod_wg_per__c = tmp.cstk_gf_thermal_coal_prod_wg_per__c;

            lTabTempl.add(tabTempl);
        }
        
        if (!lTabTempl.isEmpty()) {
            insert lTabTempl;
        }
    }

    /**
     * @description Completa el campo Industry_AA_type__c - OPTIMIZADO
     */
    public static void completeIndustry(List<DES_Template__c> triggerNew) {
        // Recoger IDs de Opportunities
        Set<Id> oppsId = new Set<Id>();
        Map<Id, Id> templOpp = new Map<Id, Id>();
        
        for (DES_Template__c templ : triggerNew) {
            if (templ.opportunity_id__c != null) {
                oppsId.add(templ.opportunity_id__c);
                templOpp.put(templ.Id, templ.opportunity_id__c);
            }
        }
        
        if (oppsId.isEmpty()) {
            return;
        }
        
        // Una sola query para todas las Opportunities
        Map<Id, Opportunity> mapOpps = new Map<Id, Opportunity>([
            SELECT Id, AccountId, Account.DES_AGGR_Sector__c
            FROM Opportunity
            WHERE Id IN :oppsId
        ]);
        
        // Obtener labels del picklist una sola vez
        Map<String, String> sectorLabels = Util_PickList.getLabelFromAPI('Account', 'DES_AGGR_Sector__c');

        for (DES_Template__c templ : triggerNew) {
            Id oppId = templOpp.get(templ.Id);
            if (oppId != null && mapOpps.containsKey(oppId)) {
                Opportunity opp = mapOpps.get(oppId);
                if (opp.Account != null && opp.Account.DES_AGGR_Sector__c != null) {
                    templ.Industry_AA_type__c = sectorLabels.get(opp.Account.DES_AGGR_Sector__c);
                }
            }
        }
    }

    /**
     * @description Marca si el cliente es Prospect - OPTIMIZADO
     */
    public static void isProspectClient(List<DES_Template__c> triggerNew) {
        Set<Id> oppsId = new Set<Id>();
        Map<Id, Id> templOpp = new Map<Id, Id>();
        
        for (DES_Template__c templ : triggerNew) {
            if (templ.opportunity_id__c != null) {
                oppsId.add(templ.opportunity_id__c);
                templOpp.put(templ.Id, templ.opportunity_id__c);
            }
        }
        
        if (oppsId.isEmpty()) {
            return;
        }
        
        Map<Id, Opportunity> mapOpps = new Map<Id, Opportunity>([
            SELECT Id, AccountId, Account.gf_cust_orig_prospect_ind_type__c
            FROM Opportunity
            WHERE Id IN :oppsId
        ]);

        for (DES_Template__c templ : triggerNew) {
            Id oppId = templOpp.get(templ.Id);
            if (oppId != null && mapOpps.containsKey(oppId)) {
                Opportunity opp = mapOpps.get(oppId);
                if (opp.Account != null) {
                    templ.DES_Prospect_Client__c = opp.Account.gf_cust_orig_prospect_ind_type__c;
                }
            }
        }
    }

    /**
     * @description Valida permisos para editar Industry - OPTIMIZADO
     */
    public static void checkIndustryEdit(List<DES_Template__c> triggerNew, Map<Id, DES_Template__c> triggerOldMap) {
        // Filtrar solo los que han cambiado Industry_AA_type__c
        List<DES_Template__c> templatesWithChangedIndustry = new List<DES_Template__c>();
        Set<Id> oppsId = new Set<Id>();
        
        for (DES_Template__c templ : triggerNew) {
            if (templ.Industry_AA_type__c != triggerOldMap.get(templ.Id).Industry_AA_type__c) {
                templatesWithChangedIndustry.add(templ);
                if (templ.opportunity_id__c != null) {
                    oppsId.add(templ.opportunity_id__c);
                }
            }
        }
        
        if (templatesWithChangedIndustry.isEmpty()) {
            return;
        }
        
        // Usar caché para obtener el profile name y S&P users
        TriggerCacheManager cache = TriggerCacheManager.getInstance();
        String profileName = cache.getCurrentUserProfileName();
        
        // Si es Admin o Integration, permitir todo
        if (profileName == Label.DES_ADMIN_PROFILE || profileName == Label.DES_INTEGRATION_PROFILE) {
            return;
        }
        
        // Obtener miembros permitidos
        Map<Id, String> oppMembers = auxFillMembers(oppsId, cache.getSPUserIds());
        
        for (DES_Template__c templ : templatesWithChangedIndustry) {
            String allowedUsers = oppMembers.get(templ.opportunity_id__c);
            if (allowedUsers != null && !allowedUsers.contains(UserInfo.getUserId())) {
                templ.addError(Label.Error_Edit_Industry);
            }
        }
    }

    /**
     * @description Construye mapa de miembros permitidos - OPTIMIZADO
     */
    private static Map<Id, String> auxFillMembers(Set<Id> oppsId, Set<Id> spUserIds) {
        Map<Id, String> oppMembers = new Map<Id, String>();
        
        if (oppsId.isEmpty()) {
            return oppMembers;
        }
        
        // Una sola query para todos los miembros
        for (DES_Opportunity_Management_member__c oppMemb : [
            SELECT Id, DES_User__c, DES_Opportunity__c, DES_Opportunity__r.OwnerId 
            FROM DES_Opportunity_Management_member__c 
            WHERE DES_Opportunity__c IN :oppsId
        ]) {
            String cadenaUsers = oppMembers.get(oppMemb.DES_Opportunity__c);
            if (cadenaUsers == null) {
                cadenaUsers = oppMemb.DES_Opportunity__r.OwnerId;
            }
            if (!cadenaUsers.contains(oppMemb.DES_User__c)) {
                cadenaUsers += '//' + oppMemb.DES_User__c;
            }
            oppMembers.put(oppMemb.DES_Opportunity__c, cadenaUsers);
        }
        
        // Añadir usuarios S&P a todas las oportunidades
        String spUsersString = '';
        for (Id spUserId : spUserIds) {
            spUsersString += '//' + spUserId;
        }
        
        for (Id oppId : oppMembers.keySet()) {
            oppMembers.put(oppId, oppMembers.get(oppId) + spUsersString);
        }
        
        return oppMembers;
    }

    /**
     * @description Completa el campo Booking_label__c - OPTIMIZADO
     */
    public static void completeBooking(List<DES_Template__c> triggerNew) {
        Set<Id> oppsIds = new Set<Id>();
        
        for (DES_Template__c templ : triggerNew) {
            if (templ.opportunity_id__c != null) {
                oppsIds.add(templ.opportunity_id__c);
            }
        }
        
        if (oppsIds.isEmpty()) {
            return;
        }
        
        Map<Id, Opportunity> mapOpps = new Map<Id, Opportunity>([
            SELECT Id, DES_Booking_Geography__c 
            FROM Opportunity 
            WHERE Id IN :oppsIds
        ]);
        
        // Obtener labels una sola vez
        Map<String, String> bookingLabels = Util_PickList.getLabelFromAPI('Opportunity', 'DES_Booking_Geography__c');

        for (DES_Template__c templ : triggerNew) {
            if (templ.opportunity_id__c != null && mapOpps.containsKey(templ.opportunity_id__c)) {
                String bookingGeo = mapOpps.get(templ.opportunity_id__c).DES_Booking_Geography__c;
                if (bookingGeo != null) {
                    templ.Booking_label__c = bookingLabels.get(bookingGeo);
                }
            }
        }
    }

    /**
     * @description Crea Chatter NBC Virtual
     */
    public static void createChatter(List<DES_Template__c> triggerNew) {
        if (triggerNew.isEmpty()) {
            return;
        }
        
        List<Chatter_NBC_Virtual__c> lstChat = new List<Chatter_NBC_Virtual__c>();
        
        for (DES_Template__c template : triggerNew) {
            Chatter_NBC_Virtual__c chat = new Chatter_NBC_Virtual__c();
            chat.id_objeto__c = template.Id;
            chat.tipo_objeto__c = 'DES_Template__c';
            lstChat.add(chat);
        }
        
        if (!lstChat.isEmpty()) {
            insert lstChat;
        }
    }

    /**
     * @description Elimina Chatter NBC Virtual
     */
    public static void deleteChatter(List<DES_Template__c> triggerOld) {
        Set<Id> templateIds = new Set<Id>();
        for (DES_Template__c templ : triggerOld) {
            templateIds.add(templ.Id);
        }
        
        if (templateIds.isEmpty()) {
            return;
        }
        
        List<Chatter_NBC_Virtual__c> lstChatter = [
            SELECT Id 
            FROM Chatter_NBC_Virtual__c 
            WHERE id_objeto__c IN :templateIds
        ];
        
        if (!lstChatter.isEmpty()) {
            delete lstChatter;
        }
    }
}