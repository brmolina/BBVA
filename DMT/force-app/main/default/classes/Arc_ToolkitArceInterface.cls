/**
* ____________________________________________________________________________
* Interface Between Arce and Toolkit
* ____________________________________________________________________________
* @author      Santiago Vidal <Santiago.Vidal.contractor@bbva.com>
* @modifiedBy
* @version     1.0
* @created     2025-08-13
* @modified
* @systemLayer Sample
* ____________________________________________________________________________
* @changes
*
* ____________________________________________________________________________
*/
@SuppressWarnings('PMD.AvoidGlobalModifier, PMD.CyclomaticComplexity, PMD.CognitiveComplexity')
global with sharing class Arc_ToolkitArceInterface implements Callable {

    /**
    * @description Returns Client Arce Rating Id
    * @param args : Map whith following structure {'statusId' => '13','stage' => '3','submittedType' => new List<String>{'1', '2'},'groupCode' => 'AA11111111', 'ratingToolId' => new List<String>{'2012P1IRP', '2021RTC_GEN'}
    * @return Map<String, Object>
    */
    public String getClientArceRatingId(Map<String, Object> args) {
        String statusId = (String) args.get('statusId');
        String stage = (String) args.get('stage');
        List<String> submittedType = (List<String>) args.get('submittedType');
        String groupCode = (String) args.get('groupCode');
        List<String> ratingToolId = (List<String>) args.get('ratingToolId');
        String id; // Response

        String query = 'SELECT Id ' +
                 'FROM arce__Account_has_Analysis__c ' +
                 'WHERE arce__Analysis__r.arce__wf_status_id__c = :statusId ' +
                 'AND arce__Analysis__r.arce__Stage__c = :stage ' +
                 'AND arce__ffss_for_rating_id__r.arce__ffss_submitted_type__c IN :submittedType ' +
                 'AND DES_Local_Client__r.Cib_Client__r.business_group_header_type__c = true ' +
                 'AND DES_Local_Client__r.Cib_Client__r.DES_Main_Parent__r.DES_Group_Code__c = :groupCode ' +
                 'AND arce__Analysis__r.arce__rating_prerating_type__c = \'Rating\' ' +
                 'AND arce__RAR_rating_tool_id__c IN :ratingToolId ' +
                 'ORDER BY arce__ffss_for_rating_id__r.arce__ffss_submitted_type__c ASC, CreatedDate DESC';

        List<arce__Account_has_Analysis__c> queryResults = Database.query(query);

        if(!queryResults.isEmpty()){
            id = queryResults[0].Id;
        }

        // Serialize map into JSON for response
        return id;

        /*
        // How to invoque apex class
        Map<String, Object> parameters = new Map<String, Object>{
            'statusId' => '13',
            'stage' => '3',
            'submittedType' => new List<String>{'1', '2'},
            'groupCode' => 'AA11111111', //Example
            'ratingToolId' => new List<String>{'2012P1IRP', '2021RTC_GEN'}
        };

        Callable callable = (Callable) Type.forName('Arc_ToolkitArceInterface').newInstance();
        String jsonResult = (String) callable.call('getClientArceRatingId', parameters);
        System.debug(jsonResult);
        */
    }

    /**
    * @description Returns Client Arce Rating Id
    * @param args : Map whith following structure {'statusId' => '13','stage' => '3','submittedType' => new List<String>{'1', '2'},'prospectId' => 'AA11111111', 'ratingToolId' => new List<String>{'2012P1IRP', '2021RTC_GEN'}
    * @return Map<String, Object>
    */
    public String getProspectArceRatingId(Map<String, Object> args) {
        String statusId = (String) args.get('statusId');
        String stage = (String) args.get('stage');
        List<String> submittedType = (List<String>) args.get('submittedType');
        String prospectId = (String) args.get('prospectId');
        List<String> ratingToolId = (List<String>) args.get('ratingToolId');
        String id; // Response

        String query = 'SELECT id ' +
                'FROM arce__Account_has_Analysis__c ' +
                'WHERE arce__Analysis__r.arce__wf_status_id__c = :statusId ' +
                'AND arce__Analysis__r.arce__Stage__c = :stage ' +
                'AND arce__ffss_for_rating_id__r.arce__ffss_submitted_type__c IN :submittedType ' +
                'AND DES_Local_Client__r.Cib_Client__r.business_group_header_type__c = true ' +
                'AND DES_Local_Client__r.Cib_Client__r.DES_Main_Parent__c = :prospectId ' +
                'AND arce__Analysis__r.arce__rating_prerating_type__c = \'Prerating\' ' +
                'AND arce__RAR_rating_tool_id__c IN :ratingToolId ' +
                'ORDER BY arce__ffss_for_rating_id__r.arce__ffss_submitted_type__c ASC, CreatedDate DESC';

        List<arce__Account_has_Analysis__c> queryResults = Database.query(query);

        if(!queryResults.isEmpty()){
            id = queryResults[0].Id;
        }

        return id;

        /*
        // How to invoque apex class
        Map<String, Object> parameters = new Map<String, Object>{
            'statusId' => '13',
            'stage' => '3',
            'submittedType' => new List<String>{'1', '2'},
            'prospectId' => 'AA11111111' //Example
        };

        Callable callable = (Callable) Type.forName('Arc_ToolkitArceInterface').newInstance();
        String jsonResult = (String) callable.call('getProspectArceRatingId', parameters);
        System.debug(jsonResult);
        */
    }

    /**
    * @description Returns sectorization from arce__Activity_Split__c/arce__Activity_Split_2012__c based on arce__Account_has_Analysis__c id
    * @param args : Map whith following structure {'ratingId' => '1111111'}
    * @return Map<String, Object> map with the name and group
    */
    public List<Map<String, Object>> getSectorization(Map<String, Object> args) {
        Id ratingId = (Id) args.get('ratingId');
        List<Map<String, Object>> results = new List<Map<String, Object>>();

        List<AggregateResult> actSplitList = [
            SELECT toLabel(arce__sector_id__c) label_sector, toLabel(arce__Subsector_id__c) label_subsector, toLabel(arce__Subsector_id_2012__c) label_subsector2012,
                toLabel(arce__gf_company_economic_actvy_id__c) label_economic_act, toLabel(arce__gf_company_economic_actvy_id_2012__c) label_economic_act2012, SUM(arce__gf_subindustry_weight_per__c) sum_perc_activity
            FROM arce__Activity_Split__c
            WHERE arce__Account_has_Analysis__c = :ratingId
            GROUP BY arce__sector_id__c, arce__Subsector_id__c, arce__Subsector_id_2012__c, arce__gf_company_economic_actvy_id__c, arce__gf_company_economic_actvy_id_2012__c
            ORDER BY SUM(arce__gf_subindustry_weight_per__c) DESC
        ];

        if(!actSplitList.isEmpty() && !String.isEmpty(String.valueOf(actSplitList[0].get('label_sector')))){
            for (AggregateResult ar : actSplitList) {
                results.add(new Map<String, Object>{
                    'sector' => ar.get('label_sector'),
                    'subsector' => ar.get('label_subsector') != null ? ar.get('label_subsector') : ar.get('label_subsector2012'),
                    'economicActvy' => String.isBlank((String) ar.get('label_economic_act2012')) ? ar.get('label_economic_act') : ar.get('label_economic_act2012'),
                    'sumPercActivity' => ar.get('sum_perc_activity')
                });
            }
        }else{
            List<AggregateResult> actSplit2012List = [
                SELECT toLabel(arce__sector_id__c) label_sector, toLabel(arce__Subsector_id__c) label_subsector, toLabel(arce__gf_company_economic_actvy_id__c) label_economic_act, SUM(arce__gf_subindustry_weight_per__c) sum_perc_activity
                FROM arce__Activity_Split_2012__c
                WHERE arce__Account_has_Analysis__c = :ratingId
                GROUP BY arce__sector_id__c, arce__Subsector_id__c, arce__gf_company_economic_actvy_id__c
                ORDER BY SUM(arce__gf_subindustry_weight_per__c) DESC
            ];

            for (AggregateResult ar : actSplit2012List) {
                results.add(new Map<String, Object>{
                    'sector' => ar.get('label_sector'),
                    'subsector' => ar.get('label_subsector'),
                    'economicActvy' => ar.get('label_economic_act'),
                    'sumPercActivity' => ar.get('sum_perc_activity')
                });
            }
        }

        return results;
    }

    /**
    * @description Returns subsector information from arce__Activity_Split__c/arce__Activity_Split_2012__c based on arce__Account_has_Analysis__c id
    * @param args : Map whith following structure {'ratingId' => '1111111'}
    * @return Map<String, Object>
    */
    public String getSubsector(Map<String, Object> args) {
        Id ratingId = (Id) args.get('ratingId');
        String results;

        List<AggregateResult> actSplitList = [
            SELECT arce__Subsector_id__c, arce__Subsector_id_2012__c
            FROM arce__Activity_Split__c
            WHERE arce__Account_has_Analysis__c = :ratingId
            AND (toLabel(arce__gf_company_economic_actvy_id__c) != null OR toLabel(arce__gf_company_economic_actvy_id_2012__c) != null)
            GROUP BY arce__sector_id__c, arce__Subsector_id__c, arce__Subsector_id_2012__c
            ORDER BY SUM(arce__gf_subindustry_weight_per__c) DESC
        ];

        if (!actSplitList.isEmpty()) {
            results = actSplitList[0].get('arce__Subsector_id__c') != null ? String.valueOf(actSplitList[0].get('arce__Subsector_id__c')) : String.valueOf(actSplitList[0].get('arce__Subsector_id_2012__c'));
        } else {
            List<AggregateResult> actSplit2012List = [
                SELECT arce__Subsector_id__c
                FROM arce__Activity_Split_2012__c
                WHERE arce__Account_has_Analysis__c = :ratingId
                AND toLabel(arce__gf_company_economic_actvy_id__c) != null
                GROUP BY arce__sector_id__c, arce__Subsector_id__c
                ORDER BY SUM(arce__gf_subindustry_weight_per__c) DESC
            ];
            if (!actSplit2012List.isEmpty()){
                results = String.valueOf(actSplit2012List[0].get('arce__Subsector_id__c'));
            }
        }

        return results;
    }

    /**
    * @description Returns Capex information from arce__Table_Content_per_Analysis__c
    * @param args : Map whith following structure {'statusId' => '13','stage' => '3','submittedType' => new List<String>{'1', '2'},'groupCode' => 'AA11111111','year' => '2020','codeTerm' => new List<String>{'1', '2'}}
    * @return Map<String, Object>
    */
    public List<Map<String, Object>> getCapex(Map<String, Object> args) {
        String statusId = (String) args.get('statusId');
        String stage = (String) args.get('stage');
        List<String> submittedType = (List<String>) args.get('submittedType');
        String groupCode = (String) args.get('groupCode');
        String year = (String) args.get('year');
        List<String> codeTerm = (List<String>) args.get('codeTerm');
        List<Map<String, Object>> results = new List<Map<String, Object>>();

        Integer ffssYear = Integer.valueOf(year);

        String query = 'SELECT id, arce__ffss_for_rating_id__c, arce__ffss_for_rating_id__r.arce__financial_statement_id__c, arce__ffss_for_rating_id__r.arce__financial_statement_end_date__c '+
                    'FROM arce__Account_has_Analysis__c '+
                    'WHERE arce__Analysis__r.arce__wf_status_id__c = :statusId '+
                    'AND arce__Analysis__r.arce__Stage__c = :stage '+
                    'AND arce__ffss_for_rating_id__r.arce__ffss_submitted_type__c IN :submittedType '+
                    'AND DES_Local_Client__r.Cib_Client__r.business_group_header_type__c = true '+
                    'AND DES_Local_Client__r.Cib_Client__r.DES_Main_Parent__r.DES_Group_Code__c = :groupCode '+
                    'AND arce__Analysis__r.arce__rating_prerating_type__c = \'Rating\' '+
                    'AND CALENDAR_YEAR(arce__ffss_for_rating_id__r.arce__financial_statement_end_date__c) = :ffssYear '+
                    'ORDER BY arce__ffss_for_rating_id__r.arce__ffss_submitted_type__c ASC, CreatedDate DESC';

        List<arce__Account_has_Analysis__c> ahaList = Database.query(query);

        if(!ahaList.isEmpty() && !String.isEmpty(ahaList[0].arce__ffss_for_rating_id__c) && !String.isEmpty(ahaList[0].arce__ffss_for_rating_id__r.arce__financial_statement_id__c) && !String.isEmpty(String.valueOf(ahaList[0].arce__ffss_for_rating_id__r.arce__financial_statement_end_date__c)) && String.valueOf(ahaList[0].arce__ffss_for_rating_id__r.arce__financial_statement_end_date__c.year()) == year){
            final String finanStateId = ahaList[0].arce__ffss_for_rating_id__r.arce__financial_statement_id__c;

            List<arce__Table_Content_per_Analysis__c> tableContAnalysisList = [SELECT Id, LastModifiedDate, arce__original_amount__c, arce__original_currency__c, arce__Data_Collection_Id__r.arce__collection_code_term__c
                FROM arce__Table_Content_per_Analysis__c
                WHERE arce__Data_Collection_Id__r.arce__collection_code_term__c IN :codeTerm
                AND arce__table_content_parent_code_id__c = :finanStateId
                ORDER BY LastModifiedDate DESC
            ];

            for (arce__Table_Content_per_Analysis__c tbAnalysis : tableContAnalysisList) {
                results.add(new Map<String, Object>{
                    'Id' => tbAnalysis.Id,
                    'LastModifiedDate' => tbAnalysis.LastModifiedDate,
                    'arce__original_amount__c' => tbAnalysis.arce__original_amount__c,
                    'arce__original_currency__c' => tbAnalysis.arce__original_currency__c,
                    'arce__collection_code_term__c' => tbAnalysis.arce__Data_Collection_Id__r.arce__collection_code_term__c
                });
            }
        }

        return results;
    }

    /**
    * @description Returns geographies information based on ahaIds
    * @param args
    * @return Map<String, Object>
    */
    public List<Map<String, Object>> getClientGeographies(Map<String, Object> args) {
        String statusId = (String) args.get('statusId');
        String stage = (String) args.get('stage');
        List<String> submittedType = (List<String>) args.get('submittedType');
        String groupCode = (String) args.get('groupCode');
        String year = (String) args.get('year');
        List<Map<String, Object>> results = new List<Map<String, Object>>();

        Integer ffssYear = Integer.valueOf(year);

        String query = 'SELECT id, arce__ffss_for_rating_id__c, arce__ffss_for_rating_id__r.arce__financial_statement_id__c, arce__ffss_for_rating_id__r.arce__financial_statement_end_date__c, arce__RAR_rating_tool_id__c ' +
                    'FROM arce__Account_has_Analysis__c ' +
                    'WHERE arce__Analysis__r.arce__wf_status_id__c = :statusId ' +
                    'AND arce__Analysis__r.arce__Stage__c = :stage ' +
                    'AND arce__ffss_for_rating_id__r.arce__ffss_submitted_type__c IN :submittedType '+
                    'AND DES_Local_Client__r.Cib_Client__r.business_group_header_type__c = true ' +
                    'AND DES_Local_Client__r.Cib_Client__r.DES_Main_Parent__r.DES_Group_Code__c = :groupCode ' +
                    'AND arce__Analysis__r.arce__rating_prerating_type__c = \'Rating\' '+
                    'AND CALENDAR_YEAR(arce__ffss_for_rating_id__r.arce__financial_statement_end_date__c) = :ffssYear '+
                    'ORDER BY arce__ffss_for_rating_id__r.arce__ffss_submitted_type__c ASC, CreatedDate DESC LIMIT 1';

        List<arce__Account_has_Analysis__c> ahaList = Database.query(query);

        if(!ahaList.isEmpty()){
            results = getGeographiesData(ahaList, args);
        }

        return results;
    }

    /**
    * @description Returns geographies information based on ahaIds
    * @param args
    * @return Map<String, Object>
    */
    public List<Map<String, Object>> getProspectGeographies(Map<String, Object> args) {
        String statusId = (String) args.get('statusId');
        String stage = (String) args.get('stage');
        List<String> submittedType = (List<String>) args.get('submittedType');
        String prospectId = (String) args.get('prospectId');
        String year = (String) args.get('year');
        List<Map<String, Object>> results = new List<Map<String, Object>>();

        Integer ffssYear = Integer.valueOf(year);

        String query = 'SELECT id, arce__ffss_for_rating_id__c, arce__ffss_for_rating_id__r.arce__financial_statement_id__c, arce__ffss_for_rating_id__r.arce__financial_statement_end_date__c, arce__RAR_rating_tool_id__c ' +
                    'FROM arce__Account_has_Analysis__c ' +
                    'WHERE arce__Analysis__r.arce__wf_status_id__c = :statusId ' +
                    'AND arce__Analysis__r.arce__Stage__c = :stage ' +
                    'AND arce__ffss_for_rating_id__r.arce__ffss_submitted_type__c IN :submittedType '+
                    'AND DES_Local_Client__r.Cib_Client__r.business_group_header_type__c = true ' +
                    'AND DES_Local_Client__r.Cib_Client__r.DES_Main_Parent__c = :prospectId ' +
                    'AND arce__Analysis__r.arce__rating_prerating_type__c = \'Prerating\' '+
                    'AND CALENDAR_YEAR(arce__ffss_for_rating_id__r.arce__financial_statement_end_date__c) = :ffssYear '+
                    'ORDER BY arce__ffss_for_rating_id__r.arce__ffss_submitted_type__c ASC, CreatedDate DESC LIMIT 1';

        List<arce__Account_has_Analysis__c> ahaList = Database.query(query);

        if(!ahaList.isEmpty()){
            results = getGeographiesData(ahaList, args);
        }

        return results;
    }

    /**
    * @description Helper method for getClientGeographies & getProspectGeographies, returns geographies information based on ahaIds
    * @param args
    * @return Map<String, Object>
    */
    private List<Map<String, Object>> getGeographiesData(List<arce__Account_has_Analysis__c> ahaList, Map<String, Object> args){
        List<Map<String, Object>> results = new List<Map<String, Object>>();
        Set<Id> ahaListIds = new Set<Id>(); //NOSONAR
        String year = (String) args.get('year');

        ahaListIds = (new Map<Id, arce__Account_has_Analysis__c>(ahaList)).keySet().clone();

        if (!ahaListIds.isEmpty() && !String.isEmpty(ahaList[0].arce__ffss_for_rating_id__c) && !String.isEmpty(ahaList[0].arce__ffss_for_rating_id__r.arce__financial_statement_id__c) && !String.isEmpty(String.valueOf(ahaList[0].arce__ffss_for_rating_id__r.arce__financial_statement_end_date__c)) && String.valueOf(ahaList[0].arce__ffss_for_rating_id__r.arce__financial_statement_end_date__c.year()) == year) {
            final String typeSplit = ahaList[0].arce__RAR_rating_tool_id__c;
            final String arceYear = String.valueOf(ahaList[0].arce__ffss_for_rating_id__r.arce__financial_statement_end_date__c.year());
            final Map<String,String> mapActSplit = Util_PickList.getLabelFromAPI('arce__Activity_Split__c', 'arce__gf_activity_split_per_type__c');
            final Map<String,String> mapSectorId = Util_PickList.getLabelFromAPI('arce__Activity_Split__c', 'arce__sector_id__c');
            final Map<String,String> mapSubsectId = Util_PickList.getLabelFromAPI('arce__Activity_Split__c', 'arce__Subsector_id__c');
            final Map<String,String> mapEconAct = Util_PickList.getLabelFromAPI('arce__Activity_Split__c', 'arce__gf_company_economic_actvy_id__c');
            final Map<String,String> mapSubactId = Util_PickList.getLabelFromAPI('arce__Activity_Split__c', 'arce__gf_subactivity_id__c');
            final Map<String,String> mapTemplType = Util_PickList.getLabelFromAPI('arce__Activity_Split__c', 'arce__Template_type__c');
            // 2012 Variant
            final Map<String,String> mapSubsectId2012 = Util_PickList.getLabelFromAPI('arce__Activity_Split__c', 'arce__Subsector_id_2012__c');
            final Map<String,String> mapEconAct2012 = Util_PickList.getLabelFromAPI('arce__Activity_Split__c', 'arce__gf_company_economic_actvy_id_2012__c');
            final Map<String,String> mapSubactId2012 = Util_PickList.getLabelFromAPI('arce__Activity_Split__c', 'arce__gf_subactivity_id_2012__c');
            final Map<String,String> mapTemplType2012 = Util_PickList.getLabelFromAPI('arce__Activity_Split__c', 'arce__Template_type_2012__c');
            if (typeSplit == '2012P1IRP' && (arceYear == year)) {
                List<arce__Geographic_Split__c> geoSplitList = [SELECT Id, arce__Activity_Split__c, arce__Activity_Split__r.arce__gf_activity_split_per_type__c,
                            arce__Activity_Split__r.arce__sector_id__c, arce__Activity_Split__r.arce__Subsector_id__c, arce__Activity_Split__r.arce__gf_company_economic_actvy_id__c,
                            arce__Activity_Split__r.arce__gf_subactivity_id__c, arce__Activity_Split__r.arce__Template_type__c ,arce__Activity_Split__r.arce__gf_subindustry_weight_per__c,
                            arce__Country_2012__c,arce__gf_geography_weight_per__c, LastModifiedDate, arce__Activity_Split__r.arce__Subsector_id_2012__c, arce__Activity_Split__r.arce__gf_company_economic_actvy_id_2012__c,
                            arce__Activity_Split__r.arce__gf_subactivity_id_2012__c, arce__Activity_Split__r.arce__Template_type_2012__c
                            FROM arce__Geographic_Split__c
                            WHERE arce__Activity_Split__r.arce__Account_has_Analysis__c IN :ahaListIds
                            ORDER BY LastModifiedDate DESC];

                for (arce__Geographic_Split__c geo : geoSplitList){
                    results.add(new Map<String, Object>{
                    'Id' =>  geo.Id,
                    'arce__Activity_Split__c' => geo.arce__Activity_Split__c,
                    'label_activity_split' => mapActSplit.get(geo.arce__Activity_Split__r.arce__gf_activity_split_per_type__c),
                    'label_sector' => mapSectorId.get(geo.arce__Activity_Split__r.arce__sector_id__c),
                    'label_subsector' => geo.arce__Activity_Split__r.arce__Subsector_id__c != null ? mapSubsectId.get(geo.arce__Activity_Split__r.arce__Subsector_id__c) : mapSubsectId2012.get(geo.arce__Activity_Split__r.arce__Subsector_id_2012__c),
                    'label_econ_activity' => geo.arce__Activity_Split__r.arce__gf_company_economic_actvy_id__c != null ? mapEconAct.get(geo.arce__Activity_Split__r.arce__gf_company_economic_actvy_id__c) : mapEconAct2012.get(geo.arce__Activity_Split__r.arce__gf_company_economic_actvy_id_2012__c),
                    'label_subactivity' => geo.arce__Activity_Split__r.arce__gf_subactivity_id__c != null ? mapSubactId.get(geo.arce__Activity_Split__r.arce__gf_subactivity_id__c) : mapSubactId2012.get(geo.arce__Activity_Split__r.arce__gf_subactivity_id_2012__c),
                    'label_template_type' => geo.arce__Activity_Split__r.arce__Template_type__c != null ?  mapTemplType.get(geo.arce__Activity_Split__r.arce__Template_type__c) : mapTemplType2012.get(geo.arce__Activity_Split__r.arce__Template_type_2012__c),
                    'gf_subindustry_weight_per__c' => geo.arce__Activity_Split__r.arce__gf_subindustry_weight_per__c,
                    'Country' => geo.arce__Country_2012__c,
                    'gf_geography_weight_per__c' => geo.arce__gf_geography_weight_per__c,
                    'LastModifiedDate' => geo.LastModifiedDate,
                    'typeSplit' => typeSplit
                    });
                }
            } else if (typeSplit == '2012IRP' && (arceYear == year)) {
                List<arce__Activity_Split_2012__c> geoSplit2012List = [SELECT Id, arce__Country_2012__c, arce__gf_subindustry_weight_per__c, toLabel(arce__sector_id__c) label_sector, toLabel(arce__gf_activity_split_per_type__c) label_act_split, LastModifiedDate
                            FROM arce__Activity_Split_2012__c
                            WHERE arce__Account_has_Analysis__c IN :ahaListIds
                            ORDER BY LastModifiedDate DESC];

                for (arce__Activity_Split_2012__c geo : geoSplit2012List) {
                    results.add(new Map<String, Object>{
                    'Id' =>  geo.Id,
                    'Country' => geo.arce__Country_2012__c,
                    'gf_subindustry_weight_per__c' => geo.arce__gf_subindustry_weight_per__c,
                    'label_sector' => geo.get('label_sector'),
                    'label_activity_split' => geo.get('label_activity_split'),
                    'LastModifiedDate' => geo.LastModifiedDate,
                    'typeSplit' => typeSplit
                    });
                }
            }
        }

        return results;
    }

    /**
    * @description Returns Top5Activities information from arce__Activity_Split__c or arce__Activity_Split_2012__c based on AhaId
    * @param args
    * @return Map<String, Object>
    */
    public List<Map<String, Object>> getTop5Activities(Map<String, Object> args) {
        String statusId = (String) args.get('statusId');
        String stage = (String) args.get('stage');
        List<String> submittedType = (List<String>) args.get('submittedType');
        String groupCode = (String) args.get('groupCode');
        String year = (String) args.get('year');
        List<String> ratingToolId = (List<String>) args.get('ratingToolId');
        List<Map<String, Object>> results = new List<Map<String, Object>>();

        Integer ffssYear = Integer.valueOf(year);

        String query = 'SELECT id ' +
                    'FROM arce__Account_has_Analysis__c ' +
                    'WHERE arce__Analysis__r.arce__wf_status_id__c = :statusId ' +
                    'AND arce__Analysis__r.arce__Stage__c = :stage ' +
                    'AND arce__ffss_for_rating_id__r.arce__ffss_submitted_type__c IN :submittedType '+
                    'AND DES_Local_Client__r.Cib_Client__r.business_group_header_type__c = true ' +
                    'AND DES_Local_Client__r.Cib_Client__r.DES_Main_Parent__r.DES_Group_Code__c = :groupCode ' +
                    'AND arce__Analysis__r.arce__rating_prerating_type__c = \'Rating\' '+
                    'AND CALENDAR_YEAR(arce__ffss_for_rating_id__r.arce__financial_statement_end_date__c) = :ffssYear '+
                    'AND arce__RAR_rating_tool_id__c IN :ratingToolId ' +
                    'ORDER BY arce__ffss_for_rating_id__r.arce__ffss_submitted_type__c ASC, CreatedDate DESC LIMIT 1';

        List<arce__Account_has_Analysis__c> ahaList = Database.query(query);

        // If rating not empty, check activity with Aha Id
        if(!ahaList.isEmpty()){
            String ahaId = ahaList[0].Id;

            final List<AggregateResult> actSplitList = [SELECT toLabel(arce__sector_id__c), toLabel(arce__Subsector_id__c), toLabel(arce__Subsector_id_2012__c),
                                                            arce__gf_company_economic_actvy_id__c, arce__gf_company_economic_actvy_id_2012__c, SUM(arce__gf_subindustry_weight_per__c) perc
                                                        FROM arce__Activity_Split__c
                                                        WHERE arce__Account_has_Analysis__c =: ahaId
                                                        AND (arce__gf_company_economic_actvy_id__c != null
                                                        OR arce__gf_company_economic_actvy_id_2012__c != null)
                                                        GROUP BY arce__sector_id__c, arce__Subsector_id__c, arce__Subsector_id_2012__c, arce__gf_company_economic_actvy_id__c, arce__gf_company_economic_actvy_id_2012__c
                                                        ORDER BY SUM(arce__gf_subindustry_weight_per__c) DESC LIMIT 5];

            final List<arce__Activity_Split__c> actDate = [SELECT SystemModstamp
                                                        FROM arce__Activity_Split__c
                                                        WHERE arce__Account_has_Analysis__c =: ahaId
                                                        AND (arce__gf_company_economic_actvy_id__c != null
                                                        OR arce__gf_company_economic_actvy_id_2012__c != null)
                                                        ORDER BY SystemModstamp DESC LIMIT 5];
            if (!actSplitList.isEmpty()){

                Datetime arceDate = actDate[0].SystemModstamp;
                List<ActivityListWrapper> actListWrap = new List<ActivityListWrapper>();

                for (AggregateResult aggRes : actSplitList) {
                    ActivityListWrapper actPerc = new ActivityListWrapper();
                    actPerc.activity = aggRes.get('arce__gf_company_economic_actvy_id__c') != null ? String.valueOf(aggRes.get('arce__gf_company_economic_actvy_id__c')) : String.valueOf(aggRes.get('arce__gf_company_economic_actvy_id_2012__c'));
                    Object percVal = aggRes.get('perc');
                    actPerc.percent = (percVal != null) ? String.valueOf(percVal) : '';
                    actListWrap.add(actPerc);
                }

                ActivitiesWrapper actWrap = new ActivitiesWrapper();
                actWrap.activities = actListWrap;
                String arceActivities = String.valueOf(JSON.serialize(actWrap));
                Map<String, Object> resultEntry = new Map<String, Object>();
                resultEntry.put('activities', arceActivities);
                resultEntry.put('date', arceDate);
                results.add(resultEntry);

            }else{

                final List<AggregateResult> listaGeos = [SELECT toLabel(arce__sector_id__c), toLabel(arce__Subsector_id__c), arce__gf_company_economic_actvy_id__c, SUM(arce__gf_subindustry_weight_per__c) perc
                                                        FROM arce__Activity_Split_2012__c
                                                        WHERE arce__Account_has_Analysis__c =: ahaId
                                                        AND arce__gf_company_economic_actvy_id__c != null
                                                        GROUP BY arce__sector_id__c, arce__Subsector_id__c, arce__gf_company_economic_actvy_id__c
                                                        ORDER BY SUM(arce__gf_subindustry_weight_per__c) DESC LIMIT 5];

                final List<arce__Activity_Split_2012__c> actDate2 = [SELECT SystemModstamp FROM arce__Activity_Split_2012__c
                                                                    WHERE arce__Account_has_Analysis__c =: ahaId
                                                                    AND arce__gf_company_economic_actvy_id__c != null
                                                                    ORDER BY SystemModstamp DESC LIMIT 5];

                if (!listaGeos.isEmpty()) {
                    Datetime arceDate2 = actDate2[0].SystemModstamp;
                    List<ActivityListWrapper> actListWrap2 = new List<ActivityListWrapper>();

                    for (AggregateResult aggRes : listaGeos) {
                        ActivityListWrapper actPerc = new ActivityListWrapper();
                        actPerc.activity = String.valueOf(aggRes.get('arce__gf_company_economic_actvy_id__c'));
                        Object percVal = aggRes.get('perc');
                        actPerc.percent = (percVal != null) ? String.valueOf(percVal) : '';
                        actListWrap2.add(actPerc);
                    }

                    ActivitiesWrapper actWrap2 = new ActivitiesWrapper();
                    actWrap2.activities = actListWrap2;

                    Map<String, Object> resultEntry2 = new Map<String, Object>();
                    String arceActivities = String.valueOf(JSON.serialize(actWrap2));
                    resultEntry2.put('activities', arceActivities);
                    resultEntry2.put('date', arceDate2);
                    results.add(resultEntry2);
                }
            }
        }
        return results;
    }

    /**
    * @description
    * @param args
    * @return List<Map<String, Object>>
    */
    public List<Map<String, Object>> getCamn(Map<String, Object> args) {
        final String statusId = (String) args.get('statusId');
        final String stage = (String) args.get('stage');
        final List<String> submittedType = (List<String>) args.get('submittedType');
        final List<String> groupCode = (List<String>) args.get('groupCode');
        final List<String> ratingToolId = (List<String>) args.get('ratingToolId');
        List<Map<String, Object>> results = new List<Map<String, Object>>();

        String query = 'SELECT Id, arce__AHA_Extension__r.arce__Camn_API_Value__c, arce__AHA_Extension__r.arce__Camn_Label_Value__c, DES_Local_Client__r.Cib_Client__r.DES_Main_Parent__r.DES_Group_Code__c, CreatedDate ' +
                'FROM arce__Account_has_Analysis__c ' +
                'WHERE arce__Analysis__r.arce__wf_status_id__c = :statusId ' +
                'AND arce__Analysis__r.arce__Stage__c = :stage ' +
                'AND arce__ffss_for_rating_id__r.arce__ffss_submitted_type__c IN :submittedType ' +
                'AND DES_Local_Client__r.Cib_Client__r.business_group_header_type__c = true ' +
                'AND DES_Local_Client__r.Cib_Client__r.DES_Main_Parent__r.DES_Group_Code__c IN :groupCode ' +
                'AND arce__Analysis__r.arce__rating_prerating_type__c = \'Rating\' ' +
                'AND arce__RAR_rating_tool_id__c IN :ratingToolId ' +
                'ORDER BY arce__ffss_for_rating_id__r.arce__ffss_submitted_type__c ASC, CreatedDate DESC, DES_Local_Client__r.Cib_Client__r.DES_Main_Parent__r.DES_Group_Code__c DESC';

        final List<arce__Account_has_Analysis__c> ahaList = Database.query(query);

        if(!ahaList.isEmpty()){
            for(arce__Account_has_Analysis__c aha : ahaList){
                final SObject desLocal = aha.getSObject('DES_Local_Client__r');
                final SObject cibClient = desLocal != null ? desLocal.getSObject('Cib_Client__r') : null;
                final SObject mainParent = cibClient != null ? cibClient.getSObject('DES_Main_Parent__r') : null;
                final String grpCode = mainParent != null ? (String) mainParent.get('DES_Group_Code__c') : null;
                results.add(new Map<String, Object>{
                    'ahaId' => aha.Id,
                    'groupCode' => grpCode,
                    'camnApiValue' => aha.arce__AHA_Extension__r.arce__Camn_API_Value__c,
                    'camnLabelValue' => aha.arce__AHA_Extension__r.arce__Camn_Label_Value__c,
                    'createdDate' => aha.CreatedDate
                    });
            }
        }

        return results;
    }

    /**
    * @description Returns TopActivities information from arce__Activity_Split__c or arce__Activity_Split_2012__c based on AhaId
    * @param args
    * @return Map<String, Object>
    */
    public Map<String, Object> getTopActivities(Map<String, Object> args) {
        List<String> ahaList = (List<String>) args.get('ahaIdList');
        Map<String, Object> results = new Map<String, Object>();
        final Map<String, List<String>> mapGrpCodeActLst = new Map<String, List<String>>();

        // If rating not empty, check activity with Aha Id
        if(!ahaList.isEmpty()){
            Set<String> ahaIdSet = new Set<String>(ahaList);
            Set<String> queriedAhaIdSet = new Set<String>();

            final String actSplitQuery =
                'SELECT arce__Account_has_Analysis__r.DES_Local_Client__r.Cib_Client__r.DES_Main_Parent__r.DES_Group_Code__c grpCode,' +
                ' toLabel(arce__sector_id__c), toLabel(arce__Subsector_id__c), toLabel(arce__Subsector_id_2012__c), arce__gf_company_economic_actvy_id__c, arce__gf_company_economic_actvy_id_2012__c, arce__Account_has_Analysis__c' +
                ' FROM arce__Activity_Split__c' +
                ' WHERE arce__Account_has_Analysis__c IN :ahaIdSet' +
                ' AND (arce__gf_company_economic_actvy_id__c != null OR arce__gf_company_economic_actvy_id_2012__c != null)' +
                ' GROUP BY arce__Account_has_Analysis__r.DES_Local_Client__r.Cib_Client__r.DES_Main_Parent__r.DES_Group_Code__c, arce__sector_id__c, arce__Subsector_id__c, arce__gf_company_economic_actvy_id__c, arce__Subsector_id_2012__c, arce__gf_company_economic_actvy_id_2012__c, arce__Account_has_Analysis__c' +
                ' ORDER BY SUM(arce__gf_subindustry_weight_per__c) DESC';
            final List<AggregateResult> actSplitList = Database.query(actSplitQuery);
            if (!actSplitList.isEmpty()){

                for (AggregateResult aggRes : actSplitList) {
                    final String actId = aggRes.get('arce__gf_company_economic_actvy_id__c') != null ? String.valueOf(aggRes.get('arce__gf_company_economic_actvy_id__c')) : String.valueOf(aggRes.get('arce__gf_company_economic_actvy_id_2012__c'));
                    queriedAhaIdSet.add((String) aggRes.get('arce__Account_has_Analysis__c'));
                    if(!mapGrpCodeActLst.containsKey((String) aggRes.get('grpCode'))){
                        mapGrpCodeActLst.put((String) aggRes.get('grpCode'), new List<String>());
                    }
                    mapGrpCodeActLst.get((String) aggRes.get('grpCode')).add(actId);
                }

                //Remove already queried AhaIds
                ahaIdSet.removeAll(queriedAhaIdSet);
            }

            if(!ahaIdSet.isEmpty()){
                final String actSplit2Query =
                    'SELECT arce__Account_has_Analysis__r.DES_Local_Client__r.Cib_Client__r.DES_Main_Parent__r.DES_Group_Code__c grpCode,' +
                    ' toLabel(arce__sector_id__c), toLabel(arce__Subsector_id__c), arce__gf_company_economic_actvy_id__c' +
                    ' FROM arce__Activity_Split_2012__c' +
                    ' WHERE arce__Account_has_Analysis__c IN :ahaIdSet' +
                    ' AND arce__gf_company_economic_actvy_id__c != null' +
                    ' GROUP BY arce__Account_has_Analysis__r.DES_Local_Client__r.Cib_Client__r.DES_Main_Parent__r.DES_Group_Code__c, arce__sector_id__c, arce__Subsector_id__c, arce__gf_company_economic_actvy_id__c' +
                    ' ORDER BY SUM(arce__gf_subindustry_weight_per__c) DESC';
                final List<AggregateResult> actSplit2List = Database.query(actSplit2Query);

                for (AggregateResult aggRes : actSplit2List) {
                    final String actId = String.valueOf(aggRes.get('arce__gf_company_economic_actvy_id__c'));
                    if(!mapGrpCodeActLst.containsKey((String) aggRes.get('grpCode'))){
                        mapGrpCodeActLst.put((String) aggRes.get('grpCode'), new List<String>());
                    }
                    mapGrpCodeActLst.get((String) aggRes.get('grpCode')).add(actId);
                }
            }
        }

        if(!mapGrpCodeActLst.isEmpty()){
            for(String grpCode : mapGrpCodeActLst.keySet()){
                results.put(grpCode, String.valueOf(JSON.serialize(mapGrpCodeActLst.get(grpCode))));
            }
        }

        return results;
    }

    /**
    * @description Dispatch actual methods
    * @param action : name of method
    * @param args : map with the variables
    */
    public Object call(String action, Map<String, Object> args) {
        Object response = null;
        switch on action {
            when 'getClientArceRatingId' {
                response = this.getClientArceRatingId(args);
            }
            when 'getProspectArceRatingId' {
                response = this.getProspectArceRatingId(args);
            }
            when 'getSectorization'{
                response = this.getSectorization(args);
            }
            when 'getSubsector'{
                response = this.getSubsector(args);
            }
            when 'getCapex'{
                response = this.getCapex(args);
            }
            when 'getClientGeographies'{
                response = this.getClientGeographies(args);
            }
            when 'getProspectGeographies'{
                response = this.getProspectGeographies(args);
            }
            when 'getTop5Activities'{
                response = this.getTop5Activities(args);
            }
            when 'getCamn'{
                response = this.getCamn(args);
            }
            when 'getTopActivities'{
                response = this.getTopActivities(args);
            }
            when else {
                throw new ExtensionMalformedCallException('Method not implemented');
            }
        }
        return response;
    }

    /**
    * @description Activities wrapper class
    */
    public class ActivitiesWrapper {
        public List<ActivityListWrapper> activities;

        public ActivitiesWrapper() {
            activities = new List<ActivityListWrapper>();
        }
    }

    /**
    * @description ActivitiesList wrapper class
    */
    public class ActivityListWrapper {
        public String activity;
        public String percent;
    }

    /**
    * @description Extension class exception
    */
    public class ExtensionMalformedCallException extends Exception {}
}