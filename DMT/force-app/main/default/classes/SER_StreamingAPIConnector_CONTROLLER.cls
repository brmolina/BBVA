public class SER_StreamingAPIConnector_CONTROLLER {
  @AuraEnabled
  public static String getSessionId() { 
    String result;
    try {
      result =  UserInfo.getSessionId();
    } catch(Exception error) {
      System.debug('getSessionId ERROR');
      result = null;
    }
    return result;
  }
}