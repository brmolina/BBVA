/*
    * @author Global Desktop
    * @description clase RateOfSuccessChartCnt
    */
public with sharing class RateOfSuccessChartCnt {//NOSONAR
    //CAMBIAR LAS REFERENCIAS AL CAMPO CloseDate POR CreatedDate para subir a producción. Está así para poder presentar datos en la ficha.

    /*
    * @author Global Desktop
    * @description Recoge los valores de picklist del campo Family del objeto Product
    */
    private static List<String> getFamilyValuesIntoList() {//NOSONAR
        List<String> pickListValuesList;//NOSONAR
        pickListValuesList = new List<String>();
        final Schema.DescribeFieldResult fieldResult = Product2.Family.getDescribe();
        final List<Schema.PicklistEntry> ple = fieldResult.getPicklistValues();
        system.debug('>>>>> ple: ' + ple);
        for( Schema.PicklistEntry pickListVal : ple) {
            pickListValuesList.add(pickListVal.getLabel());
        }
        system.debug('>>>>> pickListValuesList: ' + pickListValuesList);
        return pickListValuesList;
    }


    /*
    * @author Global Desktop
    * @description Recupera las oportunidades denormalizadas relacionadas con la cuenta
    */
    @AuraEnabled
    public static String getData(String clientId) {
        system.debug('>>>>> FUNCION getData. ID CLIENTE : ' + clientId);
        final date lastYear = system.today().addDays(-366);
        final Set<Id> setIdOppsDenormClient = new Set<Id>();//NOSONAR
        final list<dwp_acmh__Denorm_Account_Opportunity__c> denOppList = [SELECT dwp_acmh__OpportunityId__c, dwp_acmh__OpportunityId__r.Name, dwp_acmh__OpportunityId__r.CloseDate,
                                                                    dwp_acmh__OpportunityId__r.CreatedDate
                                                                    FROM dwp_acmh__Denorm_Account_Opportunity__c
                                                                    WHERE dwp_acmh__AccountId__c = :clientId
                                                                      AND dwp_acmh__OpportunityId__r.CreatedDate > :lastYear ///*CloseDate*/
                                                                      AND (dwp_acmh__OpportunityId__r.StageName = 'Closed Won'
                                                                       OR dwp_acmh__OpportunityId__r.StageName = 'Closed Lost')
                                                                 ORDER BY dwp_acmh__OpportunityId__r.CreatedDate DESC];

        for(dwp_acmh__Denorm_Account_Opportunity__c denOpp : denOppList) {
          if(!setIdOppsDenormClient.contains(denOpp.dwp_acmh__OpportunityId__c)) {
            setIdOppsDenormClient.add(denOpp.dwp_acmh__OpportunityId__c);
          }
        }

        List<OpportunityLineItem> listOppProduct = new List<OpportunityLineItem>();

        listOppProduct = new List<OpportunityLineItem>([SELECT DES_Product_Family__c,
                                                        convertCurrency(DES_Potential_Revenue__c),
                                                        convertCurrency(pre_oppy_revenue_next_12m_amount__c),
                                                        OpportunityId,
                                                        Opportunity.Name,
                                                        Opportunity.AccountId,
                                                        Opportunity.Account.Name,
                                                        Opportunity.DES_Expected_Probability__c,
                                                        Opportunity.StageName,
                                                        Opportunity.CreatedDate,
                                                        Opportunity.CloseDate
                                                        FROM OpportunityLineItem
                                                        WHERE ((Opportunity.StageName != : Label.DES_Draft AND OpportunityId IN: setIdOppsDenormClient)) ORDER BY Opportunity.CreatedDate /*CloseDate*/ DESC
                                                        ]);
        system.debug('Valor de listOppProduct: ' +listOppProduct);
        final Map<String, Double> mapFirst = new Map<String, Double>();
        final Map<String, Double> mapSecond = new Map<String, Double>();
        final Map<String, Double> mapThird = new Map<String, Double>();
        final Map<String, Double> mapFourth = new Map<String, Double>();

        //Sustituir la agrupación de familia de producto por agrupacion por Q:
        system.debug('Valor de listOppProduct[0].Opportunity.CreatedDate: ' +listOppProduct[0].Opportunity.CreatedDate);
        // List<String> listQs = getQs(listOppProduct[0].Opportunity.CloseDate);
        final List<String> listQs = getQs(listOppProduct[0].Opportunity.CreatedDate);
        system.debug('Valor de listQs' +listQs);
        final List<String> listFamProd = getFamilyValuesIntoList();
        famPro(listFamProd,mapFirst,mapSecond,mapThird,mapFourth);



        final Set<Integer> Q1 = new Set<Integer> {1,2,3};//NOSONAR
        final Set<Integer> Q2 = new Set<Integer> {4,5,6};//NOSONAR
        final Set<Integer> Q3 = new Set<Integer> {7,8,9};//NOSONAR
        final Set<Integer> Q4 = new Set<Integer> {10,11,12};//NOSONAR
        Map<String, Map<String, Double> > mapStage = new Map<String, Map<String, Double> >();

        system.debug('Rate of Sucsess: Valor de listOppProduct: ' +listOppProduct);
        //Si la lista no está vacia
        if(!listOppProduct.isEmpty()) {

            final map<String,Integer> QProduct = new map<String,Integer>();//NOSONAR
            map<String,Integer> QProductWon = new map<String,Integer>();       //NOSONAR

            //parte 1
            putproduct(listOppProduct,Q1,Q2,Q3,Q4,QProduct,QProductWon);

            //parte 2
            mapStage = stage(QProduct,listQs,QProductWon,mapFirst,mapSecond,mapThird,mapFourth);

        }

        return JSON.serialize(mapStage);
    }


    //Calcular antes de la llamada a esta función el número de Q y pasarlo como parámetro y devolver los Qs
    // ordenados para tratarlos en cada uno de los mapas Firs, Second... etc.
    /*
    * @author Global Desktop
    * @description Ordena las oportunidades ordenadas por Qs desde la fecha actual hacia atras
    */
    private static List<String> getQs(DateTime dateTimeNow) {
        final List<String> pickListValuesList = new List<String>();//NOSONAR
        final Set<Integer> Q1 = new Set<Integer> {1,2,3};//NOSONAR
        final Set<Integer> Q2 = new Set<Integer> {4,5,6};//NOSONAR
        final Set<Integer> Q3 = new Set<Integer> {7,8,9};//NOSONAR
        final Set<Integer> Q4 = new Set<Integer> {10,11,12};//NOSONAR
        String firstColumnDate = String.valueOf(dateTimeNow.year());//NOSONAR
        Integer firstColumn;
        if(Q1.contains(dateTimeNow.month())) {
            firstColumnDate += ' Q1';
            firstColumn = 1;
        } else if(Q2.contains(dateTimeNow.month())) {
            firstColumnDate += ' Q2';
            firstColumn = 2;
        } else if(Q3.contains(dateTimeNow.month())) {
            firstColumnDate += ' Q3';
            firstColumn = 3;
        } else if(Q4.contains(dateTimeNow.month())) {
            firstColumnDate += ' Q4';
            firstColumn = 4;
        }

        //set<Integer> QNumber = new Set<String>{1,2,3,4};
        for(Integer i = 0; i<4; i++) {
            //pickListValuesList.add('Q'+firstColumn);
            if(firstColumn == 1) {//NOSONAR
                pickListValuesList.add('Q'+firstColumn);
                firstColumn = 4;//NOSONAR
            } else {
                pickListValuesList.add('Q'+firstColumn);
                firstColumn = firstColumn -1;
            }
        }
        return pickListValuesList;
    }


	/*
    * @author Global Desktop
    * @description Recupera los productos de las oportunidades denormalizadas relacionadas a la cuenta
    */
    @AuraEnabled
    public static String getOppProducts(String clientId) {
      system.debug('>>>>> clientId: ' + clientId);
      final date lastYear = system.today().addDays(-366);
      final Set<Id> setIdOppsDenormClient = new Set<Id>();//NOSONAR
      for(dwp_acmh__Denorm_Account_Opportunity__c denOpp : [SELECT dwp_acmh__OpportunityId__c FROM dwp_acmh__Denorm_Account_Opportunity__c WHERE dwp_acmh__AccountId__c = :clientId]) {
        if(!setIdOppsDenormClient.contains(denOpp.dwp_acmh__OpportunityId__c)) {
          setIdOppsDenormClient.add(denOpp.dwp_acmh__OpportunityId__c);
        }
      }

      final List<OpportunityLineItem> listOppProduct = new List<OpportunityLineItem>([
                                  SELECT DES_Product_Family__c,
                                          convertCurrency(DES_Potential_Revenue__c),
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
                                  WHERE CreatedDate > : lastYear
                                          AND ((Opportunity.StageName != : Label.DES_Draft AND OpportunityId IN: setIdOppsDenormClient) /* OR (Opportunity.StageName = :Label.DES_Draft AND Opportunity.OwnerId = :UserInfo.getUserId())*/)
          ]);

      system.debug('>>>>> listOppProduct : ' + listOppProduct);
      final List<WrapperClass> listWrapper = new List<WrapperClass>();
      for(OpportunityLineItem opli : listOppProduct) {
          system.debug('>>>>> POT.REVENUES: ' + opli.pre_oppy_revenue_next_12m_amount__c);
          listWrapper.add(new WrapperClass(opli.Opportunity, opli.Opportunity.Name, opli.Product2, opli.Product2.Name, opli.DES_Product_Family__c, opli.pre_oppy_revenue_next_12m_amount__c, String.valueOf(opli.Opportunity.DES_Expected_Probability__c)));
      }

      system.debug('>>>>>listWrapper : ' + listWrapper);
      return JSON.serialize(listWrapper);
    }
     /*
    * @author Global Desktop
    * @description Met0d0 aux 1
    */
    public static void famPro(List<String> listFamProd,Map<String, Double> mapFirst,Map<String, Double> mapSecond,Map<String, Double> mapThird,Map<String, Double> mapFourth) {
        for(String fp : listFamProd) {
            if(mapFirst.get(fp) == null) {
                mapFirst.put(fp,0);
            }
            if(mapSecond.get(fp) == null) {
                mapSecond.put(fp,0);
            }
            if(mapThird.get(fp) == null) {
                mapThird.put(fp,0);
            }
            if(mapFourth.get(fp) == null) {
                mapFourth.put(fp,0);
            }
        }
    }
	/*
    * @author Global Desktop
    * @description Met0d0 aux 1
    */
    public static void putproduct(list <OpportunityLineItem> listOppProduct,Set<Integer> Q1,Set<Integer> Q2,Set<Integer> Q3, Set<Integer> Q4,map<String,Integer> QProduct,map<String,Integer> QProductWon) {//NOSONAR
        for(OpportunityLineItem i : listOppProduct) {
                String numberQ;
                // if(Q1.contains(i.Opportunity.CloseDate.month())) {
                if(Q1.contains(i.Opportunity.CreatedDate.month())) {
                    numberQ = 'Q1';
                // } else if(Q2.contains(i.Opportunity.CloseDate.month())) {
                } else if(Q2.contains(i.Opportunity.CreatedDate.month())) {
                    numberQ = 'Q2';
                // } else if(Q3.contains(i.Opportunity.CloseDate.month())) {
                } else if(Q3.contains(i.Opportunity.CreatedDate.month())) {
                    numberQ = 'Q3';
                // } else if(Q4.contains(i.Opportunity.CloseDate.month())) {
                } else if(Q4.contains(i.Opportunity.CreatedDate.month())) {
                    numberQ = 'Q4';
                }

                if(QProduct.get(numberQ+'_'+i.DES_Product_Family__c) == null) {
                    QProduct.put(numberQ+'_'+i.DES_Product_Family__c,1);
                } else {
                    QProduct.put(numberQ+'_'+i.DES_Product_Family__c,QProduct.get(numberQ+'_'+i.DES_Product_Family__c)+1);
                }

                if(i.Opportunity.StageName == Label.DES_Closed_Won) {
                    if(QProductWon.get(numberQ+'_'+i.DES_Product_Family__c)==null) {
                        QProductWon.put(numberQ+'_'+i.DES_Product_Family__c,1);
                    } else {
                        QProductWon.put(numberQ+'_'+i.DES_Product_Family__c,QProductWon.get(numberQ+'_'+i.DES_Product_Family__c)+1);
                    }
                }
            }
    }
	/*
    * @author Global Desktop
    * @description Met0d0 aux 3
    */
    public static Map<String, Map<String, Double> > stage(map<String,Integer> QProduct,List<String> listQs,map<String,Integer> QProductWon,Map<String, Double> mapFirst,Map<String, Double> mapSecond,Map<String, Double> mapThird,Map<String, Double> mapFourth) {//NOSONAR
        Map<String, Map<String, Double> > mapStage;
        mapStage= new Map<String, Map<String, Double> >();
        for(String key : QProduct.keySet()) {
                if(key.split('_')[0]==listQs[0]) {
                    if(QProductWon.get(key) != null) {//NOSONAR
                        mapFirst.put(key.split('_')[1],((decimal)QProductWon.get(key)/QProduct.get(key))*100);
                    } else {
                        mapFirst.put(key.split('_')[1],0);
                    }
                    mapStage.put(key.split('_')[0], mapFirst);
                } else if(key.split('_')[0]==listQs[1]) {
                    if(QProductWon.get(key) != null) {//NOSONAR
                        mapSecond.put(key.split('_')[1],((decimal)QProductWon.get(key)/QProduct.get(key))*100);
                    } else {
                        mapSecond.put(key.split('_')[1],0);
                    }
                    mapStage.put(key.split('_')[0], mapSecond);
                } else if(key.split('_')[0]==listQs[2]) {
                    if(QProductWon.get(key) != null) {//NOSONAR
                        mapThird.put(key.split('_')[1],((decimal)QProductWon.get(key)/QProduct.get(key))*100);
                    } else {
                        mapThird.put(key.split('_')[1],0);
                    }
                    mapStage.put(key.split('_')[0], mapThird);
                } else if(key.split('_')[0]==listQs[3]) {
                    if(QProductWon.get(key) != null) {//NOSONAR
                        mapFourth.put(key.split('_')[1],((decimal)QProductWon.get(key)/QProduct.get(key))*100);
                    } else {
                        mapFourth.put(key.split('_')[1],0);
                    }
                    mapStage.put(key.split('_')[0], mapFourth);
                }
            }
        return mapStage;
    }
	/*
    * @author Global Desktop
    * @description Recuera el Iso code del usuario logado
    */
    @AuraEnabled
    public static String getCurrentUserISOCode() {//NOSONAR
        return UserInfo.getDefaultCurrency();
    }

	/*
    * @author Global Desktop
    * @description construye la lista wrapper que devuelve la informacion al componente lightning
    */
    public class WrapperClass {
      /**
      * @author Global Desktop
      * @description Variables de la lista wrapper
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
      /*
      * expectedProbability para crear el expectedProbability
      */
      final private String expectedProbability;//NOSONAR

	  /**
      * @author Global Desktop
      * @description Construye la clase wrapper
      */
      public WrapperClass(Opportunity opp, String oppName, Product2 product, String prodName, String prodFam, Decimal expRevenuePercent, String expProbability) {
        this.urlOpp = '/lightning/r/Opportunity/' + opp.Id + '/view';
        this.urlAccount = '/lightning/r/Account/' + opp.AccountId + '/view';
        this.urlProduct = '/lightning/r/Product2/' + product.Id + '/view';
        this.oppName = oppName;
        this.oppAccountName = opp.Account.Name;
        this.prodName = prodName;
        this.prodFam = prodFam;
        this.expectedProbability = expProbability == null ? '' : expProbability + '%';
        if(opp.DES_Expected_Probability__c != null && expRevenuePercent != null) {//NOSONAR
          this.expRevenue = expRevenuePercent * opp.DES_Expected_Probability__c/100;
        } else {
          this.expRevenue = 0;
        }
        this.stageName = opp.StageName;
        this.CloseDate = opp.CloseDate;
        this.createdDate = opp.CreatedDate;
      }
    }




}