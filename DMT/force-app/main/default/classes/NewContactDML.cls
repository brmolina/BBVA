/***
*   @author: GlobalDesktop
*   @Class: UpdateContactDML
*   @Description: Realiza las operacones DML sobre contacto
*   @Versions:
        v1 - 2019/03/XX - Initial version
**/
public without sharing class NewContactDML {

	/* pattern */
    private static NewContactDML instance;

    /**
    * @author Global Desktop
    * @description Constructor de la clase
    */
    private  NewContactDML() {
    	system.debug('Constructor NewContactDML');
    }

    /**
	* @author Global Desktop
	* @description pattern
	*/
    public static NewContactDML getInstance() { //NOSONAR
        if(instance == null) {
            instance = new NewContactDML();
        }
        return instance;
    }

	/**
	* @author Global Desktop
	* @description Devuelve los contactos a insertar
	*/
    public static Database.SaveResult createContact(Contact contacto) {
        final Database.SaveResult result = Database.insert(contacto);
        System.debug('createContact:: ' + result);
        return result;
    }

	/**
	* @author Global Desktop
	* @description Devuelve los contactos a actualizaar
	*/
    // public static Database.SaveResult updateContactWithoutSharing(Contact contacto) {
    //     final Database.SaveResult result = Database.update(contacto);
    //     System.debug('updateContactWithoutSharing:: ' + result);
    //     return result;
    // }

}