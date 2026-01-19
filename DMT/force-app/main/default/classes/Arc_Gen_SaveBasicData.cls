/**
* ------------------------------------------------------------------------------------------------
* @Name     Arc_Gen_SaveBasicData
* @Author   Ricardo Almanza Angeles
* @Date     Created: 15/01/2020
* @Group    ARCE
* -----------------------------------------------------------------------------------------------
* @Description Class that manages dyanmic form save for Basic Data.
* -----------------------------------------------------------------------------------------------
* @Changes
*
* |2019-01-15 Ricardo Almanza Angeles
*             Class creation.
* |2020-07-13 Ricardo Almanza Angeles
*             Modification for save method for manual triage.
* |2020-08-11 javier.soto.carrascosa@bbva.com
*             Update sector field
* |2020-03-12 juanpedro.benito.contractor@bbva.com
*             Change arce__sector_desc__c for arce__sector_id__c and arce__subsector_desc__c for arce__subsector_id__c
* |2021-06-17 juanignacio.hita.contractor@bbva.com
*             Rollback last commit  (PR: 1231)
* -----------------------------------------------------------------------------------------------
*/
global class Arc_Gen_SaveBasicData implements dyfr.Save_Interface {
    /**
    * -----------------------------------------------------------------------------------------------
    * @Description Wrapper that contain all the information to call basic data service
    * -----------------------------------------------------------------------------------------------
    * @param void
    * @return void
    * @example DataBasic data = new DataBasic()
    * -----------------------------------------------------------------------------------------------
    **/
    public class DataBasic{
        /**
        * @Description: String with an identifier of dinamic form
        */
        public String id {get; set;}
        /**
        * @Description: String with a value of 1 or 2 to know if it is a group or Subsiadiary
        */
        public String grupo {get; set;}
        /**
        * @Description: String with a value of 1 or 2 to know if it is a refinanced customer
        */
        public String refinanced {get; set;}
        /**
        * @Description: String with an description of refinanced custmer
        */
        public String refinanceDesc {get; set;}
        /**
        * @Description: String that saves the sector Custumer
        */
        public String sector {get; set;}
        /**
        * @Description: String that saves the sub sector Custumer
        */
        public String subSector {get; set;}
        /**
        * @Description: String that saves the Ativity Custumer
        */
        public String actividad {get; set;}
        /**
        * @Description: String that saves the template Custumer
        */
        public String template {get; set;}
        /**
        * @Description: String that saves the employees numbers
        */
        public String empleados {get; set;}
    }

    /**
    * -----------------------------------------------------------------------------------------------
    * @Description - Method that is responsible for invoking the classes to save the
      basic data information.
    * -----------------------------------------------------------------------------------------------
    * @Author   Bertha Elena Téllez Lira  berthaelena.tellez.contractor@bbva.com
    * @Date     Created: 23/01/2020
    * @param listObject - List of the account has analisys object
    * @return String with the execution message
    * @example save (listObject)
    * -----------------------------------------------------------------------------------------------
    **/
    public String save(List<sObject> listObject) {
        List<DataBasic> datEnv = new List<DataBasic>();
        Boolean succes = true;
        Final set<String> arcAcc;
        Final Map<String,sObject> idTemplateArc = new Map<String,sObject> ();
        if(!listObject.isEmpty()) {
            arcAcc = new Set<String>();
            for(sObject obj : listObject) {
                String accHasId = String.valueOf(obj.get('Id'));
                // Validate that the user has permission to edit the record
                // before saving.
                if (Arc_Gen_TabSet_service.getPermissionToEdit(accHasId) != 'true') {
                    throw new AuraHandledException(Label.Arc_Gen_Generic_NotAllowed);
                }
                arcAcc.add(accHasId);
                dataBasic objrR = new dataBasic();
                objrR.id = accHasId;
                objrR.grupo = String.valueOf(obj.get('arce__enterprise_group_type__c'));
                objrR.refinanced = String.valueOf(obj.get('arce__client_refinanced_type__c'));
                objrR.refinanceDesc = String.valueOf(obj.get('arce__client_refinanced_desc__c'));
                objrR.sector = String.valueOf(obj.get('arce__sector_desc__c'));
                objrR.subSector = String.valueOf(obj.get('arce__subsector_desc__c'));
                objrR.actividad = String.valueOf(obj.get('arce__economic_activity_sector_desc__c'));
                objrR.template = String.valueOf(obj.get('arce__rating_econ_sector_tmpl_id__c'));
                objrR.empleados = String.valueOf(obj.get('arce__employees_number__c'));
                datEnv.add(objrR);
                idTemplateArc.put(accHasId,obj);
            }
        }
        Boolean result = Arc_Gen_PersistenciaDB_Service.persistenceBD(new List<String>(arcAcc), datEnv);
        succes = Arc_Gen_PersistanceBR_Service.persistBR(new List<String>(arcAcc),listObject);
        return JSON.serialize(new arce.Arc_Gen_wrpSave(result&&succes,Label.Arc_Gen_Generic_ErrorSumPersBR,listObject));
    }

}