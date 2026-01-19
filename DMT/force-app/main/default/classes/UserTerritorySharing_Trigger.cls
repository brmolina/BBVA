/*
 * @author GlobalDesktop
 * @Description Clase que contiene las funciones con la lógica necesaria para gestionar los territorios
 * 				y la compartición de los distintos objetos con los territorios correspondientes
 *
 */
public without sharing class UserTerritorySharing_Trigger {

    /*
     * Instancia de la clase userTerritorySharing
     */
    private static UserTerritorySharing_Trigger instance;

    /*
     * CONSTRUCTOR
     */
    private UserTerritorySharing_Trigger() {
    }

    /*
     * Instancia de UserTerritorySharing
     */
    public static UserTerritorySharing_Trigger getInstance() {
        if (instance == null) instance = new UserTerritorySharing_Trigger();
        return instance;
    }


    /*
     * @author	Global Desktop
     * @Description	Funcion que contiene la logica a aplicar para obtener el pais de cada usuario en un set
     * @return	Set con los países acumulados de ese usuario
     *
     */
    public static Set<String> countrySetLogic(Set<String> setCountriesOrg, User usr) {
		Set<String> setCountries;
        setCountries = setCountriesOrg;
        if(usr.gf_user_work_country_desc__c.contains(';')) {
            for(String strCountry : usr.gf_user_work_country_desc__c.split(';')) {
                if(!setCountries.contains(strCountry)) {
                    setCountries.add(strCountry);
                }
            }
        } else {
            if(!setCountries.contains(usr.gf_user_work_country_desc__c)) {
                setCountries.add(usr.gf_user_work_country_desc__c);
            }
        }
        return setCountries;
    }

    /*
     * @author	Global Desktop
     * @Description	Funcion que contiene la logica a aplicar para obtener el segmento de cada usuario en un set
     * @return	Set con los segmentos acumulados de ese usuario
     *
     */
    public static Set<String> segmentSetLogic(Set<String> setSegmentsOrg, User usr) {
		Set<String> setSegments;
        setSegments = setSegmentsOrg;
        if(usr.gf_user_work_segment_desc__c.contains(';')) {
            for(String strCountry : usr.gf_user_work_segment_desc__c.split(';')) {
                if(!setSegments.contains(strCountry)) {
                    setSegments.add(strCountry);
                }
            }
        } else {
            if(!setSegments.contains(usr.gf_user_work_segment_desc__c)) {
                setSegments.add(usr.gf_user_work_segment_desc__c);
            }
        }
        return setSegments;
    }

    /*
     * @author	Global Desktop
     * @Description	Funcion que contiene la logica a aplicar para obtener el segmento de cada usuario en un set
     * @return	Set con los segmentos acumulados de ese usuario
     *
     */
    public static Set<String> productsSetLogic(Set<String> setProductsOrg, User usr) {
		Set<String> setProducts;
        setProducts = setProductsOrg;
        if(usr.gf_user_work_segment_desc__c.contains(';')) {
            for(String strCountry : usr.gf_user_work_segment_desc__c.split(';')) {
                if(!setProducts.contains(strCountry)) {
                    setProducts.add(strCountry);
                }
            }
        } else {
            if(!setProducts.contains(usr.gf_user_work_segment_desc__c)) {
                setProducts.add(usr.gf_user_work_segment_desc__c);
            }
        }
        return setProducts;
    }

} //FIN userTerritorySharing