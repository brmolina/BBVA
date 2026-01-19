/*
 * @author GlobalDesktop - APC
 * @description Clase base para methods reutilizables para Ficha de Grupo/Filial/producto/geografía...
 */
public with sharing class UtilsFichaGrupo {
  /*
   *   Mes final del calendario
   */
  private final static Integer FINALMONTH = 12;

  /*
   *   Opciones de conversion pais
   */
  private final static String DEVNAME = 'DEVNAME';
  /*
   *   Opciones de conversion pais
   */
  private final static String LABEL = 'LABEL';
  /*
   *   Opciones de conversion pais
   */
  private final static String OPPREGION = 'OPPREGION';
  /*
   *   Opciones de conversion pais
   */
  private final static String NBCREGION = 'NBCREGION';
  /*
   *   Opciones de conversion pais
   */
  private final static String USERCOUNTRY = 'USERCOUNTRY';
  /*
   *   Opciones de conversion pais
   */
  private final static String BOOKCOUNTRY = 'BOOKCOUNTRY';
  /*
   *   Var others
   */
  private final static String OTHERS = 'Others';
  /*
   * Author: Global Desktop
   * con patron sigleton
   *
   */
  private UtilsFichaGrupo() {
  }
  /*
   * Get colors by metadata
   */
  public static Map<String, String> getCountryColor(Set<String> setData) {
    Final Map<String, String> mapCountryColor = new Map<String, String>();
    List<BBVA_Color_Palette__mdt> listFamColor;
    listFamColor = [SELECT Hex_Color__c, Priority__c FROM BBVA_Color_Palette__mdt order by Priority__c asc LIMIT :setData.size()];
    System.debug('::::listFamColor: ' + listFamColor);
    System.debug('::::setData: ' + setData);
    Final Set<String> setColors = new Set<String>();
    Final List<String> lstData = new List<String>(setData);

    if(!listFamColor.isEmpty()) {
      for(BBVA_Color_Palette__mdt color : listFamColor) {
        setColors.add(color.Hex_Color__c );
      }

      Final List<String> lstColors =  new List<String>(setColors);
      system.debug('**setColors -> ' + setColors);
      for(Integer ctr = 0; ctr < lstData.size(); ctr++) {
        mapCountryColor.put(lstData[ctr], lstColors[ctr]);
      }
    }

    System.debug('lstData ' + lstData);
    System.debug('setColors ' + setColors);
    return mapCountryColor;
  }
  /*
   *   @author: GlobalDesktop - APC
   *   @Method: checkTimeWindow
   *   @Description: used to verify whitin a date is inside of a time window (controlDate - monthsWindow)

   *   @Inputs:    WrapperBookingDate wrDate
   *   @Output:    Boolean isValid
   *   @Versions:
          v1 - 2019/05/14 - Initial version
   */
  public static Boolean checkTimeWindow(WrapperBookingDate wrDate) {
    Final Integer DIFFMONTHS = wrDate.yearControl >= wrDate.yearToCheck ? diffMonths(wrDate) : -1;
    // Final Boolean isValid = DIFFMONTHS >= 0  ? true : false; //&& DIFFMONTHS >= wrDate.monthsWindow
    return DIFFMONTHS >= 0  ? true : false;      //&& DIFFMONTHS >= wrDate.monthsWindow
  }
  /*
   *   @author: GlobalDesktop - APC
   *   @Method: diffMonths
   *   @Description:  helper method which calculates the diff in months between two "Month/Year" values

   *   @Inputs:    WrapperBookingDate wrDate
   *   @Output:    Integer months
   *   @Versions:
         v1 - 2019/05/14 - Initial version
   */
  public static Integer diffMonths(WrapperBookingDate wrDate) {
    return (wrDate.monthControl - wrDate.monthToCheck) + 12 * (wrDate.yearControl - wrDate.yearToCheck);
  }


  /*
   *   @author: GlobalDesktop - DRL
   *   @Method: orderMap
   *   @Description:  helper method which order desc a map

   *   @Inputs:    Map<String, Integer> mapData
   *   @Output:    orderMap
   *   @Versions:
          v1 - 2019/06/25 - Initial version
   */
  public static Map<String, Double> orderMap(Map<String, Double> mapData) {
    final Map<String, Double> mapToReturn = new Map<String, Double>();
    final List<Double> listOrder = new List<Double>();
    // for(Double aux : mapData.values()) {
    //     listOrder.add(aux);
    // }

    listOrder.addAll(mapData.values());

    system.debug(' Antes listOrder ' + JSON.serialize(mapData));
    for(Integer i = 0; i < listOrder.size(); i++) {
      for(Integer j = i+1; j <= listOrder.size() -1; j++) {
        Double counter = 0;
        if(listOrder[i] < listOrder[j]) {
          counter = listOrder[i];
          listOrder[i] = listOrder[j];
          listOrder[j] = counter;
        }
      }
    }

    for(Double aux : listOrder) {
      for(String visit : mapData.keySet()) {
        if(mapData.get(visit) == aux && !mapToReturn.containsKey(visit)) {
          mapToReturn.put(visit, aux);
        }
      }
    }
    system.debug(' Despues listOrder ' + JSON.serialize(mapToReturn));
    return mapToReturn;
  }

  /*
   *   @author: GlobalDesktop - DRL
   *   @Method: calculateTopNLev1
   *   @Description:  Group a map in top N values and others by the key of the external Map

   *   @Inputs:   Map<String, Map<String, Double>> mapPais (map to Group), Map <String, Double> paisTotal (orderedMap which first values are displayed),
   *               Integer topN (values which are not grouped)
   *   @Output:    mapOrdered
   *   @Versions:
          v1 - 2019/06/27 - Initial version
   */
  public static Map<String, Map<String, Double> > calculateTopNLev1(Map<String, Map<String, Double> > mapPais, Map <String, Double> paisTotal, Integer topN) {
    Map<String, Map<String, Double> > mapOrdered = new Map <String, Map<String, Double> >();
    if(topN == 0) {
      mapOrdered = mapPais;
    } else {
      Integer auxNumber = 0;
      for(String aux : paisTotal.keySet()) {
        if(auxNumber < topN) {
          mapOrdered.put(aux, mapPais.get(aux));
        } else {
          groupOthers(mapOrdered, mapPais, aux);
        }
        auxNumber++;
        system.debug('auxNumber -> ' + auxNumber);
      }
    }
    return mapOrdered;
  }


  /*
   *   @author: GlobalDesktop - DRL
   *   @Method: calculateTopNLev2
   *   @Description:  Group a map in top N values and others by the key of the internal Map

   *   @Inputs:   Map<String, Map<String, Double>> mapPais (map to Group), Map <String, Double> paisTotal (orderedMap which first values are displayed),
   *               Integer topN (values which are not grouped)
   *   @Output:    mapOrdered
   *   @Versions:
          v1 - 2019/06/27 - Initial version
   */
  public static Map<String, Map<String, Double> > calculateTopNLev2(Map<String, Map<String, Double> > mapProd, Map <String, Double> paisTotal, Integer topN) {
    system.debug('calculateTopNLev2 antes -> ' + JSON.serialize(mapProd));
    Map<String, Map<String, Double> > mapOrdered = new Map <String, Map<String, Double> >();
    Map<String, Double> mapAux = new Map<String,Decimal>();
    if(topN == 0) {
      mapOrdered = mapProd;
    } else {
      for(String aux : mapProd.keySet()) {
        Integer auxNumber = 0;
        mapAux = new Map<String,Decimal>();
        for(String auxCountry : paisTotal.keySet()) {
          if(auxNumber < topN) {
            mapAux.put(auxCountry, mapProd.get(aux).get(auxCountry));
          } else {
            if(mapAux.get(OTHERS) == null) {
              mapAux.put(OTHERS, mapProd.get(aux).get(auxCountry));
            } else {
              mapAux.put(OTHERS, mapAux.get(OTHERS) + mapProd.get(aux).get(auxCountry));
            }
          }
          auxNumber++;
        }
        mapOrdered.put(aux, mapAux);
        system.debug('++ auxNumber -> ' + auxNumber);
      }
    }
    system.debug('++ mapAux -> ' + mapAux);
    system.debug('calculateTopNLev2 -> ' + JSON.serialize(mapOrdered));
    return mapOrdered;
  }

  /*
   *   @author: GlobalDesktop - DRL
   *   @Method: groupOthers
   *   @Description:  aux Method for calculateTopN

   *   @Inputs:   Map<String, Map<String, Double>> mapPais (map to Group), Map <String, Double> paisTotal (orderedMap which first values are displayed),
   *               Integer topN (values which are not grouped)
   *   @Output:    mapOrdered
   *   @Versions:
          v1 - 2019/06/27 - Initial version
   */
  private static Map<String, Map<String, Double> > groupOthers(Map<String, Map<String, Double> > mapToGroup, Map<String, Map<String, Double> > mapPais, String aux) {
    final Map<String, Map<String, Double> > mapOrdered = mapToGroup;
    if(mapOrdered.get(OTHERS) == null) {
      mapOrdered.put(OTHERS, mapPais.get(aux));
    } else {
      for(String auxProd : mapPais.get(aux).keySet()) {
        if(mapOrdered.get(OTHERS).get(auxProd) == null) {
          mapOrdered.get(OTHERS).put(auxProd, mapPais.get(aux).get(auxProd));
        } else {
          final Double totalProd = mapOrdered.get(OTHERS).get(auxProd) + mapPais.get(aux).get(auxProd);
          mapOrdered.get(OTHERS).put(auxProd,totalProd);
        }
      }
    }
    return mapOrdered;
  }


  /*
   *   @author: GlobalDesktop - APC
   *   @Method: parseToMonth
   *   @Description: parse number months to literal month

   *   @Inputs:    Integer digit
   *   @Output:    String literal
   *   @Versions:
          v1 - 2019/05/14 - Initial version
   */
  public static String parseToMonth(Integer digit) {   //NOSONAR
    String literal;

    switch on digit {
      when 1 {
        literal = 'JAN';
      }
      when 2 {
        literal = 'FEB';
      }
      when 3 {
        literal = 'MAR';
      }
      when 4 {
        literal = 'APR';
      }
      when 5 {
        literal = 'MAY';
      }
      when 6 {
        literal = 'JUN';
      }
      when else {
        literal = parseToMonthAux(digit);
      }
    }
    return literal;
  }


  /*
   *   @author: GlobalDesktop - APC
   *   @Method: parseToMonthAux
   *   @Description: parse number months to literal month

   *   @Inputs:    Integer digit
   *   @Output:    String literal
   *   @Versions:
          v1 - 2019/05/14 - Initial version
   */
  private static String parseToMonthAux(Integer digit) {
    String literal;

    switch on digit {
      when 7 {
        literal = 'JUL';
      }
      when 8 {
        literal = 'AUG';
      }
      when 9 {
        literal = 'SEP';
      }
      when 10 {
        literal = 'OCT';
      }
      when 11 {
        literal = 'NOV';
      }
      when 12 {
        literal = 'DEC';
      }
      when else {
        literal = '';
      }
    }
    return literal;
  }
  /*
   *   @author: GlobalDesktop - APC
   *   @Method: parseFromMonth
   *   @Description: parse literal month to number months

   *   @Inputs:    String literal
   *   @Output:    Integer digit
   *   @Versions:
          v1 - 2019/05/29 - Initial version
   */
  public static Integer parseFromMonth(String literal) {
    Integer digit;
    Final String text = literal.toUpperCase();

    switch on text {
      when 'JAN' {
        digit = 1;
      }
      when 'FEB' {
        digit = 2;
      }
      when 'MAR' {
        digit = 3;
      }
      when 'APR' {
        digit = 4;
      }
      when 'MAY' {
        digit = 5;
      }
      when 'JUN' {
        digit = 6;
      }
      when else {
        digit = parseFromMonthAux(literal);
      }
    }
    return digit;
  }


  /*
   *   @author: GlobalDesktop - APC
   *   @Method: parseFromMonthAux
   *   @Description: parse literal month to number months

   *   @Inputs:    String literal
   *   @Output:    Integer digit
   *   @Versions:
          v1 - 2019/05/29 - Initial version
   */
  public static Integer parseFromMonthAux(String literal) {
    Integer digit;
    Final String text = literal.toUpperCase();

    switch on text {
      when 'JUL' {
        digit = 7;
      }
      when 'AUG' {
        digit = 8;
      }
      when 'SEP' {
        digit = 9;
      }
      when 'OCT' {
        digit = 10;
      }
      when 'NOV' {
        digit = 11;
      }
      when 'DEC' {
        digit = 12;
      }
      when else {
        digit = 0;
      }
    }
    return digit;
  }

  /**
   * @author Global Desktop - APC
   * @description Clase que construye la lista wrapper
   */
  public class WrapperBookingDate {
    /* monthsWindow: time window specified in months */
    private Integer monthsWindow;     //NOSONAR
    /* yearControl: year of the last date (controlDate - months = timeWindowToCheck)  */
    private Integer yearControl;     //NOSONAR
    /* monthControl: month of the last date (controlDate - months = timeWindowToCheck)  */
    private Integer monthControl;     //NOSONAR
    /* yearToCheck: year to check */
    private Integer yearToCheck;     //NOSONAR
    /* monthToCheck: month to check */
    private Integer monthToCheck;     //NOSONAR

    /**
     * @author Global Desktop - APC
     * @description WrapperBookingDate´s constructor
     * @Params: (Integer monthToCheck, Integer yearToCheck, Integer monthControl, Integer yearControl, Integer monthsWindow)
     */
    public WrapperBookingDate(Integer monthToCheck, Integer yearToCheck, Integer monthControl, Integer yearControl, Integer monthsWindow) {
      this.monthsWindow = monthsWindow;
      this.yearControl = yearControl;
      this.monthControl = monthControl;
      this.monthToCheck = monthToCheck;
      this.yearToCheck = yearToCheck;
    }
  }
/*************************************************************************************************************
 *   @author: GlobalDesktop - APC
 *   @Method: mapCountryCodesSelector
 *   @Description:

 *   @Returns: List<Opp_Countries__mdt>

 *   @Versions:
        v1 - 2019/01/28 - Initial version
 ***************************************************************************************************************/
  public static List<Opp_Countries__mdt> mapCountryCodesSelector() {
    System.debug(':::::::mapCountries init');
    List<Opp_Countries__mdt> lstCountriesMTD;
    lstCountriesMTD = [SELECT Id, Label, MasterLabel, DeveloperName, Opp_Region__c, NBC_Region__c,
                       Country_User__c, Booking_country__c
                       FROM Opp_Countries__mdt LIMIT 5000];
    if(lstCountriesMTD.isEmpty()) {
      lstCountriesMTD = new List<Opp_Countries__mdt>();
    }
    return lstCountriesMTD;
  }
/******************************************************************************************************************
   Name:           helperCreateMapCountryCodes method
   Description:    Helper que crea mapa de paises - map< codigoPais , stringPais > segun el metadata Opp_Countries__mdt

   Input - String (Enum => (DevName || Label))
   Output - Map(String country.DeveloperName, String country.Label)

   Version             Date        Author                          Summary of changes
   --------------------------------------------------------------------------------------------------------------------
   0.1             22/11/2018      GlobalDesktop - APC          Initial Version
   0.2             05/02/2019      GlobalDesktop - APC          Modes OPPREGION and NBCREGION added
   0.3             21/05/2019      GlobalDesktop - APC          Copied in this class from groupGeographyCnt.cls
 *********************************************************************************************************************/
  public static Map<String,String> helperCreateMapCountryCodes(String mode, List<Opp_Countries__mdt> lstCountriesMTD) {
    System.debug(':::::::mapCountries init');
    final Map<String,String> mapCountryCodes = new Map<String,String>();     //code + string
    // List<Opp_Countries__mdt> lstCountriesMTD = [SELECT Id, Label, MasterLabel, DeveloperName, Opp_Region__c, NBC_Region__c, Country_User__c
    //                                              FROM Opp_Countries__mdt];

    for(Opp_Countries__mdt country : lstCountriesMTD) {
      if(mode == DEVNAME) {
        mapCountryCodes.put(country.DeveloperName, country.Label);
      } else if(mode == LABEL) {
        mapCountryCodes.put(country.Label, country.DeveloperName);
      } else if(mode == OPPREGION) {
        mapCountryCodes.put(country.DeveloperName, country.Opp_Region__c);
      } else if(mode == NBCREGION) {
        mapCountryCodes.put(country.DeveloperName, country.NBC_Region__c);
      } else if(mode == USERCOUNTRY) {
        mapCountryCodes.put(country.Country_User__c, country.DeveloperName);
      } else if(mode == BOOKCOUNTRY) {
        mapCountryCodes.put(country.Label, country.Booking_country__c);
      }
    }
    System.debug( 'Options: ' + DEVNAME + ', ' + LABEL + ', ' + OPPREGION + ', ' + NBCREGION + ', ' + USERCOUNTRY + ', ' + BOOKCOUNTRY);
    System.debug(':::::::mapCountries: ' + mapCountryCodes);
    return mapCountryCodes;
  }
  /**
   * @author Global Desktop
   * @description Construye el formato de la fecha
   */
  public static Date getDate(String month, String year) {
    final Integer monthInt = Integer.valueOf(month);
    final Integer monthLaterInt = Integer.valueOf(month) + 1;
    final String monthLater = String.valueOf(monthLaterInt);
    Date dateBooking = Date.today();

    if(monthInt == FINALMONTH) {
      dateBooking = Date.valueOf(year + '-' + month + '-31');
    } else {
      dateBooking = Date.valueOf(year + '-' + monthLater + '-01').addDays(-1);
    }
    System.debug('monthLater ' + monthLater);
    return dateBooking;
  }
  /**
   * @author Global Desktop
   * @description Devuelve un mapa con el IsoCode y el valor el coversion Rate de EUR a esa IsoCode
   */
  public static Map<String, Decimal> conversionCurrency() {
    final Map<String, Decimal> currencyValue = new Map <String, Decimal>();
    final List<CurrencyType> currencies = new List <CurrencyType>([
                                                                    SELECT Id, IsoCode, ConversionRate, DecimalPlaces, IsActive, IsCorporate
                                                                    FROM currencyType
                                                                    WHERE IsActive = true
                                                                  ]);
    for(CurrencyType currencyRecord : currencies) {
      currencyValue.put(currencyRecord.IsoCode, currencyRecord.ConversionRate);
    }
    return currencyValue;
  }
}