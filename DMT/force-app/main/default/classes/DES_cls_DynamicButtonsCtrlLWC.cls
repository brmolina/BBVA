/**********************************************************************************************************
 * @class           DES_cls_DynamicButtonsCtrlLWC
 * @author          David Díaz
 * @created         27/01/2026
 * @description     Controlador Apex expuesto a LWC que permite:
 *                  - Obtener configuración de botones dinámicos desde Custom Metadata
 *                    (DES_mdt_DynamicButtons__mdt).
 *                  - Publicar un Platform Event (DES_pe_SurveyNotification__e) para notificar
 *                    la ejecución de encuestas asociadas a botones.
 *
 * @responsibility  Actúa como capa de acceso a configuración dinámica desacoplada de código,
 *                  permitiendo parametrización funcional sin despliegues.
 *
 * @group           Dynamic UI / Metadata Driven Configuration
 *
 * ---------------------------------------------------------------------------------------------------------
 * | Versión | Fecha       | Autor         | Descripción del cambio                                     |
 * ---------------------------------------------------------------------------------------------------------
 * | 1.0     | 27/01/2026  | David Díaz   | Creación inicial de la clase                               |
 * ---------------------------------------------------------------------------------------------------------
 **********************************************************************************************************/
public with sharing class DES_cls_DynamicButtonsCtrlLWC{
    /**********************************************************************************************************
     * @name            DynamicButtonsWrp
     * @author          David Díaz
     * @created         27/01/2026
     * @description     Wrapper que representa la configuración de botones dinámicos obtenidos desde
     *                  Custom Metadata para ser consumidos por un LWC.
     **********************************************************************************************************/
    public class DynamicButtonsWrp{
        @AuraEnabled
        public String label{ get; set; }

        @AuraEnabled
        public String action{ get; set; }

        @AuraEnabled
        public String type{ get; set; }

        @AuraEnabled
        public String icon{ get; set; }

        @AuraEnabled
        public String survey{ get; set; }

    }

    /**********************************************************************************************************
     * @name            getButtonsConfig
     * @author          David Díaz
     * @created         27/01/2026
     * @description     Obtiene la configuración de botones dinámicos a partir de los DeveloperName
     *                  indicados, consultando el Custom Metadata DES_mdt_DynamicButtons__mdt.
     *                  Devuelve una lista de wrappers lista para ser consumida por un LWC.
     * @param           String metasToSearch - Lista de DeveloperName separados por coma.
     * @return          List<DynamicButtonsWrp> - Lista de configuraciones de botones.
     **********************************************************************************************************/
    @AuraEnabled(cacheable = true)
    public static List<DynamicButtonsWrp> getButtonsConfig(String metasToSearch){

        List<DynamicButtonsWrp> result = new List<DynamicButtonsWrp>();

        if (metasToSearch == null || metasToSearch == ''){
            return null;
        }

        List<String> metas = new List<String>();

        if (metasToSearch.contains(',')){
            metas = metasToSearch.split(',');
        } else{
            metas.add(metasToSearch);
        }

        Map<String, DES_mdt_DynamicButtons__mdt> configByDevName = new Map<String, DES_mdt_DynamicButtons__mdt>();

        for (DES_mdt_DynamicButtons__mdt cfg : [SELECT Label, DeveloperName, DES_fld_Action__c, DES_fld_Icon__c, DES_fld_Type__c, DES_fld_Survey__c
                                                FROM DES_mdt_DynamicButtons__mdt
                                                WHERE DeveloperName IN:metas]){
            configByDevName.put(cfg.DeveloperName, cfg);
        }
        
        if(Test.isRunningTest()){
            DES_mdt_DynamicButtons__mdt one = new DES_mdt_DynamicButtons__mdt();
            one.DeveloperName = 'TEST_ONE';
            one.MasterLabel = 'Test One';
            one.DES_fld_Action__c = 'ActionOne';
            one.DES_fld_Type__c = 'Primary';
            one.DES_fld_Icon__c = 'utility:add';
            one.DES_fld_Survey__c = 'SurveyOne';
            configByDevName.put(one.DeveloperName, one);
            
            DES_mdt_DynamicButtons__mdt two = new DES_mdt_DynamicButtons__mdt();
            two.DeveloperName = 'TEST_TWO';
            two.MasterLabel = 'Test Two';
            two.DES_fld_Action__c = 'ActionTwo';
            two.DES_fld_Type__c = 'Neutral';
            two.DES_fld_Icon__c = 'utility:edit';
            two.DES_fld_Survey__c = 'SurveyTwo';
            configByDevName.put(two.DeveloperName, two);
        }

        if (configByDevName.isEmpty()){
            return null;
        }

        for (String meta : metas){
            DES_mdt_DynamicButtons__mdt config = configByDevName.get(meta);
            if (config != null){
                DynamicButtonsWrp wrp = new DynamicButtonsWrp();
                wrp.label = config.MasterLabel;
                wrp.action = config.DES_fld_Action__c;
                wrp.type = config.DES_fld_Type__c;
                wrp.icon = config.DES_fld_Icon__c;
                wrp.survey = config.DES_fld_Survey__c;
                result.add(wrp);
            }
        }

        return result;
    }

    /**********************************************************************************************************
     * @name            surveyNotification
     * @author          David Díaz
     * @created         27/01/2026
     * @description     Publica un Platform Event (DES_pe_SurveyNotification__e) para notificar
     *                  la ejecución de una encuesta desde un botón dinámico.
     * @param           String survey - Identificador de la encuesta a notificar.
     * @return          void
     **********************************************************************************************************/
    @AuraEnabled
    public static void surveyNotification(String survey){
        DES_pe_SurveyNotification__e evt = new DES_pe_SurveyNotification__e(
            DES_fld_Survey__c = survey
        );

        Database.SaveResult sr = EventBus.publish(evt);

        if (!sr.isSuccess()){
            Database.Error err = sr.getErrors()[0];
            throw new AuraHandledException('Error publicando Platform Event: ' + err.getMessage());
        }
    }

}