/*
 * @author GlobalDesktop
 * @Description Clase que contiene las funciones con la lógica necesaria para gestionar los territorios
 * 				y la compartición de los distintos objetos con los territorios correspondientes
 *
 */
public without sharing class UserTerritorySharing {

    /*
     * Instancia de la clase userTerritorySharing
     */
    private static UserTerritorySharing instance;

    /*
     * CONSTRUCTOR
     */
    private UserTerritorySharing() {
    }

    /*
     * Instancia de UserTerritorySharing
     */
    public static UserTerritorySharing getInstance() {//NOSONAR
        if (instance == null) {
            instance = new UserTerritorySharing();
        }
        return instance;
    }

    /*
     * @author	Global Desktop
     * @Description	Clase que, a partir de un listado de usuarios, asigna a cada usuario uno o varios territorios.
     * 				Este method se llama desde el batch 'UserToTerritoryBatch'
     *
     */
    public static void manageUserTerritories(Map<String, Territory2> mapStrTerritory, List<User> listUsers) {
        system.debug('::::: listUsers : ' + listUsers);

		//Se limpia la tabla UserTerritory2Association primero
        final List<UserTerritory2Association> territoriosBorrar = [Select id from UserTerritory2Association where UserId in :listUsers];
        delete territoriosBorrar;

        //Mapa que contiene el Id del usuario como key y como valor una lista de strings con los territorios en los que tiene que estar
        Map<Id, List<String>> mapUserStrTerrit = new Map<Id, List<String>>();//NOSONAR

        final List<UserTerritory2Association> userTerriToInsert = new List<UserTerritory2Association>();
        //Recorro mapUsers.values() y guardo los countries, los products y los segmentos de los usuarios en distintos Sets de Strings
        for(User usr : listUsers) {
            //HALLO EL PRODUCTO CARTESIANO DE TODAS LAS LISTAS
            List<List<String>> listOfLists;
            listOfLists = new List<List<String>>();
			List<String> listProdAux;
            listProdAux = productsListLogic(usr);
            if(!listProdAux.isEmpty()) {
                listOfLists.add(listProdAux);
            }
            List<String> listCounAux;
            listCounAux = countryListLogic(usr);
            if(!listCounAux.isEmpty()) {
                listOfLists.add(listCounAux);
            }
            List<String> listSegmAux;
            listSegmAux = segmentListLogic(usr);
            if(!listSegmAux.isEmpty()) {
                listOfLists.add(listSegmAux);
            }
            List<String> listConfAux;
            listConfAux = confidentialListLogic(usr);
            if(!listConfAux.isEmpty()) {
                listOfLists.add(listConfAux);
            }
            system.debug('>>>>> listOfLists: ' + JSON.serializePretty(listOfLists));
            List<String> listResultado;
            listResultado = new List<String>();
            generateCartesianProduct(listOfLists, listResultado, 0, '');
            system.debug('>>>>> listResultado: ' + JSON.serializePretty(listResultado));
            system.debug('::::: mapStrTerritory.SIZE : ' + mapStrTerritory.size());
            system.debug('::::: listResultado.SIZE: ' + listResultado.size());

            //RECORRO LA LISTA DE RESULTADOS Y GENERO UN GROUP MEMBER DEL USUARIO QUE ESTOY RECORRIENDO PARA CADA UNO DE LOS GRUPOS
            for(String keyTerrit : listResultado) {
                system.debug('>>>>> keyTerrit: ' + keyTerrit);
                system.debug('>>>>> mapStrTerritory.get(keyTerrit.toUpperCase()): ' + mapStrTerritory.get(keyTerrit.toUpperCase()));
                if(mapStrTerritory.get(keyTerrit.toUpperCase()) != null) {
                    system.debug('>>>>> CREO UN userTerriToInsert - mapStrTerritory.get(keyTerrit.toUpperCase()) : ' + JSON.serialize(mapStrTerritory.get(keyTerrit.toUpperCase())));
                    userTerriToInsert.add(createTerritoryMember(mapStrTerritory.get(keyTerrit.toUpperCase()).Id, usr.Id));
                }
            }
        }

        system.debug('>>>>> mapStrTerritory : ' + JSON.serialize(mapStrTerritory));
        system.debug('>>>>> listUsers : ' + JSON.serialize(listUsers));
        system.debug('>>>>> userTerriToInsert : ' + JSON.serialize(userTerriToInsert));
        if(!userTerriToInsert.isEmpty()) {
            insert userTerriToInsert;
        }

    } //FIN manageUserTerritories

    /*
     * @author	Global Desktop
     * @Description	Funcion que contiene la logica a aplicar para obtener el pais de cada usuario en un set
     * @return	Set con los países acumulados de ese usuario
     *
     */
    public static List<String> countryListLogic(User usr) {
		List<String> listCountries;
        listCountries = new List<String>();
        if(usr.gf_user_work_country_desc__c != null && usr.gf_user_work_country_desc__c.contains(';')) {
            for(String strCountry : usr.gf_user_work_country_desc__c.split(';')) {
                if(!listCountries.contains(strCountry)) {
                    listCountries.add(strCountry);
                }
            }
        } else if (usr.gf_user_work_country_desc__c != null) { //NOSONAR
            if(!listCountries.contains(usr.gf_user_work_country_desc__c)) {//NOSONAR
                listCountries.add(usr.gf_user_work_country_desc__c);
            }
        }
        return listCountries;
    }

    /*
     * @author	Global Desktop
     * @Description	Funcion que contiene la logica a aplicar para obtener la confidencialidad de cada usuario en un set
     * @return	Set con los segmentos acumulados de ese usuario
     *
     */
    public static List<String> confidentialListLogic(User usr) {
		List<String> listConfident;
        listConfident = new List<String>();
        if(usr.gf_user_auth_level_name__c != null && usr.gf_user_auth_level_name__c.contains(';')) {
            for(String strSegments : usr.gf_user_auth_level_name__c.split(';')) {
                if(!listConfident.contains(strSegments)) {
                    listConfident.add(strSegments);
                }
            }
        } else if (usr.gf_user_auth_level_name__c != null) {//NOSONAR
            if(!listConfident.contains(usr.gf_user_auth_level_name__c)) {//NOSONAR
                listConfident.add(usr.gf_user_auth_level_name__c);
            }
        }
        return listConfident;
    }


    /*
     * @author	Global Desktop
     * @Description	Funcion que contiene la logica a aplicar para obtener el segmento de cada usuario en un set
     * @return	Set con los segmentos acumulados de ese usuario
     *
     */
    public static List<String> segmentListLogic(User usr) {
		List<String> listSegments;
        listSegments = new List<String>();
        if(usr.gf_user_work_segment_desc__c != null && usr.gf_user_work_segment_desc__c.contains(';')) {
            for(String strSegments : usr.gf_user_work_segment_desc__c.split(';')) {
                if(!listSegments.contains(strSegments)) {
                    listSegments.add(strSegments);
                }
            }
        } else if (usr.gf_user_work_segment_desc__c != null) {//NOSONAR
            if(!listSegments.contains(usr.gf_user_work_segment_desc__c)) {//NOSONAR
                listSegments.add(usr.gf_user_work_segment_desc__c);
            }
        }
        return listSegments;
    }

    /*
     * @author	Global Desktop
     * @Description	Funcion que contiene la logica a aplicar para obtener el segmento de cada usuario en un set
     * @return	Set con los segmentos acumulados de ese usuario
     *
     */
    public static List<String> productsListLogic(User usr) {
		List<String> listProducts;
        listProducts = new List<String>();
        if(usr.gf_user_work_product_desc__c != null && usr.gf_user_work_product_desc__c.contains(';')) {
            for(String strProduct : usr.gf_user_work_product_desc__c.split(';')) {
                if(!listProducts.contains(strProduct)) {
                    listProducts.add(strProduct);
                }
            }
        } else if(usr.gf_user_work_product_desc__c != null) {//NOSONAR
            if(!listProducts.contains(usr.gf_user_work_product_desc__c)) {//NOSONAR
                listProducts.add(usr.gf_user_work_product_desc__c);
            }
        }
        return listProducts;
    }

    /*
     * @author	Global Desktop
     * @Description	Producto cartesiano de las listas deseadas
     *
     */
    public static void generateCartesianProduct(List<List<String>> lists, List<String> result, Integer depth, String current) {
        if (depth == lists.size()) {
            result.add(current);
            return;
        }

        system.debug('::::: ANTES result: ' + result);
        system.debug('::::: ANTES lists: ' + lists);
        system.debug('::::: depth: ' + depth);
        system.debug('::::: lists.get(depth): ' + lists.get(depth));
        for (Integer i = 0; i < lists.get(depth).size(); i++) {
            generateCartesianProduct(lists, result, depth + 1, current + lists.get(depth).get(i));
        }
        system.debug('::::: DESPUES lists: ' + lists);
        system.debug('::::: DESPUES result: ' + result);
    }

    /*
     * @author	Global Desktop
     * @Description	Producto cartesiano de las listas deseadas
     *
     */
    public static UserTerritory2Association createTerritoryMember(Id idTerritory, Id userMember) {
        UserTerritory2Association userTerritNew = new UserTerritory2Association();//NOSONAR
        userTerritNew.Territory2Id = idTerritory;
        userTerritNew.UserId = userMember;
        return userTerritNew;
    }

} //FIN userTerritorySharing