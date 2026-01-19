/**
* @author Global Desktop
* @description Controlador del componente lightning PotRevenuesByRegionProduct
*/
public with sharing class PotRevenuesByRegionProductCnt {//NOSONAR

    private static PotRevenuesByRegionProductCnt instance;
    
  /*Constructor de la clase*/
  public PotRevenuesByRegionProductCnt() {
    system.debug('Constructor PotRevenuesByRegionProductCnt');
  }

  /*Instancia de la clase*/
  public static PotRevenuesByRegionProductCnt getInstance() {       //NOSONAR
    if (instance == null) {
      instance = new PotRevenuesByRegionProductCnt();
    }
    return instance;
  }
    /*
    * @author Global Desktop
    * @description Se recogen los datos de las oportunidades denormalizadas relacionadas con el cliente
    */
    @AuraEnabled
    public static String getData(String clientId) {
        try {
		    final Set<Id> setIdOpps = new Set<Id>();
		    for(dwp_acmh__Denorm_Account_Opportunity__c denOpp : [SELECT dwp_acmh__OpportunityId__c FROM dwp_acmh__Denorm_Account_Opportunity__c WHERE dwp_acmh__AccountId__c = :clientId]) {
		  		if(!setIdOpps.contains(denOpp.dwp_acmh__OpportunityId__c)) {
		        	setIdOpps.add(denOpp.dwp_acmh__OpportunityId__c);
		  		}
	    	}

    		system.debug('>>>>> setIdOpps : ' + setIdOpps);
        //Rec0j0 todos los 0pportunity Pr0ducts que pertenezcan a alguna 0p0rtunidad de la cu3nta de la t4bla Desn0rmalizada
        final List<OpportunityLineItem> listOppProduct = new List<OpportunityLineItem>([
                                     SELECT DES_Product_Family__c,
                                            Opportunity.region_name__c,
                                            toLabel(Opportunity.DES_Booking_Geography__c),
                                            convertCurrency(pre_oppy_revenue_next_12m_amount__c),
            								convertCurrency(DES_Expected_Revenue__c),
                                            OpportunityId,
                                            Opportunity.Name,
                                            Opportunity.AccountId,
                                            Opportunity.Account.Name,
                                            Opportunity.DES_Expected_Probability__c,
                                            Opportunity.StageName
                                       FROM OpportunityLineItem
                                      WHERE (Opportunity.StageName != :Label.DES_Draft AND OpportunityId IN :setIdOpps)
            ]);
        system.debug('>>>>> listOppProduct : ' + listOppProduct);
        // Mapa que tiene como key el País y como value el mapa mapFPPR para el país
        Final Map<String, Map<String, Double>> mapPais = new Map<String, Map<String, Double>>();
        //Mapa que tiene como key la Familia y como value el color
        Map<String, String> mapFamCol = new Map<String, String>();
        Final Set<String> setFams = new Set<String>();

        if(!listOppProduct.isEmpty()) {
           for(OpportunityLineItem opli : listOppProduct) {
                //Si tiene informado el potential revenue
                if(opli.DES_Expected_Revenue__c != null) {
                  mapGeoFamilyExpReve(opli,mapPais);
                }
          		setFams.add(opli.DES_Product_Family__c);
       		}
        }//FIN !listOppProduct.isEmpty()

        mapFamCol = getFamilyColor(setFams);
	    final WrapperGlobalData wrapperGlobal = new WrapperGlobalData(mapFamCol, mapPais);
	    return JSON.serialize(wrapperGlobal);
        } catch(Exception exc) {
			throw new AuraHandledException(Label.DES_Error + exc);
		}
    }

    /*
    * @author Global Desktop
    * @description Se construye el mapa que mostraria la geografia junto el Product Family y los Expected Revenue
    */
    public static void mapGeoFamilyExpReve(OpportunityLineItem opli,Map<String, Map<String, Double>> mapPais) {
        //Mapa que tiene como key la Famlia y como value el Potencial revenue asociado
        final Map<String, Double> mapFPPR;//NOSONAR
        if(opli.Opportunity.DES_Booking_Geography__c != null && opli.DES_Product_Family__c!=null) {
        	System.debug('opli = '+opli);
            if(mapPais.get(opli.Opportunity.DES_Booking_Geography__c) == null) {
            	mapFPPR = new Map<String, Double>();
                mapFPPR.put(opli.DES_Product_Family__c,  opli.DES_Expected_Revenue__c);
                mapPais.put(opli.Opportunity.DES_Booking_Geography__c, mapFPPR);
            } else {
                if (mapPais.get(opli.Opportunity.DES_Booking_Geography__c).get(opli.DES_Product_Family__c) == null) {
                	mapFPPR = mapPais.get(opli.Opportunity.DES_Booking_Geography__c);
                    mapFPPR.put(opli.DES_Product_Family__c,  opli.DES_Expected_Revenue__c);
                    mapPais.put(opli.Opportunity.DES_Booking_Geography__c, mapFPPR);
                } else {
                    mapFPPR = mapPais.get(opli.Opportunity.DES_Booking_Geography__c);
                    final Double revTot = mapPais.get(opli.Opportunity.DES_Booking_Geography__c).get(opli.DES_Product_Family__c) + opli.DES_Expected_Revenue__c;
                    mapFPPR.put(opli.DES_Product_Family__c, revTot);
                    mapPais.put(opli.Opportunity.DES_Booking_Geography__c, mapFPPR);
                }
           }
    	}
    }
    /*
    * @author Global Desktop
    * @description Recoge los valores del metadato Product Family
    */
    public static Map<String, String> getFamilyColor(Set<String> setFamilyData) {

        final Map<String, String> mapFamColor = new Map<String, String>();
        final List<Product_Family__mdt> listFamColor = [select DeveloperName,  Color__c from Product_Family__mdt where DeveloperName IN :setFamilyData];
        system.debug('listFamColor: ' + listFamColor);

        if(!listFamColor.isEmpty()) {
        	for(Product_Family__mdt fam : listFamColor) {
        		if(fam.DeveloperName != null && fam.Color__c != null && mapFamColor.get(fam.DeveloperName) == null) {
                	mapFamColor.put(fam.DeveloperName, fam.Color__c);
                }
           	}
        }
        return mapFamColor;
    }

    /*
    * @author Global Desktop
    * @description Construye la wrapper list que se devolvera al componente lightning
    */
    public class WrapperGlobalData {
        /*
        * mapFamCol para crear el mapFamCol
        */
        final private Map<String, String> mapFamCol;
        /*
        * mapData para crear el mapData
        */
        final private Map<String, Map<String, Double>> mapData;
         /*
        * construct0r
        */
        public WrapperGlobalData (Map<String, String> fams, Map<String, Map<String, Double>> data) {
            this.mapFamCol = fams;
            this.mapData = data;
        }
        /*
        * Met0d0 que mapFamCol
        */
        public Map<String, String> getMapFamCol() {
          return mapFamCol;
        }
        /*
        * Met0d0 que mapFamCol
        */
        public Map<String, Map<String, Double>> getMapData() {
          return mapData;
        }
    }


	/*
    * @author Global Desktop
    * @description Recoge los datos de los productos de las oportunidades relacionadas con el cliente
    */
    @AuraEnabled
    public static String getOppProducts(String clientId) {
        system.debug('>>>>> clientId: ' + clientId);
        final date lastyear = system.today().addDays(-366);
        final Set<Id> setIdOpps = new Set<Id>();
    	for(dwp_acmh__Denorm_Account_Opportunity__c denOpp : [SELECT dwp_acmh__OpportunityId__c FROM dwp_acmh__Denorm_Account_Opportunity__c WHERE dwp_acmh__AccountId__c = :clientId]) {
      		if(!setIdOpps.contains(denOpp.dwp_acmh__OpportunityId__c)) {
        		setIdOpps.add(denOpp.dwp_acmh__OpportunityId__c);
      		}
    	}
        //Rec0j0 todos los 0pportunity Pr0ducts que pertenezcan a alguna 0p0rtunidad de la cu3nta de la t4bla Desn0rmalizada
        final List<OpportunityLineItem> listOppProduct = new List<OpportunityLineItem>([
                                    SELECT  DES_Product_Family__c,
                                            convertCurrency(pre_oppy_revenue_next_12m_amount__c),
            								convertCurrency(DES_Expected_Revenue__c),
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
                                      WHERE CreatedDate > :lastyear
                                        AND ((Opportunity.StageName != :Label.DES_Draft AND OpportunityId IN :setIdOpps) )
            ]);

        final List<WrapperClass> listWrapper = new List<WrapperClass>();
        for(OpportunityLineItem opli : listOppProduct) {
            listWrapper.add(new WrapperClass(opli.Opportunity, opli.Opportunity.Name, opli.Product2, opli.Product2.Name, opli.DES_Product_Family__c, opli.pre_oppy_revenue_next_12m_amount__c, opli.DES_Expected_Revenue__c));
        }

        return JSON.serialize(listWrapper);
    }//FIN getOppProduct

	/*
    * @author Global Desktop
    * @description Recoge el Iso code del usuario logado
    */
    @AuraEnabled
    public static String getCurrentUserISOCode() {
        return UserInfo.getDefaultCurrency();
    }


	/*
    * @author Global Desktop
    * @description Construye la wrapper list que se devuelve al componente lightning
    */
    public class WrapperClass {
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
      * potRevenue para crear el potRevenue
      */
      final private Decimal potRevenue;//NOSONAR
        /*
      * expRevenue para crear el expRevenue
      */
      final private Decimal expRevenue;//NOSONAR
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
      final private String stageName;
        /*
      * closeDate para crear el closeDate
      */
      final private Date closeDate;
        /*
      * createdDate para crear el createdDate
      */
      final private DateTime createdDate;
	/*
    * Met0d0 para crear el wrapp
    */
      public WrapperClass(Opportunity opp, String oppName, Product2 product, String prodName, String prodFam, Decimal potRevenue, Decimal expRevenue) {
        this.urlOpp = '/lightning/r/Opportunity/' + opp.Id + '/view';
        this.urlAccount = '/lightning/r/Account/' + opp.AccountId + '/view';
        this.urlProduct = '/lightning/r/Product2/' + product.Id + '/view';
        this.oppName = oppName;
        this.oppAccountName = opp.Account.Name;
        this.prodName = prodName;
        this.prodFam = prodFam;
        /*if(opp.DES_Expected_Probability__c != null && expRevenuePercent != null){
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