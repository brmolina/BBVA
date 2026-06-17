/**
* ────────────────────────────────────────────────────────────────────
* CSTK_ES_Framework_Automation
* CSTK_ES_Framework_Automation class
* ────────────────────────────────────────────────────────────────────
* @author      Markel Landa <markel.landa.contractor@bbva.com>
* @modifiedBy
* @version     1.0
* @created     2025-12-12
* @modified
* @systemLayer Business
* ────────────────────────────────────────────────────────────────────
* @changes
*
* ────────────────────────────────────────────────────────────────────
*/
global with sharing class CSTK_ES_Framework_Automation implements Database.Batchable<sObject>  {
    
    /**
    * @description String with query to Strtegy object
    */
    private String queryStrategy;
    /**
    * @description String with year zero value
    */
    String yearZero = '0000';
    /**
    * @description String with segmentation filter value
    */
	String segmentation = 'C';

    /**
    * @description String with query to E&S Framework Automation object
    */
    private String queryESFrameworkAutomation;

    public CSTK_ES_Framework_Automation() {
        queryStrategy = 'SELECT Id, cstk__year__c, cstk__company_affected_by_framework__c, cstk__affected_sector__c, cstk__toolkit_id__c, cstk__toolkit_id__r.cstk__year__c, cstk__toolkit_id__r.cstk__toolkit_unique_id__c, cstk__toolkit_id__r.cstk__has_parent_prospect__c FROM cstk__Strategy__c WHERE cstk__Es_framework_edit__c = false AND cstk__year__c != :yearZero AND cstk__toolkit_id__r.cstk__account_id__r.DES_BBVA_Segmentation__c = :segmentation';
    }

    public Database.QueryLocator start(Database.BatchableContext BC) {
        return Database.getQueryLocator(queryStrategy);
    }

    public void execute(Database.BatchableContext BC, List<cstk__Strategy__c> stratList) {
        //Todays date
        Date consDate = Date.today().addMonths(-1);
        //List of Strategies to update
        List<cstk__Strategy__c> strategiesToUpdate = new List<cstk__Strategy__c>();
        //List of the group codes for the toolkits affected
        List<String> toolUniqueIds = new List<String>();
        //Response from arce interface with camn values
        List<Map<String, Object>> responseCamn = new List<Map<String, Object>>();
        //Map with group code and arce camns
        Map<String, String> arceCamns = new Map<String, String>();
        //Map to track arceCamn created date
        Map<String, DateTime> arceCamnDate = new Map<String, DateTime>();
        //Map with group code and arce activities
        Map<String, Object> arceActs = new Map<String, Object>();
        //Map with group code and camns from holding
        Map<String, String> masterCamns = new Map<String, String>();
        //Map with group code and activities from holding
        Map<String, String> masterActs = new Map<String, String>();
        //Map with group code and tiers from holding
        Map<String, String> masterTiers = new Map<String, String>();
        //Map with group code and created date
        Map<String, Datetime> masterDate = new Map<String, Datetime>();
        //Map with group code and holding activity
        Map<String, String> masterAct = new Map<String, String>();
        //Instance for callable to Arce Interface class
        final Callable callable = (Callable) Type.forName('Arc_ToolkitArceInterface').newInstance();
        //List with Account has Analysis Ids
        List<String> ahaIds = new List<String>();

        //Process strategies
        for (cstk__Strategy__c strat : stratList) {
            if (Integer.valueOf(strat.cstk__year__c) >= Integer.valueOf(strat.cstk__toolkit_id__r.cstk__year__c)) {
                strategiesToUpdate.add(strat);
                toolUniqueIds.add(strat.cstk__toolkit_id__r.cstk__toolkit_unique_id__c);
            }
        }

        //Query new Es Framework Object
        cstk__Es_framework_automation__c frameworkAuto = [SELECT Id, CreatedDate, cstk__sector_agriculture_act__c, cstk__sector_agriculture_camns__c, cstk__sector_defense_act__c, cstk__sector_defense_camns__c, cstk__sector_energy_act__c, cstk__sector_energy_camns__c, cstk__sector_infrastructure_act__c, cstk__sector_infrastructure_camns__c, cstk__sector_mining_act__c, cstk__sector_mining_camns__c, cstk__tier__c, cstk__year__c FROM cstk__Es_framework_automation__c ORDER BY CreatedDate DESC LIMIT 1];

        //Map with possible affected sectors and camns
        Map<String, Object> affectedSectMap = new Map<String, Object>();
        affectedSectMap.put('A', frameworkAuto.cstk__sector_agriculture_camns__c);
        affectedSectMap.put('D', frameworkAuto.cstk__sector_defense_camns__c);
        affectedSectMap.put('E', frameworkAuto.cstk__sector_energy_camns__c);
        affectedSectMap.put('I', frameworkAuto.cstk__sector_infrastructure_camns__c);
        affectedSectMap.put('M', frameworkAuto.cstk__sector_mining_camns__c);
        affectedSectMap.put('tiers', frameworkAuto.cstk__tier__c);

        //Map with posible affected activities
        Map<String, Object> affectedActMap = new Map<String, Object>();
        affectedActMap.put('A', frameworkAuto.cstk__sector_agriculture_act__c);
        affectedActMap.put('D', frameworkAuto.cstk__sector_defense_act__c);
        affectedActMap.put('E', frameworkAuto.cstk__sector_energy_act__c);
        affectedActMap.put('I', frameworkAuto.cstk__sector_infrastructure_act__c);
        affectedActMap.put('M', frameworkAuto.cstk__sector_mining_act__c);
        affectedActMap.put('tiers', frameworkAuto.cstk__tier__c);

        final Map<String, Object> parametersCamn = new Map<String, Object> {
            'statusId' => '13',
            'stage' => '3',
            'submittedType' => new List<String>{'1', '2'},
            'groupCode' => toolUniqueIds,
            'ratingToolId' => new List<String>{'2012P1IRP', '2021RTC_GEN'}
        };

        responseCamn = (List<Map<String, Object>>) callable.call('getCamn', parametersCamn);

        for (Map<String, Object> res : responseCamn) {
            if (arceCamnDate.get(String.valueOf(res.get('groupCode'))) > DateTime.valueOf(res.get('createdDate'))) {
                continue;
            } else {
                ahaids.add(String.valueOf(res.get('ahaId')));
                arceCamnDate.put(String.valueOf(res.get('groupCode')), DateTime.valueOf(res.get('createdDate')));
                arceCamns.put(String.valueOf(res.get('groupCode')), String.valueOf(res.get('camnApiValue')));
            }
        }

        final Map<String, Object> parametersAct = new Map<String, Object> {
            'ahaIdList' => ahaids
        };

        arceActs = (Map<String, Object>) callable.call('getTopActivities', parametersAct);

        //Get masterizacion camns y actividades
        List <Account> masterCamnsActs = [SELECT Id, DES_Main_Parent__r.DES_Group_Code__c, DES_Main_Parent__r.DES_Tier__c, g_min_risk_lvl_final_actvy_id__c, DES_Main_Parent__r.DES_Activity__c, CreatedDate FROM Account WHERE DES_Client_Type__c = 'Subsidiary' AND business_group_header_type__c = true AND DES_Main_Parent__r.DES_Group_Code__c IN :toolUniqueIds];

        for (Account masterCamnAct : masterCamnsActs) {
            if (String.isNotBlank(String.valueOf(masterCamnAct.g_min_risk_lvl_final_actvy_id__c)) && String.isNotBlank(String.valueOf(masterCamnAct.DES_Main_Parent__r.DES_Group_Code__c))){
                masterCamns.put(String.valueOf(masterCamnAct.DES_Main_Parent__r.DES_Group_Code__c), String.valueOf(masterCamnAct.g_min_risk_lvl_final_actvy_id__c));
            }
            if (String.isNotBlank(String.valueOf(masterCamnAct.DES_Main_Parent__r.DES_Tier__c)) && String.isNotBlank(String.valueOf(masterCamnAct.DES_Main_Parent__r.DES_Group_Code__c))) {
                masterTiers.put(String.valueOf(masterCamnAct.DES_Main_Parent__r.DES_Group_Code__c), String.valueOf(masterCamnAct.DES_Main_Parent__r.DES_Tier__c));
            }
            if (String.isNotBlank(String.valueOf(masterCamnAct.DES_Main_Parent__r.DES_Group_Code__c))) {
                masterDate.put(String.valueOf(masterCamnAct.DES_Main_Parent__r.DES_Group_Code__c), DateTime.valueOf(masterCamnAct.CreatedDate));
            }
            if (String.isNotBlank(String.valueOf(masterCamnAct.DES_Main_Parent__r.DES_Activity__c))) {
                masterAct.put(String.valueOf(masterCamnAct.DES_Main_Parent__r.DES_Group_Code__c), String.valueOf(masterCamnAct.DES_Main_Parent__r.DES_Activity__c));
            }
        }

        //Compare camns and activities
        for (cstk__Strategy__c strat : strategiesToUpdate) {
            Map<String, String> frameworkAffected = new Map<String, String>();
            if (masterDate.get(strat.cstk__toolkit_id__r.cstk__toolkit_unique_id__c) < consDate) {
                if (String.isNotBlank(arceCamns.get(strat.cstk__toolkit_id__r.cstk__toolkit_unique_id__c)) && String.isNotBlank(masterTiers.get(strat.cstk__toolkit_id__r.cstk__toolkit_unique_id__c))) {
                    frameworkAffected = checkCamns(affectedSectMap, arceCamns.get(strat.cstk__toolkit_id__r.cstk__toolkit_unique_id__c), masterTiers.get(strat.cstk__toolkit_id__r.cstk__toolkit_unique_id__c));
                } else if (String.isNotBlank(masterCamns.get(strat.cstk__toolkit_id__r.cstk__toolkit_unique_id__c)) && String.isNotBlank(masterTiers.get(strat.cstk__toolkit_id__r.cstk__toolkit_unique_id__c))) {
                    frameworkAffected = checkCamns(affectedSectMap, masterCamns.get(strat.cstk__toolkit_id__r.cstk__toolkit_unique_id__c), masterTiers.get(strat.cstk__toolkit_id__r.cstk__toolkit_unique_id__c));
                } else if (String.isNotBlank(String.valueOf(arceActs.get(strat.cstk__toolkit_id__r.cstk__toolkit_unique_id__c))) && String.isNotBlank(masterTiers.get(strat.cstk__toolkit_id__r.cstk__toolkit_unique_id__c))) {
                    frameworkAffected = checkActs(affectedActMap, arceActs.get(strat.cstk__toolkit_id__r.cstk__toolkit_unique_id__c), masterTiers.get(strat.cstk__toolkit_id__r.cstk__toolkit_unique_id__c));
                } else if (String.isNotBlank(masterAct.get(strat.cstk__toolkit_id__r.cstk__toolkit_unique_id__c))) {
                    frameworkAffected = checkActs(affectedActMap, masterActs.get(strat.cstk__toolkit_id__r.cstk__toolkit_unique_id__c), masterTiers.get(strat.cstk__toolkit_id__r.cstk__toolkit_unique_id__c));

                }
                //check new client/ prospect
            } else if (masterDate.get(strat.cstk__toolkit_id__r.cstk__toolkit_unique_id__c) >= consDate || strat.cstk__toolkit_id__r.cstk__has_parent_prospect__c == true) {
                //check camns
                if (String.isNotBlank(arceCamns.get(strat.cstk__toolkit_id__r.cstk__toolkit_unique_id__c))) {
                    frameworkAffected = checkCamns(affectedSectMap, arceCamns.get(strat.cstk__toolkit_id__r.cstk__toolkit_unique_id__c));
                } else if (String.isNotBlank(masterCamns.get(strat.cstk__toolkit_id__r.cstk__toolkit_unique_id__c))) {
                    frameworkAffected = checkCamns(affectedSectMap, masterCamns.get(strat.cstk__toolkit_id__r.cstk__toolkit_unique_id__c));
                    //check acts
                } else if (String.isNotBlank(masterAct.get(strat.cstk__toolkit_id__r.cstk__toolkit_unique_id__c))) {
                    //Check new client or prospect client with activities arce
                    frameworkAffected = checkActs(affectedActMap, arceActs.get(strat.cstk__toolkit_id__r.cstk__toolkit_unique_id__c));
                } else if (String.isNotBlank(masterAct.get(strat.cstk__toolkit_id__r.cstk__toolkit_unique_id__c))) {
                    //Check new client or prospect client with activities holding
                    frameworkAffected = checkActs(affectedActMap, masterActs.get(strat.cstk__toolkit_id__r.cstk__toolkit_unique_id__c));
                }
            }

            if (String.isNotBlank(frameworkAffected.get('frameworkAffected'))) {
                strat.cstk__company_affected_by_framework__c = frameworkAffected.get('frameworkAffected');
            	if (frameworkAffected.get('frameworkAffected') == 'Yes') {
                	strat.cstk__affected_sector__c = frameworkAffected.get('sectorAffected');
            	}
            } else {
                strat.cstk__company_affected_by_framework__c = 'No';
                strat.cstk__affected_sector__c = null;
            }
        }

        //Update strategies 
        Database.update(strategiesToUpdate);
    }

    public void finish(Database.BatchableContext BC) {
        System.debug('Bathc finished.');
    }

    /**
    * @description Check Arce camns affected for consolidate clients
    * @param affectedSectMap: Map with affected sectors camn tiers
    * @param arceCamn: Camn from Rating
    * @param masterTier: Tier from Holding
    * @return Map: Affected Framework and sectors
    */
    private static Map<String, String> checkCamns(Map<String, Object> affectedSectMap, String camn, String tier) {
        Map<String, String> res = new Map<String, String>();
        Boolean frameworkAffected = false;
        List<String> sectorsAffected = new List<String>();
        String tiers = (String)(affectedSectMap.get('tiers'));
        affectedSectMap.remove('tiers');

        if (String.isNotBlank(tiers)) {
        	for (String sector : affectedSectMap.keySet()) {
            	if (String.valueOf(affectedSectMap.get(sector)).contains(camn) && tiers.contains(tier)) {
                	frameworkAffected = true;
                	sectorsAffected.add(sector);
            	}
        	}   
        }

        if (frameworkAffected) {
            res.put('frameworkAffected', 'Yes');
            res.put('sectorAffected', String.join(sectorsAffected, ';'));
        } else {
            res.put('frameworkAffected', 'No');
            res.put('sectorAffected', '');
        }
		affectedSectMap.put('tiers', tiers);
        return res;
    }
    
    /**
    * @description Check camns affected for new clients
    * @param affectedSectMap: Map with affected sectors camn tiers
    * @param arceCamn: Camn from Rating
    * @param masterCamn: Camn from Holding
    * @return Map: Affected Framework and sectors
    */
    private static Map<String, String> checkCamns(Map<String, Object> affectedSectMap, String camn) {
        Map<String, String> res = new Map<String, String>();
        Boolean frameworkAffected = false;
        List<String> sectorsAffected = new List<String>();
        String tiers = (String)(affectedSectMap.get('tiers'));
        affectedSectMap.remove('tiers');
        
        for (String sector : affectedSectMap.keySet()) {
            if (String.valueOf(affectedSectMap.get(sector)).contains(camn)) {
                frameworkAffected = true;
                sectorsAffected.add(sector);
            }
        }

        if (frameworkAffected) {
            res.put('frameworkAffected', 'Yes');
            res.put('sectorAffected', String.join(sectorsAffected, ';'));
        } else {
            res.put('frameworkAffected', 'No');
            res.put('sectorAffected', '');
        }

		affectedSectMap.put('tiers', tiers);
        return res;
    }

    /**
    * @description Check camns affected for consolidate clients
    * @param affectedActMap: Map with affected sectors camn tiers
    * @param arceCamn: Camn from Rating
    * @param masterCamn: Camn from Holding
    * @param masterTier: Tier from Holding
    * @return Map: Affected Framework and sectors
    */
    private static Map<String, String> checkActs(Map<String, Object> affectedActMap, List<String> acts, String tier) {
        Map<String, String> res = new Map<String, String>();
        Boolean frameworkAffected = false;
        List<String> sectorsAffected = new List<String>();
        String tiers = (String)(affectedActMap.get('tiers'));
        affectedActMap.remove('tiers');
        
        for (String sector : affectedActMap.keySet()) {
            for (String act : acts) {
                if (String.valueOf(affectedActMap.get(sector)).contains(act) && tiers.contains(tier)) {
                    frameworkAffected = true;
                    sectorsAffected.add(sector);
                    break;
                }
            }
        }

        if (frameworkAffected) {
            res.put('frameworkAffected', 'Yes');
            res.put('sectorAffected', String.join(sectorsAffected, ';'));
        } else {
            res.put('frameworkAffected', 'No');
            res.put('sectorAffected', '');
        }

        affectedActMap.put('tiers', tiers);
        return res;
    }

    /**
    * @description Check camns affected for consolidate clients
    * @param affectedActMap: Map with affected sectors camn tiers
    * @param arceCamn: Camn from Rating
    * @param masterCamn: Camn from Holding
    * @param masterTier: Tier from Holding
    * @return Map: Affected Framework and sectors
    */
    private static Map<String, String> checkActs(Map<String, Object> affectedActMap, Object act, String tier) {
        Map<String, String> res = new Map<String, String>();
        Boolean frameworkAffected = false;
        List<String> sectorsAffected = new List<String>();
        String tiers = (String)affectedActMap.get('tiers');
        affectedActMap.remove('tiers');
        
        for (String sector : affectedActMap.keySet()) {
                if (String.valueOf(affectedActMap.get(sector)).contains(String.valueOf(act)) && tiers.contains(tier)) {
                    frameworkAffected = true;
                    sectorsAffected.add(sector);
                    break;
                }
            }

        if (frameworkAffected) {
            res.put('frameworkAffected', 'Yes');
            res.put('sectorAffected', String.join(sectorsAffected, ';'));
        } else {
            res.put('frameworkAffected', 'No');
            res.put('sectorAffected', '');
        }

        affectedActMap.put('tiers', tiers);
        return res;
    }
    
    /**
    * @description Check camns affected for consolidate clients
    * @param affectedActMap: Map with affected sectors camn tiers
    * @param arceCamn: Camn from Rating
    * @param masterCamn: Camn from Holding
    * @param masterTier: Tier from Holding
    * @return Map: Affected Framework and sectors
    */
    private static Map<String, String> checkActs(Map<String, Object> affectedActMap, Object acts) {
        Map<String, String> res = new Map<String, String>();
        List<String> actList = (List<String>)acts;
        Boolean frameworkAffected = false;
        List<String> sectorsAffected = new List<String>();
        String tiers = (String)(affectedActMap.get('tiers'));
        affectedActMap.remove('tiers');
        
        for (String sector : affectedActMap.keySet()) {
            for (String act : actList) {
                if (String.valueOf(affectedActMap.get(sector)).contains(act)) {
                    frameworkAffected = true;
                    sectorsAffected.add(sector);
                    break;
                }
            }
        }

        if (frameworkAffected) {
            res.put('frameworkAffected', 'Yes');
            res.put('sectorAffected', String.join(sectorsAffected, ';'));
        } else {
            res.put('frameworkAffected', 'No');
            res.put('sectorAffected', '');
        }

        affectedActMap.put('tiers', tiers);
        return res;
    }
    
    /**
    * @description Check camns affected for consolidate clients
    * @param affectedActMap: Map with affected sectors camn tiers
    * @param arceCamn: Camn from Rating
    * @param masterCamn: Camn from Holding
    * @param masterTier: Tier from Holding
    * @return Map: Affected Framework and sectors
    */
    private static Map<String, String> checkActs(Map<String, Object> affectedActMap, String act) {
        Map<String, String> res = new Map<String, String>();
        Boolean frameworkAffected = false;
        List<String> sectorsAffected = new List<String>();
        String tiers = (String)(affectedActMap.get('tiers'));
        affectedActMap.remove('tiers');
        
        for (String sector : affectedActMap.keySet()) {
                if (String.valueOf(affectedActMap.get(sector)).contains(act)) {
                    frameworkAffected = true;
                    sectorsAffected.add(sector);
                    break;
                }
            }

        if (frameworkAffected) {
            res.put('frameworkAffected', 'Yes');
            res.put('sectorAffected', String.join(sectorsAffected, ';'));
        } else {
            res.put('frameworkAffected', 'No');
            res.put('sectorAffected', '');
        }

        affectedActMap.put('tiers', tiers);
        return res;
    }
}