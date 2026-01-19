/**
* ------------------------------------------------------------------------------------------------
* @Name     Arc_Gen_JsonBuilder
* @Author   luisruben.quinto.munoz@bbva.com
* @Date     Created: 2019-07-12
* @Group    ARCE
* ------------------------------------------------------------------------------------------------
* @Description retrieve a JSON to build dynamics tables.
* ------------------------------------------------------------------------------------------------
* @Changes
*
* |2019-07-12 luisruben.quinto.munoz@bbva.com
*             Class creation.
* |2019-08-29 mariohumberto.ramirez.contractor@bbva.com
*             Added new param "apiNameObject".
* -----------------------------------------------------------------------------------------------
*/
global with sharing class Arc_Gen_JsonBuilder implements cmpw.GBL_ComponentWrapper_Interface {
  /**
  *-------------------------------------------------------------------------------
  * @Description retrieve financial statemnts formated to table
  *--------------------------------------------------------------------------------
  * @ Author luisruben.quinto.munoz@bbva.com
  * @ Date 2019-11-04
  * @ param recordId recordId of the account_has_analysis.
  * @ param jsonInput Json obtained from the component.
  * @ return JsonFinal returns the Json generated from the method.
  * @ example Arc_Gen_JsonBuilder.getComponents(recordId,jsonInput)
  *--------------------------------------------------------------------------------
  **/
  global String getComponents(Id recordId, String jsonInput){
    Map<String, Object> jsonMap = (Map<String, Object>)JSON.deserializeUntyped(jsonInput);
    String collectionType = String.valueOf(jsonMap.get('collectionType'));
    String apiNameObject = String.valueOF(jsonMap.get('apiNameObject'));
    Arc_Gen_Tables_controller tablesPresntation = new Arc_Gen_Tables_controller();
    String table = tablesPresntation.getTableJsonComponent(collectionType,recordId);
    Arc_Gen_Charts_controller chartsPresntation = new Arc_Gen_Charts_controller();
    String charts = chartsPresntation.getChartsJsonComponent(collectionType,recordId);
    String buttons = Arc_Gen_Buttons_controller.getButtonsJsonComponent(collectionType,recordId,apiNameObject);
    String jsonFinal = '{"orientation":"horizontal",'+
                        '"components":['+
                        table+
                        charts+
                        buttons+
                        ']'+
                        '}';
    return jsonFinal;
  }
}