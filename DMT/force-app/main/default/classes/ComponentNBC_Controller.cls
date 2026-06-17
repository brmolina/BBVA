/**
 * Controlador para el Componente NBC
 *
 * @author Desktop
 */
@SuppressWarnings('PMD.CyclomaticComplexity,PMD.CognitiveComplexity, sf:NPathComplexity, PMD.NcssMethodCount')
public with sharing class ComponentNBC_Controller {
  /**
   * Lista de configuraciones del template
   */
  public static List<Template_Configurations__c> listTemConfigs = new List<Template_Configurations__c>(); //NOSONAR
  /**
   * Mapa de regiones del pais
   */
  public static final Map<String, String> MAPCOUNTRYREGION = new Map<String, String>();

  /**
   *
   * @author GlobalDesktop
   */
  public static ComponentNBC_Controller instance {
    get {
      if (instance == null) {
        instance = new ComponentNBC_Controller();
      }
      return instance;
    }
    set {

    }
  }

  /**
   *
   * @author GlobalDesktop
   */
  //private static ComponentNBC_Controller instance;

  /**
   * Constructor
   * @author GlobalDesktop
   */
  private ComponentNBC_Controller() {
    //this.logic = new ActivitiesUtils();
  }


  /**
   * Met0d0 para obtener el Id del template
   *
   * @param product
   * @param booking
   * @param amount
   * @param bookingCibBec
   * @param substandardOp
   *
   * @return
   */
  public static Id getTemplateId(String product, String booking, Decimal amount, String bookingCibBec, Boolean substandardOp) {
    Id templateId;
    system.debug('>>>>> product : ' + product);
    system.debug('>>>>> booking : ' + booking);
    system.debug('>>>>> amount : ' + amount);
    system.debug('>>>>> bookingCibBec : ' + bookingCibBec);
    system.debug('>>>>> substandardOp : ' + substandardOp);

    for (Template_Configurations__c temConfig : listTemConfigs) {
      system.debug('>>>>> temConfig : ' + temConfig);

      if(product == Label.DES_Project_Finance_Lending
         && bookingCibBec == 'CIB'
         && temConfig.Product_id__r.Name == product) {
        templateId = Schema.SObjectType.DES_Template__c.getRecordTypeInfosByDeveloperName().get(temConfig.Template_type__c).getRecordTypeId();
      } else if(product == Label.DES_Leverage_Buyout_LBOs
                && bookingCibBec == 'CIB'
                && temConfig.Product_id__r.Name == product) {
        system.debug('>>>>> temConfig.Product_id__r.Name : ' + temConfig.Product_id__r.Name);
        templateId = Schema.SObjectType.DES_Template__c.getRecordTypeInfosByDeveloperName().get(temConfig.Template_type__c).getRecordTypeId();
      } else if((product == Label.DES_Transaction_Trade_Finance || product == Label.DES_Working_Capital)
                && temConfig.Product_id__r.Name == product
                && (temConfig.Booking_type__c == null || temConfig.Booking_type__c == booking)
                && (temConfig.Amount_num__c == 0 || amount >= temConfig.Amount_num__c)
                && (substandardOp == temConfig.Substandard_Operation__c)) {
        templateId = Schema.SObjectType.DES_Template__c.getRecordTypeInfosByDeveloperName().get(temConfig.Template_type__c).getRecordTypeId();
      } else if(temConfig.Product_id__r.Name == product
                && (temConfig.Booking_type__c == null || temConfig.Booking_type__c == booking)
                && bookingCibBec == 'CIB'
                && (temConfig.Amount_num__c == 0 || amount >= temConfig.Amount_num__c)
                && (substandardOp == temConfig.Substandard_Operation__c)) {
        templateId = Schema.SObjectType.DES_Template__c.getRecordTypeInfosByDeveloperName().get(temConfig.Template_type__c).getRecordTypeId();
      }
    }
    return templateId;
  }

  /**
   * setter para rellenar el mapa de las regiones de pais
   */
  public static void setMapCountryRegion() {
    if(MAPCOUNTRYREGION.isEmpty()) {
      // se añade limite 2000 para cumplir la regla del sonar "Avoid Calling SOQL Without a Where Clause or Limit Statement"
      for(Opp_Countries__mdt countryRegMDT : [SELECT Id, NBC_Region__c, MasterLabel, DeveloperName FROM Opp_Countries__mdt LIMIT 2000]) {
        MAPCOUNTRYREGION.put(countryRegMDT.DeveloperName, countryRegMDT.NBC_Region__c);
      }
    }
    system.debug('>>>>> mapCountryRegion : ' + MAPCOUNTRYREGION);
  }

  /**
   * getter para obtener la lista de configuraciones del template
   */
  public static void getTemplateConfigurationsList() {

    // se añade limite 2000 para cumplir la regla del sonar "Avoid Calling SOQL Without a Where Clause or Limit Statement"
    if(listTemConfigs.isEmpty()) {
      listTemConfigs = new List<Template_Configurations__c>([SELECT Id, Product_id__r.Name, Name, Amount_num__c, Booking_type__c, Substandard_Operation__c, Product_id__c, Template_type__c FROM Template_Configurations__c LIMIT 2000]);
    }
    system.debug('>>>>> listTemConfigs : ' + listTemConfigs);
  }

  /**
   *
   *
   * @param recordId
   *
   * @return
   */
  @AuraEnabled
  public static String typeNBC(String recordId) { //NOSONAR

    final Map<Id, OpportunityLineItem> mapProducts = new Map<Id, OpportunityLineItem>([SELECT Id, product_scope_type__c, syndicated_loan_drawn_amount__c, Converted_Currency__c, opportunity_stage_type__c, DES_Product_Family__c, solution_classification_desc__c, subproduct_name__c, OpportunityId, bbva_prtcp_tranche_amount__c, Name, Opportunity.DES_Booking_Geography__c, Opportunity.gf_opportunity_nbc_name__c, Opportunity.Name, Opportunity.CurrencyIsoCode, Product2Id, Opportunity.Substandard_Operation__c FROM OpportunityLineItem WHERE OpportunityId = : recordId]);
    setMapCountryRegion();
    Desktop_Utils.setMapCountryTemplateName();
    getTemplateConfigurationsList();
    Id templateRTId = null;
    //String oppName;
    String productName;
    String oppProductId;
    String oppBookingGeo;
    String currencyIso;
    String portfolio;
    Boolean oppSubstandardOp;
    boolean hasPF = false;
    for(OpportunityLineItem oppl : mapProducts.values()) {
      if(templateRTId != null && oppl.solution_classification_desc__c != Label.DES_Project_Finance_Lending) {
        system.debug('::::: SALTO PRODUCTO.');
        continue;
      }
      //oppName = oppl.Opportunity.Name;
      system.debug('>>>>> oppl.solution_classification_desc__c : ' + oppl.solution_classification_desc__c);
      system.debug('>>>>> region : ' + MAPCOUNTRYREGION.get(oppl.Opportunity.DES_Booking_Geography__c));
      system.debug('>>>>> oppl.Opportunity.DES_Booking_Geography__c : ' + oppl.Opportunity.DES_Booking_Geography__c);
      system.debug('>>>>> oppl.bbva_prtcp_tranche_amount__c : ' + oppl.bbva_prtcp_tranche_amount__c);
      system.debug('>>>>> oppl.syndicated_loan_drawn_amount__c : ' + oppl.syndicated_loan_drawn_amount__c);
      system.debug('>>>>> oppl.product_scope_type__c : ' + oppl.product_scope_type__c);
      system.debug('>>>>> oppl.Opportunity.Substandard_Operation__c : ' + oppl.Opportunity.Substandard_Operation__c);
      Id idTemplateAux;
      if(oppl.solution_classification_desc__c == Label.DES_Project_Finance_Lending) {
        idTemplateAux = getTemplateId(oppl.solution_classification_desc__c, MAPCOUNTRYREGION.get(oppl.Opportunity.DES_Booking_Geography__c), oppl.Converted_Currency__c, oppl.product_scope_type__c, oppl.Opportunity.Substandard_Operation__c);
        system.debug('::::: idTemplateAux - getTemplateId: ' + idTemplateAux);
        if (idTemplateAux != null) {
          templateRTId = idTemplateAux;
        }
        hasPF = true; //NOSONAR
        productName = oppl.solution_classification_desc__c;
        oppProductId = oppl.Id;
        oppBookingGeo = oppl.Opportunity.DES_Booking_Geography__c;
        portfolio = oppl.Opportunity.gf_opportunity_nbc_name__c;
        currencyIso = oppl.Opportunity.CurrencyIsoCode;
        oppSubstandardOp = oppl.Opportunity.Substandard_Operation__c;
      } else if(!hasPF
                && (oppl.solution_classification_desc__c == Label.DES_Transaction_Trade_Finance
                    || oppl.solution_classification_desc__c == Label.DES_Structure_Trade_Finance
                    || oppl.solution_classification_desc__c == Label.DES_Corporate_Loans
                    || oppl.solution_classification_desc__c == Label.DES_Leverage_Buyout_LBOs
                    || oppl.solution_classification_desc__c == LABEL.DES_Working_Capital
                    )
                && templateRTId == null) { //AQUI CUYO AMOUNT SON EL CAMPO BBVA COMMITMENT
        system.debug('>>>>> ELSE IF 1');
        productName = oppl.solution_classification_desc__c;
        oppProductId = oppl.Id;
        oppBookingGeo = oppl.Opportunity.DES_Booking_Geography__c;
        portfolio = oppl.Opportunity.gf_opportunity_nbc_name__c;
        oppSubstandardOp = oppl.Opportunity.Substandard_Operation__c;
        idTemplateAux = getTemplateId(oppl.solution_classification_desc__c, MAPCOUNTRYREGION.get(oppl.Opportunity.DES_Booking_Geography__c), oppl.Converted_Currency__c, oppl.product_scope_type__c,oppSubstandardOp);
        system.debug('::::: idTemplateAux - getTemplateId: ' + idTemplateAux);
        if (idTemplateAux != null) {
          templateRTId = idTemplateAux;
        }
        currencyIso = oppl.Opportunity.CurrencyIsoCode;
      }
    }
    system.debug('>>>>> templateRecordTypeId : ' + templateRTId);

    final Opportunity opp = [select Account.Name, AccountId, Account.DES_Main_Parent__c, Account.DES_Client_Type__c, PAW_simulation_Id__c, PAW_simulation_url__c from Opportunity where Id = :recordId LIMIT 1];
    List<DES_Denorm_AccountVisits__c> listVisit = new List<DES_Denorm_AccountVisits__c>();

    if(opp.AccountId != null) {
      listVisit = [SELECT id, DES_Start_Date__c FROM DES_Denorm_AccountVisits__c WHERE DES_Client__c = :opp.AccountId AND DES_Start_Date__c != null AND DES_Start_Date__c <= TODAY ORDER BY DES_Start_Date__c DESC]; //NOSONAR
    }

    final String clientName = opp.Account.Name;

    Date lastDateVisit;
    if ( listVisit != null && !listVisit.isEmpty() ) {
      lastDateVisit = Date.valueOf(listVisit[0].DES_Start_Date__c);
    }

    final DES_Template__c template = createTemplate(templateRTId, oppProductId, recordId, oppBookingGeo == 'NY' ? (portfolio != null && portfolio != '' ? portfolio : 'USA') : Desktop_Utils.mapCountryTemplateName.get(oppBookingGeo), clientName,lastDateVisit,productName, currencyIso); //NOSONAR

    // 2022-10-03 torcuato.tejada.contractor@bbva.com
    // Preload ESG Information from Toolkit
    final cstk__toolkit_settings__mdt bypassNbc = cstk.Utils.getGeneralConfiguration();
    if (bypassNbc != null && !bypassNbc.cstk__bypass_nbc__c) {
      preloadToolkitInfo(opp, template);
    }

    // 2024-11-22 torcuato.tejada.tech@bbva.com
    // Add PAWIF Id and URL to NBC Template
    template.PAWIF_Simulation_Id__c = opp.PAW_simulation_Id__c;
    template.PAWIF_Simulation_URL__c = opp.PAW_simulation_url__c;

    if(!Test.isRunningTest()) { //NOSONAR
      insert template;
    }

    //return String.valueof(System.URL.getOrgDomainURL().toExternalForm() + '/lightning/r/DES_Template__c/' + template.id  + '/view');
    //return templateRecordTypeId;
    return '/lightning/r/DES_Template__c/' + template.id  + '/view';

  }

  /**
   * Mét0d0 para crear un Template
   *
   * @param recordTypeId
   * @param oppProductId
   * @param oppId
   * @param templateRegion
   * @param clientName
   * @param lastDateVisit
   *
   * @return objeto DES_Template__c
   */
  private static DES_Template__c createTemplate(Id recordTypeId, Id oppProductId, Id oppId, String templateRegion, String clientName, Date lastDateVisit, String productName, String currencyIso) {//NOSONAR
    DES_Template__c template;
    template = new DES_Template__c();
    template.recordTypeId = recordTypeId;
    if(templateRegion == null) {
      template.Name = 'NBC' + ' ' + clientName;
    } else {
      template.Name = 'NBC' + ' ' + templateRegion + ' ' + clientName;
    }

    if (template.Name.length() > 80) {
      template.Name = template.Name.substring(0,79) + '.';
    }

    template.Opportunity_Product_Id__c = oppProductId;
    template.opportunity_id__c = oppId;
    template.Product_Name__c = productName;
    template.CurrencyIsoCode = currencyIso;

    if(lastDateVisit != null) {
      template.Last_Visit_to_the_Client_desc__c = lastDateVisit;
    }

    return template;
  }


  /**
  * @description Preload ESG Information from Toolkit from Account or Group
  * @param opp : opportunity
  * @param template : NBC template
  * @return populate template fields with toolkit info
  */
  public static void preloadToolkitInfo(Opportunity opp, DES_Template__c template) {

    Id toolkitAccountId;

    if (opp.Account.DES_Client_Type__c == 'CIB Group') {
      toolkitAccountId = opp.AccountId;
    } else {
        if (!String.isEmpty(opp.Account.DES_Main_Parent__c)) {
            toolkitAccountId = opp.Account.DES_Main_Parent__c;
        }
    }

    if (!String.isEmpty(toolkitAccountId)) {
      List<cstk__Toolkit__c> toolkits = [SELECT Id FROM cstk__Toolkit__c WHERE cstk__account_id__c = :toolkitAccountId LIMIT 1];

      System.debug('--> toolkits found: ' + toolkits);

      if (toolkits.size() > 0) {
        Map<string, object> cstkInfo = loadToolkitInfo(toolkits[0].Id);

        template.gf_paris_agreement_ind_type__c = getDefaultValue(cstkInfo.get('ParisAlignment'), '');
        template.gf_esg_score_close_ope_name__c = getDefaultValue(cstkInfo.get('EsgScore'), '');
        template.gf_co_list_tcfd_ind_type__c = getDefaultValue(cstkInfo.get('TcfdSupporter'), '');
        template.gf_customer_sustnbl_strg_desc__c = getDefaultValue(cstkInfo.get('SustainableStrategy'), '');
        template.cstk_tri_engagement_plan__c = getDefaultValue(cstkInfo.get('TRIEngagementPlan'), '');
        template.cstk_positioning__c = getDefaultValue(cstkInfo.get('Positioning'), '');
        template.cstk_group_alignment_degree__c = getDefaultValue(cstkInfo.get('GroupAlignmentDegree'), '');
        template.cstk_sector_alignment_degree__c = getDefaultValue(cstkInfo.get('SectorAlignmentDegree'), '');
        template.cstk_emissions_intensity_units__c = getDefaultValue(cstkInfo.get('EmissionIntensityMetric'), '');
        template.cstk_sust_indicators_comments__c = getDefaultValue(cstkInfo.get('TRIAssesment'), '');
        template.cstk_sector_affected__c = getDefaultValue(cstkInfo.get('Scope'), '');
        try {
          template.Sectorial_Norms_type__c = getDefaultValue(cstkInfo.get('SectorAffected'), '');
        } catch (Exception e) {
          system.debug('Sector Affected has a value not available on picklist field');
        }

        template.Reputational_Risk_type__c = getDefaultValue(cstkInfo.get('ReputationalRisk'), '');
        template.cstk_gf_cust_esg_profile_aspects_improve__c = getDefaultValue(cstkInfo.get('GroupEngagementPlan'), '');
        template.cstk_portfolio_alignment_engagement_link__c = getDefaultValue(cstkInfo.get('PlanLink'), '');

        try {
          template.cstk_tri_auto__c = Decimal.valueOf(String.valueOf(cstkInfo.get('triAuto')));
        } catch (Exception e) {
          template.cstk_tri_auto__c = null;
          system.debug('Tri Auto cannot be converted to decimal');
        }

        try {
          template.cstk_tri_autoparts__c = Decimal.valueOf(String.valueOf(cstkInfo.get('triAutoparts')));
        } catch (Exception e) {
          template.cstk_tri_autoparts__c = null;
          system.debug('Tri Autoparts cannot be converted to decimal');
        }

        try {
          template.cstk_tri_cement__c = Decimal.valueOf(String.valueOf(cstkInfo.get('triCement')));
        } catch (Exception e) {
          template.cstk_tri_cement__c = null;
          system.debug('Tri Cement cannot be converted to decimal');
        }

        try {
          template.cstk_tri_energy__c = Decimal.valueOf(String.valueOf(cstkInfo.get('triEnergy')));
        } catch (Exception e) {
          template.cstk_tri_energy__c = null;
          system.debug('Tri Energy cannot be converted to decimal');
        }

        try {
          template.cstk_tri_generic__c = Decimal.valueOf(String.valueOf(cstkInfo.get('triGeneric')));
        } catch (Exception e) {
          template.cstk_tri_generic__c = null;
          system.debug('Tri Generic cannot be converted to decimal');
        }

        try {
          template.cstk_tri_steel__c = Decimal.valueOf(String.valueOf(cstkInfo.get('triSteel')));
        } catch (Exception e) {
          template.cstk_tri_steel__c = null;
          system.debug('Tri Steel cannot be converted to decimal');
        }

        try {
          template.cstk_tri_utilities__c = Decimal.valueOf(String.valueOf(cstkInfo.get('triUtilities')));
        } catch (Exception e) {
          template.cstk_tri_utilities__c = null;
          system.debug('Tri Utilities cannot be converted to decimal');
        }

        //Thermal Coal Fields Added
        template.cstk_g_thermal_coal_exps_ind_type__c = getDefaultValue(cstkInfo.get('ExposureThermalCoal'), '');
        template.cstk_g_thermal_coal_exps_i_src_type__c = getDefaultValue(cstkInfo.get('ExposureIndicatorSource'), '');
        template.cstk_g_coal_prgrsv_red_pl_ind_type__c = getDefaultValue(cstkInfo.get('CoalPhaseOutPlan'), '');
        try {
          template.cstk_gf_thermal_coal_rev_wg_per__c = Decimal.valueOf(String.valueOf(cstkInfo.get('RevenuesThermalCoalActivity'))) * 100;
        } catch (Exception e) {
          system.debug('Revenues Thermal Coal Activity is null and cannot be converted to decimal');
        }
        try {
          template.cstk_gf_thermal_coal_prod_wg_per__c = Decimal.valueOf(String.valueOf(cstkInfo.get('CapacityWeight'))) * 100;
        } catch (Exception e) {
          system.debug('Capacity Weight is null and cannot be converted to decimal');
        }
        //END Thermal Coal Fields

        //template.gf_pitch_oppy_l12m_ibf_desc__c = getDefaultValue(cstkInfo.get('lastPitchIbf'), '');
        //template.gf_pitch_oppy_l12m_gm_desc__c = getDefaultValue(cstkInfo.get('lastPitchGm'), '');
        //template.gf_pitch_oppy_l12m_gtb_desc__c = getDefaultValue(cstkInfo.get('lastPitchGtb'), '');

        try {
          template.cstk_tri__c = Decimal.valueOf(String.valueOf(cstkInfo.get('TRI')));
        } catch (Exception e) {
          system.debug('TRI is null and cannot be converted to decimal');
        }

        try {
          template.cstk_cca__c = Decimal.valueOf(String.valueOf(cstkInfo.get('CCA')));
        } catch (Exception e) {
          system.debug('CCA is null and cannot be converted to decimal');
        }

        try {
          template.cstk_cta__c = Decimal.valueOf(String.valueOf(cstkInfo.get('CTA')));
        } catch (Exception e) {
          system.debug('CTA is null and cannot be converted to decimal');
        }

        try {
          template.cstk_emissions_intensity__c = Decimal.valueOf(String.valueOf(cstkInfo.get('EmissionIntensity')));
        } catch (Exception e) {
          system.debug('Value is null and cannot be converted to decimal');
        }

      } else {
        System.debug('NO SUSTAINABILITY INFO FROM TOOLKIT: ' + toolkitAccountId);
      }
    }

  }

  private static String getDefaultValue(Object obj, String defaultStr) {
    String res = defaultStr;
    try {
        res = String.valueOf(obj);
    } catch (Exception e) {
      System.debug('Could not set value'); //NOSONAR
    }
    return res;
  }

  public static Map<String, Object> loadToolkitInfo(Id toolkitId) {

    final Map<String, Object> res = new Map<String, Object>();
    final Set<Id> ids = new Set<Id>{toolkitId};
    Map<String, Object> info = new Map<String, Object>();
    try {
      info = cstk.Toolkit_Service.getNbcInfo(toolkitId);
    } catch (Exception e) {
      System.debug('Could not get toolkit info'); //NOSONAR
    }
    List<cstk__General_Data__c> toolkits = new List<cstk__General_Data__c>();
    List<cstk__Strategy__c> listStrategy = new List<cstk__Strategy__c>();
    List<cstk__EmissionTarget__c> listTarget = new List<cstk__EmissionTarget__c>();
    List<cstk__Rating__c> ratingList = new List<cstk__Rating__c>();
    List<cstk__Tri_Generic__c> triGen = new List<cstk__Tri_Generic__c>();
    List<cstk__Tri_Autoparts__c> triAutoparts = new List<cstk__Tri_Autoparts__c>();
    //final cstk.Strategy_Wrapper getNbc =  cstk.Strategy_Service.getNbc(toolkitId);
    final String sector;
    if (!info.isEmpty()) {
      sector = (String)info.get('sector');
      toolkits = (List<cstk__General_Data__c>)info.get('GeneralData');
      listStrategy = (List<cstk__Strategy__c>)info.get('strategy');
      listTarget = (List<cstk__EmissionTarget__c>)info.get('emissionTargets');
      triGen = (List<cstk__Tri_Generic__c>)info.get('triGeneric');
      triAutoparts = (List<cstk__Tri_Autoparts__c>)info.get('triAutoparts');
    } 

    String rating;
    String sectorAvg;
    String reputational;
    String scope;

    if(!ratingList.isEmpty()) {
      String esgStr;
      rating = ratingList[0].cstk__rating__c;
      sectorAvg = ratingList[0].cstk__sector_avg__c;
      if (rating != null && sectorAvg != null) {
        try {
          if (Integer.valueOf(rating) > Integer.valueOf(sectorAvg)) {
              esgStr = 'Above industry average';
          } else if (Integer.valueOf(rating) == Integer.valueOf(sectorAvg)) {
              esgStr =  'Industry average';
          } else {
              esgStr =  'Below industry average';
          }
        } catch (Exception e) {
          System.debug('Invalid Type Integer for rating: ' + e.getMessage());
        }
      }
      res.put('EsgScore', esgStr);
    }

    if(!triGen.isEmpty()) {
      res.put('triGeneric', triGen[0].cstk__gf_generic_sector_tri_final_score_number__c);
    }
    if(!triAutoparts.isEmpty()) {
      res.put('triAutoparts', triAutoparts[0].cstk__gf_autoparts_sector_tri_final_score_id__c);
    }

    if(!toolkits.isEmpty()) {

        res.put('TRI',toolkits[0].cstk__gf_tri_final_score_number__c);
        res.put('CCA',toolkits[0].cstk__cca__c);
        res.put('CTA',toolkits[0].cstk__cta__c);
        res.put('TRIAssesment', toolkits[0].cstk__tri_assessment__c);
        res.put('Positioning', toolkits[0].cstk__gf_tri_final_score_label_desc__c);
        res.put('triUtilities',toolkits[0].cstk__gf_utilities_sc_tri_final_score_number__c);
        res.put('triAuto',toolkits[0].cstk__gf_auto_sector_tri_final_score_number__c);
        res.put('triEnergy',toolkits[0].cstk__gf_energy_sector_tri_final_score_number__c);
        res.put('triSteel',toolkits[0].cstk__gf_steel_sector_tri_final_score_number__c);
        res.put('triCement',toolkits[0].cstk__gf_cement_sector_tri_final_score_number__c);


        if (toolkits[0].cstk__tfdc_supporter__c != null) {
            res.put('TcfdSupporter', toolkits[0].cstk__tfdc_supporter__c.toUpperCase());
        }

        if (toolkits[0].cstk__controversy__c != null) {
            Integer cont = Integer.valueOf(toolkits[0].cstk__controversy__c);
            if (cont >= 0 && cont <= 2) {
              reputational = 'Low';
            }
            if (cont >= 3 && cont <= 4) {
              reputational = 'Medium';
            }
            if (cont > 4) {
              reputational = 'High';
            }
        } else {
          reputational = 'N/A';
        }
        res.put('ReputationalRisk', reputational);
    }

    if (!listStrategy.isEmpty()) {
        res.put('TRIEngagementPlan',listStrategy[0].cstk__tri_engagement_link__c);
        res.put('GroupEngagementPlan', (!String.isBlank(listStrategy[0].cstk__gf_cust_esg_profile_aspects_improve_id__c)) ? 'Yes' : '');
        res.put('PlanLink', (!String.isBlank(listStrategy[0].cstk__gf_cust_esg_profile_aspects_improve_id__c)) ? listStrategy[0].cstk__portfolio_alignment_engagement_link__c : '');
        //res.put('SectorAffected',listStrategy[0].cstk__affected_sector__c);
        //Thermal coal fields goes here, get from toolkit
        res.put('ExposureThermalCoal',listStrategy[0].cstk__g_thermal_coal_exps_ind_type__c);
        res.put('RevenuesThermalCoalActivity',listStrategy[0].cstk__gf_thermal_coal_rev_wg_per__c);
        res.put('ExposureIndicatorSource',listStrategy[0].cstk__g_thermal_coal_exps_i_src_type__c);
        res.put('CapacityWeight',listStrategy[0].cstk__gf_thermal_coal_prod_wg_per__c);
        res.put('CoalPhaseOutPlan',listStrategy[0].cstk__g_coal_prgrsv_red_pl_ind_type__c);
        //Thermal coal fields goes here, to get from toolkit
    }

    if(!listTarget.isEmpty()) {
        /*if (listTarget[0].cstk__group_alignment_degree__c != null) {
            res.put('GroupAlignmentDegree', (listTarget[0].cstk__group_alignment_degree__c >= 1.0) ? 'Aligned' : 'Misaligned' );
        }
        if (listTarget[0].cstk__sector_alignment_degree__c != null) {
            res.put('SectorAlignmentDegree', (listTarget[0].cstk__sector_alignment_degree__c >= 1.0) ? 'Aligned' : 'Misaligned' );
        }*/
        if (listTarget[0].cstk__paris_alignment__c != null) {
            res.put('ParisAlignment', (listTarget[0].cstk__paris_alignment__c == 'No') ? 'NO' : 'YES');
        }

        //res.put('EmissionIntensity',listTarget[0].cstk__emissions_intensity__c);
        res.put('EmissionIntensityMetric',listTarget[0].cstk__emissions_intensity_units__c);
    }

    switch on sector {
      when 'Energy', 'Utilities', 'Steel', 'Cement' {
        scope = '1+2';
      }
      when 'Auto' {
        scope = '3';
      }
      when else {
        scope = 'N/A';
      }
    }

    res.put('Scope', scope);

    //res.put('lastPitchGm', getNbc.get('lastPitchMadeGm'));
    //res.put('lastPitchGtb', getNbc.get('lastPitchMadeGtb'));
    //res.put('lastPitchIbf', getNbc.get('lastPitchMadeIbf'));

    res.put('Rating',rating);
    res.put('SectorAverage', sectorAvg);
    return res;
  }

  /**
  * @description Preload ESG Information Template NBC CSL
  * @param request : List<DES_Template__c>
  * @return String of updated database
  */
  @auraEnabled
  public static void refreshToolkit(Id templateId) {
    List<DES_Template__c> request = new List<DES_Template__c>(); //NOSONAR
    request = [SELECT id, Status__c, opportunity_id__c, gf_paris_agreement_ind_type__c, gf_esg_score_close_ope_name__c, gf_co_list_tcfd_ind_type__c, gf_customer_sustnbl_strg_desc__c, cstk_tri_engagement_plan__c, cstk_positioning__c,
    cstk_group_alignment_degree__c, cstk_sector_alignment_degree__c, cstk_emissions_intensity_units__c, cstk_sust_indicators_comments__c, cstk_sector_affected__c, Sectorial_Norms_type__c, Reputational_Risk_type__c, cstk_g_thermal_coal_exps_ind_type__c,
    cstk_g_thermal_coal_exps_i_src_type__c, cstk_g_coal_prgrsv_red_pl_ind_type__c, cstk_gf_thermal_coal_rev_wg_per__c, cstk_gf_thermal_coal_prod_wg_per__c, cstk_tri__c, cstk_cca__c, cstk_cta__c, cstk_emissions_intensity__c,
    cstk_gf_cust_esg_profile_aspects_improve__c, cstk_portfolio_alignment_engagement_link__c, cstk_tri_auto__c, cstk_tri_autoparts__c, cstk_tri_cement__c, cstk_tri_energy__c, cstk_tri_generic__c, cstk_tri_steel__c, cstk_tri_utilities__c
    FROM DES_Template__c WHERE Id = :templateId];

    DES_Template__c requestAux = request[0]; //NOSONAR
    final Opportunity opp = [select Account.Name, AccountId, Account.DES_Main_Parent__c, Account.DES_Client_Type__c  from Opportunity where Id = :requestAux.opportunity_id__c LIMIT 1];
    final cstk__toolkit_settings__mdt bypassNbc = cstk.Utils.getGeneralConfiguration();
    if (bypassNbc != null && !bypassNbc.cstk__bypass_nbc__c) {
      preloadToolkitInfo(opp, requestAux);
    }
    System.debug('template to update: ' + requestAux);
    update requestAux;
    List<DES_Template_Table__c> lTabTempl = [SELECT id, gf_paris_agreement_ind_type__c, gf_esg_score_close_ope_name__c, gf_co_list_tcfd_ind_type__c, gf_customer_sustnbl_strg_desc__c, cstk_tri_engagement_plan__c, cstk_positioning__c,
    cstk_group_alignment_degree__c, cstk_sector_alignment_degree__c, cstk_emissions_intensity_units__c, cstk_sust_indicators_comments__c, cstk_sector_affected__c, Sectorial_Norms_type__c, Reputational_Risk_type__c, cstk_g_thermal_coal_exps_ind_type__c,
    cstk_g_thermal_coal_exps_i_src_type__c, cstk_g_coal_prgrsv_red_pl_ind_type__c, cstk_gf_thermal_coal_rev_wg_per__c, cstk_gf_thermal_coal_prod_wg_per__c, cstk_tri__c, cstk_cca__c, cstk_cta__c, cstk_emissions_intensity__c,
    cstk_gf_cust_esg_profile_aspects_improve__c, cstk_portfolio_alignment_engagement_link__c, cstk_tri_auto__c, cstk_tri_autoparts__c, cstk_tri_cement__c, cstk_tri_energy__c, cstk_tri_generic__c, cstk_tri_steel__c, cstk_tri_utilities__c
    FROM DES_Template_Table__c WHERE Parent_Template__c = :templateId LIMIT 1]; //NOSONAR
    If (!lTabTempl.isEmpty()) {
      lTabTempl[0].gf_paris_agreement_ind_type__c = requestAux.gf_paris_agreement_ind_type__c;
      lTabTempl[0].gf_esg_score_close_ope_name__c = requestAux.gf_esg_score_close_ope_name__c;
      lTabTempl[0].gf_co_list_tcfd_ind_type__c = requestAux.gf_co_list_tcfd_ind_type__c;
      lTabTempl[0].gf_customer_sustnbl_strg_desc__c = requestAux.gf_customer_sustnbl_strg_desc__c;
      lTabTempl[0].cstk_tri_engagement_plan__c = requestAux.cstk_tri_engagement_plan__c;
      lTabTempl[0].cstk_positioning__c = requestAux.cstk_positioning__c;
      lTabTempl[0].cstk_group_alignment_degree__c = requestAux.cstk_group_alignment_degree__c;
      lTabTempl[0].cstk_sector_alignment_degree__c = requestAux.cstk_sector_alignment_degree__c;
      lTabTempl[0].cstk_emissions_intensity_units__c = requestAux.cstk_emissions_intensity_units__c;
      lTabTempl[0].cstk_sust_indicators_comments__c = requestAux.cstk_sust_indicators_comments__c;
      lTabTempl[0].cstk_sector_affected__c = requestAux.cstk_sector_affected__c;
      lTabTempl[0].Sectorial_Norms_type__c = requestAux.Sectorial_Norms_type__c;
      lTabTempl[0].Reputational_Risk_type__c = requestAux.Reputational_Risk_type__c;
      lTabTempl[0].cstk_g_thermal_coal_exps_ind_type__c = requestAux.cstk_g_thermal_coal_exps_ind_type__c;
      lTabTempl[0].cstk_g_thermal_coal_exps_i_src_type__c = requestAux.cstk_g_thermal_coal_exps_i_src_type__c;
      lTabTempl[0].cstk_g_coal_prgrsv_red_pl_ind_type__c = requestAux.cstk_g_coal_prgrsv_red_pl_ind_type__c;
      lTabTempl[0].cstk_gf_thermal_coal_rev_wg_per__c = requestAux.cstk_gf_thermal_coal_rev_wg_per__c;
      lTabTempl[0].cstk_gf_thermal_coal_prod_wg_per__c = requestAux.cstk_gf_thermal_coal_prod_wg_per__c;
      lTabTempl[0].cstk_tri__c = requestAux.cstk_tri__c;
      lTabTempl[0].cstk_cca__c = requestAux.cstk_cca__c;
      lTabTempl[0].cstk_cta__c = requestAux.cstk_cta__c;
      lTabTempl[0].cstk_emissions_intensity__c = requestAux.cstk_emissions_intensity__c;
      lTabTempl[0].cstk_portfolio_alignment_engagement_link__c = requestAux.cstk_portfolio_alignment_engagement_link__c;
      lTabTempl[0].cstk_gf_cust_esg_profile_aspects_improve__c = requestAux.cstk_gf_cust_esg_profile_aspects_improve__c;
      lTabTempl[0].cstk_tri_auto__c = requestAux.cstk_tri_auto__c;
      lTabTempl[0].cstk_tri_autoparts__c = requestAux.cstk_tri_autoparts__c;
      lTabTempl[0].cstk_tri_cement__c = requestAux.cstk_tri_cement__c;
      lTabTempl[0].cstk_tri_energy__c = requestAux.cstk_tri_energy__c;
      lTabTempl[0].cstk_tri_generic__c = requestAux.cstk_tri_generic__c;
      lTabTempl[0].cstk_tri_steel__c = requestAux.cstk_tri_steel__c;
      lTabTempl[0].cstk_tri_utilities__c = requestAux.cstk_tri_utilities__c;

      update lTabTempl[0]; //NOSONAR
    }
  }

  /**
  * @description Preload ESG Information Template NBC CSL
  * @param request : List<DES_Template__c>
  * @return String of updated database
  */
  @auraEnabled
  public static String canbeRefreshedToolkit(String templateId) {
    List<DES_Template__c> request = new List<DES_Template__c>(); //NOSONAR
    request = [SELECT id, Status__c FROM DES_Template__c WHERE Id = :templateId LIMIT 1];
    String response = 'NO';
    If (!request.isEmpty() && request[0].Status__c == 'Not Submitted') {
      response = 'YES';
    }
    return response;
  }

}