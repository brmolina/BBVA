/**
* ------------------------------------------------------------------------------------------------
* @Name     Arc_GBL_PersistanceMB_Locator
* @Author   berthaelena.tellez.contractor@bbva.com
* @Date     Created: 19/02/2020
* @Group    ARCE
* -----------------------------------------------------------------------------------------------
* @Description GBL class that implements Arc_Gen_PersistanceMB_Interface
* -----------------------------------------------------------------------------------------------
* @Changes
*
* |2020-02-19 berthaelena.tellez.contractor@bbva.com
*             Class creation.
* |2021-04-30 otiliaramona.veres.contractor@bbva.com
              Added an empty constructor method.
* |2021-05-04 otiliaramona.veres.contractor@bbva.com
              Added annotation '@testVIsible' to the empty constructor method.
* -----------------------------------------------------------------------------------------------
*/
public class Arc_GBL_PersistanceMB_Locator implements  Arc_Gen_PersistanceMB_Interface {
    /**
    *-------------------------------------------------------------------------------
    * @description Empty constructor method
    *-------------------------------------------------------------------------------
    *@author otiliaramona.veres.contractor@bbva.com
    *@Date   Created:2021-04-30
    */
    @TestVisible
    private Arc_GBL_PersistanceMB_Locator() { }
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
    public Static String createBureauTable (String idArce) {
        final String dataBureau = '{\\"id\\":\\" \\",\\"participantName\\":\\" \\",\\"operationDate\\":\\" \\",\\"preventionKeyId\\":\\" \\",\\"banksNumber\\":\\" \\",\\"outstandingAmounts\\":[{\\"disposedAmounts\\":[{\\"amount\\":\\" \\"}],\\"id\\":\\" \\",\\"amount\\":\\" \\"}]}';
        return dataBureau;
    }

    /**
    *-------------------------------------------------------------------------------
    * @description  Method that return the jason of finansial System
    --------------------------------------------------------------------------------
    * @author berthaelena.tellez.contractor@bbva.com
    * @date 2020-02-19
    * @param idArce identifier of arce
    * @param List<>
    * @return String jason financial system
    * @example createfiancialSystem(idArce, listObject)
    **/
    public static String createfinacialSystem(String idArce,List<sObject>listObject) {
        String jsonRet = '';
        jsonRet = '\\"financialSystem\\":{\\"paymentDelay\\":{\\"hasDelay\\":null, \\"comments\\": null},\\"alert\\":{\\"hasAlert\\":null,\\"preventionDescription\\":null,\\"warningOwnerDescription\\":null,\\"origin\\":null,\\"measure\\":null}}';
        return jsonRet;
    }

}