/**
* ────────────────────────────────────────────────────────────────────────────────────
* Test class for HPG_ContractGuarantees apex class
* ────────────────────────────────────────────────────────────────────────────────────
* @author      Cosme Alcázar <cosme.alcazar.tech@bbva.com>
* @modifiedBy
* @version     1.0
* @created     2024-08-02
* @modified
* @systemLayer Test
* ────────────────────────────────────────────────────────────────────────────────────
* @changes
*
* ────────────────────────────────────────────────────────────────────────────────────
*/
@isTest
public with sharing  class HPG_ContractGuarantees_Test {
    @isTest
    static void wrapperTest() {
        Test.startTest();
            HPG_ContractGuarantees.Wrapper contractGuarantees = new HPG_ContractGuarantees.Wrapper();
            contractGuarantees.data = new List<HPG_ContractGuarantees.Data>();
            contractGuarantees.pagination = new HPG_ContractGuarantees.Pagination();
            contractGuarantees.success = true;
            contractGuarantees.errorMessage = 'Error Message';
            HPG_ContractGuarantees.Data data = new HPG_ContractGuarantees.Data();
            data.guaranteeId = '';
            data.contractId = '';
            data.localContractNumberId = '';
            data.internalContractCodeDesc = '';
            data.cutoffDate = Date.today();
            data.beginningGuaranteeDate = Date.today();
            data.endGuaranteeDate = Date.today();
            data.guaranteeType = '';
            data.guaranteeTypeDesc = '';
            data.tradeCollateralType = '';
            data.tradeGuarranteeCollateralTypeDesc = '';
            data.guarantorCustomerId = '';
            data.guarantorCustomerNameDesc = '';
            data.guarantorAmount = 0;
            data.currentGuaranteedAmount = 0;
            data.guaranteeCurrencyId = '';
            data.guarantorCurrencyId = '';
            data.guarantorMitigationPer = 0;
            data.lastAppraisalDate = Date.today();
            data.assetId = '';
            data.expirationSecuritiesDate = Date.today();
            data.insuranceCoverPer = 0;
            data.guaranteeCurrentYearId = '';
            data.recordTypeName = '';
            contractGuarantees.data.add(data);
            HPG_ContractGuarantees.Pagination pagination = new HPG_ContractGuarantees.Pagination();
            pagination.links = new HPG_ContractGuarantees.Links();
            pagination.links.first = '';
            pagination.links.last = '';
            pagination.links.next = '';
            pagination.links.previous = '';
            pagination.page = 1;
            pagination.pageSize = 300;
            pagination.totalElements = 1;
            pagination.totalPages = 1;
            System.assertEquals(true, contractGuarantees.success, 'wrapperTest - Not passed - success');
        Test.stopTest();
    }
}