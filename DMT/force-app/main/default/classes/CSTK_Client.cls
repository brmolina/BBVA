/**
* ____________________________________________________________________________
* Toolkit Client CIB
* CIB implementation of the interface Client_Itf
* ____________________________________________________________________________
* @author      Torcuato Tejada <torcuato.tejada.contractor@bbva.com>
* @modifiedBy
* @version     1.0
* @created     2021-05-23
* @modified
* @systemLayer Sample
* ____________________________________________________________________________
* @changes
*
* ____________________________________________________________________________
*/
@SuppressWarnings('PMD.AvoidGlobalModifier, PMD.CyclomaticComplexity, PMD.CognitiveComplexity')
global with sharing class CSTK_Client implements cstk.Client_Itf, Callable {

    /**
    * String representing the generic sector.
    **/
    public static final String SECTOR_GENERIC = 'generic';

    /**
    * @description Returns user permissions to manage a toolkit record
    * @param toolkitId : Id of the Toolkit
    * @param userId : Id of the User
    * @return Map<String, Boolean> map with the actions and permissions
    */
    global Map<String, Object> getClientInfo(Id toolkitId) {

        final Map<String, Object> res = new Map<String, Object>();
        final List<cstk__Toolkit__c> toolkits = [SELECT Id, Name, cstk__year__c, cstk__account_id__r.Name, cstk__account_id__r.DES_AGGR_Sector__c, cstk__account_id__r.DES_Tier__c, cstk__account_id__r.DES_Activity__c, cstk__account_id__r.DES_Group_Code__c, cstk__account_id__r.DES_Client_Type__c, cstk__account_id__r.DES_Country_of_Management__c, cstk__account_id__r.DES_BBVA_Segmentation__c, cstk__has_all_sector_info__c, cstk__has_parent_prospect__c FROM cstk__Toolkit__c WHERE Id =: toolkitId];

        if (!toolkits.isEmpty()) {
            //---------------------------------- Account data ----------------------------------//
            final String sectorPicklistLabel = Util_PickList.getLabelFromApi('Account', 'DES_AGGR_Sector__c').get(toolkits[0].cstk__account_id__r.DES_AGGR_Sector__c);
            final String activityPicklistLabel = Util_PickList.getLabelFromApi('Account', 'DES_Activity__c').get(toolkits[0].cstk__account_id__r.DES_Activity__c);
            final String tierPicklistLabel = Util_PickList.getLabelFromApi('Account', 'DES_Tier__c').get(toolkits[0].cstk__account_id__r.DES_Tier__c);
            final String segmentationPicklistLabel = Util_PickList.getLabelFromApi('Account', 'DES_BBVA_Segmentation__c').get(toolkits[0].cstk__account_id__r.DES_BBVA_Segmentation__c);
            final String groupCode = toolkits[0].cstk__account_id__r.DES_Group_Code__c;
            final String prospectId = toolkits[0].cstk__account_id__c;
            List<CSTK_Client.ActivityListWrapper> actListWrap = new List<CSTK_Client.ActivityListWrapper>();
            String ratingId;
            String sector;
			String percent;

            res.put('name', toolkits[0].Name);
            res.put('account', toolkits[0].cstk__account_id__r.Name);
            res.put('accountId', toolkits[0].cstk__account_id__c);
            res.put('accountGeography', toolkits[0].cstk__account_id__r.DES_Country_of_Management__c);
            res.put('segmentationType', segmentationPicklistLabel);
            res.put('type', toolkits[0].cstk__account_id__r.DES_Client_Type__c);
            res.put('groupCode', groupCode);
            res.put('htrActivity', activityPicklistLabel);
            res.put('tier', tierPicklistLabel);

            //---------------------------------- Manual Sector ----------------------------------//
            final cstk.Information_Sector_Manual_Selector selector = new cstk.Information_Sector_Manual_Selector(true);
            final List<cstk__Information_Sector_Manual__c> sectorManualList = selector.selectByToolkitIdAndYear(toolkits[0].Id, toolkits[0].cstk__year__c);
            
            if (!sectorManualList.isEmpty()) {
                final List<CSTK_Client.ActivityListWrapper> actListWrapManual = new List<CSTK_Client.ActivityListWrapper>();
                final List<String> listFieldsAllSectors = new List<String>{'cement','steel','auto','utilities','energy','autoparts','generic'};
                final List<String> percentFieldsList = cstk.Utils.getAllPercentageFieldList('cstk__Information_Sector_Manual__c', 5, 2);
                final Boolean isSubsector = sectorManualList[0].cstk__Subsector__c != null;

                for(String percentFieldName : percentFieldsList) {
                    final String lowerField = percentFieldName.replace('cstk__percentage_', '').replace('__c', '');
                    Decimal numPercentField = (Decimal) sectorManualList[0].get(percentFieldName);
                    // Get name sector correct
                    if ( numPercentField != null && numPercentField != 0 && listFieldsAllSectors.contains(lowerField)) {
                        String formattedSector = lowerField.substring(0,1).toUpperCase() + lowerField.substring(1).toLowerCase();

                        // Get sector info
                        CSTK_Client.ActivityListWrapper actPerc = new CSTK_Client.ActivityListWrapper();
                        actPerc.activity = formattedSector;
                        actPerc.percent = String.valueOf(numPercentField);
                        actListWrapManual.add(actPerc);
                    }
                }
                
                if (isSubsector) {
                        res.put('subsector', sectorManualList[0].get('cstk__Subsector__c'));
                }
                
				CSTK_Client.ActivityListWrapper sectorPercSecManual = CSTK_Utils.getSectorValues(actListWrapManual);
                sector = sectorPercSecManual.activity;
                percent = sectorPercSecManual.percent;

            } else {
            //---------------------------------- Arce/Holding Sector ----------------------------------//
                final cstk__toolkit_settings__mdt config = cstk.Utils.getGeneralConfiguration();
                final String sectorValues = config.cstk__toolkit_sector__c;
                final SectorWrapper allSectValues = (SectorWrapper)System.JSON.deserialize(sectorValues, SectorWrapper.class);

                // Callable Prospect Rating.
                if (toolkits[0].cstk__has_parent_prospect__c) {
                    final Map<String, Object> parameters = new Map<String, Object> {
                        'statusId' => '13',
                        'stage' => '3',
                        'submittedType' => new List<String>{'1', '2'},
                        'prospectId' => prospectId,
                        'ratingToolId' => new List<String>{'2012P1IRP', '2021RTC_GEN'}
                    };

                    final Callable callable = (Callable) Type.forName('Arc_ToolkitArceInterface').newInstance();
                    ratingId = (String) callable.call('getProspectArceRatingId', parameters);
                
                // Callable Client Rating.
                } else {
                    final Map<String, Object> parameters = new Map<String, Object> {
                        'statusId' => '13',
                        'stage' => '3',
                        'submittedType' => new List<String>{'1', '2'},
                        'groupCode' => groupCode,
                        'ratingToolId' => new List<String>{'2012P1IRP', '2021RTC_GEN'}
                    };

                    final Callable callable = (Callable) Type.forName('Arc_ToolkitArceInterface').newInstance();
                    ratingId = (String) callable.call('getClientArceRatingId', parameters);
                }

                if (!String.isBlank(ratingId)) {
                    // Callable Sector Information. 
                    final Map<String, Object> parameters = new Map<String, Object>{
                        'ratingId' => ratingId
                    };

                    final Callable callable = (Callable) Type.forName('Arc_ToolkitArceInterface').newInstance();
                    final List<Map<String, Object>> sectorInfo = (List<Map<String, Object>>) callable.call('getSectorization', parameters);
                    System.debug('********************' + sectorInfo);
                    

                    // Calculate sector with arce information.
                    if (!sectorInfo.isEmpty()) {

                        for (Map<String, Object> act : sectorInfo) {
                            String sectorId = (String) act.get('sector');
                            String subsectorId = (String) act.get('subsector');
                            String activityId = (String) act.get('economicActvy');
                            String sumPercent = String.valueOf((Decimal) act.get('sumPercActivity'));

                            CSTK_Client.ActivityListWrapper actPerc = new CSTK_Client.ActivityListWrapper();
                            actPerc.activity = CSTK_Utils.mapArceSector(sectorId, subsectorId, activityId, allSectValues.arceValues);
                            actPerc.percent = sumPercent;
                            actListWrap.add(actPerc);
                        }
                    } 
                }

                //---------------------------------- Arce Sector ----------------------------------//
                if (!actListWrap.isEmpty()) {
                    CSTK_Client.ActivityListWrapper sectorPerc = CSTK_Utils.getSectorValues(actListWrap);
                    sector = sectorPerc.activity;
                    percent = sectorPerc.percent;

                //---------------------------------- Holding Sector ----------------------------------//
                } else {
                    sector = CSTK_Utils.mapClientSector(sectorPicklistLabel, activityPicklistLabel, allSectValues.clientValues);
                    percent = '100';
                }
            }

            //---------------------------------- Add Generic for has_all_sector_info ----------------------------------//
            if (toolkits[0].cstk__has_all_sector_info__c != null && !toolkits[0].cstk__has_all_sector_info__c && !sector.contains('Generic')) {
                res.put('sector', 'Generic;' + sector );
                res.put('sectorPercent', '100;' + percent);
            
            } else if (toolkits[0].cstk__has_all_sector_info__c != null && !toolkits[0].cstk__has_all_sector_info__c && sector.contains('Generic')) {
                List<String> sectorList = sector.split(';');
                List<String> sectorPercentList = new List<String>();
                sectorList.remove(sectorList.indexOf('Generic'));

                for (String sect : sectorList) {
                    sectorPercentList.add('0');
                }
                    
                if (sectorList.isempty()) {
                    sectorList.add('Generic');
                    sectorPercentList.add('100');
                } else {
                    sectorList.add(0,'Generic');
                    sectorPercentList.add(0, '100');
                }
                res.put('sector', String.join(sectorList, ';'));
                res.put('sectorPercent', String.join(sectorPercentList, ';'));

            } else {
                res.put('sector', sector);
                res.put('sectorPercent', percent);
            }

            //---------------------------------- Get subsector for Generic ----------------------------------//
            if (!String.isBlank(ratingId) && sector.contains('Generic')) {
                // Callable Subsector.
                final Map<String, Object> parameters = new Map<String, Object>{
                'ratingId' => ratingId
                };

                final Callable callable = (Callable) Type.forName('Arc_ToolkitArceInterface').newInstance();
                final String subSector = (String) callable.call('getSubsector', parameters);

                if (!String.isBlank(subSector)) {
                    res.put('subsector', subSector);
                }
            }
        }

        return res;
    }

    /**
    * @description Returns Accounts Name and Group
    * @param accountId : Id of the Account
    * @return Map<String, Boolean> map with the name and group
    */
    global Map<String, Object> getClientNameGroup(String accountId) {
        final Map<String, Object> res = new Map<String, Object>();
        final List<Account> acc = [SELECT Name, DES_Group_Code__c, RecordType.DeveloperName, gf_customer_prospect_id__c, Subsector__c, DES_AGGR_Sector__c, DES_Activity__c, lei_id__c FROM Account WHERE Id = :accountId LIMIT 1];
        String activityPicklistLabel = Util_PickList.getLabelFromApi('Account', 'DES_Activity__c').get(acc[0].DES_Activity__c);
        String sectorPicklistLabel = Util_PickList.getLabelFromApi('Account', 'DES_AGGR_Sector__c').get(acc[0].DES_AGGR_Sector__c);
        String subsectorPicklistLabel = Util_PickList.getLabelFromApi('Account', 'Subsector__c').get(acc[0].Subsector__c);
        // KSAG-- Se da por hecho que aquí se tiene que pasar el label, y el valor de acc[0] es api
        if (!acc.isEmpty()) {
            res.put('name', acc[0].Name);
            res.put('RTDeveloperName', acc[0].RecordType.DeveloperName);
            res.put('accSubSector', subsectorPicklistLabel);
            res.put('accDesActivity', activityPicklistLabel);
            res.put('accDesAggrSector', sectorPicklistLabel);
            res.put('identifier', acc[0].gf_customer_prospect_id__c);
            res.put('leiId', acc[0].lei_id__c);

            if (!String.isEmpty(acc[0].DES_Group_Code__c)) {
                res.put('group', acc[0].DES_Group_Code__c);
            }
        }
        return res;
    }

    /**
    * @description get account Name
    * @param accountId : Id of the account
    * @return Name of account
    */
    global String getClientName(String accountId) {
        final List<Account> acc = [SELECT Name FROM Account WHERE Id = :accountId LIMIT 1];
        String accName = null;
        if (!acc.isEmpty()) {
            accName = acc[0].Name;
        }
        return accName;
    }

    /**
    * @description Method that returns an toolkit Id from a context_id
    * @param contextId name: contextId
    * @return Toolkit Id
    */
    global Id getToolkitId(Id contextId) {

        final Schema.SObjectType sobjectType = contextId.getSObjectType();
        final String sobjectName = sobjectType.getDescribe().getName();
        Id res;

        switch on sobjectName {
            when  'Account' {
                Id toolkitId = [SELECT Id FROM cstk__Toolkit__c WHERE cstk__account_id__c =: contextId].Id;
                res = toolkitId;
            }
            when else {
                res = contextId;
            }
        }
        return res;
    }

    /**
    * @description Method that returns an filtered set of account Ids
    * @param tier : filter by account tier
    * @param subsegment : filter by account subsegment
    * @param industry : filter by account industry
    * @param banker : filter by account banker
    * @return Set<Id>
    */
    global Set<Id> getAccountIds(Map<String,String> accountIdsMap) {
        final String tier       = accountIdsMap.get('Tier');
        final String subsegment = accountIdsMap.get('Subseg');
        final String industry   = accountIdsMap.get('Industry');
        final String banker     = accountIdsMap.get('Banker');

        Set<Id> toolkitids = new Set<Id>();
        List<String> criteria = new List<String>();

        criteria.add('cstk__account_id__r.DES_Client_Type__c = \'CIB Group\'');

        if (!String.isEmpty(tier)) {
            criteria.add('cstk__account_id__r.DES_Tier__c = \'' + String.escapeSingleQuotes(tier) + '\'');
        }

        if (!String.isEmpty(subsegment)) {
            criteria.add('cstk__account_id__r.DES_Subsegment__c = \'' + String.escapeSingleQuotes(subsegment) + '\'');
        }

        if (!String.isEmpty(industry)) {
            criteria.add('cstk__account_id__r.DES_AGGR_Sector__c = \'' + String.escapeSingleQuotes(industry) + '\'');
        }

        if (!String.isEmpty(banker)) {
            criteria.add('cstk__account_id__r.DES_Global_Banker_Ref__r.DES_User__c = \'' + String.escapeSingleQuotes(banker) + '\'');
            //criteria.add('cstk__account_id__r.DES_Global_Banker_Ref__c = \'' + String.escapeSingleQuotes(banker) + '\'');
        }

        if (!criteria.isEmpty()) {
        	final List<cstk__Toolkit__c> toolkits = Database.query('SELECT Id from cstk__Toolkit__c WHERE ' + String.join(criteria, ' AND ') + ' LIMIT 1000'); //NOSONAR
            toolkitids = (new Map<Id, cstk__Toolkit__c>(toolkits)).keySet().clone();
        }

        return toolkitids;
    }

    /**
    * @description Method that returns picklist values
    * @param name : name of picklist
    * @return Toolkit Id
    */
    global List<cstk.Picklist_Wrapper> createPicklist(String name) {

        List<cstk.Picklist_Wrapper> picklist = new List<cstk.Picklist_Wrapper>();

        switch on name {
            when 'tier' {
                picklist = cstk.Utils.picklistLabelandValue('Account', 'DES_Tier__c');
            }
            when 'subsegment' {
                picklist = cstk.Utils.picklistLabelandValue('cstk__ESG_Account_Subsegment__mdt', 'cstk__Subsegment__c');
            }
            when 'industry' {
                picklist = cstk.Utils.picklistLabelandValue('Account', 'DES_AGGR_Sector__c');
            }
            when 'provider' {
                picklist = cstk.Utils.picklistLabelandValue('cstk__Toolkit__c', 'cstk__Provider__c');
            }
        }

        cstk.Picklist_Wrapper pwr = new cstk.Picklist_Wrapper();
        pwr.label = 'Choose one...';
        pwr.value = '';

        if (picklist.isEmpty()) {
            picklist.add(pwr);
        } else {
            picklist.add(0, pwr);
        }

        return picklist;
    }
    /**
    * @description Method that returns picklist values
    * @param name : name of picklist
    * @return Toolkit Id
    */
    global List<cstk.Picklist_Wrapper> createPicklistByFilter(String name,Map<String, Object> mapafilter) {

        List<cstk.Picklist_Wrapper> picklistFiltered = new List<cstk.Picklist_Wrapper>();

        switch on name {
            when 'banker' {
                picklistFiltered = getBankerOptions(mapafilter);
            }
        }

        cstk.Picklist_Wrapper pwr = new cstk.Picklist_Wrapper();
        pwr.label = Label.cstk.choose_one;
        pwr.value = '';

        if (picklistFiltered.isEmpty()) {
            picklistFiltered.add(pwr);
        } else {
            picklistFiltered.add(0, pwr);
        }

        return picklistFiltered;
    }

    /**
    * @description returns the label and values of a BBVA Client Team
    * @return List<Picklist_Wrapper> of the BBVA Client Team values
    */
    global static List<cstk.Picklist_Wrapper> getBankerOptions(Map<String, Object> mapafilter) {
        List<cstk.Picklist_Wrapper> picklistValues = new List<cstk.Picklist_Wrapper>(); //NOSONAR
        List<Account> accounts = new List<Account>(); //NOSONAR
        if (mapafilter.keySet().size()>0) {
            // KSAG-- estos valores son api o label? deberían ser api para hacer un filtro correcto
            final String valuetier =  (String)mapafilter.get('tier'); //NOSONAR
            final String valueSubseg = Util_PickList.getAPIFromLabel('Account', 'DES_Subsegment__c', (String)mapafilter.get('subsegment')); //NOSONAR
            final String valueIndustry = Util_PickList.getAPIFromLabel('Account', 'DES_AGGR_Sector__c', (String)mapafilter.get('industry')); //NOSONAR


            List<String> criteria = new List<String>();
            criteria.add('DES_Global_Banker_Ref__c !=null ');
            if (!String.isEmpty(valuetier)) {
                criteria.add('DES_Tier__c = \'' + String.escapeSingleQuotes(valuetier) + '\'');
            }
            if (!String.isEmpty(valueSubseg)) {
                criteria.add('DES_Subsegment__c = \'' + String.escapeSingleQuotes(valueSubseg) + '\'');
            }
            if (!String.isEmpty(valueIndustry)) {
                criteria.add('DES_AGGR_Sector__c = \'' + String.escapeSingleQuotes(valueIndustry) + '\'');
            }
            if (!criteria.isEmpty()) {
                accounts = Database.query('SELECT Id, DES_Global_banker__c, DES_Global_banker__r.Name, DES_Global_Banker_Ref__c, DES_Global_Banker_Ref__r.Name, DES_Global_Banker_Ref__r.DES_User__c FROM Account WHERE ' + String.join(criteria, ' AND ') + ' LIMIT 1000'); //NOSONAR
            }

            Map<Id,String> mapaIdUserName = new Map<Id,String>();
            for (Account entry : accounts) {
                cstk.Picklist_Wrapper pick = new cstk.Picklist_Wrapper(); //NOSONAR
                if (mapaIdUserName.get(entry.DES_Global_Banker_Ref__r.DES_User__c)==null) {
                    mapaIdUserName.put(entry.DES_Global_Banker_Ref__r.DES_User__c,entry.DES_Global_Banker_Ref__r.Name);
                    pick.label = String.valueOf(entry.DES_Global_Banker_Ref__r.Name);
                    pick.value = String.valueOf(entry.DES_Global_Banker_Ref__r.DES_User__c);
                    picklistValues.add(pick);
                }
            }
        }
        return picklistValues;
    }
    /**
    * @description returns picklist values filtered
    * @return List<sObject> of picklist values prefiltered
    */
    global static List<SObject> getRecordsPicklist(String unprocessedQuery) {
        String sQuery = replaceLabelFiltersWithApiValues(unprocessedQuery);
        final List<AggregateResult> results = Database.query(sQuery); // NOSONAR
        final List<SObject> output = new List<SObject>();

        Map<String, String> sectorMap = Util_PickList.getLabelFromApi('Account', 'DES_AGGR_Sector__c');
        Map<String, String> subsegmentMap = Util_PickList.getLabelFromApi('Account', 'DES_Subsegment__c');

        for (AggregateResult eachResult : results) {
            SObject row = new Account(); // Or a generic SObject if you prefer: new SObject('Account')
            Map<String, Object> fields = eachResult.getPopulatedFieldsAsMap();

            for (String key : fields.keySet()) {
                Object value = fields.get(key);
                if (key == 'DES_AGGR_Sector__c' && value != null) {
                    row.put(key, sectorMap.get((String)value));
                } else if (key == 'DES_Subsegment__c' && value != null) {
                    row.put(key, subsegmentMap.get((String)value));
                } else {
                    row.put(key, value);
                }
            }

            output.add(row);
        }

        return output;
    }
    /**
    * @description Returns from arce__Table_Content_per_Analysis__c information
    * @param toolkitId : Id of the Toolkit
    * @return Map<String, Decimal> Capex / Revenues from ARCE
    */
    global Map<String, Object> getCapex(Id toolkitId, String year) {
        final Map<String, Object> res = new Map<String, Object>();
        List<arce__Table_Content_per_Analysis__c> response = new List<arce__Table_Content_per_Analysis__c>(); //NOSONAR
        final List<cstk__Toolkit__c> toolkits = [SELECT Name, cstk__account_id__r.Name, cstk__account_id__r.DES_AGGR_Sector__c, cstk__account_id__r.DES_Activity__c, cstk__account_id__r.DES_Group_Code__c FROM cstk__Toolkit__c WHERE Id =: toolkitId];
        if (!toolkits.isEmpty()) {
            final String groupCode = toolkits[0].cstk__account_id__r.DES_Group_Code__c;
            response = getCapexAndRevenues(groupCode, year);
        }
        for (arce__Table_Content_per_Analysis__c tbAnalys : response) {
            if (tbAnalys.arce__Data_Collection_Id__r.arce__collection_code_term__c == '712' && !res.containsKey('capexTotal')) {
                res.put('capexTotal', tbAnalys.arce__original_amount__c);
                res.put('capexTotalcurrencies', tbAnalys.arce__original_currency__c);
                res.put('date', tbAnalys.LastModifiedDate.date());
            }
            if (tbAnalys.arce__Data_Collection_Id__r.arce__collection_code_term__c == '700' && !res.containsKey('revenuesTotal')) {
                res.put('revenuesTotal', tbAnalys.arce__original_amount__c);
                res.put('revenuesTotalcurrencies', tbAnalys.arce__original_currency__c);
                res.put('date', tbAnalys.LastModifiedDate.date());
            }
        }
        return res;
    }

    /**
    * @description Returns from Arce information
    * @param groupCode : Account group code
    * @return List<arce__Table_Content_per_Analysis__c> list with CAPEX & Revenues information
    */
    global List<arce__Table_Content_per_Analysis__c> getCapexAndRevenues(String groupCode, String year) {
        List<arce__Table_Content_per_Analysis__c> response = new List<arce__Table_Content_per_Analysis__c>(); //NOSONAR
        Integer ffssYear = Integer.valueOf(year);
        final List<arce__Account_has_Analysis__c> listaHasAcc = [SELECT id, name, DES_Local_Client__c, arce__WF_Stage_WF_Status__c, arce__ffss_for_rating_id__c, arce__ffss_for_rating_id__r.arce__financial_statement_id__c, arce__ffss_for_rating_id__r.arce__financial_statement_end_date__c, arce__Analysis__r.arce__wf_status_id__c, arce__Analysis__r.arce__Stage__c, IsDeleted, CreatedDate, DES_Local_Client__r.Cib_Client__r.Name, DES_Local_Client__r.Cib_Client__r.DES_Main_Parent__r.DES_Group_Code__c
                                                                FROM arce__Account_has_Analysis__c
                                                                WHERE  arce__Analysis__r.arce__wf_status_id__c = '13' AND arce__Analysis__r.arce__Stage__c = '3' AND arce__ffss_for_rating_id__r.arce__ffss_submitted_type__c in ('1','2') AND DES_Local_Client__r.Cib_Client__r.business_group_header_type__c = true AND DES_Local_Client__r.Cib_Client__r.DES_Main_Parent__r.DES_Group_Code__c = :groupCode AND arce__Analysis__r.arce__rating_prerating_type__c = 'Rating' AND CALENDAR_YEAR(arce__ffss_for_rating_id__r.arce__financial_statement_end_date__c) = :ffssYear
                                                                ORDER BY arce__ffss_for_rating_id__r.arce__ffss_submitted_type__c ASC, CreatedDate DESC];
        if (!listaHasAcc.isEmpty() && !String.isEmpty(listaHasAcc[0].arce__ffss_for_rating_id__c) && !String.isEmpty(listaHasAcc[0].arce__ffss_for_rating_id__r.arce__financial_statement_id__c) && !String.isEmpty(String.valueOf(listaHasAcc[0].arce__ffss_for_rating_id__r.arce__financial_statement_end_date__c)) && String.valueOf(listaHasAcc[0].arce__ffss_for_rating_id__r.arce__financial_statement_end_date__c.year()) == year) {
            final String arceAnalyId = listaHasAcc[0].arce__ffss_for_rating_id__c;
            final String stateFinanId = listaHasAcc[0].arce__ffss_for_rating_id__r.arce__financial_statement_id__c;
            response = [SELECT Id, CreatedDate, LastModifiedDate, arce__account_has_analysis_id__c, arce__original_amount__c, arce__original_currency__c, arce__table_content_parent_code_id__c, arce__Data_collection_name__c, arce__Data_Collection_Id__r.arce__collection_code_term__c, arce__account_has_analysis_id__r.arce__Analysis__r.arce__end_date__c
                            FROM arce__Table_Content_per_Analysis__c
                            WHERE (arce__Data_Collection_Id__r.arce__collection_code_term__c = '700' OR arce__Data_Collection_Id__r.arce__collection_code_term__c= '712') AND arce__table_content_parent_code_id__c = :stateFinanId Order By LastModifiedDate DESC];
        }
        return response;
    }

    /**
    * @description Returns from NBC information
    * @param toolkitId : Id of the Toolkit
    * @return Map<String, Object> map with NBC information
    */
    global Map<String, Object> getNbcInfo(Id toolkitId) {

        String clientId = [SELECT cstk__account_id__c FROM cstk__Toolkit__c WHERE Id =:toolkitId].cstk__account_id__c;
        String mainClientId = [SELECT Id FROM account WHERE business_group_header_type__c = true AND DES_Main_Parent__c = :clientId ORDER BY LastModifiedDate DESC LIMIT 1].Id;

        Set<String> mainClientIds = new Set<string>{mainClientId};
        mainClientIds.add(mainClientId.substring(0, 15));

        List<DES_Template__c> nbc = [SELECT Id, Client_Id__c, gf_pitch_oppy_l12m_gm_desc__c, gf_pitch_oppy_l12m_gtb_desc__c, gf_pitch_oppy_l12m_ibf_desc__c, LastModifiedDate FROM DES_Template__c WHERE Client_Id__c IN :mainClientIds ORDER BY CreatedDate DESC NULLS LAST];

        final Map<String, Object> res = new Map<String, Object>();
        if (nbc.size() > 0) {
            res.put('last_gm', nbc[0].gf_pitch_oppy_l12m_gm_desc__c);
            res.put('last_gtb', nbc[0].gf_pitch_oppy_l12m_gtb_desc__c);
            res.put('last_ibf', nbc[0].gf_pitch_oppy_l12m_ibf_desc__c);
            if (nbc[0].gf_pitch_oppy_l12m_gm_desc__c != null || nbc[0].gf_pitch_oppy_l12m_gtb_desc__c != null || nbc[0].gf_pitch_oppy_l12m_ibf_desc__c != null) {
                res.put('date', nbc[0].LastModifiedDate.date());
            }
        }

        return res;
    }

    /**
    * @description returns picklist values filtered
    * @return List<SustainabilityContact_Wrapper> of all possible contacts for toolkit
    */
    global static List<cstk.SustainabilityContact_Wrapper> getAccountsToolkit(Set<Id> accGroupId, List<cstk.SustainabilityContact_Wrapper> suscon) {
        final List<Account> accounts = [SELECT Name, Id, DES_Group_Code__c FROM Account WHERE DES_Main_Parent__c IN :accGroupId AND business_group_header_type__c = true];
        final Set<Id> accountids = new Map<Id, Account>(accounts).keySet().clone();
        final List<Contact> contatcs = [SELECT Name, FirstName, LastName, Email, Department, Description, Id FROM Contact WHERE AccountId IN :accountids];

        Map<Id, cstk.SustainabilityContact_Wrapper> listSusWr = new Map<Id, cstk.SustainabilityContact_Wrapper>(); //NOSONAR
        for (cstk.SustainabilityContact_Wrapper susw : suscon) {
            susw.isToolkit = true;
            listSusWr.put(susw.contactId, susw);
        }
        for (Contact con : contatcs) {
            if (listSusWr.get(con.Id)==null) {
                cstk.SustainabilityContact_Wrapper consw = new cstk.SustainabilityContact_Wrapper(); //NOSONAR
                consw.contactId = con.Id;
                consw.name = con.Name;
                consw.firstname = con.FirstName;
                consw.lastname = con.LastName;
                consw.email = con.Email;
                consw.department = con.Department;
                consw.description = con.Description;
                consw.isToolkit = false;
                listSusWr.put(consw.contactId, consw);
            }
        }
        return listSusWr.values();
    }
    
    /**
    * @description returns contacts for engagement plan
    * @return List<SustainabilityContact_Wrapper> of all possible contacts for toolkit
    */
    global static List<cstk.SustainabilityContact_Wrapper> getAccountsEngaPlan(Set<Id> accGroupId, List<cstk.SustainabilityContact_Wrapper> suscon) {
        final List<Account> accounts = [SELECT Name, Id, DES_Group_Code__c FROM Account WHERE Id IN :accGroupId OR (DES_Main_Parent__c IN :accGroupId AND business_group_header_type__c = true)];
        final Set<Id> accountids = new Map<Id, Account>(accounts).keySet().clone();
        final List<Contact> contatcs = [SELECT Name, FirstName, LastName, Email, Department, Description, Id FROM Contact WHERE AccountId IN :accountids];

        Map<Id, cstk.SustainabilityContact_Wrapper> listSusWr = new Map<Id, cstk.SustainabilityContact_Wrapper>(); //NOSONAR
        for (cstk.SustainabilityContact_Wrapper susw : suscon) {
            susw.isToolkit = true;
            listSusWr.put(susw.contactId, susw);
        }
        for (Contact con : contatcs) {
            if (listSusWr.get(con.Id)==null) {
                cstk.SustainabilityContact_Wrapper consw = new cstk.SustainabilityContact_Wrapper(); //NOSONAR
                consw.contactId = con.Id;
                consw.name = con.Name;
                consw.firstname = con.FirstName;
                consw.lastname = con.LastName;
                consw.email = con.Email;
                consw.department = con.Department;
                consw.description = con.Description;
                consw.isToolkit = false;
                listSusWr.put(consw.contactId, consw);
            }
        }
        return listSusWr.values();
    }

    /**
    * @description Returns geography from arce
    * @param toolkitId : Id of the Toolkit
    * @param sector : Sector of the Toolkit
    * @return Wrapper with geography values
    */
    global List<cstk.Top5Geographies_Wrapper> getGeographyInfo(Id toolkitId, String sector, String year) {

        final List<cstk__Toolkit__c> toolkits = [SELECT Name, cstk__account_id__r.Name, cstk__account_id__r.DES_AGGR_Sector__c, cstk__account_id__r.DES_Group_Code__c, cstk__has_parent_prospect__c FROM cstk__Toolkit__c WHERE Id =: toolkitId];
        List<Map<String, Object>> response = new List<Map<String, Object>>();

        if (!toolkits.isEmpty()) {
            final String groupCode = toolkits[0].cstk__account_id__r.DES_Group_Code__c;
            final String prospectId = toolkits[0].cstk__account_id__c;

            // Callable Prospect Geos.
            if (toolkits[0].cstk__has_parent_prospect__c) {
                final Map<String, Object> parameters = new Map<String, Object> {
                    'statusId' => '13',
                    'stage' => '3',
                    'submittedType' => new List<String>{'1', '2'},
                    'prospectId' => prospectId,
                    'year' => year
                };

                final Callable callable = (Callable) Type.forName('Arc_ToolkitArceInterface').newInstance();
                response = (List<Map<String, Object>>) callable.call('getProspectGeographies', parameters);
    
            // Callable Client geos.
            } else {
                final Map<String, Object> parameters = new Map<String, Object> {
                    'statusId' => '13',
                    'stage' => '3',
                    'submittedType' => new List<String>{'1', '2'},
                    'groupCode' => groupCode,
                    'year' => year
                };

                final Callable callable = (Callable) Type.forName('Arc_ToolkitArceInterface').newInstance();
                response = (List<Map<String, Object>>) callable.call('getClientGeographies', parameters);

            }
        }

        List<cstk.Top5Geographies_Wrapper> geoLista = new List<cstk.Top5Geographies_Wrapper>(); //NOSONAR

        if (!response.isEmpty()) {
            final String typeSplit = (String) response[0].get('typeSplit');

            if (typeSplit == '2012P1IRP') { 
                geoLista = getGeographyInfoAUX(response);

            } else if (typeSplit == '2012IRP') {
                geoLista = getGeographyInfoOLD(response);

            }
        }

        for (Integer i = 0; i < geoLista.size(); i++) {
            for (Integer j = 0; j < geoLista.size(); j++) {
                if (j + 1 != geoLista.size()){
                    if (geoLista[j].mainGeo1EBITDA < geoLista[j+1].mainGeo1EBITDA) {
                        cstk.Top5Geographies_Wrapper wrapper = geoLista[j+1];
                        geoLista[j+1] = geoLista[j];
                        geoLista[j] = wrapper;
                    }
                }
            }
        }

        if (geoLista.size() > 0) {
            Integer i = geoLista.size() -1;
            while(i > 4){
                geoLista.remove(i);
                i--;
            }
        }

        return geoLista;
    }

    /**
    * @description Returns geography from arce
    * @param listaGeos : Geos from arce
    * @return Wrapper with geography values
    */
    global List<cstk.Top5Geographies_Wrapper> getGeographyInfoAUX(List<Map<String, Object>> response) {

        Map<String, Double> mapSubindPerct = new Map<String, Double>(); //NOSONAR //add subindustry and subindustry %
        List<cstk.Top5Geographies_Wrapper> geoLista = new List<cstk.Top5Geographies_Wrapper>(); //NOSONAR
        Map<String, Map<String, Double>> mapGeoSubsPerGeo = new Map<String, Map<String, Double>>(); //NOSONAR

        for (Map<String, Object> actSpli : response) {
            String labelEconAct = (String) actSpli.get('label_econ_activity');
            Decimal subinWeight = (Decimal) actSpli.get('gf_subindustry_weight_per__c');
            Decimal geowheight = (Decimal) actSpli.get('gf_geography_weight_per__c');
            String country = (String) actSpli.get('Country');
            mapSubindPerct.put(labelEconAct, subinWeight);

            Map<String, Double> aux = new Map<String, Double>(); //NOSONAR //subindustry and country %
            if (mapGeoSubsPerGeo.get(country) != null) { //get if country exists
                aux = mapGeoSubsPerGeo.get(country);
            }
            aux.put(labelEconAct, geowheight); //add subindustry and country %
            mapGeoSubsPerGeo.put(country, aux); //add country and map subindustry and country %
        }

        for (Map<String, Object> actSpli2 : response) {
            cstk.Top5Geographies_Wrapper geo = new cstk.Top5Geographies_Wrapper(); //NOSONAR
            Map<String, Double> aux = new Map<String, Double>(); //NOSONAR
            String country = (String) actSpli2.get('Country');
            Datetime lastModified = (Datetime) actSpli2.get('LastModifiedDate');
            String labelAct = (String) actSpli2.get('label_activity_split');

            if (mapGeoSubsPerGeo.get(country) != null) { //NOSONAR
                aux = mapGeoSubsPerGeo.get(country); //subindustry and country %
                Double perctCount = 0; //NOSONAR
                for (String subIndustry : aux.keySet()) { //get all same countries and different sub industries
                    perctCount = perctCount + (mapSubindPerct.get(subIndustry) * aux.get(subIndustry) / 100);
                }
                geo.mainGeo1Code = country;
                geo.mainGeo1EBITDA = perctCount / 100;
                geo.mainGeo1 = cstk.Utils.picklistLabel('arce__Geographic_Split__c', 'arce__Country_2012__c', country, country);
                geo.sourceDate = lastModified.date();
                geo.outOfDate = getDateBoolean(geo);
                geo.type = labelAct;
                geoLista.add(geo);
                mapGeoSubsPerGeo.remove(country); //removed processed country to avoid duplicates
            }
        }
        return geoLista;
    }

    /**
    * @description Returns geography from arce
    * @param listaGeos : Geos from arce
    * @return Wrapper with geography values
    */
    global List<cstk.Top5Geographies_Wrapper> getGeographyInfoOLD(List<Map<String, Object>> response) {

        List<cstk.Top5Geographies_Wrapper> geoLista = new List<cstk.Top5Geographies_Wrapper>(); //NOSONAR
        Map<String, Double> mapCounPerc = new Map<String, Double>(); //NOSONAR

        for (Map<String, Object> actSpli : response) {
            Decimal subinWeight = (Decimal) actSpli.get('gf_subindustry_weight_per__c');
            String country = (String) actSpli.get('Country');
            Double aux = 0; //NOSONAR

            if (mapCounPerc.get(country) != null) {
                aux = mapCounPerc.get(country);
            }
            aux = aux + subinWeight;
            mapCounPerc.put(country, aux);
        }
        for (Map<String, Object> actSpli2 : response) {
            String country = (String) actSpli2.get('Country');
            Datetime lastModified = (Datetime) actSpli2.get('LastModifiedDate');
            String labelAct = (String) actSpli2.get('label_activity_split');

            if (mapCounPerc.get(country) != null) {
                cstk.Top5Geographies_Wrapper geo = new cstk.Top5Geographies_Wrapper(); //NOSONAR
                geo.mainGeo1EBITDA = mapCounPerc.get(country);
                if (geo.mainGeo1EBITDA != null) {
                    geo.mainGeo1EBITDA = geo.mainGeo1EBITDA / 100;
                }
                geo.mainGeo1Code = country;
                geo.mainGeo1 = cstk.Utils.picklistLabel('arce__Activity_Split_2012__c', 'arce__Country_2012__c', country, country);
                geo.sourceDate = lastModified.date();
                geo.outOfDate = getDateBoolean(geo);
                geo.type = labelAct;
                geoLista.add(geo);
                mapCounPerc.remove(country);
            }
        }
        return geoLista;
    }

    /**
    * @description Returns geography from arce
    * @param toolkitId : Id of the Toolkit
    * @param sector : Sector of the Toolkit
    * @param year : year of the Toolkit
    * @return Wrapper with geography values
    */
    public String getGeographyInfoForArce(Id toolkitId, String sector, String year) {
        final List<cstk.Top5Geographies_Wrapper> listaGeos = getGeographyInfo( toolkitId,  sector,  year);
        return Json.serialize(listaGeos);
    }

    /**
    * @description This method returns year of arce validation
    * @param accANalysis: arce__Account_has_Analysis__c arce object
    * @return String year of arce
    */
    private static String getArceYear (arce__Account_has_Analysis__c accANalysis) {
        String yearArce = ''; //NOSONAR
        if (accANalysis.arce__Analysis__c != null && accANalysis.arce__Analysis__r.arce__end_date__c != null) {
            yearArce = String.valueOf(accANalysis.arce__Analysis__r.arce__end_date__c.year());
        }

        return yearArce;
    }

    /**
    * @description This method returns the sector Id
    * @param Top5Geographies_Wrapper: Wrapper of Top5Geographies
    * @return Boolean data is OutOfDate
    */
    private static Boolean getDateBoolean(cstk.Top5Geographies_Wrapper res) {
        Boolean outOfDate = false;
        if (res.sourceDate!=null && res.sourceDate.addYears(1) < System.now().date()) {
            outOfDate = true;
        }
        return outOfDate;
    }

    /**
    * @description Returns client information
    * @param toolkitId : Id of the Toolkit
    * @param year : Selected year on the picklist
    * @return String with user information
    */
    global String getCacheSessionToolkit(Id toolkitId, String year) {
        Cache.Session.put(toolkitId + 'year' + UserInfo.getUserId(), year);
        return 'Cache Setted';
    }

    /**
    * @description Returns Groups
    * @param toolkitId : Id of the Toolkit
    * @param year : Selected year on the picklist
    * @return String with user information
    */
    public static List<Map<String, Object>> getAccountsByName(String queryText, List<Id> excludeIds, String sectorName) {
        List<Local_Client__c> accountsList = new List<Local_client__c>(); //NOSONAR
        List<Map<String, Object>> res = new  List<Map<String, Object>>(); //NOSONAR
        Set<Id> accIdTri = new Set<Id>(); //NOSONAR
        String filter = ''; //NOSONAR
        try {
            final List<cstk__tri__c> listaTri = [SELECT Id, Name, cstk__account__c, cstk__account__r.Name FROM cstk__tri__c where cstk__sector__c = :sectorName AND cstk__status__c = 'validated' AND cstk__account__c NOT IN :excludeIds];
            for (cstk__tri__c tri : listaTri ) {
                   accIdTri.add(tri.cstk__account__c);
            }
            String queryString = 'SELECT Cib_Client__c, Name FROM Local_Client__c WHERE Name LIKE \'%' + String.escapeSingleQuotes(queryText) + '%\''; //NOSONAR
            if (!accIdTri.isEmpty()) { //NOSONAR
                queryString = queryString + ' AND Cib_Client__c IN (\'' + String.join(new List<Id>(accIdTri), '\',\'') + '\')'; //NOSONAR
            }

            accountsList = Database.query(queryString); //NOSONAR

            for (Local_Client__c client : accountsList ) {
                Map<String, Object> result = new Map<String, Object>{'Id' => client.Cib_Client__c, 'Name' => client.Name}; //NOSONAR
                res.add(result); //NOSONAR
            }

        } catch (Exception e) { //NOSONAR
            throw new AuraHandledException(e.getMessage()); //NOSONAR
        }
        return res;
    }

    /**
    * @description Get activities from arce filtered by client group code and year
    * @param toolkitId : Id of the Toolkit
    * @param year : Selected year on the picklist show data from
    * @return Map <String, Date> with user information
    */
    public static Map<String, Datetime> getGenericActivitiesFromArce(String toolkitId, String year) {

        final List<cstk__Toolkit__c> toolkits = [SELECT Id, Name, cstk__account_id__r.DES_Group_Code__c, cstk__year__c FROM cstk__Toolkit__c WHERE Id =: toolkitId];
        final String groupCode = toolkits[0].cstk__account_id__r.DES_Group_Code__c;
        Map <String, Datetime> res = new Map <String, Datetime>();        
        Datetime arceDate = null;

        // Callable Activities.
        final Map<String, Object> parameters = new Map<String, Object> {
            'statusId' => '13',
            'stage' => '3',
            'submittedType' => new List<String>{'1', '2'},
            'groupCode' => groupCode,
            'year' => year,
            'ratingToolId' => new List<String>{'2012P1IRP', '2021RTC_GEN'}
        };

        final Callable callable = (Callable) Type.forName('Arc_ToolkitArceInterface').newInstance();
        final List<Map<String, Object>> top5Activities = (List<Map<String, Object>>) callable.call('getTop5Activities', parameters);

        if (!top5Activities.isEmpty()) {

            for (Map<String, Object> top : top5Activities) {

                String topActsList = (String) top.get('activities');
            	arceDate = (DateTime) top.get('date');
                res.put(topActsList, arceDate);
            }
        }

        return res;   
    }

    /**
    * @description Change currency to currency values, based on €
    * @param amount : amount of the data
    * @param currencyNameOrigin : currency values from origin
    * @return Map <Double, String> with user information
    */
    public static Map<String, Double> getCurrencyExchangeRate(double amount, String currencyNameOrigin, String currencyNameDestino) {
        Map<String, Double> mapResult = new Map<String, Double>();
        Double amountResult = 0.00;
        /*Example: 
        currencyNameOrigin = 'MXN' //example of currency from arce
        currencyNameDestino = 'USD' //example currency of Toolkit
        amount = 1000000
        amountResult = 0 */
        
        List<SER_EUR_Currency_exchange_rate__c> listCurrency = [SELECT SER_Base_currency__c, SER_Counter_currency__c, SER_Exchange_rate__c 
                                                                FROM SER_EUR_Currency_exchange_rate__c 
                                                                WHERE SER_Base_currency__c = 'EUR' and SER_Counter_currency__c = :currencyNameOrigin 
                                                                ORDER BY CreatedDate desc LIMIT 1];
        if (!listCurrency.isEmpty()) {
            amountResult = amount / listCurrency[0].SER_Exchange_rate__c;
        
            List<SER_EUR_Currency_exchange_rate__c> listCurrency2 = [SELECT SER_Base_currency__c, SER_Counter_currency__c, SER_Exchange_rate__c 
                                                                     FROM SER_EUR_Currency_exchange_rate__c 
                                                                     WHERE SER_Base_currency__c = 'EUR' and SER_Counter_currency__c = :currencyNameDestino 
                                                                     ORDER BY CreatedDate desc LIMIT 1];
            if (!listCurrency2.isEmpty()) {
                amountResult = amountResult * listCurrency2[0].SER_Exchange_rate__c;
            	mapResult.put(currencyNameDestino, amountResult);
            }
        }
        return mapResult;
    }

    /**
    * @description Dispatch actual methods
    * @param action : name of method
    * @param args : map with the variables
    */
    public Object call(String action, Map<String, Object> args) {
        Object response = null;
        switch on action {
            when 'getGeographyInfo' {
                response = this.getGeographyInfoForArce((Id)args.get('toolkitId'), (String)args.get('sector'),(String)args.get('year'));
            }
            when 'getClientInfo' {
                response = this.getClientInfo((String)args.get('toolkitId'));
            }
            when else {
                throw new ExtensionMalformedCallException('Method not implemented');
            }
        }
        return response;
    }

    private static String replaceLabelFiltersWithApiValues(String unProcessedQuery) {
        String sQuery = unProcessedQuery;
        List<String> fields = new List<String>{'DES_Subsegment__c', 'DES_AGGR_Sector__c'};

        for (String field : fields) {
            String token = field + ' = \'';
            Integer start = sQuery.indexOf(token);
            if (start == -1) continue;

            Integer valueStart = start + token.length();
            Integer valueEnd = sQuery.indexOf('\'', valueStart);
            if (valueEnd <= valueStart) continue;

            String label = sQuery.substring(valueStart, valueEnd);
            String apiValue = Util_PickList.getAPIFromLabel('Account', field, label);

            if (apiValue != null) {
                sQuery = sQuery.replace(token + label + '\'', token + apiValue + '\'');
            }
        }
        return sQuery;
    }


    /**
    * @description Wrapper class containing ARCE activity values
    */
    global class ActivitiesWrapper {

        /**
        * @description Arce activities Wrapper List
        */
        @AuraEnabled
        global List<ActivityListWrapper> activities { get;set; }

    }

    /**
    * @description Wrapper class containing ARCE activity List
    */
    global class ActivityListWrapper {

        /**
        * @description Arce activity
        */
        @AuraEnabled
        global String activity{ get;set; }

        /**
        * @description Arce percent
        */
        @AuraEnabled
        global String percent { get;set; }

    }

    /**
    * @description Wrapper class containing Sector values
    */
    global class SectorWrapper {
        
        /**
        * @description Arce Sector Wrapper List
        */
        @AuraEnabled
        global List<ArceWrapper> arceValues { get;set; }
    
        /**
        * @description Client Sector Wrapper List
        */
        @AuraEnabled
        global List<ClientWrapper> clientValues { get;set; }

    }
    
    global class ArceWrapper {

        /**
        * @description Arce sector
        */
        @AuraEnabled
        global String sector { get;set; }
    
        /**
        * @description Arce subsector
        */
        @AuraEnabled
        global String subsector { get;set; }
    
        /**
        * @description Arce activity
        */
        @AuraEnabled
        global String actividad { get;set; }
    
        /**
        * @description Arce Toolkit Sector
        */
        @AuraEnabled
        global String result { get;set; }
    }
    
    global class ClientWrapper {
    
        /**
        * @description Client sector
        */
        @AuraEnabled
        global String sector { get;set; }
        
        /**
        * @description Client activity
        */
        @AuraEnabled
        global String actividad { get;set; }

        /**
        * @description Client Toolkit sector
        */
        @AuraEnabled
        global List<String> exclusion { get;set; }
    
        /**
        * @description Client Toolkit sector
        */
        @AuraEnabled
        global String result { get;set; }
    }

    /**
    * @description Extension class exception
    */
    public class ExtensionMalformedCallException extends Exception {}
}