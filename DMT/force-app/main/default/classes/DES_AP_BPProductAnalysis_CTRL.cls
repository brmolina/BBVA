/**
  * BBVA
  * @author            Alejandro Alvarez
  * Project:           Global Desktop
  * Description:       Clase Controller DES_AP_BPProductAnalysis_CTRL for Component DES_AP_BPProductAnalysis
  *
  *            No.     Date            Author                  Description
  *            -----   ----------      --------------------    ---------------
  * @version   1.0     2021-02-26      Alejandro Alvarez       Clase Controller DES_AP_BPProductAnalysis_CTRL
  **************************************************************************************************************************************/
public with sharing class DES_AP_BPProductAnalysis_CTRL {

  /**
  * description: Private Constructor
  */
  private DES_AP_BPProductAnalysis_CTRL() {
  }

  @AuraEnabled
  public static String getGridData(String parentquery , String sectionquery, String gridGroupingField, String bpVersionId, Boolean lastValidatedV) { //NOSONAR
    String query = 'select Id,';
    query += 'bupl__solution_category_desc__c,';
    query += 'bupl__solution_category_id__c,';
    query += 'convertCurrency(bupl__expected_revenue_amount__c),';
    query += 'convertCurrency(gf_est_ginc_lcl_product_amount__c),';
    query += 'bbva_share_of_wallet_per__c,';
    query += 'gf_potencial_level_oppy_type__c,';
    query += 'other_information_desc__c,';
    query += 'gf_lcl_prdt_sustnbl_oppy_name__c,';
    query += 'bupl__gf_booking_operation_cntry_id__c ';
    query += 'from bupl__BusinessPlan_Item__c where '+ sectionquery;
      if(lastValidatedV) {
          query += ' and '+ parentquery;
          query +=' AND bupl__gf_business_plan_version_id__r.bupl__gf_bus_pl_lst_vldt_vr_ind_type__c = true ';
      } else {
          if(bpVersionId == '' || bpVersionId == null) {
            query += ' and '+ parentquery;
            query +=' AND bupl__gf_business_plan_version_id__r.bupl__gf_business_plan_act_ind_type__c =\'Yes\' ';
          } else {
            query +=' and bupl__gf_business_plan_version_id__c = \''+bpVersionId+'\'';
          }
      }
    System.debug('La query para rellenar la grid queda : '+query);
    System.debug('La parent query para rellenar la grid queda : '+parentquery);
    System.debug('La section query para rellenar la grid queda : '+sectionquery);
    List<SObject> results = Database.query(query); //NOSONAR
    final Map<String, List<bupl__BusinessPlan_Item__c>> groups = new Map<String, List<bupl__BusinessPlan_Item__c>>();
    //groups.put('Totals',new List<bupl__BusinessPlan_Item__c>());
    for(SObject result : results) {
      final bupl__BusinessPlan_Item__c bpItem = (bupl__BusinessPlan_Item__c) result;
      final String gridGroupingFieldValue = (String) bpItem.get(gridGroupingField);
      if(groups.containsKey(gridGroupingFieldValue)) {
        groups.get(gridGroupingFieldValue).add(bpItem);
      } else {
        groups.put((String) bpItem.get(gridGroupingField), new List<bupl__BusinessPlan_Item__c>{bpItem});
      }
      //groups.get('Totals').add(bpItem);
    }
    Integer gridGroupId;
    gridGroupId = 0;
    final List<GridRowGroup> gridrowgroups = new List<GridRowGroup>();
    for(String gridGroupingFieldValue : groups.keyset()) {
      gridrowgroups.add(new GridRowGroup(String.valueof(gridGroupId),gridGroupingField,gridGroupingFieldValue, groups.get(gridGroupingFieldValue)));
      gridGroupId++;
    }
    return buildDataJSON(gridrowgroups);
  }
  private static String buildDataJSON(List<GridRowGroup> rowgroups) {
    String result;
    result = '[';
    Integer counter;
    counter = 0;
    System.debug('Número de grupos : '+rowgroups.size());
    for(GridRowGroup gridgroup : rowgroups) {
      result += JSON.serializepretty(gridgroup).replaceAll('children','_children');
      if(counter == 0 && rowgroups.size()==1) {
        //DONOTHING
      }else if(counter<rowgroups.size()-1){
        result += ',';
        counter++;
      }
    }
    result += ']';
    return result;
  }
  public class GridRowGroup { //NOSONAR
    List<GridRow> children;
    String id;
    String productName;
    String productFamily;
    String country;
    Decimal percentCount;
    Decimal percentCountSum;
    Decimal expectedrevenueamount;
    Decimal gfestginclclproductamount;
    Decimal bbvashareofwalletper;
    String gfpotencialleveloppytype;
    String gflclprdtsustnbloppyname;
    String otherinformationdesc;
    public GridRowGroup(String id,String gridGroupingField,String gridGroupingFieldValue,List<bupl__BusinessPlan_Item__c> bpItems) {
      //this.Id = gridGroupingFieldValue;
      this.id =  id;
      this.fillGroupingFieldValue(gridGroupingField,gridGroupingFieldValue); //NOSONAR
      //this.gridGroupingField = gridGroupingField;
      this.children = new List<GridRow>();
      this.initializeCurrencies(); //NOSONAR
      for(bupl__BusinessPlan_Item__c bpItem : bpItems) {
        this.children.add(new GridRow(bpItem));
        this.addChildrenValues(bpItem);
      }
    }
    private void fillGroupingFieldValue(String gridGroupingField,String gridGroupingFieldValue) {
      if(gridGroupingField.contains('gf_booking_operation_cntry_id__c')) {
        this.country = gridGroupingFieldValue;
      } else if(gridGroupingField.contains('solution_category_id__c')) {
        this.productFamily = gridGroupingFieldValue;
      } else if(gridGroupingField.contains('solution_category_desc__c')) {
        this.productName = gridGroupingFieldValue;
      }
    }
    private void initializeCurrencies() {
      this.expectedrevenueamount = 0;
      this.gfestginclclproductamount = 0;
      this.bbvashareofwalletper = 0;
      this.percentCount = 0;
      this.percentCountSum = 0;
    }
    private void addChildrenValues(bupl__BusinessPlan_Item__c bpItem) {
      if(bpItem.bupl__expected_revenue_amount__c != null) {
        this.expectedrevenueamount += bpItem.bupl__expected_revenue_amount__c;
      }
      if(bpItem.gf_est_ginc_lcl_product_amount__c != null) {
        this.gfestginclclproductamount += bpItem.gf_est_ginc_lcl_product_amount__c;
      }
      if(bpItem.bbva_share_of_wallet_per__c != null && bpItem.bbva_share_of_wallet_per__c !=0) {
        this.percentCountSum += bpItem.bbva_share_of_wallet_per__c;
        this.percentCount = this.percentCount +1;
        this.bbvashareofwalletper = this.percentCountSum / this.percentCount ;
      }
    }
  }
  public class GridRow { //NOSONAR
    String id;
    String productName;
    String productFamily;
    String country;
    Boolean ready;
    Decimal expectedrevenueamount;
    Decimal gfestginclclproductamount;
    Decimal bbvashareofwalletper;
    String gfpotencialleveloppytype;
    String gflclprdtsustnbloppyname;
    String otherinformationdesc;
    public GridRow(bupl__BusinessPlan_Item__c bpitem) {
      this.id = bpItem.Id;
      this.productName = bpItem.bupl__solution_category_desc__c;
      this.productFamily = bpItem.bupl__solution_category_desc__c;
      this.country = bpItem.bupl__gf_booking_operation_cntry_id__c;
      this.expectedrevenueamount = bpItem.bupl__expected_revenue_amount__c;
      this.gfestginclclproductamount = bpItem.gf_est_ginc_lcl_product_amount__c;
      if(bpItem.bbva_share_of_wallet_per__c != null ){

              this.bbvashareofwalletper = bpItem.bbva_share_of_wallet_per__c ;
          
      }
      this.gfpotencialleveloppytype = bpItem.gf_potencial_level_oppy_type__c;
      this.gflclprdtsustnbloppyname = bpItem.gf_lcl_prdt_sustnbl_oppy_name__c;
      this.otherinformationdesc = bpItem.other_information_desc__c;
    }
  }
  /* TABLE */
  @AuraEnabled
  public static String getTableData(String parentquery, String sectionquery, String gridGroupingField, String bpVersionId, Boolean lastValidatedV) {
    final String query = getDataQuery(parentquery, sectionquery, gridGroupingField, bpVersionId, lastValidatedV);
    final List<bupl__BusinessPlan_Item__c> bpItems = (List<bupl__BusinessPlan_Item__c>) Database.query(query); //NOSONAR
    final List<TableRow> tablerows = new List<TableRow>();
    for(bupl__BusinessPlan_Item__c bpItem : bpItems) {
      tablerows.add(new TableRow(bpItem));
    }
    return JSON.serialize(tablerows);
  }
  @AuraEnabled
  public static String saveData(String tablerows) {
    final string STRSUCCESS = 'SUCCESS';
    final string STRERROR = 'ERROR';
    final string strmsj;
    System.debug('TROWS APEX: '+tablerows);
    //final List<TableRow> parsedtablerows = (List<TableRow>) JSON.deserialize(tablerows, List<DES_AP_BPProductAnalysis_CTRL.TableRow.class>);
    final List<bupl__BusinessPlan_Item__c> bpItems = new List<bupl__BusinessPlan_Item__c>();
    for(Object row : (List<Object>) JSON.deserializeUntyped(tablerows)) {
      final bupl__BusinessPlan_Item__c bpitem = ((TableRow) JSON.deserialize(JSON.serialize(row), DES_AP_BPProductAnalysis_CTRL.TableRow.class)).getItem();
      bpItems.add(bpitem);
    }
    try {
      update bpItems;
      strmsj = STRSUCCESS;
    } catch (Exception error) {
      System.debug('Error: '+error.getMessage()+'\n');
      strmsj = STRERROR;
    }
    return strmsj;
  }

  public class TableRow {
    String id;
    String country;
    String productName;
    String productFamily;
    Decimal expectedrevenueamount;
    Decimal gfestginclclproductamount;
    Decimal bbvashareofwalletper;
    String gfpotencialleveloppytype;
    String gflclprdtsustnbloppyname;
    String otherinformationdesc;
    public TableRow(bupl__BusinessPlan_Item__c bpItem) {
      this.Id = bpItem.Id;
      this.country = bpItem.bupl__gf_booking_operation_cntry_id__c;
      this.productName = bpItem.bupl__solution_category_desc__c;
      this.productFamily = bpItem.bupl__solution_category_id__c;
      this.expectedrevenueamount = bpItem.bupl__expected_revenue_amount__c;
      this.gfestginclclproductamount = bpItem.gf_est_ginc_lcl_product_amount__c;
      if(bpItem.bbva_share_of_wallet_per__c != null ){
          this.bbvashareofwalletper = bpItem.bbva_share_of_wallet_per__c * 100;
      }
      this.gfpotencialleveloppytype = bpItem.gf_potencial_level_oppy_type__c;
      this.gflclprdtsustnbloppyname = bpItem.gf_lcl_prdt_sustnbl_oppy_name__c;
      this.otherinformationdesc = bpItem.other_information_desc__c;
    }
    public bupl__BusinessPlan_Item__c getItem(){
      final bupl__BusinessPlan_Item__c bpItem = new bupl__BusinessPlan_Item__c();
      bpItem.Id = this.Id;
      this.copyField(bpItem);
      this.copyCurrency(bpItem);
      return bpItem;
    }
    private void copyCurrency(bupl__BusinessPlan_Item__c bpItem) {
      decimal currRate = getRate();
      if(this.expectedrevenueamount != null) {
        bpItem.bupl__expected_revenue_amount__c = this.expectedrevenueamount / currRate;
      }
      if(this.gfestginclclproductamount != null) {
        bpItem.gf_est_ginc_lcl_product_amount__c = this.gfestginclclproductamount / currRate;
      }
      if(this.bbvashareofwalletper != null) {
        Decimal percent = this.bbvashareofwalletper / 100;
		  if(percent > 1){
              bpItem.bbva_share_of_wallet_per__c = 1;
          }else{
              bpItem.bbva_share_of_wallet_per__c = percent;
          }
      }
    }

    private decimal getRate() {
      String userCurrency = UserInfo.getDefaultCurrency();
      return [SELECT Id, ConversionRate FROM CurrencyType WHERE IsoCode = :userCurrency].ConversionRate;
    }

    private void copyField(bupl__BusinessPlan_Item__c bpItem) {
      if(this.country != null) {
        bpItem.bupl__gf_booking_operation_cntry_id__c = this.country;
      }
      if(this.productName != null) {
        bpItem.bupl__solution_category_desc__c = this.productName;
      }
      if(this.productFamily != null) {
        bpItem.bupl__solution_category_id__c = this.productFamily;
      }
      if(this.gfpotencialleveloppytype != null) {
        bpItem.gf_potencial_level_oppy_type__c = this.gfpotencialleveloppytype;
      }
      if(this.gflclprdtsustnbloppyname != null) {
        bpItem.gf_lcl_prdt_sustnbl_oppy_name__c = this.gflclprdtsustnbloppyname;
      }
      if(this.otherinformationdesc != null) {
        bpItem.other_information_desc__c = this.otherinformationdesc;
      }
    }
  }
  /* COMMON */
  public static String getDataQuery(String parentquery, String sectionquery, String gridGroupingField, String bpVersionId, Boolean lastValidatedV) {
    String query = 'select Id,';
    query += 'bupl__solution_category_desc__c,';
    query += 'bupl__solution_category_id__c,';
    query += 'bupl__gf_booking_operation_cntry_id__c,';
    query += 'convertCurrency(bupl__expected_revenue_amount__c),';
    query += 'convertCurrency(gf_est_ginc_lcl_product_amount__c),';
    query += 'bbva_share_of_wallet_per__c,';
    query += 'gf_potencial_level_oppy_type__c,';
    query += 'other_information_desc__c,';
    query += 'gf_lcl_prdt_sustnbl_oppy_name__c ';
    query += 'from bupl__BusinessPlan_Item__c where '+sectionquery;
      if(lastValidatedV) {
        query +=+' and '+ parentquery;
        query +=' AND bupl__gf_business_plan_version_id__r.bupl__gf_bus_pl_lst_vldt_vr_ind_type__c = true ';
      } else {
        if(bpVersionId == '' || bpVersionId == null) {
          query +=+' and '+ parentquery;
          query +=' AND bupl__gf_business_plan_version_id__r.bupl__gf_business_plan_act_ind_type__c =\'Yes\' ';
        } else {
          query +=' and bupl__gf_business_plan_version_id__c = \''+bpVersionId+'\'';
        }
      }
    return query;
  }
  

}