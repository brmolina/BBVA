/**
 * Line helper class contains logic related with lines, for example methods used en line trigger
 */
public with sharing class DMT_Line_Helper{

    private Map<Id, User> cachedUsersById = new Map<Id, User>();
    
    // Global Cache to prevent duplicate queries across helper methods
    private static Map<Id, List<DMT_Risk_Line_Term__c>> cachedRiskLineTerms = new Map<Id, List<DMT_Risk_Line_Term__c>>();
    private static Set<Id> fullyCachedLineIds = new Set<Id>();

    private static Set<Id> collectOwnerIds(List<DMT_Line__c> lines){
        Set<Id> ownerIds = new Set<Id>();
        if (lines == null || lines.isEmpty()){
            return ownerIds;
        }
        for (DMT_Line__c line : lines){
            if (line.OwnerId != null){
                ownerIds.add(line.OwnerId);
            }
        }
        return ownerIds;
    }

    private void preloadUsersByLines(List<DMT_Line__c> lines){
        Set<Id> userIdsToFetch = collectOwnerIds(lines);
        userIdsToFetch.add(UserInfo.getUserId()); // Safely inject the running user into the bulk fetch
        getCachedUsersByIds(userIdsToFetch);
    }

    private Map<Id, User> getCachedUsersByIds(Set<Id> userIds){
        if (userIds == null || userIds.isEmpty()){
            return new Map<Id, User>();
        }

        Set<Id> missingUserIds = new Set<Id>();
        for (Id userId : userIds){
            if (userId != null && !cachedUsersById.containsKey(userId)){
                missingUserIds.add(userId);
            }
        }

        if (!missingUserIds.isEmpty()){
            for (User userRecord : [SELECT Id, ID_User__c FROM User WHERE Id IN :missingUserIds WITH SYSTEM_MODE]){
                cachedUsersById.put(userRecord.Id, userRecord);
            }
        }

        Map<Id, User> result = new Map<Id, User>();
        for (Id userId : userIds){
            if (userId != null && cachedUsersById.containsKey(userId)){
                result.put(userId, cachedUsersById.get(userId));
            }
        }
        return result;
    }

    private User getCachedUserById(Id userId){
        if (userId == null){
            return null;
        }
        getCachedUsersByIds(new Set<Id>{ userId });
        return cachedUsersById.get(userId);
    }

    public void createConsolidatedLine(List<DMT_Line__c> newLines, Map<Id, DMT_Line__c> mapLines, Map<Id, DMT_Line__c> mapOldLines){

        final List<DMT_Consolidated_Line__c> cLines = new List<DMT_Consolidated_Line__c>();
        final List<String> producCodeSearch = new List<String>{ DMT_Constants.PRODUCT_DERI, DMT_Constants.PRODUCT_DEPO, DMT_Constants.PRODUCT_EQUI, DMT_Constants.PRODUCT_REPO };

        // OPTIMIZATION: Query ALL risk lines once, then partition in memory to save SOQL queries
        Map<Id, List<DMT_Risk_Line_Term__c>> mapRskltByIdLineNonTreasury = getAllRiskLineTermsByLine(mapLines.keySet());
        Map<Id, List<DMT_Risk_Line_Term__c>> mapRskltByIdLine = new Map<Id, List<DMT_Risk_Line_Term__c>>();
        Map<Id, List<DMT_Risk_Line_Term__c>> mapRskltByIdLineSingular = new Map<Id, List<DMT_Risk_Line_Term__c>>();

        for (Id lineId : mapRskltByIdLineNonTreasury.keySet()) {
            List<DMT_Risk_Line_Term__c> fullList = mapRskltByIdLineNonTreasury.get(lineId);
            List<DMT_Risk_Line_Term__c> regList = new List<DMT_Risk_Line_Term__c>();
            List<DMT_Risk_Line_Term__c> singList = new List<DMT_Risk_Line_Term__c>();

            for (DMT_Risk_Line_Term__c rsk : fullList) {
                if (rsk.DMT_Amount__c != null) {
                    // Logic mapped from the old `treasuryLine=true, singular=false` query
                    if (rsk.DMT_Singular__c == false && 
                       (rsk.DMT_Risk_Type__c == DMT_Constants.RSK_DERIVATIVES || 
                        rsk.DMT_Risk_Type__c == DMT_Constants.RSK_DEPOS || 
                        rsk.DMT_Risk_Type__c == DMT_Constants.RSK_EQUITY) || 
                        rsk.DMT_Risk_Type__c == DMT_Constants.RSK_REPOS) {
                        regList.add(rsk);
                    }
                    
                    // Logic mapped from the old `treasuryLine=true, singular=true` query
                    if (rsk.DMT_Risk_Type__c == DMT_Constants.RSK_SINGULAR || 
                        rsk.DMT_Risk_Type__c == DMT_Constants.RSK_DEPOS || 
                        rsk.DMT_Risk_Type__c == DMT_Constants.RSK_EQUITY ||
                        rsk.DMT_Risk_Type__c == DMT_Constants.RSK_REPOS) {
                        singList.add(rsk);
                    }
                }
            }
            if (!regList.isEmpty()) {
                mapRskltByIdLine.put(lineId, regList);
            }
            if (!singList.isEmpty()) {
                mapRskltByIdLineSingular.put(lineId, singList);
            }
        }

        Map<Id, List<DMT_Line_Product_Item__c>> mapPliByIdLine = getLineProductItemsByLine(mapLines);
        System.debug('producCodeSearch: ' + producCodeSearch);
        Map<String, Product2> mapProdByProdCod = getProductsByCode(producCodeSearch);
        final Map<Id, User> mapCorporateUByIdLine = getCachedUsersByIds(collectOwnerIds(mapLines.values()));
        List<DMT_Consolidated_Line__c> prevCLines = new List<DMT_Consolidated_Line__c>();
        Map<String, List<DMT_Consolidated_Line__c>> mapClines = getpreviousConsoLines(mapLines);
        
        //Iterate trigger lines
        for (DMT_Line__c line : newLines){
            //Integer for generate sub id for consolidated lines.
            Integer idPriorityLine = 1;

            if ((line.Status__c == DMT_Constants.APPROVAL || (line.Status__c == DMT_Constants.CLOSED && line.Closed__c == DMT_Constants.WON) || (line.Status__c == DMT_Constants.CLOSED && line.Closed__c == 'Lost') || (line.Status__c == DMT_Constants.DRAFT && line.DMT_Approval_Date__c != null) || (line.Status__c == DMT_Constants.PROPOSAL && line.DMT_Approval_Date__c != null)) && mapOldLines.get(line.Id).Status__c != line.Status__c || mapOldLines.get(line.Id).DMT_Update_Singular__c != line.DMT_Update_Singular__c || (line.Status__c == DMT_Constants.CLOSED && line.Closed__c == DMT_Constants.WON) || (mapOldLines.get(line.Id).DMT_Approval_Date__c != null && mapOldLines.get(line.Id).DMT_Approval_Date__c != line.DMT_Approval_Date__c) || (line.Status__c == DMT_Constants.READYTOCLOSE && line.Product__c == 'Sanction') || (line.Status__c == DMT_Constants.APPROVAL && line.Product__c == 'Sanction')){

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
                        initcLineHeader.gf_min_raroec_wo_fcg_per__c = getNullableMinimumPercentage(line.gf_min_raroec_wo_fcg_per__c);
                        initcLineHeader.gf_min_rorc_wo_fcg_per__c = getNullableMinimumPercentage(line.gf_min_rorc_wo_fcg_per__c);
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
                            
                            // SAFE MEMORY READ (NO SOQL IN LOOP)
                            List<DMT_Risk_Line_Term__c> relatedRiskDVP = mapRskltByIdLineNonTreasury.get(line.Id);
                            if (relatedRiskDVP != null) {
                                for (DMT_Risk_Line_Term__c risk : relatedRiskDVP) {
                                    if (risk.DMT_Singular__c && risk.DMT_Max_Date__c >= Date.today() && singularDVP != null && risk.DMT_Singular_DvP__c != null) {
                                        singularDVP = singularDVP + risk.DMT_Singular_DvP__c;
                                    }
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
                            
                            // SAFE MEMORY READ (NO SOQL IN LOOP)
                            List<DMT_Risk_Line_Term__c> relatedRiskFD = mapRskltByIdLineNonTreasury.get(line.Id);
                            if (relatedRiskFD != null) {
                                for (DMT_Risk_Line_Term__c risk : relatedRiskFD) {
                                    if (risk.DMT_Singular__c && risk.DMT_Max_Date__c >= Date.today() && singularFD != null && risk.DMT_Singular_FD__c != null) {
                                        singularFD = singularFD + risk.DMT_Singular_FD__c;
                                    }
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

                    //Iterate risk line term generating new consolidated line for each item
                    Boolean treasuryRisk = mapRskltByIdLine != null && !mapRskltByIdLine.isEmpty() && mapRskltByIdLine.get(line.Id) != null && !mapRskltByIdLine.get(line.Id).isEmpty();
                    Boolean treasurySingularRisk = mapRskltByIdLineSingular != null && !mapRskltByIdLineSingular.isEmpty() && mapRskltByIdLineSingular.get(line.Id) != null && !mapRskltByIdLineSingular.get(line.Id).isEmpty();
                    Boolean nontreasuryRisk = mapRskltByIdLineNonTreasury != null && !mapRskltByIdLineNonTreasury.isEmpty() && mapRskltByIdLineNonTreasury.get(line.Id) != null && !mapRskltByIdLineNonTreasury.get(line.Id).isEmpty();
                    if (treasuryRisk || treasurySingularRisk || nontreasuryRisk){
                        Integer idRiskLine = 1;

                        Integer idRiskLineDerivatives = 1;
                        Integer idRiskLineDepos = 1;
                        Integer idRiskLineEquities = 1;
                        Integer idRiskLineRepos = 1;
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
                                    System.debug('Initializing consolidated line for risk: ' + rsk.DMT_Risk_Type__c);
                                    System.debug('Initializing consolidated line for risk: ' + rsk.DMT_Risk_Type__c + ' with idRiskLineRepos: ' + idRiskLineRepos);
                                    System.debug('Initializing consolidated line for risk: ' + rsk.DMT_Risk_Type__c + ' with idRiskLineDepos: ' + idRiskLineDepos);
                                    System.debug('Initializing consolidated line for risk: ' + rsk.DMT_Risk_Type__c + ' with idRiskLineEquities: ' + idRiskLineEquities);
                                    System.debug('Initializing consolidated line for risk: ' + rsk.DMT_Risk_Type__c + ' with idRiskLineRepos: ' + idRiskLineRepos);
                                    System.debug('Initializing consolidated line for risk: ' +mapProdByProdCod);
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
                                    String riskType = rsk.DMT_Risk_Type__c;

                                    Integer currentRiskLine =
                                        riskType == 'Depos' ? idRiskLineDepos :
                                        riskType == 'Equities' ? idRiskLineEquities :
                                        riskType == 'Repos' ? idRiskLineRepos :
                                        idRiskLineDerivatives;

                                    String groupPriorityTerm =
                                        riskType == 'Depos' ? DMT_Constants.GROUP_PRIORITY_TERM_DEPOS :
                                        riskType == 'Equities' ? DMT_Constants.GROUP_PRIORITY_TERM_EQUITIES :
                                        riskType == 'Repos' ? DMT_Constants.GROUP_PRIORITY_REPOS :
                                        DMT_Constants.GROUP_PRIORITY_TERM;

                                    initcLineRsk.gf_group_priority_line_id__c =
                                        groupPriorityTerm + 'o' + String.valueOf('0' + currentRiskLine).right(2);

                                    idRiskLineDepos += riskType == 'Depos' ? 1 : 0;
                                    idRiskLineEquities += riskType == 'Equities' ? 1 : 0;
                                    idRiskLineDerivatives += riskType == 'Derivatives' ? 1 : 0;
                                    idRiskLineRepos += riskType == 'Repo' ? 1 : 0;
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
                                    //initcLineRsk.gf_prev_renewal_priority_line_id__c = rsk.DMT_Parent_Product__r.gf_group_priority_line_id__c;
                                    initcLineRsk.gf_revolvence_pd_days_number__c = rsk.gf_revolvence_pd_days_number__c;
                                    initcLineRsk.gf_break_cl_days_number__c = rsk.gf_break_cl_days_number__c;
                                    initcLineRsk.g_expert_criteria_risk_type__c = rsk.DMT_Risk_Type__c == 'Equities' ? 'WWRX' : '';

                                    //idRiskLine++;
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
                                    String rawCommitment = rsk.g_line_commitment_level_type__c;
                                    String processedCommitment;
                                    if (String.isBlank(rawCommitment)) {
                                        processedCommitment = '';
                                    } else if (rawCommitment.equalsIgnoreCase('PENDING FORMALIZATION')) {
                                        processedCommitment = 'PNG';
                                    } else {
                                        processedCommitment = rawCommitment.left(3);
                                    }
                                    initcLineRsk.g_line_commitment_level_type__c = processedCommitment;

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
                                    if (line.Product__c != 'Sanction') {
                                        initcLineRsk.gf_min_raroec_fcg_per__c = rsk.gf_min_raroec_fcg_per__c;
                                        initcLineRsk.gf_min_raroec_wo_fcg_per__c = rsk.gf_min_raroec_wo_fcg_per__c;
                                        initcLineRsk.gf_min_rorc_fcg_per__c = rsk.gf_min_rorc_fcg_per__c;
                                        initcLineRsk.gf_min_rorc_wo_fcg_per__c = rsk.gf_min_rorc_wo_fcg_per__c;
                                    }
                                    //initcLineRsk.g_isda_waiver_ind_type__c = rsk.g_isda_waiver_ind_type__c;
                                    initcLineRsk.gf_prev_renewal_group_line_id__c =line.DMT_Parent_Code_Form__c;
                                    initcLineRsk.gf_revolvence_pd_days_number__c = rsk.gf_revolvence_pd_days_number__c;
                                    initcLineRsk.gf_break_cl_days_number__c = rsk.gf_break_cl_days_number__c;
                                    initcLineRsk.g_multioperation_ind_type__c = rsk.g_multioperation_ind_type__c ? 't' : 'f';
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
            if (cLines.size() > 0){
                Boolean allNone = newLines.size() == 1 ? true : false;
                Database.insert (cLines, allNone);
            }
            if (prevCLines.size() > 0){
                delete prevCLines;
            }

        } catch (DmlException e){
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
        initLine.global_manager__c = line.DMT_GlobalBanker__c;
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
        } else if (line.Client_Type__c == 'Golden'){
            initLine.client_id__c = line.Golden_Code__c;
            //initLine.gf_customer_group_id__c = line.line_id__c;
            initLine.gf_global_desktop_lm_engine_cust_type_id__c = DMT_Constants.GOLDEN;
            initLine.client_type__c = DMT_Constants.GOLDEN;
            initLine.g_golden_customer_id__c = line.Golden_Code__c;
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

    public Decimal getNullableMinimumPercentage(Decimal percentageValue){
        return percentageValue == null || percentageValue == 0 ? null : percentageValue;
    }

    // Global cache for static products
    private static Map<String, Product2> cachedProductsByCode = new Map<String, Product2>();
    private static Set<String> queriedProductCodes = new Set<String>();

    /**
     * Get products by product code and return in Map string - product
     */
    public Map<String, Product2> getProductsByCode(List<String> productCodes){
        List<String> codesToQuery = new List<String>();
        
        if (productCodes != null) {
            for (String pCode : productCodes) {
                if (!queriedProductCodes.contains(pCode)) {
                    codesToQuery.add(pCode);
                }
            }
        }

        if (!codesToQuery.isEmpty()) {
            List<Product2> listProduct = [SELECT DMT_Global_Product_Id__c, DMT_Product_Subcategory__c, DMT_Product_Subfamily__c, DMT_Product_category__c, DMT_Product_family__c, Description, Id, Name, ProductCode
                                          FROM Product2
                                          WHERE ProductCode IN :codesToQuery AND family = 'DMT Lines'
                                          WITH SYSTEM_MODE
                                          limit 10000];

            if (listProduct != null && !listProduct.isEmpty()){
                for (Product2 p : listProduct){
                    switch on p.ProductCode{
                        when '1600000000'{
                            cachedProductsByCode.put('Derivatives', p);
                            cachedProductsByCode.put('Singular', p);
                        }
                        when '1611170000'{
                            cachedProductsByCode.put('Depos', p);
                        }
                        when '1610000000'{
                            cachedProductsByCode.put('Equities', p);
                        }
                        when '1611190000'{
                            cachedProductsByCode.put('Repos', p);
                        }
                    }
                }
            }
            
            // Mark these codes as queried so we don't query them again, even if no records were found
            queriedProductCodes.addAll(codesToQuery);
        }

        return cachedProductsByCode;
    }
    /**
     * Unified fetch: Retrieves all Risk Line Terms for the given lines using a global static cache.
     */
    public Map<Id, List<DMT_Risk_Line_Term__c>> getAllRiskLineTermsByLine(Set<Id> lineIds) {
        Set<Id> idsToQuery = new Set<Id>();
        for (Id lineId : lineIds) {
            if (!fullyCachedLineIds.contains(lineId)) {
                idsToQuery.add(lineId);
            }
        }

        if (!idsToQuery.isEmpty()) {
            List<DMT_Risk_Line_Term__c> rskltList = [
                SELECT CurrencyIsoCode, g_amortization_type__c, DMT_Parent_Product__r.gf_group_priority_line_id__c, 
                       DMT_Comments__c, DMT_Amount__c, DMT_End_Term__c, DMT_Init_Term__c, DMT_Line__c, DMT_Risk_Type__c, 
                       Id, Name, g_global_product_family_id__c, g_global_product_subfamily_id__c, g_gbl_product_subcategory_id__c, 
                       g_global_product_category_id__c, g_global_product_id__c, DMT_LastLevelId__c, g_limit_last_level_type__c, 
                       gf_inscol_months_grace_number__c, gf_loan_value_per__c, g_notary_crtfn_ind_type__c, g_gtee_public_adm_ind_type__c, 
                       gf_loan_eca_cntrb_per__c, gf_min_raroec_fcg_per__c, gf_min_rorc_fcg_per__c, gf_min_rorc_wo_fcg_per__c, 
                       g_isda_waiver_ind_type__c, gf_prev_renewal_group_line_id__c, gf_revolvence_pd_days_number__c, 
                       gf_break_cl_days_number__c, g_multioperation_ind_type__c, gf_min_raroec_wo_fcg_per__c, 
                       gf_group_priority_line_id__c, g_line_cond_guarantee_ind_type__c, g_bullet_ind_type__c, 
                       g_smscl_internal_ratg_type__c, g_limit_sinds_ast_sctr_id__c, g_limit_sinds_ast_subsec_id__c, 
                       g_branch_id__c, DMT_Parent_Product__c, DMT_Singular__c, DMT_Singular_Active__c, DMT_Max_Date__c, 
                       g_expert_criteria_risk_type__c, g_line_commitment_level_type__c, DMT_Singular_DvP__c, DMT_Singular_FD__c
                FROM DMT_Risk_Line_Term__c
                WHERE DMT_Line__c IN :idsToQuery
                WITH USER_MODE
                LIMIT 10000
            ];

            for (DMT_Risk_Line_Term__c rskItem : rskltList) {
                if (!cachedRiskLineTerms.containsKey(rskItem.DMT_Line__c)) {
                    cachedRiskLineTerms.put(rskItem.DMT_Line__c, new List<DMT_Risk_Line_Term__c>());
                }
                cachedRiskLineTerms.get(rskItem.DMT_Line__c).add(rskItem);
            }
            
            // Mark as cached so we don't query again, even if they have 0 related risk lines
            fullyCachedLineIds.addAll(idsToQuery);
        }

        Map<Id, List<DMT_Risk_Line_Term__c>> mapRskltReturn = new Map<Id, List<DMT_Risk_Line_Term__c>>();
        for (Id lineId : lineIds) {
            if (cachedRiskLineTerms.containsKey(lineId)) {
                mapRskltReturn.put(lineId, cachedRiskLineTerms.get(lineId));
            } else {
                mapRskltReturn.put(lineId, new List<DMT_Risk_Line_Term__c>());
            }
        }
        return mapRskltReturn;
    }

    /**
     * Return map of productLines items list for each line
     */
    public Map<Id, List<DMT_Line_Product_Item__c>> getLineProductItemsByLine(Map<Id, DMT_Line__c> mapLinesP){

        Map<Id, List<DMT_Line_Product_Item__c>> mapPLRReturn = new Map<Id, List<DMT_Line_Product_Item__c>>();
        List<DMT_Line_Product_Item__c> pliList = [SELECT CurrencyIsoCode, Max_Tenor_WC__c, Max_Tenor_WOC__c, Product__c, Id, Name, Product__r.ProductCode, Product__r.DMT_Product_family__c, Line__c, Product__r.DMT_Product_Subfamily__c, Product__r.DMT_Product_category__c, Product__r.DMT_Product_Subcategory__c, Product__r.DMT_Global_Product_Id__c, DMT_DerivativeRestriction__c, DMT_FDRestriction__c, DMT_DVPRestriction__c, Product_Code_Value__c
                                                  FROM DMT_Line_Product_Item__c
                                                  WHERE Line__c IN:mapLinesP.keySet()
                                                  WITH USER_MODE
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
                                                 WITH USER_MODE
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
        fillFields(newLines, null);
    }

    //before update
    public void fillFields(List<DMT_Line__c> newLines, Map<Id, DMT_Line__c> oldMapLines){
        preloadUsersByLines(newLines);

        for (DMT_Line__c nl : newLines){
            // Synchronous logic: User syncing
            User owner = getCachedUserById(nl.OwnerId);
            if (owner != null && nl.DMT_ID_User__c != owner.ID_User__c){
                nl.DMT_ID_User__c = owner.ID_User__c;
                // DMT_TeamMemberSharingBatch batch = new DMT_TeamMemberSharingBatch();
                // Database.executeBatch(batch, 200); // 200 es un scope común, ajústalo
            }

            if (Trigger.isUpdate){
                // Synchronous logic: Date and Erasable management
                if (nl.DMT_Approval_Date__c == null && nl.Status__c == DMT_Constants.APPROVAL){
                    nl.DMT_Approval_Date__c = Datetime.now();
                }
                if (nl.DMT_Approval_Date__c != null && nl.DMT_IsErasable__c){
                    nl.DMT_IsErasable__c = false;
                }

                // ASYNC LOGIC REMOVED FROM HERE!
            }
            if (nl.Name != null) {
                nl.Name = nl.Name.left(50);
            }
        }
    }

    // CIBGLOBALD-3779: keeps Term/End Date mutually consistent server-side for both Risk Approval
    // (Start_Date__c/End_Date__c/DMT_Risk_Approval_Term__c) and Business Approval
    // (DMT_Bussiness_Approved_Date__c/DMT_Business_Approved_End_Date__c/
    // DMT_Business_Approval_Term_n__c) — the same behavior the dmt_lineInfo LWC already applies
    // client-side, but enforced here too so any other write path (data load, other Apex, bulk
    // update) can't leave Term blank while the dates are filled, or End Date stale after Term
    // changes. Term takes priority: if Term is set, End Date is (re)computed from Start + Term,
    // overwriting whatever End Date held. Term is only back-computed from the date pair when Term
    // itself is blank. Does nothing when Start Date is blank (nothing to compute from).
    public void syncApprovalTermAndEndDate(List<DMT_Line__c> newLines, Map<Id, DMT_Line__c> oldMapLines){
        Formula.recalculateFormulas(newLines);
        for (DMT_Line__c line : newLines){
            DMT_Line__c oldLine = oldMapLines != null ? oldMapLines.get(line.Id) : null;
            syncTermAndEndDate(line, oldLine, DMT_Line__c.Start_Date__c, DMT_Line__c.End_Date__c, DMT_Line__c.DMT_Risk_Approval_Term__c);
            syncTermAndEndDate(line, oldLine, DMT_Line__c.DMT_Bussiness_Approved_Date__c, DMT_Line__c.DMT_Business_Approved_End_Date__c, DMT_Line__c.DMT_Business_Approval_Term_n__c);
        }
    }

    // SObjectField tokens let this stay generic across both field trios without reflection-by-name.
    private void syncTermAndEndDate(DMT_Line__c line, DMT_Line__c oldLine, Schema.SObjectField startField, Schema.SObjectField endField, Schema.SObjectField termField) {
        Date startDate = (Date) line.get(startField);
        if (startDate == null) {
            return;
        }

        Object termValue = line.get(termField);
        Boolean termChanged = oldLine == null || line.get(termField) != oldLine.get(termField);

        if (termValue != null && (termChanged || line.get(endField) == null)) {
            Integer months = ((Decimal) termValue).intValue();
            line.put(endField, startDate.addMonths(months));
        } else if (termValue == null) {
            Date endDate = (Date) line.get(endField);
            if (endDate != null) {
                line.put(termField, wholeMonthsBetween(startDate, endDate));
            }
        }
    }

    // Whole calendar months between two dates, matching the dmt_lineInfo LWC's
    // _wholeMonthsBetween (ignores leftover days unless the end day-of-month falls before the
    // start day-of-month, in which case the partial trailing month doesn't count).
    private Integer wholeMonthsBetween(Date startDate, Date endDate) {
        Integer months = (endDate.year() - startDate.year()) * 12 + (endDate.month() - startDate.month());
        if (endDate.day() < startDate.day()) {
            months -= 1;
        }
        return months;
    }

    public void closeFather(List<DMT_Line__c> newLines, Map<Id, DMT_Line__c> oldMapLines){
        // Map para almacenar las líneas padre únicas
        Map<Id, DMT_Line__c> parentLinesMap = new Map<Id, DMT_Line__c>();
        // Primero, recolectamos todos los IDs de los padres que necesitamos
        Set<Id> parentIds = new Set<Id>();

        // Added to close the Treasury lines that are active at the same time
        // as the line that triggers the process.
        Set<String> customersSet = new Set<String>();
        Set<Id> triggeringLineIds = new Map<Id, DMT_Line__c>(newLines).keySet();

        List<Custom_Association_Client__c> customAssociationsClientFromLine =
            DMT_Passport_Selector.getCustomAssociationByList(triggeringLineIds);

        // Map customer IDs by the Salesforce Id of the triggering line.
        Map<Id, List<String>> mappedCustomerIdsByLine = new Map<Id, List<String>>();

        for (Custom_Association_Client__c caClient : customAssociationsClientFromLine) {
            Id relatedLineId = caClient.Custom_Association__r == null
                ? null
                : caClient.Custom_Association__r.DMT_Line__c;

            if (relatedLineId != null && String.isNotBlank(caClient.g_customer_id__c)) {
                if (!mappedCustomerIdsByLine.containsKey(relatedLineId)) {
                    mappedCustomerIdsByLine.put(relatedLineId, new List<String>());
                }
                mappedCustomerIdsByLine.get(relatedLineId).add(caClient.g_customer_id__c);
            }
        }

        for (DMT_Line__c childLine : newLines) {
            if (childLine.DMT_Parent_Line__c != null) {
                parentIds.add(childLine.DMT_Parent_Line__c);
            }

            if (childLine.Product__c == 'Treasury Line') {
                if (childLine.Client_Type__c == 'Custom') {
                    if (mappedCustomerIdsByLine.containsKey(childLine.Id)) {
                        customersSet.addAll(mappedCustomerIdsByLine.get(childLine.Id));
                    }
                } else if (
                    childLine.Client_Type__c == 'Customer' ||
                    childLine.Client_Type__c == 'Group'
                ) {
                    if (String.isNotBlank(childLine.Client_Code__c)) {
                        customersSet.add(childLine.Client_Code__c);
                    }
                }
            }
        }

        // Si hay IDs de padres, los consultamos de una sola vez
        if (!parentIds.isEmpty()) {
            parentLinesMap = new Map<Id, DMT_Line__c>([
                SELECT Id, Name, /* Aquí agrega los campos que necesitas del padre */
                    Start_Date__c, End_Date__c
                FROM DMT_Line__c
                WHERE Id IN :parentIds
            ]);
        }
        List<DMT_Line__c> parentToClosed = new List<DMT_Line__c>();

        for (DMT_Line__c nl : newLines){
            if (nl.DMT_Parent_Line__c != null && nl.Status__c == DMT_Constants.CLOSED && nl.Closed__c == DMT_Constants.WON && nl.Status__c != oldMapLines.get(nl.Id).Status__c ){
                DMT_Line__c parentLine = parentLinesMap.get(nl.DMT_Parent_Line__c);
                if (parentLine != null && parentLine.End_Date__c != null && nl.Start_Date__c != null && parentLine.End_Date__c > nl.Start_Date__c){
                    Date startDate;
                    if (parentLine.Start_Date__c != null && nl.Start_Date__c.addDays(-1) <= parentLine.Start_Date__c) {
                        startDate = nl.Start_Date__c.addDays(-2);
                    } else {
                        startDate = parentLine.Start_Date__c;
                    }
                    
                    parentToClosed.add(new DMT_Line__c(
                    Id = nl.DMT_Parent_Line__c,
                    Start_Date__c = startDate,
                    End_Date__c = nl.Start_Date__c.addDays(-1)
                    ));
                }
            }
        }
        List<String> customerList = new List<String>(customersSet);

        DMT_Line__c triggeringLine = newLines[0];
        DMT_Line__c oldTriggeringLine = oldMapLines.get(triggeringLine.Id);

        Boolean becameClosedWon =
            triggeringLine.DMT_line_template_type__c == 'TL' &&
            triggeringLine.Status__c == DMT_Constants.CLOSED &&
            triggeringLine.Closed__c == DMT_Constants.WON &&
            (
                oldTriggeringLine == null ||
                oldTriggeringLine.Status__c != DMT_Constants.CLOSED ||
                oldTriggeringLine.Closed__c != DMT_Constants.WON
            );

            List<DMT_Line__c> treasuryLinesToExpire = new List<DMT_Line__c>();

            if (
                becameClosedWon &&
                !customerList.isEmpty() &&
                triggeringLine.Start_Date__c != null &&
                triggeringLine.End_Date__c != null
            ) {
                treasuryLinesToExpire = DMT_View_Selector.getRelatedTRSRLines(
                    customerList,
                    triggeringLine.Start_Date__c,
                    triggeringLine.End_Date__c,
                    String.valueOf(triggeringLine.Id)
                );
            }

            for (DMT_Line__c lineToExpire : treasuryLinesToExpire) {
                if (triggeringLine.DMT_Parent_Line__c != lineToExpire.Id) {
                    Date treasuryStartDate =
                        triggeringLine.Start_Date__c.addDays(-1) <= lineToExpire.Start_Date__c
                            ? triggeringLine.Start_Date__c.addDays(-2)
                            : lineToExpire.Start_Date__c;

                    parentToClosed.add(new DMT_Line__c(
                        Id = lineToExpire.Id,
                        Start_Date__c = treasuryStartDate,
                        End_Date__c = triggeringLine.Start_Date__c.addDays(-1)
                    ));
                }
            }

        if (!parentToClosed.isEmpty()){
            // Use partial DML so a transient row lock on one record does not roll back all date updates.
            Database.SaveResult[] saveResults = Database.update(parentToClosed, false);
            List<DMT_Line__c> lockRetryLines = new List<DMT_Line__c>();
            for (Integer i = 0; i < saveResults.size(); i++) {
                if (!saveResults[i].isSuccess()) {
                    for (Database.Error err : saveResults[i].getErrors()) {
                        if (err.getStatusCode() == StatusCode.UNABLE_TO_LOCK_ROW) {
                            lockRetryLines.add(parentToClosed[i]);
                        }
                    }
                }
            }
            // Retry locked records asynchronously once the current transaction has committed.
            if (!lockRetryLines.isEmpty()) {
                System.enqueueJob(new CloseFatherRetryQueueable(lockRetryLines));
            }
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

    public void createLineVersionSnapshot(List<DMT_Line__c> newLines, Map<Id, DMT_Line__c> oldMapLines) {

        preloadUsersByLines(newLines);
        String type = 'Line';

        for (DMT_Line__c line : newLines) {
            DMT_Line__c oldLine = oldMapLines.get(line.Id);
            System.debug('Antes del If ---> ' + oldLine.Status__c + ' line.Status__c --->'  + line.Status__c );
            System.debug('Cuando se cierra la tarea ---> ' + oldLine.Status__c + 'line.Status__c'  + line.Status__c );

            String oldStatus = oldLine.Status__c != null ? oldLine.Status__c : 'null';
            String newStatus = line.Status__c != null ? line.Status__c : 'null';
            String draft = DMT_Constants.DRAFT;
            String proposal = DMT_Constants.PROPOSAL;
            String approval = DMT_Constants.APPROVAL;
            String readyToClose = DMT_Constants.READYTOCLOSE;
            String closed = DMT_Constants.CLOSED;

                String categoryId = '';
                Boolean createSnapshot = false;
                if (oldStatus == draft && newStatus == proposal){
                    createSnapshot = true;
                    categoryId = draft + '-' + proposal;
                } else if (oldStatus == proposal && (newStatus == approval || newStatus == draft)){
                    createSnapshot = true;
                    categoryId = proposal + '-' + (newStatus == approval ? approval : draft);
                } else if (oldStatus == approval && (newStatus == readyToClose || newStatus == draft)){
                    createSnapshot = true;
                    categoryId = approval + '-' + (newStatus == readyToClose ? readyToClose : draft);
                } else if (oldStatus == readyToClose && (newStatus == closed || newStatus == draft)){
                    createSnapshot = true;
                    categoryId = newStatus == closed ? readyToClose + '-' + closed : readyToClose + '-' + draft;
                } else if (oldStatus == closed && newStatus == draft && line.Closed__c == DMT_Constants.WON){
                    createSnapshot = true;
                    categoryId = 'Closed-Won' + '-' + draft;
                } else if (newStatus == closed && oldLine.Closed__c != line.Closed__c  && line.Closed__c == DMT_Constants.WON){
                    createSnapshot = true;
                    categoryId = 'Closed-Won' ;
                }  

                if(createSnapshot){
                    // Using the cached logged-in user instead of the record owner
                    User ownerUser = getCachedUserById(UserInfo.getUserId());
                    String loggedInUserExtId = ownerUser != null ? ownerUser.ID_User__c : null;
                    // Prepare Request
                    DMT_SnapshotEvaluationVersions.PostRequestWrapperClass requestBody = new DMT_SnapshotEvaluationVersions.PostRequestWrapperClass();
                    requestBody.user = !String.isBlank(loggedInUserExtId) ? loggedInUserExtId : line.DMT_ID_User__c;
                    requestBody.opportunityId = line.Line_Id__c;
                    requestBody.categoryId = categoryId;
                    requestBody.versionDescription = '';
                    DMT_AsyncOrchestrator.enqueue(new DMT_SnapshotPayload(requestBody, line.Id, type));
                }
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
                } else if (riskLT.DMT_Risk_Type__c == DMT_Constants.RSK_DEPOS || riskLT.DMT_Risk_Type__c == DMT_Constants.RSK_EQUITY || riskLT.DMT_Risk_Type__c == DMT_Constants.RSK_REPOS){
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

            newLines[0].DMT_Approval_Validation__c = DMT_Case_Steps_Controller.checkApprovalValidation(newLines[0].Id);

            if (newLines[0].DMT_Approval_Validation__c && newLines[0].Status__c == DMT_Constants.APPROVAL && newLines[0].dmt_line_template_type__c != 'OP'){
                newLines[0].Status__c = DMT_Constants.READYTOCLOSE;                
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

    /**
     * @description Called in AFTER UPDATE trigger.
     * Monitors Status__c and Closed__c for changes to trigger Passport refresh.
     */
    public void updatePassport_LineStatusChanged(List<DMT_Line__c> newLines, Map<Id, DMT_Line__c> oldMapLines) {

        Id otherProductsRTId = Schema.SObjectType.DMT_Line__c.getRecordTypeInfosByDeveloperName().get('OtherProducts')?.getRecordTypeId();

        Set<Id> otherProductLineIds = new Set<Id>();
        for (DMT_Line__c ln : newLines) {
            if (ln.RecordTypeId == otherProductsRTId) {
                otherProductLineIds.add(ln.Id);
            }
        }

        Set<Id> linesWithRisks = new Set<Id>();
        if (!otherProductLineIds.isEmpty()) {
            // Memory read from the global cache instead of a duplicate Aggregate SOQL query
            Map<Id, List<DMT_Risk_Line_Term__c>> cachedRisks = getAllRiskLineTermsByLine(otherProductLineIds);
            for (Id lineId : otherProductLineIds) {
                if (cachedRisks.containsKey(lineId) && !cachedRisks.get(lineId).isEmpty()) {
                    linesWithRisks.add(lineId);
                }
            }
        }

        // 4. Main Processing Loop
        for (DMT_Line__c line : newLines) {
            DMT_Line__c oldLine = oldMapLines.get(line.Id);

            // Check 1: Status/Closed Change
            Boolean statusChanged = (line.Status__c != oldLine.Status__c || line.Closed__c != oldLine.Closed__c);

            // Check 2: Integrity Gate
            Boolean passesIntegrity = true;
            if (line.RecordTypeId == otherProductsRTId) {
                Boolean hasAmount = (line.Amount__c != null);
                Boolean hasRiskType = (line.DMT_LastLevelId__c != null);
                Boolean hasChildren = linesWithRisks.contains(line.Id);

                passesIntegrity = (hasAmount && hasRiskType && hasChildren);
            }

            // ONLY fire if status changed AND integrity is met
            if (statusChanged && passesIntegrity) {
                DMT_AsyncOrchestrator.enqueue(new DMT_PassportPayload(line.Id, line.Client__c, 'DMTO_EvaluationLine'));
            }
        }
    }

    /**
     * CIBGLOBALD-4477 - Single-record overload of enqueueAutoWorkflowOnStatusChange, for callers that only have one Line.
     */
    public void enqueueAutoWorkflowOnStatusChange(DMT_Line__c newLine, DMT_Line__c oldLine) {
        if (newLine == null || oldLine == null) {
            return;
        }
        enqueueAutoWorkflowOnStatusChange(new List<DMT_Line__c>{ newLine }, new Map<Id, DMT_Line__c>{ newLine.Id => oldLine });
    }

    /**
     * CIBGLOBALD-4477 - AFTER UPDATE. When a Line moves into Proposal, Approval or Ready to close, starts the approval Case of the
     * Passport feature flagged for automatic start (see DMT_Case_Steps_Controller.enqueueAutoWorkflowCases).
     *
     * Collects every qualifying Line and hands them over in ONE call, so the Passport and Case lookups are
     * done once for the whole save. The Case creation is deferred to DMT_AsyncOrchestrator (one payload per
     * Line, each in its own transaction), so DMT_AsyncOrchestrator.flush() must run at the end of the trigger.
     *
     * Independent from restartApprovalTasksOnLineResubmission: that one reopens tasks of Cases that already
     * exist, this one only starts Cases for features that have none yet.
     */
    public void enqueueAutoWorkflowOnStatusChange(List<DMT_Line__c> newLines, Map<Id, DMT_Line__c> oldMapLines) {
        Map<Id, String> stageByLineId = new Map<Id, String>();
        for (DMT_Line__c line : newLines) {
            DMT_Line__c oldLine = oldMapLines.get(line.Id);
            Boolean isSupportedStage = line.Status__c == DMT_Constants.PROPOSAL
                || line.Status__c == DMT_Constants.APPROVAL
                || line.Status__c == DMT_Constants.READYTOCLOSE;
            if (oldLine != null && line.Status__c != oldLine.Status__c && isSupportedStage) {
                stageByLineId.put(line.Id, line.Status__c);
            }
        }
        if (!stageByLineId.isEmpty()) {
            DMT_Case_Steps_Controller.enqueueAutoWorkflowCases(stageByLineId, false);
        }
    }

    /**
     * CIBGLOBALD-4117: AFTER UPDATE. Restarts a Line's open approval Tasks when a watched field changed since the
     * Task was last frozen, so the approver reviews the new value.
     *
     * Keeps only what is specific to DMT_Line__c - which Lines qualify and which Cases are theirs -
     * and hands the rest to DMT_ApprovalChangeStep_Helper.restartStaleApprovalTasks(), shared with
     * DMT_OpportunityTriggerHandler.
     *
     * Runs from the trigger rather than the path component, so it fires on any qualifying save.
     * Queries: 1 Case + 2 in the shared gate + 1 per child section.
     */
    public void restartApprovalTasksOnLineResubmission(List<DMT_Line__c> newLines, Map<Id, DMT_Line__c> oldLinesMap) {
        try {
            Set<Id> qualifyingLineIds = getLinesQualifyingForResubmissionCheck(newLines, oldLinesMap);
            if (qualifyingLineIds.isEmpty()) {
                return;
            }

            Map<Id, Id> caseIdToLineId = getCaseIdToLineId(qualifyingLineIds);
            if (caseIdToLineId.isEmpty()) {
                return;
            }

            // Only the qualifying Lines, so the comparator never queries child rows for Lines this
            // save didn't touch.
            Map<Id, SObject> qualifyingLines = new Map<Id, SObject>();
            for (DMT_Line__c line : newLines) {
                if (qualifyingLineIds.contains(line.Id)) {
                    qualifyingLines.put(line.Id, line);
                }
            }

            DMT_ApprovalChangeStep_Helper.restartStaleApprovalTasks(
                caseIdToLineId,
                newLines,
                'line',
                DMT_SnapshotChildComparator.forRecords(qualifyingLines),
                'DMT_Line_Helper'
            );
        } catch (Exception e) {
            logRestartFailure(e, 'DMT_Line__c', 'restartApprovalTasksOnLineResubmission');
        }
    }

    /**
     * CIBGLOBALD-4117: A Line qualifies when it leaves Draft in this save AND was already in Draft with
     * DMT_DateToProposal__c set - i.e. a genuine resubmission after Return to Draft, not a
     * first-time submission.
     *
     * Reads DMT_DateToProposal__c from oldLinesMap on purpose: Trigger.old always holds the
     * pre-save value, so this stays correct regardless of anything else stamping that field in the
     * same transaction.
     *
     * Sanction is excluded, matching enqueueRecalculateApprovals - it has never been part of this
     * mechanism.
     */
    private static Set<Id> getLinesQualifyingForResubmissionCheck(List<DMT_Line__c> newLines, Map<Id, DMT_Line__c> oldLinesMap) {
        Id treasurySettlementRTId = Schema.SObjectType.DMT_Line__c.getRecordTypeInfosByDeveloperName().get('TreasurySettlement')?.getRecordTypeId();
        Id otherProductsRTId = Schema.SObjectType.DMT_Line__c.getRecordTypeInfosByDeveloperName().get('OtherProducts')?.getRecordTypeId();

        Set<Id> qualifyingLineIds = new Set<Id>();
        for (DMT_Line__c line : newLines) {
            if (line.RecordTypeId != treasurySettlementRTId && line.RecordTypeId != otherProductsRTId) {
                continue;
            }
            DMT_Line__c oldLine = oldLinesMap.get(line.Id);
            if (oldLine.Status__c == DMT_Constants.DRAFT && line.Status__c != DMT_Constants.DRAFT && oldLine.DMT_DateToProposal__c != null) {
                qualifyingLineIds.add(line.Id);
            }
        }
        return qualifyingLineIds;
    }

    private static Map<Id, Id> getCaseIdToLineId(Set<Id> lineIds) {
        Map<Id, Id> caseIdToLineId = new Map<Id, Id>();
        for (Case c : [SELECT Id, DMT_Line__c FROM Case WHERE DMT_Line__c IN :lineIds AND IsDeleted = false]) {
            caseIdToLineId.put(c.Id, c.DMT_Line__c);
        }
        return caseIdToLineId;
    }

    private static void logRestartFailure(Exception e, String objectName, String methodName) {
        DMT_AsyncOrchestrator.enqueue(new DMT_LogExceptionPayload(
            e.getMessage(), e.getStackTraceString(), e.getLineNumber(), e.getTypeName(),
            'DMT_Line_Helper', methodName, 'DMT', objectName
        ));
    }

    /**
     * @description Called in AFTER UPDATE trigger.
     * Automates the "Recalculate Approvals" callout (consumptionsReassign) for TreasurySettlement
     * and OtherProducts lines that just transitioned to Ready to Close or Closed Won, reusing the
     * same payload/dispatcher/callout classes as the Sanction pipeline, without reusing that
     * pipeline itself (avoids coupling to its unrelated RiskPositionLine first-callout gate).
     * Unlike Sanction lines, Treasury/OtherProducts lines have no related Opportunity
     * (DMT_Opportunity__c is never populated for them), so - confirmed against real org data -
     * Line_Id__c is not a valid "opportunityId" for this service; only groupId is sent, matching
     * the manual "Recalculate Approvals" button's payload shape (DMT_Utils.postConsumptionReassign).
     */
    public void enqueueRecalculateApprovals(List<DMT_Line__c> newLines, Map<Id, DMT_Line__c> oldLinesMap) {
        System.debug('entering enqueueRecalculateApprovals');

        Id treasurySettlementRTId = Schema.SObjectType.DMT_Line__c.getRecordTypeInfosByDeveloperName().get('TreasurySettlement')?.getRecordTypeId();
        Id otherProductsRTId = Schema.SObjectType.DMT_Line__c.getRecordTypeInfosByDeveloperName().get('OtherProducts')?.getRecordTypeId();

        Set<Id> qualifyingLineIds = new Set<Id>();

        for (DMT_Line__c line : newLines) {
            if (line.RecordTypeId != treasurySettlementRTId && line.RecordTypeId != otherProductsRTId) {
                continue;
            }

            DMT_Line__c oldLine = oldLinesMap.get(line.Id);
            if (oldLine == null) {
                continue;
            }

            Boolean justReadyToClose = line.Status__c == DMT_Constants.READYTOCLOSE && oldLine.Status__c != DMT_Constants.READYTOCLOSE;
            Boolean justClosedWon = line.Status__c == DMT_Constants.CLOSED && line.Closed__c == DMT_Constants.WON
                && !(oldLine.Status__c == DMT_Constants.CLOSED && oldLine.Closed__c == DMT_Constants.WON);

            if (justReadyToClose || justClosedWon) {
                qualifyingLineIds.add(line.Id);
            }
        }

        if (qualifyingLineIds.isEmpty()) {
            return;
        }

        Map<Id, DMT_Line__c> groupInfoByLineId = new Map<Id, DMT_Line__c>([
            SELECT Id, Client_Type__c, Client__r.DES_Main_Parent__r.DES_Group_Code__c, Client__r.DES_group_Code__c
            FROM DMT_Line__c
            WHERE Id IN :qualifyingLineIds
        ]);

        Map<Id, DMT_Line__c> newLinesById = new Map<Id, DMT_Line__c>(newLines);

        // Same "logged-in user first, fall back to the line's stored corporate id" pattern
        // already used by createLineVersionSnapshot (line ~938-944): the running user in an
        // automated/async context sometimes has no ID_User__c, so fall back to the line's own.
        preloadUsersByLines(newLines);
        User loggedInUser = getCachedUserById(UserInfo.getUserId());
        String loggedInUserExtId = loggedInUser != null ? loggedInUser.ID_User__c : null;

        for (Id lineId : qualifyingLineIds) {
            DMT_Line__c line = newLinesById.get(lineId);
            DMT_Line__c groupInfo = groupInfoByLineId.get(lineId);

            String groupId = (groupInfo != null)
                ? (line.Client_Type__c == 'Customer'
                    ? groupInfo.Client__r?.DES_Main_Parent__r?.DES_Group_Code__c
                    : groupInfo.Client__r?.DES_group_Code__c)
                : null;

            if (String.isBlank(groupId)) {
                DMT_AsyncOrchestrator.enqueue(new DMT_LogExceptionPayload(
                    'Missing Group ID: cannot enqueue Recalculate Approvals for line ' + lineId,
                    null, null, null,
                    'DMT_Line_Helper', 'enqueueRecalculateApprovals', 'DMT', 'DMT_Line__c'
                ));
                continue;
            }

            Map<String, Object> inputMap = new Map<String, Object>();
            inputMap.put('groupId', groupId);

            String corporateUserId = !String.isBlank(loggedInUserExtId) ? loggedInUserExtId : line.DMT_ID_User__c;
            DMT_AsyncOrchestrator.enqueue(new DMT_ConsumptionReassignPayload(inputMap, corporateUserId));
        }
    }
    
    /**
     * Retries date updates for DMT_Line__c records that failed with UNABLE_TO_LOCK_ROW
     * during closeFather. Runs asynchronously after the triggering transaction commits.
     */
    public class CloseFatherRetryQueueable implements Queueable {
        private List<DMT_Line__c> linesToRetry;

        public CloseFatherRetryQueueable(List<DMT_Line__c> linesToRetry) {
            this.linesToRetry = linesToRetry;
        }

        public void execute(QueueableContext context) {
            if (linesToRetry == null || linesToRetry.isEmpty()) {
                return;
            }
            Database.update(linesToRetry, false);
        }
    }

    public void updateStartDateOnClosedWon(List<DMT_Line__c> newLines, Map<Id, DMT_Line__c> oldLinesMap) {

        Date today = Date.today();

        for (DMT_Line__c line : newLines) {
            DMT_Line__c oldLine = oldLinesMap.get(line.Id);

            Boolean isClosed          = line.Status__c == 'Closed' && line.Closed__c == 'Won' && !(oldLine.Status__c == 'Closed' && oldLine.Closed__c == 'Won');
            Boolean isValidTemplate   = line.DMT_line_template_type__c == 'TL' || line.DMT_line_template_type__c == 'OL';
            Boolean startDateIsInPast = line.Start_Date__c != null && line.Start_Date__c < today;

            if (isClosed && isValidTemplate && startDateIsInPast) {
                 line.Start_Date__c = today;
            }
        }
     
    }

    public void setDestinationSystemOnClosedWon(List<DMT_Line__c> newLines, Map<Id, DMT_Line__c> oldLinesMap){

        Map<String, DMT_Destination_Mapping__mdt> mappingsByRecordType = getCachedDestinationMappings();


        if (mappingsByRecordType.isEmpty()){
            System.debug('### DEST salida: CMDT vacío');
            return;
        }

        for (DMT_Line__c line : newLines){
            DMT_Line__c oldLine = oldLinesMap.get(line.Id);

            Boolean isClosedWon = line.Status__c == 'Closed' && line.Closed__c == 'Won'
                                  && !(oldLine.Status__c == 'Closed' && oldLine.Closed__c == 'Won');

            if (!isClosedWon){
                continue;
            }

            DMT_Destination_Mapping__mdt mapping = mappingsByRecordType.get(line.DMT_RecordTypeName__c);

            // Record types not parametrized yet are simply skipped
            if (mapping == null){
                continue;
            }

            line.DMT_Destination_Label__c  = mapping.DMT_Booking_System_Code__c;
            line.DMT_Destination_Status__c = mapping.DMT_Initial_Status__c;
            line.DMT_Destination_Light__c  = DMT_Line_Status_Process_Helper.LIGHT_YELLOW; 
            line.DMT_Destination_Error__c  = null;                                          
            line.DMT_Destination_Date__c   = null;                                              
        }
    }

    private static Map<String, DMT_Destination_Mapping__mdt> cachedDestinationMappings;

    private static Map<String, DMT_Destination_Mapping__mdt> getCachedDestinationMappings(){
        if (cachedDestinationMappings == null){
            cachedDestinationMappings = new Map<String, DMT_Destination_Mapping__mdt>();
            for (DMT_Destination_Mapping__mdt mapping : DMT_Destination_Mapping__mdt.getAll().values()){
                if (String.isNotBlank(mapping.DMT_RecordTypeName__c)){
                    cachedDestinationMappings.put(mapping.DMT_RecordTypeName__c, mapping);
                }
            }
        }
        return cachedDestinationMappings;
    }
    

    /**
     * Valida la continuidad e integridad de los registros DMT_Risk_Line_Term__c
     * agrupados por DMT_Risk_Type__c para cada DMT_Line__c.
     * Reglas:
     * 1. El primer tramo debe tener fecha de inicio y fecha de fin
     * 2. Cada tramo posterior debe comenzar exactamente donde termina el anterior
     * 3. No se permiten huecos temporales entre tramos
     * 4. No pueden existir combinaciones duplicadas de inicio+fin por tipo de riesgo
     * 5. No se permiten solapamientos parciales entre tramos
     */
    public void validateRiskLineTermContinuity(List<DMT_Line__c> newLines, Map<Id, DMT_Line__c> mapOldLines) {
        Set<Id> lineIds = new Set<Id>();
        for (DMT_Line__c line : newLines) {
            DMT_Line__c oldLine = mapOldLines != null ? mapOldLines.get(line.Id) : null;
            // Validar cada vez que el estado cambie
            if (oldLine != null && oldLine.Status__c != line.Status__c) {
                lineIds.add(line.Id);
            }
        }

        if (lineIds.isEmpty()) {
            return;
        }

        Map<Id, List<DMT_Risk_Line_Term__c>> riskLineTermsByLine = getAllRiskLineTermsByLine(lineIds);

        for (DMT_Line__c line : newLines) {
            List<DMT_Risk_Line_Term__c> allTerms = riskLineTermsByLine.get(line.Id);
            if (allTerms == null || allTerms.isEmpty()) {
                continue;
            }

            // Agrupar por DMT_Risk_Type__c
            Map<String, List<DMT_Risk_Line_Term__c>> termsByRiskType = new Map<String, List<DMT_Risk_Line_Term__c>>();
            for (DMT_Risk_Line_Term__c term : allTerms) {
                String riskType = term.DMT_Risk_Type__c;
                if (String.isBlank(riskType)) {
                    continue;
                }
                if (!termsByRiskType.containsKey(riskType)) {
                    termsByRiskType.put(riskType, new List<DMT_Risk_Line_Term__c>());
                }
                termsByRiskType.get(riskType).add(term);
            }

            // Validar cada grupo de tipo de riesgo de forma independiente
            for (String riskType : termsByRiskType.keySet()) {
                List<DMT_Risk_Line_Term__c> terms = termsByRiskType.get(riskType);
                String errorMsg = validateTermGroup(terms, riskType);
                if (errorMsg != null) {
                    line.addError(errorMsg);
                    break;
                }
            }
        }
    }

    private String validateTermGroup(List<DMT_Risk_Line_Term__c> terms, String riskType) {
        // Regla 4: Comprobar combinaciones duplicadas de inicio+fin
        Set<String> seenCombinations = new Set<String>();
        for (DMT_Risk_Line_Term__c term : terms) {
            String combo = term.DMT_Init_Term__c + '_' + term.DMT_End_Term__c;
            if (seenCombinations.contains(combo)) {
                return 'Tipo de riesgo ' + riskType + ': tramo duplicado con Init Term = ' + term.DMT_Init_Term__c + ' y End Term = ' + term.DMT_End_Term__c + '.';
            }
            seenCombinations.add(combo);
        }

        // Regla 1: El primer tramo debe tener inicio y fin poblados
        DMT_Risk_Line_Term__c firstTerm = terms[0];
        if (String.isBlank(firstTerm.DMT_Init_Term__c) || String.isBlank(firstTerm.DMT_End_Term__c)) {
            return 'Tipo de riesgo ' + riskType + ': el primer tramo debe tener Init Term y End Term poblados.';
        }

        // Validar continuidad y solapamientos recorriendo los tramos en el orden de la tabla
        for (Integer i = 0; i < terms.size(); i++) {
            DMT_Risk_Line_Term__c current = terms[i];
            if (String.isBlank(current.DMT_Init_Term__c) || String.isBlank(current.DMT_End_Term__c)) {
                return 'Tipo de riesgo ' + riskType + ': algún intervalo del tramo está vacío.';
            }
            Integer currentInit = Integer.valueOf(current.DMT_Init_Term__c);
            Integer currentEnd = Integer.valueOf(current.DMT_End_Term__c);

            // Validación básica: el fin debe ser mayor que el inicio
            if (currentEnd <= currentInit) {
                return 'Tipo de riesgo ' + riskType + ': el tramo con Init Term = ' + current.DMT_Init_Term__c + ' tiene End Term (' + current.DMT_End_Term__c + ') no mayor que Init Term.';
            }

            // Regla 5: Comprobar solapamientos parciales con el resto de tramos
            for (Integer j = i + 1; j < terms.size(); j++) {
                DMT_Risk_Line_Term__c other = terms[j];
                if (String.isBlank(other.DMT_Init_Term__c) || String.isBlank(other.DMT_End_Term__c)) {
                    return 'Tipo de riesgo ' + riskType + ': algún intervalo del tramo está vacío.';
                }
                Integer otherInit = Integer.valueOf(other.DMT_Init_Term__c);
                Integer otherEnd = Integer.valueOf(other.DMT_End_Term__c);

                // Dos intervalos se solapan si uno empieza antes de que termine el otro
                if (currentInit < otherEnd && otherInit < currentEnd && currentEnd != otherInit) {
                    return 'Tipo de riesgo ' + riskType + ': solapamiento parcial detectado entre tramo [' + current.DMT_Init_Term__c + '-' + current.DMT_End_Term__c + '] y tramo [' + other.DMT_Init_Term__c + '-' + other.DMT_End_Term__c + '].';
                }
            }

            // Reglas 2 y 3: Continuidad - cada tramo posterior debe empezar donde termina el anterior
            if (i > 0) {
                DMT_Risk_Line_Term__c previous = terms[i - 1];

                if (current.DMT_Init_Term__c != previous.DMT_End_Term__c) {
                    return 'Tipo de riesgo ' + riskType + ': hueco o discontinuidad detectada. El tramo [' + current.DMT_Init_Term__c + '-' + current.DMT_End_Term__c + '] no comienza donde termina el tramo anterior [' + previous.DMT_Init_Term__c + '-' + previous.DMT_End_Term__c + '].';
                }
            }
        }

        return null;
    }

    /**
     * @description Helper method que retorna IDs de líneas con Prospect en cliente o multiholder
     * Cliente directo: Busca Prospect_Group O Prospect_Subsidiary
     * Multiholder: Solo busca Prospect_Subsidiary
     * 
     * @param lineIds Set de IDs de líneas a validar
     * @param clientIds Set de IDs de clientes directos de las líneas
     * @return Set<Id> IDs de líneas que tienen Prospect (Prospect_Group o Prospect_Subsidiary)
     */
    public Set<Id> getLineIdsWithProspectInClientOrMultiholder(Set<Id> lineIds, Set<Id> clientIds) {
        Id prospectGroupRtId = Schema.SObjectType.Account.getRecordTypeInfosByDeveloperName().get('Prospect_Group').getRecordTypeId();
        Id prospectSubsidiaryRtId = Schema.SObjectType.Account.getRecordTypeInfosByDeveloperName().get('Prospect_Subsidiary').getRecordTypeId();        
        Set<Id> linesWithProspect = new Set<Id>();
        
        if (lineIds == null || lineIds.isEmpty() || clientIds == null || clientIds.isEmpty()) {
            return linesWithProspect;
        }
        
        // Trae todas las líneas con cliente directo y custom associations
        List<DMT_Line__c> lines = [SELECT Id, 
                                        Client__c,
                                        Client__r.RecordTypeId,
                                        (SELECT Id, 
                                                (SELECT Id, Alpha_Code_Client__c 
                                                    FROM Custom_Associations_Clients__r 
                                                    WHERE Alpha_Code_Client__c != null)
                                            FROM Custom_Associations__r)
                                    FROM DMT_Line__c
                                    WHERE Id IN :lineIds
                                    WITH SYSTEM_MODE
                                ];
        
        // PASO 1: Verificar cliente directo (Prospect_Group O Prospect_Subsidiary)
        for (DMT_Line__c line : lines) {
            if (line.Client__r != null && (line.Client__r.RecordTypeId == prospectGroupRtId || line.Client__r.RecordTypeId == prospectSubsidiaryRtId)) {
                linesWithProspect.add(line.Id);
            }
        }
        
        // PASO 2: Verificar multiholder (solo en líneas que NO tengan Prospect directo)
        Set<String> alphaCodes = new Set<String>();
        Map<String, Set<Id>> alphaCodeToLineIds = new Map<String, Set<Id>>();
        
        for (DMT_Line__c line : lines) {
            // Saltar líneas que ya tienen Prospect directo
            if (linesWithProspect.contains(line.Id)) {
                continue;
            }
            
            if (line.Custom_Associations__r != null && !line.Custom_Associations__r.isEmpty()) {
                for (Custom_Association__c ca : line.Custom_Associations__r) {
                    if (ca.Custom_Associations_Clients__r != null && !ca.Custom_Associations_Clients__r.isEmpty()) {
                        for (Custom_Association_Client__c cac : ca.Custom_Associations_Clients__r) {
                            alphaCodes.add(cac.Alpha_Code_Client__c);
                            
                            if (!alphaCodeToLineIds.containsKey(cac.Alpha_Code_Client__c)) {
                                alphaCodeToLineIds.put(cac.Alpha_Code_Client__c, new Set<Id>());
                            }
                            alphaCodeToLineIds.get(cac.Alpha_Code_Client__c).add(line.Id);
                        }
                    }
                }
            }
        }
        
        if (!alphaCodes.isEmpty()) {
            List<Account> prospectAccounts = [SELECT g_customer_id__c FROM Account WHERE g_customer_id__c IN :alphaCodes AND RecordTypeId = :prospectSubsidiaryRtId WITH SYSTEM_MODE];
            
            // Marcar líneas que tienen Prospect en multiholder
            for (Account acc : prospectAccounts) {
                if (alphaCodeToLineIds.containsKey(acc.g_customer_id__c)) {
                    linesWithProspect.addAll(alphaCodeToLineIds.get(acc.g_customer_id__c));
                }
            }
        }        
        return linesWithProspect;
    }

    /**
     * @description Valida si líneas tienen Prospect en cliente directo o multiholder (para LWC)
     * @param lineIds IDs de líneas a validar
     * @return Lista de boolean (true si tiene Prospect, false si no)
     */
    @AuraEnabled(cacheable=false)
    public static List<Boolean> checkProspectInLine(List<Id> lineIds) {
        List<Boolean> results = new List<Boolean>();
        Set<Id> clientIds = new Set<Id>();

        if (lineIds == null || lineIds.isEmpty()) {
            results.add(false);
            return results;
        }
        
        for (DMT_Line__c line : [SELECT Id, Client__c FROM DMT_Line__c WHERE Id IN :lineIds]) {
            if (line.Client__c != null) {
                clientIds.add(line.Client__c);
            }
        }
        
        DMT_Line_Helper helper = new DMT_Line_Helper();
        Set<Id> linesWithProspect = helper.getLineIdsWithProspectInClientOrMultiholder(new Set<Id>(lineIds), clientIds);
        
        for (Id lineId : lineIds) {
            results.add(linesWithProspect.contains(lineId));
        }
        return results;
    }

    /**
     * @description Bloquea el avance a "Closed Won" de líneas NO-SANCTION que tengan Prospect en cliente o multiholder
     */
    public void blockReadyToCloseWithProspectInMultiholder(List<DMT_Line__c> triggerNew, Map<Id, DMT_Line__c> triggerOldMap) {
        
        //Filtrar líneas NO-SANCTION cambiando a "Closed Won"
        Set<Id> lineIdsToValidate = new Set<Id>();
        Set<Id> clientIds = new Set<Id>();
        Map<Id, DMT_Line__c> linesToValidate = new Map<Id, DMT_Line__c>();
        
        for (DMT_Line__c line : triggerNew) {
            DMT_Line__c oldLine = triggerOldMap.get(line.Id);
            
            if (line.Status__c == DMT_Constants.CLOSED && 
                line.Closed__c == DMT_Constants.WON &&
                (oldLine.Status__c != DMT_Constants.CLOSED || oldLine.Closed__c != DMT_Constants.WON) && 
                line.Client__c != null) {                
                    lineIdsToValidate.add(line.Id);
                    clientIds.add(line.Client__c);
                    linesToValidate.put(line.Id, line);
            }
        }
        
        if (lineIdsToValidate.isEmpty()) {
            return;
        }
        
        //Usar el helper para obtener líneas con Prospect
        Set<Id> linesWithProspect = getLineIdsWithProspectInClientOrMultiholder(lineIdsToValidate, clientIds);
        
        //Bloquear líneas que tengan Prospect
        for (Id lineId : linesWithProspect) {
            if (linesToValidate.containsKey(lineId)) {
                DMT_Line__c line = linesToValidate.get(lineId);
                line.addError('You cannot close a Line if the associated client is a &apos;Prospect&apos;. Closing a Line implies that the contract is signed and the client must be &apos;Onboarded&apos; (or &apos;Active&apos;).');
            }
        }
    }
    

}