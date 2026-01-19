/**********************************************************************************
* @author       VASS - DSL
* @date         12/04/2018
* @description  Clase que recupera los datos de Oportunidades, los procesa y devuelve el resultado en el formato apropiado para poder crear posteriormente el chart con la libreria CHART.JS
* @Revision                     
**********************************************************************************/
global with sharing class DES_OppExpRevenuesTime_Controller {

    global DES_OppExpRevenuesTime_Controller() {

    }

    @AuraEnabled
    public static String getData(String clientId){
        system.debug('>>>>> FUNCION getData. ID CLIENTE : ' + clientId);
        date d = system.today().addDays(-366);
        Set<Id> setIdOppsDenormClient = new Set<Id>();
		for(dwp_acmh__Denorm_Account_Opportunity__c denOpp : [SELECT dwp_acmh__OpportunityId__c FROM dwp_acmh__Denorm_Account_Opportunity__c WHERE dwp_acmh__AccountId__c = :clientId]){
			if(!setIdOppsDenormClient.contains(denOpp.dwp_acmh__OpportunityId__c)){
				setIdOppsDenormClient.add(denOpp.dwp_acmh__OpportunityId__c);
			}
		}
		system.debug('>>>>> setIdOppsDenormClient : ' + setIdOppsDenormClient);
        //Recojo todos los Opportunity Products que pertenezcan a alguna oportunidad de la cuenta de la tabla Desnormalizada 
        List<OpportunityLineItem> listOppProduct = new List<OpportunityLineItem>([
                                    SELECT  DES_Product_Family__c,
                                            convertCurrency(pre_oppy_revenue_next_12m_amount__c),
                                            OpportunityId,
                                            Opportunity.Name,
                                            Opportunity.AccountId,
                                            Opportunity.Account.Name,
                                            Opportunity.DES_Expected_Probability__c,
                                            Opportunity.StageName
                                    FROM OpportunityLineItem
                                    WHERE CreatedDate > :d
                                        AND ((Opportunity.StageName != :Label.DES_Draft AND OpportunityId IN :setIdOppsDenormClient) OR (Opportunity.StageName = :Label.DES_Draft AND Opportunity.OwnerId = :UserInfo.getUserId()))
            ]);
        
        system.debug('>>>>> listOppProduct : ' + listOppProduct);
        
        //Mapa que tiene como key el Family Product y como Value el Potential Revenue total de ese producto
        Map<String, Double> mapFPPR_Alive = new Map<String, Double>();
        Map<String, Double> mapFPPR_Won = new Map<String, Double>();
        Map<String, Double> mapFPPR_Lost = new Map<String, Double>();
        //Mapa que tiene como key el Stage y como Value el mapa mapFPPR
        Map<String, Map<String, Double>> mapStage = new Map<String, Map<String, Double>>();
        
        List<String> listFamProd = getFamilyValuesIntoList();
        system.debug('>>>>> listFamProd : ' + listFamProd);
        for(String fp : listFamProd){
            //recorro todo el mapa, para las familia de producto que no tengan datos (que sean null) las pongo a 0
            if(mapFPPR_Alive.get(fp) == null){
                mapFPPR_Alive.put(fp,0);
            }
            if(mapFPPR_Won.get(fp) == null){
                mapFPPR_Won.put(fp,0);
            }
            if(mapFPPR_Lost.get(fp) == null){
                mapFPPR_Lost.put(fp,0);
            }
        }
        system.debug('>>>>> mapFPPR_Alive: ' + mapFPPR_Alive);
        system.debug('>>>>> mapFPPR_Won: ' + mapFPPR_Won);
        system.debug('>>>>> mapFPPR_Lost: ' + mapFPPR_Lost);
        
        //Si la lista no está vacia
        if(!listOppProduct.isEmpty()){

            for(OpportunityLineItem opli : listOppProduct){
            	system.debug('>>>>> opli.OpportunityId : ' + opli.OpportunityId);
            	system.debug('>>>>> opli.pre_oppy_revenue_next_12m_amount__c : ' + opli.pre_oppy_revenue_next_12m_amount__c);
            	system.debug('>>>>> opli.Opportunity.DES_Expected_Probability__c : ' + opli.Opportunity.DES_Expected_Probability__c);
                //Si tiene informado el potential revenue
                if(opli.pre_oppy_revenue_next_12m_amount__c != null && opli.Opportunity.DES_Expected_Probability__c != null){
                    if(opli.Opportunity.StageName == Label.DES_Proposal
                      || opli.Opportunity.StageName == Label.DES_Approvals
                      || opli.Opportunity.StageName == Label.DES_Ready_to_close
                      || opli.Opportunity.StageName == Label.DES_Alive
                      || opli.Opportunity.StageName == Label.DES_Draft){
                        // los meto en alive 
                        opli.Opportunity.StageName = Label.DES_Alive;
                        system.debug('>>>>> entro en alive : ' + listOppProduct);
                        system.debug('>>>>> opli.DES_Product_Family__c : ' + opli.DES_Product_Family__c);
                        system.debug('>>>>> opli.pre_oppy_revenue_next_12m_amount__c * opli.Opportunity.DES_Expected_Probability__c/100 : ' + opli.pre_oppy_revenue_next_12m_amount__c * opli.Opportunity.DES_Expected_Probability__c/100);
                        //Si no existe esa familia en el mapa
                        if(mapFPPR_Alive.get(opli.DES_Product_Family__c) == null){
                            //Le pongo el valor del Potential Revenue a la key que tenga ese Product Family
                            system.debug('>>>>> mapFPPR_Alive : ' + mapFPPR_Alive);
                            mapFPPR_Alive.put(opli.DES_Product_Family__c, opli.pre_oppy_revenue_next_12m_amount__c * opli.Opportunity.DES_Expected_Probability__c/100);
                            system.debug('>>>>> mapFPPR_Alive : ' + mapFPPR_Alive);
                            mapStage.put(opli.Opportunity.StageName, mapFPPR_Alive);
                            system.debug('no existe esa familia en el mapa mapStage: ' + mapStage);
                        }else{  
                            //Si ya tiene valor, le sumo el potential revenue a ese mismo valor
                            system.debug('>>>>> mapFPPR_Alive : ' + mapFPPR_Alive);
                            mapFPPR_Alive.put(opli.DES_Product_Family__c, mapFPPR_Alive.get(opli.DES_Product_Family__c) + ((opli.pre_oppy_revenue_next_12m_amount__c) * opli.Opportunity.DES_Expected_Probability__c/100));
                            mapStage.put(opli.Opportunity.StageName, mapFPPR_Alive);
                        }
                        system.debug('clear mapFPPR_Alive en alive mapFPPR_Alive: ' + mapFPPR_Alive);
                    }else{
                       if(opli.Opportunity.StageName == Label.DES_Closed_Won
                         || opli.Opportunity.StageName == Label.DES_Won){
                            // los meto en lost
                            opli.Opportunity.StageName = Label.DES_Won;
                            //Si no existe esa familia en el mapa
                            if(mapFPPR_Won.get(opli.DES_Product_Family__c) == null){
                                //Le pongo el valor del Potential Revenue a la key que tenga ese Product Family
                                mapFPPR_Won.put(opli.DES_Product_Family__c, opli.pre_oppy_revenue_next_12m_amount__c * opli.Opportunity.DES_Expected_Probability__c/100);
                                mapStage.put(opli.Opportunity.StageName, mapFPPR_Won);
                            }else{  
                                //Si ya tiene valor, le sumo el potential revenue a ese mismo valor
                                mapFPPR_Won.put(opli.DES_Product_Family__c, mapFPPR_Won.get(opli.DES_Product_Family__c) + ((opli.pre_oppy_revenue_next_12m_amount__c) * opli.Opportunity.DES_Expected_Probability__c/100));
                                mapStage.put(opli.Opportunity.StageName, mapFPPR_Won);
                            }
                           system.debug('clear mapFPPR_Won en alive mapFPPR_Won: ' + mapFPPR_Won);
                       }else{
                           if(opli.Opportunity.StageName == Label.DES_Closed_Lose
                             || opli.Opportunity.StageName == Label.DES_Lost){
                                // los meto en lost
                                opli.Opportunity.StageName = Label.DES_Lost;
                                //Si no existe esa familia en el mapa
                                if(mapFPPR_Lost.get(opli.DES_Product_Family__c) == null){
                                    //Le pongo el valor del Potential Revenue a la key que tenga ese Product Family
                                    mapFPPR_Lost.put(opli.DES_Product_Family__c, opli.pre_oppy_revenue_next_12m_amount__c * opli.Opportunity.DES_Expected_Probability__c/100);
                                    mapStage.put(opli.Opportunity.StageName, mapFPPR_Lost);
                                }else{  
                                    //Si ya tiene valor, le sumo el potential revenue a ese mismo valor
                                    mapFPPR_Lost.put(opli.DES_Product_Family__c, mapFPPR_Lost.get(opli.DES_Product_Family__c) + ((opli.pre_oppy_revenue_next_12m_amount__c) * opli.Opportunity.DES_Expected_Probability__c/100));
                                    mapStage.put(opli.Opportunity.StageName, mapFPPR_Lost);
                                }
                                system.debug('clear mapFPPR_Lost en alive mapFPPR_Lost: ' + mapFPPR_Lost);
                            }
                        } 
                    }
                }
                system.debug('>>>>> opli.Opportunity.Name : ' + opli.Opportunity.Name);
            }
        }//FIN !listOppProduct.isEmpty()
        
        
        
        system.debug('>>>>> mapStage ANTES RELLENAR TODAS LAS FAMILIAS: ' + mapStage);
        /*for(Map<String, Double> mapFP : mapStage.values()){
            List<String> listFamProd = getFamilyValuesIntoList();
            for(String fp : listFamProd){
                //recorro todo el mapa, para las familia de producto que no tengan datos (que sean null) las pongo a 0
                if(mapFP.get(fp) == null){
                    mapFP.put(fp,0);
                }
            }
            
        }
        system.debug('>>>>> mapStage DESPUES RELLENAR TODAS LAS FAMILIAS: ' + mapStage);*/
        return JSON.serialize(mapStage);
    }


    @AuraEnabled
    public static String getOppProducts(String clientId){
        system.debug('>>>>> clientId: ' + clientId);
        date d = system.today().addDays(-366);
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
                                    WHERE CreatedDate > :d 
                                            AND ((Opportunity.StageName != :Label.DES_Draft AND OpportunityId IN :setIdOppsDenormClient) OR (Opportunity.StageName = :Label.DES_Draft AND Opportunity.OwnerId = :UserInfo.getUserId()))
            ]);
        
        system.debug('>>>>> listOppProduct : ' + listOppProduct);
        List<WrapperClass> listWrapper = new List<WrapperClass>();
        for(OpportunityLineItem opli : listOppProduct){
            system.debug('>>>>> POT.REVENUES: ' + opli.pre_oppy_revenue_next_12m_amount__c);
            listWrapper.add(new WrapperClass(opli.Opportunity, opli.Opportunity.Name, opli.Product2, opli.Product2.Name, opli.DES_Product_Family__c, opli.pre_oppy_revenue_next_12m_amount__c));
        }

        system.debug('>>>>>listWrapper : ' + listWrapper);
        return JSON.serialize(listWrapper);
    }//FIN getOppProduct
    
    private static List<String> getFamilyValuesIntoList(){
        List<String> pickListValuesList= new List<String>();
        Schema.DescribeFieldResult fieldResult = Product2.Family.getDescribe();
        List<Schema.PicklistEntry> ple = fieldResult.getPicklistValues();
        system.debug('>>>>> ple: ' + ple);
        for( Schema.PicklistEntry pickListVal : ple){
            pickListValuesList.add(pickListVal.getLabel());
        }
        system.debug('>>>>> pickListValuesList: ' + pickListValuesList);
        return pickListValuesList;
    }//getFamilyValuesIntoList
    
    
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
            if(opp.DES_Expected_Probability__c != null && expRevenuePercent != null){
                this.expRevenue = expRevenuePercent * opp.DES_Expected_Probability__c/100;
            }else{
                this.expRevenue = 0;
            }
            this.stageName = opp.StageName;
            this.CloseDate = opp.CloseDate;
            this.createdDate = opp.CreatedDate;
        }
    }   
    
}