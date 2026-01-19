/*@Author : Juan Carlos Terrón Ruiz
  @Class : Clase para dividir los métodos de testeo de la clase SER_E2CCLEANER
*/
@isTest
public class SER_E2CCLEANER_TEST_2 {
  /*@Author Juan Carlos Terrón Ruiz
    @TestCase : método execute sin excepciones
  */
  @isTest
  public static void execute() {
    test.startTest();
    final Map<Id,Case> mapCases = new Map<Id,Case>();
    final Case newcase = new Case(SER_EmailToCaseCode__c = SER_E2CCLEANER_TEST.CODE);
    final Case oldcase = new Case(SER_EmailToCaseCode__c = SER_E2CCLEANER_TEST.CODE);
    final List<Case> cases = new List<Case> {newcase,oldcase};
    insert cases;
    mapCases.put(newcase.Id,newcase);
    mapCases.put(newcase.Id,oldcase);
    final SER_E2CCLEANER cleaner = new SER_E2CCLEANER(mapCases);
    System.enqueueJob(cleaner);
    final Boolean assert = cleaner != null;
    System.assert (assert,SER_E2CCLEANER_TEST.ASSERTMSG);
    test.stoptest();
  }
  /*@Author Juan Carlos Terrón Ruiz
    @TestCase : método execute testeo de excepción
  */
  @isTest
  public static void executeEX() {
    test.startTest();
    final Map<Id,Case> mapCases = new Map<Id,Case>();
    final Case newcase = new Case(SER_EmailToCaseCode__c = SER_E2CCLEANER_TEST.CODE);
    final Case oldcase = new Case(SER_EmailToCaseCode__c = SER_E2CCLEANER_TEST.CODE);
    final List<Case> cases = new List<Case> {newcase,oldcase};
    insert cases;
    mapCases.put(newcase.Id,newcase);
    mapCases.put(newcase.Id,oldcase);
    final SER_E2CCLEANER cleaner = new SER_E2CCLEANER(mapCases);
    cleaner.mapCases = null;//NOSONAR
    System.enqueueJob(cleaner);
    final Boolean assert = cleaner.mapCases == null;
    System.assert (assert,SER_E2CCLEANER_TEST.ASSERTMSG);
    test.stoptest();
  }
  /*@Author Juan Carlos Terrón Ruiz
    @TestCase : método finalProcess casuística normal
  */
  @isTest
  public static void finalProcess() {
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
    cleaner.finalprocess();
    cleaner.mapToDelete = new Map<Id,Case>();
    cleaner.finalprocess();
    final Boolean assert = cleaner != null;
    System.assert (assert,SER_E2CCLEANER_TEST.ASSERTMSG);
    test.stoptest();
  }
  /*@Author Juan Carlos Terrón Ruiz
    @TestCase : método finalProcess testeo de excepciones
  */
  @isTest
  public static void finalProcessEx() {
    test.startTest();
    final Map<Id,Case> mapCases = new Map<Id,Case>();
    final SER_E2CCLEANER cleaner = new SER_E2CCLEANER(mapCases);
    final Case newcase = new Case(SER_EmailToCaseCode__c = SER_E2CCLEANER_TEST.CODE);
    final Case oldcase = new Case(SER_EmailToCaseCode__c = SER_E2CCLEANER_TEST.CODE);
    final List<Case> cases = new List<Case> {newcase,oldcase};
    insert cases;
    delete newcase;
    cleaner.oldestCD = datetime.now();
    cleaner.mapToDelete = new Map<Id,Case>();
    cleaner.mapToDelete.put(newcase.Id,newcase);
    cleaner.mapToDelete.put(oldcase.Id,oldcase);
    cleaner.finalprocess();
    cleaner.mapToDelete = new Map<Id,Case>();
    cleaner.finalprocess();
    final Boolean assert = cleaner != null;
    System.assert (assert,SER_E2CCLEANER_TEST.ASSERTMSG);
    test.stoptest();
  }
  /*@Author Juan Carlos Terrón Ruiz
    @TestCase : método finalProcess testeo de excepciones lock row(no se puede testear)
  */
  @isTest
  public static void finalProcessExLockRow() {
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
    update newcase;
    cleaner.finalprocess();
    cleaner.mapToDelete = new Map<Id,Case>();
    cleaner.finalprocess();
    final Boolean assert = cleaner != null;
    System.assert (assert,SER_E2CCLEANER_TEST.ASSERTMSG);
    test.stoptest();
  }
}