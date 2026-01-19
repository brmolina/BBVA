/**
* ------------------------------------------------------------------------------------------------
* @Name     Arc_Gen_AlphaCode_Interface
* @Author   antonio.perez.hernandez.contractor@bbva.com
* @Date     Created: 14/03/2023
* -----------------------------------------------------------------------------------------------
* @Description Interface to be implemented by the logic used to retrieve the alfa code
* -----------------------------------------------------------------------------------------------
* @Changes
* |13-02-2024 antonio.perez.hernandez.contractor@bbva.com
*             Class creation.
* -----------------------------------------------------------------------------------------------
*/
public interface Arc_Gen_AlphaCode_Interface {
    /**
    *---------------------------------------------------------------------------------------------------
    * @Description Method that perform the local logic to retrieve the alfa code from customerNumber
    *---------------------------------------------------------------------------------------------------
    * @Author antonio.perez.hernandez.contractor@bbva.com
    * @Date 13-02-2024
    * @param customerNumber - account number
    * @return String contains the operation result
    * @example System.Type objType = Type.forName('Name_of_the_local_class');
                final Arc_Gen_AlphaCode_Interface interfaceClass = (Arc_Gen_AlphaCode_Interface)objType.newInstance();
                interfaceClass.retrieveAlphaCode(customerNumber)
    * --------------------------------------------------------------------------------------------------
    **/
    String retrieveAlphaCode(String customerNumber);
}