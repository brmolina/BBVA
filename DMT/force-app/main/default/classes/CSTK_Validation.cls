/**
* ____________________________________________________________________________
* Toolkit Validation
* Implementation of the interface Validation_Itf
* ____________________________________________________________________________
* @author      Markel Landa <markel.landa.contractor@bbva.com>
* @modifiedBy
* @version     1.0
* @created     2023-03-03
* @modified
* @systemLayer Sample
* ____________________________________________________________________________
* @changes
*
* ____________________________________________________________________________
*/
@SuppressWarnings('PMD.AvoidGlobalModifier, sf:TooManyMethods')
global with sharing class CSTK_Validation implements cstk.Validation_Itf {

    //public CSTK_Validation() {}

    /**
    * @description Returns validation
    * @param toolkitId: Id of the Toolkit
    * @param inputFields: form
    * @param field: field to validate
    * @return Map<String, Boolean> map with validation
    */
    global Map<String, Object> validate(Id toolkitId, String inputFields, String rule, String field) {

        Map<String, Object> res = new Map<String, Object>();
        switch on field {
            when 'target_net_zero_date' {
                res = validateNetZeroDate(toolkitId, inputFields, rule, field);
            }
            when 'TopGeographyValueAuto', 'TopGeographyValueAutoparts', 'TopGeographyValueCement', 'TopGeographyValueEnergy', 'TopGeographyValueGeneric', 'TopGeographyValueSteel', 'TopGeographyValueUtilities' {
                res = validateTopGeographiesValue(toolkitId, inputFields, rule, field);
            }
            when 'emissions_comment', 'emissions_comment_edit' {
                res = validateGhgEmissionScope(toolkitId, inputFields, rule, field);
            }
            when 'emissions_int_comment', 'emissions_int_comment_edit', 'emissions_units', 'emissions_units_edit'{
                res = validateGhgEmissInt(toolkitId, inputFields, rule, field);
            }
            when 'emissions_scope12', 'emissions_scope12_edit' {
                res = validateScope12Sum(toolkitId, inputFields, rule, field);
            }
            when 'emissions_scope123', 'emissions_scope123_edit' {
                res = validateScope123Sum(toolkitId, inputFields, rule, field);
            }
            when 'prod_gwh_other_rnwable_pct', 'production_gwh_coal_pct', 'production_gwh_fuel_pct', 'production_gwh_gas_pct', 'production_gwh_hydro_pct', 'production_gwh_nuclear_pct' {
                res = validateProdPct(toolkitId, inputFields, rule, field);
            }
            when 'gf_el_car_battery_components_mfr_r_per', 'gf_brakes_manufacture_revenue_per', 'gf_el_mobility_components_mfr_rev_per', 'gf_car_exterior_components_mfr_r_per', 'gf_int_comb_engn_gearbox_c_mfr_r_per', 'gf_inf_entrt_st_components_mfr_rev_per', 'gf_car_interior_components_mfr_r_per', 'gf_other_components_manufacture_r_per', 'gf_t_el_cons_rw_sources_electricity_per', 'gf_safety_equipment_components_mfr_r_per', 'gf_wheels_suspension_systems_mfr_r_per', 'gf_transmissions_components_mfr_r_per' {
                res = validateLCTPAutoparts(toolkitId, inputFields, field);
            }
            when 'coal_exit_year' {
                res = validateCoalExitYear(toolkitId, inputFields, rule, field);
            }
            when 'bev_and_phev', 'bev_and_phev_pct' {
                res = validateBevPhev(toolkitId, inputFields, rule, field);
            }
            when 'target_paris_alignment' {
                res = validateSbti(toolkitId, inputFields, rule, field);
            }
            when 'plugin_hybrid_vt_2025' {
                res = validateCompareTarget2025UnitsSoldPct(toolkitId, inputFields, rule, field);
            }
            when 'no_engagement_plan_reason' {
                res = validateNoEngPlanReason(toolkitId, inputFields, rule, field);
            }
            when 'category' {
                res = validateCategory(toolkitId, inputFields, rule, field);
            }
            when 'expsoureToShortHaulFlightsPctKm', 'safUseTarget', 'emissionsIntensityScope12PKM', 'fleetAgeAverage', 'safUseTargetYear' {
                res = validateAviation(toolkitId, inputFields, rule, field);
            }
            when 'fossilFuelPowered', 'so2EmissionIntensity', 'lng', 'lowEmissionsTec' {
                res = validateShipping(toolkitId, inputFields, rule, field);
            }
            when 'salesTargetAltPropulsion' {
                res = validateHeavyIndustry(toolkitId, inputFields, rule, field);
            }
            when 'pctRenEnrgyFrmTotal', 'explPrtflSustImproveTarget' {
                res = validateRealEstate(toolkitId, inputFields, rule, field);
            }
            when else {
                res = validateSample(toolkitId, inputFields, rule, field);
            }
        }

        return res;
    }

    /**
    * @description Net Zero Target Date validation method
    * @param toolkitId: Id of the Toolkit
    * @param inputFields: form
    * @param field: field to validate
    * @return Map<String, Boolean> map with validation
    */
    private Map<String, Object> validateNetZeroDate(Id toolkitId, String inputFields, String rule, String field) {

        Map<String, Object> res = new Map<String, Object>();
        Map<String, Object> fields = getInputFields(inputFields);
        Integer valueNetZeroTargetDate;

        Map<string, Object> netZeroTargetDate = (Map<string, Object>)fields.get('cstk__net_zero_target_date__c');
		if (String.isEmpty(String.valueOf(netZeroTargetDate.get('value')))) {

        } else {
            valueNetZeroTargetDate = Integer.valueOf(netZeroTargetDate.get('value'));
        }

        Map<string, Object> targetSBTi = (Map<string, Object>)fields.get('cstk__science_based_target__c');
		String valueTargetSBTi = (String)targetSBTi.get('value');

        Map<string, Object> netZeroTarget = (Map<string, Object>)fields.get('cstk__net_zero_target__c');
		String valueNetZeroTarget = (String)netZeroTarget.get('value');

        Boolean rule1 = (String.isEmpty(valueNetZeroTarget) || valueNetZeroTarget == 'NO' || valueNetZeroTarget == 'UNK') && valueNetZeroTargetDate != null;
		Boolean rule2 = !String.isEmpty(valueNetZeroTarget) && valueNetZeroTarget != 'NO' && valueNetZeroTarget != 'UNK' && valueNetZeroTargetDate == null;
		Boolean rule4 = valueNetZeroTargetDate == null || (valueNetZeroTargetDate != null && Pattern.matches('\\d{4}', String.valueOf(valueNetZeroTargetDate)) && valueNetZeroTargetDate >= 2010 && valueNetZeroTargetDate <= 2100);
		Boolean rule5 = !String.isEmpty(valueTargetSBTi) && valueTargetSBTi != 'NO' && valueNetZeroTargetDate != null && valueNetZeroTargetDate > 2050;

		if (rule2) {
    		res.put('success', false);
    		res.put('errorMessage', 'Value for Net Zero Target Date cannot be null if Net Zero Target is informed.');
		} else if (rule1) {
            res.put('success', false);
            res.put('errorMessage', 'Value for Net Zero Target Date must be null if there is no Net Zero Target.');
        } else if (!rule4) {
     		res.put('success', false);
    		res.put('errorMessage', 'Value seems to be invalid.');
		} else if (rule5){
    		res.put('success', false);
    		res.put('errorMessage', 'Value for Net Zero Target Date cannot be over 2050 if there is a science based target');
        } else {
            res.put('success', true);
        }

        return res;
    }

    /**
    * @description Method to validate that the sum of all top geographies does not exceed 100%
    * @param toolkitId: Id of the sector record
    * @param inputFields: form
    * @param rule: validation rule
    * @param field: field to validate
    * @return Map<String, Object> map with validation
    */
    private Map<String, Object> validateTopGeographiesValue(Id toolkitId, String inputFields, String rule, String field) {

        Map<String, Object> res = new Map<String, Object>();
        Map<String, Object> fields = getInputFields(inputFields);
        Double totalOtherGeoValue = 0;
        Double valuetopGeoPct;
        String sector;

        Map<string, Object> topGeoPct = (Map<string, Object>)fields.get('cstk__main_geo_value__c');
        if (String.isEmpty(String.valueOf(topGeoPct.get('value')))) {

        } else {
            valuetopGeoPct = Double.valueOf(topGeoPct.get('value'));
        }

        String yearValue = (String)fields.get('year');
        Id realToolkitId = cstk.Utils.getToolkitIdFromRecord(toolkitId);
        System.debug(yearValue);
        System.debug(realToolkitId);
        /*CSTK_Client client = new CSTK_Client();
        Map<String, Object> clientInfo = client.getClientInfo(realToolkitId);
        String sector = (String) clientInfo.get('sector');*/
        switch on field {
            when 'TopGeographyValueAuto' {
                sector = 'Auto';
            }
            when 'TopGeographyValueAutoparts' {
                sector = 'Autoparts';
            }
            when 'TopGeographyValueCement' {
                sector = 'Cement';
            }
            when 'TopGeographyValueEnergy' {
                sector = 'Energy';
            }
            when 'TopGeographyValueGeneric' {
                sector = 'Generic';
            }
            when 'TopGeographyValueSteel' {
                sector = 'Steel';
            }
            when 'TopGeographyValueUtilities' {
                sector = 'Utilities';
            }
        }
        system.debug('Sector' + sector);

        List<cstk.Top5Geographies_Wrapper> otherGeoWrapper = cstk.Top5Geographies_Service.getToolGeoInfo(realToolkitId, sector,yearValue);
        List<Double> otherGeoValues = new List<Double>();
        for (cstk.Top5Geographies_Wrapper geo : otherGeoWrapper) {
            otherGeoValues.add(geo.mainGeo1EBITDA);
        }
        System.debug(otherGeoValues);

        for (Double value : otherGeoValues) {
            totalOtherGeoValue += value;
            System.debug(totalOtherGeovalue);
        }

        if (String.isEmpty(String.valueOf(valuetopGeoPct))) {
            res.put('success', false);
            res.put('errorMessage', 'A value is required');
        } else if (validateDecimals(Decimal.valueOf(valuetopGeoPct), 11)) {
            res.put('success', false);
            res.put('errorMessage', 'Number of decimal places must be less or equal 9');
        } else if (valuetopGeoPct <= 0) {
            res.put('success', false);
            res.put('errorMessage', 'Vale must be greater than 0');
        } else if((totalOtherGeoValue + valuetopGeoPct) > 1) {
            res.put('success', false);
            res.put('errorMessage', 'The sum of top 5 geographies cannot surpass 100%');
        } else {
            res.put('success', true);
        }

        return res;
    }

    /**
    * @description Ghg Emissions Comments validation method
    * @param toolkitId: Id of the Toolkit
    * @param inputFields: form
    * @param field: field to validate
    * @return Map<String, Boolean> map with validation
    */
    private Map<String, Object> validateGhgEmissionScope(Id toolkitId, String inputFields, String rule, String field) {

        Map<String, Object> res = new Map<String, Object>();
        Map<String, Object> fields = getInputFields(inputFields);
        Double scope1Value;
        Double scope2Value;
        Double scope3Value;
        Double scope12Value;
        Double scope123Value;

        Map<string, Object> emissionsComments = (Map<string, Object>)fields.get('cstk__comments__c');
        String emissionsCommentsValue = (String)emissionsComments.get('value');


        final Map<string, Object> scope1 = (Map<string, Object>)fields.get('cstk__gf_ghg_ems_from_op_number__c');
        if (String.isEmpty(String.valueOf(scope1.get('value')))) {

        } else {
            scope1Value = Double.valueOf(scope1.get('value'));
        }

        final Map<string, Object> scope2 = (Map<string, Object>)fields.get('cstk__gf_ghg_ems_from_cons_number__c');
        if (String.isEmpty(String.valueOf(scope2.get('value')))) {

        } else {
            scope2Value = Double.valueOf(scope2.get('value'));
        }

        final Map<string, Object> scope3 = (Map<string, Object>)fields.get('cstk__gf_ghg_ems_value_chain_number__c');
        if (String.isEmpty(String.valueOf(scope3.get('value')))) {

        } else {
            scope3Value = Double.valueOf(scope3.get('value'));
        }

        Map<string, Object> scope12 = (Map<string, Object>)fields.get('cstk__ton_co2_y_scope12__c');
        if (String.isEmpty(String.valueOf(scope12.get('value')))) {

        } else {
            scope12Value = Double.valueOf(scope12.get('value'));
        }

        Map<string, Object> scope123 = (Map<string, Object>)fields.get('cstk__ton_co2_y_scope123__c');
        if (String.isEmpty(String.valueOf(scope123.get('value')))) {

        } else {
            scope123Value = Double.valueOf(scope123.get('value'));
        }

        String yearValue = (String)fields.get('year');
        Id realToolkitId = cstk.Utils.getToolkitIdFromRecord(toolkitId);

        cstk.GhgEmissions_Wrapper wrapper = cstk.GhgEmissions_Service.getEmissionRecords(realToolkitId, yearValue);
        cstk.GhgEmissions_Wrapper.GhgEmissionsDetails wrapperYear1 = wrapper.currentYear1;
        System.debug('Scope: ' + wrapperYear1);

        Boolean rule1 = (getVariation(scope1Value, wrapperYear1.scope1) < 0.2) || emissionsCommentsValue != null;
        Boolean rule2 = (getVariation(scope2Value, wrapperYear1.scope2) < 0.2) || emissionsCommentsValue != null;
        Boolean rule3 = (getVariation(scope3Value, wrapperYear1.scope3) < 0.2) || emissionsCommentsValue != null;
        Boolean rule4 = (getVariation(scope12Value, wrapperYear1.scope12) < 0.2) || emissionsCommentsValue != null;
        Boolean rule5 = (getVariation(scope123Value, wrapperYear1.scope123) < 0.2) || emissionsCommentsValue != null;

        // Max 255 chars validation (cstk__comments__c)
        if (field == 'emissions_comment_edit' && !String.isBlank(emissionsCommentsValue)) {
            if (emissionsCommentsValue.length() <= 255) {
            	res.put('success', true);
            }
        	else {
                res.put('success', false);
                res.put('errorMessage', 'You must write less or equals 255 characters');
                return res;
            }
        }

        // Fill required validation
        if(rule1 && rule2 && rule3 && rule4 && rule5) {
            res.put('success', true);
        } else {
            res.put('success', false);
            res.put('errorMessage', 'If the difference between the scope with the previous year is greater than 20%, this field is required');
        }

        return res;
    }

    /**
    * @description Ghg Emissions Comments validation method
    * @param toolkitId: Id of the Toolkit
    * @param inputFields: form
    * @param field: field to validate
    * @return Map<String, Boolean> map with validation
    */
    private Map<String, Object> validateScope12Sum(Id toolkitId, String inputFields, String rule, String field) {

        Map<String, Object> res = new Map<String, Object>();
        Map<String, Object> fields = getInputFields(inputFields);
        Double scope1Value;
        Double scope2Value;
        Double scope12Value;

        final Map<string, Object> scope1 = (Map<string, Object>)fields.get('cstk__gf_ghg_ems_from_op_number__c');
        if (String.isEmpty(String.valueOf(scope1.get('value')))) {

        } else {
            scope1Value = Double.valueOf(scope1.get('value'));
        }

        final Map<string, Object> scope2 = (Map<string, Object>)fields.get('cstk__gf_ghg_ems_from_cons_number__c');
        if (String.isEmpty(String.valueOf(scope2.get('value')))) {

        } else {
            scope2Value = Double.valueOf(scope2.get('value'));
        }

        Map<string, Object> scope12 = (Map<string, Object>)fields.get('cstk__ton_co2_y_scope12__c');
        if (String.isEmpty(String.valueOf(scope12.get('value')))) {

        } else {
            scope12Value = Double.valueOf(scope12.get('value'));
        }

        //Boolean rule2 = scope12 != null && scope3 != null && scope123 != null;

        if(scope1Value != null && scope2Value != null && scope12Value != null) {
            res.put('success', false);
            res.put('errorMessage', 'If scopes 1 & 2 are informed, Scope 1 + 2 is calculated');
        } else if (scope12Value != null && scope12Value < 0) {
            res.put('success', false);
            res.put('errorMessage', 'Value must be greater than 0');
        } else if (scope12Value != null && validateDecimals(Decimal.valueOf(scope12Value), 6)){
            res.put('success', false);
            res.put('errorMessage', 'Number of decimal places must be less or equal 6');
        } else if (scope12Value != null && validateDigits(Decimal.valueOf(scope12Value), 12)){
            res.put('success', false);
            res.put('errorMessage', 'Number of digits must be less or equal 12');
        } else {
            res.put('success', true);
        }
        return res;
    }

    /**
    * @description Ghg Emissions Comments validation method
    * @param toolkitId: Id of the Toolkit
    * @param inputFields: form
    * @param field: field to validate
    * @return Map<String, Boolean> map with validation
    */
    private Map<String, Object> validateScope123Sum(Id toolkitId, String inputFields, String rule, String field) {

        Map<String, Object> res = new Map<String, Object>();
        Map<String, Object> fields = getInputFields(inputFields);
        Double scope3Value;
        Double scope12Value;
        Double scope123Value;

        final Map<string, Object> scope3 = (Map<string, Object>)fields.get('cstk__gf_ghg_ems_value_chain_number__c');
        if (String.isEmpty(String.valueOf(scope3.get('value')))) {

        } else {
            scope3Value = Double.valueOf(scope3.get('value'));
        }

        Map<string, Object> scope12 = (Map<string, Object>)fields.get('cstk__ton_co2_y_scope12__c');
        if (String.isEmpty(String.valueOf(scope12.get('value')))) {

        } else {
            scope12Value = Double.valueOf(scope12.get('value'));
        }

        Map<string, Object> scope123 = (Map<string, Object>)fields.get('cstk__ton_co2_y_scope123__c');
        if (String.isEmpty(String.valueOf(scope123.get('value')))) {

        } else {
            scope123Value = Double.valueOf(scope123.get('value'));
        }

        Boolean rule1 = scope12 != null && scope3 != null && scope123 != null;

        if(scope12Value != null && scope3Value != null && scope123Value != null) {
            res.put('success', false);
            res.put('errorMessage', 'If Scope 1 + 2 & Scope 3 are informed, Scope 1 + 2 + 3 is calculated.');
        } else if (scope123Value != null && scope123Value < 0) {
            res.put('success', false);
            res.put('errorMessage', 'Vale must be greater than 0');
        } else if (scope123Value != null && validateDecimals(Decimal.valueOf(scope123Value), 6)){
            res.put('success', false);
            res.put('errorMessage', 'Number of decimal places must be less or equal 6');
        } else if (scope12Value != null && validateDigits(Decimal.valueOf(scope12Value), 12)){
            res.put('success', false);
            res.put('errorMessage', 'Number of digits must be less or equal 12');
        } else {
            res.put('success', true);
        }
        return res;
    }

    /**
    * @description Ghg Emission Intensity Comment validation method
    * @param toolkitId: Id of the Toolkit
    * @param inputFields: form
    * @param field: field to validate
    * @return Map<String, Boolean> map with validation
    */
    private Map<String, Object> validateGhgEmissInt(Id toolkitId, String inputFields, String rule, String field) {

        Map<String, Object> res = new Map<String, Object>();
        Map<String, Object> fields = getInputFields(inputFields);
        Double emisIntValue;
        String emisIntCommentsValue;
        String emisIntUnitsValue;

        Map<string, Object> emisIntComments = (Map<string, Object>)fields.get('cstk__emissions_intensity_comments__c');
        emisIntCommentsValue = (String)emisIntComments.get('value');

        Map<string, Object> emisInt = (Map<string, Object>)fields.get('cstk__emissions_intensity__c');
        if (String.isEmpty(String.valueOf(emisInt.get('value')))) {

        } else {
            emisIntValue = Double.valueOf(emisInt.get('value'));
        }

        Map<string, Object> emisIntUnit = (Map<string, Object>)fields.get('cstk__emissions_intensity_units__c');
        emisIntUnitsValue = (String)emisIntUnit.get('value');
        System.debug(field + '************** eiuv ' + emisIntUnitsValue);

        String yearValue = (String)fields.get('year');
        Id realToolkitId = cstk.Utils.getToolkitIdFromRecord(toolkitId);

        cstk.GhgEmissions_Wrapper wrapper = cstk.GhgEmissions_Service.getEmissionRecords(realToolkitId, yearValue);
        cstk.GhgEmissions_Wrapper.GhgEmissionsDetails wrapperYear1 = wrapper.currentYear1;
        System.debug('Int: ' + wrapperYear1.emissionsIntensity);

        if(field == 'emissions_units_edit' && String.isBlank(emisIntUnitsValue)){
             System.debug('************** eiv ' + emisIntValue);
            if(emisIntValue == null){
                res.put('success', true);
            }
            else {
                res.put('success', false);
                res.put('errorMessage', 'You must select a value for intensity units if the emission intensity has been filled');
                return res;
            }
        }

        // Max 255 chars validation (cstk__emissions_intensity_comments__c)
        else if(field == 'emissions_int_comment_edit' && !String.isBlank(emisIntCommentsValue)) {
            if (emisIntCommentsValue.length() <= 255) {
            	res.put('success', true);
            }
        	else {
                res.put('success', false);
                res.put('errorMessage', 'You must write less or equals 255 characters');
                return res;
            }
        }

        else if(field == 'emissions_int_comment_edit' && String.isBlank(emisIntCommentsValue)){
            if(getVariation(emisIntValue, wrapperYear1.emissionsIntensity) < 0.2){
                res.put('success', true);
            }
			else {
            	res.put('success', false);
            	res.put('errorMessage', 'If the variation between emission intensity with the previous year is greater than 20%, this field is required');
        	}
        }
        else{
            res.put('success', true);
        }

        return res;
    }

    /**
    * @description Sample validation method
    * @param toolkitId: Id of the Toolkit
    * @param inputFields: form
    * @param field: field to validate
    * @return Map<String, Boolean> map with validation
    */
    private Map<String, Object> validateProdPct(Id toolkitId, String inputFields, String rule, String field) {

        Map<String, Object> res = new Map<String, Object>();
        Map<String, Object> fields = getInputFields(inputFields);
        Double totalValue = 0.0;

        List<String> fieldNames = new List<String>{'cstk__Production_gwh_coal_pct__c', 'cstk__Production_gwh_fuel_pct__c', 'cstk__Production_gwh_gas_pct__c', 'cstk__Production_gwh_nuclear_pct__c', 'cstk__Production_gwh_hydro_pct__c', 'cstk__Prod_gwh_other_rnwable_pct__c'};

        Boolean allNumeric = true;
        Boolean notNumeric = false;
        Boolean correctDecimals = true;

        for (String fieldName : fieldNames) {
            Map<string, Object> fieldMap = (Map<string, Object>)fields.get(fieldName);

            if (!((String)fieldMap.get('value') == '') && !Pattern.matches('(0(\\.\\d+))', (String)fieldMap.get('value')) && !(Decimal.valueOf((String)fieldMap.get('value')) == 1)) {

                if (fieldName == 'cstk__P' + field.Substring(1) + '__c') {
                    notNumeric = true;
                }
                allNumeric = false;
                break;
            } else if (!((String)fieldMap.get('value') == '') && validateDecimals(Decimal.valueOf((String)fieldMap.get('value')), 11)) {
                correctDecimals = false;
                break;
            } else {
                if (String.valueOf(fieldMap.get('value')) != '') {
                    totalValue += Double.valueOf(fieldMap.get('value'));
                }
            }
        }

        if (notNumeric) {
            res.put('success', false);
            res.put('errorMessage', 'Value must be a number between 0 and 100');
        } else if (!correctDecimals) {
            res.put('success', false);
            res.put('errorMessage', 'Number of decimal places must be less or equal 9');
        } else if (allNumeric && totalValue > 1.0) {
            res.put('success', false);
            res.put('errorMessage', 'The sum of Coal, Fuel/Oil, Gas, Nuclear, Hydro and Others cannot be over 100%');
        } else {
            res.put('success', true);
        }

        return res;
    }

    /**
    * @description Coal exit year validation method
    * @param toolkitId: Id of the Toolkit
    * @param inputFields: form
    * @param field: field to validate
    * @return Map<String, Boolean> map with validation
    */
    private Map<String, Object> validateLCTPAutoparts(Id toolkitId, String inputFields, String field) {
        Map<String, Object> res = new Map<String, Object>();
        Map<String, Object> fields = getInputFields(inputFields);

        // Count rows filled        (validation: 5 as max component fields filled)
        // Count percentages values (validation: 100% (1) as max sum of percentages)
        Integer rowsFilled = 0;
        Decimal totalPct   = 0;
        for (String inputField : fields.keySet()) {
            if (inputField.contains('cstk__') && !inputField.contains('gf_t_el_cons_rw_sources_electricity_per')) {
                Map<String, Object> lctpAutopartsField = (Map<String, Object>)fields.get(inputField);
                String lctpAutopartsFieldValue = (String)lctpAutopartsField.get('value');

                if (!String.isEmpty(lctpAutopartsFieldValue)) {
                    rowsFilled++;
                    totalPct += Decimal.ValueOf(lctpAutopartsFieldValue);
                }
            }
        }

        Map<String, Object> thisLctpAutopartsField = (Map<String, Object>)fields.get('cstk__' + field + '__c');
        String thisLctpAutopartsFieldValue = (String)thisLctpAutopartsField.get('value');

        if (!String.isEmpty(thisLctpAutopartsFieldValue)) {
            if (Decimal.ValueOf(thisLctpAutopartsFieldValue) < 0) {
                res.put('success', false);
                res.put('errorMessage', 'Percent value must be positive');
                return res;
            }
            else if (Decimal.ValueOf(thisLctpAutopartsFieldValue) > 1) {
                res.put('success', false);
                res.put('errorMessage', 'Percent value must be under 100%');
                return res;
            }
            else if(validateDecimals(Decimal.valueOf(thisLctpAutopartsFieldValue), 6)){
                res.put('success', false);
                res.put('errorMessage', 'Number of decimal places must be less or equal 4');
                return res;
            }
            else if (rowsFilled > 5) {
                res.put('success', false);
                res.put('errorMessage', 'You must fill only five rows');
                return res;
            }
            else if (totalPct > 1) {
                res.put('success', false);
                res.put('errorMessage', 'Total sum of percentages must be under 100%');
                return res;
            }
        }

        res.put('success', true);

        return res;
    }

    /**
    * @description Coal exit year validation method
    * @param toolkitId: Id of the Toolkit
    * @param inputFields: form
    * @param field: field to validate
    * @return Map<String, Boolean> map with validation
    */
    private Map<String, Object> validateCoalExitYear(Id toolkitId, String inputFields, String rule, String field) {

        Map<String, Object> res = new Map<String, Object>();
        Map<String, Object> fields = getInputFields(inputFields);

        Map<string, Object> coalExitYear = (Map<string, Object>)fields.get('cstk__Coal_exit_year__c');
        String coalExitYearValue = (String)coalExitYear.get('value');

        Id realToolkitId = cstk.Utils.getToolkitIdFromRecord(toolkitId);
        String yearValue = (String)fields.get('year');
        cstk.Sector_Utility_Wrapper utilityWrapper = cstk.Sector_Utility_Service.getSectorUtilInformation(realToolkitId, yearValue);
        Boolean validDate = false;
        if (coalExitYearValue != null){
            validDate = Pattern.matches('\\d{4}', String.valueOf(coalExitYearValue));

        }

        if (!String.isEmpty(coalExitYearValue) && !validDate){
            res.put('success', false);
            res.put('errorMessage', 'The date must have the format YYYY');
        } else {
            res.put('success', true);
        }
        return res;
    }

    /**
    * @description bev and phev pct validation method
    * @param toolkitId: Id of the Toolkit
    * @param inputFields: form
    * @param field: field to validate
    * @return Map<String, Boolean> map with validation
    */
    private Map<String, Object> validateBevPhev(Id toolkitId, String inputFields, String rule, String field) {

        Map<String, Object> res = new Map<String, Object>();
        Map<String, Object> fields = getInputFields(inputFields);
        Integer bevPhevValue;
        Double bevPhevPctValue = 0;
        Double bevAndPhevPctVal = 0;
        Integer totalCarSalesValue;
        Integer year;

        Map<string, Object> bevPhev = (Map<string, Object>)fields.get('cstk__BEV_and_PHEV__c');
        Map<string, Object> bevPhevPct = (Map<string, Object>)fields.get('cstk__BEV_and_PHEV_pct__c');
        if (!String.isEmpty(String.valueOf(bevPhevPct.get('value')))){
            bevPhevPctValue = Double.valueOf(bevPhevPct.get('value'));
        }
        if (String.isEmpty(String.valueOf(bevPhev.get('value')))) {

        } else {
            bevPhevValue = Integer.valueOf(bevPhev.get('value'));
        }

        Map<string, Object> totalCarSales = (Map<string, Object>)fields.get('cstk__Total_car_sales__c');
        if (String.isEmpty(String.valueOf(totalCarSales.get('value')))) {

        } else {
            totalCarSalesValue = Integer.valueOf(totalCarSales.get('value'));
        }

        Id realToolkitId = cstk.Utils.getToolkitIdFromRecord(toolkitId);
        String yearValue = (String)fields.get('year');

        if (!String.isEmpty(yearValue)) {
            year = Integer.valueOf(yearValue) - 1;
        }
        String yearToCompare = String.valueOf(year);

        cstk.Sector_Auto_Wrapper autoWrapper = cstk.Sector_Auto_Service.getSectorAutoInformation(realToolkitId, yearToCompare);
        cstk.Sector_Auto_Wrapper autoWrapperAc = cstk.Sector_Auto_Service.getSectorAutoInformation(realToolkitId, yearValue);
        Double variation = getVariation(bevPhevValue, autoWrapper.bevAndPhev);

        if (autoWrapperAc.bevAndPhevPct != null){
        	bevAndPhevPctVal = autoWrapperAc.bevAndPhevPct;
        }
        Boolean validPctRange = validatePctRange(bevPhevPctValue);
        if(bevPhevPctValue != null && !validPctRange){
           res.put('success', false);
           res.put('errorMessage', 'Value must be between 0 and 100');
        } else if (field == 'bev_and_phev_pct' && validateDecimals(Decimal.valueOf(bevPhevPctValue), 9)) {
            res.put('success', false);
            res.put('errorMessage', 'Number of decimal places must be less or equal 9');
        } else if (field == 'bev_and_phev' && validateDecimals(Decimal.valueOf(bevPhevValue), 0)) {
            res.put('success', false);
            res.put('errorMessage', 'Number of decimal places must be less or equal 0');
        }
        /*
        if (totalCarSalesValue != null && bevPhevValue > totalCarSalesValue) {
            res.put('success', false);
            res.put('errorMessage', 'This field cannot be greater than total car sales');
        } else if (variation < (-0.2)) {
            res.put('success', false);
            res.put('errorMessage', 'The variation with the previous year cannot be greater than -20% and must be between 0 and 100');
        } else if (bevPhevValue != autoWrapperAc.bevAndPhev &&  bevPhevPctValue == bevAndPhevPctVal){
            res.put('success', false);
            res.put('errorMessage', 'If Battery electric (BEV) and Plug-in Hybrid (PHEV) field is modified it is necessary to update the Battery electric (BEV) and Plug-in Hybrid (PHEV) % field');
        } else if (bevPhevValue == autoWrapperAc.bevAndPhev &&  bevPhevPctValue != bevAndPhevPctVal){
            res.put('success', false);
            res.put('errorMessage', 'If Battery electric (BEV) and Plug-in Hybrid (PHEV) % field is modified it is necessary to update the Battery electric (BEV) and Plug-in Hybrid (PHEV) field');
        }*/ else {
            res.put('success', true);
        }
        return res;
    }

    /**
    * @description sbti validation method
    * @param toolkitId: Id of the Toolkit
    * @param inputFields: form
    * @param field: field to validate
    * @return Map<String, Boolean> map with validation
    */
    private Map<String, Object> validateSbti(Id toolkitId, String inputFields, String rule, String field) {

        Map<String, Object> res = new Map<String, Object>();
        Map<String, Object> fields = getInputFields(inputFields);
        Integer year;

        Map<string, Object> parisAlign = (Map<string, Object>)fields.get('cstk__paris_alignment__c');
        String parisAlignValue = (String)parisAlign.get('value');

        Map<string, Object> sbtiTarget = (Map<string, Object>)fields.get('cstk__science_based_target__c');
        String sbtiTargetValue = (String)sbtiTarget.get('value');

        Id realToolkitId = cstk.Utils.getToolkitIdFromRecord(toolkitId);
        String yearValue = (String)fields.get('year');
        if (!String.isEmpty(yearValue)) {
            year = Integer.valueOf(yearValue) - 1;
        }
        String yearToCompare = String.valueOf(year);

        cstk.EmissionTarget_Wrapper targetsWrapper = cstk.EmissionTarget_Service.getTarget(realToolkitId, yearToCompare);

        if (targetsWrapper.parisAlignment != null && targetsWrapper.parisAlignment != 'NO' && parisAlignValue == 'NO') {
            res.put('success', false);
            res.put('errorMessage', 'Value cannot be No if it has been Yes in previous years');
        } else if (sbtiTargetValue != null && sbtiTargetValue != 'NO' && parisAlignValue == 'NO') {
            res.put('success', false);
            res.put('errorMessage', 'If the group has a sbti target, Paris Alignment cannot be no');
        } else {
            res.put('success', true);
        }
        return res;
    }

    /**
    * @description Compare sector auto target 2025 to bev and phev units sold pct validation method
    * @param toolkitId: Id of the Toolkit
    * @param inputFields: form
    * @param field: field to validate
    * @return Map<String, Boolean> map with validation
    */
    private Map<String, Object> validateCompareTarget2025UnitsSoldPct(Id toolkitId, String inputFields, String rule, String field) {

        Map<String, Object> res = new Map<String, Object>();
        Map<String, Object> fields = getInputFields(inputFields);
        Double target2025Value;

        Map<string, Object> target2025 = (Map<string, Object>)fields.get('cstk__gf_bev_phev_5_y_est_trgt_per__c');
        if (String.isEmpty(String.valueOf(target2025.get('value')))) {

        } else {
            target2025Value = Double.valueOf(target2025.get('value'));
        }

        Id realToolkitId = cstk.Utils.getToolkitIdFromRecord(toolkitId);
        String yearValue = (String)fields.get('year');
        cstk.Sector_Auto_Wrapper autoWrapper = cstk.Sector_Auto_Service.getSectorAutoInformation(realToolkitId, yearValue);
        Double bevAndPhevPctMsgVal = autoWrapper.bevAndPhevPct * 100;
        Boolean validPctRange = validatePctRange(target2025Value);

        if (target2025Value != null && !validPctRange) {
            res.put('success', false);
            res.put('errorMessage', 'Value must be between 0 and 100');
        } else if(validateDecimals(Decimal.valueOf(target2025Value), 4)) {
            res.put('success', false);
            res.put('errorMessage', 'Number of decimal places must be less or equal 2');
        } else if (target2025Value != null && (target2025Value < autoWrapper.bevAndPhevPct)) {
            res.put('success', false);
            res.put('errorMessage', 'Value must be greater than ' + bevAndPhevPctMsgVal + '%');
        } else {
            res.put('success', true);
        }

        return res;
    }

    /**
    * @description No engagement plan reason field validation method
    * @param toolkitId: Id of the Toolkit
    * @param inputFields: form
    * @param field: field to validate
    * @return Map<String, Boolean> map with validation
    */
    private Map<String, Object> validateNoEngPlanReason(Id toolkitId, String inputFields, String rule, String field) {

        Map<String, Object> res = new Map<String, Object>();
        Map<String, Object> fields = getInputFields(inputFields);

        Map<string, Object> noEngPlanReason = (Map<string, Object>)fields.get('cstk__no_engagement_plan_reason__c');
        String noEngPlanReasonValue = (String)noEngPlanReason.get('value');

        Map<string, Object> countDueDiligence = (Map<string, Object>)fields.get('cstk__count_due_diligence_on_framework__c');
        String countDueDiligenceValue = (String)countDueDiligence.get('value');

        Map<string, Object> engagementPlan = (Map<string, Object>)fields.get('cstk__engagement_plan__c');
        String engagementPlanValue = (String)engagementPlan.get('value');

        if (countDueDiligenceValue != 'No' || engagementPlanValue != 'No' || noEngPlanReasonValue != null) {
            res.put('success', true);
        } else {
            res.put('success', false);
            res.put('errorMessage', 'This field must have a value if the group does not have an engagement plan and does not have a positive due dilligence on framework');
        }
        return res;
    }

    /**
    * @description Rating Category validation method
    * @param toolkitId: Id of the Toolkit
    * @param inputFields: form
    * @param field: field to validate
    * @return Map<String, Boolean> map with validation
    */
    private Map<String, Object> validateCategory(Id toolkitId, String inputFields, String rule, String field) {

        Map<String, Object> res = new Map<String, Object>();
        Map<String, Object> fields = getInputFields(inputFields);

        String source = (String)fields.get('source');

        Map<string, Object> category = (Map<string, Object>)fields.get('cstk__category__c');
        String categoryValue = (String)category.get('value');

        System.debug('Source -- ' + source);
        System.debug('Category -- ' + categoryValue);

        if (String.isEmpty(categoryValue)) {
            res.put('success', false);
            res.put('errorMessage', 'Value cannot be null');
        } else if (source == 'cdp' && categoryValue != 'global') {
            res.put('success', false);
            res.put('errorMessage', 'If source CDP is chosen, category must be global');
        } else {
            res.put('success', true);
        }

        return res;
    }

    /**
    * @description Shipping fields validation
    * @param toolkitId: Id of the Toolkit
    * @param inputFields: form
    * @param field: field to validate
    * @return Map<String, Boolean> map with validation
    */
    private Map<String, Object> validateAviation(Id toolkitId, String inputFields, String rule, String field) {
        Map<String, Object> res = new Map<String, Object>();
        Map<String, Object> fields = getInputFields(inputFields);

        if (field == 'expsoureToShortHaulFlightsPctKm') {
            Map<string, Object> expsrceShortHaulFlightsPct = (Map<string, Object>)fields.get('cstk__gf_flights_less_15000_km_seat_km_per__c');
            String expsrceShortHaulFlightsPctValue = (String)expsrceShortHaulFlightsPct.get('value');

            if (expsrceShortHaulFlightsPctValue != null) {

                Decimal data = Decimal.ValueOf(expsrceShortHaulFlightsPctValue).stripTrailingZeros();
            	String cleanData = String.ValueOf(data);
            	List<String> steps = cleanData.split('.', 2);

                if (Decimal.ValueOf(expsrceShortHaulFlightsPctValue) < 0) {
                    res.put('success', false);
                    res.put('errorMessage', 'Percentage cannot be negative');
                } else if (Decimal.ValueOf(expsrceShortHaulFlightsPctValue) > 1) {
                    res.put('success', false);
                    res.put('errorMessage', 'Percentage cannot be greater than 100%');
                } else if(steps.size() > 0 && steps[1].length() > 7) {
                	res.put('success', false);
                	res.put('errorMessage', 'Number of decimal places must be less or equal 4');
            	} else {
                    res.put('success', true);
                }
            } else {
                res.put('success', true);
            }
        }

        if (field == 'safUseTarget') {
            Map<string, Object> safUseTarget = (Map<string, Object>)fields.get('cstk__gf_sust_aviation_fuel_objective_amount__c');
            String safUseTargetValue = (String)safUseTarget.get('value');

            if (safUseTargetValue != null) {
                Double safUseTargetValueDouble = Double.valueOf(safUseTargetValue);

                if (safUseTargetValueDouble < 0) {
                    res.put('success', false);
                    res.put('errorMessage', 'Percentage cannot be negative');
                } else if (safUseTargetValueDouble > 100) {
                    res.put('success', false);
                    res.put('errorMessage', 'Percentage cannot be greater than 100%');
                } else {
                    res.put('success', true);
                }
            } else {
                res.put('success', true);
            }
        }

        if (field == 'fleetAgeAverage') {
            Map<string, Object> fleetAgeAverage = (Map<string, Object>)fields.get('cstk__gf_aircraft_fleet_average_age_number__c');
            String fleetAgeAverageValue = (String)fleetAgeAverage.get('value');

            if (fleetAgeAverageValue != null) {
                Double fleetAgeAverageValueInt = Integer.valueOf(fleetAgeAverageValue);

                if (fleetAgeAverageValueInt < 0) {
                    res.put('success', false);
                    res.put('errorMessage', 'This field cannot be negative');
                } else {
                    res.put('success', true);
                }
            } else {
                res.put('success', true);
            }
        }

        if (field == 'emissionsIntensityScope12PKM') {
            Map<string, Object> emissionsIntensityScope12PKM = (Map<string, Object>)fields.get('cstk__gf_scope_1_2_emissions_intensity_number__c');
            String emissionsIntensityScope12PKMValue = (String)emissionsIntensityScope12PKM.get('value');

            if (emissionsIntensityScope12PKMValue != null) {
                Double emissionsIntensityScope12PKMValueDouble = Double.valueOf(emissionsIntensityScope12PKMValue);

                if (emissionsIntensityScope12PKMValueDouble < 0) {
                    res.put('success', false);
                    res.put('errorMessage', 'This field cannot be negative');
                } else {
                    res.put('success', true);
                }
            } else {
                res.put('success', true);
            }
        }

        if (field == 'safUseTargetYear') {
            Map<string, Object> safUseTargetYear = (Map<string, Object>)fields.get('cstk__gf_altv_aviation_fuel_objv_year_number__c');
            String safUseTargetYearValue = (String)safUseTargetYear.get('value');

            if (safUseTargetYearValue != null) {
                Double safUseTargetYearValueInt = Integer.valueOf(safUseTargetYearValue);
				system.debug('System.today().year(): ' + System.today().year());
				system.debug('safUseTargetYearValueInt: ' + safUseTargetYearValueInt);
                if (safUseTargetYearValueInt < System.today().year() || safUseTargetYearValueInt > 9999) {
                    res.put('success', false);
                    res.put('errorMessage', 'Enter a valid year');
                } else if (validateDecimals(Decimal.valueOf(safUseTargetYearValueInt), 0)){
                    res.put('success', false);
                    res.put('errorMessage', 'Number of decimal places must be less or equal 0');
                } else {
                    res.put('success', true);
                }
            } else {
                res.put('success', true);
            }
        }

        return res;
    }

    /**
    * @description Shipping fields validation
    * @param toolkitId: Id of the Toolkit
    * @param inputFields: form
    * @param field: field to validate
    * @return Map<String, Boolean> map with validation
    */
    private Map<String, Object> validateShipping(Id toolkitId, String inputFields, String rule, String field) {
        Map<String, Object> res = new Map<String, Object>();
        Map<String, Object> fields = getInputFields(inputFields);

        if (field == 'fossilFuelPowered') {
            Map<string, Object> fossilFuelPowered = (Map<string, Object>)fields.get('cstk__gf_f_fl_lw_cb_pt_sh_flt_brkdns_number__c');
            String fossilFuelPoweredValue = (String)fossilFuelPowered.get('value');
            if (fossilFuelPoweredValue != null) {
                Double fossilFuelPoweredValueDouble = Double.valueOf(fossilFuelPoweredValue);

                if (fossilFuelPoweredValueDouble < 0) {
                    res.put('success', false);
                    res.put('errorMessage', 'Percentage cannot be negative');
                } else if (fossilFuelPoweredValueDouble > 100) {
                    res.put('success', false);
                    res.put('errorMessage', 'Percentage cannot be greater than 100%');
                } else {
                    res.put('success', true);
                }
            } else {
                res.put('success', true);
            }
        }

        if (field == 'so2EmissionIntensity') {
            Map<string, Object> so2EmissionIntensity = (Map<string, Object>)fields.get('cstk__gf_so2_emission_intensity_number__c');
            String so2EmissionIntensityValue = (String)so2EmissionIntensity.get('value');
            if (so2EmissionIntensityValue != null) {
                Double so2EmissionIntensityValueDouble = Double.valueOf(so2EmissionIntensityValue);

                if (so2EmissionIntensityValueDouble < 0) {
                    res.put('success', false);
                    res.put('errorMessage', 'This field cannot be negative');
                } else {
                    res.put('success', true);
                }
            } else {
                res.put('success', true);
            }
        }

        if (field == 'lng') {
            Map<string, Object> lng = (Map<string, Object>)fields.get('cstk__gf_lng_pt_ship_flt_brkdns_number__c');
            String lngValue = (String)lng.get('value');
            if (lngValue != null) {
                Double lngValueDouble = Double.valueOf(lngValue);

                if (lngValueDouble < 0) {
                    res.put('success', false);
                    res.put('errorMessage', 'This field cannot be negative');
                } else {
                    res.put('success', true);
                }
            } else {
                res.put('success', true);
            }
        }

        if (field == 'lowEmissionsTec') {
            Map<string, Object> lowEmissionsTec = (Map<string, Object>)fields.get('cstk__gf_technology_ship_fleet_brkdn_number__c');
            String lowEmissionsTecValue = (String)lowEmissionsTec.get('value');
            if (lowEmissionsTecValue != null) {
                Double lowEmissionsTecValueDouble = Double.valueOf(lowEmissionsTecValue);

                if (lowEmissionsTecValueDouble < 0) {
                    res.put('success', false);
                    res.put('errorMessage', 'This field cannot be negative');
                } else {
                    res.put('success', true);
                }
            } else {
                res.put('success', true);
            }
        }

        return res;
    }

    /**
    * @description Heavy Industry fields validation
    * @param toolkitId: Id of the Toolkit
    * @param inputFields: form
    * @param field: field to validate
    * @return Map<String, Boolean> map with validation
    */
    private Map<String, Object> validateHeavyIndustry(Id toolkitId, String inputFields, String rule, String field) {
        Map<String, Object> res = new Map<String, Object>();
        Map<String, Object> fields = getInputFields(inputFields);

        Map<string, Object> salesTargetAltProp = (Map<string, Object>)fields.get('cstk__gf_alternative_pt_turcks_sales_per__c');
        String salesTargetAltPropValue = (String)salesTargetAltProp.get('value');

        if (salesTargetAltPropValue != null) {
            if (Decimal.valueOf(salesTargetAltPropValue) < 0) {
                res.put('success', false);
                res.put('errorMessage', 'Percentage cannot be negative');
            } else if (Decimal.valueOf(salesTargetAltPropValue) > 1) {
                res.put('success', false);
                res.put('errorMessage', 'Percentage cannot be greater than 100%');
            } else if(validateDecimals(Decimal.valueOf(salesTargetAltPropValue), 11)) {
                res.put('success', false);
                res.put('errorMessage', 'Number of decimal places must be less or equal 9');
            } else {
                res.put('success', true);
            }
        } else {
            res.put('success', true);
        }

        return res;
    }

    /**
    * @description Real Estate fields validation
    * @param toolkitId: Id of the Toolkit
    * @param inputFields: form
    * @param field: field to validate
    * @return Map<String, Boolean> map with validation
    */
    private Map<String, Object> validateRealEstate(Id toolkitId, String inputFields, String rule, String field) {
        Map<String, Object> res = new Map<String, Object>();
        Map<String, Object> fields = getInputFields(inputFields);

        if (field == 'pctRenEnrgyFrmTotal') {
            Map<string, Object> pctRenEnrgyFrmTotal = (Map<string, Object>)fields.get('cstk__gf_t_el_cons_rw_sources_electricity_per__c');
            String pctRenEnrgyFrmTotalValue = (String)pctRenEnrgyFrmTotal.get('value');

            if (String.isNotBlank(pctRenEnrgyFrmTotalValue)) {
                if (Decimal.valueOf(pctRenEnrgyFrmTotalValue) < 0) {
                    res.put('success', false);
                    res.put('errorMessage', 'Percentage cannot be negative');
                } else if (Decimal.valueOf(pctRenEnrgyFrmTotalValue) > 1) {
                    res.put('success', false);
                    res.put('errorMessage', 'Percentage cannot be greater than 100%');
                } else if(validateDecimals(Decimal.valueOf(pctRenEnrgyFrmTotalValue), 6)) {
                	res.put('success', false);
                	res.put('errorMessage', 'Number of decimal places must be less or equal 4');
                } else {
                    res.put('success', true);
                }
            } else {
                res.put('success', true);
            }
        }

        if (field == 'explPrtflSustImproveTarget') {
            Map<string, Object> explPrtflSustImproveTarget = (Map<string, Object>)fields.get('cstk__gf_best_en_e_ltts_sus_crtfns_pf_ob_desc__c');
            String explPrtflSustImproveTargetValue = (String)explPrtflSustImproveTarget.get('value');
            if (String.isNotBlank(explPrtflSustImproveTargetValue)) {
                if (explPrtflSustImproveTargetValue.length() > 500) {
                    res.put('success', false);
                    res.put('errorMessage', 'Comment length must be under 500 characters');
                } else {
                    res.put('success', true);
                }
            } else {
                res.put('success', true);
            }
        }

        return res;
    }

    /**
    * @description Sample validation method
    * @param toolkitId: Id of the Toolkit
    * @param inputFields: form
    * @param field: field to validate
    * @return Map<String, Boolean> map with validation
    */
    private Map<String, Object> validateSample(Id toolkitId, String inputFields, String rule, String field) {

        Map<String, Object> res = new Map<String, Object>();

        res.put('success', false);
        res.put('errorMessage', 'Value for ' + field + ' sample error message');
        return res;
    }

    /**
    * @description Validate a percentage between 0 and 100 method
    * @param percent: Decimal number
    * @return Boolean value
    */
    private Boolean validatePctRange(Double percent) {

        Boolean validatedPct = false;

        if (percent >= 0 && percent <= 1) {
            validatedPct = true;
        }

        return validatedPct;
    }

    /**
    * @description Retrieve input fields method
    * @param inputFields: Id of the Toolkit
    * @return Map<String, Object> map with input fields, data type and data value
    */
    private static Map<String, Object> getInputFields(String inputFields) {

    final Map<String, Object> res = new Map<string, Object>();
    final Map<String, Object> inputMap = (Map<String, Object>)JSON.deserializeUntyped(inputFields);

    res.put('source', (String)inputMap.get('source'));
    res.put('year', (String)inputMap.get('year'));
    res.put('date', (String)inputMap.get('date'));

    final Map<String, Object> data = (Map<String, Object>)inputMap.get('data');

    for(String key : data.keySet()) {
        final List<Object> obj = (List<Object>)data.get(key);
        for(Object section : obj) {
            final Map<String, Object> inputs = (Map<String, Object>)section;
            final List<Object> objFields = (List<Object>)inputs.get('fields');
            for(Object field : objFields) {
                final Map<String, Object> input = (Map<String, Object>)field;
                res.put((String)input.get('name'), input);
            }
        }
    }
    return res;
    }

    /**
    * @description Return the variation between two numéric values
    * @param var1: Numeric value 1
    * @param var2: Numeric value 2
    * @return Double variation number value
    */
    private static Double getVariation(Double Var1, Double Var2) {
        Double res = 0;

        if(var1 != null && var2 != null && var2 != 0) {
            res = (var1 - var2) / var2;
        }

        return res;
    }

    /**
    * @description validate decimals of value
    * @param value: Numeric value
    * @param maxDecimals: Max number of decimals allowed
    * @return true if value has more decimals than allowed
    */
    private static Boolean validateDecimals(Decimal value, Integer maxDecimals) {
        Boolean res = false;

        if(value != null && maxDecimals != null) {
            final Integer numDecimals = value.stripTrailingZeros().scale();
            if (numDecimals > maxDecimals){
                res = true;
            }
        }

        return res;
    }

    /**
    * @description validate digits of value
    * @param value: Numeric value
    * @param maxDigits: Maximum number of digits allowed
    * @return true if value has more digits than allowed
    */
    private static Boolean validateDigits(Decimal value, Integer maxDigits) {
        Boolean res = false;

        if(value != null && maxDigits != null) {
            final Integer numDigits = value.precision();
            if (numDigits > maxDigits){
                res = true;
            }
        }

        return res;
    }
}