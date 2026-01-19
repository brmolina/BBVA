/***
*   @author: GlobalDesktop
*   @Class: DES_Choose_New_Contact_Form_Controller
*   @Description: Clase para recoger el perfil del usuario logado y redirigir a un formnulado u otro
					en función de este
*   @Versions:
        v1 - 2019/03/XX - Initial version
**/
public with sharing class DES_Choose_New_Contact_Form_Controller {

	/* pattern */
    private static DES_Choose_New_Contact_Form_Controller instance;

	/**
	* @author Global Desktop
	* @description Constructor de la clase
	*/
	private DES_Choose_New_Contact_Form_Controller() {
		system.debug('Constructor');
	}

    /**
	* @author Global Desktop
	* @description Constructor
	*/
    public static DES_Choose_New_Contact_Form_Controller getInstance() { //NOSONAR
        if(instance == null) {
            instance = new DES_Choose_New_Contact_Form_Controller();
        }
        return instance;
    }

	/**
	* @author Global Desktop
	* @description Recupera el perfil del usuario logado
	*/
    @AuraEnabled
    public static Boolean isDesktop() {
    	try {
	        final String profileName = [SELECT Name FROM Profile WHERE Id = :userInfo.getProfileId() LIMIT 1].Name;
	        return profileName.contains('Desktop');
    	} catch(Exception exc) {
			throw new AuraHandledException(Label.DES_Error + exc);
		}
    }
}