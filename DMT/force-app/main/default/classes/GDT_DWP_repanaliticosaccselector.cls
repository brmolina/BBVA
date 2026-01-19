/*
* GDT_DWP_repanaliticosaccselector
* Clase controladora del componente de visor de informes de Account
* @author Ander Ercilla
*/
public with sharing class GDT_DWP_repanaliticosaccselector {//NOSONAR

/* ACC_SIZE -> Definición del valor de la longitud de la query */
    final static integer ACC_SIZE = 50;
/* acc -> Definición de la lista de campos variables */
    static List<Account> acc;
/*
* reportSelector
* Method que recoge los informes asociados al RT del cliente sobre el que se está trabajando
* @author Ander Ercilla
*/   
     @AuraEnabled
    public static Map<String,String> reportSelector(String recordId) {
        final Map<String,String> mapa = new Map<String,String>();
        final Account clientStarId;//NOSONAR
        if (Schema.sObjectType.Account.isAccessible()) {
        clientStarId = [SELECT SER_CClient__c FROM Account WHERE id =:recordId];
        }
        
         final List<GDT_Rep_Analiticos__c> repAn = retrieveReports(clientStarId.SER_CClient__c);
        
        
        
         acc = retrieveaccount(repAn, recordId);
         final Account account= acc == null ? null : acc[0];
        
       
        for(GDT_Rep_Analiticos__c a:repAn) {
 		 
            String urlaux = a.gf_first_part_fix_url_desc__c  ;
                if(account != null && a.gf_first_part_var_url_desc__c != null) {
                    urlaux += String.valueOf(account.get(a.gf_first_part_var_url_desc__c))  ;
                }
          
            	if(account != null && a.gf_second_part_var_url_desc__c != null) {
                    urlaux += String.valueOf(account.get(a.gf_second_part_var_url_desc__c))  ;
                }
            
            	if( a.gf_second_part_fix_url_desc__c != null) {
                    urlaux += a.gf_second_part_fix_url_desc__c  ;
                }
                        
            system.debug(urlaux);
                	
               mapa.put(a.Name,urlaux); 
                
        }
        
            return mapa;
        
    }
    
/*
* retrieveReports
* Method que devuelve los valores de los informes seleccionados
* @author Ander Ercilla
*/   
    public static List<GDT_Rep_Analiticos__c> retrieveReports(String cclient) {
        
        string clientRt = 'Ficha de cliente';//NOSONAR
        string groupRt = 'Ficha de grupo';//NOSONAR
        string bothRt = 'Ficha de grupo y Ficha de cliente';//NOSONAR
        String rep = 'SELECT Name,gf_first_part_fix_url_desc__c,gf_second_part_fix_url_desc__c,gf_first_part_var_url_desc__c, gf_second_part_var_url_desc__c, gf_record_id__c FROM GDT_Rep_Analiticos__c WHERE (gf_record_id__c = :' ;
        
        
        if(String.isBlank(cclient)) {
            rep +=   'groupRt' ;
            
        } else {
            rep +=   'clientRt' ;
        }
        rep +=   ' OR' ; 
        rep +=  ' gf_record_id__c' + ' =' + ':' + 'bothRt'+')'  ;  
        
        final List<GDT_Rep_Analiticos__c> repAn = Database.query(rep);
        return repAn;//NOSONAR
    }
/*
* retrieveaccount
* Method que devuelve los valores de los campos de account de cada cliente
* @author Ander Ercilla
*/     
    public static List<Account> retrieveaccount (List<GDT_Rep_Analiticos__c> repAn, string recordId) {
        
        String queryAccFieldPre = 'SELECT ';
        
        for(GDT_Rep_Analiticos__c a:repAn) {
            
            if(a.gf_first_part_var_url_desc__c != null && !queryAccFieldPre.contains(a.gf_first_part_var_url_desc__c)) {
                queryAccFieldPre += a.gf_first_part_var_url_desc__c + ',' ;
            }
            	system.debug(queryAccFieldPre);
            	
            	system.debug(a.gf_second_part_var_url_desc__c);
            
            if(a.gf_second_part_var_url_desc__c != null && !queryAccFieldPre.contains(a.gf_second_part_var_url_desc__c)) {
                queryAccFieldPre += a.gf_second_part_var_url_desc__c + ',' ;
                system.debug(queryAccFieldPre);
                 
            }
        }
       
        
        String queryAccountField = queryAccFieldPre.removeEnd(',');
        
        queryAccountField += ' FROM Account WHERE Id =: recordId  LIMIT 1' ;
         system.debug(queryAccountField);
       System.debug('queryAccountField length'+queryAccountField.length());
        final integer acclenght = queryAccountField.length();
        if (acclenght > ACC_SIZE) {
        acc = Database.query(String.escapeSingleQuotes(queryAccountField));
        }
        return acc;//NOSONAR

    }
}