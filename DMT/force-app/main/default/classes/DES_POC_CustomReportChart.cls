/**********************************************************************************
* @author       VASS - DSL
* @date         12/04/2018
* @description  Clase que recupera los datos de Oportunidades, los procesa y devuelve el resultado en el formato apropiado para poder crear posteriormente el chart con la libreria CHART.JS
* @Revision     12/07/2018	-	VASS DSL	-	Se modifica la clase para que en la Query recoja tambien todas las oportunidades que son MIAS y son DRAFT
**********************************************************************************/
global with sharing class DES_POC_CustomReportChart {

    global DES_POC_CustomReportChart() {

    }

    @AuraEnabled
    public static String getData(String clientId){
        system.debug('>>>>> FUNCION getData. ID CLIENTE : ' + clientId);
		
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
                                            OpportunityId,
                                            Opportunity.Name,
                                            Opportunity.AccountId,
                                            Opportunity.Account.Name,
                                            Opportunity.DES_Expected_Probability__c
                                    FROM OpportunityLineItem
                                    WHERE Opportunity.isClosed = false
                                        AND ((Opportunity.StageName != :Label.DES_Draft AND OpportunityId IN :setIdOppsDenormClient) OR (Opportunity.StageName = :Label.DES_Draft AND Opportunity.OwnerId = :UserInfo.getUserId()))
            ]);
        
        system.debug('>>>>> listOppProduct : ' + listOppProduct);

        //Mapa que tiene como key el Family Product y como Value el Potential Revenue total de ese producto
        Map<String, Double> mapFPPR = new Map<String, Double>();
        //Si la lista no está vacia
        if(!listOppProduct.isEmpty()){

            for(OpportunityLineItem opli : listOppProduct){
                //Si tiene informado el potential revenue
                if(opli.pre_oppy_revenue_next_12m_amount__c != null && opli.Opportunity.DES_Expected_Probability__c != null){
                    //Si no existe esa familia en el mapa
                    if(mapFPPR.get(opli.DES_Product_Family__c) == null){
                        //Le pongo el valor del Potential Revenue a la key que tenga ese Product Family
                        mapFPPR.put(opli.DES_Product_Family__c, opli.pre_oppy_revenue_next_12m_amount__c * (opli.Opportunity.DES_Expected_Probability__c/100));
                    }else{
                        //Si ya tiene valor, le sumo el potential revenue a ese mismo valor
                        mapFPPR.put(opli.DES_Product_Family__c, mapFPPR.get(opli.DES_Product_Family__c) + (opli.pre_oppy_revenue_next_12m_amount__c) * (opli.Opportunity.DES_Expected_Probability__c/100));
                    }
                }
                
            }

        }//FIN !listOppProduct.isEmpty()

        system.debug('>>>>> mapFPPR : ' + mapFPPR);
        return JSON.serialize(mapFPPR);
    }


    @AuraEnabled
    public static String getOppProducts(String clientId){
        system.debug('>>>>> clientId: ' + clientId);
        
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
                                    WHERE Opportunity.isClosed = false
                                        AND ((Opportunity.StageName != :Label.DES_Draft AND OpportunityId IN :setIdOppsDenormClient) OR (Opportunity.StageName = :Label.DES_Draft AND Opportunity.OwnerId = :UserInfo.getUserId()))
        ]);

        system.debug('>>>>>listOppProduct : ' + listOppProduct);
        List<WrapperClass> listWrapper = new List<WrapperClass>();
        for(OpportunityLineItem opli : listOppProduct){
            system.debug('>>>>> POT.REVENUES: ' + opli.pre_oppy_revenue_next_12m_amount__c);
            listWrapper.add(new WrapperClass(opli.Opportunity, opli.Opportunity.Name, opli.Product2, opli.Product2.Name, opli.DES_Product_Family__c, opli.pre_oppy_revenue_next_12m_amount__c));
        }

        system.debug('>>>>>listWrapper : ' + listWrapper);
        return JSON.serialize(listWrapper);
    }//FIN getOppProduct
    
    
    @AuraEnabled
    public static String getCurrentUserISOCode(){
        
        return UserInfo.getDefaultCurrency(); 
    }

    
    public class WrapperClass{
        
        /*
         *  CREAR VARIABLE QUE TEGA LA URL A LA QUE VA A REDIRECCIONAR LA COLUMNA ( TENDRÁ UNA PARA LA OPORTUNIDAD ¿Y OTRA PARA EL PRODUCTO?) 
         * 
         */
        public String oppName;
        public String prodName;
        public String prodFam;
        public Decimal expRevenue;
        public String urlOpp;
        public String urlAccount;
        public String urlProduct;
        public String oppAccountName;
        public String stageName;
        public Date closeDate;
        public DateTime createdDate;

        /*Opportunity
        Account
        Product Family
        Expected Revenues
        Created Date
        Closed Date
        Stage Name*/

        public WrapperClass(Opportunity opp, String oppName, Product2 product, String prodName, String prodFam, Decimal expRevenuePercent){
            this.urlOpp = '/lightning/r/Opportunity/' + opp.Id + '/view';
            this.urlAccount = '/lightning/r/Account/' + opp.AccountId + '/view';
            this.urlProduct = '/lightning/r/Product2/' + product.Id + '/view';
            this.oppName = oppName;
            this.oppAccountName = opp.Account.Name;
            this.prodName = prodName;
            this.prodFam = prodFam;
            system.debug('>>>>> opp.DES_Expected_Probability__c: ' + opp.DES_Expected_Probability__c);
            system.debug('>>>>> expRevenuePercent: ' + expRevenuePercent);
            if(opp.DES_Expected_Probability__c != null && expRevenuePercent != null){
                this.expRevenue = expRevenuePercent * (opp.DES_Expected_Probability__c/100);
            }else{
                this.expRevenue = 0;
            }
            this.stageName = opp.StageName;
            this.CloseDate = opp.CloseDate;
            this.createdDate = opp.CreatedDate;
        }
    }   
    
}