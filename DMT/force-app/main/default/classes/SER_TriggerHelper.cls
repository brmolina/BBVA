/*------------------------------------------------------------------------------
        Author:
        Company:
        Description:   Ser_TriggerHelper

        History:
        <Date>          <Author>                <Description>

---------------------------------------------------------------------------------*/
public with sharing class SER_TriggerHelper {


  private SER_TriggerHelper () {
  }
  /*------------------------------------------------------------------------------
        Author:
        Company:
        Description:   get y set del mapFiredTriggers
  --------------------------------------------------------------------------------*/
  public static Map<String,Boolean> mapFiredTriggers {get; set;}
  /*------------------------------------------------------------------------------
        Author:
        Company:
        Description:   get y set del mapFiredMethods
  --------------------------------------------------------------------------------*/
  public static Map<String,Boolean> mapFiredMethods {get; set;}

  static {
    if(mapFiredTriggers == null) { mapFiredTriggers = new Map<String,Boolean>(); }
    if(mapFiredMethods == null) { mapFiredMethods = new Map<String,Boolean>(); }
  }
  /*------------------------------------------------------------------------------
        Author:
        Company:
        Description:   getTriggerFired
  --------------------------------------------------------------------------------*/
  public static Boolean getTriggerFired(String triggerName) {
    boolean auxBl;
    if(mapFiredTriggers.containsKey(triggerName)) {
      auxBl =  mapFiredTriggers.get(triggerName);
    } else {
      auxBl = false;
    }
    return auxBl;
  }
  /*------------------------------------------------------------------------------
        Author:
        Company:
        Description:   setTriggerFired
  --------------------------------------------------------------------------------*/
  public static void setTriggerFired(String triggerName, Boolean isFired) {
    final String strRawName = triggerName.toLowerCase('en_US');
    if(mapFiredTriggers.containsKey(strRawName)) {
      mapFiredTriggers.put(strRawName,isFired);
    } else {
      mapFiredTriggers.put(strRawName,isFired);
    }
  }
  /*------------------------------------------------------------------------------
        Author:
        Company:
        Description:   get_MethodFired
  --------------------------------------------------------------------------------*/
  public static Boolean get_MethodFired(String methodName) {
    final String strRawName = methodName.toLowerCase('en_US');
    boolean auxBl;
    if(mapFiredMethods.containsKey(strRawName)) {
      auxBl = mapFiredMethods.get(strRawName);
    } else {
      auxBl = false;
    }
    return auxBl;
  }
  /*------------------------------------------------------------------------------
        Author:
        Company:
        Description:   set_MetodFired
  --------------------------------------------------------------------------------*/
  public static void set_MetodFired(String methodName, Boolean isFired) {
    final String strRawName = methodName.toLowerCase('en_US');
    if(mapFiredMethods.containsKey(strRawName)) {
      mapFiredMethods.put(strRawName,isFired);
    } else {
      mapFiredMethods.put(strRawName,isFired);
    }
  }
}