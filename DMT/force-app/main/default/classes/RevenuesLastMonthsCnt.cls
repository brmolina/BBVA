/****************************************
Name:            RevenuesLastMonthsCnt
Description:     Controlador del componente RevenuesLastMonths

Version        Date            Author            Summary of changes
-----------------------------------------------------------------------------------------
0.1            15/02/2019      Global Desktop    Controlador del componente RevenuesByRegionAndProducts
**************************************************/
public with sharing class RevenuesLastMonthsCnt {

    /*xb const*/
    Final private Static String XBORDER = 'XB';
    /*no xb const*/
    Final private Static String NOXB = 'NO XB';
    /*SINGLETON PATTERN*/
    private static RevenuesLastMonthsCnt instance;
    /*SINGLETON PATTERN*/
    public static RevenuesLastMonthsCnt getInstance() { //NOSONAR
        if (instance == null) {
            instance = new RevenuesLastMonthsCnt();
        }
        return instance;
    }
    /*
    *   Empty Constructor
    */
	private RevenuesLastMonthsCnt() {
        System.debug('Constructor empty');
	}
    /*
	* @author Global Desktop
	* @description Method que recoge los Revenues relacionados al cliente
	*/
	@auraEnabled
    public static String getData(String clientId, String family, Integer monthsToDisplay) {
  		try {
	        Map<String, Map<String, Double>> mapResponse;

            //Mapa que tiene como key la columna y como value el color
          	Map<String, String> mapColumns;
              mapColumns = new Map<String, String>();

            Final String QUERY = generateQuery(clientId, family, true);
            Final list<DES_Historic_Booking__c> lstHistoricRevs = Database.query(QUERY); //NOSONAR - management of escapeSingleQuotes done in generateQuery() method
            System.debug('::::lstHistoricRevs: ' + JSON.serialize(lstHistoricRevs));
            Final Set<String> setLabels = new Set<String>{NOXB, XBORDER};
            system.debug('++ -> setLabels ' + setLabels);

            if(!lstHistoricRevs.isEmpty()) {
                mapResponse = generateMapData(lstHistoricRevs, monthsToDisplay);
                mapColumns = UtilsFichaGrupo.getCountryColor(setLabels);
            }
            //wrapper to be sent
	        Final WrapperGlobalData wrapperGlobal = new WrapperGlobalData(mapColumns, mapResponse);
	        return JSON.serialize(wrapperGlobal);

        } catch (Exception exc) {
            throw new AuraHandledException(Label.DES_Error + exc);
        }
    }
    /*
    *   @author: GlobalDesktop - APC
    *   @Method: generateQuery related to DES_Historic_Booking__c
    *   @Description:   - month_type__c and year_id__c specify when the rows have been updated by last time

    *   @Versions:
            v1 - 2019/05/13 - Initial version
    */
    private static String generateQuery(String clientId, String family, Boolean order) {
        String querySelect;
        querySelect ='';

        querySelect += 'SELECT Id, country_id__c, month_type__c, Name, participant_id__c, region_name__c, sf_historic_booking_id__c, solution_category_desc__c, solution_id_path_desc__c, year_id__c ';


        querySelect += ',convertCurrency(total_gross_margin_jan_py_amount__c), convertCurrency(total_gross_margin_feb_py_amount__c), convertCurrency(total_gross_margin_mar_py_amount__c), convertCurrency(total_gross_margin_apr_py_amount__c), convertCurrency(total_gross_margin_may_py_amount__c), convertCurrency(total_gross_margin_jun_py_amount__c)';
        querySelect += ',convertCurrency(total_gross_margin_jul_py_amount__c), convertCurrency(total_gross_margin_aug_py_amount__c), convertCurrency(total_gross_margin_sep_py_amount__c), convertCurrency(total_gross_margin_oct_py_amount__c), convertCurrency(total_gross_margin_nov_py_amount__c), convertCurrency(total_gross_margin_dec_py_amount__c)';

        querySelect += ',convertCurrency(xbrdr_gross_margin_jan_py_amount__c), convertCurrency(xbrdr_gross_margin_feb_py_amount__c), convertCurrency(xbrdr_gross_margin_mar_py_amount__c), convertCurrency(xbrdr_gross_margin_apr_py_amount__c), convertCurrency(xbrdr_gross_margin_may_py_amount__c), convertCurrency(xbrdr_gross_margin_jun_py_amount__c)';
        querySelect += ',convertCurrency(xbrdr_gross_margin_jul_py_amount__c), convertCurrency(xbrdr_gross_margin_aug_py_amount__c), convertCurrency(xbrdr_gross_margin_sep_py_amount__c), convertCurrency(xbrdr_gross_margin_oct_py_amount__c), convertCurrency(xbrdr_gross_margin_nov_py_amount__c), convertCurrency(xbrdr_gross_margin_dec_py_amount__c)';

        querySelect += ',convertCurrency(total_gross_margin_jan_amount__c), convertCurrency(total_gross_margin_feb_amount__c), convertCurrency(total_gross_margin_mar_amount__c), convertCurrency(total_gross_margin_apr_amount__c), convertCurrency(total_gross_margin_may_amount__c), convertCurrency(total_gross_margin_jun_amount__c)';
        querySelect += ',convertCurrency(total_gross_margin_jul_amount__c), convertCurrency(total_gross_margin_aug_amount__c), convertCurrency(total_gross_margin_sep_amount__c), convertCurrency(total_gross_margin_oct_amount__c), convertCurrency(total_gross_margin_nov_amount__c), convertCurrency(total_gross_margin_dec_amount__c)';

        querySelect += ',convertCurrency(xbrdr_gross_margin_jan_amount__c), convertCurrency(xbrdr_gross_margin_feb_amount__c), convertCurrency(xbrdr_gross_margin_mar_amount__c), convertCurrency(xbrdr_gross_margin_apr_amount__c), convertCurrency(xbrdr_gross_margin_may_amount__c), convertCurrency(xbrdr_gross_margin_jun_amount__c)';
        querySelect += ',convertCurrency(xbrdr_gross_margin_jul_amount__c), convertCurrency(xbrdr_gross_margin_aug_amount__c), convertCurrency(xbrdr_gross_margin_sep_amount__c), convertCurrency(xbrdr_gross_margin_oct_amount__c), convertCurrency(xbrdr_gross_margin_nov_amount__c), convertCurrency(xbrdr_gross_margin_dec_amount__c)';


        querySelect += ' FROM DES_Historic_Booking__c';

        String queryWhere;
        queryWhere = ' WHERE solution_category_desc__c =\'' + String.escapeSingleQuotes(family) + '\' AND participant_id__c =\'' + String.escapeSingleQuotes(clientId) + '\'';

        String queryOrdered;
        queryOrdered = order?' ORDER BY year_id__c DESC, month_type__c DESC':'ORDER BY region_name__c DESC, solution_id_path_desc__c DESC';



        Final String query = querySelect + queryWhere + queryOrdered;
        System.debug(':::::dynamic query::: ' + query);
        return query;
    }
    /*
    *   @author: GlobalDesktop - APC
    *   @Method: generateMapData
    *   @Description: filter attributes in order to populate mapData

    *   @Inputs: List<DES_Historic_Booking__c> lstHistoricRevs
    *   @Output: Map<String, Double> mapData
    *   @Versions:
            v1 - 2019/05/13 - Initial version
    */
    private static Map<String, Map<String, Double>> generateMapData(List<DES_Historic_Booking__c> lstHistoricRevs, Integer monthsToDisplay) {
        Map<String, Map<String, Double>> mapResponse;//
        mapResponse = new Map<String, Map<String, Double>>();

        Final Integer lastMonthB = Integer.valueOf(lstHistoricRevs[0].month_type__c);
        Final Integer lastYearB = Integer.valueOf(lstHistoricRevs[0].year_id__c);

        for(DES_Historic_Booking__c hBook : lstHistoricRevs) {
            Final Integer currentMonthB = Integer.valueOf(hBook.month_type__c);
            Final Integer currentYearB = Integer.valueOf(hBook.year_id__c);
            //to verify the hBook row is created by the last data loading process
            mapResponse = fillMapResponse(hBook, currentMonthB, currentYearB, monthsToDisplay, lastMonthB, lastYearB, mapResponse);
        }
        return mapResponse;
    }

    /*
    * Aux method to fill MapResponse
    */
    private static Map<String, Map<String, Double>> fillMapResponse(DES_Historic_Booking__c hBook, Integer currentMonthB, Integer currentYearB, Integer monthsToDisplay, Integer lastMonthB,
    Integer lastYearB, Map<String, Map<String, Double>> mapResponse) {
        Map<String, Map<String, Double>> mapToReturn = mapResponse;
        if(hBook.solution_category_desc__c != null && currentMonthB == lastMonthB && currentYearB == lastYearB) {
            Final Boolean inTimeWindow = UtilsFichaGrupo.checkTimeWindow(new UtilsFichaGrupo.WrapperBookingDate(currentMonthB, currentYearB, lastMonthB, lastYearB, monthsToDisplay));
            if(inTimeWindow) {
                mapToReturn = getMapData(mapToReturn, hBook, monthsToDisplay);
            } else {
                System.debug('::::Error, el parámetro de meses a mostrar no es compatible con los datos del histórico de booking');
            }
        }
        return mapToReturn;
    }
    /*
    * @author Global Desktop
    * @description To fulfill  Map<String, Double> getMapData values
    */
    private static Map<String, Map<String, Double>> getMapData( Map<String, Map<String, Double>> mapResponseInput, DES_Historic_Booking__c hbook, Integer monthsToDisplay) {
        Map<String, Map<String, Double>> mapResponse = mapResponseInput;
        Final Integer currentMonthB = Integer.valueOf(hBook.month_type__c);
        Final Integer currentYearB = Integer.valueOf(hBook.year_id__c);
        Final Integer monthsThisYear = currentMonthB > monthsToDisplay ? currentMonthB - monthsToDisplay : currentMonthB;
        Final Integer monthsPrevYear = monthsToDisplay > currentMonthB ? monthsToDisplay - currentMonthB : 0;

        mapResponse = fillGetMap(monthsThisYear, mapResponse, hbook, currentYearB);
        mapResponse = fillGetMapPrevYear(monthsPrevYear, mapResponse, hbook, currentYearB);
        return mapResponse;
    }

    /*
    * Private method aux to getMapData
    */
    private static Map<String, Map<String, Double>> fillGetMap(Integer monthsThisYear, Map<String, Map<String, Double>> mapResponse, DES_Historic_Booking__c hbook, Integer currentYearB) {
        final Map<String, Map<String, Double>> mapToReturn = mapResponse;
        for(Integer aux = monthsThisYear; aux > 0; aux--) {
            Map<String, Double> mapData;
            Final String mes = UtilsFichaGrupo.parseToMonth(aux);

            if(mapToReturn.get(mes + ' ' + currentYearB) == null) {
                mapData = new Map<String, Double>();
                mapData.put(NOXB, getMonthValueYTD(aux, hbook, true) - getMonthValueYTD(aux, hbook, false));
                mapData.put(XBORDER, getMonthValueYTD(aux, hbook, false));
            } else {
                mapData = mapToReturn.get(mes + ' ' + currentYearB);

                mapData.put(NOXB, mapData.get(NOXB) + getMonthValueYTD(aux, hbook, true) - getMonthValueYTD(aux, hbook, false));
                mapData.put(XBORDER, mapData.get(XBORDER) + getMonthValueYTD(aux, hbook, false));
            }

            mapToReturn.put(mes + ' ' + currentYearB, mapData);
        }
        return mapToReturn;
    }

    /*
    * Private method aux to getMapData
    */
    private static Map<String, Map<String, Double>> fillGetMapPrevYear(Integer monthsPrevYear, Map<String, Map<String, Double>> mapResponse, DES_Historic_Booking__c hbook, Integer currentYearB) {
        final Map<String, Map<String, Double>> mapToReturn = mapResponse;
        if(monthsPrevYear > 0) {
            for(Integer aux = 12; aux >= 13 - monthsPrevYear; aux--) {
                Map<String, Double> mapData;
                Final String mes = UtilsFichaGrupo.parseToMonth(aux);

                if(mapToReturn.get(mes + ' ' + (currentYearB-1)) == null) {
                    mapData = new Map<String, Double>();
                    mapData.put(NOXB, getMonthValuePY(aux, hbook, true) - getMonthValuePY(aux, hbook, false));
                    mapData.put(XBORDER, getMonthValuePY(aux, hbook, false));
                } else {
                    mapData = mapToReturn.get(mes + ' ' + (currentYearB-1));

                    mapData.put(NOXB, mapData.get(NOXB) + getMonthValuePY(aux, hbook, true) - getMonthValuePY(aux, hbook, false));
                    mapData.put(XBORDER, mapData.get(XBORDER) + getMonthValuePY(aux, hbook, false));
                }

                mapToReturn.put(mes + ' ' + (currentYearB-1), mapData);
                }
        }
        return mapToReturn;
    }


    /*
    *   @author: GlobalDesktop - APC
    *   @Method: getMonthValueYTD
    *   @Description:

    *   @Inputs:    Integer digit, DES_Historic_Booking__c hbook, Boolean isXB
    *   @Output:    Decimal value
    *   @Versions:
            v1 - 2019/05/27 - Initial version
    */
    private static Decimal getMonthValueYTD(Integer digit, DES_Historic_Booking__c hbook, Boolean isTotal) {
        Decimal value;

        switch on digit {
            when 1 {
                value = monthValue(isTotal, hbook.total_gross_margin_jan_amount__c, hbook.xbrdr_gross_margin_jan_amount__c);
            }
            when 2 {
                value = monthValue(isTotal, hbook.total_gross_margin_feb_amount__c, hbook.xbrdr_gross_margin_feb_amount__c);
            }
            when 3 {
                value = monthValue(isTotal, hbook.total_gross_margin_mar_amount__c, hbook.xbrdr_gross_margin_mar_amount__c);
            }
            when 4 {
                value = monthValue(isTotal, hbook.total_gross_margin_apr_amount__c, hbook.xbrdr_gross_margin_apr_amount__c);
            }
            when 5 {
                value = monthValue(isTotal, hbook.total_gross_margin_may_amount__c, hbook.xbrdr_gross_margin_may_amount__c);
            }
            when 6 {
                value = monthValue(isTotal, hbook.total_gross_margin_jun_amount__c, hbook.xbrdr_gross_margin_jun_amount__c);
            }
            when else {
                value = contgetMonthValueYTD(digit, hbook, isTotal);
            }
        }
        return value;
    }

    /*
    * Continuación getMonthValueYTD
    */
    private static Decimal contgetMonthValueYTD(Integer digit, DES_Historic_Booking__c hbook, Boolean isTotal) {
        Decimal value;

        switch on digit {
            when 7 {
                value = monthValue(isTotal, hbook.total_gross_margin_jul_amount__c, hbook.xbrdr_gross_margin_jul_amount__c);
            }
            when 8 {
                value = monthValue(isTotal, hbook.total_gross_margin_aug_amount__c, hbook.xbrdr_gross_margin_aug_amount__c);
            }
            when 9 {
                value = monthValue(isTotal, hbook.total_gross_margin_sep_amount__c, hbook.xbrdr_gross_margin_sep_amount__c);
            }
            when 10 {
                value = monthValue(isTotal, hbook.total_gross_margin_oct_amount__c, hbook.xbrdr_gross_margin_oct_amount__c);
            }
            when 11 {
                value = monthValue(isTotal, hbook.total_gross_margin_nov_amount__c, hbook.xbrdr_gross_margin_nov_amount__c);
            }
            when 12 {
                value = monthValue(isTotal, hbook.total_gross_margin_dec_amount__c, hbook.xbrdr_gross_margin_dec_amount__c);
            }
            when else {
                value = 0;
            }
        }
        return value;
    }
     /*
    *   @author: GlobalDesktop - APC
    *   @Method: getMonthValuePY
    *   @Description:

    *   @Inputs:    Integer digit, DES_Historic_Booking__c hbook, Boolean isTotal
    *   @Output:    Decimal value
    *   @Versions:
            v1 - 2019/05/27 - Initial version
    */
    private static Decimal getMonthValuePY(Integer digit, DES_Historic_Booking__c hbook, Boolean isTotal) {
        Decimal value;

        switch on digit {
            when 1 {
                value = monthValue(isTotal, hbook.total_gross_margin_jan_py_amount__c, hbook.xbrdr_gross_margin_jan_py_amount__c);
            }
            when 2 {
                value = monthValue(isTotal, hbook.total_gross_margin_feb_py_amount__c, hbook.xbrdr_gross_margin_feb_py_amount__c);
            }
            when 3 {
                value = monthValue(isTotal, hbook.total_gross_margin_mar_py_amount__c, hbook.xbrdr_gross_margin_mar_py_amount__c);
            }
            when 4 {
                value = monthValue(isTotal, hbook.total_gross_margin_apr_py_amount__c, hbook.xbrdr_gross_margin_apr_py_amount__c);
            }
            when 5 {
                value = monthValue(isTotal, hbook.total_gross_margin_may_py_amount__c, hbook.xbrdr_gross_margin_may_py_amount__c);
            }
            when 6 {
                value = monthValue(isTotal, hbook.total_gross_margin_jun_py_amount__c, hbook.xbrdr_gross_margin_jun_py_amount__c);
            }
            when else {
                value = contgtMonthValuePY(digit, hbook,isTotal);
            }
        }
        return value;
    }

    /*
    * Continuación getMonthValuePY
    */
    private static Decimal contgtMonthValuePY(Integer digit, DES_Historic_Booking__c hbook, Boolean isTotal) {
        Decimal value;

        switch on digit {
            when 7 {
                value = monthValue(isTotal, hbook.total_gross_margin_jul_py_amount__c, hbook.xbrdr_gross_margin_jul_py_amount__c);
            }
            when 8 {
                value = monthValue(isTotal, hbook.total_gross_margin_aug_py_amount__c, hbook.xbrdr_gross_margin_aug_py_amount__c);
            }
            when 9 {
                value = monthValue(isTotal, hbook.total_gross_margin_sep_py_amount__c, hbook.xbrdr_gross_margin_sep_py_amount__c);
            }
            when 10 {
                value = monthValue(isTotal, hbook.total_gross_margin_oct_py_amount__c, hbook.xbrdr_gross_margin_oct_py_amount__c);
            }
            when 11 {
                value = monthValue(isTotal, hbook.total_gross_margin_nov_py_amount__c, hbook.xbrdr_gross_margin_nov_py_amount__c);
            }
            when 12 {
                value = monthValue(isTotal, hbook.total_gross_margin_dec_py_amount__c, hbook.xbrdr_gross_margin_dec_py_amount__c);
            }
            when else {
                value = 0;
            }
        }
        return value;
    }

    /*
    *Aux method to getMonthValuePY
    */
    private static Decimal monthValue(Boolean isTotal, Decimal totalValue, Decimal noTotalValue) {
        Decimal toReturn;
        toReturn = noTotalValue;
        if(isTotal) {
            toReturn = totalValue;
        }
        return toReturn;
    }
    /*
    * @author Global Desktop
    * @description Construye la wrapper list que se devolvera al componente lightning
    */
    public class WrapperGlobalData {
    	/*Declaracion de variables*/
        private final Map<String, String> mapColumns;
        /*Declaracion de variables*/
        private final Map<String, Map<String, Double>> mapData;

        /*Method que construye le lista wraper*/
        public WrapperGlobalData (Map<String, String> columns, Map<String, Map<String, Double>> data) {
            this.mapColumns = columns;
            this.mapData = data;
        }
    }

    /*
    * Method for detail report
    */
    @AuraEnabled
	public static String getTrigDetail(String clientId, String family) {
        try {
            List<WrapperColumns> wrColumns = new List<WrapperColumns>();

            Final String QUERY = generateQuery(clientId, family, false);
            Final list<DES_Historic_Booking__c> lstHistoricRevs = Database.query(QUERY); //NOSONAR - management of escapeSingleQuotes done in generateQuery() method

            wrColumns = fillWRColumns(lstHistoricRevs);

            String lastCountry = '';
            List<WrapperRow> listRowProduct;
            final List<WrapperData> listData = new List<WrapperData>();
            List<String> listValues;
            final List<String> listCountryString = new List<String>{'','','','','',''};
            system.debug('++ listCountryString ' + listCountryString + ' ' + lastCountry);

            for(DES_Historic_Booking__c hBook : lstHistoricRevs) {
                if(lastCountry != hBook.region_name__c) {       //metemos la fila del pais contenedora
                    if(lastCountry != '') {
                        listData.add(new WrapperData( new WrapperRow(lastCountry, listCountryString), listRowProduct));
                    }
                    lastCountry = hBook.region_name__c;
                    system.debug('++ listCountryString ' + listCountryString + ' ' + lastCountry);
                    listRowProduct = new List<WrapperRow> ();
                }
                listValues = new List<String>();
                for(integer month = 0; month < 6; month++) {
                    // listValues.add(getLast6Values(hBook, month-1));
                    listValues.add(getLast6Values(hBook, month));
                }
                listRowProduct.add(new WrapperRow(hBook.solution_id_path_desc__c, listValues));
            }

            if(!listRowProduct.isEmpty()) {
                listData.add(new WrapperData( new WrapperRow(lastCountry, listCountryString), listRowProduct));
            }

            final WrapperGlobalTableData wrapperGlobal = new WrapperGlobalTableData(wrColumns, listData);
            final String jsonGlobal = JSON.serialize(wrapperGlobal);
            System.debug('::::wrapperGlobal antes de fix: ' + jsonGlobal);

            return helperfixerJson(jsonGlobal);
        } catch (Exception exc) {
            throw new AuraHandledException(Label.DES_Error + exc);
        }
    }

    /*
    * Aux method to format number
    */
    private static List<WrapperColumns> fillWRColumns(list<DES_Historic_Booking__c> lstHistoricRevs) {
        Boolean pastYear;
        String rowName;

        final List<WrapperColumns> wrColumns = new List<WrapperColumns>();
        wrColumns.add(new WrapperColumns('name', 0));
        for(integer month = 0; month < 6; month++) {
            pastYear = Integer.valueOf(lstHistoricRevs.get(0).month_type__c) - month < 1;
            if(pastYear) {
                rowName = UtilsFichaGrupo.parseToMonth( Integer.valueOf(lstHistoricRevs.get(0).month_type__c)+12 - month) + '-' + (Integer.valueOf(lstHistoricRevs.get(0).year_id__c)-1);// + ' : ' + hBook.solution_id_path_desc__c;
            } else {
                rowName = UtilsFichaGrupo.parseToMonth( Integer.valueOf(lstHistoricRevs.get(0).month_type__c) - month) + '-' + Integer.valueOf(lstHistoricRevs.get(0).year_id__c);// + ' : ' + hBook.solution_id_path_desc__c;
            }
            wrColumns.add(new WrapperColumns(rowName, month+2));
        }
        return wrColumns;
    }

    /*
    * Aux method to format number
    */
    private static String formatNumber(Decimal aux) {
        String auy = String.valueOf(aux);
        String auz = '.';
        system.debug(auz);
        String returnValue;
        returnValue = String.valueOf(aux);
        if(auy.contains(',')) {
            auz = ',';
            system.debug(auz);
        }
        if(auy.contains(',') || auy.contains('.')) {
            auy = auy.substring(0, auy.indexOf(auz));
        }
        if(aux - Decimal.valueOf(auy) == 0) {
            returnValue = aux.format() + auz + '00';
        } else {
            returnValue = aux.format();
        }
        return returnValue;
    }

    private static String helperfixerJson(String str) {
        String cadena = str;//sonar requirement
        cadena = cadena.replaceAll('children', '_children');
        //cadena = cadena.replaceAll('\\s*"lstRevenuesByProduct":[\\[\\\\na-zA-Z0-9\\s,\\.\\]]*', '');
        cadena = cadena.replaceAll(',"_children":\\[\\]', '');//empty children = detail row, without ">" icon
        cadena = cadena.replaceAll('typeReplaceMe', 'type');
        System.debug('::::helperfixerJson: ' + cadena);
        return cadena;
    }

    private static String getLast6Values(DES_Historic_Booking__c hBook, integer month) {
        final Boolean pastYear = Integer.valueOf(hBook.month_type__c) - month < 1;
        String result;
        if(pastYear) {
            result = formatNumber(getMonthValuePY(Integer.valueOf(hBook.month_type__c)+12 - month, hbook, true)) + ' ' + UserInfo.getDefaultCurrency();
        } else {
            result = formatNumber(getMonthValueYTD(Integer.valueOf(hBook.month_type__c) - month, hbook, true)) + ' ' + UserInfo.getDefaultCurrency();
        }
        return result;
    }

    /**
	* @author Global Desktop
	* @description sumXBrevenues
	*/
    public class WrapperGlobalTableData {
        /*
        * Var 1
        */
        final private List<WrapperColumns> wrColumns;
        /*
        * Var 2
        */
        final private List<WrapperData> wrData; //NOSONAR
        /*
		* Constructor
		*/
        public WrapperGlobalTableData(List<WrapperColumns> columns, List<WrapperData> data) {
            this.wrColumns = columns;
            this.wrData = data;
        }
    }

    /*
    * wrapperData
    */
    public class WrapperColumns {
        /*
		* field wrapper
		*/
        private String typeReplaceMe; //NOSONAR
        /*
		* field wrapper
		*/
        private String fieldName; //NOSONAR
        /*
		* field wrapper
		*/
        private String label; //NOSONAR
        /*
		* field wrapper
		*/
        private Integer initialWidth; //NOSONAR
        /*
		* Constructor
		*/
        public WrapperColumns(String columna, Integer num) {
            if(columna.equalsIgnoreCase('name')) {
                this.typeReplaceMe = 'text';
                this.initialWidth = 250;
                this.label = '';
                this.fieldName = 'name';
            } else {
                this.typeReplaceMe = 'text';
                this.label = columna;
                this.fieldName = 'columna' + num; //String.valueOf(num);
            }
        }
    }

    /*
    * Aux method to check null string
    */
    private static String checkNullString(String toCheck) {
        String toReturn = null;
        if(toCheck != null) {
            toReturn = toCheck;
        }
        return toReturn;
    }

    /*
    * wrapperData
    */
    public class WrapperRow {
        /*
		* field wrapper
		*/
        private String name;
        /*
		* field wrapper
		*/
        private List<String> lstRevenues;
        /*
		* Constructor
		*/
        public WrapperRow(String nombre, List<String> lstValores) {
            if(nombre != null) {
                this.name = nombre;
            }
            if(lstValores != null) {
                this.lstRevenues = lstValores;
            }
        }
    }

    /*
    * wrapperData
    */
    public class WrapperData {
        /*
        * field wrapper
        */
        private final List<String> lstRevByProd; //NOSONAR
        /*
        * field wrapper
        */
        private final String name; //NOSONAR
        /*
        * field wrapper
        */
        private String columna2; //NOSONAR
        /*
        * field wrapper
        */
        private String columna3; //NOSONAR
        /*
        * field wrapper
        */
        private String columna4; //NOSONAR
        /*
        * field wrapper
        */
        private String columna5; //NOSONAR
        /*
        * field wrapper
        */
        private String columna6; //NOSONAR
        /*
        * field wrapper
        */
        private String columna7; //NOSONAR
        /*
        * field wrapper
        */
        private final List<WrapperData> children = new List<WrapperData>(); //replace by _children before return json

        /*
		* Constructor
		*/
        public WrapperData(WrapperRow row, List<WrapperRow> lstHijos) { //NOSONAR
            this.name = row.name; //columna1
            this.lstRevByProd = row.lstRevenues;
            this.columna2 = '';
            this.columna3 = '';
            this.columna4 = '';
            this.columna5 = '';
            this.columna6 = '';
            this.columna7 = '';

            if(lstHijos != null) {
                for(WrapperRow child : lstHijos) {
                    WrapperData hijo;
                    hijo = new WrapperData(child, null);
                    this.children.add(hijo);
                }
            }
            final List<String> lstValores = row.lstRevenues; //= mapRevenuesByProducto.get('key');

            if(lstValores != null) {
                this.columna2 = RevenuesLastMonthsCnt.checkNullString(lstValores[0]);
                this.columna3 = RevenuesLastMonthsCnt.checkNullString(lstValores[1]);
                this.columna4 = RevenuesLastMonthsCnt.checkNullString(lstValores[2]);
                this.columna5 = RevenuesLastMonthsCnt.checkNullString(lstValores[3]);
                this.columna6 = RevenuesLastMonthsCnt.checkNullString(lstValores[4]);
                this.columna7 = RevenuesLastMonthsCnt.checkNullString(lstValores[5]);
            }
        }


    }
}