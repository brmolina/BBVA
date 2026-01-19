/*
 * @author Global Desktop
 * Description: MatrixTreeGridReportCntTest
 */
@isTest
public class MatrixTreeGridReportCntTest {
  /*
   * @author Global Desktop
   * Description: caseinstance of utilTestClass
   */
  private static DES_UtilTestClass utilTestClass = new DES_UtilTestClass();
  /*
   * @author Global Desktop
   * Description: constant pais = ESPAÑA
   */
  private static String pais = 'ESPAÑA';
  /*
   * @author Global Desktop
   * Description: constant pais = ESPAÑA
   */
  Final static Integer LSTSIZE = 5;

  /*
   * @author Global Desktop
   * Description: case 1
   */
  @isTest
  public static void responseOKPais() {
    Final List<DES_Booking__c> lstBooks = new List<DES_Booking__c>();
    Boolean devuelveJSON = false;
    //Nuevo cliente
    Final Account acc = utilTestClass.createClient();
    insert acc;
    //Creando bookings
    for(Integer i = 0; i < LSTSIZE; i++) {
      Final DES_Booking__c booking = utilTestClass.createBooking(acc, pais, pais, 1000,'GTB', '2018');
      booking.DES_Engloba_Load_Helper__c = '0';
      booking.DES_Client__c = acc.id;
      lstBooks.add(booking);
    }

    insert lstBooks;

    Test.startTest();
    Final String response = MatrixTreeGridReportCnt.getInfo(generateParams(acc.Id, 'REGION'));
    if(response != null) {
      devuelveJSON = true;
    }
    System.assert (devuelveJSON, 'Response OK');
    Test.stopTest();
  }
  /*
   * @author Global Desktop
   * Description: case 2
   */
  @isTest
  public static void responseOKRegion() {
    Final List<DES_Booking__c> lstBooks = new List<DES_Booking__c>();
    Boolean devuelveJSON = false;
    //Nuevo cliente
    Final Account acc = utilTestClass.createClient();
    insert acc;
    //Creando bookings
    for(Integer i = 0; i < LSTSIZE; i++) {
      Final DES_Booking__c booking = utilTestClass.createBooking(acc, pais, pais, 1000,'GTB', '2018');
      booking.DES_Engloba_Load_Helper__c = '0';
      booking.DES_Client__c = acc.id;
      lstBooks.add(booking);
    }

    insert lstBooks;

    Test.startTest();
    Final String response = MatrixTreeGridReportCnt.getInfo(generateParams(acc.Id, 'COUNTRY'));
    if(response != null) {
      devuelveJSON = true;
    }
    System.assert (devuelveJSON, 'Response OK');
    Test.stopTest();
  }
  /*
   * @author Global Desktop
   * Description: case 3
   */
  @isTest
  public static void responseNullRegion() {
    Final MatrixTreeGridReportCnt instance = MatrixTreeGridReportCnt.getInstance();
    System.debug(instance);
    Boolean devuelveJSON = false;
    //Nuevo cliente
    Final Account acc = utilTestClass.createClient();
    insert acc;

    Test.startTest();
    Final String response = MatrixTreeGridReportCnt.getInfo(generateParams(acc.Id, 'COUNTRY'));
    if(response != null) {
      devuelveJSON = true;
    }
    System.assert (!devuelveJSON, 'Response null OK');
    Test.stopTest();
  }

