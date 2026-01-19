/*************************************************************************************
   Name:            VisitsByRegionAndProductsYTDcnt
   Description:     Apex controller of RevenuesStageProduct_ReportChart Lightning component

   Version        Date            Author            Summary of changes
   -----------------------------------------------------------------------------------------
   0.1            14/11/2018      Global Desktop    Apex controller of RevenuesStageProduct_ReportChart Lightning component
 *****************************************************************************************/
public with sharing class RevenuesStageProduct_ReportChartCont {//NOSONAR

  /*Declarando variable*/
  private static RevenuesStageProduct_ReportChartCont instance;
  /*SINGLETON PATTERN*/
  public static RevenuesStageProduct_ReportChartCont getInstance() {   //NOSONAR singleton hecho
    if (instance == null) {
      instance = new RevenuesStageProduct_ReportChartCont();
    }
    return instance;
  }

  /*
   * @author Global Desktop
   * @description Recupera la informacion de las oportunidades denormalizadas relacionadas con el cliente
   */
  @AuraEnabled
  public static String getData(String clientId) {
    system.debug('>>>>> FUNCION getData. ID CLIENTE : ' + clientId);
    final date d = system.today().addDays(-366);//NOSONAR
    final Set<Id> setIdOppsDenormClient = new Set<Id>();//NOSONAR
    final list<dwp_acmh__Denorm_Account_Opportunity__c> denOppList = [SELECT dwp_acmh__OpportunityId__c, dwp_acmh__OpportunityId__r.Name FROM dwp_acmh__Denorm_Account_Opportunity__c WHERE dwp_acmh__AccountId__c = :clientId
                                                                                                                                                                                                               AND dwp_acmh__OpportunityId__r.CreatedDate > :d];

    for(dwp_acmh__Denorm_Account_Opportunity__c denOpp : denOppList) {
      if(!setIdOppsDenormClient.contains(denOpp.dwp_acmh__OpportunityId__c)) {
        setIdOppsDenormClient.add(denOpp.dwp_acmh__OpportunityId__c);
      }
    }

    List<OpportunityLineItem> listOppProduct = new List<OpportunityLineItem>();

    listOppProduct = new List<OpportunityLineItem>([
                                                     SELECT DES_Product_Family__c,
                                                     convertCurrency(DES_Potential_Revenue__c),
                                                     convertCurrency(DES_Expected_Revenue__c),
                                                     convertCurrency(pre_oppy_revenue_next_12m_amount__c),
                                                     OpportunityId,
                                                     Opportunity.Name,
                                                     Opportunity.AccountId,
                                                     Opportunity.Account.Name,
                                                     Opportunity.DES_Expected_Probability__c,
                                                     Opportunity.StageName
                                                     FROM OpportunityLineItem
                                                     WHERE ((Opportunity.StageName != : Label.DES_Draft AND OpportunityId IN: setIdOppsDenormClient) /* OR (Opportunity.StageName = :Label.DES_Draft AND Opportunity.OwnerId = :UserInfo.getUserId())*/)
                                                   ]);

    //Mapa que tiene como key el Family Product y como Value el Potential Revenue total de ese producto
    // final Map<String, Double> mapFPPR_Alive = new Map<String, Double>();
    final Map<String, Double> mapFPPR_Draft = new Map<String, Double>();
    Map<String, Double> mapFPPRProposal;
    mapFPPRProposal = new Map<String, Double>();
    final Map<String, Double> mapFPPR_Approval = new Map<String, Double>();
    final Map<String, Double> mapFPPR_ReadyClose = new Map<String, Double>();//NOSONAR
    final Map<String, Double> mapFPPR_Won = new Map<String, Double>();
    Map<String, Double> mapFPPRLost;
    mapFPPRLost = new Map<String, Double>();
    Map<String, Map<String, Double> > mapStage = new Map<String, Map<String, Double> >();

    final List<String> listFamProd = getFamilyValuesIntoList();
    mapFPPR(listFamProd,mapFPPR_Draft,mapFPPRProposal,mapFPPR_Approval,mapFPPR_ReadyClose,mapFPPR_Won,mapFPPRLost);

    if(!listOppProduct.isEmpty()) {
      final list<OpportunityLineItem> listOppProductOrder = OppProductOrder(listOppProduct);//NOSONAR

      for(OpportunityLineItem opli : listOppProductOrder) {
        //if(opli.pre_oppy_revenue_next_12m_amount__c != null && opli.Opportunity.DES_Expected_Probability__c != null) {
        if(opli.DES_Expected_Revenue__c != null) {
          mapStage = ifProposal(opli, mapFPPRProposal, mapStage, Label.DES_Proposal);
          mapStage = ifProposal(opli, mapFPPR_Approval, mapStage, Label.DES_Approvals);
          mapStage = ifProposal(opli, mapFPPR_ReadyClose, mapStage, Label.DES_Ready_to_close);
          mapStage = ifClose(opli, mapFPPRLost, mapStage, Label.DES_Closed_Lose, Label.DES_Lost);
          mapStage = ifClose(opli, mapFPPR_Won, mapStage, Label.DES_Closed_Won, Label.DES_Won);
        }
        system.debug('>>>>> opli.Opportunity.Name : ' + opli.Opportunity.Name);
      }
    }

    system.debug('>>>>> mapStage ANTES RELLENAR TODAS LAS FAMILIAS: ' + mapStage);

    return JSON.serialize(mapStage);
  }

  /*
   * Aux Method1
   */
  private static Map<String, Map<String, Double> > ifProposal(OpportunityLineItem opli, Map<String, Double> mapFPPRProposal, Map<String, Map<String, Double> > mapStage, String stage) {
    final Map<String, Map<String, Double> > mapAux = mapStage;
    if(opli.Opportunity.StageName == stage) {
      if(mapFPPRProposal.get(opli.DES_Product_Family__c) == null) {
        mapFPPRProposal.put(opli.DES_Product_Family__c, opli.DES_Expected_Revenue__c);
        mapAux.put(opli.Opportunity.StageName, mapFPPRProposal);
      } else {
        mapFPPRProposal.put(opli.DES_Product_Family__c, mapFPPRProposal.get(opli.DES_Product_Family__c) + opli.DES_Expected_Revenue__c);
        mapAux.put(opli.Opportunity.StageName, mapFPPRProposal);
      }
    }
    return mapAux;
  }


  /*
   * Aux Method2
   */
  private static Map<String, Map<String, Double> > ifClose(OpportunityLineItem opli, Map<String, Double> mapFPPRLost, Map<String, Map<String, Double> > mapStage, String stage1, String stage2) {
    final Map<String, Map<String, Double> > mapAux = mapStage;
    if((opli.Opportunity.StageName == stage1 || opli.Opportunity.StageName == stage2) && opli.pre_oppy_revenue_next_12m_amount__c != null) {
      opli.Opportunity.StageName = stage2;
      if(mapFPPRLost.get(opli.DES_Product_Family__c) == null) {
        mapFPPRLost.put(opli.DES_Product_Family__c, opli.pre_oppy_revenue_next_12m_amount__c);
        mapStage.put(opli.Opportunity.StageName, mapFPPRLost);
      } else {
        mapFPPRLost.put(opli.DES_Product_Family__c, mapFPPRLost.get(opli.DES_Product_Family__c) + opli.pre_oppy_revenue_next_12m_amount__c);
        mapStage.put(opli.Opportunity.StageName, mapFPPRLost);
      }
    }
    return mapAux;
  }
  /*
   * Aux Method3
   */
  public static void mapFPPR(List<String> listFamProd,Map<String, Double> mapFPPR_Draft,Map<String, Double> mapFPPRProposal,Map<String, Double> mapFPPR_Approval,Map<String, Double> mapFPPR_ReadyClose, Map<String, Double> mapFPPR_Won,Map<String, Double> mapFPPRLost){//NOSONAR
    for(String fpr : listFamProd) {
      if(mapFPPR_Draft.get(fpr) == null) {
        mapFPPR_Draft.put(fpr,0);
      }
      if(mapFPPRProposal.get(fpr) == null) {
        mapFPPRProposal.put(fpr,0);
      }
      if(mapFPPR_Approval.get(fpr) == null) {
        mapFPPR_Approval.put(fpr,0);
      }
      if(mapFPPR_ReadyClose.get(fpr) == null) {
        mapFPPR_ReadyClose.put(fpr,0);
      }
      if(mapFPPR_Won.get(fpr) == null) {
        mapFPPR_Won.put(fpr,0);
      }
      if(mapFPPRLost.get(fpr) == null) {
        mapFPPRLost.put(fpr,0);
      }
    }
  }

  /*
   * Aux Method4
   */
  public static list<OpportunityLineItem> OppProductOrder(List<OpportunityLineItem> listOppProduct) {
    final list<OpportunityLineItem> oppLineProposal = new list<OpportunityLineItem>();
      final list<OpportunityLineItem> oppLineApproval = new list<OpportunityLineItem>();
      final list<OpportunityLineItem> oppLineReadyClose = new list<OpportunityLineItem>();
      final list<OpportunityLineItem> oppLineWon = new list<OpportunityLineItem>();
      final list<OpportunityLineItem> oppLineLose = new list<OpportunityLineItem>();
      final list<OpportunityLineItem> listOppProductOrder = new list<OpportunityLineItem>();//NOSONAR
      for(OpportunityLineItem i : listOppProduct) {
        if(i.Opportunity.StageName == Label.DES_Proposal) {
          oppLineProposal.add(i);
        } else if(i.Opportunity.StageName == Label.DES_Approvals) {
          oppLineApproval.add(i);
        } else if(i.Opportunity.StageName == Label.DES_Ready_to_close) {
          oppLineReadyClose.add(i);
        } else if(i.Opportunity.StageName == Label.DES_Closed_Lose || i.Opportunity.StageName == Label.DES_Lost) {
          oppLineWon.add(i);
        } else if(i.Opportunity.StageName == Label.DES_Closed_Won || i.Opportunity.StageName == Label.DES_Won) {
          oppLineLose.add(i);
        }
      }
      listOppProductOrder.addAll(oppLineLose);
      listOppProductOrder.addAll(oppLineWon);
      listOppProductOrder.addAll(oppLineReadyClose);
      listOppProductOrder.addAll(oppLineApproval);
      listOppProductOrder.addAll(oppLineProposal);
      return listOppProductOrder;
  }


  /*
   * @author Global Desktop
   * @description Recupera los productos de las oportunidades relacionadas con el cliente
   */
  @AuraEnabled
  public static String getOppProducts(String clientId) {
    system.debug('>>>>> clientId: ' + clientId);
    final date d = system.today().addDays(-366);//NOSONAR
    final Set<Id> setIdOppsDenormClient = new Set<Id>();//NOSONAR
    for(dwp_acmh__Denorm_Account_Opportunity__c denOpp : [SELECT dwp_acmh__OpportunityId__c FROM dwp_acmh__Denorm_Account_Opportunity__c WHERE dwp_acmh__AccountId__c = :clientId]) {
      if(!setIdOppsDenormClient.contains(denOpp.dwp_acmh__OpportunityId__c)) {
        setIdOppsDenormClient.add(denOpp.dwp_acmh__OpportunityId__c);
      }
    }

    final List<OpportunityLineItem> listOppProduct = new List<OpportunityLineItem>([
                                                                               SELECT DES_Product_Family__c,
                                                                               convertCurrency(DES_Potential_Revenue__c),
                                                                               convertCurrency(DES_Expected_Revenue__c),
                                                                               convertCurrency(pre_oppy_revenue_next_12m_amount__c),
                                                                               Product2Id,
                                                                               Product2.Name,
                                                                               OpportunityId,
                                                                               Opportunity.Name,
                                                                               Opportunity.AccountId,
                                                                               Opportunity.Account.Name,
                                                                               Opportunity.DES_Expected_Probability__c,
                                                                               Opportunity.StageName,
                                                                               Opportunity.CreatedDate,
                                                                               Opportunity.CloseDate
                                                                               FROM OpportunityLineItem
                                                                               WHERE CreatedDate > : d
                                                                               AND ((Opportunity.StageName != : Label.DES_Draft AND OpportunityId IN: setIdOppsDenormClient) /* OR (Opportunity.StageName = :Label.DES_Draft AND Opportunity.OwnerId = :UserInfo.getUserId())*/)
                                                                             ]);

    system.debug('>>>>> listOppProduct : ' + listOppProduct);
    final List<WrapperClass> listWrapper = new List<WrapperClass>();
    for(OpportunityLineItem opli : listOppProduct) {
      system.debug('>>>>> POT.REVENUES: ' + opli.pre_oppy_revenue_next_12m_amount__c);
      listWrapper.add(new WrapperClass(opli.Opportunity, opli.Opportunity.Name, opli.Product2, opli.Product2.Name, opli.DES_Product_Family__c, opli.pre_oppy_revenue_next_12m_amount__c, opli.DES_Expected_Revenue__c));
    }

    system.debug('>>>>>listWrapper : ' + listWrapper);
    return JSON.serialize(listWrapper);
  }  //FIN getOppProduct


  /*
   * @author Global Desktop
   * @description Recupera los valores de la picklist de Family del objeto Product
   */
  private static List<String> getFamilyValuesIntoList() {//NOSONAR
    final List<String> pickListValuesList= new List<String>();//NOSONAR
    final Schema.DescribeFieldResult fieldResult = Product2.Family.getDescribe();
    final List<Schema.PicklistEntry> ple = fieldResult.getPicklistValues();
    system.debug('>>>>> ple: ' + ple);
    for( Schema.PicklistEntry pickListVal : ple) {
      pickListValuesList.add(pickListVal.getLabel());
    }
    system.debug('>>>>> pickListValuesList: ' + pickListValuesList);
    return pickListValuesList;
  }  //getFamilyValuesIntoList


  /*
   * @author Global Desktop
   * @description Recupera el Iso code del usuario logado
   */
  @AuraEnabled
  public static String getCurrentUserISOCode() {//NOSONAR
    return UserInfo.getDefaultCurrency();
  }

  /*
   * @author Global Desktop
   * @description Construye la lista wrapper con los datos que se devolveran al componente lightning
   */
  public class WrapperClass {
    /**
     * @uthor Global Desktop
     * @description Declaracion de variables para lista wrapper
     */
     /*
      * oppName para crear el oppName
      */
    final private String oppName;//NOSONAR
    /*
      * prodName para crear el prodName
      */
    final private String prodName;//NOSONAR
    /*
      * prodFam para crear el prodFam
      */
    final private String prodFam;//NOSONAR
    /*
      * expRevenue para crear el expRevenue
      */
    final private Decimal expRevenue;//NOSONAR
    /*
      * potRevenue para crear el potRevenue
      */
    final private Decimal potRevenue;//NOSONAR
    /*
      * urlOpp para crear el urlOpp
      */
    final private String urlOpp;//NOSONAR
    /*
      * urlAccount para crear el urlAccount
      */
    final private String urlAccount;//NOSONAR
    /*
      * urlProduct para crear el urlProduct
      */
    final private String urlProduct;//NOSONAR
    /*
      * oppAccountName para crear el oppAccountName
      */
    final private String oppAccountName;//NOSONAR
    /*
      * stageName para crear el stageName
      */
    final private String stageName;//NOSONAR
    /*
      * closeDate para crear el closeDate
      */
    final private Date closeDate;//NOSONAR
    /*
      * createdDate para crear el createdDate
      */
    final private DateTime createdDate;//NOSONAR

    /**
     * @uthor Global Desktop
     * #description Clase que construye la lista wrapper
     */
    public WrapperClass(Opportunity opp,String oppName,Product2 product,String prodName,String prodFam,Decimal potRevenue, Decimal expRevenue) {
      this.urlOpp = '/lightning/r/Opportunity/' + opp.Id + '/view';
      this.urlAccount = '/lightning/r/Account/' + opp.AccountId + '/view';
      this.urlProduct = '/lightning/r/Product2/' + product.Id + '/view';
      this.oppName = oppName;
      this.oppAccountName = opp.Account.Name;
      this.prodName = prodName;
      this.prodFam = prodFam;
      /*if(opp.DES_Expected_Probability__c != null && expRevenuePercent != null) {
         this.expRevenue = expRevenuePercent * opp.DES_Expected_Probability__c/100;
         } else {
         this.expRevenue = 0;
         }*/
      this.potRevenue = potRevenue;
      this.expRevenue = expRevenue;
      this.stageName = opp.StageName;
      this.CloseDate = opp.CloseDate;
      this.createdDate = opp.CreatedDate;
    }
  }
}