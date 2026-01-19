/**********************************************************************************
* @author       Global Desktop
* @date         28/01/2020
* @description  InttCmpApexController
**********************************************************************************/
public with sharing class InttCmpApexController {
	/**
        * @author Global Desktop
    * @description SINGLETON PATTERN
    */
    private static InttCmpApexController instance;

    /**
    * @author Global Desktop
    * @description getInstance
    */
    public static InttCmpApexController getInstance() { //NOSONAR
        if (instance == null) {
        instance = new InttCmpApexController();
        }
        return instance;
    }

    /*
    * Met0d0 para pasar sonar
    */
    private InttCmpApexController() {}

    /*
    *   Comentario sonar
    *
    */
    @AuraEnabled
    public static Boolean getPermission() {
        final String permission = 'Create_Initiative_Permission';
        System.debug(permission);
        final Boolean hasPermission = FeatureManagement.checkPermission('Create_Initiative_Permission');
        return hasPermission;
    }
}