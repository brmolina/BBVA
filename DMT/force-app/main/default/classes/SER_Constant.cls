/*---------------------------------------------------------------------
    Author:        Jose Luis Aranda
    Company:       Accenture
    Description:   Class that contains different Service Cloud constants

    History:
    <Date>          <Author>                <Description>
    13/11/2017      Jose Luis Aranda        Initial version
---------------------------------------------------------------------*/
public with sharing class SER_Constant {

  /*****************NEGOCIOS*****************/
  /**Business Case Type STE*/
  public static final String BUSINESS_STE = 'STE';
  /**Business Case Type GNC*/
  public static final String BUSINESS_GNC = 'GNC';
  /**Business Case Type GM*/
  public static final String BUSINESS_GM = 'GM';
  /**Business Case Type GTB*/
  public static final String BUSINESS_GTB = 'GTB';
  /**Business Case Type EGS*/
  public static final String BUSINESS_EGS = 'EGS';
  /***************FIN NEGOCIOS***************/


  /*****************EMAILS*****************/
  /**Constante ANS_EMAIL*/
  public static final String ANS_EMAIL = 'ans_clientcloud@bbva.com';
  /***************FIN EMAILS***************/


  /*****************WEB SERVICE*****************/
  //Mensajes del servicio
  /*Constante 'Operation successful.'*/
  public static final String MSG_SUCCESS = 'Operation successful.';
  /*Constante 'Failure to insert.'*/
  public static final String MSG_FAIL = 'Failure to insert.';
  /*Constante 'Incorrect or null value found in required fields'*/
  public static final String MSG_ERROR_FIELDS = 'Incorrect or null value found in required fields';
  /*Constante 'Fields with exceeded size'*/
  public static final String MSG_ERROR_SIZE = 'Fields with exceeded size';
  /*Constante 'Product not found'*/
  public static final String MSG_ERROR_PRODUCT = 'Product not found ';
  /*Constante 'Account not found for Product'*/
  public static final String MSG_ERROR_ACCOUNT = 'Account not found for Product';
  /*Constante 'Access from Web Service REST'*/
  public static final String MSG_ACCESS = 'Access from Web Service REST';
  /***************FIN WEB SERVICE***************/

  /*****************REMEDY*****************/
  /*Constante REMEDY_ID*/
  public static final string REMEDY_ID = 'Remedy_1234';
  /*Constante TOOLONGCOMMENT*/
  public static final string TOOLONGCOMMENT = '12345678901234567890123456789012345678901234567890123456789012345678901234567890123456789012345678901234567890123456789012345678901234567890123456789012345678901234567890123456789012345678901234567890123456789012345678901234567890123456789012345678901234567890123456789012345678901234567890123456789012345678901234567890123456789012345678901234567890123456789012345678901234567890123456789012345678901234567890123456789012345678901234567890123456789012345678901234567890123456789012345678901234567890123456789012345678901234567890123456789012345678901234567890123456789012345678901234567890123456789012345678901234567890123456789012345678901234567890123456789012345678901234567890123456789012345678901234567890123456789012345678901234567890123456789012345678901234567890123456789012345678901234567890123456789012345678901234567890123456789012345678901234567890123456789012345678901234567890123456789012345678901234567890123456789012345678901234567890123456789012345678901234567890123456789012345678901234567890123456789012345678901234567890123456789012345678901234567890123456789012345678901234567890123456789012345678901234567890123456789012345678901234567890123456789012345678901234567890123456789012345678901234567890123456789012345678901234567890123456789012345678901234567890123456789012345678901234567890123456789012345678901234567890123456789012345678901234567890123456789012345678901234567890123456789012345678901234567890123456789012345678901234567890123456789012345678901234567890123456789012345678901234567890123456789012345678901234567890123456789012345678901234567890123456789012345678901234567890123456789012345678901234567890123456789012345678901234567890123456789012345678901234567890123456789012345678901234567890123456789012345678901234567890123456789012345678901234567890123456789012345678901234567890123456789012345678901234567890123456789012345678901234567890123456789012345678901234567890123456789012345678901234567890123456789012345678901234567890123456789012345678901234567890123456789012345678901234567890123456789012345678901234567890123456789012345678901234567890123456789012345678901234567890123456789012345678901234567890123456789012345678901234567890123456789012345678901234567890123456789012345678901234567890123456789012345678901234567890123456789012345678901234567890123456789012345678901234567890123456789012345678901234567890123456789012345678901234567890123456789012345678901234567890123456789012345678901234567890123456789012345678901234567890123456789012345678901234567890123456789012345678901234567890123456789012345678901234567890123456789012345678901234567890123456789012345678901234567890123456789012345678901234567890123456789012345678901234567890123456789012345678901234567890123456789012345678901234567890123456789012345678901234567890123456789012345678901234567890123456789012345678901234567890123456789012345678901234567890123456789012345678901234567890123456789012345678901234567890123456789012345678901234567890123456789012345678901234567890123456789012345678901234567890123456789012345678901234567890123456789012345678901234567890123456789012345678901234567890123456789012345678901234567890123456789012345678901234567890123456789012345678901234567890123456789012345678901234567890123456789012345678901234567890123456789012345678901234567890123456789012345678901234567890123456789012345678901234567890123456789012345678901234567890123456789012345678901234567890123456789012345678901234567890123456789012345678901234567890123456789012345678901234567890123456789012345678901234567890123456789012345678901234567890123456789012345678901234567890123456789012345678901234567890123456789012345678901234567890123456789012345678901234567890123456789012345678901234567890123456789012345678901234567890123456789012345678901234567890123456789012345678901234567890';
  /*Constante 'Remedy - Pending to close'*/
  public static final string PENDINGTOCLOSE = 'Remedy - Pending to close';
  /*Constante 'Send Attachment'*/
  public static final string SENDATTACHMENT = 'Send Attachment';
  /*Constante 'Remedy - Pending information'*/
  public static final string PENDINGINF = 'Remedy - Pending information';
  /*Constante 'Send Comment'*/
  public static final string SENDCOMMENT = 'Send Comment';
  /*Constante 'Send Comment'*/
  public static final string UPDATEREMEDY = 'update remedy';
  /*Constante 'Send Comment'*/
  public static final string REMEDYSCALATED = 'Remedy - Escalated';
  /*Constante 'ans banca de empresas'*/
  public static final string ANSBANCEMP = 'ANS Banca de Empresas';
  /*Constante 'ANS SSTT'*/
  public static final string ANSSSTT = 'ANS SSTT';
  /*Constante 'Your ticket has been submitted'*/
  public static final string SUBMITED = 'Your ticket has been submitted';
  /*Constante 'new remedy'*/
  public static final string NEWREMEDY = 'new remedy';
  /*Constante 'Remedy - Rejected'*/
  public static final string REJECTED = 'Remedy - Rejected';
  /***************FIN REMEDY***************/


  /*****************OTROS*****************/
  /*Constante 40*/
  public static final Integer LENGTH40 = 40;
  /*Constante ' - '*/
  public static final String GUION = ' - ';
  /*Constante '\n\r'*/
  public static final String SALTO_DE_LINEA = '\n\r';
  /*Constante LOCALE ES*/
  public static final String LOCALE = 'es_ES';
  /*Constante 'Product'*/
  public static final String PRODUCT = 'Product ';
  /*Constante 'Account'*/
  public static final String ACCOUNT = 'Account ';
  /*Constante 'CASH00001'. Product external reference*/
  public static final String REFERENCE = 'CASH00001';
  /*Constante 'Low'*/
  public static final String LOW = 'Low';
  /*Constante 'Medium'*/
  public static final String MEDIUM = 'Medium';
  /*Constante 'Normal'*/
  public static final String HIGH = 'High';
  /*Constante 'High'*/
  public static final String NORMAL = 'Normal';
  /*Constante 'EXCEPTION'*/
  public static final String SER_EXCEPTION = '---- EXCEPTION ----';
  /*Constante 'solution'*/
  public static final String SOLUTION = 'solution';
  /*Constante 'new comment'*/
  public static final String NEWCOMMENT = 'new comment';
  /*Constante 'Closed'*/
  public static final String CLOSED = 'Closed';
  /*Constante 'Resolved'*/
  public static final String RESOLVED = 'Resolved';
  /*Constante 'Resolved (pending VoBO)'*/
  public static final String RESOLVED_SUBS = 'Resolved (pending VoBO)';
  /*Constante 'Working'*/
  public static final String WORKING = 'Working';
  /*Constante 'Completed'*/
  public static final String COMPLETED = 'Completed';
  /*Constante 'Case'*/
  public static final String CASECTN = 'Case';
  /*Constante 'Incident'*/
  public static final String INCIDENT = 'Incident';
  /*Constante 'Query'*/
  public static final String QUERY = 'Query';
  /*Constante 'Transferred'*/
  public static final String TRANSFERRED = 'Transferred';
  /*Constante 'Caso descartado'*/
  public static final String DESCARTADO = 'Caso descartado';
  /*Constante 'Email GNC'*/
  public static final String EMAIL_GNC = 'Email GNC';
  /*Constante 'Status "Transferred" cannot be selected'*/
  public static final String MSG_TRANFERRED = 'Status "Transferred" cannot be selected';
  /*Constante 'Reopen'*/
  public static final String REOPEN = 'Reopen';
  /*Constante 'Linked to Master Case'*/
  public static final String LINKMASTER = 'Linked to Master Case';
  /*Constante 'Mantener equipo resolutor'*/
  public static final String EQRESOLUTOR = 'Mantener equipo resolutor';
  /*Constante 'Status "Linked to Master Case" cannot be selected'*/
  public static final String MSG_LINKMASTER = 'Status "Linked to Master Case" cannot be selected';
  /*Constante 'A case that is closed must be reopened using "Close" checkbox field.'*/
  public static final String MSG_REOPEN = 'A case that is closed must be reopened using "Close" checkbox field.';
  /*Constante 'Remedy statuses are reserved for remedy processes.'*/
  public static final String MSG_REMEDY = 'Remedy statuses are reserved for remedy processes.';
  /*Constante 'Open Tasks'*/
  public static final String OPEN_TASKS = 'Open Tasks';
  /*Constante '500'*/
  public static final String CASE_500 = '500';
  /*Constante 'Task'*/
  public static final String TASK = 'Task';
  /*Constante 'Email'*/
  public static final String EMAIL = 'Email';
  /***************FIN OTROS***************/

}