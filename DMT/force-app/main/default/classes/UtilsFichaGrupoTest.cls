@isTest
/*
*Clase for UtilsFichaGrupo
*/
public class UtilsFichaGrupoTest {

    /*
    *   String field
    */
    private final static String SPAIN = 'SPAIN';
    /*
    *   String field
    */
    private final static String FRANCE = 'FRANCE';
    /*
    *   String field
    */
    private final static String MEXICO = 'MEXICO';
    /*
    *   String field
    */
    private final static String PROD = 'PROD';
    /**
    *@Author: Global Desktop
    *Description: INsert
    */
    @isTest
    public static void getCountryColor() {

        final Map<String, Map<String, Double>> mapPais = new Map<String, Map<String, Double>>();
        final Map<String, Double> mapToReturn = new Map<String, Double>();
        final Map<String, Double> map1ToReturn = new Map<String, Double>();
        mapToReturn.put(SPAIN, 999);
        mapToReturn.put(FRANCE, 111);
        mapToReturn.put(MEXICO, 222);
        mapPais.put(SPAIN, mapToReturn);
        mapPais.put(FRANCE, mapToReturn);
        map1ToReturn.put(PROD, 222);
        mapPais.put(MEXICO, mapToReturn);

        UtilsFichaGrupo.getCountryColor(new Set<String>{SPAIN, FRANCE});
        UtilsFichaGrupo.checkTimeWindow(new UtilsFichaGrupo.WrapperBookingDate(1, 2, 3, 4, 5));
        UtilsFichaGrupo.diffMonths(new UtilsFichaGrupo.WrapperBookingDate(1, 2, 3, 4, 5));
        UtilsFichaGrupo.orderMap(mapToReturn);
        UtilsFichaGrupo.parseToMonth(12);
        UtilsFichaGrupo.parseFromMonth('DEC');
        final List<Opp_Countries__mdt> lOppCountries= UtilsFichaGrupo.mapCountryCodesSelector();
        UtilsFichaGrupo.helperCreateMapCountryCodes('BOOKCOUNTRY',lOppCountries);
        UtilsFichaGrupo.getDate('12', '2019');
        UtilsFichaGrupo.conversionCurrency();
        UtilsFichaGrupo.calculateTopNLev1(mapPais, mapToReturn, 0);
        UtilsFichaGrupo.calculateTopNLev1(mapPais, mapToReturn, 1);
        System.assert(mapPais.containsKey(SPAIN), 'Error');
    }
    /**
    *@Author: Global Desktop
    *Description: INsert
    */
    @isTest
    public static void getMonths() {
        UtilsFichaGrupo.parseToMonth(1);
        UtilsFichaGrupo.parseToMonth(2);
        UtilsFichaGrupo.parseToMonth(3);
        UtilsFichaGrupo.parseToMonth(4);
        UtilsFichaGrupo.parseToMonth(5);
        UtilsFichaGrupo.parseToMonth(6);
        UtilsFichaGrupo.parseToMonth(7);
        UtilsFichaGrupo.parseToMonth(8);
        UtilsFichaGrupo.parseToMonth(9);
        UtilsFichaGrupo.parseToMonth(10);
        UtilsFichaGrupo.parseToMonth(11);
        UtilsFichaGrupo.parseToMonth(12);
        UtilsFichaGrupo.parseFromMonth('JAN');
        UtilsFichaGrupo.parseFromMonth('FEB');
        UtilsFichaGrupo.parseFromMonth('MAR');
        UtilsFichaGrupo.parseFromMonth('APR');
        UtilsFichaGrupo.parseFromMonth('MAY');
        UtilsFichaGrupo.parseFromMonth('JUN');
        UtilsFichaGrupo.parseFromMonth('JUL');
        UtilsFichaGrupo.parseFromMonth('AUG');
        UtilsFichaGrupo.parseFromMonth('SEP');
        UtilsFichaGrupo.parseFromMonth('OCT');
        UtilsFichaGrupo.parseFromMonth('NOV');
        UtilsFichaGrupo.parseFromMonth('DEC');
        System.assertEquals(UtilsFichaGrupo.parseFromMonth('DEC'),12, 'Error');
    }
}