/**********************************************************************************
* @author       SERBATIC (GRUPO VASS)   -   DSL
* @description  Clase que contiene los procesos a ejecutar cuando se insertan los registros de tipo DES_Booking__c.
* @Revision
**********************************************************************************/
public with sharing class DES_BookingTriggerHandler {

    private static CIB_User_Org__c userSettings = CIB_User_Org__c.getInstance();

    /*public static void limpiarDatos(List<DES_Booking__c> triggerOld){
       //if (userSettings.CIB_Is_Desktop__c){
            //Este mapa tendrá como key la concatenacion de la cuenta, el año y el tipo de producto y como value el importe que va sumando
            Set<Id> setIdAcc = new Set<Id>();
            //Recorro booking
            for(DES_Booking__c b : triggerOld){

                if(!setIdAcc.contains(b.DES_Client__c)){
                    setIdAcc.add(b.DES_Client__c);
                }

            }

			List<Account> listaCuentas;
            listaCuentas = new List<Account>([SELECT  Id,
													DES_GF_YOY__c,
													DES_GTB_YOY__c,
													DES_GM_YOY__c,
													DES_CF_YOY__c,
													DES_CO_YOY__c,
													DES_GL_YOY__c,
													DES_GTB_Revenues__c,
													DES_GM_Revenues__c,
													DES_GF_Revenues__c,
													DES_CF_Revenues__c,
													DES_CO_Revenues__c,
													DES_GL_Revenues__c
											FROM Account
											WHERE Id IN :setIdAcc
											AND (DES_GF_YOY__c != null
												OR DES_GTB_YOY__c != null
												OR DES_GM_YOY__c != null
												OR DES_CF_YOY__c != null
												OR DES_CO_YOY__c != null
												OR DES_GL_YOY__c != null
												OR DES_GTB_Revenues__c != null
												OR DES_GM_Revenues__c != null
												OR DES_GF_Revenues__c != null
												OR DES_CF_Revenues__c != null
												OR DES_CO_Revenues__c != null
												OR DES_GL_Revenues__c != null)
											FOR UPDATE
			]);
            system.debug('>>>>> ANTES LIMPIAR listaCuentas : ' + listaCuentas);
            if(!listaCuentas.isEmpty()){
	            for(Account acc : listaCuentas){
	                acc.DES_GF_YOY__c = null;
	                acc.DES_GTB_YOY__c = null;
	                acc.DES_GM_YOY__c = null;
	                acc.DES_CF_YOY__c = null;
	                acc.DES_CO_YOY__c = null;
	                acc.DES_GL_YOY__c = null;
	                acc.DES_GTB_Revenues__c = null;
	                acc.DES_GM_Revenues__c = null;
	                acc.DES_GF_Revenues__c = null;
	                acc.DES_CF_Revenues__c = null;
	                acc.DES_CO_Revenues__c = null;
	                acc.DES_GL_Revenues__c = null;
	            }
	            system.debug('>>>>> DESPUES LIMPIAR listaCuentas : ' + listaCuentas);
	            update listaCuentas;
            }

       //}//FIN SI ES USUARIO DESKTOP
    }*///limpiarDatos


    /*public static void calcularRevenues(List<DES_Booking__c> triggerNew){
        if (userSettings.CIB_Is_Desktop__c){
            //Este mapa tendrá como key la concatenacion de la cuenta, el año y el tipo de producto y como value el importe que va sumando
            Map<String, Double> mapRevenues = new Map<String, Double>();
            Double totalThisYear = 0.00;
            Double totalLastYear = 0.00;
            Set<Id> setIdAcc = new Set<Id>();
            Integer mesEngloba = 12;
            Integer anioCarga = system.today().year();
*/
/*
            //Recorro booking
            for(DES_Booking__c b : triggerNew){

                if(!setIdAcc.contains(b.DES_Client__c)){
                    setIdAcc.add(b.DES_Client__c);
                }

            }

            List<Account> listaCuentas = new List<Account>([SELECT  Id,
                                                                    DES_GF_YOY__c,
                                                                    DES_GTB_YOY__c,
                                                                    DES_GM_YOY__c,
                                                                    DES_CF_YOY__c,
                                                                    DES_GTB_Revenues__c,
                                                                    DES_GM_Revenues__c,
                                                                    DES_GF_Revenues__c,
                                                                    DES_CF_Revenues__c,
                                                                    DES_Revenue_Update_Engloba__c
                                                            FROM Account
                                                            WHERE Id IN :setIdAcc]);
*/
            //Recojo el mes en el que se han insertado los datos de Engloba
/*
            for(Account acc : listaCuentas){
                if(acc.DES_Revenue_Update_Engloba__c != null){
                    system.debug('>>>>>acc.DES_Revenue_Update_Engloba__c : ' + acc.DES_Revenue_Update_Engloba__c);
                    mesEngloba = Integer.valueOf(acc.DES_Revenue_Update_Engloba__c.substring(4,6));
                    anioCarga = Integer.valueOf(acc.DES_Revenue_Update_Engloba__c.substring(0,4));
                    break;
                }
            }

            system.debug('>>>>> MES ENGLOBA: ' + mesEngloba);
            system.debug('>>>>> AÑO ENGLOBA: ' + anioCarga);

            //RECOJO TODOS LOS BOOKINGS QUE TIENEN LAS CUENTAS, PARA CALCULAR TODOS LOS TOTALES DE NUEVO
            List<DES_Booking__c> listaBookCuentas = new List<DES_Booking__c>([
                                    SELECT  Id,
                                            DES_Type__c,
                                            DES_Year__c,
                                            DES_Client__c,
                                            DES_Revenues__c
                                    FROM DES_Booking__c
                                    WHERE DES_Client__c IN :setIdAcc]);

            //system.debug('>>>>> ANTES MERGE: listaBookCuentas : ' + listaBookCuentas);
            //system.debug('>>>>> ANTES MERGE: SIZE : ' + listaBookCuentas.size());

            //EL ADDALL NO HAY QUE HACERLO, YA QUE AL HACER LA QUERY YA SE HAN INSERTADO LOS DATOS (TRIGGER.AFTER), SI SE HACE EL ADDALL SE VAN A DUPLICAR LOS DATOS
            //listaBookCuentas.addAll(triggerNew);
*/
/*
            //system.debug('>>>>> DESPUES MERGE: listaBookCuentas : ' + listaBookCuentas);
            //system.debug('>>>>> DESPUES MERGE: SIZE : ' + listaBookCuentas.size());
            system.debug('>>>>> listaBookCuentas : ' + listaBookCuentas);
            for(DES_Booking__c b : listaBookCuentas){

                String key, key2;
                //Genero la key que esta formada por el id del cliente, el año y el tipo de producto
                //Si el año introducido es el año actual, se generan las claves con year y year-1
                if(anioCarga == Integer.valueOf(b.DES_Year__c)){
                    key = b.DES_Client__c + '_' + b.DES_Year__c + '' + b.DES_Type__c;
                    key2 = b.DES_Client__c + '_' + (Integer.valueOf(b.DES_Year__c)-1) + '' + b.DES_Type__c;
                }else if(anioCarga > Integer.valueOf(b.DES_Year__c)){//Si el año introducido es un año anterior al actual, se general las claves con year y year+1
                    //Integer yearDiff = anioCarga - b.DES_Year__c;
                    key = b.DES_Client__c + '_' + (Integer.valueOf(b.DES_Year__c)) + '' + b.DES_Type__c;
                    key2 = b.DES_Client__c + '_' + (Integer.valueOf(b.DES_Year__c) + 1) + '' + b.DES_Type__c;
                }

                //system.debug('>>>>> key : ' + key);
                //system.debug('>>>>> key2 : ' + key2);

                //Compruebo si no existe esa key, y si no existe creo la key en el mapa
                if(mapRevenues.get(key) == null){
                    mapRevenues.put(key,0.00);
                }
                if(mapRevenues.get(key2) == null){
                    mapRevenues.put(key2,0.00);
                }

                //Recojo el valor del mapa

                totalThisYear = mapRevenues.get(key);
                //system.debug('>>>>> ' + b.DES_Type__c +  ' ANTES SUMAR : totalThisYear : ' + totalThisYear);
                //le sumo el Revenue de el booking en el que estoy
                totalThisYear += b.DES_Revenues__c;
                //system.debug('>>>>> ' + b.DES_Type__c +  ' DESPUES SUMAR : totalThisYear : ' + totalThisYear);
                //Actualizo el mapa
                mapRevenues.put(key, totalThisYear);

*/
/*
                //Recojo el valor del mapa
                totalLastYear = mapRevenues.get(key2);
                system.debug('>>>>> ANTES SUMAR : totalLastYear : ' + totalLastYear);
                //le sumo el Revenue de el booking en el que estoy
                totalLastYear += b.DES_Revenues__c;
                system.debug('>>>>> DESPUES SUMAR : totalLastYear : ' + totalLastYear);
                //Actualizo el mapa
                mapRevenues.put(key2, totalLastYear);
            }

            //En el mapa mapRevenues ya tengo TODOS los datos
            //system.debug('>>>>> mapRevenues: ' + mapRevenues);


            List<String> listaFamilyProducts = getFamilyValuesIntoList();
            system.debug('>>>>> listaFamilyProducts : ' + listaFamilyProducts);
            List<Account> listAccUpd = new List<Account>();
            for(Account acc : listaCuentas){//Recorro la lista de cuentas y voy comprobando todo el mapa

                for(String str : listaFamilyProducts){
                    system.debug('\n\n>>>>> FAMILY: ' + str);
                    if(mapRevenues.get(acc.Id + '_' + anioCarga + str) != null){
                        system.debug('>>>>> mapRevenues POS: ' + mapRevenues.get(acc.Id + '_' + anioCarga + str));

                        if(str == 'GF'){
                            acc.DES_GF_Revenues__c = mapRevenues.get(acc.Id + '_' + anioCarga + str);
                            system.debug('>>>>> acc.DES_GF_Revenues__c: ' + acc.DES_GF_Revenues__c);
                        }else if(str ==  'GTB'){
                            acc.DES_GTB_Revenues__c = mapRevenues.get(acc.Id + '_' + anioCarga + str);
                            system.debug('>>>>> acc.DES_GTB_Revenues__c: ' + acc.DES_GTB_Revenues__c);
                        }else if(str == 'GM'){
                            acc.DES_GM_Revenues__c = mapRevenues.get(acc.Id + '_' + anioCarga + str);
                            system.debug('>>>>> acc.DES_GM_Revenues__c: ' + acc.DES_GM_Revenues__c);
                        }else if(str == 'CF'){
                            acc.DES_CF_Revenues__c = mapRevenues.get(acc.Id + '_' + anioCarga + str);
                            system.debug('>>>>> acc.DES_CF_Revenues__c: ' + acc.DES_CF_Revenues__c);
                        }else if(str == 'CO'){
                            acc.DES_CO_Revenues__c = mapRevenues.get(acc.Id + '_' + anioCarga + str);
                            system.debug('>>>>> acc.DES_CO_Revenues__c: ' + acc.DES_CO_Revenues__c);
                        }else if(str == 'GL'){
                            acc.DES_GL_Revenues__c = mapRevenues.get(acc.Id + '_' + anioCarga + str);
                            system.debug('>>>>> acc.DES_GL_Revenues__c: ' + acc.DES_GL_Revenues__c);
                        }
*/
/*
                        if( mapRevenues.get(acc.Id + '_' + (anioCarga-1) + str) != null
                            && mapRevenues.get(acc.Id + '_' + (anioCarga-1) + str) != 0){
                            system.debug('>>>>> mapRevenues : ' + mapRevenues.get(acc.Id + '_' + (anioCarga-1) + str));
                            system.debug('>>>>> mesEngloba : ' +  mesEngloba);
                            system.debug('>>>>> mesEngloba DIVISION : ' + (Double) mesEngloba/12);
                            system.debug('>>>>> NUMERADOR: ' + mapRevenues.get(acc.Id + '_' + anioCarga + str));
                            system.debug('>>>>> DENOMINADOR : ' + (mapRevenues.get(acc.Id + '_' + (anioCarga-1) + str) * (mesEngloba/12)));

                            if(str == 'GF'){
                                acc.DES_GF_YOY__c = (mapRevenues.get(acc.Id + '_' + anioCarga + str) / (mapRevenues.get(acc.Id + '_' + (anioCarga-1) + str) * ((Double)mesEngloba/12)));
                                system.debug('>>>>> : DES_GF_YOY__c' + acc.DES_GF_YOY__c);
                            }else if(str ==  'GTB'){
                                acc.DES_GTB_YOY__c = mapRevenues.get(acc.Id + '_' + anioCarga + str) / (mapRevenues.get(acc.Id + '_' + (anioCarga-1) + str) * ((Double)mesEngloba/12));
                                system.debug('>>>>> : DES_GTB_YOY__c' + acc.DES_GTB_YOY__c);
                            }else if(str == 'GM'){
                                acc.DES_GM_YOY__c = mapRevenues.get(acc.Id + '_' + anioCarga + str) / (mapRevenues.get(acc.Id + '_' + (anioCarga-1) + str) * ((Double)mesEngloba/12));
                                system.debug('>>>>> : DES_GM_YOY__c' + acc.DES_GM_YOY__c);
                            }else if(str == 'CF'){
                                acc.DES_CF_YOY__c = mapRevenues.get(acc.Id + '_' + anioCarga + str) / (mapRevenues.get(acc.Id + '_' + (anioCarga-1) + str) * ((Double)mesEngloba/12));
                                system.debug('>>>>> : DES_CF_YOY__c' + acc.DES_CF_YOY__c);
                            }else if(str == 'CO'){
                                acc.DES_CO_YOY__c = mapRevenues.get(acc.Id + '_' + anioCarga + str) / (mapRevenues.get(acc.Id + '_' + (anioCarga-1) + str) * ((Double)mesEngloba/12));
                                system.debug('>>>>> : DES_CO_YOY__c' + acc.DES_CO_YOY__c);
                            }else if(str == 'GL'){
                                acc.DES_GL_YOY__c = mapRevenues.get(acc.Id + '_' + anioCarga + str) / (mapRevenues.get(acc.Id + '_' + (anioCarga-1) + str) * ((Double)mesEngloba/12));
                                system.debug('>>>>> : DES_GL_YOY__c' + acc.DES_GL_YOY__c);
                            }
                         }
                    }
                }
                listAccUpd.add(acc);
            }
*/
/*
            try{
                system.debug('>>>>> listAccUpd : ' + listAccUpd);
                upsert listAccUpd;
            }catch(Exception e){
                system.debug('>>>>> EXCEPTION : ' + e);
            }
        }//FIN SI ES USUARIO DESKTOP
    }//FIN calcularRevenues
    */

     /*
      * @author Global Desktop
      * @Description identify Year Of Booking
      */
	public static void identifyYearOfBooking(List<DES_Booking__c> triggerNew) {
		if (userSettings.CIB_Is_Desktop__c) {
			//Set<Id> setIdsCuentasBook = new Set<Id>();
			//for(DES_Booking__c book : triggerNew){
			//	if(!setIdsCuentasBook.contains(book.DES_Client__c)){
			//		setIdsCuentasBook.add(book.DES_Client__c);
			//	}
			//}
			List<Account> listaCuentas;
            listaCuentas = new List<Account>([
									SELECT  Id, DES_Revenue_Update_Engloba__c
									FROM Account
									WHERE Id = :triggerNew.get(0).DES_Client__c
									//WHERE Id IN :setIdsCuentasBook
									ORDER BY DES_Revenue_Update_Engloba__c DESC NULLS LAST
									LIMIT 1]);
			decimal maxYear;
            maxYear = Integer.valueOf(listaCuentas[0].DES_Revenue_Update_Engloba__c.substring(0,4));
			for(DES_Booking__c b : triggerNew) {
				if(b.DES_Type__c == 'GF') {
					b.DES_Type__c = 'IBF';
				}
				if(b.DES_Year_Number__c == maxYear) {
					b.DES_Engloba_Load_Helper__c = '0';
				} else if(b.DES_Year_Number__c == maxYear-1) {
					b.DES_Engloba_Load_Helper__c = '1';
				} else if(b.DES_Year_Number__c == maxYear-2) {
					b.DES_Engloba_Load_Helper__c = '2';
				}
			}
            update triggerNew;
		}//fin si no es usuario desktop
	}//FIN identifyYearOfBooking


    /*private static List<String> getFamilyValuesIntoList(){
        List<String> pickListValuesList= new List<String>();
        Schema.DescribeFieldResult fieldResult = Product2.Family.getDescribe();
        List<Schema.PicklistEntry> ple = fieldResult.getPicklistValues();
        for( Schema.PicklistEntry pickListVal : ple){
            pickListValuesList.add(pickListVal.getLabel());
        }
        return pickListValuesList;
    }
    */
}