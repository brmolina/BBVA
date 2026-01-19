public without sharing class DES_Ip_UpdateCountry {
  public class IpCountry {
    /**
     * Email
     */
     @InvocableVariable(label='AA_Compliance_to_email__c' required=false)
    public string email; //NOSONAR
    /**
     * Lista de a visita IP a actualizar
     */
     @InvocableVariable(label='visits' required=false)
    public List<dwp_kitv__Visit__c> visits; //NOSONAR
     /**
     * Lista del formulario IP a actualizar
     */
     @InvocableVariable(label='forms' required=false)
    public List<Inside_information_form__c> forms; //NOSONAR
    /**
     * Lista de la Oportunidad IP a actualizar
     */
     @InvocableVariable(label='oppo' required=false)
    public List<Opportunity> oppo; //NOSONAR
    /**
     * Operacion que contendra a un string de diferentes operaciones a realizar
     */
     @InvocableVariable(label='operation' required=false)
    public String operation; //NOSONAR
  }
  @InvocableMethod(label='Update IP Country' description='Updated the country from opportunity, visit or form')
  public static List<ID> DES_Ip_UpdateCountry(List<IpCountry> country) {
    IpCountry IpCountrys = country[0];
    List<ID> Ids= new List<ID>();
    switch on IpCountrys.operation {
        //Operación que actualiza la opportunidad
      when 'oppo' {
          update(IpCountrys.oppo);
        Database.SaveResult[] results = Database.update(IpCountrys.oppo);
        List<ID> opportunityIds = new List<ID>();
        for (Database.SaveResult result : results) {
          if (result.isSuccess()) {
            opportunityIds.add(result.getId());
          }
        }
        Ids= opportunityIds;
      }
        //Operación que actualiza la visita
      when 'visit' {
          update(IpCountrys.visits);
        Database.SaveResult[] results = Database.update(IpCountrys.visits);
        List<ID> visitIds = new List<ID>();
        for (Database.SaveResult result : results) {
          if (result.isSuccess()) {
            visitIds.add(result.getId());
          }
        }
        Ids= visitIds;
      }
        //Operación que actualiza el formulario
      when 'form' {
        IpCountrys.forms[0].AA_Compliance_to_email__c=IpCountrys.email;
          update(IpCountrys.forms);
        Database.SaveResult[] results = Database.update(IpCountrys.forms);
        List<ID> formIds = new List<ID>();
        for (Database.SaveResult result : results) {
          if (result.isSuccess()) {
            formIds.add(result.getId());
          }
        }
        Ids= formIds;
      }
    }
    return Ids;
  }
}