/*
* @author Global Desktop
* @description Aux class to utils methods
*/
public with sharing class Desktop_Utils2 {
  /*
  * @author Global Desktop
  * @Description instance
  */
  private static Desktop_Utils2 instance;

  /**
  * @author Global Desktop
  * @Description Empty constructor
  */
  private Desktop_Utils2() {
    System.debug('Empty constructor');
  }

  /*
  * @author Global Desktop
  * @Description gtInstance method
  */
  public static Desktop_Utils2 gtInstance() {
    if (instance == null) {
      instance = new Desktop_Utils2();
    }
    return instance;
  }

  /*
  * @author Global Desktop
  * @Description Method to generate externalId with date
  */
  public static String generateExtId() {
    final String miliseconds = completeString(String.valueOf(System.now().millisecondGMT()));
    final Decimal random = (Math.random()*1000).round();
    String randomText = '';
    if(random == 1000) {
      randomText = '999';
    } else {
      randomText = completeString(String.valueOf(random));
    }
    final Datetime gmtDate = Datetime.newInstanceGmt(
      System.now().year(),
      System.now().month(),
      System.now().day(),
      System.now().hour(),
      System.now().minute(),
      System.now().second());
    return gmtDate.format('yyMMddhhmmss') + miliseconds + randomText;
  }

  /*
  * @author Global Desktop
  * @Description Method to complete String with zeroes
  */
  private static String completeString(String numberToComplete) {
    String numberaux = numberToComplete;
    if(numberaux.length() == 1) {
      numberaux = '00' + numberaux;
    } else if (numberaux.length() == 2) {
      numberaux = '0' + numberaux;
    }
    return numberaux;
  }
}