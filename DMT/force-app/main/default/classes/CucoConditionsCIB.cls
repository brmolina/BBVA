/**
* ____________________________________________________________________________
* Conditions
* Implementation of the interface Conditions_itf
* ____________________________________________________________________________
* @author      Torcuato Tejada <torcuato.tejada.contractor@bbva.com>
* @modifiedBy
* @version     1.0
* @created     2021-04-21
* @modified
* @systemLayer Sample
* ____________________________________________________________________________
* @changes
*
* ____________________________________________________________________________
*/
@SuppressWarnings('PMD.AvoidGlobalModifier, PMD.ExcessiveParameterList')
global with sharing class CucoConditionsCIB implements cuco.Conditions_itf {

    /**
    * @description Validates input values from conditions_change component
    * @param inputConditions: conditions input information to validate
    * @return ConditionsValidationErrors_Wrapper
    */
    global cuco.ConditionsValidationErrors_Wrapper validateInputConditionValues(cuco.ConditionsValidationInput_Wrapper inputConditions) {

        final cuco.ConditionsValidationErrors_Wrapper validationsResult = new cuco.ConditionsValidationErrors_Wrapper();

        final List<cuco.ConditionsValidationErrors_Wrapper.Condition> outputErrors = new List<cuco.ConditionsValidationErrors_Wrapper.Condition>();

        if(inputConditions.conditions != null) {
            // Get and structure the input conditions and catalog information
            final Map<Id,cuco__ps_catalog_condition__c> condDetailsMap = cuco.ValidationsCond_Helper.getCondDetails(inputConditions);
            final Map<String,cuco__ps_catalog_condition_attribute__c> condAttMap = cuco.ValidationsCond_Helper.getCatCondAtt(condDetailsMap.keySet());
            final Map<String,Map<String,String>> valuePerAttMap =  cuco.ValidationsCond_Helper.getAttributesByCondition(inputConditions, condDetailsMap, condAttMap);
            final Map<String,cuco__ps_catalog_attribute__c> attDetailsMap =  cuco.ValidationsCond_Helper.getAttDetails();


            for(cuco__ps_catalog_condition__c cond : condDetailsMap.values()) {

                final List<String> condErrorList =  new List<String> ();

                // Basic validations
                final List<String> booleanErrors =  cleanOutput(cuco.ValidationsCond_Helper.checkBooleanAtts(valuePerAttMap.get(cond.cuco__gf_psc_condition_id__c), attDetailsMap));
                condErrorList.addAll(booleanErrors);

                final List<String> mandatoryErrors = cleanOutput(cuco.ValidationsCond_Helper.checkMandatoryAtts(valuePerAttMap.get(cond.cuco__gf_psc_condition_id__c), cond));
                condErrorList.addAll(mandatoryErrors);

                if(condErrorList.isEmpty()) {

                    final List<String> maxMinErrors =  cleanOutput(cuco.ValidationsCond_Helper.checkMinVSMax(valuePerAttMap.get(cond.cuco__gf_psc_condition_id__c)));
                    condErrorList.addAll(maxMinErrors);

                    final Map<String,Map<String,cuco__ps_catalog_condition_standard__c>> standardValuesMap = cuco.ValidationsCond_Helper.getStandardValues(condAttMap);
                    final List<String> rangeErrors =  cleanOutput(cuco.ValidationsCond_Helper.checkAttRange(valuePerAttMap.get(cond.cuco__gf_psc_condition_id__c), standardValuesMap.get(cond.cuco__gf_psc_condition_id__c), attDetailsMap));
                    condErrorList.addAll(rangeErrors);

                    final List<String> transferErrors =  cleanOutput(cuco.ValidationsCond_Helper.checkTransferAtts(valuePerAttMap.get(cond.cuco__gf_psc_condition_id__c), cond, valuePerAttMap));
                    condErrorList.addAll(transferErrors);

                    final List<String> listErrorNP = cuco.ValidationsCond_Helper.checkNPAtts(valuePerAttMap.get(cond.cuco__gf_psc_condition_id__c), cond);
                    condErrorList.addAll(listErrorNP);

                    final List<String> listErrorCR = cuco.ValidationsCond_Helper.checkCRAttbs(valuePerAttMap.get(cond.cuco__gf_psc_condition_id__c), cond);
                    condErrorList.addAll(listErrorCR);

                    final List<String> cardsErrorList =  cleanOutput(cuco.ValidationsCond_Helper.checkCardsAtts(valuePerAttMap.get(cond.cuco__gf_psc_condition_id__c), cond));
                    condErrorList.addAll(cardsErrorList);

                    if(!condErrorList.isEmpty()) {
                        final cuco.ConditionsValidationErrors_Wrapper.Condition condError = new cuco.ConditionsValidationErrors_Wrapper.Condition();
                        condError.title = cond.Name;
                        condError.messages = condErrorList;
                        outputErrors.add(condError);
                    }

                } else {
                    final cuco.ConditionsValidationErrors_Wrapper.Condition condError = new cuco.ConditionsValidationErrors_Wrapper.Condition();
                    condError.title = cond.Name;
                    condError.messages = condErrorList;
                    outputErrors.add(condError);
                }
            }
        }

        if(!outputErrors.isEmpty()) {
            validationsResult.conditions = outputErrors;
        }
        return validationsResult;
    }

    /**
    * @description clean up unformatted values in errors
    * @param input: List<string> error strings
    * @return List<string> error strings
    */
    private List<String> cleanOutput(List<String> input) {
        Pattern p = Pattern.compile('\\b(\\d+\\.?\\d*)');
        List<String> res = new List<String>();
        for (String str : input) {
            Matcher m = p.matcher(str);
            while (m.find() == true) {
                Decimal value = Decimal.valueOf(m.group(0));
                str = str.replace(m.group(0), value.format());
            }
            res.add(str);
        }
        return res;
    }

}