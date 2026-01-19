/**
* ------------------------------------------------------------------------------------------------
* @Name     Arc_Gen_PersistenceLimits_helper
* @Author   Juan Ignacio Hita Manso
* @Date     Created: 2020-30-09
* @Group    ARCE
* -----------------------------------------------------------------------------------------------
* @Description Class with methods used in persistence services of limit exposures
* -----------------------------------------------------------------------------------------------
* @Changes
*
* |2020-10-01 Juan Ignacio Hita Manso
*             Class creation.
* |2020-12-14 Juan Ignacio Hita Manso
*             Changes limitsJSON method for add persistence limit service
* |2020-05-14 Juan Ignacio Hita Manso
*             Add arce__limit_exposure_ext_ind_type__c in logic createRiskAmounts method
* |2021-06-14 Juan Ignacio Hita Manso
*             Changes API_RISKAMOUNT and API_RISKCOND fields
* |2021-07-12 Juan Ignacio Hita Manso
*             Remove validation of extended button for TOTAL CREDIT RISK
*             Change the mapped field for APPROVED key
* -----------------------------------------------------------------------------------------------
*/
public without sharing class Arc_Gen_PersistenceLimits_helper {

    /**
        * @Description: Label of the fields of risk amount section
    */
    private static final List<String> LBL_RISKAMOUNT = new List<String> {'LAST_APPROVED_LIMIT',
                                                            'APPROVED_COMMITED',
                                                            'APPROVED_UNCOMMITED',
                                                            'APPROVED',
                                                            'FORMALIZED', 'PROPOSED', 'OUTSTANDING'};
    /**
        * @Description: Api names of the fields of the risk amounts section
    */
    private static final List<String> API_RISKAMOUNT = new List<String> {'arce__last_approved_amount__c',
                                        'arce__curr_approved_commited_amount__c',
                                        'arce__curr_apprv_uncommited_amount__c',
                                        'arce__current_proposed_amount__c', // Maps arce__current_proposed_amount__c field as APPROVED key temporally
                                        'arce__current_formalized_amount__c',
                                        'arce__current_proposed_amount__c',
                                        'arce__outstanding_amount__c'};
    /**
        * @Description: Api names of the fields of the risk conditions section
    */
    private static final List<String>  API_RIKSCOND = new List<String> {'arce__curr_apprv_deleg_rm_amount__c',
                                                            'arce__curr_apprv_deleg_dchan_amount__c',
                                                            'arce__current_apprv_limit_term_type__c', 'arce__cust_amortized_oblg_type__c',
                                                            'arce__grace_months_number__c','arce__shareholder_gntee_limit_type__c',
                                                            'arce__notary_certification_type__c', 'arce__amortization_type_desc__c',
                                                            'arce__currency_id__c','arce__no_real_guarantee_type__c','arce__treasury_break_clause_date__c',
                                                            'arce__real_guarantee_type__c','arce__collection_payment_period_id__c',
                                                            'arce__days_period_number__c',
                                                            'arce__ltv_per__c'};
    /**
        * @Description: Format fields of the risk conditions section
    */
    private static final List<String> TYPE_RISKCOND = new List<String> {'AMOUNT', 'AMOUNT',
                                                        'AMOUNT', 'TEXT',
                                                        'AMOUNT', 'TEXT',
                                                        'TEXT', 'TEXT',
                                                        'TEXT', 'TEXT',
                                                        'DATE', 'TEXT',
                                                        'TEXT', 'AMOUNT', 'RATE'};
    /**
        * @Description: Map unit field
    */
    private static final Map<String, String> MAP_UNIT = new Map<String, String> {
        '1' => 'UNITS',
        '2' => 'THOUSANDS',
        '3' => 'MILLIONS',
        '4' => 'THOUSANDS_MILLIONS'
    };

    /*------------------------------------------------------------------------------------------------------
    * @Description Builder Arc_Gen_PersistenceLimits_helper
    * -----------------------------------------------------------------------------------------------------
    * @Author   Juan Ignacio Hita Manso
    * @Date     2020-10-01
    * @param    null
    * @return   Arc_Gen_PersistenceLimits_helper
    * @example  new Arc_Gen_PersistenceLimits_helper()
    * */
    @TestVisible
    private Arc_Gen_PersistenceLimits_helper() {}
    /**
    *-------------------------------------------------------------------------------
    * @description This method builds a json input from limit exposure records
    --------------------------------------------------------------------------------
    * @author  juanignacio.hita.contractor@bbva.com
    * @date    2020-10-06
    * @param   List<arce__limits_exposures__c> limitsRecord
    * @param   arce__Account_has_Analysis__c newAha
    * @return  Map<String, Object> - return a map with the data input for limits service
    * @example Map<String, Object> mapStrObj = limitsJSON(limitsRecord);
    **/
    public static Map<String, Object> limitsJSON(List<arce__limits_exposures__c> limitsRecord, arce__Account_has_Analysis__c newAha) {
        final Map<String, Object> mapObj = new Map<String, Object>();
        final List<Map<String, Object>> lstData = new List<Map<String, Object>>();
        for (arce__limits_exposures__c limitExp : limitsRecord) {
            final Map<String, Object> mapDataLimit = createDataLimit(limitExp, newAha);
            lstData.add(mapDataLimit);
        }
        mapObj.put('limits', lstData);
        return mapObj;
    }
    /**
    *-------------------------------------------------------------------------------
    * @description This method creates an input map object from one entry limit exposure
    --------------------------------------------------------------------------------
    * @author  juanignacio.hita.contractor@bbva.com
    * @date    2020-10-06
    * @param   arce__limits_exposures__c limitExp
    * @param   arce__Account_has_Analysis__c newAha
    * @return  Map<String, Object> - return a map with the data input for limits service
    * @example Map<String, Object> mapStrObj = createDataLimit(limitExp);
    **/
    public static Map<String, Object> createDataLimit(arce__limits_exposures__c limitExp, arce__Account_has_Analysis__c newAha) {
        final Map<String, Object> mapObj = new Map<String, Object>();
        final arce__limits_typology__c limitTipology = (arce__limits_typology__c) limitExp.arce__limits_typology_id__r;
        final Map<String, Object> mapTypology = mapTypology(limitTipology);
        Arc_Gen_Persistence_Utils.addifFilled(mapObj, 'typology', mapTypology);
        final List<Object> lstRiskCond = createRiskConditions(limitExp);

        mapObj.put('id', limitExp.get('Id'));
        mapObj.put('level', getLevelTypology(limitTipology));
        mapObj.put('riskAmounts', createRiskAmounts(limitExp, newAha));
        if (!lstRiskCond.isEmpty()) {
            mapObj.put('riskConditions', lstRiskCond);
        }
        return mapObj;
    }
    /**
    *-------------------------------------------------------------------------------
    * @description Method that returns level typology of a limit
    --------------------------------------------------------------------------------
    * @author  juanignacio.hita.contractor@bbva.com
    * @date    2020-10-06
    * @param   arce__limits_typology__c limitTipology
    * @return  String - level typology
    * @example String getLevelTypology = limitsJSON(limitTipology);
    **/
    private static String getLevelTypology(arce__limits_typology__c limitTipology) {
        String levelTypology = '';
        if (arce.Arc_Gen_ValidateInfo_utils.isFilled(limitTipology.arce__risk_typology_level_type__c)) {
            final Map<String, String> mapLevel = new Map<String, String> { '1' => 'LEVEL_1', '2' => 'LEVEL_2', '3' => 'LEVEL_3' };
            levelTypology = (String) mapLevel.get(limitTipology.arce__risk_typology_level_type__c);
        }
        return levelTypology;
    }
    /**
    *-------------------------------------------------------------------------------
    * @description Method that returns a map with the typology data
    --------------------------------------------------------------------------------
    * @author  juanignacio.hita.contractor@bbva.com
    * @date    2020-10-06
    * @param   arce__limits_typology__c limitTipology
    * @return  Map<String, Object> - map with the typology info
    * @example Map<String, Object> mapTyp = mapTypology(limitTipology)
    **/
    private static Map<String, Object> mapTypology(arce__limits_typology__c limitTipology) {
        Map<String, Object> mapObj = new Map<String, Object>();
        if (arce.Arc_Gen_ValidateInfo_utils.isFilled(limitTipology.arce__risk_typo_ext_id__c)) {
            mapObj.put('id', (String) limitTipology.arce__risk_typo_ext_id__c);
        } else if(arce.Arc_Gen_ValidateInfo_utils.isFilled(limitTipology.arce__risk_typology_level_id__c)) {
            mapObj.put('id', (String) limitTipology.arce__risk_typology_level_id__c);
        }
        return mapObj;
    }
    /**
    *-------------------------------------------------------------------------------
    * @description Method that builds risk amount structure from limit exposure
    --------------------------------------------------------------------------------
    * @author  juanignacio.hita.contractor@bbva.com
    * @date    2020-10-06
    * @param   arce__limits_exposures__c limitExp
    * @param   arce__Account_has_Analysis__c newAha
    * @return  List<Object>
    * @example List<Object> riskAmount = createRiskAmounts(limitExp);
    **/
    private static List<Object> createRiskAmounts(arce__limits_exposures__c limitExp, arce__Account_has_Analysis__c newAha) {
        final List<Object> lstObj = new List<Object>();
        String currencyId, unitType;
        if (newAha == null) {
            final arce__Account_has_Analysis__c ahaObj = (arce__Account_has_Analysis__c) limitExp.arce__account_has_analysis_id__r;
            currencyId = (String) ahaObj.get('arce__currency_id__c');
            unitType = (String) ahaObj.get('arce__magnitude_unit_type__c');
        } else {
            currencyId = newAha.arce__currency_id__c;
            unitType = newAha.arce__magnitude_unit_type__c;
        }

        for (Integer i = 0; i < LBL_RISKAMOUNT.size(); i++) {
            final Double value = (Double) limitExp.get(API_RISKAMOUNT[i]);
            if (value != null) {
                final Map<String, Object> mapRiskAm = addRiskAmount(LBL_RISKAMOUNT[i], value, currencyId, MAP_UNIT.get(unitType));
                lstObj.add(mapRiskAm);
            }
        }
        return lstObj;
    }
    /**
    *-------------------------------------------------------------------------------
    * @description Method that builds risk conditions structure from limit exposure
    --------------------------------------------------------------------------------
    * @author  juanignacio.hita.contractor@bbva.com
    * @date    2020-10-06
    * @param   arce__limits_exposures__c limitExp
    * @return  Map<String, Object>
    * @example List<Object> lstObj = createRiskConditions(limitExp);
    **/
    private static List<Object> createRiskConditions(arce__limits_exposures__c limitExp) {
        final List<Object> lstObj = new List<Object>();
        for (Integer i = 0; i < API_RIKSCOND.size(); i++) {
            final String value = String.valueOf(limitExp.get(API_RIKSCOND[i]));
            if (value != null) {
                final Map<String, Object> mapRiskCond = addRiskCondition(String.valueOf(i+1), value, TYPE_RISKCOND[i]);
                lstObj.add(mapRiskCond);
            }
        }
        return lstObj;
    }
    /**
    *-------------------------------------------------------------------------------
    * @description Auxiliary method for builds risk amount map of objects
    --------------------------------------------------------------------------------
    * @author  juanignacio.hita.contractor@bbva.com
    * @date    2020-10-06
    * @param   String amountType
    * @param   Double value
    * @param   String currencyId
    * @param   String unit
    * @return  Map<String, Object>
    * @example Map<String, Object> mapObj = addRiskAmount(amountType, value, currencyId, unit);
    **/
    private static Map<String, Object> addRiskAmount(String amountType, Double value, String currencyId, String unit) {
        final List<Map<String, Object>> lstAmounts = new List<Map<String, Object>>();
        Map<String, Object> mapAmount = new Map<String, Object> {
            'amount' => value,
            'currency' => currencyId
        };
        if (arce.Arc_Gen_ValidateInfo_utils.isFilled(unit)) {
            mapAmount.put('unit', unit);
        }
        lstAmounts.add(mapAmount);
        return new Map<String, Object> {
            'amountType' => amountType,
            'amounts' => lstAmounts
        };
    }
    /**
    *-------------------------------------------------------------------------------
    * @description Auxiliary method for builds risk conditions map of objects
    --------------------------------------------------------------------------------
    * @author  juanignacio.hita.contractor@bbva.com
    * @date    2020-10-06
    * @param   String riskId
    * @param   String value
    * @param   String formatId
    * @return  Map<String, Object>
    * @example Map<String, Object> mapStrObj = addRiskCondition(riskId, value, formatId);
    **/
    private static Map<String, Object> addRiskCondition(String riskId, String value, String formatId) {
        final Map<String, Object> mapFormat = new Map<String, Object> {
            'formatType' => new Map<String, Object> {'id' => formatId },
            'value' => value
        };
        return new Map<String, Object> {
            'id' => riskId,
            'description' => 'desc',
            'format' => mapFormat
        };
    }
}