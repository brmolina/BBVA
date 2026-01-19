/**
* ------------------------------------------------------------------------------------------------
* @Name     Arc_Gen_PersistanceMB_Locator
* @Author   berthaelena.tellez.contractor@bbva.com
* @Date     Created: 19/02/2020
* @Group    ARCE
* -----------------------------------------------------------------------------------------------
* @Description Data class Arc_Gen_PersistanceMB_Locator
* -----------------------------------------------------------------------------------------------
* @Changes
*
* |2020-02-19 berthaelena.tellez.contractor@bbva.com
*             Class creation.
* |2020-09-23 saimassimilianno.jordana.contractor@bbva.com
*             Added arce. namespace to all classes that are now in the arce-dependencies package
* |2021-06-17 juanmanuel.perez.ortiz.contractor@bbva.com
*             Add empty constructor to avoid sonar major
* -----------------------------------------------------------------------------------------------
*/
public without sharing class Arc_Gen_PersistanceMB_Locator implements Arc_Gen_PersistanceMB_Interface {
    /**
    * ----------------------------------------------------------------------------------------------------
    * @Description Void Constructor to avoid warning in sonar qube
    * ----------------------------------------------------------------------------------------------------
    * @param void
    * @return void
    * @example Arc_Gen_PersistanceMB_Locator service = new Arc_Gen_PersistanceMB_Locator()
    * ----------------------------------------------------------------------------------------------------
    **/
    @TestVisible
    private Arc_Gen_PersistanceMB_Locator() {

    }
    /**
    *-------------------------------------------------------------------------------
    * @description  Method that return the jason of bureau table
    --------------------------------------------------------------------------------
    * @author berthaelena.tellez.contractor@bbva.com
    * @date 2020-02-19
    * @param idArce identifier of arce
    * @return String jason bureau table
    * @example createBureauTable(idArce)
    **/
    public static String createBureauTable(String idArce) {
        final String classLocator = getClassLocalePersistanceMB();
        String jsonTabBureau = '';
        final System.Type objType = Type.forName(classLocator);
        try {
            final Arc_Gen_PersistanceMB_Interface classLocatorPerMB = (Arc_Gen_PersistanceMB_Interface)objType.newInstance();
            jsonTabBureau = classLocatorPerMB.createBureauTable(idArce);
        } catch(Exception ex) {
            System.debug(ex.getMessage());
        }
        return jsonTabBureau;
    }
    /**
    *-------------------------------------------------------------------------------
    * @description  Method that return the jason of financial system
    --------------------------------------------------------------------------------
    * @author berthaelena.tellez.contractor@bbva.com
    * @date 2020-02-19
    * @param idArce identifier of arce
    * @param listObject list object dinamic form
    * @return String jason finacial system
    * @example createfinacialSystem(idArce, listObject)
    **/
    public static String createfinacialSystem(String idArce, List<sObject> listObject) {
        String classLocator = getClassLocalePersistanceMB();
        String jsonfinSystem = '';
        System.Type objType = Type.forName(classLocator);
        try {
            Arc_Gen_PersistanceMB_Interface classLocatorPerMB = (Arc_Gen_PersistanceMB_Interface)objType.newInstance();
            jsonfinSystem = classLocatorPerMB.createfinacialSystem(idArce, listObject);
        } catch(Exception ex) {
            System.debug(ex.getMessage());
        }
        return jsonfinSystem;
    }
    /**
    * ---------------------------------------------------------------------------------------------------
    * @Description - Method to find the name class from the metadata config
    * ---------------------------------------------------------------------------------------------------
    * @Author   berthaelena.tellez.contractor@bbva.com
    * @Date     Created: 2020-02-19
    * @return   String with the name of the class
    * @example getClassLocalePersistanceMB()
    * ---------------------------------------------------------------------------------------------------
    **/
    private static String getClassLocalePersistanceMB() {
        String finRes = '';
        final List<arce__Arce_Config__mdt> lstConfig = [SELECT Id, arce__Config_Name__c, arce__Value1__c FROM arce__Arce_Config__mdt WHERE arce__Config_Name__c = 'PersistanceMBInterface'];
        if(!lstConfig.isEmpty()) {
            finRes = lstConfig.get(0).arce__Value1__c;
        }
        return finRes;
    }
}