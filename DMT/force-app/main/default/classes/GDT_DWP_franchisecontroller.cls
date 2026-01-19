/*
* @author Ander Ercilla
* @description Clase del componente lightning DES_FranchiseAccordion de la ficha de grupo.
*/
public with sharing class GDT_DWP_franchisecontroller {//NOSONAR
    /* DES_VISION definición de la variable estatica DES_Vision__c */
    final static string DES_VISION = 'DES_Vision__c';
    /* YEAR definición de la variable estatica 'Year' */
    final static string YEAR = 'Year';
    /*
    * @author Ander Ercilla
    * @description Recupera las franchises relacionadas con la cuenta YTD
    */
    
    @AuraEnabled
    public static List<TableWrapper> returnFracnhise(String accountId) {
   
             final List<AggregateResult> franchises = [SELECT  DES_Vision__c, solution_name_path_desc__c, SUM(DES_YTD_Franchise__c)AmountYear 

                                                 FROM DES_Franchises__c
                                                 WHERE DES_Client__c =:accountId
                                                 AND DES_Type_of_vision__c = 'Business Line'
                                                 AND source_code_desc__c = 'Datio'
                                                 GROUP BY DES_Vision__c, solution_name_path_desc__c];
            system.debug(franchises);
            
            final List<AggregateResult> newProducts = [SELECT  DES_Vision__c, SUM(gf_frnch_cva_ytd_amount__c)CVA, SUM(gf_frnch_matfil_ytd_amount__c)Matfil, SUM(gf_frnch_xsell_ytd_amount__c)XB



                                                 FROM DES_Franchises__c
                                                 WHERE DES_Client__c =:accountId
                                                 AND DES_Type_of_vision__c = 'Business Line'
                                                 AND source_code_desc__c = 'Datio'
                                                 GROUP by DES_Vision__c
                                                 ];
            return franchiseValues(franchises, newProducts, 'Year');
    }
    /*
    * @author Ander Ercilla
    * @description Recupera las franchises relacionadas con la cuenta MTD
    */    
   @AuraEnabled
    public static List<TableWrapper> returnFracnhiseM(String accountId) {
   
             final List<AggregateResult> franchises = [SELECT  DES_Vision__c, solution_name_path_desc__c, SUM(DES_MTD_Franchise__c
)AmountMonth 

                                                 FROM DES_Franchises__c
                                                 WHERE DES_Client__c =:accountId
                                                 AND DES_Type_of_vision__c = 'Business Line'
                                                 AND source_code_desc__c = 'Datio'
                                                 GROUP BY DES_Vision__c, solution_name_path_desc__c];
            system.debug(franchises);
            
            final List<AggregateResult> newProducts = [SELECT  DES_Vision__c, SUM(gf_frnch_cva_mtd_amount__c)CVA, SUM(gf_frnch_matfil_mtd_amount__c)Matfil, SUM(gf_frnch_xsell_mtd_amount__c)XB



                                                 FROM DES_Franchises__c
                                                 WHERE DES_Client__c =:accountId
                                                 AND DES_Type_of_vision__c = 'Business Line'
                                                 AND source_code_desc__c = 'Datio'
                                                 GROUP by DES_Vision__c
                                                 ];
            return franchiseValues(franchises, newProducts, 'Month');
    }      

    
    /*
    * @author Ander Ercilla
    * @description Mapeo de las tablas creadas
    */
    public static List<TableWrapper> franchiseValues(List<AggregateResult> aggregateFr, List<AggregateResult> newProducts, String dateMtdYtd) {
        final List<TableWrapper> returnTableList = new List<TableWrapper>();
        final Map<String,Map<String,Decimal>> returnmap = new Map<String,Map<String,Decimal>>();
        Map<String,Decimal> tempMap;
system.debug(JSON.serializePretty(aggregateFr));
        for(AggregateResult a : aggregateFr) {
            tempMap = new Map<String,Decimal>();
            tempMap = returnmap.containsKey((String)a.get(DES_VISION)) ? returnmap.get((String)a.get(DES_VISION)) : new Map<String,Decimal>();
            if(dateMtdYtd == YEAR) {
                tempMap.put((String)a.get('solution_name_path_desc__c'), (Decimal)a.get('AmountYear'));
            } else {
            tempMap.put((String)a.get('solution_name_path_desc__c'), (Decimal)a.get('AmountMonth'));
        }
            returnmap.put((String)a.get(DES_VISION), tempMap);
        }
        for(String mKey : returnmap.keySet()) {
            returnTableList.add(new TableWrapper(mKey, returnmap.get(mKey), newProducts ));
            
        }
        return returnTableList;
        
    }
    /*
    * @author Ander Ercilla
    * @description Clase dentro de la clase para controlar el mapeo de la tablas
    */
    public class TableWrapper {
        /* Recupera el valor de la tabla para business line */
        @AuraEnabled public String businessLine {get;set;}
        /* Recupera el valor de la tabla para rates */
        @AuraEnabled public Decimal rates {get;set;}
        /* Recupera el valor de la tabla para credit */
        @AuraEnabled public Decimal credit {get;set;}
        /* Recupera el valor de la tabla para fx */
        @AuraEnabled public Decimal fxProduct {get;set;}
        /* Recupera el valor de la tabla para equity */
        @AuraEnabled public Decimal equity {get;set;}
        /* Recupera el valor de la tabla para other */
        @AuraEnabled public Decimal other {get;set;}
        /* Recupera el valor de la tabla para total*/
        @AuraEnabled public Decimal total {get;set;}
        /* Recupera el valor de la tabla para cva */
        @AuraEnabled public Decimal cva {get;set;}
        /* Recupera el valor de la tabla para matfil */
        @AuraEnabled public Decimal matfil {get;set;}
        /* Recupera el valor de la tabla para xsell */
        @AuraEnabled public Decimal xsell {get;set;}

    /*
    * @author Ander Ercilla
    * @description Mapeo de las tablas creadas
    */
        
        public TableWrapper(String bLine, Map<String,Decimal> values,  List<AggregateResult> newProducts) {
            
            this.businessLine = bLine;
            this.rates = convertNull(GDT_DWP_franchisecontroller.getValueByKey(values,'Rates'));
            this.credit = convertNull(GDT_DWP_franchisecontroller.getValueByKey(values,'Credit'));
            this.fxProduct = convertNull(GDT_DWP_franchisecontroller.getValueByKey(values,'FX'));
            this.equity = convertNull(GDT_DWP_franchisecontroller.getValueByKey(values,'Equity'));
            this.other = convertNull(GDT_DWP_franchisecontroller.getValueByKey(values,'Others'));
            

               
            for(AggregateResult agrResults: newProducts) {
                if(bLine == agrResults.get(DES_VISION)) {
                    this.cva = convertNull(getValueByKey(agrResults,'CVA'));
                    this.matfil = convertNull(getValueByKey(agrResults,'Matfil'));
                    this.xsell = convertNull(getValueByKey(agrResults,'XB'));
   
                }
            }
     
            this.total = sumValues(values,newProducts, bLine);
            
            system.debug(values);
        }
    }
        
    /*
    * @author Ander Ercilla
    * @description mapeo de los assets originales
    */
        public static Decimal getValueByKey(Map<String,Decimal> values,String key) {
            
            return values.containsKey(key) ? values.get(key) : 0;
            
        }
        
    /*
    * @author Ander Ercilla
    * @description mapeo de los assets nuevos
    */
        public static Decimal getValueByKey(AggregateResult agg, String key) {
            return agg.get(key) != null ? (Decimal)agg.get(key) : 0;//NOSONAR
        }
        
    /*
    * @author Ander Ercilla
    * @description Sumatorio de los assets nuevos y originales
    */
        public static Decimal sumValues(Map<String,Decimal> values,List<AggregateResult> newProducts, string bLine) {
            Decimal totalSum = 0;
            for(string totalKey : values.keySet()) {
                totalSum += convertNull(values.get(totalKey));
            }
        
            for(AggregateResult agrResults: newProducts) {
                if(bLine == agrResults.get(DES_VISION)) {
                    if(agrResults.get('CVA') != null) {
                        totalSum += convertNull((Decimal)agrResults.get('CVA'));
                    }
   
                    if(agrResults.get('Matfil') != null) {
                        totalSum += convertNull((Decimal)agrResults.get('Matfil'));
                    }
   
                    if(agrResults.get('XB') != null) {
                        totalSum += convertNull((Decimal)agrResults.get('XB'));
                    }

                }
            }
            return totalSum;
        }
    /*
    * @author Ander Ercilla
    * @description Controlar los valores vacíos que llegan de Datio
    */
    public static Decimal convertNull(Decimal num) {
        return num == null  ?  0:num;
    }
    
}