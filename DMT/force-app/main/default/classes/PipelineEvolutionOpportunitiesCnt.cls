public with sharing class PipelineEvolutionOpportunitiesCnt {

    @AuraEnabled
  	public static String getData(String clientId){    
    	Map<String, Map<String, Double>> mapMonth = new Map<String, Map<String, Double>>();
        Integer currentDay = Date.today().day(); 
        Integer currentMonth = Date.today().month();
        Integer currentYear = Date.today().year();
        Date todayMonth = Date.newInstance(currentYear, currentMonth, currentDay);
  		Date firstDayMonth = Date.newInstance(currentYear, currentMonth, 1);
        Date lastMonth = Date.newInstance(currentYear, currentMonth-1, 1);
        Date twoMonthsBefore = Date.newInstance(currentYear, currentMonth-2, 1);
        
        system.debug('>>>>> Clase PipelineEvolutionOpportunitiesCnt: ' + clientId);
        date d = system.today().addDays(-366);
        Set<Id> setIdOppsDenormClient = new Set<Id>();
        list<dwp_acmh__Denorm_Account_Opportunity__c> denOppList = [SELECT dwp_acmh__OpportunityId__c, dwp_acmh__OpportunityId__r.Name FROM dwp_acmh__Denorm_Account_Opportunity__c 
                                                                    WHERE dwp_acmh__AccountId__c = :clientId
                                                                    /*AND dwp_acmh__OpportunityId__r.CreatedDate < :twoMonthsBefore*/
                                                                    /*dwp_acmh__OpportunityId__r.CreatedDate > :d*/ ORDER BY dwp_acmh__OpportunityId__r.CreatedDate ASC];
        system.debug('Valor de denOppList: ' +denOppList);
        
        for(dwp_acmh__Denorm_Account_Opportunity__c denOpp : denOppList){
            if(!setIdOppsDenormClient.contains(denOpp.dwp_acmh__OpportunityId__c)){
                setIdOppsDenormClient.add(denOpp.dwp_acmh__OpportunityId__c);
            }
            system.debug('Valor de denOpp: ' +denOpp.dwp_acmh__OpportunityId__r.Name);
        }
        
        List<OpportunityLineItem> listOppProduct = new List<OpportunityLineItem>();
        listOppProduct = new List<OpportunityLineItem>([
                                SELECT  DES_Product_Family__c,
                                        convertCurrency(pre_oppy_revenue_next_12m_amount__c),
                                        OpportunityId,
                                        Opportunity.Name,
                                        Opportunity.AccountId,
                                        Opportunity.Account.Name,
                                        Opportunity.DES_Expected_Probability__c,
                                        Opportunity.StageName,
            							Opportunity.CreatedDate,
             							Opportunity.CloseDate,
            							Opportunity.DES_Date_Won_Lost__c
                                FROM OpportunityLineItem
                                WHERE ((Opportunity.StageName != :Label.DES_Draft AND OpportunityId IN :setIdOppsDenormClient)) ORDER BY Opportunity.CloseDate DESC
            ]);
        
        
        Map<String, Double> twoMonths = new Map<String, Double>();
        Map<String, Double> oneMonths = new Map<String, Double>();
        Map<String, Double> thisMonth = new Map<String, Double>();
        
        for(OpportunityLineItem opli : listOppProduct){
            system.debug('Valor de opli.pre_oppy_revenue_next_12m_amount__c: ' +opli.pre_oppy_revenue_next_12m_amount__c);
            system.debug('Valor de opli.Opportunity.CreatedDate: ' +opli.Opportunity.CreatedDate);
            system.debug('Valor de opli.Opportunity.CloseDate: ' +opli.Opportunity.CloseDate);
            if(opli.pre_oppy_revenue_next_12m_amount__c != null){
                
                //Si son del actual mes
                if((opli.Opportunity.CreatedDate < firstDayMonth && opli.Opportunity.CloseDate > firstDayMonth) 
                   || (opli.Opportunity.CreatedDate > firstDayMonth) ){
                       system.debug('Entra en el primer if.');
                    //Si son alive
                    if(opli.Opportunity.CreatedDate < firstDayMonth && opli.Opportunity.CloseDate > firstDayMonth && opli.Opportunity.DES_Date_Won_Lost__c == null){
                        if(thisMonth.get('Alive') == null){
                    		thisMonth.put('Alive', opli.pre_oppy_revenue_next_12m_amount__c);
                        }else{
                        	thisMonth.put('Alive', thisMonth.get('Alive') + (opli.pre_oppy_revenue_next_12m_amount__c));    
                        }
                        mapMonth.put('Current Month',thisMonth);
                    }
                    //Si son creadas
                    if(opli.Opportunity.CreatedDate > firstDayMonth && opli.Opportunity.CreatedDate <= todayMonth){
                        if(thisMonth.get('Created') == null){
                    		thisMonth.put('Created', opli.pre_oppy_revenue_next_12m_amount__c);
                        }else{
                         	//thisMonth.put('Created', thisMonth.get('Created') + (20000));   
                         	thisMonth.put('Created', thisMonth.get('Created') + (opli.pre_oppy_revenue_next_12m_amount__c)); 
                    	} 
                        mapMonth.put('Current Month',thisMonth);
                	}
                    //Si son ganadas
                    if(opli.Opportunity.DES_Date_Won_Lost__c > firstDayMonth && opli.Opportunity.DES_Date_Won_Lost__c <= todayMonth && opli.Opportunity.StageName == 'Closed Won'){
                    	if(thisMonth.get('Won') == null){
                    		thisMonth.put('Won', -opli.pre_oppy_revenue_next_12m_amount__c);
                        }else{
                         	thisMonth.put('Won', thisMonth.get('Won') - (opli.pre_oppy_revenue_next_12m_amount__c));    
                    	}  
                        mapMonth.put('Current Month',thisMonth);
                    }
                    //Si son perdidas
                    if(opli.Opportunity.DES_Date_Won_Lost__c > firstDayMonth && opli.Opportunity.DES_Date_Won_Lost__c <= todayMonth && opli.Opportunity.StageName == 'Closed Lost'){
                    	if(thisMonth.get('Lost') == null){
                    		//thisMonth.put('Lost', -500000);
                    		thisMonth.put('Lost', -opli.pre_oppy_revenue_next_12m_amount__c);
                        }else{
                         	//thisMonth.put('Lost', thisMonth.get('Lost') - (2000));    
                         	thisMonth.put('Lost', thisMonth.get('Lost') - (opli.pre_oppy_revenue_next_12m_amount__c));  
                    	}  
                        mapMonth.put('Current Month',thisMonth);
                    }
            	} 
                
                
                //Si son de hace un mes
                if((opli.Opportunity.CreatedDate < lastMonth && opli.Opportunity.CloseDate > lastMonth) 
                   || (opli.Opportunity.CreatedDate > lastMonth) ){
                    //Si son Alive
                	if(opli.Opportunity.CreatedDate < lastMonth && opli.Opportunity.CloseDate > lastMonth && opli.Opportunity.DES_Date_Won_Lost__c == null){
                    	if(oneMonths.get('Alive') == null){
                    		oneMonths.put('Alive', opli.pre_oppy_revenue_next_12m_amount__c);
                        }else{
                        	oneMonths.put('Alive', oneMonths.get('Alive') + (opli.pre_oppy_revenue_next_12m_amount__c));    
                        }
                        mapMonth.put('Last Month',oneMonths);		       
                    }
                    //Si son creadas
                    if(opli.Opportunity.CreatedDate >= lastMonth && opli.Opportunity.CreatedDate < firstDayMonth){
                        if(oneMonths.get('Created') == null){
                    		oneMonths.put('Created', opli.pre_oppy_revenue_next_12m_amount__c);
                        }else{
                         	//oneMonths.put('Created', oneMonths.get('Created') + (20000)); 
                         	oneMonths.put('Created', oneMonths.get('Created') + (opli.pre_oppy_revenue_next_12m_amount__c));    
                    	} 
                        mapMonth.put('Last Month',oneMonths);
                	}
                    //Si son ganadas
                    if(opli.Opportunity.DES_Date_Won_Lost__c >= lastMonth && opli.Opportunity.DES_Date_Won_Lost__c < firstDayMonth && opli.Opportunity.StageName == 'Closed Won'){
                    	if(oneMonths.get('Won') == null){
                    		oneMonths.put('Won', -opli.pre_oppy_revenue_next_12m_amount__c);
                        }else{
                         	oneMonths.put('Won', oneMonths.get('Won') - (opli.pre_oppy_revenue_next_12m_amount__c));    
                    	}  
                        mapMonth.put('Last Month',oneMonths);
                    }
                    //Si son perdidas
                    if(opli.Opportunity.DES_Date_Won_Lost__c >= lastMonth && opli.Opportunity.DES_Date_Won_Lost__c < firstDayMonth && opli.Opportunity.StageName == 'Closed Lost'){
                    	if(oneMonths.get('Lost') == null){
                    		//oneMonths.put('Lost', -500000);
                    		oneMonths.put('Lost', -opli.pre_oppy_revenue_next_12m_amount__c);
                        }else{
                         	//oneMonths.put('Lost', oneMonths.get('Lost') - (2000));    
                         	oneMonths.put('Lost', oneMonths.get('Lost') - (opli.pre_oppy_revenue_next_12m_amount__c));
                    	}  
                        mapMonth.put('Last Month',oneMonths);
                    }               
                }
                
                //Si son de hace dos meses.
                if((opli.Opportunity.CreatedDate < twoMonthsBefore && opli.Opportunity.CloseDate > twoMonthsBefore) 
                   || (opli.Opportunity.CreatedDate > twoMonthsBefore) ){
                       
                	//Si son Alive
                	if(opli.Opportunity.CreatedDate < twoMonthsBefore && opli.Opportunity.CloseDate > twoMonthsBefore && opli.Opportunity.DES_Date_Won_Lost__c == null){
                    	if(twoMonths.get('Alive') == null){
                    		twoMonths.put('Alive', opli.pre_oppy_revenue_next_12m_amount__c);
                        }else{
                        	twoMonths.put('Alive', twoMonths.get('Alive') + (opli.pre_oppy_revenue_next_12m_amount__c));    
                        }
                        mapMonth.put('2 Months Ago',twoMonths);		       
                    }
                    //Si son creadas
                    if(opli.Opportunity.CreatedDate >= twoMonthsBefore && opli.Opportunity.CreatedDate < lastMonth){
                        if(twoMonths.get('Created') == null){
                    		twoMonths.put('Created', opli.pre_oppy_revenue_next_12m_amount__c);
                        }else{
                         	//twoMonths.put('Created', twoMonths.get('Created') + (20000));    
                         	twoMonths.put('Created', twoMonths.get('Created') + (opli.pre_oppy_revenue_next_12m_amount__c));   
                    	} 
                        mapMonth.put('2 Months Ago',twoMonths);
                	}
                    //Si son ganadas
                    if(opli.Opportunity.DES_Date_Won_Lost__c >= twoMonthsBefore && opli.Opportunity.DES_Date_Won_Lost__c < lastMonth && opli.Opportunity.StageName == 'Closed Won'){
                    	if(twoMonths.get('Won') == null){
                    		twoMonths.put('Won', -opli.pre_oppy_revenue_next_12m_amount__c);
                        }else{
                         	twoMonths.put('Won', twoMonths.get('Won') - (opli.pre_oppy_revenue_next_12m_amount__c));    
                    	}  
                        mapMonth.put('2 Months Ago',twoMonths);
                    }
                    //Si son perdidas
                    if(opli.Opportunity.DES_Date_Won_Lost__c >= twoMonthsBefore && opli.Opportunity.DES_Date_Won_Lost__c < lastMonth && opli.Opportunity.StageName == 'Closed Lost'){
                    	if(twoMonths.get('Lost') == null){
                    		//twoMonths.put('Lost', -500000);
                    		twoMonths.put('Lost', -opli.pre_oppy_revenue_next_12m_amount__c);
                        }else{
                         	//twoMonths.put('Lost', twoMonths.get('Lost') - (2000));  
                         	twoMonths.put('Lost', twoMonths.get('Lost') - (opli.pre_oppy_revenue_next_12m_amount__c));   
                    	}  
                        mapMonth.put('Last Month',twoMonths);
                    }    
                       
                }
                
            
        	}          
        }
        
        //Datos para la Review
        thisMonth.put('Alive', 90000);
        mapMonth.put('Current Month',thisMonth);
        thisMonth.put('Created', 50000);
        mapMonth.put('Current Month',thisMonth);       
        thisMonth.put('Won', -40000);
        mapMonth.put('Current Month',thisMonth);
        thisMonth.put('Lost', -30000);
        mapMonth.put('Current Month',thisMonth);
        
        oneMonths.put('Alive', 30000);
        mapMonth.put('Last Month',oneMonths);
        oneMonths.put('Created', 100000);
        mapMonth.put('Last Month',oneMonths);
        oneMonths.put('Won', -15000);
        mapMonth.put('Last Month',oneMonths);
        oneMonths.put('Lost', -25000);
        mapMonth.put('Last Month',oneMonths);
        
        twoMonths.put('Alive', 50000);
        mapMonth.put('2 Months Ago',twoMonths);
        twoMonths.put('Created', 20000);
        mapMonth.put('2 Months Ago',twoMonths);
        twoMonths.put('Won', -30000);
        mapMonth.put('2 Months Ago',twoMonths);
        twoMonths.put('Lost', -10000);
        mapMonth.put('2 Months Ago',twoMonths);
        

        
        system.debug('Valor de mapMonth: ' +mapMonth);
        return JSON.serialize(mapMonth);
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
                AND ((Opportunity.StageName != :Label.DES_Draft AND OpportunityId IN :setIdOppsDenormClient)/* OR (Opportunity.StageName = :Label.DES_Draft AND Opportunity.OwnerId = :UserInfo.getUserId())*/)
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
    
    
     @AuraEnabled
    public static String getCurrentUserISOCode(){
        return UserInfo.getDefaultCurrency();
    }

    public class WrapperClass{
      /*
        *  CREAR VARIABLE QUE TEGA LA URL A LA QUE VA A REDIRECCIONAR LA COLUMNA ( TENDRÁ UNA PARA LA OPORTUNIDAD ¿Y OTRA PARA EL PRODUCTO?) 
        *
        */
      private String oppName;
      private String prodName;
      private String prodFam;
      private Decimal expRevenue;
      private String urlOpp;
      private String urlAccount;
      private String urlProduct;
      private String oppAccountName;
      private String stageName;
      private Date closeDate;
      private DateTime createdDate;

      /*Opportunity
      Account
      Product Family
      Expected Revenues
      Created Date
      Closed Date
      Stage Name*/

      private WrapperClass(Opportunity opp, String oppName, Product2 product, String prodName, String prodFam, Decimal expRevenuePercent){
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