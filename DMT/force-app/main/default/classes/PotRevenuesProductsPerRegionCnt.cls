public with sharing class PotRevenuesProductsPerRegionCnt {

    @AuraEnabled
    public static String getData(String clientId, String family){
    	try{
    		System.debug(':::::getData init en familia: ' + family);
	        //date d = System.today().addDays(-366);
	        Set<Id> setIdOppsDenormClient = new Set<Id>();
		    for(dwp_acmh__Denorm_Account_Opportunity__c denOpp : [SELECT dwp_acmh__OpportunityId__c FROM dwp_acmh__Denorm_Account_Opportunity__c WHERE dwp_acmh__AccountId__c = :clientId]){
		      if(!setIdOppsDenormClient.contains(denOpp.dwp_acmh__OpportunityId__c)){
		        setIdOppsDenormClient.add(denOpp.dwp_acmh__OpportunityId__c);
		      }
		    }
	    	System.debug('::::::setIdOppsDenormClient : ' + setIdOppsDenormClient);
	        //Recojo todos los Opportunity Products que pertenezcan a alguna oportunidad de la cuenta de la tabla Desnormalizada
	        List<OpportunityLineItem> listOppProduct = new List<OpportunityLineItem>([
	                                    SELECT  DES_Product_Family__c, 
	                                    		Opportunity.region_name__c,
	                                    		Product2.name,
	                                            convertCurrency(pre_oppy_revenue_next_12m_amount__c),
	                                            //pre_oppy_revenue_next_12m_amount__c,
	                                            OpportunityId,
	                                            Opportunity.Name,
	                                            Opportunity.AccountId,
	                                            Opportunity.Account.Name,
	                                            Opportunity.DES_Expected_Probability__c,
	                                            Opportunity.StageName
	                                    FROM OpportunityLineItem
	                                    WHERE  ((Opportunity.StageName != :Label.DES_Draft 
	                                    		//AND Opportunity.AccountId = :clientId
	                                    		AND OpportunityId IN :setIdOppsDenormClient
	                                    		AND DES_Product_Family__c = :family
	                                    		))
	            						]);

	        System.debug('::::::listOppProduct : ' + listOppProduct);

	        //Mapa que tiene como key el Product.name y como Value el Potential Revenue total de ese producto
	        Map<String, Double> mapPRRE_Amesur = new Map<String, Double>();
	        Map<String, Double> mapPRRE_Asia = new Map<String, Double>();
	        Map<String, Double> mapPRRE_EEUU = new Map<String, Double>();
	        Map<String, Double> mapPRRE_Spain = new Map<String, Double>();
	        Map<String, Double> mapPRRE_Mexico = new Map<String, Double>();
	        Map<String, Double> mapPRRE_Europe = new Map<String, Double>();
	        Map<String, Double> mapFPPR_Latam = new Map<String, Double>();
	        //Mapa que tiene como key el Stage y como Value el mapa mapFPPR
	        Map<String, Map<String, Double>> mapStage = new Map<String, Map<String, Double>>();

	        List<String> lstProdNames = new List<String>();
	        for(OpportunityLineItem oppLineItem : listOppProduct){	
	        	if(!lstProdNames.contains(oppLineItem.Product2.Name)){
		        	lstProdNames.add(oppLineItem.Product2.Name);
		     	}
	        }
	        System.debug('::::::lstProdNames : ' + lstProdNames);

	        //List<String> listFamProd = getFamilyValuesIntoList();
	        //System.debug('::::::listFamProd : ' + listFamProd);
	        
	        for(String prod : lstProdNames){
	            //recorro todo el mapa, para las familia de producto que no tengan datos (que sean null) las pongo a 0
	            if(mapPRRE_Amesur.get(prod) == null){
	                mapPRRE_Amesur.put(prod,0);
	            }
	            if(mapPRRE_Asia.get(prod) == null){
	                mapPRRE_Asia.put(prod,0);
	            }
	            if(mapPRRE_EEUU.get(prod) == null){
	                mapPRRE_EEUU.put(prod,0);
	            }
	            if(mapPRRE_Spain.get(prod) == null){
	                mapPRRE_Spain.put(prod,0);
	            }
	            if(mapPRRE_Mexico.get(prod) == null){
	                mapPRRE_Mexico.put(prod,0);
	            }
	            if(mapPRRE_Europe.get(prod) == null){
	                mapPRRE_Europe.put(prod,0);
	            }
	            if(mapFPPR_Latam.get(prod) == null){
	                mapFPPR_Latam.put(prod,0);
	            }
	        }
           
	        //Si la lista no está vacia
	        if(!listOppProduct.isEmpty()){
	            for(OpportunityLineItem opli : listOppProduct){
	                if(opli.pre_oppy_revenue_next_12m_amount__c != null){
	                    if(opli.Opportunity.region_name__c == Label.RegionAmesur){
	                    	if(mapPRRE_Amesur.get(opli.Product2.Name) == null){
	                            //Le pongo el valor del Potential Revenue a la key que tenga ese Product Family
	                            mapPRRE_Amesur.put(opli.Product2.Name, opli.pre_oppy_revenue_next_12m_amount__c);
	                            mapStage.put(opli.Opportunity.region_name__c, mapPRRE_Amesur);
	                        }else{
	                            //Si ya tiene valor, le sumo el potential revenue a ese mismo valor
	                            mapPRRE_Amesur.put(opli.Product2.Name, mapPRRE_Amesur.get(opli.Product2.Name) + ((opli.pre_oppy_revenue_next_12m_amount__c)));
	                            mapStage.put(opli.Opportunity.region_name__c, mapPRRE_Amesur);
	                        }
	                    }else if(opli.Opportunity.region_name__c == Label.RegionAsia){
	                    	//System.debug('::::::Cash Management : ' + opli.Product2.Name + ' - ' + opli.pre_oppy_revenue_next_12m_amount__c);
	                      	if(mapPRRE_Asia.get(opli.Product2.Name) == null){
	                            mapPRRE_Asia.put(opli.Product2.Name, opli.pre_oppy_revenue_next_12m_amount__c);
	                            mapStage.put(opli.Opportunity.region_name__c, mapPRRE_Asia);
	                        }else{
	                            mapPRRE_Asia.put(opli.Product2.Name, mapPRRE_Asia.get(opli.Product2.Name) + ((opli.pre_oppy_revenue_next_12m_amount__c)));
	                            mapStage.put(opli.Opportunity.region_name__c, mapPRRE_Asia);
	                        }
	                        //System.debug('::::::Cash Management 2 : ' + mapStage + ' - ' + mapPRRE_Asia);
	                    }else if(opli.Opportunity.region_name__c == Label.RegionEEUU){
	                      	if(mapPRRE_EEUU.get(opli.Product2.Name) == null){
	                            mapPRRE_EEUU.put(opli.Product2.Name, opli.pre_oppy_revenue_next_12m_amount__c);
	                            mapStage.put(opli.Opportunity.region_name__c, mapPRRE_EEUU);
	                        }else{
	                            mapPRRE_EEUU.put(opli.Product2.Name, mapPRRE_EEUU.get(opli.Product2.Name) + ((opli.pre_oppy_revenue_next_12m_amount__c)));
	                            mapStage.put(opli.Opportunity.region_name__c, mapPRRE_EEUU);
	                        }
	                    }else if(opli.Opportunity.region_name__c == Label.RegionSpain){
	                      	if(mapPRRE_Spain.get(opli.Product2.Name) == null){
		                        mapPRRE_Spain.put(opli.Product2.Name, opli.pre_oppy_revenue_next_12m_amount__c);
		                        mapStage.put(opli.Opportunity.region_name__c, mapPRRE_Spain);
		                    }else{
		                        mapPRRE_Spain.put(opli.Product2.Name, mapPRRE_Spain.get(opli.Product2.Name) + ((opli.pre_oppy_revenue_next_12m_amount__c)));
		                        mapStage.put(opli.Opportunity.region_name__c, mapPRRE_Spain);
	                      	}
	                    }else if(opli.Opportunity.region_name__c == Label.RegionMexico){
	                      	if(mapPRRE_Mexico.get(opli.Product2.Name) == null){
	                            mapPRRE_Mexico.put(opli.Product2.Name, opli.pre_oppy_revenue_next_12m_amount__c);
	                            mapStage.put(opli.Opportunity.region_name__c, mapPRRE_Mexico);
	                        }else{
	                            mapPRRE_Mexico.put(opli.Product2.Name, mapPRRE_Mexico.get(opli.Product2.Name) + ((opli.pre_oppy_revenue_next_12m_amount__c)));
	                            mapStage.put(opli.Opportunity.region_name__c, mapPRRE_Mexico);
	                        }
	                    }else if(opli.Opportunity.region_name__c == Label.RegionEuropa){
	                      	if(mapPRRE_Europe.get(opli.Product2.Name) == null){
	                            mapPRRE_Europe.put(opli.Product2.Name, opli.pre_oppy_revenue_next_12m_amount__c);
	                            mapStage.put(opli.Opportunity.region_name__c, mapPRRE_Europe);
	                        }else{
	                            mapPRRE_Europe.put(opli.Product2.Name, mapPRRE_Europe.get(opli.Product2.Name) + ((opli.pre_oppy_revenue_next_12m_amount__c)));
	                            mapStage.put(opli.Opportunity.region_name__c, mapPRRE_Europe);
	                        }
	                    }else if(opli.Opportunity.region_name__c == Label.RegionRestoLatam){
	                      	if(mapFPPR_Latam.get(opli.Product2.Name) == null){
	                            mapFPPR_Latam.put(opli.Product2.Name, opli.pre_oppy_revenue_next_12m_amount__c);
	                            mapStage.put(opli.Opportunity.region_name__c, mapFPPR_Latam);
	                        }else{
	                            mapFPPR_Latam.put(opli.Product2.Name, mapFPPR_Latam.get(opli.Product2.Name) + ((opli.pre_oppy_revenue_next_12m_amount__c)));
	                            mapStage.put(opli.Opportunity.region_name__c, mapFPPR_Latam);
	                        }
	                    }
	                }
	                System.debug('::::::opli.Opportunity.Name : ' + opli.Opportunity.Name);
	                System.debug('::::::opli.Product2.Name : ' + opli.Product2.Name);
	            }
	        }

	        System.debug('::::::mapStage: ' + JSON.serialize(mapStage));
	        return JSON.serialize(mapStage);
    	}catch (Exception e) {
            throw new AuraHandledException('Error en PotRevenuesProductsPerRegionCnt.getData ' + e);
        }
    }


    @AuraEnabled
    public static String getOppProducts(String clientId, String family){ //antes getOppProducts
        System.debug('::::::getOppProducts init');
        System.debug('::::::clientId: ' + clientId);
        date d = System.today().addDays(-366);
        Set<Id> setIdOppsDenormClient = new Set<Id>();
    for(dwp_acmh__Denorm_Account_Opportunity__c denOpp : [SELECT dwp_acmh__OpportunityId__c FROM dwp_acmh__Denorm_Account_Opportunity__c WHERE dwp_acmh__AccountId__c = :clientId]){
      if(!setIdOppsDenormClient.contains(denOpp.dwp_acmh__OpportunityId__c)){
        setIdOppsDenormClient.add(denOpp.dwp_acmh__OpportunityId__c);
      }
    }
        //Recojo todos los Opportunity Products que pertenezcan a alguna oportunidad de la cuenta de la tabla Desnormalizada
        List<OpportunityLineItem> listOppProduct = new List<OpportunityLineItem>([
                                    SELECT  DES_Product_Family__c,
                                            convertCurrency(pre_oppy_revenue_next_12m_amount__c),
                                            //pre_oppy_revenue_next_12m_amount__c,
                                            Product2Id,
                                            Product2.Name,
                                            Opportunity.region_name__c,
                                            OpportunityId,
                                            Opportunity.Name,
                                            Opportunity.AccountId,
                                            Opportunity.Account.Name,
                                            Opportunity.DES_Expected_Probability__c,
                                            Opportunity.StageName,
                                            Opportunity.CreatedDate,
                                            Opportunity.CloseDate
                                    FROM OpportunityLineItem			
                                    WHERE CreatedDate > :d
                                    		//AND Opportunity.AccountId = :clientId
	                                    	AND DES_Product_Family__c = :family
                                            AND ((Opportunity.StageName != :Label.DES_Draft 
                                            AND OpportunityId IN :setIdOppsDenormClient)

                                            /* OR (Opportunity.StageName = :Label.DES_Draft AND Opportunity.OwnerId = :UserInfo.getUserId())*/)
            ]);

        System.debug('::::::listOppProduct : ' + listOppProduct);
        List<WrapperClass> listWrapper = new List<WrapperClass>();
        for(OpportunityLineItem opli : listOppProduct){
            System.debug('::::::POT.REVENUES: ' + opli.pre_oppy_revenue_next_12m_amount__c);
            listWrapper.add(new WrapperClass(opli.Opportunity, opli.Opportunity.Name, opli.Product2, opli.Product2.Name, opli.DES_Product_Family__c, opli.pre_oppy_revenue_next_12m_amount__c, opli.Opportunity.region_name__c));
        }

        System.debug(':::::::listWrapper getOppProducts : ' + JSON.serialize(listWrapper));
        return JSON.serialize(listWrapper);
    }

    //private static List<String> getFamilyValuesIntoList(){
    //    List<String> pickListValuesList= new List<String>();
    //    Schema.DescribeFieldResult fieldResult = Product2.Family.getDescribe();
    //    List<Schema.PicklistEntry> ple = fieldResult.getPicklistValues();
    //    System.debug('::::::ple: ' + ple);
    //    for( Schema.PicklistEntry pickListVal : ple){
    //        pickListValuesList.add(pickListVal.getLabel());
    //    }
    //    System.debug('::::::pickListValuesList: ' + pickListValuesList);
    //    return pickListValuesList;
    //}

    @AuraEnabled
    public static String getCurrentUserISOCode(){
        return UserInfo.getDefaultCurrency();
    }

    public class WrapperClass{
      private String oppName;
      private String prodName;
      private String prodFam;
      private Decimal expRevenue;
      private Decimal potRevenue;
      private String urlOpp;
      private String urlAccount;
      private String urlProduct;
      private String oppAccountName;
      private String stageName;
      private Date closeDate;
      private DateTime createdDate;
      private String regionName;
	      public WrapperClass(Opportunity opp, String oppName, Product2 product, String prodName, String prodFam, Decimal expRevenuePercent, String regionName){
	        this.urlOpp = '/lightning/r/Opportunity/' + opp.Id + '/view';
	        this.urlAccount = '/lightning/r/Account/' + opp.AccountId + '/view';
	        this.urlProduct = '/lightning/r/Product2/' + product.Id + '/view';
	        this.oppName = oppName;
	        this.oppAccountName = opp.Account.Name;
	        this.prodName = prodName;
	        this.prodFam = prodFam;
	        this.regionName = regionName;
	        if(opp.DES_Expected_Probability__c != null && expRevenuePercent != null){
	            this.expRevenue = expRevenuePercent * opp.DES_Expected_Probability__c/100;
	        }else{
	            this.expRevenue = 0;
	        }
	        this.potRevenue = expRevenuePercent;
	        this.stageName = opp.StageName;
	        this.closeDate = opp.CloseDate;
	        this.createdDate = opp.CreatedDate;
	      }
    }
}