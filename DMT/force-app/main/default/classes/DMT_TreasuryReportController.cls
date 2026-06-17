public without sharing class DMT_TreasuryReportController {

    public class GroupWrapper {
        @AuraEnabled public String groupCode { get; set; }
        @AuraEnabled public List<ClientWrapper> clients { get; set; }
        @AuraEnabled public Integer totalRows { get; set; }
    }

    public class ClientWrapper {
        @AuraEnabled public String accountName { get; set; }
        @AuraEnabled public String sector { get; set; }
        @AuraEnabled public String customerId { get; set; }
        @AuraEnabled public String starCode { get; set; }
        @AuraEnabled public String fiscalId { get; set; }
        @AuraEnabled public String rating { get; set; }
        @AuraEnabled public List<LineWrapper> lines { get; set; }
        @AuraEnabled public Integer totalRows { get; set; }
    }

    public class LineWrapper {
        @AuraEnabled public String lineId { get; set; }
        @AuraEnabled public String dmtLineId { get; set; }
        @AuraEnabled public String currencyIsoCode { get; set; }
        @AuraEnabled public Decimal conversionFactor { get; set; }
        @AuraEnabled public String conversionLabel { get; set; }
        @AuraEnabled public String bookingGeography { get; set; }
        @AuraEnabled public Date startDate { get; set; }
        @AuraEnabled public Date endDate { get; set; }
        @AuraEnabled public String status { get; set; }
        @AuraEnabled public String addProd { get; set; }
        @AuraEnabled public List<RiskWrapper> risks { get; set; }
        @AuraEnabled public Integer totalRows { get; set; }
        @AuraEnabled public DateTime lastUpdated { get; set; }
    }

    public class RiskWrapper {
        @AuraEnabled public String lastLevelId { get; set; }
        @AuraEnabled public String typeOfRisk { get; set; }
        @AuraEnabled public String product { get; set; }
        @AuraEnabled public String naToNa { get; set; }
        @AuraEnabled public String zeroDaysTo3Years { get; set; }
        @AuraEnabled public String threeYearsTo5Years { get; set; }
        @AuraEnabled public String fiveYearsTo8Years { get; set; }
        @AuraEnabled public String eightYearsTo10Years { get; set; }
    }

    @AuraEnabled(cacheable=true)
    public static List<GroupWrapper> getDMTData() {
        List<GroupWrapper> result = new List<GroupWrapper>();

        List<DMT_Operational_Restrictions__mdt> productLabel = [SELECT Id, DeveloperName, Label, Description__c, Product_Group__c from DMT_Operational_Restrictions__mdt ];
        Map<String,String> productLabelMap = new Map<String,String>();
        for (DMT_Operational_Restrictions__mdt product : productLabel) {
            productLabelMap.put(product.DeveloperName,product.Product_Group__c);
        }

        // Query para DMT_Line__c
        List<DMT_Line__c> dmtLines = [
            SELECT Id, Client__c, CurrencyIsoCode, Booking_Geography__c,
                   Start_Date__c, End_Date__c, Line_ID__c, Status__c, LastModifiedDate, DMT_Additional_Restrictions__c, DMT_Status_Completed__c
            FROM DMT_Line__c
            WHERE DMT_line_status_type__c = 'CW' AND Booking_Geography__c IN ('AR', 'CO', 'MX') AND Client_Type__c = 'Customer' AND DMT_line_template_type__c = 'TL'
            ORDER BY LastModifiedDate, Line_ID__c
        ];
        Set<String> lineIds = new Set<String>();
        Set<String> lineCurrencies = new Set<String>();
        for (DMT_Line__c line : dmtLines) {
            lineIds.add(line.Line_ID__c);
            lineCurrencies.add(line.CurrencyIsoCode);
        }

        List<DMT_Currency_Conversion__mdt> objConversionFactorList = [SELECT Conversion_Factor__c, Currency_Label__c, CurrencyIsoCode__c FROM DMT_Currency_Conversion__mdt WHERE CurrencyIsoCode__c IN :lineCurrencies];
        Map<String, Decimal> currencyConversionMap = new Map<String, Decimal>();
        Map<String, String> currencyLabelMap = new Map<String, String>();

        for (DMT_Currency_Conversion__mdt currencyconversion : objConversionFactorList) {
            currencyConversionMap.put(currencyconversion.CurrencyIsoCode__c, currencyconversion.Conversion_Factor__c);
            currencyLabelMap.put(currencyconversion.CurrencyIsoCode__c, currencyconversion.Currency_Label__c);
        }
                // Query para Account con Parent Group
        Map<Id, Account> accountMap = new Map<Id, Account>([
            SELECT Id, Name, Group_Code_EGS__c, DES_AGGR_Sector__c,
                   g_customer_id__c, DES_ID_Fiscal__c, participant_name__c, DES_Rating_Int__c, SAL_Client_STAR_ID_Solo__c
            FROM Account
            WHERE Id IN (SELECT Client__c FROM DMT_Line__c WHERE Line_Id__c IN :lineIds)
            AND Group_Code_EGS__c != null
            ORDER BY g_customer_id__c,Group_Code_EGS__c
        ]);
        //Get sector

        List<DMT_Taxonomy_values__c> taxoC162B444 = [SELECT Id, DMT_Value__c, DMT_Name__c, DMT_Name_EN__c FROM DMT_Taxonomy_values__c WHERE DMT_Catalog__c IN ('C162','B444')];
        Map<String,String> taxoMap = new Map<String,String>();
        for ( DMT_Taxonomy_values__c taxo :taxoC162B444) {
            taxoMap.put(taxo.DMT_Value__c,taxo.DMT_Name_EN__c);
        }
        // Agrupar accounts por Parent Group Code
        Map<String, List<Account>> accountsByGroup = new Map<String, List<Account>>();
        for (Account acc : accountMap.values()) {
            if (!accountsByGroup.containsKey(acc.Group_Code_EGS__c)) {
                accountsByGroup.put(acc.Group_Code_EGS__c, new List<Account>());
            }
            accountsByGroup.get(acc.Group_Code_EGS__c).add(acc);
        }

        // Agrupar lines por Account Id
        Map<Id, List<DMT_Line__c>> linesByAccount = new Map<Id, List<DMT_Line__c>>();
        for (DMT_Line__c line : dmtLines) {
            if (!linesByAccount.containsKey(line.Client__c)) {
                linesByAccount.put(line.Client__c, new List<DMT_Line__c>());
            }
            linesByAccount.get(line.Client__c).add(line);
        }

        // Query para DMT_Consolidated_Line__c

        List<DMT_Consolidated_Line__c> consolidatedLines = [
            SELECT Id, Line_Id__c, g_limit_last_level_type__c, g_expert_criteria_risk_type__c,
                   gf_period_from_line_day_number__c, gf_clsfn_risk_type_internal_id__c, gf_condition_line_amount__c
            FROM DMT_Consolidated_Line__c
            WHERE Line_ID__c IN :lineIds AND g_line_status_type__c = 'CW' AND g_entific_id__c IN ('AR', 'CO', 'MX') AND gf_group_priority_line_id__c != '00'
            ORDER BY last_updated__c, g_limit_last_level_type__c
        ];

        // Agrupar consolidated lines por Line_ID__c
        Map<String, List<DMT_Consolidated_Line__c>> consolidatedByLineId = new Map<String, List<DMT_Consolidated_Line__c>>();
        for (DMT_Consolidated_Line__c cl : consolidatedLines) {
            if (!consolidatedByLineId.containsKey(cl.Line_ID__c)) {
                consolidatedByLineId.put(cl.Line_ID__c, new List<DMT_Consolidated_Line__c>());
            }
            consolidatedByLineId.get(cl.Line_ID__c).add(cl);
        }

        // Construir estructura jerárquica
        Integer groupTotalRows = 0;
        for (String groupCode : accountsByGroup.keySet()) {
            GroupWrapper groupWrapper = new GroupWrapper();
            groupWrapper.groupCode = accountsByGroup.get(groupCode)[0].participant_name__c;
            groupWrapper.clients = new List<ClientWrapper>();


            Integer clientTotalRows = 0;
            for (Account acc : accountsByGroup.get(groupCode)) {
                ClientWrapper clientWrapper = new ClientWrapper();
                clientWrapper.accountName = acc.Name;
                clientWrapper.sector = taxoMap.get(acc.DES_AGGR_Sector__c);
                clientWrapper.customerId = acc.g_customer_id__c;
                clientWrapper.starCode = acc.SAL_Client_STAR_ID_Solo__c;
                clientWrapper.fiscalId = acc.DES_ID_Fiscal__c;
                clientWrapper.rating = acc.DES_Rating_Int__c;
                clientWrapper.lines = new List<LineWrapper>();


                Integer lineTotalRows = 0;
                if (linesByAccount.containsKey(acc.Id)) {
                    for (DMT_Line__c line : linesByAccount.get(acc.Id)) {
                        LineWrapper lineWrapper = new LineWrapper();
                        lineWrapper.lineId = line.Line_ID__c;
                        lineWrapper.dmtLineId = line.Id;
                        lineWrapper.currencyIsoCode = line.CurrencyIsoCode;
                        lineWrapper.conversionFactor = currencyConversionMap.get(line.CurrencyIsoCode) != null ? currencyConversionMap.get(line.CurrencyIsoCode) : 1;
                        lineWrapper.conversionLabel = currencyLabelMap.get(line.CurrencyIsoCode) != null ? currencyLabelMap.get(line.CurrencyIsoCode) : '';
                        lineWrapper.bookingGeography = line.Booking_Geography__c;
                        lineWrapper.startDate = line.Start_Date__c;
                        lineWrapper.endDate = line.End_Date__c;
                        lineWrapper.status = line.DMT_Status_Completed__c;
                        lineWrapper.addProd = line.DMT_Additional_Restrictions__c == 'null' ? '' : line.DMT_Additional_Restrictions__c;
                        lineWrapper.lastUpdated = line.LastModifiedDate;
                        lineWrapper.risks = new List<RiskWrapper>();



                        if (consolidatedByLineId.containsKey(line.Line_ID__c)) {
                            // Agrupar por Last_Level_ID
                            Map<String, List<DMT_Consolidated_Line__c>> byLastLevel = groupByLastLevel(
                                consolidatedByLineId.get(line.Line_ID__c)
                            );

                            for (String lastLevelId : byLastLevel.keySet()) {
                                RiskWrapper riskWrapper = processRiskData(
                                    lastLevelId,
                                    byLastLevel.get(lastLevelId),
                                    productLabelMap,
                                    taxoMap
                                );
                                lineWrapper.risks.add(riskWrapper);
                                lineTotalRows++;
                            }
                        }

                        lineWrapper.totalRows = lineTotalRows > 0 ? lineTotalRows : 1;
                        clientWrapper.lines.add(lineWrapper);
                        clientTotalRows += lineWrapper.totalRows;
                    }
                }

                clientWrapper.totalRows = clientTotalRows > 0 ? clientTotalRows : 1;
                groupWrapper.clients.add(clientWrapper);
                groupTotalRows += clientWrapper.totalRows;
            }

            groupWrapper.totalRows = groupTotalRows;
            result.add(groupWrapper);
        }

        return result;
    }

    public static Map<String, List<DMT_Consolidated_Line__c>> groupByLastLevel(List<DMT_Consolidated_Line__c> lines) {
        Map<String, List<DMT_Consolidated_Line__c>> result = new Map<String, List<DMT_Consolidated_Line__c>>();

        for (DMT_Consolidated_Line__c line : lines) {
            if (!result.containsKey(line.g_limit_last_level_type__c)) {
                result.put(line.g_limit_last_level_type__c, new List<DMT_Consolidated_Line__c>());
            }
            result.get(line.g_limit_last_level_type__c).add(line);
        }

        return result;
    }

    public static RiskWrapper processRiskData(String lastLevelId, List<DMT_Consolidated_Line__c> lines, Map<String, String> productLabelMap, Map<String, String> taxoMap) {
        RiskWrapper risk = new RiskWrapper();
        risk.lastLevelId = taxoMap.get(lastLevelId);

        Set<String> expertCriteriaSet = new Set<String>();
        Set<String> riskTypes = new Set<String>();
        Map<String, String> periodMapping = new Map<String, String>();

        for (DMT_Consolidated_Line__c line : lines) {
            // Recolectar Expert_Criteria
            if (String.isNotBlank(line.g_expert_criteria_risk_type__c)) {
                expertCriteriaSet.add(productLabelMap.get(line.g_expert_criteria_risk_type__c));
            }

            // Recolectar Type of Risk
            if (String.isNotBlank(line.gf_clsfn_risk_type_internal_id__c)) {
                riskTypes.add(taxoMap.get(line.gf_clsfn_risk_type_internal_id__c));
            }

            // Mapear por periodo
            String periodField = getPeriodField(line.gf_period_from_line_day_number__c);
            if (periodField != null && line.g_expert_criteria_risk_type__c == null) {
                periodMapping.put(periodField, String.valueOf(line.gf_condition_line_amount__c));
            }
        }

        risk.product = String.join(new List<String>(expertCriteriaSet), ', ');
        risk.typeOfRisk = String.join(new List<String>(riskTypes), ', ');

        // Asignar a campos de periodo
        risk.naToNa = periodMapping.get('naToNa');
        risk.zeroDaysTo3Years = periodMapping.get('zeroDaysTo3Years');
        risk.threeYearsTo5Years = periodMapping.get('threeYearsTo5Years');
        risk.fiveYearsTo8Years = periodMapping.get('fiveYearsTo8Years');
        risk.eightYearsTo10Years = periodMapping.get('eightYearsTo10Years');

        return risk;
    }

    public static String getPeriodField(Decimal fromPeriod) {
        if (fromPeriod == null) return 'naToNa';
        if (fromPeriod == 0) return 'zeroDaysTo3Years';
        if (fromPeriod == 3*365) return 'threeYearsTo5Years';
        if (fromPeriod == 5*365) return 'fiveYearsTo8Years';
        if (fromPeriod == 8*365) return 'eightYearsTo10Years';
        return null;
    }
    
    @AuraEnabled(cacheable=true)       
    public static Boolean hasAccessUO() {
        User u = [
            SELECT DES_LevelUO_10__c
            FROM User
            WHERE Id = :UserInfo.getUserId()
            LIMIT 1
        ];
        List<DMT_TRSR_UO__mdt> uos = [
            SELECT UO_Code__c
            FROM DMT_TRSR_UO__mdt
        ];
        for (DMT_TRSR_UO__mdt uo : uos) {
            if (uo.UO_Code__c == u.DES_LevelUO_10__c) return true;
        }
        return false;
    }

}