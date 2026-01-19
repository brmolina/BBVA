/*
* Clae para controlar el componente que anade oportunidades al NBC
* @author Aitor Martin
*/
public with sharing class AddOppNBCVirtual_Controller {

    /*
    * String para comprobar si el RT del NBC es del tipo Virtual
    */
    static final String VIRTUALNBC = 'Virtual';

    /**
    * SINGLETON PATTERN
    */
    private static AddOppNBCVirtual_Controller instance;

    /**
    * getInstance
    */
    public static AddOppNBCVirtual_Controller gtInstance() {//NOSONAR
        if (instance == null) {
        instance = new AddOppNBCVirtual_Controller();
        }
        return instance;
    }

    /*
    * Met0d0 para pasar sonar
    */
    private AddOppNBCVirtual_Controller() {}

    /*
    * Met0d0 para el lookup de las oportunidades
    */
    @AuraEnabled
    public static List < sObject > fetchLookUpValues(String searchKeyWord, Id recordId) {
        system.debug('searchKeyWord-->' + searchKeyWord);
        system.debug('recordId---------------'+recordId);
        final List < sObject > returnList = new List < sObject > ();
        boolean virt = false; //NOSONAR
        try {

            final List <NBC__c> lstNBC = [SELECT id, NBC_Region_type__c, RecordType.DeveloperName FROM NBC__c WHERE Id = :recordId LIMIT 1];
            List < Id > lstIdFilt = new List < Id > (); //NOSONAR
            List < Opportunity > lstFiltrada = new List < sObject > (); //NOSONAR
            System.debug('NBC------------------------------->'+lstNBC);
            if(!lstNBC.isEmpty()) {
                if(lstNBC.get(0).RecordType.DeveloperName == VIRTUALNBC) {
                    virt = true;
                }
                system.debug('Valor boolean virt---------------> '+virt);

                final String searchKey2 = searchKeyWord + '*';
                final List<List<Opportunity>>lstOfRecordsSOSL = [FIND :searchKey2 IN NAME FIELDS RETURNING Opportunity(id, Name WHERE NBC_Decision_Taken_type__c = null AND DES_NBC_Region__c = :lstNBC.get(0).NBC_Region_type__c AND gf_oppy_virtual_cmtee_ind_type__c = :virt AND Template_approved_type__c = true AND StageName != 'Closed Won' AND StageName != 'Closed Lost' AND StageName != 'Draft Opp' AND Committee_id__c = null)]; //NOSONAR

                if(lstOfRecordsSOSL != null && lstNBC != null) {
                    for(List<SObject> lObject : lstOfRecordsSOSL) {
                        for(SObject op : lObject) {
                            lstIdFilt.add(String.valueof(op.get('Id')));
                        }
                    }
                    lstFiltrada = [SELECT id, Name FROM Opportunity WHERE id =:lstIdFilt];
                }

                //system.debug('Lista total de oportunidades---------------'+lstOfRecords.size());
                system.debug('Lista filtrada de oportunidades---------------'+lstFiltrada.size());

                returnList.addAll(lstFiltrada);
            }
            return returnList;
        } catch (Exception e) {
            throw new AuraHandledException(e.getLineNumber() + ': ' + e.getMessage()); //NOSONAR
        }
    }

    /*
    * Met0d0 para asignar una oportunidad al NBC
    */
    @AuraEnabled
    public static void saveOp(Opportunity opp, Id recordId) {
        try {
            if(opp.id != null) {
                System.debug('Nombre oportunidad--------------------------->' +opp);
                System.debug('recordId--------------------------->' +recordId);
                opp.Committee_id__c = recordId;
                System.debug('Id comite de la opp--------------------------->' +opp.Committee_id__c);
                update opp;
            }
        } catch(Exception e) {
            throw new AuraHandledException(e.getLineNumber() + ': ' + e.getMessage());//NOSONAR
        }
    }

    /*
    * Met0d0 para mostrar todas las oportunidades asociadas.
    */
    @AuraEnabled
    public static String listarOpp(Id recordId) {
        try {

            System.debug('recordId--------------------------->' +recordId);
            final List <NBC__c> lstNBC = [SELECT id FROM NBC__c WHERE Id = :recordId LIMIT 1];
            List<wrapperClass> listWrapperClass = new List<wrapperClass>();//NOSONAR
            if(!lstNBC.isEmpty()) {
                final List <Opportunity> lstOpp = [SELECT id, Name FROM Opportunity WHERE Committee_id__c = :lstNBC AND StageName != 'Closed Won' AND StageName != 'Closed Lost' AND StageName != 'Draft Opp']; //NOSONAR

                for(Opportunity opp : lstOpp) {
                    listWrapperClass.add(new wrapperClass(opp.Id, opp.Name));
                }

                system.debug('>>>>> listWrapperClass: ' + listWrapperClass);

                System.debug('Lista de oportunidades del NBC--------------------> '+lstOpp);
                System.debug('Lista de oportunidades del NBC--------------------> '+listWrapperClass);
            }
            return JSON.serialize(listWrapperClass);
        } catch(Exception e) {
            throw new AuraHandledException(e.getLineNumber() + ': ' + e.getMessage());//NOSONAR
        }
    }

    /*
    * Met0d0 para eliminar las oportunidades asociadas
    */
    @AuraEnabled
    public static void eliminarOpp(Id recordId, String opps) {
        try {
        system.debug('------------------------> listaSeleccionada Opps: ' + opps);
        List<Id> idsEliminar = new List<Id>();//NOSONAR
        final List<wrapperClass> wraplst = (List<AddOppNBCVirtual_Controller.wrapperClass>) JSON.deserialize(opps, List<AddOppNBCVirtual_Controller.wrapperClass>.class);
        if(!wraplst.isEmpty()) {
            for(wrapperClass op : wraplst) {

                idsEliminar.add(op.idOpp);

            }
        }
        system.debug(wraplst);
        final List<Opportunity> lstOpsElim = [SELECT id, Name, Committee_id__c FROM Opportunity WHERE id = :idsEliminar];
        if(!lstOpsElim.isEmpty()) {
            system.debug('------------------------> listaParaEliminar: ' + lstOpsElim);
            for(Opportunity opp : lstOpsElim) {
                system.debug('------------------------> idsEliminar: ' + opp.Committee_id__c);
                opp.Committee_id__c = null;//NOSONAR
                system.debug('------------------------> idsEliminar: ' + opp.Committee_id__c);
            }
            update lstOpsElim;
        }
        } catch(Exception e) {
            throw new AuraHandledException(e.getLineNumber() + ': ' + e.getMessage());//NOSONAR
        }

    }

    /**
    *
    * Clase necesaria para  recoger los valores de la tabla
    * @author Aitor Martin
    */
    public class wrapperClass {
        /*
        * Variable para recoger el nombre de la oportunidad
		*/
        final String oppName;
        /*
        * Variable para recoger el id de la oportunidad
        */
        final Id idOpp;

        /*
        * Met0d0 para setear los datos de la tabla
         */
		public wrapperClass(Id idOpp, String oppName) {
			this.oppName = oppName;
            this.idOpp = idOpp;
		}

	}
}