/**
 * Line helper class contains logic related with lines, for example methods used en line trigger
 */
public with sharing class DMT_Line_Helper{
    Map<String, String> mapEntify = getEntify();
    public void createConsolidatedLine(List<DMT_Line__c> newLines, Map<Id, DMT_Line__c> mapLines, Map<Id, DMT_Line__c> mapOldLines){


        final List<DMT_Consolidated_Line__c> cLines = new List<DMT_Consolidated_Line__c>();
        final List<String> producCodeSearch = new List<String>{ DMT_Constants.PRODUCT_DERI, DMT_Constants.PRODUCT_DEPO, DMT_Constants.PRODUCT_EQUI, DMT_Constants.PRODUCT_REPO };

        //TODO: querys only needed for treasury lines but avoid include in for loop.
        Map<Id, List<DMT_Risk_Line_Term__c>> mapRskltByIdLine = getRiskLineTermByLine(mapLines, true, false);
        Map<Id, List<DMT_Risk_Line_Term__c>> mapRskltByIdLineSingular = getRiskLineTermByLine(mapLines, true, true);
        Map<Id, List<DMT_Risk_Line_Term__c>> mapRskltByIdLineNonTreasury = getRiskLineTermByLine(mapLines, false, false);

        Map<Id, List<DMT_Line_Product_Item__c>> mapPliByIdLine = getLineProductItemsByLine(mapLines);
        Map<String, Product2> mapProdByProdCod = getProductsByCode(producCodeSearch);
        final Map<Id, User> mapCorporateUByIdLine = getCorporateUsersOwnLines(mapLines);
        List<DMT_Consolidated_Line__c> prevCLines = new List<DMT_Consolidated_Line__c>();
        Map<String, List<DMT_Consolidated_Line__c>> mapClines = getpreviousConsoLines(mapLines);
        //Iterate trigger lines
        for (DMT_Line__c line : newLines){
            //Integer for generate sub id for consolidated lines.
            Integer idPriorityLine = 1;

            if ((line.Status__c == DMT_Constants.APPROVAL || (line.Status__c == DMT_Constants.CLOSED && line.Closed__c == DMT_Constants.WON) || (line.Status__c == DMT_Constants.CLOSED && line.Closed__c == 'Lost') || (line.Status__c == DMT_Constants.DRAFT && line.DMT_Approval_Date__c != null) || (line.Status__c == DMT_Constants.PROPOSAL && line.DMT_Approval_Date__c != null)) && mapOldLines.get(line.Id).Status__c != line.Status__c || mapOldLines.get(line.Id).DMT_Update_Singular__c != line.DMT_Update_Singular__c || (line.Status__c == DMT_Constants.CLOSED && line.Closed__c == DMT_Constants.WON) || (mapOldLines.get(line.Id).DMT_Approval_Date__c != null && mapOldLines.get(line.Id).DMT_Approval_Date__c != line.DMT_Approval_Date__c)){

                if (mapClines != null && mapClines.get(line.Line_Id__c) != null){
                    prevCLines.addAll(mapClines.get(line.Line_Id__c));
                }

                if (line.Product__c == 'Treasury Line' || line.Product__c == 'Sanction' || line.Product__c == 'Line (Other Products)'){

                    DMT_Consolidated_Line__c initcLineHeader = mapCommonFields(line, mapCorporateUByIdLine.get(line.OwnerId).ID_User__c);
                    initcLineHeader.gf_group_priority_line_id__c = '00';

                    initcLineHeader.CurrencyIsoCode = line.CurrencyIsoCode;
                    initcLineHeader.g_currency_id__c = line.CurrencyIsoCode;
                    initcLineHeader.gf_additional_comments_desc__c = line.DMT_Comments__c?.left(500);

                    initcLineHeader.status__c = line.DMT_Status_Completed__c;
                    initcLineHeader.Origin__c = line.DMT_Approval_Validation__c ? 'Salesforce' : 'XX';
                    if (line.Product__c == 'Sanction' || line.Product__c == 'Line (Other Products)'){
                        initcLineHeader.g_limit_last_level_type__c = line.DMT_LastLevelId__c;
                        initcLineHeader.gf_clsfn_risk_type_internal_id__c = line.DMT_LastLevelId__c;
                        initcLineHeader.gf_condition_line_amount__c = line.Amount__c;
                    } else{
                        initcLineHeader.g_limit_last_level_type__c = '';
                        initcLineHeader.gf_clsfn_risk_type_internal_id__c = '';
                        initcLineHeader.gf_additional_comments_desc__c = line.DMT_Comments__c?.left(500);
                        initcLineHeader.g_isda_waiver_ind_type__c = false;
                        initcLineHeader.gf_break_cl_dt_freq_number__c = null;
                        initcLineHeader.gf_break_clause_date__c = null;
                        //initcLineHeader.gf_condition_line_amount__c = line.Amount__c;
                    }
                    cLines.add(initcLineHeader);


                    if (line.DvP_Amount__c != null){
                        DMT_Consolidated_Line__c initcLineDvP = mapCommonFields(line, mapCorporateUByIdLine.get(line.OwnerId).ID_User__c);
                        if (line.DMT_SingularCon__c >= Date.today()) {
                            Decimal singularDVP = line.DvP_Amount__c;
                            List<DMT_Risk_Line_Term__c> relatedRiskDVP = DMT_Passport_Selector.getSingularRisk(line.Id);
                            for ( DMT_Risk_Line_Term__c risk : relatedRiskDVP) {
                                if ( risk.DMT_Singular__c && risk.DMT_Max_Date__c >= Date.today()  && singularDVP != null && risk.DMT_Singular_DvP__c != null) {
                                    singularDVP = singularDVP + risk.DMT_Singular_DvP__c;
                                }
                            }
                            initcLineDvP.gf_condition_line_amount__c = singularDVP;
                        } else {
                            initcLineDvP.gf_condition_line_amount__c = line.DvP_Amount__c;
                        }

                        initcLineDvP.gf_group_priority_line_id__c = DMT_Constants.GROUP_PRIORITY_DVP;
                        initcLineDvP.gf_clsfn_risk_type_internal_id__c = DMT_Constants.RSK_LVL_SETTLEMENT_DVP;
                        initcLineDvP.g_limit_last_level_type__c = DMT_Constants.RSK_LVL_SETTLEMENT_DVP;
                        initcLineDvP.status__c = line.DMT_Status_Completed__c;
                        initcLineDvP.Origin__c = line.DMT_Approval_Validation__c ? 'Salesforce' : 'XX';
                        idPriorityLine++;

                        cLines.add(initcLineDvP);

                    }

                    if (line.FD_Amount__c != null){
                        DMT_Consolidated_Line__c initcLineFD = mapCommonFields(line, mapCorporateUByIdLine.get(line.OwnerId).ID_User__c);

                        if (line.DMT_SingularCon__c >= Date.today()) {
                            Decimal singularFD = line.FD_Amount__c;
                            List<DMT_Risk_Line_Term__c> relatedRiskFD = DMT_Passport_Selector.getSingularRisk(line.Id);
                            for ( DMT_Risk_Line_Term__c risk : relatedRiskFD) {
                                if ( risk.DMT_Singular__c && risk.DMT_Max_Date__c >= Date.today() && singularFD != null && risk.DMT_Singular_FD__c != null) {
                                    singularFD = singularFD + risk.DMT_Singular_FD__c;
                                }
                            }
                            initcLineFD.gf_condition_line_amount__c = singularFD;
                        } else {
                            initcLineFD.gf_condition_line_amount__c = line.FD_Amount__c;
                        }
                        initcLineFD.gf_group_priority_line_id__c = DMT_Constants.GROUP_PRIORITY_FD;
                        initcLineFD.gf_clsfn_risk_type_internal_id__c = DMT_Constants.RSK_LVL_SETTLEMENT_FD;
                        initcLineFD.g_limit_last_level_type__c = DMT_Constants.RSK_LVL_SETTLEMENT_FD;
                        initcLineFD.status__c = line.DMT_Status_Completed__c;
                        initcLineFD.Origin__c = line.DMT_Approval_Validation__c ? 'Salesforce' : 'XX';
                        idPriorityLine++;
                        cLines.add(initcLineFD);
                    }
                    if (line.Repos_Limit__c != null){

                        DMT_Consolidated_Line__c initcLineRepos = mapCommonFields(line, mapCorporateUByIdLine.get(line.OwnerId).ID_User__c);
                        initcLineRepos.gf_condition_line_amount__c = line.Repos_Limit__c;

                        initcLineRepos.g_global_product_family_id__c = mapProdByProdCod.get('Repo') != null ? mapProdByProdCod.get('Repo').DMT_Product_family__c : '1600000000';
                        initcLineRepos.g_global_product_subfamily_id__c = mapProdByProdCod.get('Repo') != null ? mapProdByProdCod.get('Repo').DMT_Product_Subfamily__c : '1611000000';
                        initcLineRepos.g_global_product_category_id__c = mapProdByProdCod.get('Repo') != null ? mapProdByProdCod.get('Repo').DMT_Product_category__c : '1611190000';
                        initcLineRepos.g_gbl_product_subcategory_id__c = mapProdByProdCod.get('Repo') != null ? mapProdByProdCod.get('Repo').DMT_Product_Subcategory__c : '';
                        initcLineRepos.g_global_product_id__c = mapProdByProdCod.get('Repo') != null ? mapProdByProdCod.get('Repo').DMT_Global_Product_Id__c : '';
                        initcLineRepos.status__c = line.DMT_Status_Completed__c;
                        initcLineRepos.Origin__c = line.DMT_Approval_Validation__c ? 'Salesforce' : 'XX';

                        //initcLineRepos.gf_period_from_line_day_number__c = 0; // null not 0
                        initcLineRepos.gf_group_priority_line_id__c = DMT_Constants.GROUP_PRIORITY_REPOS;
                        idPriorityLine++;

                        cLines.add(initcLineRepos);

                    }

                    if (line.Repos_Limit_6M__c != null){

                        DMT_Consolidated_Line__c initcLineReposLessSixMonth = mapCommonFields(line, mapCorporateUByIdLine.get(line.OwnerId).ID_User__c);

                        initcLineReposLessSixMonth.gf_condition_line_amount__c = line.Repos_Limit_6M__c;
                        initcLineReposLessSixMonth.gf_period_until_line_day_number__c = 6 * 30;

                        initcLineReposLessSixMonth.g_global_product_family_id__c = mapProdByProdCod.get('Repo') != null ? mapProdByProdCod.get('Repo').DMT_Product_family__c : '1600000000';
                        initcLineReposLessSixMonth.g_global_product_subfamily_id__c = mapProdByProdCod.get('Repo') != null ? mapProdByProdCod.get('Repo').DMT_Product_Subfamily__c : '1611000000';
                        initcLineReposLessSixMonth.g_global_product_category_id__c = mapProdByProdCod.get('Repo') != null ? mapProdByProdCod.get('Repo').DMT_Product_category__c : '1611190000';
                        initcLineReposLessSixMonth.g_gbl_product_subcategory_id__c = mapProdByProdCod.get('Repo') != null ? mapProdByProdCod.get('Repo').DMT_Product_Subcategory__c : '';
                        initcLineReposLessSixMonth.g_global_product_id__c = mapProdByProdCod.get('Repo') != null ? mapProdByProdCod.get('Repo').DMT_Global_Product_Id__c : '';
                        initcLineReposLessSixMonth.status__c = line.DMT_Status_Completed__c;
                        initcLineReposLessSixMonth.Origin__c = line.DMT_Approval_Validation__c ? 'Salesforce' : 'XX';

                        //initcLineReposLessSixMonth.gf_period_from_line_day_number__c = 0; // null not 0
                        initcLineReposLessSixMonth.gf_group_priority_line_id__c = DMT_Constants.GROUP_PRIORITY_REPOSNOFLOW;
                        idPriorityLine++;
                        cLines.add(initcLineReposLessSixMonth);
                    }

                    //Iterate risk line term generating new consolidated line for each iteam
                    Boolean treasuryRisk = mapRskltByIdLine != null && !mapRskltByIdLine.isEmpty() && mapRskltByIdLine.get(line.Id) != null && !mapRskltByIdLine.get(line.Id).isEmpty();
                    Boolean treasurySingularRisk = mapRskltByIdLineSingular != null && !mapRskltByIdLineSingular.isEmpty() && mapRskltByIdLineSingular.get(line.Id) != null && !mapRskltByIdLineSingular.get(line.Id).isEmpty();
                    Boolean nontreasuryRisk = mapRskltByIdLineNonTreasury != null && !mapRskltByIdLineNonTreasury.isEmpty() && mapRskltByIdLineNonTreasury.get(line.Id) != null && !mapRskltByIdLineNonTreasury.get(line.Id).isEmpty();
                    if (treasuryRisk || treasurySingularRisk || nontreasuryRisk){
                        Integer idRiskLine = 1;
                        List<DMT_Risk_Line_Term__c> relatedRisk = new List<DMT_Risk_Line_Term__c>();
                        if (line.Product__c == 'Treasury Line'){
                            if (line.DMT_SingularCon__c >= Date.today()){
                                List<List<DMT_Risk_Line_Term__c>> singularList = new List<List<DMT_Risk_Line_Term__c>>();
                                relatedRisk = mapRskltByIdLineSingular.get(line.Id);
                            } else{
                                relatedRisk = mapRskltByIdLine.get(line.Id);
                            }
                        } else{
                            relatedRisk = mapRskltByIdLineNonTreasury.get(line.Id);
                        }
                        if (relatedRisk != null){
                            for (DMT_Risk_Line_Term__c rsk : relatedRisk){
                                if (line.Product__c == 'Treasury Line'){

                                    DMT_Consolidated_Line__c initcLineRsk = mapCommonFields(line, mapCorporateUByIdLine.get(line.OwnerId).ID_User__c);

                                    initcLineRsk.g_global_product_family_id__c = !String.isBlank(mapProdByProdCod.get(rsk.DMT_Risk_Type__c).DMT_Product_family__c) ? mapProdByProdCod.get(rsk.DMT_Risk_Type__c).DMT_Product_family__c : rsk.g_global_product_family_id__c;
                                    initcLineRsk.g_global_product_subfamily_id__c = !String.isBlank(mapProdByProdCod.get(rsk.DMT_Risk_Type__c).DMT_Product_Subfamily__c) ? mapProdByProdCod.get(rsk.DMT_Risk_Type__c).DMT_Product_Subfamily__c : rsk.g_global_product_subfamily_id__c;
                                    initcLineRsk.g_global_product_category_id__c = !String.isBlank(mapProdByProdCod.get(rsk.DMT_Risk_Type__c).DMT_Product_category__c) ? mapProdByProdCod.get(rsk.DMT_Risk_Type__c).DMT_Product_category__c : rsk.g_global_product_category_id__c;
                                    initcLineRsk.g_gbl_product_subcategory_id__c = !String.isBlank(mapProdByProdCod.get(rsk.DMT_Risk_Type__c).DMT_Product_Subcategory__c) ? mapProdByProdCod.get(rsk.DMT_Risk_Type__c).DMT_Product_Subcategory__c : rsk.g_gbl_product_subcategory_id__c;
                                    initcLineRsk.g_global_product_id__c = !String.isBlank(mapProdByProdCod.get(rsk.DMT_Risk_Type__c).DMT_Global_Product_Id__c) ? mapProdByProdCod.get(rsk.DMT_Risk_Type__c).DMT_Global_Product_Id__c : rsk.g_global_product_id__c;
                                    // initcLineRsk.g_global_product_subfamily_id__c = mapProdByProdCod.get(rsk.DMT_Risk_Type__c).DMT_Product_Subfamily__c;
                                    // initcLineRsk.g_global_product_category_id__c = mapProdByProdCod.get(rsk.DMT_Risk_Type__c).DMT_Product_category__c;
                                    // initcLineRsk.g_gbl_product_subcategory_id__c = mapProdByProdCod.get(rsk.DMT_Risk_Type__c).DMT_Product_Subcategory__c;
                                    // initcLineRsk.g_global_product_id__c = mapProdByProdCod.get(rsk.DMT_Risk_Type__c).DMT_Global_Product_Id__c;
                                    initcLineRsk.Origin__c = line.DMT_Approval_Validation__c ? 'Salesforce' : 'XX';
                                    initcLineRsk.gf_period_from_line_day_number__c = rsk.DMT_Init_Term__c != null ? Decimal.valueOf(rsk.DMT_Init_Term__c) : null;
                                    initcLineRsk.gf_period_until_line_day_number__c = rsk.DMT_End_Term__c != null ? Decimal.valueOf(rsk.DMT_End_Term__c) : null;
                                    initcLineRsk.status__c = line.DMT_Status_Completed__c;
                                    initcLineRsk.gf_condition_line_amount__c = rsk.DMT_Amount__c;
                                    initcLineRsk.gf_group_priority_line_id__c = DMT_Constants.GROUP_PRIORITY_TERM + 'o' + String.valueOf('0' + idRiskLine).right(2);
                                    initcLineRsk.g_limit_last_level_type__c = DMT_Constants.RSK_LVL_TREASURY;
                                    initcLineRsk.gf_inscol_months_grace_number__c = rsk.gf_inscol_months_grace_number__c;
                                    initcLineRsk.gf_loan_value_per__c = rsk.gf_loan_value_per__c;
                                    initcLineRsk.g_notary_crtfn_ind_type__c = rsk.g_notary_crtfn_ind_type__c;
                                    initcLineRsk.g_gtee_public_adm_ind_type__c = rsk.g_gtee_public_adm_ind_type__c;
                                    initcLineRsk.gf_loan_eca_cntrb_per__c = rsk.gf_loan_eca_cntrb_per__c;
                                    initcLineRsk.gf_min_raroec_fcg_per__c = rsk.gf_min_raroec_fcg_per__c;
                                    initcLineRsk.gf_min_raroec_wo_fcg_per__c = rsk.gf_min_raroec_wo_fcg_per__c;
                                    initcLineRsk.gf_min_rorc_fcg_per__c = rsk.gf_min_rorc_fcg_per__c;
                                    initcLineRsk.gf_min_rorc_wo_fcg_per__c = rsk.gf_min_rorc_wo_fcg_per__c;
                                    //initcLineRsk.g_isda_waiver_ind_type__c = rsk.g_isda_waiver_ind_type__c;
                                    initcLineRsk.gf_prev_renewal_group_line_id__c = rsk.DMT_Parent_Product__r.gf_group_priority_line_id__c;
                                    initcLineRsk.gf_revolvence_pd_days_number__c = rsk.gf_revolvence_pd_days_number__c;
                                    initcLineRsk.gf_break_cl_days_number__c = rsk.gf_break_cl_days_number__c;
                                    initcLineRsk.g_expert_criteria_risk_type__c = rsk.DMT_Risk_Type__c == 'Equities' ? 'WWRX' : '';

                                    idRiskLine++;
                                    cLines.add(initcLineRsk);
                                } else{
                                    DMT_Consolidated_Line__c initcLineRsk = mapCommonFields(line, mapCorporateUByIdLine.get(line.OwnerId).ID_User__c);
                                    if (line.Product__c == 'Sanction'){
                                        initcLineRsk.g_amortization_type__c = rsk.g_amortization_type__c;
                                    }
                                    initcLineRsk.g_global_product_family_id__c = rsk.g_global_product_family_id__c;
                                    initcLineRsk.g_line_name_desc__c = rsk.Name?.left(50);
                                    initcLineRsk.g_global_product_subfamily_id__c = rsk.g_global_product_subfamily_id__c;
                                    initcLineRsk.g_global_product_category_id__c = rsk.g_global_product_category_id__c;
                                    initcLineRsk.g_gbl_product_subcategory_id__c = rsk.g_gbl_product_subcategory_id__c;
                                    initcLineRsk.g_global_product_id__c = rsk.g_global_product_id__c;
                                    initcLineRsk.Origin__c = line.DMT_Approval_Validation__c ? 'Salesforce' : 'XX';
                                    if (rsk.DMT_Init_Term__c != null){
                                        initcLineRsk.gf_period_from_line_day_number__c = Decimal.valueOf(rsk.DMT_Init_Term__c);
                                    }
                                    if (rsk.DMT_End_Term__c != null){
                                        initcLineRsk.gf_period_until_line_day_number__c = Decimal.valueOf(rsk.DMT_End_Term__c);
                                    }
                                    initcLineRsk.gf_clsfn_risk_type_internal_id__c = rsk.DMT_LastLevelId__c;
                                    initcLineRsk.g_limit_last_level_type__c = rsk.DMT_LastLevelId__c;
                                    initcLineRsk.status__c = line.DMT_Status_Completed__c;
                                    initcLineRsk.gf_condition_line_amount__c = rsk.DMT_Amount__c;
                                    initcLineRsk.gf_additional_comments_desc__c = !String.isBlank(rsk.DMT_Comments__c) ? rsk.DMT_Comments__c?.left(500) : line.DMT_Comments__c?.left(500);
                                    //initcLineRsk.gf_group_priority_line_id__c = mapRskltByIdLine.get(line.Id).size() > 1 && line.Product__c == 'Sanction' ? '01' + 'o' + String.valueOf('0' + idRiskLine).right(2) : (mapRskltByIdLine.get(line.Id).size() == 1 && line.Product__c == 'Sanction' ? '01' : DMT_Constants.GROUP_PRIORITY_TERM + 'o' + String.valueOf('0' + idRiskLine).right(2));
                                    initcLineRsk.gf_group_priority_line_id__c = !String.isBlank(rsk.gf_group_priority_line_id__c) ? rsk.gf_group_priority_line_id__c : String.valueOf('0' + idRiskLine).right(2);
                                    initcLineRsk.g_limit_last_level_type__c = rsk.DMT_LastLevelId__c;
                                    initcLineRsk.gf_inscol_months_grace_number__c = rsk.gf_inscol_months_grace_number__c;
                                    initcLineRsk.gf_loan_value_per__c = rsk.gf_loan_value_per__c;
                                    initcLineRsk.g_notary_crtfn_ind_type__c = rsk.g_notary_crtfn_ind_type__c;
                                    initcLineRsk.g_gtee_public_adm_ind_type__c = rsk.g_gtee_public_adm_ind_type__c;
                                    initcLineRsk.gf_loan_eca_cntrb_per__c = rsk.gf_loan_eca_cntrb_per__c;
                                    initcLineRsk.gf_min_raroec_fcg_per__c = rsk.gf_min_raroec_fcg_per__c;
                                    initcLineRsk.gf_min_raroec_wo_fcg_per__c = rsk.gf_min_raroec_wo_fcg_per__c;
                                    initcLineRsk.gf_min_rorc_fcg_per__c = rsk.gf_min_rorc_fcg_per__c;
                                    initcLineRsk.gf_min_rorc_wo_fcg_per__c = rsk.gf_min_rorc_wo_fcg_per__c;
                                    //initcLineRsk.g_isda_waiver_ind_type__c = rsk.g_isda_waiver_ind_type__c;
                                    initcLineRsk.gf_prev_renewal_group_line_id__c =line.DMT_Parent_Code_Form__c;
                                    initcLineRsk.gf_revolvence_pd_days_number__c = rsk.gf_revolvence_pd_days_number__c;
                                    initcLineRsk.gf_break_cl_days_number__c = rsk.gf_break_cl_days_number__c;
                                    initcLineRsk.g_multioperation_ind_type__c = rsk.g_multioperation_ind_type__c;
                                    initcLineRsk.g_line_cond_guarantee_ind_type__c = rsk.g_line_cond_guarantee_ind_type__c;
                                    initcLineRsk.g_bullet_ind_type__c = rsk.g_bullet_ind_type__c;
                                    initcLineRsk.g_smscl_internal_ratg_type__c = rsk.g_smscl_internal_ratg_type__c;
                                    initcLineRsk.g_limit_sinds_ast_sctr_id__c = rsk.g_limit_sinds_ast_sctr_id__c;
                                    initcLineRsk.g_limit_sinds_ast_subsec_id__c = rsk.g_limit_sinds_ast_subsec_id__c;
                                    initcLineRsk.g_booking_geo_type__c = rsk.g_branch_id__c?.left(9);
                                    initcLineRsk.g_expert_criteria_risk_type__c = rsk.g_expert_criteria_risk_type__c;
                                    initcLineRsk.CurrencyIsoCode = rsk.CurrencyIsoCode;
                                    initcLineRsk.gf_prev_renewal_priority_line_id__c = rsk.DMT_Parent_Product__r.gf_group_priority_line_id__c;
                                    //Change maded for CIBGLOBALD-1497
                                    if (rsk.DMT_Amount__c != null){
                                        initcLineRsk.g_currency_id__c = rsk.CurrencyIsoCode;
                                    }
                                    idRiskLine++;
                                    cLines.add(initcLineRsk);
                                }
                            }
                        }
                    }

                    //Iterate Line product item, for each lpi create a new one consolidated line

                    Integer idPriorityProductLine = 1;
                    Integer idPriorityProductLineFD = 1;
                    Integer idPriorityProductLineDVP = 1;
                    if (mapPliByIdLine != null && !mapPliByIdLine.isEmpty() && mapPliByIdLine.get(line.Id) != null && !mapPliByIdLine.get(line.Id).isEmpty()){

                        for (DMT_Line_Product_Item__c pli : mapPliByIdLine.get(line.Id)){

                            // initcLinePli.g_clearing_house_type__c = pli.Max_Tenor_WC__c != null ? 'Y' : 'N';
                            if (pli.DMT_DerivativeRestriction__c){
                                DMT_Consolidated_Line__c initcLinePliWCDeri = mapCommonFields(line, mapCorporateUByIdLine.get(line.OwnerId).ID_User__c);
                                initcLinePliWCDeri.g_global_product_family_id__c = pli.Product__r.DMT_Product_family__c;
                                initcLinePliWCDeri.g_global_product_subfamily_id__c = pli.Product__r.DMT_Product_Subfamily__c;
                                initcLinePliWCDeri.g_global_product_category_id__c = pli.Product__r.DMT_Product_category__c;
                                initcLinePliWCDeri.g_gbl_product_subcategory_id__c = pli.Product__r.DMT_Product_Subcategory__c;
                                initcLinePliWCDeri.g_global_product_id__c = pli.Product__r.DMT_Global_Product_Id__c;
                                initcLinePliWCDeri.g_expert_criteria_risk_type__c = pli.Product_Code_Value__c;
                                //initcLinePliWCDeri.g_clearing_house_type__c = 'Y';
                                initcLinePliWCDeri.status__c = line.DMT_Status_Completed__c;
                                initcLinePliWCDeri.Origin__c = line.DMT_Approval_Validation__c ? 'Salesforce' : 'XX';

                                initcLinePliWCDeri.gf_clsfn_risk_type_internal_id__c = DMT_Constants.RSK_LVL_TREASURY;
                                initcLinePliWCDeri.g_limit_last_level_type__c = DMT_Constants.RSK_LVL_TREASURY;
                                //Hay que crear una cdLine pro clering o no

                                if (!String.isBlank(pli.Max_Tenor_WC__c)){
                                    initcLinePliWCDeri.gf_period_from_line_day_number__c = 0;
                                    initcLinePliWCDeri.gf_period_until_line_day_number__c = Decimal.valueOf(pli.Max_Tenor_WC__c);
                                }

                                initcLinePliWCDeri.gf_group_priority_line_id__c = DMT_Constants.GROUP_PRIORITY_RESTRIC + 'o' + String.valueOf('0' + idPriorityProductLine).right(2);
                                idPriorityProductLine++;
                                cLines.add(initcLinePliWCDeri);

                            }
                            if (pli.DMT_DVPRestriction__c){
                                DMT_Consolidated_Line__c initcLinePliWCDVP = mapCommonFields(line, mapCorporateUByIdLine.get(line.OwnerId).ID_User__c);
                                initcLinePliWCDVP.g_global_product_family_id__c = pli.Product__r.DMT_Product_family__c;
                                initcLinePliWCDVP.g_global_product_subfamily_id__c = pli.Product__r.DMT_Product_Subfamily__c;
                                initcLinePliWCDVP.g_global_product_category_id__c = pli.Product__r.DMT_Product_category__c;
                                initcLinePliWCDVP.g_gbl_product_subcategory_id__c = pli.Product__r.DMT_Product_Subcategory__c;
                                initcLinePliWCDVP.g_global_product_id__c = pli.Product__r.DMT_Global_Product_Id__c;
                                initcLinePliWCDVP.g_expert_criteria_risk_type__c = pli.Product_Code_Value__c;
                                //initcLinePliWCDVP.g_clearing_house_type__c = 'Y';
                                initcLinePliWCDVP.status__c = line.DMT_Status_Completed__c;
                                initcLinePliWCDVP.Origin__c = line.DMT_Approval_Validation__c ? 'Salesforce' : 'XX';

                                initcLinePliWCDVP.gf_clsfn_risk_type_internal_id__c = DMT_Constants.RSK_LVL_SETTLEMENT_DVP;
                                initcLinePliWCDVP.g_limit_last_level_type__c = DMT_Constants.RSK_LVL_SETTLEMENT_DVP;
                                //Hay que crear una cdLine pro clering o no
                                //  initcLinePliWCDVP.gf_period_from_line_day_number__c = 0;
                                //  initcLinePliWCDVP.gf_period_until_line_day_number__c = Decimal.valueOf(pli.Max_Tenor_WC__c);
                                initcLinePliWCDVP.gf_group_priority_line_id__c = DMT_Constants.GROUP_PRIORITY_RESTRIC_DVP + 'o' + String.valueOf('0' + idPriorityProductLineDVP).right(2);
                                idPriorityProductLineDVP++;
                                cLines.add(initcLinePliWCDVP);

                            }
                            if (pli.DMT_FDRestriction__c){
                                DMT_Consolidated_Line__c initcLinePliWCFD = mapCommonFields(line, mapCorporateUByIdLine.get(line.OwnerId).ID_User__c);
                                initcLinePliWCFD.g_global_product_family_id__c = pli.Product__r.DMT_Product_family__c;
                                initcLinePliWCFD.g_global_product_subfamily_id__c = pli.Product__r.DMT_Product_Subfamily__c;
                                initcLinePliWCFD.g_global_product_category_id__c = pli.Product__r.DMT_Product_category__c;
                                initcLinePliWCFD.g_gbl_product_subcategory_id__c = pli.Product__r.DMT_Product_Subcategory__c;
                                initcLinePliWCFD.g_global_product_id__c = pli.Product__r.DMT_Global_Product_Id__c;
                                initcLinePliWCFD.g_expert_criteria_risk_type__c = pli.Product_Code_Value__c;
                                //initcLinePliWCFD.g_clearing_house_type__c = 'Y';
                                initcLinePliWCFD.status__c = line.DMT_Status_Completed__c;
                                initcLinePliWCFD.Origin__c = line.DMT_Approval_Validation__c ? 'Salesforce' : 'XX';

                                initcLinePliWCFD.gf_clsfn_risk_type_internal_id__c = DMT_Constants.RSK_LVL_SETTLEMENT_FD;
                                initcLinePliWCFD.g_limit_last_level_type__c = DMT_Constants.RSK_LVL_SETTLEMENT_FD;
                                //  //Hay que crear una cdLine pro clering o no
                                //  initcLinePliWCFD.gf_period_from_line_day_number__c = 0;
                                //  initcLinePliWCFD.gf_period_until_line_day_number__c = Decimal.valueOf(pli.Max_Tenor_WC__c);
                                initcLinePliWCFD.gf_group_priority_line_id__c = DMT_Constants.GROUP_PRIORITY_RESTRIC_FD + 'o' + String.valueOf('0' + idPriorityProductLineFD).right(2);
                                idPriorityProductLineFD++;
                                cLines.add(initcLinePliWCFD);
                            }
                        }
                    }
                }

            }
        }
        try{
            System.debug('num' + cLines.size());
            if (cLines.size() > 0){
                Boolean allNone = newLines.size() == 1 ? true : false;
                Database.insert (cLines, allNone);
            }
            if (prevCLines.size() > 0){
                delete prevCLines;
            }

        } catch (DmlException e){
            System.debug(e.getMessage());
        }
    }

    /**
     * This method complete de common info for consolidated lines, with the common line info
     */
    public DMT_Consolidated_Line__c mapCommonFields(DMT_Line__c line, String corporateUserId){
        DMT_Consolidated_Line__c initLine = new DMT_Consolidated_Line__c();

        //All lines
        initLine.gf_additional_comments_desc__c = line.DMT_Comments__c?.left(500);
        initLine.gf_from_date__c = line.Start_Date__c;
        initLine.gf_to_date__c = line.End_Date__c;
        initLine.g_currency_id__c = line.CurrencyIsoCode;
        initLine.CurrencyIsoCode = line.CurrencyIsoCode;
        //cLine.gf_condition_line_amount__c = line.Amount__c;
        initLine.line_id__c = line.Line_Id__c;
        initLine.g_corporate_user_id__c = line.DMT_Origin__c != 'Salesforce' ? line.DMT_ID_User__c?.left(7) : corporateUserId?.left(7);
        initLine.g_entific_id__c = line.Booking_Geography__c != null ? line.Booking_Geography__c : 'HO';
        initLine.gf_group_line_id__c = line.Line_Id__c;
        initLine.g_acm_amount_limit_ind_type__c = 'Y';
        initLine.g_risk_level_clsfn_type__c = line.Product__c == 'Sanction' ? 'O' : 'L'; //L indicando que es una linea
        //initLine.DMT_Parent_Line__c = line.DMT_Parent_Code_Form__c;
        initLine.local_risk_analyst_name__c = line.DMT_Local_Risk_Analyst__c;
        initLine.global_risk_analyst_name__c = line.DMT_Global_Risk_Analyst__c;
        initLine.global_manager__c = line.DMT_Global_Manager__c;
        initLine.global_risk_analyst__c = line.DMT_Global_Risk_Analyst_User__c;
        initLine.local_risk_analyst__c = line.DMT_Local_Risk_Analyst_User__c;
        //initLine.DMT_Additional_Restrictions__c = line.DMT_Additional_Restrictions__c;
        initLine.g_line_status_type__c = line.DMT_line_status_type__c;
        initLine.g_line_template_type__c = line.DMT_line_template_type__c;
        initLine.gf_origin_application_type__c = line.DMT_Approval_Validation__c ? '04' : 'XX';
        initLine.gf_prev_renewal_group_line_id__c = line.DMT_Parent_Code_Form__c;
        initLine.DMT_Additional_Restrictions__c = line.DMT_Additional_Restrictions__c != 'null' ? line.DMT_Additional_Restrictions__c : '';
        initLine.Origin__c = line.DMT_Approval_Validation__c ? 'Salesforce' : 'XX';
        initLine.g_entity_id__c = line.DMT_Entity__c;
        initLine.g_line_name_desc__c = line.Name?.left(50);
        initLine.g_line_commitment_level_type__c = line.Product__c == 'Treasury Line' ? 'UNC' : line.g_line_commitment_level_type__c;

        //initLine.client_id__c = line.Client_Code__c;
        initLine.status__c = DMT_Constants.ACTIVE;
        //initLine.g_entity_id__c = line.Booking_Geography__c;

        if (line.Client_Type__c == 'Customer'){
            initLine.client_id__c = line.Client_Code__c;
            initLine.g_customer_id__c = line.Client_Code__c;
            initLine.gf_global_desktop_lm_engine_cust_type_id__c = DMT_Constants.CLIENT;
            initLine.client_type__c = DMT_Constants.CLIENT;
        } else if (line.Client_Type__c == 'Group'){
            initLine.client_id__c = line.Client_Code__c;
            initLine.g_holding_group_id__c = line.Client_Code__c;
            initLine.gf_global_desktop_lm_engine_cust_type_id__c = DMT_Constants.GROUP_CLIENT;
            initLine.client_type__c = DMT_Constants.GROUP_CLIENT;
        } else if (line.Client_Type__c == 'Custom'){
            initLine.client_id__c = line.line_id__c;
            //initLine.gf_customer_group_id__c = line.line_id__c;
            initLine.gf_global_desktop_lm_engine_cust_type_id__c = DMT_Constants.CUSTOM;
            initLine.client_type__c = DMT_Constants.CUSTOM;
        } else{
            initLine.client_id__c = line.Client_Code__c;
            initLine.g_customer_id__c = line.Client_Code__c;
            initLine.gf_global_desktop_lm_engine_cust_type_id__c = DMT_Constants.CLIENT;
            initLine.client_type__c = DMT_Constants.CLIENT;
        }

        //Treasury Lines
        if (line.Product__c == 'Treasury Line'){
            initLine.Waiver__c = line.Waiver__c;
            initLine.g_isda_waiver_ind_type__c = line.Waiver__c;
            initLine.gf_break_cl_dt_freq_number__c = line.Breakclause_Frequency__c != null ? Decimal.valueOf(line.Breakclause_Frequency__c) : null;
            initLine.gf_break_clause_date__c = line.First_Breakclause_Date__c;
            initLine.gf_clsfn_risk_type_internal_id__c = DMT_Constants.RSK_LVL_TREASURY;
            initLine.g_limit_last_level_type__c = DMT_Constants.RSK_LVL_TREASURY;
        }

        return initLine;
    }

    public Map<Id, USer> getCorporateUsersOwnLines(Map<ID, DMT_Line__c> mapnewLines){

        Set<Id> setOwnerLines = new Set<Id>();

        for (DMT_Line__c line : mapnewLines.values()){
            if (line.OwnerId != null){
                setOwnerLines.add(line.OwnerId);
            }
        }

        Map<Id, User> mapCorporateUser = new Map<Id, User>([SELECT Id, ID_User__c
                                                            from User
                                                            where Id = :setOwnerLines]);

        return mapCorporateUser;
    }

    /**
     * Get products by product code and return in Map string - product
     */
    public Map<String, Product2> getProductsByCode(List<String> productCodes){
        Map<String, Product2> mapReturn = new Map<String, Product2>();

        List<Product2> listProduct = [SELECT DMT_Global_Product_Id__c, DMT_Product_Subcategory__c, DMT_Product_Subfamily__c, DMT_Product_category__c, DMT_Product_family__c, Description, Id, Name, ProductCode
                                      FROM Product2
                                      WHERE ProductCode IN:productCodes AND family = 'DMT Lines'
                                      limit 10000];

        if (listProduct != null && !listProduct.isEmpty()){
            for (Product2 p : listProduct){
                switch  on p.ProductCode{
                    when '1600000000'{
                        mapReturn.put('Derivatives', p);
                        mapReturn.put('Singular', p);
                    }
                    when '1611170000'{
                        mapReturn.put('Depos', p);
                    }
                    when '1610000000'{
                        mapReturn.put('Equities', p);
                    }
                    when '1611190000'{
                        mapReturn.put('Repo', p);
                    }
                }
            }
        }


        return mapReturn;
    }

    /**
     * Return map of Risk Line term items list for each line
     */
    public Map<Id, List<DMT_Risk_Line_Term__c>> getRiskLineTermByLine(Map<Id, DMT_Line__c> mapLinesRsk, Boolean treasuryLine, Boolean singular){

        Map<Id, List<DMT_Risk_Line_Term__c>> mapRskltReturn = new Map<Id, List<DMT_Risk_Line_Term__c>>();
        List<DMT_Risk_Line_Term__c> rskltList = new List<DMT_Risk_Line_Term__c>();
        if (treasuryLine){
            if (singular){
                rskltList = [SELECT CurrencyIsoCode, g_amortization_type__c, DMT_Parent_Product__r.gf_group_priority_line_id__c, DMT_Comments__c, DMT_Amount__c, DMT_End_Term__c, DMT_Init_Term__c, DMT_Line__c, DMT_Risk_Type__c, Id, Name, g_global_product_family_id__c, g_global_product_subfamily_id__c, g_gbl_product_subcategory_id__c, g_global_product_category_id__c, g_global_product_id__c, DMT_LastLevelId__c, g_limit_last_level_type__c, gf_inscol_months_grace_number__c, gf_loan_value_per__c, g_notary_crtfn_ind_type__c, g_gtee_public_adm_ind_type__c, gf_loan_eca_cntrb_per__c, gf_min_raroec_fcg_per__c, gf_min_rorc_fcg_per__c, gf_min_rorc_wo_fcg_per__c, g_isda_waiver_ind_type__c, gf_prev_renewal_group_line_id__c, gf_revolvence_pd_days_number__c, gf_break_cl_days_number__c, g_multioperation_ind_type__c, gf_min_raroec_wo_fcg_per__c, gf_group_priority_line_id__c, g_line_cond_guarantee_ind_type__c, g_bullet_ind_type__c, g_smscl_internal_ratg_type__c, g_limit_sinds_ast_sctr_id__c, g_limit_sinds_ast_subsec_id__c, g_branch_id__c, DMT_Parent_Product__c, DMT_Singular__c, DMT_Singular_Active__c, DMT_Max_Date__c, g_expert_criteria_risk_type__c
                             FROM DMT_Risk_Line_Term__c
                             WHERE DMT_Line__c IN:mapLinesRsk.keySet() AND DMT_Amount__c != null AND (DMT_Risk_Type__c = :DMT_Constants.RSK_SINGULAR OR DMT_Risk_Type__c = :DMT_Constants.RSK_DEPOS OR DMT_Risk_Type__c = :DMT_Constants.RSK_EQUITY)
                             WITH SECURITY_ENFORCED
                             limit 10000];
            } else{
                rskltList = [SELECT CurrencyIsoCode, g_amortization_type__c, DMT_Parent_Product__r.gf_group_priority_line_id__c, DMT_Comments__c, DMT_Amount__c, DMT_End_Term__c, DMT_Init_Term__c, DMT_Line__c, DMT_Risk_Type__c, Id, Name, g_global_product_family_id__c, g_global_product_subfamily_id__c, g_gbl_product_subcategory_id__c, g_global_product_category_id__c, g_global_product_id__c, DMT_LastLevelId__c, g_limit_last_level_type__c, gf_inscol_months_grace_number__c, gf_loan_value_per__c, g_notary_crtfn_ind_type__c, g_gtee_public_adm_ind_type__c, gf_loan_eca_cntrb_per__c, gf_min_raroec_fcg_per__c, gf_min_rorc_fcg_per__c, gf_min_rorc_wo_fcg_per__c, g_isda_waiver_ind_type__c, gf_prev_renewal_group_line_id__c, gf_revolvence_pd_days_number__c, gf_break_cl_days_number__c, g_multioperation_ind_type__c, gf_min_raroec_wo_fcg_per__c, gf_group_priority_line_id__c, g_line_cond_guarantee_ind_type__c, g_bullet_ind_type__c, g_smscl_internal_ratg_type__c, g_limit_sinds_ast_sctr_id__c, g_limit_sinds_ast_subsec_id__c, g_branch_id__c, DMT_Parent_Product__c, DMT_Singular__c, DMT_Singular_Active__c, DMT_Max_Date__c, g_expert_criteria_risk_type__c
                             FROM DMT_Risk_Line_Term__c
                             WHERE DMT_Line__c IN:mapLinesRsk.keySet() AND DMT_Amount__c != null AND DMT_Singular__c = false AND (DMT_Risk_Type__c = :DMT_Constants.RSK_DERIVATIVES OR DMT_Risk_Type__c = :DMT_Constants.RSK_DEPOS OR DMT_Risk_Type__c = :DMT_Constants.RSK_EQUITY)
                             WITH SECURITY_ENFORCED
                             limit 10000];
            }
        } else{
            rskltList = [SELECT CurrencyIsoCode, g_amortization_type__c, DMT_Parent_Product__r.gf_group_priority_line_id__c, DMT_Comments__c, DMT_Amount__c, DMT_End_Term__c, DMT_Init_Term__c, DMT_Line__c, DMT_Risk_Type__c, Id, Name, g_global_product_family_id__c, g_global_product_subfamily_id__c, g_gbl_product_subcategory_id__c, g_global_product_category_id__c, g_global_product_id__c, DMT_LastLevelId__c, g_limit_last_level_type__c, gf_inscol_months_grace_number__c, gf_loan_value_per__c, g_notary_crtfn_ind_type__c, g_gtee_public_adm_ind_type__c, gf_loan_eca_cntrb_per__c, gf_min_raroec_fcg_per__c, gf_min_rorc_fcg_per__c, gf_min_rorc_wo_fcg_per__c, g_isda_waiver_ind_type__c, gf_prev_renewal_group_line_id__c, gf_revolvence_pd_days_number__c, gf_break_cl_days_number__c, g_multioperation_ind_type__c, gf_min_raroec_wo_fcg_per__c, gf_group_priority_line_id__c, g_line_cond_guarantee_ind_type__c, g_bullet_ind_type__c, g_smscl_internal_ratg_type__c, g_limit_sinds_ast_sctr_id__c, g_limit_sinds_ast_subsec_id__c, g_branch_id__c, DMT_Parent_Product__c, DMT_Singular__c, DMT_Singular_Active__c, g_expert_criteria_risk_type__c
                         FROM DMT_Risk_Line_Term__c
                         WHERE DMT_Line__c IN:mapLinesRsk.keySet()
                         WITH SECURITY_ENFORCED
                         limit 10000];
        }

        for (DMT_Risk_Line_Term__c rskItem : rskltList){
            if (mapRskltReturn.containsKey(rskItem.DMT_Line__c)){
                mapRskltReturn.get(rskItem.DMT_Line__c).add(rskItem);
            } else{
                mapRskltReturn.put(rskItem.DMT_Line__c, new List<DMT_Risk_Line_Term__c>{ rskItem });
            }
        }
        return mapRskltReturn;
    }

    public Map<String, String> getEntify(){
        Map<String, String> mapReturn = new Map<String, String>();
        for (DMT_Entity__c e : [SELECT Id, g_entity_id__c, gf_entity_id__c
                                FROM DMT_Entity__c
                                WITH SECURITY_ENFORCED
                                ORDER BY CreatedDate ASC
                                limit 10000]){
            mapReturn.put(e.g_entity_id__c, e.gf_entity_id__c);
        }

        return mapReturn;
    }

    /**
     * Return map of productLines items list for each line
     */
    public Map<Id, List<DMT_Line_Product_Item__c>> getLineProductItemsByLine(Map<Id, DMT_Line__c> mapLinesP){

        Map<Id, List<DMT_Line_Product_Item__c>> mapPLRReturn = new Map<Id, List<DMT_Line_Product_Item__c>>();
        List<DMT_Line_Product_Item__c> pliList = [SELECT CurrencyIsoCode, Max_Tenor_WC__c, Max_Tenor_WOC__c, Product__c, Id, Name, Product__r.ProductCode, Product__r.DMT_Product_family__c, Line__c, Product__r.DMT_Product_Subfamily__c, Product__r.DMT_Product_category__c, Product__r.DMT_Product_Subcategory__c, Product__r.DMT_Global_Product_Id__c, DMT_DerivativeRestriction__c, DMT_FDRestriction__c, DMT_DVPRestriction__c, Product_Code_Value__c
                                                  FROM DMT_Line_Product_Item__c
                                                  WHERE Line__c IN:mapLinesP.keySet()
                                                  WITH SECURITY_ENFORCED
                                                  limit 10000];

        for (DMT_Line_Product_Item__c pliItem : pliList){
            if (mapPLRReturn.containsKey(pliItem.Line__c)){
                mapPLRReturn.get(pliItem.Line__c).add(pliItem);
            } else{
                mapPLRReturn.put(pliItem.Line__c, new List<DMT_Line_Product_Item__c>{ pliItem });
            }
        }

        return mapPLRReturn;
    }

    public Map<String, List<DMT_Consolidated_Line__c>> getpreviousConsoLines(Map<Id, DMT_Line__c> mapLinesC){
        Map<String, DMT_Line__c> lineIdMap = new Map<String, DMT_Line__c>();
        for (Id key : mapLinesC.keySet()){
            lineIdMap.put(mapLinesC.get(key).Line_Id__c, mapLinesC.get(key));
        }

        Map<String, List<DMT_Consolidated_Line__c>> mapcLineReturn = new Map<String, List<DMT_Consolidated_Line__c>>();
        List<DMT_Consolidated_Line__c> cLines = [SELECT Id, gf_group_line_id__c
                                                 FROM DMT_Consolidated_Line__c
                                                 WHERE gf_group_line_id__c IN:lineIdMap.keySet()
                                                 WITH SECURITY_ENFORCED
                                                 LIMIT 10000];

        for (DMT_Consolidated_Line__c cLine : cLines){
            if (mapcLineReturn.containsKey(cLine.gf_group_line_id__c)){
                mapcLineReturn.get(cLine.gf_group_line_id__c).add(cLine);
            } else{
                mapcLineReturn.put(cLine.gf_group_line_id__c, new List<DMT_Consolidated_Line__c>{ cLine });
            }

        }
        return mapcLineReturn;
    }

    //before insert
    public void fillFields(List<DMT_Line__c> newLines){
        System.debug('fillFields before insert');
        fillFields(newLines, null);
    }

    //before update
    public void fillFields(List<DMT_Line__c> newLines, Map<Id, DMT_Line__c> oldMapLines){
        // Collect all OwnerIds from the newLines
        Set<Id> ownerIds = new Set<Id>();
        for (DMT_Line__c nl : newLines){
            if (nl.OwnerId != null){
                ownerIds.add(nl.OwnerId);
            }
        }

        // Query all Users with the collected OwnerIds
        Map<Id, User> ownerMap = new Map<Id, User>([SELECT ID_User__c
                                                    FROM User
                                                    WHERE Id IN:ownerIds]);

        Set<Id> idsForFuture = new Set<Id>();
        // Process each line
        for (DMT_Line__c nl : newLines){
            if (Trigger.isInsert || Trigger.isUpdate){
                User owner = ownerMap.get(nl.OwnerId);
                if (owner != null && nl.DMT_ID_User__c != owner.ID_User__c){
                    nl.DMT_ID_User__c = owner.ID_User__c;
                }
            }
            if (Trigger.isUpdate){
                if (nl.DMT_Approval_Date__c == null && nl.Status__c == DMT_Constants.APPROVAL){
                    nl.DMT_Approval_Date__c = Datetime.now();
                }
                if (nl.DMT_Approval_Date__c != null && nl.DMT_IsErasable__c){
                    nl.DMT_IsErasable__c = false;
                }
                if (nl.Status__c == DMT_Constants.READYTOCLOSE && oldMapLines.get(nl.Id).Status__c != nl.Status__c && nl.Booking_Geography__c != 'PE' && nl.Product__c != 'Sanction'){
                    List<DMT_Passport_CalloutQueueable> queueableJobs = new List<DMT_Passport_CalloutQueueable>();
                    queueableJobs.add(new DMT_Passport_CalloutQueueable(nl.Id, nl.Client__c));
                    if(!queueableJobs.isEmpty()) {
                        for(DMT_Passport_CalloutQueueable job : queueableJobs) {
                            System.enqueueJob(job);
                        }
                        System.debug('Nº lines ' + queueableJobs.size() + ' jobs queueable for Ready to close');
                    }
                    idsForFuture.add(nl.Id);

                }
                if (nl.Status__c == DMT_Constants.CLOSED && oldMapLines.get(nl.Id).Status__c != nl.Status__c && nl.Booking_Geography__c != 'PE' && nl.Product__c != 'Sanction'){

                List<DMT_Passport_CalloutQueueable> queueableJobs = new List<DMT_Passport_CalloutQueueable>();
                queueableJobs.add(new DMT_Passport_CalloutQueueable(nl.Id, nl.Client__c));
                    if(!queueableJobs.isEmpty()) {
                        for(DMT_Passport_CalloutQueueable job : queueableJobs) {
                            System.enqueueJob(job);
                        }
                        System.debug('Nº lines ' + queueableJobs.size() + ' jobs queueable for Closed Won');
                    }
                }
            }
        }
        if (!idsForFuture.isEmpty()){
            //updateRecordStatus(idsForFuture);
            }
    }

    // @future(callout=true)
    // public static void updateRecordStatus(Set<Id> recordIds ) {
    //     List<DMT_Line__c> recordsToUpdate = new List<DMT_Line__c>();

    //     for (Id recordId : recordIds) {
    //         DMT_Line__c record = new DMT_Line__c(
    //             Id = recordId,
    //             Closed__c = DMT_Constants.WON,
    //             Status__c = DMT_Constants.CLOSED
    //         );
    //         recordsToUpdate.add(record);

    //     }
    //     update recordsToUpdate;
    // }


    public void closeFather(List<DMT_Line__c> newLines, Map<Id, DMT_Line__c> oldMapLines){
        List<DMT_Line__c> parentToClosed = new List<DMT_Line__c>();

        for (DMT_Line__c nl : newLines){
            if (nl.DMT_Parent_Line__c != null && nl.Status__c == DMT_Constants.CLOSED && nl.Closed__c == DMT_Constants.WON && nl.Status__c != oldMapLines.get(nl.Id).Status__c && nl.End_Date__c > Date.today() && oldMapLines.get(nl.Id).End_Date__c >=  Date.today() ){
                parentToClosed.add(new DMT_Line__c(
                    Id = nl.DMT_Parent_Line__c,
                    End_Date__c = Date.today().addDays(-1)
                ));
            }
        }

        if (!parentToClosed.isEmpty()){
            update parentToClosed;
        }
    }

    // sync Custom Association Name with Name field // after update
    public void syncCustomAssociationName(List<DMT_Line__c> newList){
        List<String> lineIds = new List<String>();
        for (DMT_Line__c line : newList){
            lineIds.add(line.Id);
        }

        // method reused from different points (apex and flow)
        DMT_HPG_Utils.syncCustomAssociationName(lineIds);
    }

    public void updateLastModifiedByHuman(List<SObject> records){
        DMT_HPG_Utils.updateLastModifiedByHuman(records);
    }

    public void createLineVersionSnapshot(List<DMT_Line__c> newLines, Map<Id, DMT_Line__c> oldMapLines){
        List<DMT_AsyncPayload> batchPayloads = new List<DMT_AsyncPayload>();
        String userId = UserInfo.getUserId();
        List<User> loggedInUser = [SELECT ID_User__c
                                   FROM User
                                   WHERE Id = :userId];
        String type = 'Line';
        for (DMT_Line__c line : newLines){
            System.debug('new Status: ' + line.Status__c);
            System.debug('old Status: ' + oldMapLines.get(line.Id).Status__c);
             if ((oldMapLines.get(line.Id).Status__c == DMT_Constants.READYTOCLOSE)|| 
            (line.Status__c == DMT_Constants.PROPOSAL && oldMapLines.get(line.Id).Status__c == DMT_Constants.DRAFT) ||
            (line.Status__c == DMT_Constants.APPROVAL && oldMapLines.get(line.Id).Status__c == DMT_Constants.PROPOSAL) ||
            (line.Status__c == DMT_Constants.READYTOCLOSE && oldMapLines.get(line.Id).Status__c == DMT_Constants.APPROVAL) ||
            (oldMapLines.get(line.Id).Status__c == DMT_Constants.PROPOSAL && line.Status__c == DMT_Constants.DRAFT) ||
            (oldMapLines.get(line.Id).Status__c == DMT_Constants.APPROVAL && line.Status__c == DMT_Constants.DRAFT) ||
            (oldMapLines.get(line.Id).Status__c == DMT_Constants.READYTOCLOSE && line.Status__c == DMT_Constants.DRAFT) ||
            (oldMapLines.get(line.Id).Status__c == DMT_Constants.CLOSED && line.Status__c == DMT_Constants.DRAFT && line.Closed__c == DMT_Constants.WON)){
                System.debug('Enqueuing callout to createLineVersionSnapshot for Line ID: ' + line.Line_Id__c);

                String categoryId;
                if (line.Status__c == DMT_Constants.PROPOSAL){
                    categoryId = DMT_Constants.DRAFT + '-' + DMT_Constants.PROPOSAL;
                } else if (line.Status__c == DMT_Constants.APPROVAL){
                    categoryId = DMT_Constants.PROPOSAL + '-' + DMT_Constants.APPROVAL;
                } else if (line.Status__c == DMT_Constants.READYTOCLOSE){
                    categoryId = DMT_Constants.APPROVAL + '-' + DMT_Constants.READYTOCLOSE;
                } else if (line.Status__c == DMT_Constants.CLOSED){
                    categoryId = line.Closed__c == DMT_Constants.WON ? 'Closed-Won' : DMT_Constants.READYTOCLOSE + '-' + DMT_Constants.CLOSED;
                } else{
                    categoryId = '';
                }

                //sending userDmtId, dmtLineId, categoryId, versionDescription, line.Id and type
                if (!Test.isRunningTest()){
                    DMT_SnapshotEvaluationVersions.PostRequestWrapperClass requestBody = new DMT_SnapshotEvaluationVersions.PostRequestWrapperClass();
                    requestBody.user = (loggedInUser.isEmpty() ? line.DMT_ID_User__c : loggedInUser[0].ID_User__c);
                    requestBody.opportunityId = line.Line_Id__c;
                    requestBody.categoryId = categoryId;
                    requestBody.versionDescription = '';

                    batchPayloads.add(new DMT_SnapshotPayload(requestBody, line.Id, type));
                }

            }
        }

        if (!batchPayloads.isEmpty()){
            Database.executeBatch(new DMT_AsyncBatchJob(batchPayloads), 1);
        }
    }

    @InvocableMethod(label = 'Singular Tresury Consumption'description = 'Tranform Singular Tresury Risk Line Term')
    public static List<List<DMT_Risk_Line_Term__c>> singularTreasuryConsumption(List<List<DMT_Risk_Line_Term__c>> inputRisks){

        List<DMT_Consolidated_Line__c> cLines = new List<DMT_Consolidated_Line__c>();
        //List<DMT_Risk_Line_Term__c> relatedRisks = inputRisks[0];
        List<List<DMT_Risk_Line_Term__c>> returnRisk = new List<List<DMT_Risk_Line_Term__c>>();

        for ( List<DMT_Risk_Line_Term__c> relatedRisks : inputRisks  ) {
            List<DMT_Risk_Line_Term__c> defRisk = new List<DMT_Risk_Line_Term__c>();
            List<DMT_Risk_Line_Term__c> riskList = new List<DMT_Risk_Line_Term__c>();
            List<DMT_Risk_Line_Term__c> singularRiskList = new List<DMT_Risk_Line_Term__c>();
            List<DMT_Risk_Line_Term__c> nonDeriRisk = new List<DMT_Risk_Line_Term__c>();

            for (DMT_Risk_Line_Term__c riskLT : relatedRisks){
                if (riskLT.DMT_Singular__c && riskLT.DMT_Max_Date__c >= Date.today() && riskLT.DMT_Risk_Type__c == DMT_Constants.RSK_DERIVATIVES){
                    singularRiskList.add(riskLT);
                } else if (!riskLT.DMT_Singular__c && riskLT.DMT_Risk_Type__c == DMT_Constants.RSK_DERIVATIVES){
                    riskList.add(riskLT);
                } else if (riskLT.DMT_Risk_Type__c == DMT_Constants.RSK_DEPOS || riskLT.DMT_Risk_Type__c == DMT_Constants.RSK_EQUITY){
                    nonDeriRisk.add(riskLT);
                }
            }

            for (DMT_Risk_Line_Term__c singularRisk : singularRiskList){
                defRisk = new List<DMT_Risk_Line_Term__c>();
                Decimal maxTermDerivatives = 0;
                for (DMT_Risk_Line_Term__c newRisk : new List<DMT_Risk_Line_Term__c>(riskList)){
                    if (Decimal.valueOf(newRisk.DMT_End_Term__c) <= Decimal.valueOf(singularRisk.DMT_End_Term__c)){
                        DMT_Risk_Line_Term__c addRisk = newRisk.clone();
                        addRisk.DMT_Amount__c = newRisk.DMT_Amount__c + singularRisk.DMT_Amount__c;
                        addRisk.DMT_Risk_Type__c = DMT_Constants.RSK_SINGULAR;
                        addRisk.CurrencyIsoCode = newRisk.CurrencyIsoCode;
                        defRisk.add(addRisk);
                    } else if (Decimal.valueOf(newRisk.DMT_End_Term__c) > Decimal.valueOf(singularRisk.DMT_End_Term__c) && Decimal.valueOf(newRisk.DMT_Init_Term__c) < Decimal.valueOf(singularRisk.DMT_End_Term__c)){
                        DMT_Risk_Line_Term__c addRisk = newRisk.clone();
                        DMT_Risk_Line_Term__c addRisk2 = newRisk.clone();
                        addRisk.DMT_Amount__c = newRisk.DMT_Amount__c + singularRisk.DMT_Amount__c;
                        addRisk.DMT_End_Term__c = singularRisk.DMT_End_Term__c;
                        addRisk.DMT_Risk_Type__c = DMT_Constants.RSK_SINGULAR;
                        addRisk2.DMT_Init_Term__c = singularRisk.DMT_End_Term__c;
                        addRisk2.DMT_Risk_Type__c = DMT_Constants.RSK_SINGULAR;
                        addRisk.CurrencyIsoCode = newRisk.CurrencyIsoCode;
                        addRisk2.CurrencyIsoCode = newRisk.CurrencyIsoCode;
                        defRisk.add(addRisk);
                        defRisk.add(addRisk2);

                    } else{
                        DMT_Risk_Line_Term__c addRisk = newRisk.clone();
                        addRisk.DMT_Risk_Type__c = DMT_Constants.RSK_SINGULAR;
                        addRisk.CurrencyIsoCode = newRisk.CurrencyIsoCode;
                        defRisk.add(addRisk);
                    }
                    riskList = defRisk;
                    maxTermDerivatives = maxTermDerivatives < Decimal.valueOf(newRisk.DMT_End_Term__c) ? Decimal.valueOf(newRisk.DMT_End_Term__c) : maxTermDerivatives;
                }
                if (maxTermDerivatives < Decimal.valueOf(singularRisk.DMT_End_Term__c) && !riskList.isEmpty()){
                    DMT_Risk_Line_Term__c addRisk = riskList[0].clone();
                    addRisk.DMT_Amount__c = singularRisk.DMT_Amount__c;
                    addRisk.DMT_Init_Term__c = String.valueOf(maxTermDerivatives);
                    addRisk.DMT_End_Term__c = singularRisk.DMT_End_Term__c;
                    addRisk.DMT_Risk_Type__c = DMT_Constants.RSK_SINGULAR;
                    //addRisk.CurrencyIsoCode = newRisk.CurrencyIsoCode;
                    defRisk.add(addRisk);
                    riskList = defRisk;
                }
            }
            defRisk.addAll(nonDeriRisk);
            returnRisk.add(defRisk);

        }

        return returnRisk;
    }

    public void avoidPassingApproval(List<DMT_Line__c> newLines, Map<Id, DMT_Line__c> oldMapLines, Integer triggerSize){
        if (triggerSize == 1 && ((oldMapLines.values()[0].Status__c == newLines[0].Status__c && oldMapLines.values()[0].DMT_Approval_Date__c != newLines[0].DMT_Approval_Date__c) || ((newLines[0].Status__c == DMT_Constants.READYTOCLOSE || newLines[0].Status__c == DMT_Constants.CLOSED) && oldMapLines.values()[0].Status__c != newLines[0].Status__c))){

            List<Passport__c> passportList = [SELECT DMT_Passport_Save__c, DMT_Line__c
                                            FROM Passport__c
                                            WHERE DMT_Line__c = :newLines[0].Id
                                            WITH SECURITY_ENFORCED
                                            LIMIT 1];

            if (passportList.isEmpty()) {
                System.debug(LoggingLevel.ERROR, 'DMT_Line_Helper: No Passport record found for Line ' + newLines[0].Id);
                return;
            } else {
                Passport__c passportRecord = passportList[0];

                if (passportRecord.DMT_Passport_Save__c != null){
                    Map<String, Object> data = (Map<String, Object>)JSON.deserializeUntyped(passportRecord.DMT_Passport_Save__c);

                    if (data.containsKey('data')){
                        Map<String, Object> dataMap = (Map<String, Object>)data.get('data');

                        if (dataMap.containsKey('features')){
                            List<Object> rawFeatures = (List<Object>)dataMap.get('features');
                            Set<String> approvalFeatureSet = new Set<String>();
                            for (Object featureObj : rawFeatures){
                                Map<String, Object> featureData = (Map<String, Object>)featureObj;

                                if (featureData.get('id') != null && featureData.get('passportSanction') != null && String.valueOf(featureData.get('passportSanction')).toUpperCase() == DMT_Constants.APPROVAL.toUpperCase()){
                                    approvalFeatureSet.add(String.valueOf(featureData.get('id')));
                                }
                            }
                            List<Case> approvalCases = new List<Case>();
                            approvalCases = [SELECT Id, Status, DMT_Passport_Sanction__c, DMT_Feature_Id__c
                                            FROM Case
                                            WHERE DMT_Line__c = :newLines[0].Id AND Status = :DMT_Constants.FINISHED AND DMT_Passport_Sanction__c = 'approval'];
                            Set<String> approvalCasesSet = new Set<String>();

                            for (Case c : approvalCases){
                                approvalCasesSet.add(c.DMT_Feature_Id__c);
                            }
                            if (!approvalCasesSet.equals(approvalFeatureSet)){
                                newLines[0].DMT_Approval_Validation__c = false;
                            } else{
                                List<DMT_Case_Steps_Controller.WRAPPER_Step> steps = new List<DMT_Case_Steps_Controller.WRAPPER_Step>();
                                if (!DMT_Case_Steps_Controller.getCurrentStepsFromCases(approvalCases).isEmpty()) {
                                    steps = DMT_Case_Steps_Controller.getCurrentStepsFromCases(approvalCases)[0].subitems;
                                }
                                for (DMT_Case_Steps_Controller.WRAPPER_Step step : steps){
                                    if (step.rawresult != 'Yes'){
                                        newLines[0].DMT_Approval_Validation__c = false;
                                        break;
                                    } else{
                                        newLines[0].DMT_Approval_Validation__c = true;
                                    }
                                }
                            }
                        }
                    }
                } else{
                    newLines[0].DMT_Approval_Validation__c = false;
                }

                if (newLines[0].DMT_Approval_Validation__c && newLines[0].Status__c == DMT_Constants.APPROVAL){
                    newLines[0].Status__c = DMT_Constants.READYTOCLOSE;
                }
            }
        }
    }
    
    // Método privado que hace las actualizaciones
    public void handleCancelChange(List<DMT_Line__c> newLines, Map<Id, DMT_Line__c> oldMap) {
        
        // 1. Identificar qué líneas cambiaron DMT_Cancel__c a true
        Set<Id> dmtLineIdsCancelTrue = new Set<Id>();
        
        for (DMT_Line__c newLine : newLines) {
            DMT_Line__c oldLine = oldMap != null ? oldMap.get(newLine.Id) : null;
            
            // Si el campo cambió de false a true, o si antes era null y ahora es true
            if (newLine.DMT_Cancel__c == true && 
                (oldLine == null || oldLine.DMT_Cancel__c == false)) {
                dmtLineIdsCancelTrue.add(newLine.Id);
            }
        }
        
        // 2. Si no hay cambios relevantes, salir
        if (dmtLineIdsCancelTrue.isEmpty()) {
            return;
        }   
        // Obtener todos los casos relacionados con estas DMT Lines
        List<Case> casosParaActualizar = [SELECT Id, Status 
                                         FROM Case 
                                         WHERE DMT_Line__c IN :dmtLineIdsCancelTrue
                                         AND Status != 'Finished'];
        
        if (casosParaActualizar.isEmpty()) {
            return; // No hay casos para actualizar
        }
        
        // Obtener IDs de casos para buscar tareas
        Set<Id> casoIds = new Set<Id>();
        for (Case caso : casosParaActualizar) {
            casoIds.add(caso.Id);
            caso.Status = 'Finished'; // Actualizar estado del caso
        }
        
        // Obtener todas las tareas relacionadas con estos casos
        List<Task> tareasParaActualizar = [SELECT Id, Status 
                                          FROM Task 
                                          WHERE WhatId IN :casoIds 
                                          AND Status != 'Cancelled'];
        
        // Actualizar estado de las tareas
        for (Task tarea : tareasParaActualizar) {
            tarea.Status = 'Cancelled';
        }
        
        // Ejecutar DML en orden adecuado (primero casos, luego tareas si quieres)
        // Usamos Database.update para manejar posibles errores parciales
        if (!casosParaActualizar.isEmpty()) {
            DMT_WithoutSharingDAO.updateRecords(casosParaActualizar);
        }
        
        if (!tareasParaActualizar.isEmpty()) {
            DMT_WithoutSharingDAO.updateRecords(tareasParaActualizar);
        }
        
        // Opcional: Logging
        System.debug('Actualizados ' + casosParaActualizar.size() + ' casos a Finished');
        System.debug('Actualizadas ' + tareasParaActualizar.size() + ' tareas a Cancelled');
    }
}