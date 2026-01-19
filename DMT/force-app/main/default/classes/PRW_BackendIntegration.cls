/**
* ____________________________________________________________________________
* Back End Integration Helper
* Name class: BackendIntegration_Helper
* ____________________________________________________________________________
* @author      Torcuato Tejada <torcuato.tejada.contractor@bbva.com>
* @modifiedBy
* @version     1.0
* @created     2021-03-08
* @modified
* @systemLayer Service
* ____________________________________________________________________________
* @changes
*
* ____________________________________________________________________________
*/
@SuppressWarnings('PMD.TooManyMethods,sf:CyclomaticComplexity,sf:NcssMethodCount,sf:AvoidDeeplyNestedIfStmts,sf:NPathComplexity')
public with sharing class PRW_BackendIntegration {
  /**
  * @description query limit
  */
  final static Integer QUERYLIMIT = 2000;

  /**
  * @description field
  */
  final static String PROFANALYSIS = 'cuco__profitability_analysis_flat_rates_dp__c';

  /**
  * @description field
  */
  final static String CUCOVAR = 'cuco__';

  /**
  * @description field
  */
  final static String FORMATVAR = 'format';

  /**
  * @description field
  */
  final static String FORMATSVAR = 'formats';

  /**
  * @description field
  */
  final static String EXTENDEDVAR = 'extended.package';

  /**
  * @description field
  */
  final static String ORIGINVAR = 'origin';

  /**
  * @description field
  */
  static Integer fatrateaccount; //NOSONAR

  /**
  * SINGLETON PATTERN
  */
  private static PRW_BackendIntegration instance;

  /**
  * Constructor
  */
  private PRW_BackendIntegration() {
  }

  /**
  * getInstance
  */
  public static PRW_BackendIntegration gtInstance() {
    if(instance == null) {
      instance = new PRW_BackendIntegration();
    }
    return instance;
  }

  /**
  * @description returns wrapper with Profitability Sheet info. this is a second service call called from getProfSheetFullDetails
  * @param profSheetId : profitability sheet Id
  * @param psDate : Date from first service call
  * @param responseMap : Map<String, Object> response data from first service call
  * @param psStatus : String Status response from first service call
  * @return Map<String,Object>, wrapper with Profitability Sheet info
  */
  public static Map<String,Object> callListProposalNotebookConditions(cuco__profitability_sheet__c profSheet, Date psDate, Map<String, Object> responseMap, String psStatus) {

    Map<String,Object> returnMap = new Map<String,Object>();
    final PRW_TabContainerCtrl.GetListProposalWrapper listWrap = new PRW_TabContainerCtrl.GetListProposalWrapper(profSheet.cuco__gf_profitability_sheet_id__c, psDate);
    final HttpResponse response = PRW_TabContainerCtrl.callWs('listProposalNotebookConditions',JSON.serialize(listWrap));
    switch on response.getStatusCode() {
      when 204 {
        returnMap.put('success', false);
        returnMap.put('errorMessage', Label.cuco.no_ps_conditions_details);
      }
      when 200 {

        cuco.ProfitabilitySheet_Wrapper wrapper = initializeWrap(responseMap, profSheet, psStatus);

        final Map<String, Object> response2Map = (Map<String, Object>) JSON.deserializeUntyped(response.getBody());

        if(response2Map.containsKey('data')) {

          final Map<String, cuco__ps_catalog_condition_attribute__c> mapConditionAttr = gtConditionAttributes();
          final Map<String, cuco__ps_catalog_flat_rates_attribute__c> mapfrAttributes = gtPSflatRateAttr();
          final Map<String, cuco__ps_catalog_flat_rates_account__c> mappscfrAccount = gtPSCatFltRtAc();
          final Map<String, cuco__ps_catalog_flat_rates_dp_attribute__c> mapFltRatDPatr = gtPScatFltRtDP();
          final Map<String, cuco__ps_catalog_flat_rates_dp__c> mappsFlatRatDP = gtPScatFltRsDP();

          Map<String, cuco.ProfitabilitySheet_Wrapper.Condition> conditions = new Map<String, cuco.ProfitabilitySheet_Wrapper.Condition>();
          final cuco.FlatRates_Wrapper  flatRateWrapper = new cuco.FlatRates_Wrapper();
          List<cuco.FlatRates_Wrapper.FlatRatesAccount> flatRatesAccount = new List<cuco.FlatRates_Wrapper.FlatRatesAccount>();
          List<cuco.FlatRates_Wrapper.FlatRatesDP> flatRatesDPList = new List<cuco.FlatRates_Wrapper.FlatRatesDP>();

          Integer fatrate = 0;
          fatrateaccount = 0;
          Integer fatratedp = 0;
          String extendedPackage = null;

          for(Object objRecord : (List<Object>)response2Map.get('data')) {

            final Map<String, Object> recordMap = (Map<String, Object>)objRecord;
            if((String)recordMap.get('id') == EXTENDEDVAR) {
              extendedPackage = getAttributeValue((List<Object>)recordMap.get(FORMATSVAR), 'TEXT');
              continue;
            }

            conditions = simpleOrigValid(recordMap, mapConditionAttr, conditions);

            fatrate = stFatRate(recordMap, mapfrAttributes, fatrate,  flatRateWrapper);
            flatRatesAccount = stFlatAcc(recordMap, mappscfrAccount, flatRatesAccount);

            if (getoriginId(recordMap) == 'DYNAMIC_PRICING' && mapFltRatDPatr.containsKey((String)recordMap.get('id')) ) {
              fatratedp = fatratedp + 1;
              //PS Catalog Flat Rates DP
              final cuco__ps_catalog_flat_rates_dp_attribute__c mpatRatesDP = mapFltRatDPatr.get((String)recordMap.get('id'));
              Boolean exFrdp = false;
              Integer position;
              for (Integer i = 0; i<flatRatesDPList.size(); i++) {
                if (flatRatesDPList.get(i).id == mpatRatesDP.cuco__gf_psc_fr_dynamic_pricing_id__c ) {
                  position = i;
                  exFrdp = true;
                  break;
                }
              }
              if(exFrdp) {
                flatRatesDPList = stDPList1(recordMap, mapFltRatDPatr, flatRatesDPList, position);
              } else {
                flatRatesDPList = stDPList2(recordMap, mappsFlatRatDP, mapFltRatDPatr, mpatRatesDP,flatRatesDPList);
              }
            }

          }

          wrapper = stFlatCond(wrapper, flatRatesAccount, flatRatesDPList,  flatRateWrapper, fatrate, fatratedp, conditions, extendedPackage);
        }

        returnMap.put('success', true);
        returnMap.put('profSheetDetails', wrapper);
      }
      when else {
        returnMap = stElseResponse(returnMap, response);
      }
    }
    return returnMap;
  }

  /**
  * @description return Profitability Sheet Participants
  * @param participants : returned participants node from first service call
  * @return List<ProfitabilitySheet_Wrapper.Participant> list of PS participants wrapper.
  */
  private static List<cuco.ProfitabilitySheet_Wrapper.Participant> getParticipants(List<Object> participants) {

    final List<cuco.ProfitabilitySheet_Wrapper.Participant> participantsList = new List<cuco.ProfitabilitySheet_Wrapper.Participant>();
    Map<String,Id> validParticipants = new Map<String,Id>();

    final cuco__pa_general_configuration__mdt config = cuco.Utils.getGeneralConfiguration();
    Type participantClass;

    if(Test.isRunningTest()) {
      participantClass = Type.forName('cuco.' + config.cuco__participants_itf_name__c);
    } else {
      participantClass = Type.forName(config.cuco__participants_itf_name__c);
    }

    final cuco.Participant_itf participantItf = (cuco.Participant_itf) participantClass.newInstance();
    final Set<String> participantIds = new Set<String>();

    for (Object objParticipant : participants) {
      final Map<String, Object> participant = (Map<String, Object>)objParticipant;
      if(!String.isEmpty((String)participant.get('interventionStartDate')) &&  Date.valueOf((String)participant.get('interventionStartDate')) <= date.today() && (String.isEmpty((String)participant.get('interventionEndDate')) || Date.valueOf((String)participant.get('interventionEndDate')) >= date.today())) {
        participantIds.add(participant.get('id') + 'C');
      }
    }

    validParticipants = participantItf.getParticipantsIds(participantIds);

    for(Id participantId : validParticipants.values()) {
      final cuco.ProfitabilitySheet_Wrapper.Participant wrapperPart = new cuco.ProfitabilitySheet_Wrapper.Participant();
      wrapperPart.id = participantId;
      participantsList.add(wrapperPart);
    }
    return participantsList;
  }

  /**
  * @description return all condition attributes in the catalag with a maximum limit of QUERYLIMIT
  * @return Map<String, ps_catalog_condition_attribute__c> map with all condition attributes.
  */
  private static Map<String, cuco__ps_catalog_condition_attribute__c> gtConditionAttributes() {
    final cuco.PsCatalogConditionAttribute_Selector pscCondAttrSel = new cuco.PsCatalogConditionAttribute_Selector(new List<String>{'cuco__BackendIntegration'});
    final List<cuco__ps_catalog_condition_attribute__c> pscCondAttri = pscCondAttrSel.getCatalogConditionsAttribute(2000);
    final Map<String, cuco__ps_catalog_condition_attribute__c> mapConditionAttr = new Map<String, cuco__ps_catalog_condition_attribute__c>();

    for (cuco__ps_catalog_condition_attribute__c pscCondAttr : pscCondAttri) {
      mapConditionAttr.put(pscCondAttr.cuco__gf_psc_condition_attribute_id__c, pscCondAttr);
    }
    return mapConditionAttr;
  }

  /**
  * @description return all falte rate attributes in the catalag
  * @return Map<String, ps_catalog_flat_rates_attribute__c> map with all falte rate attributes.
  */
  public static Map<String, cuco__ps_catalog_flat_rates_attribute__c> gtPSflatRateAttr() {

    final cuco.PsCatalogFlatRatesAttribute_Selector psCFlatRtAttSelec = new cuco.PsCatalogFlatRatesAttribute_Selector(true);
    final List<cuco__ps_catalog_flat_rates_attribute__c> lPsCtlatRtAtt = psCFlatRtAttSelec.selectAll(100);
    final Map<String, cuco__ps_catalog_flat_rates_attribute__c> mapPsCtFltRtAtt = new Map<String, cuco__ps_catalog_flat_rates_attribute__c>();

    for (cuco__ps_catalog_flat_rates_attribute__c pscFRattribute : lPsCtlatRtAtt) {
      mapPsCtFltRtAtt.put(pscFRattribute.cuco__gf_psc_flat_attribute_id__c, pscFRattribute);
    }
    return mapPsCtFltRtAtt;
  }

  /**
  * @description return all falte rate account
  * @return Map<String, ps_catalog_flat_rates_attribute__c> map with all falte rate attributes.
  */
  public static Map<String, cuco__ps_catalog_flat_rates_account__c> gtPSCatFltRtAc() {

    final cuco.PSCatalogFlatRatesAccount_Selector seleclatRateAcct = new cuco.PSCatalogFlatRatesAccount_Selector(true);
    final List<cuco__ps_catalog_flat_rates_account__c> psFlRtAccList = seleclatRateAcct.selectAll(100);
    final Map<String, cuco__ps_catalog_flat_rates_account__c> mappsFlRtAcc = new Map<String, cuco__ps_catalog_flat_rates_account__c>();

    for (cuco__ps_catalog_flat_rates_account__c pspsFlRtAccList : psFlRtAccList) {
      mappsFlRtAcc.put(pspsFlRtAccList.cuco__gf_psc_flat_rate_ac_svc_id__c, pspsFlRtAccList);
    }
    return mappsFlRtAcc;
  }

  /**
  * @description return all falte rate DP
  * @return Map<String, ps_catalog_flat_rates_attribute__c> map with all falte rate attributes.
  */
  public static Map<String, cuco__ps_catalog_flat_rates_dp__c> gtPScatFltRsDP() {

    final cuco.PSCatalogFlatRatesDpSelector psctFalRtDpSelec = new cuco.PSCatalogFlatRatesDpSelector(true);
    final List<cuco__ps_catalog_flat_rates_dp__c> lstPscatFlatDp = psctFalRtDpSelec.selectAll();
    final Map<String, cuco__ps_catalog_flat_rates_dp__c> mapPscatFlatDp = new Map<String, cuco__ps_catalog_flat_rates_dp__c>();

    for (cuco__ps_catalog_flat_rates_dp__c psCatFlatDp : lstPscatFlatDp) {
      mapPscatFlatDp.put(psCatFlatDp.cuco__gf_dynamic_pricing_item_id__c, psCatFlatDp);
    }
    return mapPscatFlatDp;
  }

  /**
  * @description return all falte rate DP
  * @return Map<String, ps_catalog_flat_rates_attribute__c> map with all falte rate attributes.
  */
  public static Map<String, cuco__ps_catalog_flat_rates_dp_attribute__c> gtPScatFltRtDP() {

    final cuco.PSCatalogAttributesFlatRatesDpSelector pscFRDpAttrSelec = new cuco.PSCatalogAttributesFlatRatesDpSelector(true);
    final List<cuco__ps_catalog_flat_rates_dp_attribute__c> ltPsctFlatDpAtrr = pscFRDpAttrSelec.selectAllfields();
    final Map<String, cuco__ps_catalog_flat_rates_dp_attribute__c> mapPscFlatDpattr = new Map<String, cuco__ps_catalog_flat_rates_dp_attribute__c>();

    for (cuco__ps_catalog_flat_rates_dp_attribute__c psCatFlatDpAttr : ltPsctFlatDpAtrr) {
      mapPscFlatDpattr.put(psCatFlatDpAttr.cuco__gf_psc_dynamic_pricing_atrb_id__c, psCatFlatDpAttr);
    }
    return mapPscFlatDpattr;
  }

  /**
  * @description extract and return attribute value, dependeing on the value type
  * @param formats : Map<String, Object> as returned from second service
  * @param type : tupe of attribute.
  * @return String
  */
  private static String getAttributeValue(List<Object> formats, String type) {

    final Map<String, Object> formatMap = (Map<String, Object>)formats.get(0);
    final Map<String, Object> format1 = (Map<String, Object>)formatMap.get(FORMATVAR);
    system.debug(format1);
    String result = '';

    switch on type {
      when 'RATE' {
        final Map<String, Object> mapRate = (Map<String, Object>) formatMap.get(FORMATVAR);
        result = String.valueof((Decimal) mapRate.get('value'));
      }
      when 'AMOUNT' {
        final Map<String, Object> mapAmount = (Map<String, Object>) format1.get('amount');
        result = String.valueof((Decimal) mapAmount.get('amount'));
      }
      when 'TEXT' {
        final Map<String, Object> mapText = (Map<String, Object>) formatMap.get(FORMATVAR);
        result = (String) mapText.get('text');
      }
      when 'TERM' {
        final Map<String, Object> mapTerm = (Map<String, Object>) formatMap.get(FORMATVAR);
        result = String.valueof((Integer) mapTerm.get('termValue'));
      }
      when 'DATE' {
        final Map<String, Object> mapDate = (Map<String, Object>) formatMap.get('date');
        result = (String) mapDate.get('date');
      }
      when else {
        result = '';
      }
    }
    return result;
  }

  /**
  * @description return whether origin is valid
  * @param origin : string
  * @return Boolean
  */
  private static Boolean isOriginValid(String origin) {
    return origin == 'COMMISSIONS_FLAT' || origin == 'GIP_PACKAGE' || origin == 'FORFAIT' || origin == 'COMMERCIAL_PACKAGE';
  }

  /**
  * @description return whether origin is valid
  * @param origin : Map<String, Object> as returned from second service
  * @return Boolean
  */
  private static Boolean isOriginValid(Map<String, Object> record) {
    Boolean validOrigin = false;
    if(record.containsKey(ORIGINVAR)) {
      final Map<String, Object> origin = (Map<String, Object>)record.get(ORIGINVAR);
      validOrigin = String.isEmpty((String)origin.get('id')) || isOriginValid((String)origin.get('id'));
    } else {
      validOrigin = true;
    }
    return validOrigin;
  }

  /**
  * @description return whether source is extended package
  * @param origin : Map<String, Object> as returned from second service
  * @return Boolean
  */
  private static String getoriginId (Map<String, Object> record) {
    String originId;
    if(record.containsKey(ORIGINVAR)) {
      final Map<String, Object> origin = (Map<String, Object>)record.get(ORIGINVAR);
      originId = (String)origin.get('id');
    }
    return originId;
  }

  /**
  * @description return whether source is extended package
  * @param source : String with condition source
  * @return Boolean
  */
  private static Boolean getExtendedPackageType(String source) {
    Boolean ispackageSource = false;
    if(source == 'GIP_PACKAGE' || source == 'FORFAIT' || source == 'COMMERCIAL_PACKAGE') {
      ispackageSource = true;
    }
    return ispackageSource;
  }

  /**
  * @description returns wrapper
  * @param recordMap : current record
  * @param flatRateWrapper : flate rate Wapper
  * @param mapfrAttributes : map of flate rate attributes
  * @return FlatRates_Wrapper, wrapper
  */
  public static cuco.FlatRates_Wrapper setFlatInfoWrapper(Map<String, Object> recordMap, cuco.FlatRates_Wrapper flatRateWrapper, Map<String, cuco__ps_catalog_flat_rates_attribute__c> mapfrAttributes) {
    final cuco__ps_catalog_flat_rates_attribute__c frAttribute = mapfrAttributes.get((String)recordMap.get('id'));
    system.debug(frAttribute);

    switch on (String)recordMap.get('id') {
        when 'comflat.amount.type' {
          flatRateWrapper.priceType = getAttributeValue((List<Object>)recordMap.get(FORMATSVAR), frAttribute.cuco__gf_psc_attribute_id__r.cuco__gf_psc_bknd_svc_format_type__c);
        }
        when 'comflat.fixed.amount' {
          flatRateWrapper.fixedAmount = Decimal.valueof(getAttributeValue((List<Object>)recordMap.get(FORMATSVAR), frAttribute.cuco__gf_psc_attribute_id__r.cuco__gf_psc_bknd_svc_format_type__c));
        }
        when 'comflat.variable.amount' {
          flatRateWrapper.variableAmountDesc = getAttributeValue((List<Object>)recordMap.get(FORMATSVAR), frAttribute.cuco__gf_psc_attribute_id__r.cuco__gf_psc_bknd_svc_format_type__c);
        }
        when 'comflat.payment.type' {
          flatRateWrapper.chargeType = getAttributeValue((List<Object>)recordMap.get(FORMATSVAR), frAttribute.cuco__gf_psc_attribute_id__r.cuco__gf_psc_bknd_svc_format_type__c);
        }
        when 'comflat.charge.periodicity' {
          flatRateWrapper.periodicityChageType = getAttributeValue((List<Object>)recordMap.get(FORMATSVAR), frAttribute.cuco__gf_psc_attribute_id__r.cuco__gf_psc_bknd_svc_format_type__c);
        }
        when 'comflat.currency' {
          flatRateWrapper.currencyType = getAttributeValue((List<Object>)recordMap.get(FORMATSVAR), frAttribute.cuco__gf_psc_attribute_id__r.cuco__gf_psc_bknd_svc_format_type__c);
        }
        when 'comflat.payment.date' {
          flatRateWrapper.chargeDay = getAttributeValue((List<Object>)recordMap.get(FORMATSVAR), frAttribute.cuco__gf_psc_attribute_id__r.cuco__gf_psc_bknd_svc_format_type__c);
        }
        when 'comflat.nonbusiness.payday.procedure' {
          flatRateWrapper.nonWorkingDayChargeMethod = getAttributeValue((List<Object>)recordMap.get(FORMATSVAR), frAttribute.cuco__gf_psc_attribute_id__r.cuco__gf_psc_bknd_svc_format_type__c);
        }
        when 'comflat.account.unavailable.procedure' {
          flatRateWrapper.accWithoutBalanceMethod = getAttributeValue((List<Object>)recordMap.get(FORMATSVAR), frAttribute.cuco__gf_psc_attribute_id__r.cuco__gf_psc_bknd_svc_format_type__c);
        }
    }
    return flatRateWrapper;
  }

  /**
  * @description returns list condition
  * @param recordMap : current record
  * @param mapConditionAttr : flate rate Wapper
  * @param conditionsAux : map of flate rate attributes
  * @return Map<String, cuco.ProfitabilitySheet_Wrapper.Condition>
  */
  private static Map<String, cuco.ProfitabilitySheet_Wrapper.Condition> simpleOrigValid(Map<String, Object> recordMap, Map<String, cuco__ps_catalog_condition_attribute__c> mapConditionAttr, Map<String, cuco.ProfitabilitySheet_Wrapper.Condition> conditionsAux) {
    final Map<String, cuco.ProfitabilitySheet_Wrapper.Condition> conditions = conditionsAux;
    if (recordMap.get('conditionType') == 'SIMPLE' && isOriginValid(recordMap) && mapConditionAttr.containsKey((String)recordMap.get('id'))) {
      cuco.ProfitabilitySheet_Wrapper.Condition condition = new cuco.ProfitabilitySheet_Wrapper.Condition();
      final cuco__ps_catalog_condition_attribute__c condAttribute = mapConditionAttr.get((String)recordMap.get('id'));

      if (conditions.containsKey(condAttribute.cuco__gf_psc_condition_id__c)) {
        condition = (cuco.ProfitabilitySheet_Wrapper.Condition)conditions.get(condAttribute.cuco__gf_psc_condition_id__c);
      } else {
        condition.id = condAttribute.cuco__gf_psc_condition_id__c;
        condition.familyId = condAttribute.cuco__gf_psc_condition_id__r.cuco__gf_psc_family_id__c;
        condition.attributesList = new List<cuco.ProfitabilitySheet_Wrapper.Attribute>();
      }

      final List<cuco.ProfitabilitySheet_Wrapper.Attribute> attributesList = (List<cuco.ProfitabilitySheet_Wrapper.Attribute>)condition.attributesList;
      final cuco.ProfitabilitySheet_Wrapper.Attribute attribute = new cuco.ProfitabilitySheet_Wrapper.Attribute();

      attribute.id = condAttribute.cuco__gf_psc_atribute_id__c;
      attribute.condAttrId = condAttribute.Id;
      attribute.canonicalId = condAttribute.cuco__gf_psc_condition_attribute_id__c;
      attribute.value = getAttributeValue((List<Object>)recordMap.get(FORMATSVAR), condAttribute.cuco__gf_psc_atribute_id__r.cuco__gf_psc_bknd_svc_format_type__c);

      final Map<String, Object> origin = (Map<String, Object>)recordMap.get(ORIGINVAR);
      final string originId = (String)origin.get('id');
      condition.source =  originId;
      attributesList.add(attribute);

      if(!conditions.containsKey(condAttribute.cuco__gf_psc_condition_id__c)) {
        conditions.put(condAttribute.cuco__gf_psc_condition_id__c, condition);
      }
    }
    return conditions;
  }

  /**
  * @description returns list condition
  * @param recordMap : current record
  * @param mapConditionAttr : flate rate Wapper
  * @param conditionsAux : map of flate rate attributes
  * @return Map<String, cuco.ProfitabilitySheet_Wrapper.Condition>
  */
  private static List<cuco.FlatRates_Wrapper.FlatRatesDP> stDPList1(Map<String, Object> recordMap, Map<String, cuco__ps_catalog_flat_rates_dp_attribute__c> mapFltRatDPatr, List<cuco.FlatRates_Wrapper.FlatRatesDP> flatRatesDPListAx, Integer position) {
    final List<cuco.FlatRates_Wrapper.FlatRatesDP> flatRatesDPList = flatRatesDPListAx;
    final cuco.FlatRates_Wrapper.DPAttribute  dPAttribute = new cuco.FlatRates_Wrapper.DPAttribute();
    final cuco__ps_catalog_flat_rates_dp_attribute__c psfatRadpAttr = mapFltRatDPatr.get((String)recordMap.get('id'));
    dPAttribute.id = psfatRadpAttr.cuco__gf_psc_atribute_id__c;
    dPAttribute.canonicalId = psfatRadpAttr.cuco__gf_psc_dynamic_pricing_atrb_id__c;
    dPAttribute.value = getAttributeValue((List<Object>)recordMap.get(FORMATSVAR), psfatRadpAttr.cuco__gf_psc_atribute_id__r.cuco__gf_psc_bknd_svc_format_type__c);
    final List<String> decimalLstFlatDP = new List<String>{'Number', 'Currency', 'Percent'};
    system.debug(decimalLstFlatDP);
    if(psfatRadpAttr.cuco__gf_psc_atribute_id__r.cuco__gf_stored_fnl_atrb_field_name__c != null) {
      if(decimalLstFlatDP.contains(psfatRadpAttr.cuco__gf_psc_atribute_id__r.cuco__gf_attribute_value_type_name__c)) {
        final Integer lengthValueDP = Schema.getGlobalDescribe().get(PROFANALYSIS).getDescribe().fields.getMap().get(CUCOVAR + psfatRadpAttr.cuco__gf_psc_atribute_id__r.cuco__gf_stored_prps_atrb_field_name__c).getDescribe().getPrecision();
        final Integer decimalValueDP = Schema.getGlobalDescribe().get(PROFANALYSIS).getDescribe().fields.getMap().get(CUCOVAR + psfatRadpAttr.cuco__gf_psc_atribute_id__r.cuco__gf_stored_prps_atrb_field_name__c).getDescribe().getScale();
        dPAttribute.lengthValue = String.valueOf(lengthValueDP);
        dPAttribute.decimalValue = String.valueOf(decimalValueDP);
        dPAttribute.isDecimal = true;
      } else {
        dPAttribute.isDecimal = false;
      }
    }
    flatRatesDPList.get(position).dpAttributeList.add(dPAttribute);
    return flatRatesDPList;
  }

  /**
  * @description returns list condition
  * @param recordMap : current record
  * @param mapConditionAttr : flate rate Wapper
  * @param conditionsAux : map of flate rate attributes
  * @return Map<String, cuco.ProfitabilitySheet_Wrapper.Condition>
  */
  private static List<cuco.FlatRates_Wrapper.FlatRatesDP> stDPList2(Map<String, Object> recordMap, Map<String, cuco__ps_catalog_flat_rates_dp__c> mappsFlatRatDP, Map<String, cuco__ps_catalog_flat_rates_dp_attribute__c> mapFltRatDPatr, cuco__ps_catalog_flat_rates_dp_attribute__c mpatRatesDP, List<cuco.FlatRates_Wrapper.FlatRatesDP> flatRatesDPListAx) {
    final List<cuco.FlatRates_Wrapper.FlatRatesDP> flatRatesDPList = flatRatesDPListAx;
    final cuco.FlatRates_Wrapper.FlatRatesDP flatRatesDP = new cuco.FlatRates_Wrapper.FlatRatesDP();
    flatRatesDP.id = mpatRatesDP.cuco__gf_psc_fr_dynamic_pricing_id__c;
    final cuco__ps_catalog_flat_rates_dp__c psfatRadp = mappsFlatRatDP.get((String)recordMap.get(mpatRatesDP.cuco__gf_psc_fr_dynamic_pricing_id__c));
    system.debug(psfatRadp);
    flatRatesDP.visualizOrder = mpatRatesDP.cuco__gf_psc_fr_dynamic_pricing_id__r.cuco__gf_psc_fr_dp_visual_ord_number__c;
    //PS Catalog Attribute
    final List<cuco.FlatRates_Wrapper.DPAttribute> dPAttributeList = new List<cuco.FlatRates_Wrapper.DPAttribute>();
    final cuco.FlatRates_Wrapper.DPAttribute  dPAttribute = new cuco.FlatRates_Wrapper.DPAttribute();
    final cuco__ps_catalog_flat_rates_dp_attribute__c psfatRadpAttr = mapFltRatDPatr.get((String)recordMap.get('id'));
    dPAttribute.id = psfatRadpAttr.cuco__gf_psc_atribute_id__c;
    dPAttribute.canonicalId = psfatRadpAttr.cuco__gf_psc_dynamic_pricing_atrb_id__c;
    dPAttribute.value = getAttributeValue((List<Object>)recordMap.get(FORMATSVAR), psfatRadpAttr.cuco__gf_psc_atribute_id__r.cuco__gf_psc_bknd_svc_format_type__c);
    dPAttribute.visualizOrder = psfatRadpAttr.cuco__gf_dp_atrb_vslztn_ord_number__c;
    dPAttribute.destinyApiName = psfatRadpAttr.cuco__gf_psc_atribute_id__r.cuco__gf_stored_prps_atrb_field_name__c;
    dPAttribute.valueTypeName = psfatRadpAttr.cuco__gf_psc_atribute_id__r.cuco__gf_attribute_value_type_name__c;
    final List<String> decimalLstValueFt = new List<String>{'Number', 'Currency', 'Percent'};
    system.debug(decimalLstValueFt);
    if(psfatRadpAttr.cuco__gf_psc_atribute_id__r.cuco__gf_stored_fnl_atrb_field_name__c != null) {
      if(decimalLstValueFt.contains(psfatRadpAttr.cuco__gf_psc_atribute_id__r.cuco__gf_attribute_value_type_name__c)) {
        final Integer lengthValue = Schema.getGlobalDescribe().get(PROFANALYSIS).getDescribe().fields.getMap().get(CUCOVAR + psfatRadpAttr.cuco__gf_psc_atribute_id__r.cuco__gf_stored_prps_atrb_field_name__c).getDescribe().getPrecision();
        final Integer decimalValue = Schema.getGlobalDescribe().get(PROFANALYSIS).getDescribe().fields.getMap().get(CUCOVAR + psfatRadpAttr.cuco__gf_psc_atribute_id__r.cuco__gf_stored_prps_atrb_field_name__c).getDescribe().getScale();
        dPAttribute.lengthValue = String.valueOf(lengthValue);
        dPAttribute.decimalValue = String.valueOf(decimalValue);
        dPAttribute.isDecimal = true;
      } else {
        dPAttribute.isDecimal = false;
      }
    }
    dPAttributeList.add(dPAttribute);
    flatRatesDP.dpAttributeList = dPAttributeList;
    flatRatesDPList.add(flatRatesDP);
    return flatRatesDPList;
  }

  /**
  * @description returns list condition
  * @param recordMap : current record
  * @param mapConditionAttr : flate rate Wapper
  * @param conditionsAux : map of flate rate attributes
  * @return Map<String, cuco.ProfitabilitySheet_Wrapper.Condition>
  */
  private static Integer stFatRate(Map<String, Object> recordMap, Map<String, cuco__ps_catalog_flat_rates_attribute__c> mapfrAttributes, Integer fatrateAux, cuco.FlatRates_Wrapper  flatRateWrapper) {
    Integer fatrate = fatrateAux;
    if (recordMap.get('conditionType') == 'SIMPLE' && getoriginId(recordMap) == 'FLAT_INFORMATION' && mapfrAttributes.containsKey((String)recordMap.get('id'))) {
      fatrate = fatrate + 1;
      setFlatInfoWrapper( recordMap,  flatRateWrapper, mapfrAttributes);
    }
    return fatrate;
  }

  /**
  * @description returns list condition
  * @param recordMap : current record
  * @param mapConditionAttr : flate rate Wapper
  * @param conditionsAux : map of flate rate attributes
  * @return Map<String, cuco.ProfitabilitySheet_Wrapper.Condition>
  */
  private static List<cuco.FlatRates_Wrapper.FlatRatesAccount> stFlatAcc(Map<String, Object> recordMap, Map<String, cuco__ps_catalog_flat_rates_account__c> mappscfrAccount, List<cuco.FlatRates_Wrapper.FlatRatesAccount> flatRatesAccountx) {
    final List<cuco.FlatRates_Wrapper.FlatRatesAccount> flatRatesAccount = flatRatesAccountx;
    if (recordMap.get('conditionType') == 'SIMPLE' && getoriginId(recordMap) == 'PROFIT_LOSS_ACCOUNT' && mappscfrAccount.containsKey((String)recordMap.get('id'))) {
      final cuco.FlatRates_Wrapper.FlatRatesAccount frateacc = new cuco.FlatRates_Wrapper.FlatRatesAccount();
      final cuco__ps_catalog_flat_rates_account__c flatRateAccAtt = mappscfrAccount.get((String)recordMap.get('id'));

      if (mappscfrAccount.containsKey(flatRateAccAtt.cuco__gf_psc_flat_rate_ac_svc_id__c)) {
        fatrateaccount = fatrateaccount + 1;
        frateacc.id = flatRateAccAtt.id;
        frateacc.usePercent =  decimal.valueof(getAttributeValue((List<Object>)recordMap.get(FORMATSVAR), 'RATE'));
        flatRatesAccount.add(frateacc);
      }
      system.debug(frateacc);
    }
    return flatRatesAccount;
  }

  /**
  * @description returns list condition
  * @param recordMap : current record
  * @param mapConditionAttr : flate rate Wapper
  * @param conditionsAux : map of flate rate attributes
  * @return Map<String, cuco.ProfitabilitySheet_Wrapper.Condition>
  */
  private static cuco.ProfitabilitySheet_Wrapper initializeWrap(Map<String, Object> responseMap, cuco__profitability_sheet__c profSheet, String psStatus) {
    final cuco.ProfitabilitySheet_Wrapper wrapper = new cuco.ProfitabilitySheet_Wrapper();
    List<cuco.ProfitabilitySheet_Wrapper.Participant> participantsList = new List<cuco.ProfitabilitySheet_Wrapper.Participant>();
    final Map<String, Object> mapData = (Map<String, Object>) responseMap.get('data');
    final Map<String, Object> branchCode = (Map<String, Object>)mapData.get('branch');
    final Map<String, Object> segmentType = (Map<String, Object>)mapData.get('segmentType');
    final Map<String, Object> businessAgent = (Map<String, Object>)mapData.get('businessAgent');

    wrapper.id = profSheet.id;
    wrapper.code = profSheet.cuco__gf_profitability_sheet_id__c;
    wrapper.groupId = profSheet.cuco__participant_id__c;
    wrapper.status = psStatus;
    wrapper.branchCode = mapData.containsKey('branch') ? (String) branchCode.get('id') : '' ;
    wrapper.segment = mapData.containsKey('segmentType') ?  (String) segmentType.get('id') : '' ;
    wrapper.ownerCode = mapData.containsKey('businessAgent') ? (String) businessAgent.get('id') : '' ;
    wrapper.isSpecificContractsScope = mapData.containsKey('isSpecificContractsScope') ? (Boolean) mapData.get('isSpecificContractsScope') : false ;
    wrapper.isForcedManualManagement = false;

    if (mapData.containsKey('conditionsStartDate')) {
      wrapper.startDate = Date.valueOf((String)mapData.get('conditionsStartDate'));
    }

    if (mapData.containsKey('endDate')) {
      wrapper.endDate = Date.valueOf((String)mapData.get('endDate'));
    }

    if (mapData.containsKey('participants')) {
      participantsList = getParticipants((List<Object>)mapData.get('participants'));
    }

    wrapper.participantsList = participantsList;
    wrapper.conditionsList = new List<cuco.ProfitabilitySheet_Wrapper.Condition>();
    return wrapper;
  }

  /**
  * @description returns list condition
  * @param recordMap : current record
  * @param mapConditionAttr : flate rate Wapper
  * @param conditionsAux : map of flate rate attributes
  * @return Map<String, cuco.ProfitabilitySheet_Wrapper.Condition>
  */
  private static cuco.ProfitabilitySheet_Wrapper stFlatCond(cuco.ProfitabilitySheet_Wrapper wrapper, List<cuco.FlatRates_Wrapper.FlatRatesAccount> flatRatesAccount, List<cuco.FlatRates_Wrapper.FlatRatesDP> flatRatesDPList, cuco.FlatRates_Wrapper  flatRateWrapper, Integer fatrate, Integer fatratedp, Map<String, cuco.ProfitabilitySheet_Wrapper.Condition> conditions, String extendedPackage) {
    if(fatrate > 0) {
      if(fatrateaccount > 0) {
         flatRateWrapper.flatRatesAccountList = flatRatesAccount;
      }
      if(fatratedp > 0) {
         flatRateWrapper.flatRatesDPList = flatRatesDPList;
      }
      wrapper.flatRates =  flatRateWrapper;
    }
    for (String key : conditions.keySet()) {
      final cuco.ProfitabilitySheet_Wrapper.Condition condition = (cuco.ProfitabilitySheet_Wrapper.Condition)conditions.get(key);
      if(!String.isEmpty(extendedPackage) && getExtendedPackageType(condition.source) && extendedPackage != 'DEFAULT_INTERNAL') {
        condition.sourceCode = extendedPackage;
      }
      wrapper.conditionsList.add(condition);
    }
    return wrapper;
  }

  /**
  * @description returns list condition
  * @param recordMap : current record
  * @param mapConditionAttr : flate rate Wapper
  * @param conditionsAux : map of flate rate attributes
  * @return Map<String,Object>
  */
  private static Map<String,Object> stElseResponse(Map<String,Object> recordMapAux, HttpResponse response) {
    final Map<String,Object> returnMap = recordMapAux;
    String error = null;
    final Map<String,Object> errorMap = (Map<String,Object>) JSON.deserializeUntyped(response.getBody());
    if (errorMap.containsKey('messages')) {
      final List<Object> messageMapList = (List <Object>) errorMap.get('messages');
      final Map<String,Object> messageMap = (Map<String,Object>) messageMapList[0];
      if (messageMap.containsKey('message')) {
        error = (String) messageMap.get('message');
      }
    }
    returnMap.put('success', false);
    returnMap.put('errorMessage', Label.cuco.error_ps_conditions_details + ' ' + error);
    return returnMap;
  }


}