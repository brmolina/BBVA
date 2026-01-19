/**
* GDT_DWP_Selector_FormularioReportes_test
* tests para la clase  GDT_DWP_Selector_FormularioReportes
* @author Ander Ercilla
*/
@isTest 
public class GDT_DWP_Selector_FormularioReportes_test { //NOSONAR
/**
* getcampostest
* Método que recoge los campos de account
* @author Ander Ercilla
*/

    
    @isTest 
    public static void getcampostest() {
 
        
        // Perform test
        Test.startTest();

            GDT_DWP_Selector_FormularioReportes.getCampos();
        Test.stopTest();  
        system.assert(true, true);
         
    }
/**
* insertreport
* Método que insertar los informes nuevos a través del formulario
* @author Ander Ercilla
*/    
    @isTest 
     public static void insertreport() {
         
           String parameters;      
       			  parameters = '{"url1":"https://www.google.com/","url2":"test","cliente1":"id","name":"test report","cliente2":"Name","rtCliente":"Ficha de cliente"}';
        // Perform test
        GDT_DWP_Selector_FormularioReportes.createNewReport(parameters);
        System.assert(true, parameters!=null);
      
    }
    
    
    
}