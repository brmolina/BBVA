/**
* ____________________________________________________________________________
* Toolkit Utils
* Utils related to Toolkit Component classes
* ____________________________________________________________________________
* @author      Torcuato Tejada <torcuato.tejada.contractor@bbva.com>
* @modifiedBy
* @version     1.0
* @created     2021-08-23
* @modified
* @systemLayer 
* ____________________________________________________________________________
* @changes
*
* ____________________________________________________________________________
*/
public with sharing class CSTK_Utils {
    
    public CSTK_Utils() {

    }

    /**
    * @description Map sectors from Client
    * @param sector: sector from the client record
    * @param activity: activity from the client record
    * @param sectValues: Possible sector values from custom metadata json
    * @return String with the correct value of the sector to show on the toolkit record
    */
    public static String mapClientSector(String sector, String activity, List<CSTK_Client.ClientWrapper> sectValues) {
        String res;
        for (CSTK_Client.ClientWrapper sectorInfo : sectValues) {
            if ((String.isBlank(sectorInfo.sector) || sector == sectorInfo.sector) && (String.isBlank(sectorInfo.actividad) || activity == sectorInfo.actividad)) {
                res = sectorInfo.result;
                break;
            } else {
                res = Label.cstk.generic_Sector;
            }
        }
        return res;
    }

    /**
    * @description Map sectors from Arce
    * @param coreAsset: core asset value from Arce
    * @param sector: sector from Arce
    * @param subsector: subsector from Arce
    * @param activity: activity from Arce
    * @param sectValues: Possible sector values from custom metadata json
    * @return String with the correst value of the sector to show on the toolkit record
    */
    public static String mapArceSector(String sector, String subsector, String activity, List<CSTK_Client.ArceWrapper> sectValues) {
        String res;
        for(CSTK_Client.ArceWrapper sectorInfo : sectValues) {
            if ((String.isBlank(sectorInfo.sector) || sector == sectorInfo.sector) && (String.isBlank(sectorInfo.subsector) || subsector == sectorInfo.subsector) && (String.isBlank(sectorInfo.actividad) || activity == sectorInfo.actividad)) {
                res = sectorInfo.result;
                break;
            } else {
                res = Label.cstk.generic_Sector;
            }
        }

        return res;
    }

    /**
    * @description Calculate Sectors
    * @param actList: List<CSTK_Client.ActivityListWrapper>
    * @return CSTK_Client.ActivityListWrapper Wrapper with the sector and the percents realted to each one.
    */
    public static CSTK_Client.ActivityListWrapper getSectorValues(List<CSTK_Client.ActivityListWrapper> actList){
    	//Map para guardar actividades a agrupar.
       	Map<String, Decimal> groupByActivity = new Map<String, Decimal>();
        //Contador para saber si el total de porcentaje es igual o menor a 100%
        Decimal countPerc = 0;

        //Iteración sobre el wrapper de actividades para rellenar los mapas con las actividades y sus porcentajes agrupados.
        for (CSTK_Client.ActivityListWrapper act : actList) {
            Decimal porcentajeDecimal = Decimal.valueOf(act.percent);
            countPerc += porcentajeDecimal;
            if (groupByActivity.containsKey(act.activity)) {
                groupByActivity.put(act.activity, groupByActivity.get(act.activity) + porcentajeDecimal);
            } else {
                groupByActivity.put(act.activity, porcentajeDecimal);
            }
        }
        
        //Lista para ordenar por porcentaje
        List<CSTK_Client.ActivityListWrapper> actListWrap = new List<CSTK_Client.ActivityListWrapper>();
        Decimal countGeneric = 0; // Acumulador para "Generic" cuando HTR es menor a 15%
        //Iteramos la lista para rellenarla con el mapa de los nombres agrupados y los porcentajes.
        for (String act : groupByActivity.keySet()) {
            Decimal totalPercent = groupByActivity.get(act);
            //Si count perc es menor 100, regularizamos.
            if (countPerc < 100){
                totalpercent = (totalPercent * 100 / countPerc).setScale(2);
            }
            if (totalPercent < 15 || act == 'Generic') {
                // Si el porcentaje es menor al 15% o es generic, sumar a "Generic"
                countGeneric += totalPercent;
            } else {
                // Sector con porcentaje >= 15 se agregan al agrupado directamente
                CSTK_Client.ActivityListWrapper sectorSum = new CSTK_Client.ActivityListWrapper();
                sectorSum.activity = act;
                sectorSum.percent = String.valueOf(totalPercent);
                actListWrap.add(sectorSum);
            }
        }
        // Agregar "Generic" si tiene porcentaje acumulado
        if (countGeneric >= 15) {
            CSTK_Client.ActivityListWrapper genSum = new CSTK_Client.ActivityListWrapper();
            genSum.activity = 'Generic';
            genSum.percent = String.valueOf(countGeneric);
            actListWrap.add(genSum);
        }
        
        //Ordenar lista por porcentajes de mayor a menor.
        actListWrap.sort(new sectorWrapCompare());

        CSTK_Client.ActivityListWrapper result = new CSTK_Client.ActivityListWrapper();
        // Si no hay ningun sector > 80%, revisamos para eliminar sectores con porcentaje < 15%
        List<CSTK_Client.ActivityListWrapper> filteredList = new List<CSTK_Client.ActivityListWrapper>();
        for (CSTK_Client.ActivityListWrapper wrap : actListWrap) {
            Decimal percentage;
            if(countGeneric < 15 && countGeneric > 0){
                percentage = (Decimal.valueOf(wrap.percent) * 100 / (100 - countGeneric)).setScale(2);
            } else{
                percentage = Decimal.valueOf(wrap.percent);
            }
            if (percentage >= 80) {
                // Devolver una única Sector
				result.activity = wrap.activity;
                result.percent = String.valueOf(percentage);
                System.debug('***** Sectores: ' + result.activity);
        		System.debug('***** porcentajes: ' + result.percent);
                return result;
            }
            wrap.percent = String.valueOf(percentage);
            filteredList.add(wrap);
        }
        
        // Si la lista filtrada no está vacía, concatenar nombres y porcentajes con ';'
        String concatenatedNames = '';
        String concatenatedPercentages = '';
        if (!filteredList.isEmpty()) { 
           for (CSTK_Client.ActivityListWrapper wrap : filteredList) {
                concatenatedNames += wrap.activity + ';';
                concatenatedPercentages += wrap.percent + ';';
           }  
        }
        result.activity = concatenatedNames.removeEnd(';');
        result.percent = concatenatedPercentages.removeEnd(';');
        
        System.debug('***** Sectores: ' + result.activity);
        System.debug('***** porcentajes: ' + result.percent);
        
        return result;
    }

    /**
    * @description returns the order for CSTK_Client.ActivityListWrapper to sort the values
    * @return Integer
    */
    public class sectorWrapCompare implements Comparator<CSTK_Client.ActivityListWrapper> {
        public Integer compare(CSTK_Client.ActivityListWrapper a, CSTK_Client.ActivityListWrapper b) {
            // Convertir porcentaje a Decimal y ordenar de mayor a menor
            Decimal percentA = Decimal.valueOf(a.percent);
            Decimal percentB = Decimal.valueOf(b.percent);
            if (percentA > percentB) {
                return -1; // Orden descendente
            } else if (percentA < percentB) {
                return 1; // Orden descendente
            } else {
                return 0; // Son iguales
            }
        }
    }

    /**
    * @description returns the label and values of a picklist
    * @return List<Picklist_Wrapper> of the picklist values
    * @param String objName : API Name of the object MUST include namespace prefix
    * @param String fieldName : API Name of the picklist field MUST include namespace prefix
    */
    public static List<cstk.Picklist_Wrapper> picklistLabelandValue(String objName, String fieldName) {
        List<cstk.Picklist_Wrapper> picklistValues = new List<cstk.Picklist_Wrapper>(); //NOSONAR
        final String notDefined = 'Not Defined'; //NOSONAR
        List<Schema.PicklistEntry> entries = Schema.getGlobalDescribe().get(objName).getDescribe().fields.getMap().get(fieldName).getDescribe().getPicklistValues(); //NOSONAR
        for (Schema.PicklistEntry entry : entries) {
            if(entry.getLabel() != notDefined) {
                cstk.Picklist_Wrapper pick = new cstk.Picklist_Wrapper(); //NOSONAR
                pick.label = String.valueOf(entry.getLabel());
                pick.value = String.valueOf(entry.getValue());
                picklistValues.add(pick);
            }
        }
        return picklistValues;
    }

    /**
    * @description Sends emails
    * @param messagesList : list of SingleEmailMessages
    */
    public static void sendEmails(List<Messaging.SingleEmailMessage> messagesList) {
        final List<cstk.Exception_Wrapper> excWrapList = new List<cstk.Exception_Wrapper>();
        if (Limits.getEmailInvocations() < Limits.getLimitEmailInvocations()) {
            Messaging.SendEmailResult[] results = Messaging.sendEmail(messagesList, false);
            for (Messaging.SendEmailResult result : results) {
                if (result.isSuccess()) {
                    System.debug('The email was sent successfully.');
                } else {
                    for (Messaging.SendEmailError error : result.getErrors()) {
                        excWrapList.add(new cstk.Exception_Wrapper(null, 'CSTK_Utils', 'sendEmails', 'toolkit', null, error.getMessage() ));
                        System.debug('The email failed to send: ' + error.getMessage());
                    }
                }
            }
        } else {
            final String errorMessage = 'Limit of emails per transaction reached. Number of unsent emails: ' + messagesList.size();
            excWrapList.add(new cstk.Exception_Wrapper(null, 'CSTK_Utils', 'sendEmails', 'toolkit', null, errorMessage ));
            System.debug(errorMessage);
        }
        if(!excWrapList.isEmpty()){
            cstk.Utils.logException(excWrapList);
        }
    }
}