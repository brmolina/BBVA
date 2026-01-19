/*------------------------------------------------------------
    Author:        Juan Carlos Terrón
    Company:       Accenture
    Description:   Email address formatting to avoid limit errors.

    History:
    <Date>          <Author>                <Description>
    30/11/2018      Juan Carlos Terrón        Initial version
--------------------------------------------------------------*/
public with sharing class SER_E2C_FormatAddressFields {
  /*@Description Longitud máxima permitida para los campos de copiado de direcciones en el caso*/
  final static Integer MAXLENGTH = 40;
  /*@Description EMailMessage pasado como parámetro para modificar sus campos.*/
  EmailMessage email;

  /*@Constructor*/
  public SER_E2C_FormatAddressFields(EmailMessage email) {
    this.email = email;
  }
  /*Método para procesar las direcciones de un email message que se pasen de un máximo establecido de caracteres. */
  public Map<String,String> processEmailAddresses() {
    String ccAddress,toAddress;
    Map<String,String> result;
    toAddress = '';
    ccAddress = '';
    for(String address : this.processTo()) {
      toAddress += address+';';
    }
    for(String address : this.processCc()) {
      ccAddress += address+';';
    }
    result = new Map<String,String>();
    result.put('TO',toAddress);
    result.put('CC',ccAddress);
    return result;
  }
  private List<String> processTo() {
    String toAddress; toAddress = '';
    Boolean full; full = false;
    List<String> result; result = new List<String>();
    final List<String> addresses = SER_EmailMessageMethods.customSplit(this.email.ToAddress, ';');
    final List<String> defined = SER_E2C_CaseRedirect.getDefinedAddresses(addresses);
    for(String address : defined) {
      if(address.length()+toAddress.length() < SER_E2C_FormatAddressFields.MAXLENGTH) {
        result.add(address);
      } else {
        full = true;
        break;
      }
    }
    if(full == false) {
      for(String address: addresses) {
        if(defined.contains(address) == false) {
          if(address.length()+toAddress.length() < SER_E2C_FormatAddressFields.MAXLENGTH) {
            result.add(address);
          } else {
            break;
          }
        }
      }
    }
    return result;
  }
  private List<String> processCc() {
    String ccAddress; ccAddress = '';
    Boolean full; full = false;
    List<String> result; result = new List<String>();
    final List<String> addresses = SER_EmailMessageMethods.customSplit(this.email.ccAddress, ';');
    final List<String> defined = SER_E2C_CaseRedirect.getDefinedAddresses(addresses);
    for(String address : defined) {
      if(address.length()+ccAddress.length() < SER_E2C_FormatAddressFields.MAXLENGTH) {
        result.add(address);
      } else {
        full  = true;
        break;
      }
    }
    if(full == false) {
      for(String address: addresses) {
        if(defined.contains(address) == false) {
          if(address.length()+ccAddress.length() < SER_E2C_FormatAddressFields.MAXLENGTH) {
            result.add(address);
          } else {
            break;
          }
        }
      }
    }
    return result;
  }
  public static Set<Id> checkAddressesLength(List<EmailMessage> emails) {
    final Set<Id> setCaseId = new Set<Id>();
    for(EmailMessage email : emails) {
      final Boolean condition = ((email.ToAddress != null && String.valueOf(email.ToAddress).length()>SER_E2C_FormatAddressFields.MAXLENGTH) || (email.CcAddress != null && String.valueOf(email.CcAddress).length()>SER_E2C_FormatAddressFields.MAXLENGTH)) && email.Incoming && email.ParentId != null && String.valueOf(email.ParentId).startswith('500');
      if(condition) {
        setCaseId.add(email.ParentId);
      }
    }
    return setCaseId;
  }
}