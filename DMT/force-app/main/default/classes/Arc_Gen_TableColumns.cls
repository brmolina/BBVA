/**
* ------------------------------------------------------------------------------------------------
* @Name     Arc_Gen_TableColumns
* @Author   Mario Humberto Ramirez Lio  mariohumberto.ramirez.contractor@bbva.com
* @Date     Created: 2019-06-20
* @Group    ARCE
* ------------------------------------------------------------------------------------------------
* @Description Global wrapper that contain all the information to create columns in tables
* ------------------------------------------------------------------------------------------------
* @Changes
*
* |2019-06-20 mariohumberto.ramirez.contractor@bbva.com
*             Class creation.
* |2019-07-26 mariohumberto.ramirez.contractor@bbva.com
*             Add new param "cellAttributes"
* |2019-07-30 mariohumberto.ramirez.contractor@bbva.com
*             Add new param "editable"
* -----------------------------------------------------------------------------------------------
**/
global class Arc_Gen_TableColumns {
    /**
    * @Description: String with the record type
    */
    @AuraEnabled public String type {get;set;}
    /**
    * @Description: String with the field name in the policie table
    */
    @AuraEnabled public String fieldName {get;set;}
    /**
    * @Description: String with the label in the policie table
    */
    @AuraEnabled public String label {get;set;}
    /**
    * @Description: Integer with the initial width value
    */
    @AuraEnabled public Integer initialWidth {get;set;}
    /**
    * @Description: Map with the cellAttributes values
    */
    @AuraEnabled public Map<String,String> cellAttributes {get;set;}
    /**
    * @Description: Map with the typeAttributes values
    */
    @AuraEnabled public Map<String,String> typeAttributes {get;set;}
    /**
    * @Description: Boolean to know if the column is editable
    */
    @AuraEnabled public Boolean editable {get;set;}

    /**
    * @Description: public contstructor
    */
    public Arc_Gen_TableColumns(){}

    /**
    * @Description: public contstructor with map parameter
    */
    public Arc_Gen_TableColumns(Map<String,String> mapValues){
        Map<String,String> attributes = new Map<String,String>();
        attributes.put('alignment','center');
        for(String keyMap : mapValues.keySet()){
            switch on keyMap {
                when 'type' {
                    type = mapValues.get(keyMap);
                }
                when 'fieldName' {
                    fieldName = mapValues.get(keyMap);
                }
                when 'label' {
                    label = mapValues.get(keyMap);
                }
                when 'initialWidth' {
                    initialWidth = Integer.valueOf(mapValues.get(keyMap));
                }
            }
        }
        cellAttributes = attributes;
    }

}