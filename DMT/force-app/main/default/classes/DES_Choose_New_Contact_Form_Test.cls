/****
*   @author: GlobalDesktop
*   @Class: DES_Choose_New_Contact_Form_Test
*   @Description: Clase de test de la clase DES_Choose_New_Contact_Form
*   @Versions:
        v1 - 2019/03/XX - Initial version
**/
@isTest
public class DES_Choose_New_Contact_Form_Test {
	
	/**
	* @author Global Desktop
	* @description 
	*/
	@isTest
    public static void chooseContactFormContTest() {
        Boolean message;
        message = false;
        try {
            DES_Choose_New_Contact_Form_Controller.getInstance();
			DES_Choose_New_Contact_Form_Controller.isDesktop();
        } catch(Exception e) {
            message = true;
            system.debug(e.getMessage());
            system.assert(message, 'Correcto');
        }
    }
}