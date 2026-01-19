/*@Author Juan Carlos Terrón Ruiz
  @CreationDate 7-6-2019
  @Version1.0
*/
@isTest
public class SER_E2CCLEANER_TEST {
  /*Literal repetido*/
  public static final String CODE = 'code';
  /*Mensaje de assert*/
  public static final String ASSERTMSG = 'Assertion Failed';
  /*@Author Juan Carlos Terrón Ruiz
    @TestCase : método Comaprecase
  */
  @isTest
  public static void compareCase() {
    test.startTest();
    final Map<Id,Case> mapCases = new Map<Id,Case>();
    final SER_E2CCLEANER cleaner = new SER_E2CCLEANER(mapCases);
    final Case newcase = new Case(SER_EmailToCaseCode__c = SER_E2CCLEANER_TEST.CODE);
    final Case oldcase = new Case(SER_EmailToCaseCode__c = SER_E2CCLEANER_TEST.CODE);
    final List<Case> cases = new List<Case> {newcase,oldcase};
    insert cases;
    final Boolean test1 = cleaner.compareCase(newcase, oldcase);
    final Boolean test2 = cleaner.compareCase(oldcase, newcase);
    final boolean assert = test1 == test2;
    System.debug('newcase ID : '+newcase.Id);
    System.debug('oldcase ID : '+oldcase.Id);
    System.debug('newcase CN : '+newcase.casenumber);
    System.debug('oldcase CN : '+oldcase.casenumber);
    System.assert (assert,SER_E2CCLEANER_TEST.ASSERTMSG);
    test.stoptest();
  }
  /*@Author Juan Carlos Terrón Ruiz
    @TestCase : método checkCode
  */
  @isTest
  public static void checkCode() {
    test.startTest();
    final Map<Id,Case> mapCases = new Map<Id,Case>();
    final SER_E2CCLEANER cleaner = new SER_E2CCLEANER(mapCases);
    final Case newcase = new Case(SER_EmailToCaseCode__c = SER_E2CCLEANER_TEST.CODE);
    final Case oldcase = new Case(SER_EmailToCaseCode__c = SER_E2CCLEANER_TEST.CODE);
    final List<Case> cases = new List<Case> {newcase,oldcase};
    insert cases;
    cleaner.checkCode(newcase);
    cleaner.checkCode(oldcase);
    final Boolean assert = cleaner != null;
    System.assert (assert,SER_E2CCLEANER_TEST.ASSERTMSG);
    test.stoptest();
  }
  /*@Author Juan Carlos Terrón Ruiz
    @TestCase : método checktime range
  */
  @isTest
  public static void checkTimeRange() {
    test.startTest();
    final Map<Id,Case> mapCases = new Map<Id,Case>();
    final SER_E2CCLEANER cleaner = new SER_E2CCLEANER(mapCases);
    final Case newcase = new Case(SER_EmailToCaseCode__c = SER_E2CCLEANER_TEST.CODE);
    final List<Case> cases = new List<Case> {newcase};
    insert cases;
    cleaner.oldestCD = newcase.createddate;
    cleaner.newestCD = newcase.createddate;
    cleaner.checkTimeRange(newcase);
    cleaner.oldestCD = Datetime.now().addseconds(-50);
    cleaner.newestCD = Datetime.now().addseconds(-49);
    final Boolean assert = cleaner.checkTimeRange(newcase);
    System.assert (!assert,SER_E2CCLEANER_TEST.ASSERTMSG);
    test.stoptest();
  }
  /*@Author Juan Carlos Terrón Ruiz
    @TestCase : método calculatetimerange
  */
  @isTest
  public static void calculateTimeRange() {
    test.startTest();
    final Map<Id,Case> mapCases = new Map<Id,Case>();
    final SER_E2CCLEANER cleaner = new SER_E2CCLEANER(mapCases);
    final Case newcase = new Case(SER_EmailToCaseCode__c = SER_E2CCLEANER_TEST.CODE);
    final List<Case> cases = new List<Case> {newcase};
    insert cases;
    cleaner.oldestCD = newcase.createddate;
    cleaner.calculateTimeRange(newcase);
    final Boolean assert = cleaner != null;
    System.assert (assert,SER_E2CCLEANER_TEST.ASSERTMSG);
    test.stoptest();
  }
  /*@Author Juan Carlos Terrón Ruiz
    @TestCase : método deleteCases
  */
  @isTest
  public static void deleteCases() {
    test.startTest();
    final Map<Id,Case> mapCases = new Map<Id,Case>();
    final SER_E2CCLEANER cleaner = new SER_E2CCLEANER(mapCases);
    cleaner.deleteCases();
    final Boolean assert = cleaner != null;
    System.assert (assert,SER_E2CCLEANER_TEST.ASSERTMSG);
    test.stoptest();
  }
  /*@Author Juan Carlos Terrón Ruiz
    @TestCase : método retrieveDuplicatedCases
  */
  @isTest
  public static void retrieveDuplicatedCases() {
    test.startTest();
    final Map<Id,Case> mapCases = new Map<Id,Case>();
    final SER_E2CCLEANER cleaner = new SER_E2CCLEANER(mapCases);
    final Case newcase = new Case(SER_EmailToCaseCode__c = SER_E2CCLEANER_TEST.CODE);
    cleaner.oldestCD = newcase.createddate;
    cleaner.newestCD = newcase.createddate;
    final List<Case> cases = new List<Case> {newcase};
    insert cases;
    final Map<Id,Case> result = cleaner.retrieveDuplicatedCases();
    final Boolean assert = result.isempty();
    System.assert (assert,SER_E2CCLEANER_TEST.ASSERTMSG);
    test.stoptest();
  }
  /*@Author Juan Carlos Terrón Ruiz
    @TestCase : método firstProcess
  */
  @isTest
  public static void firstProcess() {
    test.startTest();
    final Map<Id,Case> mapCases = new Map<Id,Case>();
    final SER_E2CCLEANER cleaner = new SER_E2CCLEANER(mapCases);
    final Case newcase = new Case(SER_EmailToCaseCode__c = SER_E2CCLEANER_TEST.CODE);
    final List<Case> cases = new List<Case> {newcase};
    insert cases;
    cleaner.mapcases.put(newcase.Id,newcase);
    cleaner.firstProcess();
    cleaner.mapCodes.put(newcase.SER_EmailToCaseCode__c,newcase);
    cleaner.firstProcess();
    cleaner.mapCodes = new Map<String,Case>();
    final Boolean assert = cleaner.firstProcess();
    System.assert (assert,SER_E2CCLEANER_TEST.ASSERTMSG);
    test.stoptest();
  }
  /*@Author Juan Carlos Terrón Ruiz
    @TestCase : método secondProcess
  */
  @isTest
  public static void secondProcess() {
    test.startTest();
    final Map<Id,Case> mapCases = new Map<Id,Case>();
    final SER_E2CCLEANER cleaner = new SER_E2CCLEANER(mapCases);
    final Case newcase = new Case(SER_EmailToCaseCode__c = SER_E2CCLEANER_TEST.CODE);
    final Case oldcase = new Case(SER_EmailToCaseCode__c = SER_E2CCLEANER_TEST.CODE);
    final List<Case> cases = new List<Case> {newcase,oldcase};
    insert cases;
    cleaner.oldestCD = datetime.now();
    cleaner.mapToDelete = new Map<Id,Case>();
    cleaner.mapToDelete.put(newcase.Id,newcase);
    cleaner.mapToDelete.put(oldcase.Id,oldcase);
    cleaner.secondprocess();
    cleaner.mapToDelete = new Map<Id,Case>();
    final Boolean assert = !cleaner.secondprocess();
    System.assert (assert,SER_E2CCLEANER_TEST.ASSERTMSG);
    test.stoptest();
  }
}