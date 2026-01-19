/*-----------------------------------------------------------------------------------------------
    Author:
    Company:
    Description:   This class contains trigger helper of Case Object

    History:
    <Date>          <Author>                <Description>
                                                                        Initial version
    -------------------------------------------------------------------------------------------------*/

public with sharing class SER_Case_TriggerHelper {

/*-----------------------------------------------------------------------------------------------
    Author:
    Company:
    Description:   Get/Set del booleano bl_E2CProcessing
    -------------------------------------------------------------------------------------------------*/
  public static Boolean bl_E2CProcessing {get; set;}
/*-----------------------------------------------------------------------------------------------
    Author:
    Company:
    Description:   Get/Set del mapa Email to Case
    -------------------------------------------------------------------------------------------------*/
  public static Map<Id,Case> map_EmailToCase {get; set;}
/*-----------------------------------------------------------------------------------------------
    Author:
    Company:
    Description:   Get/Set del mapa Duplicated Email to Case
    -------------------------------------------------------------------------------------------------*/
  public static Map<Id,Case> map_DuplicatedEmailToCase {get; set;}
/*-----------------------------------------------------------------------------------------------
    Author:
    Company:
    Description:   Get/Set del mapa de notificación de Master Case
    -------------------------------------------------------------------------------------------------*/
  public static Map<Id,Case> map_NotifiedMasterCases {get; set;}

  static {
    bl_E2CProcessing = false;
    if(map_EmailToCase == null) {
      map_EmailToCase = new Map<Id,Case>();
    }
    if(map_DuplicatedEmailToCase == null) {
      map_DuplicatedEmailToCase = new Map<Id,Case>();
    }
    if(map_NotifiedMasterCases == null) {
      map_NotifiedMasterCases = new Map<Id,Case>();
    }
  }
}