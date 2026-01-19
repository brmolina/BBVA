/***
*   @author: GlobalDesktop
*   @Class: DES_Popup_Custom_newContactController
*   @Versions:
        v1 - 2019/11/07 - Initial version
**/
public with sharing class DES_Popup_Custom_newContactController {
	/* pattern */
    private static DES_Popup_Custom_newContactController instance;

	/**
	* @author Global Desktop
	* @description Constructor de la clase
	*/
	private DES_Popup_Custom_newContactController() {
		system.debug('Constructor');
	}

    /**
	* @author Global Desktop
	* @description Constructor
	*/
    public static DES_Popup_Custom_newContactController getInstance() { //NOSONAR
        if(instance == null) {
            instance = new DES_Popup_Custom_newContactController();
        }
        return instance;
    }

    /**
    * @author Global Desktop
    * Description: currentDomain
    */
    @AuraEnabled
	public static String currentDomain() {
		try {
			String stringReturn;
			System.debug('::::URL.getOrgDomainURL().toExternalForm() : ' + URL.getOrgDomainURL().toExternalForm());
			if(URL.getOrgDomainURL().toExternalForm().contains('.cs')) {
				stringReturn = URL.getOrgDomainURL().toExternalForm().split('.cs')[0];
			} else {
				stringReturn = URL.getOrgDomainURL().toExternalForm().split('.my')[0];
			}
			return stringReturn;
		} catch(Exception exc) {
			throw new AuraHandledException(Label.DES_Error + exc);
		}
	}
}