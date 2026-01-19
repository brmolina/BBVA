/**********************************************************************************
* @author       Global Desktop  - DSL
* @date         05/2019
* @description  Clase con los methods y la funcionalidad que se encarga de validar los campos obligatorios necesarios para
                cambiar de fase la oportunidad
**********************************************************************************/
public with sharing class RelatedProductsValidations {

  /*
   *  Instancia de la clase RelatedTranchesValidations
   *
  */
  public RelatedTranchesValidations handlerTrancVal = RelatedTranchesValidations.getInstance();//NOSONAR

  /*
   *  Mapa que contiene el id de la Opp y el String del mensaje de error como value
   *
  */
  public Map<Id, String> mapOppProductsMess = new Map<Id, String>(); //NOSONAR

  /*
   *  Mapa que contiene como key el id de la opp y y como value un mapa <ProductId, OpportunityLineItem>
   *
  */
  final public Map<Id, List<OpportunityLineItem>> mapOppProducts = new Map<Id, List<OpportunityLineItem>>(); //NOSONAR

  /*
   *  Mapa que contiene los metadatos de los campos del objeto OpportunityLineItem
   *
  */
  final Map<String, Schema.SObjectField> oppliFieldMap = Schema.getGlobalDescribe().get('OpportunityLineItem').getDescribe().fields.getMap();

  /*
   *
  **/
  final Map <String,String> mapBookRegion = new Map<String,String>();

  /*
   *
  **/
  final Map <String,String> mapOppRegion = new Map<String,String>();

  /*
   *  Mapa que contiene el id del oppli y las label de los campos correspondientes
   *
  */
  Map<Id, String> mapOppliFldsLbl;

  /*
   *  Template Configurations
   *
  **/
  final List <Template_Configurations__c> configurations = new List <Template_Configurations__c> ([SELECT Name, Booking_type__c, Amount_num__c, Product_id__r.Name from Template_Configurations__c LIMIT 50000]);

  /* SINGLETON PATTERN
   *  @author GlobalDesktop  - DSL
   *
  **/
  private static RelatedProductsValidations instance;


	/* constructor
   *  @author GlobalDesktop  - DSL
   *
  **/
  private RelatedProductsValidations() {
    System.debug('CONSTRUCTOR');
  }

  /* SINGLETON PATTERN
   *  @author GlobalDesktop  - DSL
   *
  **/
  public static RelatedProductsValidations getInstance() { //NOSONAR
      if (instance == null) {
        instance = new RelatedProductsValidations();
      }
      return instance;
  }

  /*
  * @author   Global Desktop  - DSL
  * @Description  Funcion que se encarga de las validaciones de los campos obligatorios de los productos
  *
  **/
  public void validateProducts(Map<Id, Opportunity> triggerNewMap, Map<Id, Opportunity> triggerOldMap) {
    system.debug('>>>>> 1. ENTRO EN VALIDATEPRODUCTS');
    final Map<Id, Opportunity> mapOppsStageChg = handlerTrancVal.gtOppsStageChanged(triggerNewMap, triggerOldMap);

    for(Opp_Countries__mdt region : [SELECT DeveloperName, NBC_Region__c from Opp_Countries__mdt LIMIT 5000]) {
      if(!mapBookRegion.containsKey(region.DeveloperName)) {
        mapBookRegion.put(region.DeveloperName, region.NBC_Region__c);
      }
    }

    for(Opportunity  opp : triggerNewMap.values()) {

      if ( opp.opportunity_expiration_ind_type__c == false ) {
        if(mapBookRegion.containsKey(opp.DES_Booking_Geography__c)) {
          mapOppRegion.put(opp.id, mapBookRegion.get(opp.DES_Booking_Geography__c));
        }
      }

    }
    system.debug('>>>>> mapOppsStageChg: ' + mapOppsStageChg);
    if(!mapOppsStageChg.isEmpty()) {
      final Map<Id, OpportunityLineItem> mapAllOppli = gtAllProducts(mapOppsStageChg);
      system.debug('>>>>> mapAllOppli: ' + JSON.serialize(mapAllOppli));
      checkProductsFields(triggerNewMap, mapAllOppli);

    }
  }//FIN validateProducts



  /*
  * @author   Global Desktop  - DSL
  * @Description Funcion que devuelve un mapa con ALL los OpportunityLineItem (Opportunity product)
  *               a partir de las oportunidades indicadas por parametro
  *
  **/
  public Map<Id, OpportunityLineItem> gtAllProducts(Map<Id, Opportunity> mapOppsChanged) {//NOSONAR
    return new Map<Id, OpportunityLineItem>([
      SELECT Id, Name, OpportunityId, Opportunity.Name, Product2Id, Product2.Name, fprd__GBL_Empty_visible_fields__c,
              Opportunity.StageName, opportunity_nbc_recm_ind_type__c, Converted_Currency__c, product_scope_type__c,
              DES_Contract_Signed__c, subproduct_name__c, solution_name_path_desc__c
      FROM OpportunityLineItem
      WHERE OpportunityId IN :mapOppsChanged.keySet()
    ]);
  }//FIN gtAllProducts


  /*
  * @author   Global Desktop  - DSL
  * @Description Funcion que se encarga de validar que esten ALL los campos obligatorios
                 del objeto 'OpportunityLineItem' (Opportunity Products) rellenos.
  *
  **/
  private void checkProductsFields(Map<Id, Opportunity> triggerNewMap, Map<Id, OpportunityLineItem> mapAllOppli) {
    system.debug('>>>>> 2. ENTRO EN CHECKPRODUCTSFIELDS');
    mapOppliFldsLbl = new Map<Id, String>();
    system.debug('>>>>> mapAllOppli : ' + JSON.serialize(mapAllOppli));
    for(OpportunityLineItem oppli : mapAllOppli.values()) {//NOSONAR
      //Primero compruebo si es necesario template para pasar avanzar la fase de esta oportunidad
      checkNBCConditions(triggerNewMap, oppli);
      if(oppli.fprd__GBL_Empty_visible_fields__c != null
      && oppli.fprd__GBL_Empty_visible_fields__c != '') {
        fillmapProductFields(oppli);
        fillmapOppliFldsLbl(oppli, triggerNewMap);
      }
      checkOtherFields(oppli, triggerNewMap);
    }
    system.debug('>>>>> mapOppProducts: ' + JSON.serialize(mapOppProducts));
    createMapMessage();

    system.debug('>>>>> mapOppProductsMess: ' + JSON.serialize(mapOppProductsMess));
    for(Id oppId : mapOppProductsMess.keySet()) {
      system.debug('>>>>> mapOppProductsMess.get(oppId) : ' + mapOppProductsMess.get(oppId));
      //Sorry, you can't do this yet. To move forward the opportunity, please make sure that you have filled out the following fields:
      if(mapOppProductsMess.get(oppId) != null) {
        triggerNewMap.get(oppId).addError(Label.DES_PRODUCT_FIELD_REQUIRED_MESSAGE + mapOppProductsMess.get(oppId));
      }

    }

  }//FIN checkProductsFields

  /*
  * @author Global Desktop  - DSL
  * @Description  - Method que rellena el mapa mapOppProducts<OppId, listOpplis>
  *
  **/
  private void checkOtherFields(OpportunityLineItem oppli, Map<Id, Opportunity> triggerNewMap) {
    system.debug('>>>>> 7. ENTRO EN CHECK OTHER FIELDS');
    system.debug('>>>>> oppli: ' + JSON.serialize(oppli));
    system.debug('>>>>> triggerNewMap.get(oppli.OpportunityId).StageName: ' + triggerNewMap.get(oppli.OpportunityId).StageName);
    //Lógica que controla campos checkbox necesarios para ganar (como contract signed)
    // if(triggerNewMap.get(oppli.OpportunityId).StageName == Label.DES_Closed_Won
    // && /*(oppli.Product2.Name == Label.DES_Corporate_Loans
    // || oppli.Product2.Name == Label.DES_Leverage_Buyout_LBOs
    // ||*/ oppli.Product2.Name == Label.DES_Securities_Services/*)*/) {
    //   system.debug('>>>>> oppli.Product2.Name: ' + oppli.Product2.Name);
    //   if(!oppli.DES_Contract_Signed__c) {
    //     fillmapProductFields(oppli);
    //     if(mapOppliFldsLbl.get(oppli.Id) == null) {
    //       mapOppliFldsLbl.put(oppli.Id, 'Contract Signed');
    //     } else {
    //       mapOppliFldsLbl.put(oppli.Id, mapOppliFldsLbl.get(oppli.Id) + ', Contract Signed');
    //     }
    //     system.debug('>>>>> mapOppliFldsLbl: ' + JSON.serialize(mapOppliFldsLbl));
    //     system.debug('>>>>> mapOppProducts: ' + JSON.serialize(mapOppProducts));
    //   }
    // }

  }


  /*
  * @author Global Desktop  - DSL
  * @Description  - Method que rellena el mapa mapOppProducts<OppId, listOpplis>
  *
  **/
  private void fillmapProductFields(OpportunityLineItem oppli) {
    system.debug('>>>>> 4. ENTRO EN FILLMAPPRODUCTFIELDS');
    List<OpportunityLineItem> listOppliAux;
    if(mapOppProducts.get(oppli.OpportunityId) == null) {
      listOppliAux = new List<OpportunityLineItem>();
    } else {
      listOppliAux = mapOppProducts.get(oppli.OpportunityId);
    }

    listOppliAux.add(oppli);
    mapOppProducts.put(oppli.OpportunityId, listOppliAux);

  }//FIN fillmapProductFields

  /*
  * @author Global Desktop  - DSL
  * @Description  - Method que rellena el mapa 'mapOppliFldsLbl' que contiene
  *                 el Id de la oportunidad como key y los campos a rellenar por
  *
  **/
  @SuppressWarnings('all')
  private void fillmapOppliFldsLbl(OpportunityLineItem oppli, Map<Id, Opportunity> triggerNewMap) { //NOSONAR
    system.debug('>>>>> 5. ENTRO EN FILLMAPOPPLIFIELDS');
    String strFlds;
    strFlds = '';
    final List<String> listStrCLS = new List<String>{'fee_next_12m_amount__c', 'pre_net_margin_next_12m_amount__c', 'undrawn_fee_next_12m_amount__c',
    'deferred_fee_amount__c', 'no_deferred_fee_amount__c', 'periodic_fee_amount__c', 'underwriting_fee_amount__c',
    'opening_fee_amount__c', 'deferred_fee_per__c', 'opportunity_tenor_years_number__c', 'opening_fee_per__c', 'syndicated_loan_drawn_amount__c',
    'pre_net_margin_next_12m_per__c', 'credit_drawn_next_12m_per__c','pre_gross_margin_next_12m_per__c', 'funding_cost_per__c',
    'credit_undrawn_next_12m_per__c', 'undrawn_fee_next_12m_per__c', 'bbva_prtcp_tranche_amount__c'};

    final List<String> listStrPFL = new List<String>{'pre_oppy_revenue_next_12m_amount__c', 'fee_next_12m_amount__c', 'pre_net_margin_next_12m_amount__c',
    'undrawn_fee_next_12m_amount__c', 'deferred_fee_amount__c', 'no_deferred_fee_amount__c', 'periodic_fee_amount__c',
    'underwriting_fee_amount__c', 'opening_fee_amount__c', 'deferred_fee_per__c', 'opportunity_tenor_years_number__c',
    'opening_fee_per__c', 'syndicated_loan_drawn_amount__c', 'pre_net_margin_next_12m_per__c', 'credit_drawn_next_12m_per__c',
    'pre_gross_margin_next_12m_per__c', 'funding_cost_per__c', 'credit_undrawn_next_12m_per__c', 'undrawn_fee_next_12m_per__c'};

    final List<String> listStrLBO = new List<String>{'pre_oppy_revenue_next_12m_amount__c', 'bbva_prtcp_tranche_amount__c',
    'DES_BBVA_Final_Hold__c','fee_next_12m_amount__c', 'pre_net_margin_next_12m_amount__c', 'undrawn_fee_next_12m_amount__c',
    'deferred_fee_amount__c', 'no_deferred_fee_amount__c', 'periodic_fee_amount__c', 'underwriting_fee_amount__c', 'opening_fee_amount__c',
    'deferred_fee_per__c', 'opportunity_tenor_years_number__c', 'opening_fee_per__c', 'syndicated_loan_drawn_amount__c',
    'pre_net_margin_next_12m_per__c', 'credit_drawn_next_12m_per__c','pre_gross_margin_next_12m_per__c', 'funding_cost_per__c',
    'credit_undrawn_next_12m_per__c', 'undrawn_fee_next_12m_per__c'};

    final List<String> listStrPFA = new List<String>{'pre_oppy_revenue_next_12m_amount__c', 'fee_next_12m_amount__c', 'DES_Retainer_Fees_Next_12_Months__c'};

    final List<String> listStrECM = new List<String>{'pre_oppy_revenue_next_12m_amount__c', 'fee_next_12m_amount__c', 'DES_Retainer_Fees_Next_12_Months__c'};

    final List<String> listStrMA = new List<String>{'pre_oppy_revenue_next_12m_amount__c', 'fee_next_12m_amount__c', 'DES_Retainer_Fees_Next_12_Months__c'};
    final List<String> listStrDCM = new List<String>{'pre_oppy_revenue_next_12m_amount__c','fee_next_12m_amount__c'};
    final List<String> listStrCASHM = new List<String>{'pre_oppy_revenue_next_12m_amount__c','opportunity_sold_prdt_number__c','unit_price_with_tax_amount__c','fee_next_12m_amount__c','bbva_est_incm_next_12m_amount__c'};
    final List<String> listStrCR = new List<String>{'pre_oppy_revenue_next_12m_amount__c', 'pre_net_margin_next_12m_amount__c', 'pre_net_margin_next_12m_per__c', 'syndicated_loan_drawn_amount__c'};

    final List<String> listStrWCNS = new List<String>{'pre_oppy_revenue_next_12m_amount__c'}; //working capital sin subproducto

    final List<String> listStrWCCred = new List<String>{'pre_oppy_revenue_next_12m_amount__c', 'pre_net_margin_next_12m_per__c',
    'syndicated_loan_drawn_amount__c', 'credit_drawn_next_12m_per__c','opening_fee_per__c'}; //working capital con subproducto 'Credit Accounts'
    final List<String> listStrWCSsG = new List<String>{'pre_oppy_revenue_next_12m_amount__c', 'DES_Risk_Fee_Next_12_Months__c',
    'loan_tenor_month_desc__c'}; //working capital subproducto 'TB Guarantees'
    final List<String> listStrWCSnG = new List<String>{'pre_oppy_revenue_next_12m_amount__c', 'pre_net_margin_next_12m_per__c',
    'syndicated_loan_drawn_amount__c', 'credit_drawn_next_12m_per__c','opening_fee_per__c',
    'loan_tenor_month_desc__c'}; //working capital subproducto 'Bilateral Loans', 'SCF - Factoring' o 'SCF - Reverse Factoring'
    final List<String> listStrWCRL = new List<String>{'pre_oppy_revenue_next_12m_amount__c', 'pre_net_margin_next_12m_per__c',
    'syndicated_loan_drawn_amount__c', 'credit_drawn_next_12m_per__c','opening_fee_per__c'}; //working capital subproducto 'Renting' o 'Leasing'

    final List<String> listStrSTFnE = new List<String>{'pre_oppy_revenue_next_12m_amount__c','opening_fee_per__c', 'syndicated_loan_drawn_amount__c', 'deferred_fee_per__c', 'opportunity_tenor_years_number__c', 'no_deferred_fee_amount__c', 'periodic_fee_amount__c',
    'underwriting_fee_amount__c', 'pre_net_margin_next_12m_per__c','credit_drawn_next_12m_per__c', 'pre_gross_margin_next_12m_per__c ', 'funding_cost_per__c'};//STF general sin excepciones
    final List<String> listStrSTFsF = new List<String>{'pre_oppy_revenue_next_12m_amount__c', 'opening_fee_per__c',
    'syndicated_loan_drawn_amount__c', 'periodic_fee_amount__c'};//STF general sin excepciones
    final List<String> listStrSTFsECAG = new List<String>{'pre_oppy_revenue_next_12m_amount__c', 'DES_Risk_Fee_Next_12_Months__c', 'syndicated_loan_drawn_amount__c',
    'pre_net_margin_next_12m_amount__c', 'deferred_fee_amount__c', 'no_deferred_fee_amount__c', 'periodic_fee_amount__c'};//STF SI EL SUBPRODUCT ES ECA GUARANTEE

    final List<String> listStrTTFSinProd = new List<String>{'pre_oppy_revenue_next_12m_amount__c', 'deferred_fee_amount__c', 'no_deferred_fee_amount__c'};//Lista TTF SI NO SE ELIGE PRODUCTO
    final List<String> listStrTTFs1 = new List<String>{'pre_oppy_revenue_next_12m_amount__c', 'deferred_fee_amount__c','no_deferred_fee_amount__c', 'credit_undrawn_next_12m_per__c',
    'undrawn_fee_next_12m_per__c','pre_net_margin_next_12m_per__c',
    'syndicated_loan_drawn_amount__c', 'credit_drawn_next_12m_per__c'};//SI EL PRODUCTO ES es Trade Loans, Factoring,Forfaiting, SCF
    final List<String> listStrTTFs2 = new List<String>{'pre_oppy_revenue_next_12m_amount__c', 'deferred_fee_amount__c','no_deferred_fee_amount__c','DES_Risk_Fee_Next_12_Months__c', 'syndicated_loan_drawn_amount__c'};//Lista TTF SI LOS PRODUCTOS SON Guarantees/SBLCs Y SI LOS SUBPRODUCTOS SON TECHNICAL GUARANTEES ISSUANCE,FINANCIAL GUARANTEES ISSUANCE,SILENT GUARANTEES ISSUANCE, SBLC CONFIRMATION
    final List<String> listStrTTFs3 = new List<String>{'pre_oppy_revenue_next_12m_amount__c', 'deferred_fee_amount__c',
    'no_deferred_fee_amount__c','DES_Risk_Fee_Next_12_Months__c', 'syndicated_loan_drawn_amount__c','pre_net_margin_next_12m_per__c', 'credit_drawn_next_12m_per__c'};//Lista TTF SI LOS PRODUCTOS SON Guarantees/SBLCs Y SI LOS SUBPRODUCTOS SON SILENT GUARANTEES ISSUANCE & FINANCING:
    final List<String> listStrTTFs4 = new List<String>{'pre_oppy_revenue_next_12m_amount__c', 'deferred_fee_amount__c',
    'no_deferred_fee_amount__c','syndicated_loan_drawn_amount__c', 'credit_undrawn_next_12m_per__c', 'undrawn_fee_next_12m_per__c',
    'pre_net_margin_next_12m_per__c', 'credit_drawn_next_12m_per__c'};//Lista TTF SI EL PRODUCTO ES Letter of Credit Y LOS SUBPRODUCTOS SON IMPORT LC POST FINANCING, LC DISCOUNT,LC FORFAITING:
    system.debug('>>>>> LETTER OF CREDIT');
    final List<String> listStrTTFs5 = new List<String>{'pre_oppy_revenue_next_12m_amount__c', 'deferred_fee_amount__c','no_deferred_fee_amount__c',
    'credit_undrawn_next_12m_per__c', 'undrawn_fee_next_12m_per__c','pre_net_margin_next_12m_per__c',
    'credit_drawn_next_12m_per__c','DES_Risk_Fee_Next_12_Months__c', 'syndicated_loan_drawn_amount__c'};//Lista TTF SI EL PRODUCTO ES Letter of Credit Y LOS SUBPRODUCTOS SON IMPORT LC WITH BENEFICIARY FINANCING , LC CONFIRMATION AND DISCOUNT, LC CONFIRMATION AND POST FINANCING:
    system.debug('>>>>> LETTER OF CREDIT');
    final List<String> listStrTTFs6 = new List<String>{'pre_oppy_revenue_next_12m_amount__c', 'deferred_fee_amount__c','no_deferred_fee_amount__c',
    'syndicated_loan_drawn_amount__c', 'credit_undrawn_next_12m_per__c', 'undrawn_fee_next_12m_per__c','DES_Risk_Fee_Next_12_Months__c'};//Lista TTF SI EL PRODUCTO ES Letter of Credit Y LOS SUBPRODUCTOS SON LC SILENT CONFIRMATION, LC CONFIRMATION, ISSUANCE OF IMPORT LC
    system.debug('>>>>> LETTER OF CREDIT');

    final List<String> listStrTTFProds1 = new List<String>{'TRADE LOANS','FACTORING','FORFAITING','SCF'};
    final List<String> listStrTTFsubProd2 = new List<String>{'TECHNICAL GUARANTEES ISSUANCE','FINANCIAL GUARANTEES ISSUANCE','SILENT GUARANTEES ISSUANCE','SBLC CONFIRMATION'};
    final List<String> listStrTTFsubProd3 = new List<String>{'SILENT GUARANTEES ISSUANCE & FINANCING'};
    final List<String> listStrTTFsubProd4 = new List<String>{'IMPORT LC POST-FINANCING',' LC DISCOUNT', 'LC FORFAITING'};
    final List<String> listStrTTFsubProd5 = new List<String>{'IMPORT LC WITH BENEFICIARY FINANCING', 'LC CONFIRMATION AND DISCOUNT', 'LC CONFIRMATION AND POST-FINANCING'};
    final List<String> listStrTTFsubProd6 = new List<String>{'LC SILENT CONFIRMATION', 'LC CONFIRMATION', 'ISSUANCE OF IMPORT LC'};
    final List<String> listStrPotRev = new List<String>{'pre_oppy_revenue_next_12m_amount__c'};

    //SI SE CAMBIA EL STAGE A CLOSED LOST Y FALTA POR RELLENAR EL CAMPO POTENTIAL REVENUES, MUESTRO EL MENSAJE DE POTENTIAL REVENUES
    if(triggerNewMap.get(oppli.OpportunityId).StageName == Label.DES_Closed_Lose) {
      //COMPRUEBO SI EL CAMPO EMPTYFIELDS TIENE VARIOS CAMPOS
        system.debug('>>>>> oppli.fprd__GBL_Empty_visible_fields__c : ' + oppli.fprd__GBL_Empty_visible_fields__c);
        if(oppli.fprd__GBL_Empty_visible_fields__c.contains(',')) {
          for(String str : oppli.fprd__GBL_Empty_visible_fields__c.split(',')) {
            system.debug('>>>>> str : ' + str);
            system.debug('>>>>> strFlds : ' + strFlds);
            if(strFlds == '') {
              //COMPRUEBO SI EL CAMPO ESTÁ EN LA LISTA DE ESE PRODUCTO
              //TODO: A LA HORA DE SACAR ESTA PARTE A FUNCIONES, HACER UNA PRIMERA FUNCION
              //QUE SE LLAME 'EXCEPCIONESSUBPRODUCT' Y OTRA QUE SEA 'GENERALEXCEPTIONS'
              if(oppli.Product2.Name == Label.DES_Corporate_Loans && listStrCLS.contains(str)) {
                strFlds = oppliFieldMap.get(str).getDescribe().getLabel();
              } else if (oppli.Product2.Name == Label.DES_Leverage_Buyout_LBOs && listStrLBO.contains(str)) {
                strFlds = oppliFieldMap.get(str).getDescribe().getLabel();
              } else if (oppli.Product2.Name == Label.DES_Project_Finance_Lending && listStrPFL.contains(str)) {
                strFlds = oppliFieldMap.get(str).getDescribe().getLabel();
              } else if (oppli.Product2.Name == Label.DES_Debt_Capital_Markets && listStrDCM.contains(str)) {
                strFlds = oppliFieldMap.get(str).getDescribe().getLabel();
              } else if (oppli.Product2.Name == Label.DES_Cash_Management && listStrCASHM.contains(str)) {
                strFlds = oppliFieldMap.get(str).getDescribe().getLabel();
              } else if (oppli.Product2.Name == Label.DES_Project_Finance_Advisory && listStrPFA.contains(str)) {
                strFlds = oppliFieldMap.get(str).getDescribe().getLabel();
              } else if (oppli.Product2.Name == Label.DES_Equity_Capital_Markets && listStrECM.contains(str)) {
                strFlds = oppliFieldMap.get(str).getDescribe().getLabel();
              } else if (oppli.Product2.Name == Label.DES_Mergers_Acquisitions && listStrMA.contains(str)) {
                strFlds = oppliFieldMap.get(str).getDescribe().getLabel();
              } else if (oppli.Product2.Name == Label.DES_Working_Capital && listStrWCNS.contains(str)
              && oppli.solution_name_path_desc__c == '') {
                strFlds = oppliFieldMap.get(str).getDescribe().getLabel();
              } else if (oppli.Product2.Name == Label.DES_Working_Capital && listStrWCCred.contains(str)
              && oppli.solution_name_path_desc__c == 'Credit Accounts') {
                strFlds = oppliFieldMap.get(str).getDescribe().getLabel();
              } else if (oppli.Product2.Name == Label.DES_Working_Capital && listStrWCSnG.contains(str)
              && (oppli.solution_name_path_desc__c == 'Bilateral Loans'
              || oppli.solution_name_path_desc__c == 'SCF - Factoring' || oppli.solution_name_path_desc__c == 'SCF - Reverse Factoring')) {
                strFlds = oppliFieldMap.get(str).getDescribe().getLabel();
              } else if (oppli.Product2.Name == Label.DES_Working_Capital && listStrWCSsG.contains(str)
              && oppli.solution_name_path_desc__c == 'TB Guarantees') {
                strFlds = oppliFieldMap.get(str).getDescribe().getLabel();
              } else if (oppli.Product2.Name == Label.DES_Working_Capital && listStrWCRL.contains(str)
              && (oppli.solution_name_path_desc__c == 'Renting' || oppli.solution_name_path_desc__c == 'Leasing')) {
                strFlds = oppliFieldMap.get(str).getDescribe().getLabel();
              } else if (oppli.Product2.Name == Label.DES_Structure_Trade_Finance && listStrSTFsF.contains(str)
              && oppli.solution_name_path_desc__c == 'FIEM') {
                strFlds = oppliFieldMap.get(str).getDescribe().getLabel();
              } else if (oppli.Product2.Name == Label.DES_Structure_Trade_Finance && listStrSTFsECAG.contains(str)
              && oppli.solution_name_path_desc__c == 'ECA Guarantee') {
                strFlds = oppliFieldMap.get(str).getDescribe().getLabel();
              } else if (oppli.Product2.Name == Label.DES_Structure_Trade_Finance && listStrSTFnE.contains(str)) {
                strFlds = oppliFieldMap.get(str).getDescribe().getLabel();
              } else if (oppli.Product2.Name == Label.DES_Client_Resources && listStrCR.contains(str)) {
                strFlds = oppliFieldMap.get(str).getDescribe().getLabel();
              } else if(oppli.Product2.Name == Label.DES_Transaction_Trade_Finance) {
                //si no tiene producto y es el campo X
                if((oppli.subproduct_name__c == null || oppli.subproduct_name__c == '') && listStrTTFSinProd.contains(str)) {
                  strFlds = oppliFieldMap.get(str).getDescribe().getLabel();
                } else if(listStrTTFProds1.contains(oppli.subproduct_name__c) && listStrTTFs1.contains(str)) {//Si el producto es trade loans
                  strFlds = oppliFieldMap.get(str).getDescribe().getLabel();
                } else if(oppli.subproduct_name__c == 'Guarantees/SBLCs') {
                  if(listStrTTFsubProd2.contains(oppli.solution_name_path_desc__c.toUpperCase()) && listStrTTFs2.contains(str)) {
                    strFlds = oppliFieldMap.get(str).getDescribe().getLabel();
                  } else if(listStrTTFsubProd3.contains(oppli.solution_name_path_desc__c.toUpperCase()) && listStrTTFs3.contains(str)) {
                    strFlds = oppliFieldMap.get(str).getDescribe().getLabel();
                  }
                } else if(oppli.subproduct_name__c == 'Letter of Credit') {
                  if(listStrTTFsubProd4.contains(oppli.solution_name_path_desc__c.toUpperCase()) && listStrTTFs4.contains(str)) {
                    strFlds = oppliFieldMap.get(str).getDescribe().getLabel();
                  } else if(listStrTTFsubProd5.contains(oppli.solution_name_path_desc__c.toUpperCase()) && listStrTTFs5.contains(str)) {
                    strFlds = oppliFieldMap.get(str).getDescribe().getLabel();
                  } else if(listStrTTFsubProd6.contains(oppli.solution_name_path_desc__c.toUpperCase()) && listStrTTFs6.contains(str)) {
                    strFlds = oppliFieldMap.get(str).getDescribe().getLabel();
                  }
                }
              } else if (listStrPotRev.contains(str)) {
                strFlds = oppliFieldMap.get(str).getDescribe().getLabel();
              }
            } else {// ELSE SI strFls no está vacio (por lo que ya tiene algun campo para pedir por mensaje)
              if(oppli.Product2.Name == Label.DES_Corporate_Loans && listStrCLS.contains(str)) {
                strFlds += ', ' + oppliFieldMap.get(str).getDescribe().getLabel();
              } else if (oppli.Product2.Name == Label.DES_Leverage_Buyout_LBOs && listStrLBO.contains(str)) {
                strFlds += ', ' + oppliFieldMap.get(str).getDescribe().getLabel();
              } else if (oppli.Product2.Name == Label.DES_Project_Finance_Lending && listStrPFL.contains(str)) {
                strFlds += ', ' + oppliFieldMap.get(str).getDescribe().getLabel();
              } else if (oppli.Product2.Name == Label.DES_Debt_Capital_Markets && listStrDCM.contains(str)) {
                strFlds += ', ' + oppliFieldMap.get(str).getDescribe().getLabel();
              } else if (oppli.Product2.Name == Label.DES_Cash_Management && listStrCASHM.contains(str)) {
                strFlds += ', ' + oppliFieldMap.get(str).getDescribe().getLabel();
              } else if (oppli.Product2.Name == Label.DES_Project_Finance_Advisory && listStrPFA.contains(str)) {
                strFlds += ', ' + oppliFieldMap.get(str).getDescribe().getLabel();
              } else if (oppli.Product2.Name == Label.DES_Equity_Capital_Markets && listStrECM.contains(str)) {
                strFlds += ', ' + oppliFieldMap.get(str).getDescribe().getLabel();
              } else if (oppli.Product2.Name == Label.DES_Mergers_Acquisitions && listStrMA.contains(str)) {
                strFlds += ', ' + oppliFieldMap.get(str).getDescribe().getLabel();
              } else if (oppli.Product2.Name == Label.DES_Working_Capital && listStrWCNS.contains(str)
              && oppli.solution_name_path_desc__c == '') {
                strFlds += ', ' + oppliFieldMap.get(str).getDescribe().getLabel();
              } else if (oppli.Product2.Name == Label.DES_Working_Capital && listStrWCCred.contains(str)
              && oppli.solution_name_path_desc__c == 'Credit Accounts') {
                strFlds += ', ' + oppliFieldMap.get(str).getDescribe().getLabel();
              } else if (oppli.Product2.Name == Label.DES_Working_Capital && listStrWCSnG.contains(str)
              && (oppli.solution_name_path_desc__c == 'Bilateral Loans'
              || oppli.solution_name_path_desc__c == 'SCF - Factoring' || oppli.solution_name_path_desc__c == 'SCF - Reverse Factoring')) {
                strFlds += ', ' + oppliFieldMap.get(str).getDescribe().getLabel();
              } else if (oppli.Product2.Name == Label.DES_Working_Capital && listStrWCSsG.contains(str)
              && oppli.solution_name_path_desc__c == 'TB Guarantees') {
                strFlds += ', ' + oppliFieldMap.get(str).getDescribe().getLabel();
              } else if (oppli.Product2.Name == Label.DES_Working_Capital && listStrWCRL.contains(str)
              && (oppli.solution_name_path_desc__c == 'Renting' || oppli.solution_name_path_desc__c == 'Leasing')) {
                strFlds = oppliFieldMap.get(str).getDescribe().getLabel();
              } else if (oppli.Product2.Name == Label.DES_Structure_Trade_Finance && listStrSTFsF.contains(str)
              && oppli.solution_name_path_desc__c == 'FIEM') {
                strFlds += ', ' + oppliFieldMap.get(str).getDescribe().getLabel();
              } else if (oppli.Product2.Name == Label.DES_Structure_Trade_Finance && listStrSTFsECAG.contains(str)
              && oppli.solution_name_path_desc__c == 'ECA Guarantee') {
                strFlds += ', ' + oppliFieldMap.get(str).getDescribe().getLabel();
              } else if (oppli.Product2.Name == Label.DES_Structure_Trade_Finance && listStrSTFnE.contains(str)) {
                strFlds += ', ' + oppliFieldMap.get(str).getDescribe().getLabel();
              } else if (oppli.Product2.Name == Label.DES_Client_Resources && listStrCR.contains(str)) {
                strFlds += ', ' + oppliFieldMap.get(str).getDescribe().getLabel();
              } else if(oppli.Product2.Name == Label.DES_Transaction_Trade_Finance) {
                //si no tiene producto y es el campo X
                if((oppli.subproduct_name__c == null || oppli.subproduct_name__c == '') && listStrTTFSinProd.contains(str)) {
                  strFlds += ', ' + oppliFieldMap.get(str).getDescribe().getLabel();
                } else if(listStrTTFProds1.contains(oppli.subproduct_name__c) && listStrTTFs1.contains(str)) {//Si el producto es trade loans
                  strFlds += ', ' + oppliFieldMap.get(str).getDescribe().getLabel();
                } else if(oppli.subproduct_name__c == 'Guarantees/SBLCs') {
                  if(listStrTTFsubProd2.contains(oppli.solution_name_path_desc__c.toUpperCase()) && listStrTTFs2.contains(str)) {
                    strFlds += ', ' + oppliFieldMap.get(str).getDescribe().getLabel();
                  } else if(listStrTTFsubProd3.contains(oppli.solution_name_path_desc__c.toUpperCase()) && listStrTTFs3.contains(str)) {
                    strFlds += ', ' + oppliFieldMap.get(str).getDescribe().getLabel();
                  }
                } else if(oppli.subproduct_name__c == 'Letter of Credit') {
                  if(listStrTTFsubProd4.contains(oppli.solution_name_path_desc__c.toUpperCase()) && listStrTTFs4.contains(str)) {
                    strFlds += ', ' + oppliFieldMap.get(str).getDescribe().getLabel();
                  } else if(listStrTTFsubProd5.contains(oppli.solution_name_path_desc__c.toUpperCase()) && listStrTTFs5.contains(str)) {
                    strFlds += ', ' + oppliFieldMap.get(str).getDescribe().getLabel();
                  } else if(listStrTTFsubProd6.contains(oppli.solution_name_path_desc__c.toUpperCase()) && listStrTTFs6.contains(str)) {
                    strFlds += ', ' + oppliFieldMap.get(str).getDescribe().getLabel();
                  }
                }
              } else if (listStrPotRev.contains(str)) {
                strFlds += ', ' + oppliFieldMap.get(str).getDescribe().getLabel();
              }

            }
          }
        } else {
          if(oppli.Product2.Name == Label.DES_Corporate_Loans && listStrCLS.contains(oppli.fprd__GBL_Empty_visible_fields__c)) {
            strFlds = oppliFieldMap.get(oppli.fprd__GBL_Empty_visible_fields__c).getDescribe().getLabel();
          }

        }
        // SI TIENE VARIOS CAMPOS
          //LOS RECORRO Y, SI COINCIDE CON ALGUNO DE LOS CAMPOS DE LA LISTA, CONCATENO LA LABEL DE ESE CAMPO EN STRFLDS
        // SI SOLO TIENE UN CAMPO
          //COMPRUEBO SI ESTÁ EN LA LISTA DE CAMPOS OBLIGATORIOS Y SI ESTÁ, GUARDO LA LABEL DE ESE CAMPO EN STRFLDS

    } else if(triggerNewMap.get(oppli.OpportunityId).StageName != Label.DES_Closed_Lose) { //SI NO SE CAMBIA EL ESTADO A CLOSED LOST
      if(oppli.fprd__GBL_Empty_visible_fields__c.contains(',')) {
        for(String str : oppli.fprd__GBL_Empty_visible_fields__c.split(',')) {
          if(strFlds == '') {
            strFlds = oppliFieldMap.get(str).getDescribe().getLabel();
          } else {
            strFlds += ', ' + oppliFieldMap.get(str).getDescribe().getLabel();
          }
        }
      } else {
        strFlds = oppliFieldMap.get(oppli.fprd__GBL_Empty_visible_fields__c).getDescribe().getLabel();

      }
    }

    system.debug('>>>>> strFlds : ' + strFlds);

    if(strFlds != '' && strFlds != null) {
      system.debug('>>>>> mapOppliFldsLbl : ' + mapOppliFldsLbl);
      mapOppliFldsLbl.put(oppli.Id, strFlds);
      system.debug('>>>>> mapOppliFldsLbl.get(oppli.Id) : ' + mapOppliFldsLbl.get(oppli.Id));
    }


  }//FIN fillmapOppliFldsLbl





  /*
  * @author Global Desktop  - DSL
  * @Description  - Method que genera el mapa con los mensajes obligatorios para cada oportunidad
  *
  **/
  private void createMapMessage() {
    system.debug('>>>>> 8. ENTRO EN CREATE MAP MESSAGE');
    String message;
    for(Id oppId : mapOppProducts.keySet()) {
      for(OpportunityLineItem oppli : mapOppProducts.get(oppId)) {
        if(mapOppliFldsLbl.get(oppli.Id) != null && mapOppliFldsLbl.get(oppli.Id) != '') {
          message = '';
          if(mapOppProductsMess.get(oppli.OpportunityId) == null) {
            message += 'Product  \'' + oppli.Product2.Name + '\':  ' + mapOppliFldsLbl.get(oppli.Id);
          } else {
            message += mapOppProductsMess.get(oppli.OpportunityId) + ', ' + 'Product  \'' + oppli.Product2.Name + '\':  ' + mapOppliFldsLbl.get(oppli.Id);
          }
          if(message != null && message != '') {
            mapOppProductsMess.put(oppId, message);
          }

        }

      }
    }
  }//FIN createMapMessage


  /*
   *  @author   Global Desktop  - DSL
   *  @Description  - Función que se encarga de validar que al pasar de fase la oportunidad,
   *                  tiene un template creado y bloquea o no el avance de la opp en función de si tiene template o no
   *
  **/
  private void checkNBCConditions(Map<Id, Opportunity> triggerNewMap, OpportunityLineItem oppli) {
      system.debug('>>>>> 3. ENTRO EN CHECK NBC CONDITIONS');
      system.debug('>>>>> configurations: ' + configurations);
      system.debug('>>>>> oppli.Product2.Name: ' + oppli.Product2.Name);
      system.debug('>>>>> mapOppRegion.get(triggerNewMap.get(oppli.OpportunityId).Id): ' + mapOppRegion.get(triggerNewMap.get(oppli.OpportunityId).Id));
      system.debug('>>>>> oppli.Converted_Currency__c: ' + oppli.Converted_Currency__c);
      system.debug('>>>>> Booking_type__c: ' + oppli.product_scope_type__c);
    if(triggerNewMap.get(oppli.OpportunityId).recordTypeId != Schema.SObjectType.Opportunity.getRecordTypeInfosByName().get(Label.DES_RT_Inside_opp).getRecordTypeId()
      && triggerNewMap.get(oppli.OpportunityId).recordTypeId != Schema.SObjectType.Opportunity.getRecordTypeInfosByName().get(Label.DES_RT_Inside_GM_opp).getRecordTypeId()
      && (oppli.opportunity_nbc_recm_ind_type__c == Label.DES_No
      || oppli.opportunity_nbc_recm_ind_type__c == Label.NBC_Decision_Pending
      || oppli.opportunity_nbc_recm_ind_type__c == Label.NBC_Decision_Outdated
			|| (oppli.opportunity_nbc_recm_ind_type__c == 'N.A.'
      && applyTemplate(configurations, oppli.Product2.Name, mapOppRegion.get(triggerNewMap.get(oppli.OpportunityId).Id), oppli.Converted_Currency__c, oppli.product_scope_type__c)))) { //NOSONAR
        system.debug('>>>>> FIN triggerNewMap.get(oppli.OpportunityId) : ' + triggerNewMap.get(oppli.OpportunityId));
        if(triggerNewMap.get(oppli.OpportunityId).StageName == LABEL.DES_Closed_Won) { //NOSONAR
          triggerNewMap.get(oppli.OpportunityId).addError(LABEL.DES_NOT_CLOSE_OPP_NBC_APPROVAL);
        }
    }
  }//FIN checkNBCConditions

  /*
  *   @author Global Desktop
  *
  **/
  private Boolean applyTemplate(List <Template_Configurations__c> configurations, String product, String booking, decimal amount, String cibBec) {
    system.debug('DENTRO APPLY TEMPLATE');
    Boolean apply;
    apply = false;
    if((product == Label.DES_Project_Finance_Lending || product == Label.DES_Leverage_Buyout_LBOs) && cibBec == 'CIB') {
      apply = true;
    } else if(product == Label.DES_Structure_Trade_Finance && cibBec == 'CIB') {
      apply = applyTemplateSTF(configurations, product, amount);
    } else {
      apply = applyTemplateElse(configurations, product, booking, amount, cibBec);
    }
    return apply;
  }//FIN applyTemplate


  /*
  *   @author Global Desktop
  *
  **/
  private Boolean applyTemplateSTF(List <Template_Configurations__c> configurations, String product, decimal amount) {
    Boolean apply;
    apply = false;
    for (Template_Configurations__c config : configurations) {
      if(config.Product_id__r.Name == product
      && checkAmount(config, amount)) {
        apply = true;
      }
    }
    return apply;

  }
  /*
  *   @author Global Desktop
  *
  **/
  private Boolean applyTemplateElse(List <Template_Configurations__c> configurations, String product, String booking, decimal amount, String cibBec) {
    system.debug('>>>>> applyTemplateElse: ');
    Boolean apply;
    apply = false;
    for (Template_Configurations__c config : configurations) {
      if(config.Product_id__r.Name == product && checkBooking(config, booking) && cibBec == 'CIB'
      && checkAmount(config, amount)) {
        apply = true;
      }
    }
    system.debug('>>>>> apply: ' + apply);
    return apply;

  }

  /*
  *   @author Global Desktop
  *
  **/
  private Boolean checkAmount (Template_Configurations__c config, decimal amount) { //NOSONAR
    Boolean applyAmount;
    applyAmount = false;
    if(amount >= config.Amount_num__c) {
      applyAmount = true;
    }
    return applyAmount;
  }//FIN checkAmount

  /*
  *   @author Global Desktop
  *
  **/
  private Boolean checkBooking (Template_Configurations__c config, String booking) { //NOSONAR
    Boolean applyBooking;
    applyBooking = false;
    if(config.Booking_type__c == booking) {
      applyBooking = true;
    }
    return applyBooking;
  }//FIN checkBooking


}//FIN CLASS RelatedProductsValidations