  /*
          Title
          Product GAP Analysis

          Query:
          SELECT Id, DES_Revenues__c, DES_Type__c, DES_Region__c,
          SOLUTION_CATEGORY_NAME__c, DES_Client__c, DES_Client__r.Name, DES_Engloba_Load_Helper__c,
          DES_Country__c FROM DES_Booking__c WHERE DES_Engloba_Load_Helper__c = '0'  AND DES_XB__c = false AND DES_Client__c = @THISRECORD@

          Label Primaria
          Country

          Api Primaria
          DES_Country__c

          Label Complementaria
          Region

          Api Complementaria
          DES_Region__c

          Label of total column
          -opcional-

          Api primary row
          DES_Type__c

          Api children rows
          SOLUTION_CATEGORY_NAME__c

          Api decimal values
          DES_Revenues__c

          groupBy ==> country || region

   */
  private static String generateParams(String recId, String groupBy) {

    String labelFirstGr;
    labelFirstGr = 'Country';
    String labelSecondGr;
    labelSecondGr = 'Region';
    String fieldFirstGr;
    fieldFirstGr = 'DES_Country__c';
    String fieldSecondGr;
    fieldSecondGr = 'DES_Region__c';
    String labelTotalColumn;
    labelTotalColumn = '';
    String fieldRowPrimary;
    fieldRowPrimary = 'DES_Type__c';
    String fieldRowChild;
    fieldRowChild = 'SOLUTION_CATEGORY_NAME__c';
    String fieldDecimalVal;
    fieldDecimalVal = 'DES_Revenues__c';

    String recordId;
    recordId = recId;
    String columnsGroupBy;
    columnsGroupBy = groupBy;
    String queryInput;
    queryInput = 'SELECT Id, DES_Revenues__c, DES_Type__c, DES_Region__c, SOLUTION_CATEGORY_NAME__c, DES_Client__c, DES_Client__r.Name, DES_Engloba_Load_Helper__c,';
    queryInput += ' DES_Country__c FROM DES_Booking__c WHERE DES_Engloba_Load_Helper__c = \'0\'  AND DES_XB__c = false AND DES_Client__c = @THISRECORD@';

    // Labels labels = labels;
    Final Labels label = new Labels(labelFirstGr, labelSecondGr, fieldFirstGr, fieldSecondGr, labelTotalColumn, fieldRowPrimary, fieldRowChild, fieldDecimalVal);
    Final Params params = new Params(recordId, columnsGroupBy, queryInput, label);


    return JSON.serialize(params);
  }
  /*
   * object Labels
   */
  public class Labels {
    /*
     * labelFirstGr
     */
    Final private String labelFirstGr;
    /*
     * labelSecondGr
     */
    Final private String labelSecondGr;
    /*
     * fieldFirstGr
     */
    Final private String fieldFirstGr;
    /*
     * fieldSecondGr
     */
    Final private String fieldSecondGr;
    /*
     * labelTotalColumn
     */
    Final private String labelTotalColumn;
    /*
     * fieldRowPrimary
     */
    Final private String fieldRowPrimary;
    /*
     * fieldRowChild
     */
    Final private String fieldRowChild;
    /*
     * fieldDecimalVal
     */
    Final private String fieldDecimalVal;
    /*
     * constructor Labels()
     */
    public Labels(String labelFirstGr, String labelSecondGr, String fieldFirstGr, String fieldSecondGr, String labelTotalColumn, String fieldRowPrimary, String fieldRowChild, String fieldDecimalVal) {
      this.labelFirstGr = labelFirstGr;
      this.labelSecondGr = labelSecondGr;
      this.fieldFirstGr = fieldFirstGr;
      this.fieldSecondGr = fieldSecondGr;
      this.labelTotalColumn = labelTotalColumn;
      this.fieldRowPrimary = fieldRowPrimary;
      this.fieldRowChild = fieldRowChild;
      this.fieldDecimalVal = fieldDecimalVal;
    }
  }
  /*
   * Object Params
   */
  public class Params {
    /*
     * recordId
     */
    Final private String recordId;
    /*
     * columnsGroupBy
     */
    Final private String columnsGroupBy;
    /*
     * queryInput
     */
    Final private String queryInput;
    /*
     * labels
     */
    Final private Labels labels;     //NOSONAR -> it is used...
    /*
     * constructor Params()
     */
    public Params(String recordId, String columnsGroupBy, String queryInput, Labels labels) {
      this.recordId = recordId;
      this.columnsGroupBy = columnsGroupBy;
      this.queryInput = queryInput;
      this.labels = labels;
    }
  }
}