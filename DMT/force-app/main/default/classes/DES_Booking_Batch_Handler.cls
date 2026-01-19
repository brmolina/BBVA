/**********************************************************************************
* @author       Accenture
* @date
* @description  Manejador del Batch para el borrado de Bookings
* @Revision
                03/12/2018 Se añade la instrucción después de cada borrado masivo para vaciar la papelera de reciclaje
**********************************************************************************/
public with sharing class DES_Booking_Batch_Handler {

    private static CIB_User_Org__c userSettings = CIB_User_Org__c.getInstance();

	public static void alternativeTopCountries(List<Account> accList) {
		//final set<Id> accIds = new set<Id>();
		final map <Id,Account> accMap = new map<Id,Account>();

		for(Account acc : accList) {
            acc.cust_first_income_country_name__c = null;
            acc.cust_first_income_country_amount__c = 0;
            acc.cust_second_income_country_name__c = null;
            acc.cust_second_income_cntry_amount__c = 0;
            acc.cust_third_income_country_name__c = null;
            acc.cust_third_income_country_amount__c = 0;
            //accIds.add(acc.Id);
            accMap.put(acc.Id, acc);
        }
        AggregateResult[] groupedResults = [SELECT DES_Client__c,DES_Country__c, CurrencyIsoCode, SUM(DES_Revenues__c)suma
        									FROM DES_Booking__c
        									WHERE DES_Client__c IN :accMap.keySet()
        									GROUP BY DES_Country__c,DES_Client__c,CurrencyIsoCode
        									ORDER BY SUM(DES_Revenues__c) DESC ];

		for(AggregateResult ar : groupedResults) {
            Id idCliente = (Id)ar.get('DES_Client__c');
            if(accMap.get(idCliente) != null && (string.isBlank(accMap.get(idCliente).cust_first_income_country_name__c) || accMap.get(idCliente).cust_first_income_country_name__c == null)) {
                accMap.get(idCliente).cust_first_income_country_name__c = (String)ar.get('DES_Country__c') + ' ('+(Decimal)ar.get('suma')+' '+(String)ar.get('CurrencyIsoCode')+')';
                accMap.get(idCliente).cust_first_income_country_amount__c = (Decimal)ar.get('suma');
            } else if(accMap.get(idCliente) != null && (string.isBlank(accMap.get(idCliente).cust_second_income_country_name__c) || accMap.get(idCliente).cust_second_income_country_name__c == null)) {
                accMap.get(idCliente).cust_second_income_country_name__c = (String)ar.get('DES_Country__c') + ' ('+(Decimal)ar.get('suma')+' '+(String)ar.get('CurrencyIsoCode')+')';
                accMap.get(idCliente).cust_second_income_cntry_amount__c = (Decimal)ar.get('suma');
            } else if(accMap.get(idCliente) != null && (string.isBlank(accMap.get(idCliente).cust_third_income_country_name__c) || accMap.get(idCliente).cust_third_income_country_name__c == null)) {
                accMap.get(idCliente).cust_third_income_country_name__c = (String)ar.get('DES_Country__c') + ' ('+(Decimal)ar.get('suma')+' '+(String)ar.get('CurrencyIsoCode')+')';
                accMap.get(idCliente).cust_third_income_country_amount__c = (Decimal)ar.get('suma');
            }
        }
        update accMap.values();


	}


    // public static void calculateTopCountries(List<DES_Booking__c> bookingInputList) {

    //     set<Id> idsAccount = new set<Id>();
    //     for(DES_Booking__c i : bookingInputList) {
    //         idsAccount.add(i.DES_Client__c);
    //     }
    //     map<Id,Account> accMap = new map<Id,Account>([SELECT id, cust_first_income_country_name__c, cust_first_income_country_amount__c,
    //                                                 cust_second_income_country_name__c, cust_second_income_cntry_amount__c,
    //                                                 cust_third_income_country_name__c, cust_third_income_country_amount__c
    //                                                 FROM Account WHERE Id IN :idsAccount]);

    //     for(Account a : accMap.values()) {
    //         a.cust_first_income_country_name__c = null;
    //         a.cust_first_income_country_amount__c = 0;
    //         a.cust_second_income_country_name__c = null;
    //         a.cust_second_income_cntry_amount__c = 0;
    //         a.cust_third_income_country_name__c = null;
    //         a.cust_third_income_country_amount__c = 0;
    //     }
    //     update accMap.values();

    //     AggregateResult[] groupedResults = [SELECT DES_Client__c,DES_Country__c, CurrencyIsoCode, SUM(DES_Revenues__c)suma FROM DES_Booking__c WHERE DES_Client__c IN :idsAccount GROUP BY DES_Country__c,DES_Client__c,CurrencyIsoCode ORDER BY SUM(DES_Revenues__c) DESC ];
    //     system.debug('Valor de groupedResults: ' +groupedResults);
    //     for(AggregateResult ar : groupedResults) {
    //         system.debug('Valor de (Id)ar.get(DES_Client__c): ' +(Id)ar.get('DES_Client__c'));
    //         system.debug('Valor de (String)ar.get(DES_Country__c): ' +(String)ar.get('DES_Country__c'));
    //         system.debug('Valor de (Decimal)ar.get(suma): ' +(Decimal)ar.get('suma'));
    //         Id idCliente = (Id)ar.get('DES_Client__c');
    //         if(accMap.get(idCliente) != null && (string.isBlank(accMap.get(idCliente).cust_first_income_country_name__c) || accMap.get(idCliente).cust_first_income_country_name__c == null)) {
    //             accMap.get(idCliente).cust_first_income_country_name__c = (String)ar.get('DES_Country__c') + ' ('+(Decimal)ar.get('suma')+' '+(String)ar.get('CurrencyIsoCode')+')';
    //             accMap.get(idCliente).cust_first_income_country_amount__c = (Decimal)ar.get('suma');
    //         } else if(accMap.get(idCliente) != null && (string.isBlank(accMap.get(idCliente).cust_second_income_country_name__c) || accMap.get(idCliente).cust_second_income_country_name__c == null)) {
    //             accMap.get(idCliente).cust_second_income_country_name__c = (String)ar.get('DES_Country__c') + ' ('+(Decimal)ar.get('suma')+' '+(String)ar.get('CurrencyIsoCode')+')';
    //             accMap.get(idCliente).cust_second_income_cntry_amount__c = (Decimal)ar.get('suma');
    //         } else if(accMap.get(idCliente) != null && (string.isBlank(accMap.get(idCliente).cust_third_income_country_name__c) || accMap.get(idCliente).cust_third_income_country_name__c == null)) {
    //             accMap.get(idCliente).cust_third_income_country_name__c = (String)ar.get('DES_Country__c') + ' ('+(Decimal)ar.get('suma')+' '+(String)ar.get('CurrencyIsoCode')+')';
    //             accMap.get(idCliente).cust_third_income_country_amount__c = (Decimal)ar.get('suma');
    //         }
    //     }
    //     update accMap.values();

    // }

    // public static void calcularRevenues(List<DES_Booking__c> bookingInputList) {
    //     system.debug('>>>>> ENTRO EN CALCULAR REVENUES : ' + bookingInputList);
    //     //if (userSettings.CIB_Is_Desktop__c) {
    //         Set<Id> setIdsCuentasActualizadas = new Set<Id>();
    //         //Este mapa tendrá como key la concatenacion de la cuenta, el año y el tipo de producto y como value el importe que va sumando
    //         Map<String, Double> mapRevenues = new Map<String, Double>();
    //         Double totalThisYear;
    //         Double totalLastYear;
    //         totalThisYear = 0.00;
    //         totalLastYear = 0.00;
    //         Set<Id> setIdAcc = new Set<Id>();
    //         Integer mesEngloba = 12;
    //         Integer anioCarga = system.today().year();

    //         //Recorro booking
    //         for(DES_Booking__c b : bookingInputList) {
    //             if(!setIdAcc.contains(b.DES_Client__c)) {
    //                 setIdAcc.add(b.DES_Client__c);
    //             }
    //         }

    //         system.debug('>>>>> setIdAcc : ' + setIdAcc);

    //         List<Account> listaCuentas = new List<Account>([SELECT  Id,
    //                                                                 DES_GF_YOY__c,
    //                                                                 DES_GTB_YOY__c,
    //                                                                 DES_GM_YOY__c,
    //                                                                 DES_CF_YOY__c,
    //                                                                 DES_GTB_Revenues__c,
    //                                                                 DES_GM_Revenues__c,
    //                                                                 DES_GF_Revenues__c,
    //                                                                 DES_CF_Revenues__c,
    //                                                                 DES_Revenue_Update_Engloba__c,
    //                                                                 DES_Previous_Revenue_Update_Engloba__c
    //                                                         FROM Account
    //                                                         WHERE Id IN :setIdAcc
    //                                                         ORDER BY DES_Revenue_Update_Engloba__c DESC]);
    //         system.debug('>>>>> listaCuentas : ' + listaCuentas);
    //         //Recojo el mes en el que se han insertado los datos de Engloba

    //         for(Account acc : listaCuentas) {
    //             if(acc.DES_Revenue_Update_Engloba__c != null) {
    //                 system.debug('>>>>>acc.DES_Revenue_Update_Engloba__c : ' + acc.DES_Revenue_Update_Engloba__c);
    //                 mesEngloba = Integer.valueOf(acc.DES_Revenue_Update_Engloba__c.substring(4,6));
    //                 anioCarga = Integer.valueOf(acc.DES_Revenue_Update_Engloba__c.substring(0,4));
    //                 break;
    //             }
    //         }

    //         system.debug('>>>>> MES ENGLOBA: ' + mesEngloba);
    //         system.debug('>>>>> AÑO ENGLOBA: ' + anioCarga);

    //         //RECOJO TODOS LOS BOOKINGS QUE TIENEN LAS CUENTAS, PARA CALCULAR TODOS LOS TOTALES DE NUEVO
    //         for(DES_Booking__c b : [SELECT Id, DES_Type__c, DES_Year__c, DES_Client__c, DES_Revenues__c FROM DES_Booking__c WHERE DES_Client__c IN :setIdAcc]) {

    //             String key, key2;
    //             //Genero la key que esta formada por el id del cliente, el año y el tipo de producto
    //             //Si el año introducido es el año actual, se generan las claves con year y year-1
    //             if(anioCarga == Integer.valueOf(b.DES_Year__c)) {
    //                 key = b.DES_Client__c + '_' + b.DES_Year__c + '' + b.DES_Type__c;
    //                 key2 = b.DES_Client__c + '_' + (Integer.valueOf(b.DES_Year__c)-1) + '' + b.DES_Type__c;
    //             } else if(anioCarga > Integer.valueOf(b.DES_Year__c)) {//Si el año introducido es un año anterior al actual, se general las claves con year y year+1
    //                 //Integer yearDiff = anioCarga - b.DES_Year__c;
    //                 key = b.DES_Client__c + '_' + (Integer.valueOf(b.DES_Year__c)) + '' + b.DES_Type__c;
    //                 key2 = b.DES_Client__c + '_' + (Integer.valueOf(b.DES_Year__c) + 1) + '' + b.DES_Type__c;
    //             }

    //             //system.debug('>>>>> key : ' + key);
    //             //system.debug('>>>>> key2 : ' + key2);

    //             //Compruebo si no existe esa key, y si no existe creo la key en el mapa
    //             if(mapRevenues.get(key) == null) {
    //                 mapRevenues.put(key,0.00);
    //             }
    //             if(mapRevenues.get(key2) == null) {
    //                 mapRevenues.put(key2,0.00);
    //             }

    //             //Recojo el valor del mapa

    //             totalThisYear = mapRevenues.get(key);
    //             //system.debug('>>>>> ' + b.DES_Type__c +  ' ANTES SUMAR : totalThisYear : ' + totalThisYear);
    //             //le sumo el Revenue de el booking en el que estoy
    //             totalThisYear += b.DES_Revenues__c;
    //             //system.debug('>>>>> ' + b.DES_Type__c +  ' DESPUES SUMAR : totalThisYear : ' + totalThisYear);
    //             //Actualizo el mapa
    //             mapRevenues.put(key, totalThisYear);
    //         }

    //         //En el mapa mapRevenues ya tengo TODOS los datos
    //         //system.debug('>>>>> mapRevenues: ' + mapRevenues);


    //         List<String> listaFamilyProducts = getFamilyValuesIntoList();
    //         system.debug('>>>>> listaFamilyProducts : ' + listaFamilyProducts);
    //         List<Account> listAccUpd = new List<Account>();
    //         for(Account acc : listaCuentas) {//Recorro la lista de cuentas y voy comprobando todo el mapa

    //             for(String str : listaFamilyProducts) {
    //                 system.debug('\n\n>>>>> FAMILY: ' + str);
    //                 if(mapRevenues.get(acc.Id + '_' + anioCarga + str) != null) {
    //                     system.debug('>>>>> mapRevenues POS: ' + mapRevenues.get(acc.Id + '_' + anioCarga + str));

    //                     /*
    //                      *  AQUI HABRÁ QUE AGREGAR UNA LINEA POR CADA FAMILY PRODUCT QUE SE CREE, PARA INSERTAR
    //                      *
    //                     **/
    //                     if(str == 'GF') {
    //                         acc.DES_GF_Revenues__c = mapRevenues.get(acc.Id + '_' + anioCarga + str);
    //                         system.debug('>>>>> acc.DES_GF_Revenues__c: ' + acc.DES_GF_Revenues__c);
    //                     } else if(str ==  'GTB') {
    //                         acc.DES_GTB_Revenues__c = mapRevenues.get(acc.Id + '_' + anioCarga + str);
    //                         system.debug('>>>>> acc.DES_GTB_Revenues__c: ' + acc.DES_GTB_Revenues__c);
    //                     } else if(str == 'GM') {
    //                         acc.DES_GM_Revenues__c = mapRevenues.get(acc.Id + '_' + anioCarga + str);
    //                         system.debug('>>>>> acc.DES_GM_Revenues__c: ' + acc.DES_GM_Revenues__c);
    //                     } else if(str == 'CF') {
    //                         acc.DES_CF_Revenues__c = mapRevenues.get(acc.Id + '_' + anioCarga + str);
    //                         system.debug('>>>>> acc.DES_CF_Revenues__c: ' + acc.DES_CF_Revenues__c);
    //                     } else if(str == 'CO') {
    //                         acc.DES_CO_Revenues__c = mapRevenues.get(acc.Id + '_' + anioCarga + str);
    //                         system.debug('>>>>> acc.DES_CO_Revenues__c: ' + acc.DES_CO_Revenues__c);
    //                     } else if(str == 'GL') {
    //                         acc.DES_GL_Revenues__c = mapRevenues.get(acc.Id + '_' + anioCarga + str);
    //                         system.debug('>>>>> acc.DES_GL_Revenues__c: ' + acc.DES_GL_Revenues__c);
    //                     }

    //                     if( mapRevenues.get(acc.Id + '_' + (anioCarga-1) + str) != null
    //                         && mapRevenues.get(acc.Id + '_' + (anioCarga-1) + str) != 0) {
    //                         system.debug('>>>>> mapRevenues : ' + mapRevenues.get(acc.Id + '_' + (anioCarga-1) + str));
    //                         system.debug('>>>>> mesEngloba : ' +  mesEngloba);
    //                         system.debug('>>>>> mesEngloba DIVISION : ' + (Double) mesEngloba/12);
    //                         system.debug('>>>>> NUMERADOR: ' + mapRevenues.get(acc.Id + '_' + anioCarga + str));
    //                         system.debug('>>>>> DENOMINADOR : ' + (mapRevenues.get(acc.Id + '_' + (anioCarga-1) + str) * (mesEngloba/12)));
    //                         /*
    //                          *  En los siguientes if / else if habría que agregar un nuevo else if
    //                          *  por cada familia de producto que se cree
    //                          *
    //                         **/
    //                         if(str == 'GF') {
    //                             acc.DES_GF_YOY__c = (mapRevenues.get(acc.Id + '_' + anioCarga + str) - (mapRevenues.get(acc.Id + '_' + (anioCarga-1) + str) * ((Double)mesEngloba/12))) / Math.abs((mapRevenues.get(acc.Id + '_' + (anioCarga-1) + str) * ((Double)mesEngloba/12)));
    //                             system.debug('>>>>> : DES_GF_YOY__c' + acc.DES_GF_YOY__c);
    //                         } else if(str ==  'GTB') {
    //                             acc.DES_GTB_YOY__c = (mapRevenues.get(acc.Id + '_' + anioCarga + str) - (mapRevenues.get(acc.Id + '_' + (anioCarga-1) + str) * ((Double)mesEngloba/12))) / Math.abs((mapRevenues.get(acc.Id + '_' + (anioCarga-1) + str) * ((Double)mesEngloba/12)));
    //                             Double p = (mapRevenues.get(acc.Id + '_' + (anioCarga-1) + str) * ((Double)mesEngloba/12));
    //                             system.debug('>>>>> mapRevenues.get(acc.Id +  + (anioCarga-1) + str) * ((Double)mesEngloba/12) : ' + p);
    //                             system.debug('>>>>> : DES_GTB_YOY__c' + acc.DES_GTB_YOY__c);
    //                         } else if(str == 'GM') {
    //                             acc.DES_GM_YOY__c = (mapRevenues.get(acc.Id + '_' + anioCarga + str) - (mapRevenues.get(acc.Id + '_' + (anioCarga-1) + str) * ((Double)mesEngloba/12))) / Math.abs((mapRevenues.get(acc.Id + '_' + (anioCarga-1) + str) * ((Double)mesEngloba/12)));
    //                             system.debug('>>>>> : DES_GM_YOY__c' + acc.DES_GM_YOY__c);
    //                         } else if(str == 'CF') {
    //                             acc.DES_CF_YOY__c = (mapRevenues.get(acc.Id + '_' + anioCarga + str) - (mapRevenues.get(acc.Id + '_' + (anioCarga-1) + str) * ((Double)mesEngloba/12))) / Math.abs((mapRevenues.get(acc.Id + '_' + (anioCarga-1) + str) * ((Double)mesEngloba/12)));
    //                             system.debug('>>>>> : DES_CF_YOY__c' + acc.DES_CF_YOY__c);
    //                         } else if(str == 'CO') {
    //                             acc.DES_CO_YOY__c = (mapRevenues.get(acc.Id + '_' + anioCarga + str) - (mapRevenues.get(acc.Id + '_' + (anioCarga-1) + str) * ((Double)mesEngloba/12))) / Math.abs((mapRevenues.get(acc.Id + '_' + (anioCarga-1) + str) * ((Double)mesEngloba/12)));
    //                             system.debug('>>>>> : DES_CO_YOY__c' + acc.DES_CO_YOY__c);
    //                         } else if(str == 'GL') {
    //                             acc.DES_GL_YOY__c = (mapRevenues.get(acc.Id + '_' + anioCarga + str) - (mapRevenues.get(acc.Id + '_' + (anioCarga-1) + str) * ((Double)mesEngloba/12))) / Math.abs((mapRevenues.get(acc.Id + '_' + (anioCarga-1) + str) * ((Double)mesEngloba/12)));
    //                             system.debug('>>>>> : DES_GL_YOY__c' + acc.DES_GL_YOY__c);
    //                         }
    //                      }
    //                 }
    //             }
    //             system.debug('>>>>> acc: ' + acc);
    //             listAccUpd.add(acc);
    //         }

    //         try{
    //             system.debug('>>>>> listAccUpd : ' + listAccUpd);
    //             update listAccUpd;
    //         }catch(Exception e) {
    //             system.debug('>>>>> EXCEPTION : ' + e);
    //         }
    //     //}//FIN SI ES USUARIO DESKTOP

    //     if(listaCuentas[0].DES_Previous_Revenue_Update_Engloba__c != listaCuentas[0].DES_Revenue_Update_Engloba__c) {
    //         //Incluir un IF para controlar que la fecha de la actualizacion de revenues en cliente es distinta.
    //         //Para controlar si es la primera vez que el usuario hace login despues de la actualización de revenues.
    //         List<User> userDesktopList = [
    //                                         SELECT Name, DES_First_Login_After_Revenues_Update__c
    //                                         FROM User
    //                                         WHERE Profile.Name IN ('BBVA Desktop CIB Management','BBVA Desktop GCC Business Development','BBVA Desktop GCC Management','BBVA Desktop GCC Standard','BBVA Desktop GF Business Development','BBVA Desktop GF Standard','BBVA Desktop GM Business Development','BBVA Desktop GM Standard','BBVA Desktop GTB Business Development','BBVA Desktop GTB Standard')
    //                                                       AND DES_First_Login_After_Revenues_Update__c = false];
    //         for(User u : userDesktopList) {
    //             u.DES_First_Login_After_Revenues_Update__c = true;
    //         }
    //         update userDesktopList;
    //     }


    // }//FIN calcularRevenues




//   public static void calcRevFromAcc(List<Account> listAccount) {
//     system.debug('>>>>> ENTRO EN CALCULAR REVENUES : ' + listAccount);
//     //if (userSettings.CIB_Is_Desktop__c){
//         Set<Id> setIdsCuentasActualizadas = new Set<Id>();
//         //Este mapa tendrá como key la concatenacion de la cuenta, el año y el tipo de producto y como value el importe que va sumando
//         Map<String, Double> mapRevenues = new Map<String, Double>();
//         Double totalThisYear;
//         Double totalLastYear;
//         totalThisYear = 0.00;
//         totalLastYear = 0.00;
//         Set<Id> setIdAcc = new Set<Id>();
//         Integer mesEngloba = 12;
//         Integer anioCarga = system.today().year();

//         //Recojo el mes en el que se han insertado los datos de Engloba

//         for(Account acc : listAccount){
//             if(acc.DES_Revenue_Update_Engloba__c != null){
//                 system.debug('>>>>>acc.DES_Revenue_Update_Engloba__c : ' + acc.DES_Revenue_Update_Engloba__c);
//                 mesEngloba = Integer.valueOf(acc.DES_Revenue_Update_Engloba__c.substring(4,6));
//                 anioCarga = Integer.valueOf(acc.DES_Revenue_Update_Engloba__c.substring(0,4));
//             }
//             if(!setIdAcc.contains(acc.Id)) {
//                 setIdAcc.add(acc.Id);
//             }
//         }

//         system.debug('>>>>> MES ENGLOBA: ' + mesEngloba);
//         system.debug('>>>>> AÑO ENGLOBA: ' + anioCarga);
//         system.debug('>>>>> SELECT Id, DES_Type__c, DES_Year__c, DES_Client__c, DES_Revenues__c FROM DES_Booking__c WHERE DES_Client__c IN :setIdAcc : ' + JSON.serialize([SELECT Id, DES_Type__c, DES_Year__c, DES_Client__c, DES_Revenues__c FROM DES_Booking__c WHERE DES_Client__c IN :setIdAcc]));
//         //RECOJO TODOS LOS BOOKINGS QUE TIENEN LAS CUENTAS, PARA CALCULAR TODOS LOS TOTALES DE NUEVO
//         for(DES_Booking__c book : [SELECT Id, DES_Type__c, DES_Year__c, DES_Client__c, DES_Revenues__c FROM DES_Booking__c WHERE DES_Client__c IN :setIdAcc]) {

//             String key, key2;
//             //Genero la key que esta formada por el id del cliente, el año y el tipo de producto
//             //Si el año introducido es el año actual, se generan las claves con year y year-1
//             if(anioCarga == Integer.valueOf(book.DES_Year__c)){
//                 key = book.DES_Client__c + '_' + book.DES_Year__c + '' + book.DES_Type__c;
//                 key2 = book.DES_Client__c + '_' + (Integer.valueOf(book.DES_Year__c)-1) + '' + book.DES_Type__c;
//             }else if(anioCarga > Integer.valueOf(book.DES_Year__c)){//Si el año introducido es un año anterior al actual, se general las claves con year y year+1
//                 //Integer yearDiff = anioCarga - book.DES_Year__c;
//                 key = book.DES_Client__c + '_' + (Integer.valueOf(book.DES_Year__c)) + '' + book.DES_Type__c;
//                 key2 = book.DES_Client__c + '_' + (Integer.valueOf(book.DES_Year__c) + 1) + '' + book.DES_Type__c;
//             }


//             //Compruebo si no existe esa key, y si no existe creo la key en el mapa
//             if(mapRevenues.get(key) == null){
//                 mapRevenues.put(key,0.00);
//             }
//             if(mapRevenues.get(key2) == null){
//                 mapRevenues.put(key2,0.00);
//             }

//             //Recojo el valor del mapa

//             totalThisYear = mapRevenues.get(key);
//             //le sumo el Revenue de el booking en el que estoy
//             totalThisYear += book.DES_Revenues__c;
//             //Actualizo el mapa
//             mapRevenues.put(key, totalThisYear);
//         }



//         List<String> listaFamilyProducts = getFamilyValuesIntoList();
//         system.debug('>>>>> listaFamilyProducts : ' + listaFamilyProducts);
//         List<Account> listAccUpd = new List<Account>();
//         for(Account acc : listAccount){//Recorro la lista de cuentas y voy comprobando todo el mapa

//             for(String str : listaFamilyProducts){
//                 system.debug('\n\n>>>>> FAMILY: ' + str);
//                 if(mapRevenues.get(acc.Id + '_' + anioCarga + str) != null){
//                     system.debug('>>>>> mapRevenues POS: ' + mapRevenues.get(acc.Id + '_' + anioCarga + str));

//                     /*
//                       *  AQUI HABRÁ QUE AGREGAR UNA LINEA POR CADA FAMILY PRODUCT QUE SE CREE, PARA INSERTAR
//                       *
//                     **/
//                     if(str == 'GF'){
//                         acc.DES_GF_Revenues__c = mapRevenues.get(acc.Id + '_' + anioCarga + str);
//                         system.debug('>>>>> acc.DES_GF_Revenues__c: ' + acc.DES_GF_Revenues__c);
//                     }else if(str ==  'GTB'){
//                         acc.DES_GTB_Revenues__c = mapRevenues.get(acc.Id + '_' + anioCarga + str);
//                         system.debug('>>>>> acc.DES_GTB_Revenues__c: ' + acc.DES_GTB_Revenues__c);
//                     }else if(str == 'GM'){
//                         acc.DES_GM_Revenues__c = mapRevenues.get(acc.Id + '_' + anioCarga + str);
//                         system.debug('>>>>> acc.DES_GM_Revenues__c: ' + acc.DES_GM_Revenues__c);
//                     }else if(str == 'CF'){
//                         acc.DES_CF_Revenues__c = mapRevenues.get(acc.Id + '_' + anioCarga + str);
//                         system.debug('>>>>> acc.DES_CF_Revenues__c: ' + acc.DES_CF_Revenues__c);
//                     }else if(str == 'CO'){
//                         acc.DES_CO_Revenues__c = mapRevenues.get(acc.Id + '_' + anioCarga + str);
//                         system.debug('>>>>> acc.DES_CO_Revenues__c: ' + acc.DES_CO_Revenues__c);
//                     }else if(str == 'GL'){
//                         acc.DES_GL_Revenues__c = mapRevenues.get(acc.Id + '_' + anioCarga + str);
//                         system.debug('>>>>> acc.DES_GL_Revenues__c: ' + acc.DES_GL_Revenues__c);
//                     }

//                     if( mapRevenues.get(acc.Id + '_' + (anioCarga-1) + str) != null
//                         && mapRevenues.get(acc.Id + '_' + (anioCarga-1) + str) != 0){
//                         system.debug('>>>>> mapRevenues : ' + mapRevenues.get(acc.Id + '_' + (anioCarga-1) + str));
//                         system.debug('>>>>> mesEngloba : ' +  mesEngloba);
//                         system.debug('>>>>> mesEngloba DIVISION : ' + (Double) mesEngloba/12);
//                         system.debug('>>>>> NUMERADOR: ' + mapRevenues.get(acc.Id + '_' + anioCarga + str));
//                         system.debug('>>>>> DENOMINADOR : ' + (mapRevenues.get(acc.Id + '_' + (anioCarga-1) + str) * (mesEngloba/12)));
//                         /*
//                           *  En los siguientes if / else if habría que agregar un nuevo else if
//                           *  por cada familia de producto que se cree
//                           *
//                         **/
//                         if(str == 'GF'){
//                             acc.DES_GF_YOY__c = (mapRevenues.get(acc.Id + '_' + anioCarga + str) - (mapRevenues.get(acc.Id + '_' + (anioCarga-1) + str) * ((Double)mesEngloba/12))) / Math.abs((mapRevenues.get(acc.Id + '_' + (anioCarga-1) + str) * ((Double)mesEngloba/12)));
//                             system.debug('>>>>> : DES_GF_YOY__c' + acc.DES_GF_YOY__c);
//                         }else if(str ==  'GTB'){
//                             acc.DES_GTB_YOY__c = (mapRevenues.get(acc.Id + '_' + anioCarga + str) - (mapRevenues.get(acc.Id + '_' + (anioCarga-1) + str) * ((Double)mesEngloba/12))) / Math.abs((mapRevenues.get(acc.Id + '_' + (anioCarga-1) + str) * ((Double)mesEngloba/12)));
//                             Double p = (mapRevenues.get(acc.Id + '_' + (anioCarga-1) + str) * ((Double)mesEngloba/12));
//                             system.debug('>>>>> mapRevenues.get(acc.Id +  + (anioCarga-1) + str) * ((Double)mesEngloba/12) : ' + p);
//                             system.debug('>>>>> : DES_GTB_YOY__c' + acc.DES_GTB_YOY__c);
//                         }else if(str == 'GM'){
//                             acc.DES_GM_YOY__c = (mapRevenues.get(acc.Id + '_' + anioCarga + str) - (mapRevenues.get(acc.Id + '_' + (anioCarga-1) + str) * ((Double)mesEngloba/12))) / Math.abs((mapRevenues.get(acc.Id + '_' + (anioCarga-1) + str) * ((Double)mesEngloba/12)));
//                             system.debug('>>>>> : DES_GM_YOY__c' + acc.DES_GM_YOY__c);
//                         }else if(str == 'CF'){
//                             acc.DES_CF_YOY__c = (mapRevenues.get(acc.Id + '_' + anioCarga + str) - (mapRevenues.get(acc.Id + '_' + (anioCarga-1) + str) * ((Double)mesEngloba/12))) / Math.abs((mapRevenues.get(acc.Id + '_' + (anioCarga-1) + str) * ((Double)mesEngloba/12)));
//                             system.debug('>>>>> : DES_CF_YOY__c' + acc.DES_CF_YOY__c);
//                         }else if(str == 'CO'){
//                             acc.DES_CO_YOY__c = (mapRevenues.get(acc.Id + '_' + anioCarga + str) - (mapRevenues.get(acc.Id + '_' + (anioCarga-1) + str) * ((Double)mesEngloba/12))) / Math.abs((mapRevenues.get(acc.Id + '_' + (anioCarga-1) + str) * ((Double)mesEngloba/12)));
//                             system.debug('>>>>> : DES_CO_YOY__c' + acc.DES_CO_YOY__c);
//                         }else if(str == 'GL'){
//                             acc.DES_GL_YOY__c = (mapRevenues.get(acc.Id + '_' + anioCarga + str) - (mapRevenues.get(acc.Id + '_' + (anioCarga-1) + str) * ((Double)mesEngloba/12))) / Math.abs((mapRevenues.get(acc.Id + '_' + (anioCarga-1) + str) * ((Double)mesEngloba/12)));
//                             system.debug('>>>>> : DES_GL_YOY__c' + acc.DES_GL_YOY__c);
//                         }
//                       }
//                 }
//             }
//             system.debug('>>>>> acc: ' + acc);
//             listAccUpd.add(acc);
//         }

//         try{
//             system.debug('>>>>> listAccUpd : ' + listAccUpd);
//             update listAccUpd;
//         }catch(Exception e){
//             system.debug('>>>>> EXCEPTION : ' + e);
//         }
//         //}//FIN SI ES USUARIO DESKTOP

//         if(listAccount[0].DES_Previous_Revenue_Update_Engloba__c != listAccount[0].DES_Revenue_Update_Engloba__c){
//             //Incluir un IF para controlar que la fecha de la actualizacion de revenues en cliente es distinta.
//             //Para controlar si es la primera vez que el usuario hace login despues de la actualización de revenues.
//             List<User> userDesktopList = [
//                                             SELECT Name, DES_First_Login_After_Revenues_Update__c
//                                             FROM User
//                                             WHERE Profile.Name IN ('BBVA Desktop CIB Management','BBVA Desktop GCC Business Development','BBVA Desktop GCC Management','BBVA Desktop GCC Standard','BBVA Desktop GF Business Development','BBVA Desktop GF Standard','BBVA Desktop GM Business Development','BBVA Desktop GM Standard','BBVA Desktop GTB Business Development','BBVA Desktop GTB Standard')
//                                                         AND DES_First_Login_After_Revenues_Update__c = false];
//             for(User u : userDesktopList){
//                 u.DES_First_Login_After_Revenues_Update__c = true;
//             }
//             update userDesktopList;
//         }

//     }//FIN calcularRevenues

//     private static List<String> getFamilyValuesIntoList() {
//         List<String> pickListValuesList= new List<String>();
//         Schema.DescribeFieldResult fieldResult = Product2.Family.getDescribe();
//         List<Schema.PicklistEntry> ple = fieldResult.getPicklistValues();
//         for( Schema.PicklistEntry pickListVal : ple) {
//             pickListValuesList.add(pickListVal.getLabel());
//         }
//         return pickListValuesList;
//     }//getFamilyValuesIntoList

}