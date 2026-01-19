/**
* GDT_DWP_Selector_FormularioReportes
* Clase controladora del formulario de creación de registros de reportes analíticos
* @author Ander Ercilla
*/
public with sharing class GDT_DWP_Selector_FormularioReportes {//NOSONAR
/**
* getCampos
* Método que devuelve los campos de Account
* @author Ander Ercilla
*/  
    @AuraEnabled
    public static Map<String,String> getCampos() {//NOSONAR
        
        Final Schema.DescribeSObjectResult oppDescribe = Account.sObjectType.getDescribe();
        Final Map<String, Schema.SObjectField> accountFields = oppDescribe.fields.getMap();
        Final Map<String,String> mapaCampos = new Map<String,String>();
        for(String s:accountFields.keySet()) {
            Final SObjectField  metadatosCampo = accountFields.get(s);
            Final DescribeFieldResult selectedField = metadatosCampo.getDescribe();
            
          
                mapaCampos.put(selectedField.getName(),selectedField.getLabel());
            
        }
        
        return mapaCampos;
    }
   
/**
* createNewReport
* Método que inserta los registros informados en el formulario de creación de reportes
* @author Ander Ercilla
*/    
@AuraEnabled
public static void createNewReport(String parameters) {
    Final Map<String,Object> mapJson = (Map<String,Object>) JSON.deserializeUntyped(parameters);
    String url1 = (String)mapJson.get('url1');//NOSONAR
    String url2 = (String)mapJson.get('url2');//NOSONAR
    String cliente1 = (String)mapJson.get('cliente1');//NOSONAR
    String cliente2 = (String)mapJson.get('cliente2');//NOSONAR
    String rtCliente = (String)mapJson.get('rtCliente');//NOSONAR
    String name = (String)mapJson.get('name');//NOSONAR
   if (Schema.sObjectType.GDT_Rep_Analiticos__c.isCreateable()) {
   insert new  GDT_Rep_Analiticos__c(gf_first_part_fix_url_desc__c = url1 ,
    gf_second_part_fix_url_desc__c = url2, gf_first_part_var_url_desc__c = cliente1, Name = name, gf_second_part_var_url_desc__c = cliente2, gf_record_id__c = rtCliente );
   }
}
 
    

}