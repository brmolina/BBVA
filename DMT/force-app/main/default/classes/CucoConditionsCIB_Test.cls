/**
* ────────────────────────────────────────────────────────────────────────────────────
* CucoConditionsCIB_Test
* Test class for CucoConditionsCIB apex class
* ────────────────────────────────────────────────────────────────────────────────────
* @author      Torcuato Tejada <torcuato.tejada.contractor@bbva.com>
* @modifiedBy
* @version     1.0
* @created     2021-08-21
* @modified
* @systemLayer Test
* ────────────────────────────────────────────────────────────────────────────────────
* @changes
*
* ────────────────────────────────────────────────────────────────────────────────────
*/
@SuppressWarnings('PMD.TooManyFields, sf:TooManyMethods')
@IsTest
public class CucoConditionsCIB_Test {

    /*
    * test validation string inputBoolean
    */
    static String inputBoolean= '{"conditions":[{"id":"#CONDITION_ID#","attributes":[{"id":"debit.sepa.postal.ind","proposed":"#VALUE_ID#"}]}]}';

    /*
    * test validation string mandatoryPCFixedKOInput
    */
    static String mandatoryPCFixedKOInput = '{"conditions":[{"id":"#CONDITION_ID#","attributes":[{"id":"np.nat.transfer.EEE.ob.branch.type"},{"id":"np.nat.transfer.EEE.ob.branch.min"},{"id":"np.nat.transfer.EEE.ob.branch.max","proposed":"15"},{"id":"np.nat.transfer.EEE.ob.branch.amount","proposed":"10"}]}]}';

    /*
    * test validation string mandatoryPCFixedOKInput
    */
    static String mandatoryPCFixedOKInput = '{"conditions":[{"id":"#CONDITION_ID#","attributes":[{"id":"np.nat.transfer.EEE.ob.branch.type"},{"id":"np.nat.transfer.EEE.ob.branch.min"},{"id":"np.nat.transfer.EEE.ob.branch.max"},{"id":"np.nat.transfer.EEE.ob.branch.amount","proposed":"12"}]}]}';

    /*
    * test validation string mandatoryPCVariableKOInput
    */
    static String mandatoryPCVariableKOInput = '{"conditions":[{"id":"#CONDITION_ID#","attributes":[{"id":"np.nat.transfer.EEE.ob.branch.type","proposed":"1"},{"id":"np.nat.transfer.EEE.ob.branch.min","proposed":"5"},{"id":"np.nat.transfer.EEE.ob.branch.max"},{"id":"np.nat.transfer.EEE.ob.branch.amount"}]}]}';

    /*
    * test validation string mandatoryPCVariableOKInput
    */
    static String mandatoryPCVariableOKInput = '{"conditions":[{"id":"#CONDITION_ID#","attributes":[{"id":"np.nat.transfer.EEE.ob.branch.type","proposed":"1"},{"id":"np.nat.transfer.EEE.ob.branch.min","proposed":"5"},{"id":"np.nat.transfer.EEE.ob.branch.max","proposed":"10"},{"id":"np.nat.transfer.EEE.ob.branch.amount"}]}]}';

    /*
    * test validation string mandatoryOtherKOInput
    */
    static String mandatoryOtherKOInput = '{"conditions":[{"id":"#CONDITION_ID#","attributes":[{"id":"card.bbva.others.gift.fee"}]}]}';

    /*
    * test validation string mandatoryOtherOKInput
    */
    static String mandatoryOtherOKInput = '{"conditions":[{"id":"#CONDITION_ID#","attributes":[{"id":"card.bbva.others.gift.fee","proposed":"45.7"}]}]}';

    /*
    * test validation string maxBiggerMinKOInput
    */
    static String maxBiggerMinKOInput = '{"conditions":[{"id":"#CONDITION_ID#","attributes":[{"id":"np.nat.transfer.EEE.ob.branch.type","proposed":"1"},{"id":"np.nat.transfer.EEE.ob.branch.min","proposed":"5.68"},{"id":"np.nat.transfer.EEE.ob.branch.max","proposed":"5.67"},{"id":"np.nat.transfer.EEE.ob.branch.amount"}]}]}';

    /*
    * test validation string maxBiggerMinOKInput
    */
    static String maxBiggerMinOKInput = '{"conditions":[{"id":"#CONDITION_ID#","attributes":[{"id":"np.nat.transfer.EEE.ob.branch.type","proposed":"1"},{"id":"np.nat.transfer.EEE.ob.branch.min","proposed":"5.67"},{"id":"np.nat.transfer.EEE.ob.branch.max","proposed":"5.68"},{"id":"np.nat.transfer.EEE.ob.branch.amount"}]}]}';

    /*
    * test validation string withExpZeroTypeKOInput
    */
    static String withExpZeroTypeKOInput = '{"conditions":[{"id":"#CONDITION_ID_1#","attributes":[{"id":"np.transfer.mail.expenses.amount","proposed":"1"}]},{"id":"#CONDITION_ID_2#","attributes":[{"id":"np.nat.transfer.EEE.ob.branch.type","proposed":"0"},{"id":"np.nat.transfer.EEE.ob.branch.min","proposed":"4.34"},{"id":"np.nat.transfer.EEE.ob.branch.max","proposed":"4.35"},{"id":"np.nat.transfer.EEE.ob.branch.amount"}]}]}';

    /*
    * test validation string withExpZeroTypeOKInput
    */
    static String withExpZeroTypeOKInput = '{"conditions":[{"id":"#CONDITION_ID_1#","attributes":[{"id":"np.transfer.mail.expenses.amount","proposed":"1"}]},{"id":"#CONDITION_ID_2#","attributes":[{"id":"np.nat.transfer.EEE.ob.branch.type","proposed":"0"},{"id":"np.nat.transfer.EEE.ob.branch.min","proposed":"4.35"},{"id":"np.nat.transfer.EEE.ob.branch.max","proposed":"4.35"},{"id":"np.nat.transfer.EEE.ob.branch.amount"}]}]}';

    /*
    * test validation string withExpNonZeroTypeKOInput
    */
    static String withExpNonZeroTypeKOInput = '{"conditions":[{"id":"#CONDITION_ID_1#","attributes":[{"id":"np.transfer.mail.expenses.amount","proposed":"1"}]},{"id":"#CONDITION_ID_2#","attributes":[{"id":"np.nat.transfer.EEE.ob.branch.type","proposed":"2"},{"id":"np.nat.transfer.EEE.ob.branch.min","proposed":"4.35"},{"id":"np.nat.transfer.EEE.ob.branch.max","proposed":"4.35"},{"id":"np.nat.transfer.EEE.ob.branch.amount"}]}]}';

    /*
    * test validation string withExpNonZeroTypeOKInput
    */
    static String withExpNonZeroTypeOKInput = '{"conditions":[{"id":"#CONDITION_ID_1#","attributes":[{"id":"np.transfer.mail.expenses.amount","proposed":"1"}]},{"id":"#CONDITION_ID_2#","attributes":[{"id":"np.nat.transfer.EEE.ob.branch.type","proposed":"2"},{"id":"np.nat.transfer.EEE.ob.branch.min","proposed":"4.33"},{"id":"np.nat.transfer.EEE.ob.branch.max","proposed":"4.35"},{"id":"np.nat.transfer.EEE.ob.branch.amount"}]}]}';

    /*
    * test validation string withoutExpInput
    */
    static String withoutExpInput = '{"conditions":[{"id":"#CONDITION_ID#","attributes":[{"id":"np.nat.transfer.EEE.ob.branch.type","proposed":"1"},{"id":"np.nat.transfer.EEE.ob.branch.min","proposed":"5"},{"id":"np.nat.transfer.EEE.ob.branch.max","proposed":"5"},{"id":"np.nat.transfer.EEE.ob.branch.amount"}]}]}';

    /*
    * test validation string checkZeroTypeKOInput
    */
    static String checkZeroTypeKOInput = '{"conditions":[{"id":"#CONDITION_ID#","attributes":[{"id":"np.t.check.letter.type","proposed":"0"},{"id":"np.t.check.letter.min","proposed":"1"},{"id":"np.t.check.letter.max","proposed":"2"},{"id":"np.t.check.letter.amount"}]}]}';

    /*
    * test validation string checkZeroTypeOKInput
    */
    static String checkZeroTypeOKInput = '{"conditions":[{"id":"#CONDITION_ID#","attributes":[{"id":"np.t.check.letter.type","proposed":"0"},{"id":"np.t.check.letter.min","proposed":"1"},{"id":"np.t.check.letter.max","proposed":"1"},{"id":"np.t.check.letter.amount"}]}]}';

    /*
    * test validation string checkNonZeroTypeKOInput
    */
    static String checkNonZeroTypeKOInput = '{"conditions":[{"id":"#CONDITION_ID#","attributes":[{"id":"np.t.check.letter.type","proposed":"1"},{"id":"np.t.check.letter.min","proposed":"1"},{"id":"np.t.check.letter.max","proposed":"1"},{"id":"np.t.check.letter.amount"}]}]}';

    /*
    * test validation string checkNonZeroTypeOKInput
    */
    static String checkNonZeroTypeOKInput = '{"conditions":[{"id":"#CONDITION_ID#","attributes":[{"id":"np.t.check.letter.type","proposed":"1"},{"id":"np.t.check.letter.min","proposed":"1"},{"id":"np.t.check.letter.max","proposed":"2"},{"id":"np.t.check.letter.amount"}]}]}';

    /*
    * test validation string cardBusinessInput
    */
    static String cardBusinessInput = '{"conditions":[{"id":"#CONDITION_ID#","attributes":[{"id":"card.bbva.business.fee","proposed":"#VALUE_ID#"}]}]}';

    /*
    * test validation string cardCorpInput
    */
    static String cardCorpInput = '{"conditions":[{"id":"#CONDITION_ID#","attributes":[{"id":"card.bbva.corporate.fee","proposed":"#VALUE_ID#"}]}]}';

    /*
    * test validation string cardExpInput
    */
    static String cardExpInput = '{"conditions":[{"id":"#CONDITION_ID#","attributes":[{"id":"card.bbva.others.express.fee","proposed":"#VALUE_ID#"}]}]}';

    /*
    * test validation string cardGiftInput
    */
    static String cardGiftInput = '{"conditions":[{"id":"#CONDITION_ID#","attributes":[{"id":"card.bbva.others.gift.fee","proposed":"#VALUE_ID#"}]}]}';


    @TestSetup
    static void setupTestData() {

        final List<cuco__ps_catalog_attribute__c> psCatAtt =  cuco.Test_Utils.createPSCatalogAttributes(7);
        psCatAtt[0].Name = 'Exento';
        psCatAtt[0].cuco__gf_attribute_value_type_name__c = 'Checkbox';
        psCatAtt[0].cuco__gf_psc_attribute_id__c = 'exen.ind';

        psCatAtt[1].Name = 'Max';
        psCatAtt[1].cuco__gf_attribute_value_type_name__c = 'Currency';
        psCatAtt[1].cuco__gf_psc_attribute_id__c = 'max';

        psCatAtt[2].Name = 'Min';
        psCatAtt[2].cuco__gf_attribute_value_type_name__c = 'Currency';
        psCatAtt[2].cuco__gf_psc_attribute_id__c = 'min';

        psCatAtt[3].Name = 'Fijo';
        psCatAtt[3].cuco__gf_attribute_value_type_name__c = 'Currency';
        psCatAtt[3].cuco__gf_psc_attribute_id__c = 'amount';

        psCatAtt[4].Name = '‰';
        psCatAtt[4].cuco__gf_attribute_value_type_name__c = 'Permillage';
        psCatAtt[4].cuco__gf_psc_attribute_id__c = 'type';

        psCatAtt[5].Name = 'Cuota';
        psCatAtt[5].cuco__gf_attribute_value_type_name__c = 'Currency';
        psCatAtt[5].cuco__gf_psc_attribute_id__c = 'fee';

        psCatAtt[6].Name = 'Gastos de Correo';
        psCatAtt[6].cuco__gf_attribute_value_type_name__c = 'Currency';
        psCatAtt[6].cuco__gf_psc_attribute_id__c = 'mail.amount';
        insert psCatAtt;

        // Create catalog families
        final List<cuco__ps_catalog_family__c> psCatFam = createTestFamilies();
        insert psCatFam;

        // Create conditions
        final List<cuco__ps_catalog_condition__c> catCond = createCatConditions(psCatFam);
        insert catCond;

        // Create cond attributes
        final List<cuco__ps_catalog_condition_attribute__c> catCondAt = createCatCondAt(catCond, psCatAtt);
        insert catCondAt;

        //Create standard values
        final List<cuco__ps_catalog_condition_standard__c> catStandVal = cuco.Test_Utils.createPSCatalogConditonsStandard(4);

        catStandVal[0].cuco__gf_psc_condition_attribute_id__c = catCondAt[8].Id;
        catStandVal[0].cuco__gf_cond_atrb_max_val_name__c = '10';
        catStandVal[0].cuco__gf_cond_atrb_min_val_name__c = '0';

        catStandVal[1].cuco__gf_psc_condition_attribute_id__c = catCondAt[9].Id;
        catStandVal[1].cuco__gf_cond_atrb_max_val_name__c = '10';
        catStandVal[1].cuco__gf_cond_atrb_min_val_name__c = null;

        catStandVal[2].cuco__gf_psc_condition_attribute_id__c = catCondAt[10].Id;
        catStandVal[2].cuco__gf_cond_atrb_max_val_name__c =  null;
        catStandVal[2].cuco__gf_cond_atrb_min_val_name__c = '1';

        catStandVal[3].cuco__gf_psc_condition_attribute_id__c = catCondAt[11].Id;
        catStandVal[3].cuco__gf_cond_atrb_max_val_name__c =  null;
        catStandVal[3].cuco__gf_cond_atrb_min_val_name__c = null;

        insert catStandVal;
    }

    private static List<cuco__ps_catalog_family__c> createTestFamilies() {
        // Create catalog families
        final List<cuco__ps_catalog_family__c> psCatFam = cuco.Test_Utils.createPSCatalogFamilies(6);
        psCatFam[0].cuco__gf_psc_family_id__c = 'np.nat.transfer';
        psCatFam[1].cuco__gf_psc_family_id__c = 'debit.sepa';
        psCatFam[2].cuco__gf_psc_family_id__c = 'stock.domestic';
        psCatFam[3].cuco__gf_psc_family_id__c = 'card.bbva.business';
        psCatFam[4].cuco__gf_psc_family_id__c = 'card.bbva.others';
        psCatFam[5].cuco__gf_psc_family_id__c = 'np.check';
        return psCatFam;
    }

    // Create Catalog Conditions
    private static List<cuco__ps_catalog_condition__c> createCatConditions(List<cuco__ps_catalog_family__c> psCatFam) {

        final List<cuco__ps_catalog_condition__c> catCond = new List<cuco__ps_catalog_condition__c>();

        final List<cuco__ps_catalog_condition__c> catCondNP = cuco.Test_Utils.createPSCatalogConditons(1, psCatFam[0]);
        catCondNP[0].cuco__gf_psc_condition_id__c = 'np.nat.transfer.EEE.ob.branch';
        catCondNP[0].cuco__gf_psc_cond_prc_class_ind_type__c = true;
        catCond.add(catCondNP[0]);

        final List<cuco__ps_catalog_condition__c> catCondSEPA = cuco.Test_Utils.createPSCatalogConditons(1, psCatFam[1]);
        catCondSEPA[0].cuco__gf_psc_condition_id__c = 'debit.sepa.postal';
        catCond.add(catCondSEPA[0]);

        final List<cuco__ps_catalog_condition__c> catCondStock = cuco.Test_Utils.createPSCatalogConditons(1, psCatFam[2]);
        catCondStock[0].cuco__gf_psc_condition_id__c = 'stock.domestic.equity.sharesale';
        catCondStock[0].cuco__gf_psc_cond_prc_class_ind_type__c = true;
        catCond.add(catCondStock[0]);

        final List<cuco__ps_catalog_condition__c> catCondBusinessCards = cuco.Test_Utils.createPSCatalogConditons(2, psCatFam[3]);
        catCondBusinessCards[0].cuco__gf_psc_condition_id__c = 'card.bbva.business';
        catCond.add(catCondBusinessCards[0]);
        catCondBusinessCards[1].cuco__gf_psc_condition_id__c = 'card.bbva.corporate';
        catCond.add(catCondBusinessCards[1]);

        final List<cuco__ps_catalog_condition__c> catCondOtherCards = cuco.Test_Utils.createPSCatalogConditons(2, psCatFam[4]);
        catCondOtherCards[0].cuco__gf_psc_condition_id__c = 'card.bbva.others.express';
        catCond.add(catCondOtherCards[0]);
        catCondOtherCards[1].cuco__gf_psc_condition_id__c = 'card.bbva.others.gift';
        catCond.add(catCondOtherCards[1]);

        final List<cuco__ps_catalog_condition__c> catCondMailNP = cuco.Test_Utils.createPSCatalogConditons(1, psCatFam[0]);
        catCondMailNP[0].cuco__gf_psc_condition_id__c = 'np.transfer.mail.expenses';
        catCond.add(catCondMailNP[0]);

        final List<cuco__ps_catalog_condition__c> catCondCheck = cuco.Test_Utils.createPSCatalogConditons(1, psCatFam[5]);
        catCondCheck[0].cuco__gf_psc_condition_id__c = 'np.t.check.letter';
        catCondCheck[0].cuco__gf_psc_cond_prc_class_ind_type__c = true;
        catCond.add(catCondCheck[0]);

        return catCond;
    }

    // Create Catalog Condition Attributes
    private static List<cuco__ps_catalog_condition_attribute__c> createCatCondAt(List<cuco__ps_catalog_condition__c> catCond, List<cuco__ps_catalog_attribute__c> psCatAtt) {

        // Create catalog attributes
        final List<cuco__ps_catalog_attribute__c> psCatAttBoolean = new List<cuco__ps_catalog_attribute__c>();
        final List<cuco__ps_catalog_attribute__c> psCatAttPriceClass = new List<cuco__ps_catalog_attribute__c>();
        final List<cuco__ps_catalog_attribute__c> psCatAttCards = new List<cuco__ps_catalog_attribute__c>();
        final List<cuco__ps_catalog_attribute__c> psCatAttMailAmount = new List<cuco__ps_catalog_attribute__c>();

        psCatAttBoolean.add(psCatAtt[0]);
        psCatAttPriceClass.add(psCatAtt[1]);
        psCatAttPriceClass.add(psCatAtt[2]);
        psCatAttPriceClass.add(psCatAtt[3]);
        psCatAttPriceClass.add(psCatAtt[4]);
        psCatAttCards.add(psCatAtt[5]);
        psCatAttMailAmount.add(psCatAtt[6]);

        // create cat conditions
        final List<cuco__ps_catalog_condition_attribute__c> catCondAt = new List<cuco__ps_catalog_condition_attribute__c>();

        final List<cuco__ps_catalog_condition_attribute__c> catCondAttSEPA = cuco.Test_Utils.createPSCatalogConditonAttributes(1, catCond[1], psCatAttBoolean);
        catCondAttSEPA[0].cuco__gf_psc_condition_attribute_id__c = 'debit.sepa.postal.ind';
        catCondAt.add(catCondAttSEPA[0]);

        final List<cuco__ps_catalog_condition_attribute__c> catCondAttNP = getCatCondAttNP(catCond[0], psCatAttPriceClass);
        catCondAt.addAll(catCondAttNP);

        // create cat conditions
        final List<cuco__ps_catalog_condition_attribute__c> catCondAttStock = getCatCondAttStock(catCond[2], psCatAttPriceClass);
        catCondAt.add(catCondAttStock[1]);
        catCondAt.add(catCondAttStock[2]);
        catCondAt.add(catCondAttStock[3]);

        final List<cuco__ps_catalog_condition_attribute__c> catCondAttCardBus = cuco.Test_Utils.createPSCatalogConditonAttributes(1, catCond[3], psCatAttCards);
        catCondAttCardBus[0].cuco__gf_psc_condition_attribute_id__c = 'card.bbva.business.fee';
        catCondAt.add(catCondAttCardBus[0]);

        final List<cuco__ps_catalog_condition_attribute__c> catCondAttCardCor = cuco.Test_Utils.createPSCatalogConditonAttributes(1, catCond[4], psCatAttCards);
        catCondAttCardCor[0].cuco__gf_psc_condition_attribute_id__c = 'card.bbva.corporate.fee';
        catCondAt.add(catCondAttCardCor[0]);

        final List<cuco__ps_catalog_condition_attribute__c> catCondAttCardExp = cuco.Test_Utils.createPSCatalogConditonAttributes(1, catCond[5], psCatAttCards);
        catCondAttCardExp[0].cuco__gf_psc_condition_attribute_id__c = 'card.bbva.others.express.fee';
        catCondAt.add(catCondAttCardExp[0]);

        final List<cuco__ps_catalog_condition_attribute__c> catCondAttCardGift = cuco.Test_Utils.createPSCatalogConditonAttributes(1, catCond[6], psCatAttCards);
        catCondAttCardGift[0].cuco__gf_psc_condition_attribute_id__c = 'card.bbva.others.gift.fee';
        catCondAt.add(catCondAttCardGift[0]);

        final List<cuco__ps_catalog_condition_attribute__c> catCondAttMailNP = cuco.Test_Utils.createPSCatalogConditonAttributes(1, catCond[7], psCatAttMailAmount);
        catCondAttMailNP[0].cuco__gf_psc_condition_attribute_id__c = 'np.transfer.mail.expenses.amount';
        catCondAt.add(catCondAttMailNP[0]);

        final List<cuco__ps_catalog_condition_attribute__c> catCondAttCheck = getCatCondAttCheck(catCond[8], psCatAttPriceClass);
        catCondAt.addAll(catCondAttCheck);
        return catCondAt;
    }

    private static List<cuco__ps_catalog_condition_attribute__c> getCatCondAttNP(cuco__ps_catalog_condition__c catCond, List<cuco__ps_catalog_attribute__c> psCatAttPriceClass ) {
        final List<cuco__ps_catalog_condition_attribute__c> catCondAttNP = cuco.Test_Utils.createPSCatalogConditonAttributes(4, catCond, psCatAttPriceClass);
        catCondAttNP[0].cuco__gf_psc_condition_attribute_id__c = 'np.nat.transfer.EEE.ob.branch.max';
        catCondAttNP[1].cuco__gf_psc_condition_attribute_id__c = 'np.nat.transfer.EEE.ob.branch.min';
        catCondAttNP[2].cuco__gf_psc_condition_attribute_id__c = 'np.nat.transfer.EEE.ob.branch.amount';
        catCondAttNP[3].cuco__gf_psc_condition_attribute_id__c = 'np.nat.transfer.EEE.ob.branch.type';
        return catCondAttNP;
    }

    private static List<cuco__ps_catalog_condition_attribute__c> getCatCondAttStock(cuco__ps_catalog_condition__c catCond, List<cuco__ps_catalog_attribute__c> psCatAttPriceClass ) {
        final List<cuco__ps_catalog_condition_attribute__c> catCondAttStock = cuco.Test_Utils.createPSCatalogConditonAttributes(4, catCond, psCatAttPriceClass);
        catCondAttStock[1].cuco__gf_psc_condition_attribute_id__c = 'stock.domestic.equity.sharesale.min';
        catCondAttStock[2].cuco__gf_psc_condition_attribute_id__c = 'stock.domestic.equity.sharesale.amount';
        catCondAttStock[3].cuco__gf_psc_condition_attribute_id__c = 'stock.domestic.equity.sharesale.type';
        return catCondAttStock;
    }

    private static List<cuco__ps_catalog_condition_attribute__c> getCatCondAttCheck(cuco__ps_catalog_condition__c catCond, List<cuco__ps_catalog_attribute__c> psCatAttPriceClass ) {
        final List<cuco__ps_catalog_condition_attribute__c> catCondAttCheck = cuco.Test_Utils.createPSCatalogConditonAttributes(4, catCond, psCatAttPriceClass);
        catCondAttCheck[0].cuco__gf_psc_condition_attribute_id__c = 'np.t.check.letter.max';
        catCondAttCheck[1].cuco__gf_psc_condition_attribute_id__c = 'np.t.check.letter.min';
        catCondAttCheck[2].cuco__gf_psc_condition_attribute_id__c = 'np.t.check.letter.amount';
        catCondAttCheck[3].cuco__gf_psc_condition_attribute_id__c = 'np.t.check.letter.type';
        return catCondAttCheck;
    }

    private static cuco.ConditionsValidationInput_Wrapper getInputWrapper(String jsonStr) {
        final Map<String, Object> inputMap = (Map<String, Object>)System.JSON.deserializeUntyped(jsonStr);
        final cuco.ConditionsValidationInput_Wrapper inputWrapper = new cuco.ConditionsValidationInput_Wrapper();
        final List<cuco.ConditionsValidationInput_Wrapper.Condition> wrapperConditions = new List<cuco.ConditionsValidationInput_Wrapper.Condition>();
        final List<Object> objConditions = (List<Object>) inputMap.get('conditions');
        for (Object objCondition : objConditions) {
            final Map<String, Object> mapCondition = (Map<String, Object>)objCondition;
            final cuco.ConditionsValidationInput_Wrapper.Condition wrapperCondition = new cuco.ConditionsValidationInput_Wrapper.Condition();
            wrapperCondition.id = (String)mapCondition.get('id');
            final List<cuco.ConditionsValidationInput_Wrapper.Attribute> wrapperAttributes = new List<cuco.ConditionsValidationInput_Wrapper.Attribute>();
            final List<Object> objAttributes = (List<Object>) mapCondition.get('attributes');
            for (Object objAttribute : objAttributes) {
                final Map<String, Object> mapAttribute = (Map<String, Object>)objAttribute;
                final cuco.ConditionsValidationInput_Wrapper.Attribute wrapperAttribute = new cuco.ConditionsValidationInput_Wrapper.Attribute();
                wrapperAttribute.id = (String)mapAttribute.get('id');
                wrapperAttribute.proposed = (String)mapAttribute.get('proposed');
                wrapperAttributes.add(wrapperAttribute);
            }
            wrapperCondition.attributes = wrapperAttributes;
            wrapperConditions.add(wrapperCondition);
        }
        inputWrapper.conditions = wrapperConditions;
        return inputWrapper;
    }

    //Test Check Boolean OK
    @IsTest
    static void checkBooleanOKTest() {

        final List<cuco__ps_catalog_condition__c> catCondSEPA = [SELECT Id FROM cuco__ps_catalog_condition__c WHERE cuco__gf_psc_condition_id__c = 'debit.sepa.postal'];

        String inputBooleanOK = inputBoolean;
        inputBooleanOK = inputBooleanOK.replace('#CONDITION_ID#',catCondSEPA[0].Id);
        inputBooleanOK = inputBooleanOK.replace('#VALUE_ID#','true');

        final cuco.ConditionsValidationInput_Wrapper inputWrapper = getInputWrapper(inputBooleanOK);
        final CucoConditionsCIB instance = new CucoConditionsCIB();
        final cuco.ConditionsValidationErrors_Wrapper res = instance.validateInputConditionValues(inputWrapper);
        final List<cuco.ConditionsValidationErrors_Wrapper.Condition> errors = res.conditions;

        System.assertEquals(null, errors, 'checkBooleanOKTest - with errors');
    }

    //Test Check Boolean KO
    @IsTest
    static void checkBooleanKOTest() {

        final List<cuco__ps_catalog_condition__c> catCondSEPA = [SELECT Id FROM cuco__ps_catalog_condition__c WHERE cuco__gf_psc_condition_id__c = 'debit.sepa.postal'];

        String inputBooleanKO = inputBoolean;
        inputBooleanKO = inputBooleanKO.replace('#CONDITION_ID#',catCondSEPA[0].Id);
        inputBooleanKO = inputBooleanKO.replace('#VALUE_ID#','false');

        final cuco.ConditionsValidationInput_Wrapper inputWrapper = getInputWrapper(inputBooleanKO);
        final CucoConditionsCIB instance = new CucoConditionsCIB();
        final cuco.ConditionsValidationErrors_Wrapper res = instance.validateInputConditionValues(inputWrapper);
        final List<cuco.ConditionsValidationErrors_Wrapper.Condition> errors = res.conditions;

        System.assertEquals(Label.cuco.cond_false_checkbox_error, errors[0].messages[0], 'checkBooleanKOTest - error does not match');
    }

    // Test Check Mandatory Fixed Price Class Fields KO
    @IsTest
    static void checkMandFixedPCKOTest() {

        final List<cuco__ps_catalog_condition__c> catCondNP = [SELECT Id FROM cuco__ps_catalog_condition__c WHERE cuco__gf_psc_condition_id__c = 'np.nat.transfer.EEE.ob.branch'];

        String pcFixedKOInput = mandatoryPCFixedKOInput;
        pcFixedKOInput = pcFixedKOInput.replace('#CONDITION_ID#',catCondNP[0].Id);

        final cuco.ConditionsValidationInput_Wrapper inputWrapper = getInputWrapper(pcFixedKOInput);
        final CucoConditionsCIB instance = new CucoConditionsCIB();
        final cuco.ConditionsValidationErrors_Wrapper res = instance.validateInputConditionValues(inputWrapper);
        final List<cuco.ConditionsValidationErrors_Wrapper.Condition> errors = res.conditions;

        System.assertEquals(Label.cuco.cond_variable_extra_fields, errors[0].messages[0], 'checkMandFixedPCKOTest - error does not match');
    }

    // Test Check Mandatory Fixed Price Class Fields OK
    @IsTest
    static void checkMandFixedPCOKTest() {
        final List<cuco__ps_catalog_condition__c> catCondNP = [SELECT Id FROM cuco__ps_catalog_condition__c WHERE cuco__gf_psc_condition_id__c = 'np.nat.transfer.EEE.ob.branch'];

        String pcFixedOKInput = mandatoryPCFixedOKInput;
        pcFixedOKInput = pcFixedOKInput.replace('#CONDITION_ID#',catCondNP[0].Id);

        final cuco.ConditionsValidationInput_Wrapper inputWrapper = getInputWrapper(pcFixedOKInput);
        CucoConditionsCIB instance = new CucoConditionsCIB();
        final cuco.ConditionsValidationErrors_Wrapper res = instance.validateInputConditionValues(inputWrapper);
        final List<cuco.ConditionsValidationErrors_Wrapper.Condition> errors = res.conditions;

        System.assertEquals(null, errors, 'checkMandFixedPCOKTest - error list not empty');
    }

    // Test Check Mandatory Variable Price Class Fields KO
    @IsTest
    static void checkMandVariablePCKOTest() {
        final List<cuco__ps_catalog_condition__c> catCondNP = [SELECT Id FROM cuco__ps_catalog_condition__c WHERE cuco__gf_psc_condition_id__c = 'np.nat.transfer.EEE.ob.branch'];

        String pcVariableKOInput = mandatoryPCVariableKOInput;
        pcVariableKOInput = pcVariableKOInput.replace('#CONDITION_ID#',catCondNP[0].Id);

        final cuco.ConditionsValidationInput_Wrapper inputWrapper = getInputWrapper(pcVariableKOInput);
        final CucoConditionsCIB instance = new CucoConditionsCIB();
        final cuco.ConditionsValidationErrors_Wrapper res = instance.validateInputConditionValues(inputWrapper);
        final List<cuco.ConditionsValidationErrors_Wrapper.Condition> errors = res.conditions;

        System.assertEquals(Label.cuco.cond_variable_missing_fields, errors[0].messages[0], 'checkMandVariablePCKOTest - error does not match');
    }

    // Test Check Mandatory Variable Price Class Fields OK
    @IsTest
    static void checkMandVariablePCOKTest() {
        final List<cuco__ps_catalog_condition__c> catCondNP = [SELECT Id FROM cuco__ps_catalog_condition__c WHERE cuco__gf_psc_condition_id__c = 'np.nat.transfer.EEE.ob.branch'];

        String pcVariableOKInput = mandatoryPCVariableOKInput;
        pcVariableOKInput = pcVariableOKInput.replace('#CONDITION_ID#',catCondNP[0].Id);

        final cuco.ConditionsValidationInput_Wrapper inputWrapper = getInputWrapper(pcVariableOKInput);
        final CucoConditionsCIB instance = new CucoConditionsCIB();
        final cuco.ConditionsValidationErrors_Wrapper res = instance.validateInputConditionValues(inputWrapper);
        final List<cuco.ConditionsValidationErrors_Wrapper.Condition> errors = res.conditions;

        System.assertEquals(null, errors, 'checkMandVariablePCOKTest - error list not empty');

    }

    // Test Check Mandatory Other Fields KO
    @IsTest
    static void checkMandOtherPCKOTest() {
        final List<cuco__ps_catalog_condition__c> catCondCard = [SELECT Id FROM cuco__ps_catalog_condition__c WHERE cuco__gf_psc_condition_id__c = 'card.bbva.others.gift'];

        String pcOtherKOInput = mandatoryOtherKOInput;
        pcOtherKOInput = pcOtherKOInput.replace('#CONDITION_ID#',catCondCard[0].Id);

        final cuco.ConditionsValidationInput_Wrapper inputWrapper = getInputWrapper(pcOtherKOInput);
        final CucoConditionsCIB instance = new CucoConditionsCIB();
        final cuco.ConditionsValidationErrors_Wrapper res = instance.validateInputConditionValues(inputWrapper);
        final List<cuco.ConditionsValidationErrors_Wrapper.Condition> errors = res.conditions;

        System.assertEquals(Label.cuco.cond_missing_fields_error, errors[0].messages[0], 'checkMandOtherPCKOTest - error does not match');
    }

    // Test Check Mandatory Other Fields OK
    @IsTest
    static void checkMandOtherPCOKTest() {
        final List<cuco__ps_catalog_condition__c> catCondCard = [SELECT Id FROM cuco__ps_catalog_condition__c WHERE cuco__gf_psc_condition_id__c = 'card.bbva.others.gift'];

        String pcOtherOKInput = mandatoryOtherOKInput;
        pcOtherOKInput = pcOtherOKInput.replace('#CONDITION_ID#',catCondCard[0].Id);

        final cuco.ConditionsValidationInput_Wrapper inputWrapper = getInputWrapper(pcOtherOKInput);
        final CucoConditionsCIB instance = new CucoConditionsCIB();
        final cuco.ConditionsValidationErrors_Wrapper res = instance.validateInputConditionValues(inputWrapper);
        final List<cuco.ConditionsValidationErrors_Wrapper.Condition> errors = res.conditions;

        System.assertEquals(1, errors.size(), 'checkMandOtherPCOKTest - error list not empty');
    }

    // Test Check Max vs Min - Max bigger than Min KO
    @IsTest
    static void checkMaxBiggerMinKOTest() {

        final List<cuco__ps_catalog_condition__c> catCondNP = [SELECT Id FROM cuco__ps_catalog_condition__c WHERE cuco__gf_psc_condition_id__c = 'np.nat.transfer.EEE.ob.branch'];

        String pcMaxMinKOInput = maxBiggerMinKOInput;
        pcMaxMinKOInput = pcMaxMinKOInput.replace('#CONDITION_ID#',catCondNP[0].Id);

        final cuco.ConditionsValidationInput_Wrapper inputWrapper = getInputWrapper(pcMaxMinKOInput);
        final CucoConditionsCIB instance = new CucoConditionsCIB();
        final cuco.ConditionsValidationErrors_Wrapper res = instance.validateInputConditionValues(inputWrapper);
        final List<cuco.ConditionsValidationErrors_Wrapper.Condition> errors = res.conditions;

        System.assertEquals(Label.cuco.cond_min_greater_max_error, errors[0].messages[0], 'checkMaxBiggerMinKOTest - error does not match');
    }

    // Test Check Max vs Min - Max bigger than Min OK
    @IsTest
    static void checkMaxBiggerMinOKTest() {

        final List<cuco__ps_catalog_condition__c> catCondNP = [SELECT Id FROM cuco__ps_catalog_condition__c WHERE cuco__gf_psc_condition_id__c = 'np.nat.transfer.EEE.ob.branch'];

        String pcMaxMinOKInput = maxBiggerMinOKInput;
        pcMaxMinOKInput = pcMaxMinOKInput.replace('#CONDITION_ID#',catCondNP[0].Id);

        final cuco.ConditionsValidationInput_Wrapper inputWrapper = getInputWrapper(pcMaxMinOKInput);
        final CucoConditionsCIB instance = new CucoConditionsCIB();
        final cuco.ConditionsValidationErrors_Wrapper res = instance.validateInputConditionValues(inputWrapper);
        final List<cuco.ConditionsValidationErrors_Wrapper.Condition> errors = res.conditions;

        System.assertEquals(null, errors, 'checkMaxBiggerMinOKTest - error list not empty');
    }

    // Test Check Max vs Min - No Max or Min OK
    @IsTest
    static void checkNoMaxMinOKTest() {

        final List<cuco__ps_catalog_condition__c> catCondCard = [SELECT Id FROM cuco__ps_catalog_condition__c WHERE cuco__gf_psc_condition_id__c = 'card.bbva.others.gift'];

        String noMaxMinOKInput = mandatoryOtherOKInput;
        noMaxMinOKInput = noMaxMinOKInput.replace('#CONDITION_ID#',catCondCard[0].Id);

        final cuco.ConditionsValidationInput_Wrapper inputWrapper = getInputWrapper(noMaxMinOKInput);
        final CucoConditionsCIB instance = new CucoConditionsCIB();
        final cuco.ConditionsValidationErrors_Wrapper res = instance.validateInputConditionValues(inputWrapper);
        final List<cuco.ConditionsValidationErrors_Wrapper.Condition> errors = res.conditions;

        System.assertEquals(1, errors.size(), 'checkNoMaxMinOKTest - error list not empty');
    }

    // Test Check Transfer - With Expense Zero Type OK
    @IsTest
    static void checkExpZeroTypeKOTest() {

        final List<cuco__ps_catalog_condition__c> catCondNP = [SELECT Id FROM cuco__ps_catalog_condition__c WHERE cuco__gf_psc_condition_id__c IN ('np.nat.transfer.EEE.ob.branch','np.transfer.mail.expenses') ORDER BY cuco__gf_psc_condition_id__c ASC];

        String expWithExpZeroTypeKO = withExpZeroTypeKOInput;
        expWithExpZeroTypeKO = expWithExpZeroTypeKO.replace('#CONDITION_ID_2#',catCondNP[0].Id);
        expWithExpZeroTypeKO = expWithExpZeroTypeKO.replace('#CONDITION_ID_1#',catCondNP[1].Id);

        final cuco.ConditionsValidationInput_Wrapper inputWrapper = getInputWrapper(expWithExpZeroTypeKO);
        final CucoConditionsCIB instance = new CucoConditionsCIB();
        final cuco.ConditionsValidationErrors_Wrapper res = instance.validateInputConditionValues(inputWrapper);
        final List<cuco.ConditionsValidationErrors_Wrapper.Condition> errors = res.conditions;

        System.assertEquals(Label.cuco.cond_transfer_min_max_not_equal_error, errors[0].messages[0], 'checkExpZeroTypeKOTest - error does not match');
    }

    // Test Check Transfer - With Expense Zero Type OK
    @IsTest
    static void checkExpZeroTypeOKTest() {

        final List<cuco__ps_catalog_condition__c> catCondNP = [SELECT Id FROM cuco__ps_catalog_condition__c WHERE cuco__gf_psc_condition_id__c IN ('np.nat.transfer.EEE.ob.branch','np.transfer.mail.expenses') ORDER BY cuco__gf_psc_condition_id__c ASC];

        String expWithExpZeroTypeOK = withExpZeroTypeOKInput;
        expWithExpZeroTypeOK = expWithExpZeroTypeOK.replace('#CONDITION_ID_2#',catCondNP[0].Id);
        expWithExpZeroTypeOK = expWithExpZeroTypeOK.replace('#CONDITION_ID_1#',catCondNP[1].Id);

        final cuco.ConditionsValidationInput_Wrapper inputWrapper = getInputWrapper(expWithExpZeroTypeOK);
        final CucoConditionsCIB instance = new CucoConditionsCIB();
        final cuco.ConditionsValidationErrors_Wrapper res = instance.validateInputConditionValues(inputWrapper);
        final List<cuco.ConditionsValidationErrors_Wrapper.Condition> errors = res.conditions;

        System.assertEquals(null, errors, 'checkExpZeroTypeOKTest - error list not empty');
    }

    // Test Check Transfer - With Expense Non Zero Type KO
    @IsTest
    static void checkExpNonZeroTypeKOTest() {

        final List<cuco__ps_catalog_condition__c> catCondNP = [SELECT Id FROM cuco__ps_catalog_condition__c WHERE cuco__gf_psc_condition_id__c IN ('np.nat.transfer.EEE.ob.branch','np.transfer.mail.expenses') ORDER BY cuco__gf_psc_condition_id__c ASC];

        String expWithExpNonZeroTypeKO = withExpNonZeroTypeKOInput;
        expWithExpNonZeroTypeKO = expWithExpNonZeroTypeKO.replace('#CONDITION_ID_2#',catCondNP[0].Id);
        expWithExpNonZeroTypeKO = expWithExpNonZeroTypeKO.replace('#CONDITION_ID_1#',catCondNP[1].Id);

        final cuco.ConditionsValidationInput_Wrapper inputWrapper = getInputWrapper(expWithExpNonZeroTypeKO);
        final CucoConditionsCIB instance = new CucoConditionsCIB();
        final cuco.ConditionsValidationErrors_Wrapper res = instance.validateInputConditionValues(inputWrapper);
        final List<cuco.ConditionsValidationErrors_Wrapper.Condition> errors = res.conditions;

        System.assertEquals(Label.cuco.cond_transfer_min_max_equal_error, errors[0].messages[0], 'checkExpNonZeroTypeKOTest - error does not match');
    }

    // Test Check Transfer - With Expense Non Zero Type OK
    @IsTest
    static void checkExpNonZeroTypeOKTest() {

        final List<cuco__ps_catalog_condition__c> catCondNP = [SELECT Id FROM cuco__ps_catalog_condition__c WHERE cuco__gf_psc_condition_id__c IN ('np.nat.transfer.EEE.ob.branch','np.transfer.mail.expenses') ORDER BY cuco__gf_psc_condition_id__c ASC];

        String expWithExpNonZeroTypeOK = withExpNonZeroTypeOKInput;
        expWithExpNonZeroTypeOK = expWithExpNonZeroTypeOK.replace('#CONDITION_ID_2#',catCondNP[0].Id);
        expWithExpNonZeroTypeOK = expWithExpNonZeroTypeOK.replace('#CONDITION_ID_1#',catCondNP[1].Id);

        final cuco.ConditionsValidationInput_Wrapper inputWrapper = getInputWrapper(expWithExpNonZeroTypeOK);
        final CucoConditionsCIB instance = new CucoConditionsCIB();
        final cuco.ConditionsValidationErrors_Wrapper res = instance.validateInputConditionValues(inputWrapper);
        final List<cuco.ConditionsValidationErrors_Wrapper.Condition> errors = res.conditions;

        System.assertEquals(null, errors, 'checkExpNonZeroTypeOKTest - error list not empty');
    }

    // Test Check Transfer - Without Expense
    @IsTest
    static void checkWithoutExpTest() {

        final List<cuco__ps_catalog_condition__c> catCondNP = [SELECT Id FROM cuco__ps_catalog_condition__c WHERE cuco__gf_psc_condition_id__c = 'np.nat.transfer.EEE.ob.branch'];

        String withoutExp = withoutExpInput;
        withoutExp = withoutExp.replace('#CONDITION_ID#',catCondNP[0].Id);

        final cuco.ConditionsValidationInput_Wrapper inputWrapper = getInputWrapper(withoutExp);
        final CucoConditionsCIB instance = new CucoConditionsCIB();
        final cuco.ConditionsValidationErrors_Wrapper res = instance.validateInputConditionValues(inputWrapper);
        final List<cuco.ConditionsValidationErrors_Wrapper.Condition> errors = res.conditions;

        System.assertEquals(null, errors, 'checkWithoutExpTest - error list not empty');
    }

    // Test Card Business KO
    @IsTest
    static void cardBusKOTest() {

        final List<cuco__ps_catalog_condition__c> catCondCard = [SELECT Id FROM cuco__ps_catalog_condition__c WHERE cuco__gf_psc_condition_id__c = 'card.bbva.business'];

        String cardBusKO = cardBusinessInput;
        cardBusKO = cardBusKO.replace('#CONDITION_ID#',catCondCard[0].Id);
        cardBusKO = cardBusKO.replace('#VALUE_ID#','5');

        final cuco.ConditionsValidationInput_Wrapper inputWrapper = getInputWrapper(cardBusKO);
        final CucoConditionsCIB instance = new CucoConditionsCIB();
        final cuco.ConditionsValidationErrors_Wrapper res = instance.validateInputConditionValues(inputWrapper);
        final List<cuco.ConditionsValidationErrors_Wrapper.Condition> errors = res.conditions;

        System.assertEquals(Label.cuco.cond_card_business_value_error, errors[0].messages[0], 'cardBusKOTest - error does not match');
    }

    // Test Card Business OK
    @IsTest
    static void cardBusOKTest() {

        final List<cuco__ps_catalog_condition__c> catCondCard = [SELECT Id FROM cuco__ps_catalog_condition__c WHERE cuco__gf_psc_condition_id__c = 'card.bbva.business'];

        String cardBusKO = cardBusinessInput;
        cardBusKO = cardBusKO.replace('#CONDITION_ID#',catCondCard[0].Id);
        cardBusKO = cardBusKO.replace('#VALUE_ID#','10');

        final cuco.ConditionsValidationInput_Wrapper inputWrapper = getInputWrapper(cardBusKO);
        final CucoConditionsCIB instance = new CucoConditionsCIB();
        final cuco.ConditionsValidationErrors_Wrapper res = instance.validateInputConditionValues(inputWrapper);
        final List<cuco.ConditionsValidationErrors_Wrapper.Condition> errors = res.conditions;

        System.assertEquals(null, errors, 'cardBusOKTest - error list not empty');
    }

    // Test Card Corporate KO
    @IsTest
    static void cardCorpKOTest() {

        final List<cuco__ps_catalog_condition__c> catCondCard = [SELECT Id FROM cuco__ps_catalog_condition__c WHERE cuco__gf_psc_condition_id__c = 'card.bbva.corporate'];

        String cardCorpKO = cardCorpInput;
        cardCorpKO = cardCorpKO.replace('#CONDITION_ID#',catCondCard[0].Id);
        cardCorpKO = cardCorpKO.replace('#VALUE_ID#','5');

        final cuco.ConditionsValidationInput_Wrapper inputWrapper = getInputWrapper(cardCorpKO);
        final CucoConditionsCIB instance = new CucoConditionsCIB();
        final cuco.ConditionsValidationErrors_Wrapper res = instance.validateInputConditionValues(inputWrapper);
        final List<cuco.ConditionsValidationErrors_Wrapper.Condition> errors = res.conditions;

        System.assertEquals(Label.cuco.cond_card_corporate_value_error, errors[0].messages[0], 'cardCorpKOTest - error does not match');
    }

    // Test Card Corporate OK
    @IsTest
    static void cardCorpOKTest() {

        final List<cuco__ps_catalog_condition__c> catCondCard = [SELECT Id FROM cuco__ps_catalog_condition__c WHERE cuco__gf_psc_condition_id__c = 'card.bbva.corporate'];

        String cardCorpKO = cardCorpInput;
        cardCorpKO = cardCorpKO.replace('#CONDITION_ID#',catCondCard[0].Id);
        cardCorpKO = cardCorpKO.replace('#VALUE_ID#','0');

        final cuco.ConditionsValidationInput_Wrapper inputWrapper = getInputWrapper(cardCorpKO);
        final CucoConditionsCIB instance = new CucoConditionsCIB();
        final cuco.ConditionsValidationErrors_Wrapper res = instance.validateInputConditionValues(inputWrapper);
        final List<cuco.ConditionsValidationErrors_Wrapper.Condition> errors = res.conditions;

        System.assertEquals(null, errors, 'cardCorpOKTest - error list not empty');
    }

    // Test Card Express KO
    @IsTest
    static void cardExpKOTest() {

        final List<cuco__ps_catalog_condition__c> catCondCard = [SELECT Id FROM cuco__ps_catalog_condition__c WHERE cuco__gf_psc_condition_id__c = 'card.bbva.others.express'];

        String cardExpKO = cardExpInput;
        cardExpKO = cardExpKO.replace('#CONDITION_ID#',catCondCard[0].Id);
        cardExpKO = cardExpKO.replace('#VALUE_ID#','5');

        final cuco.ConditionsValidationInput_Wrapper inputWrapper = getInputWrapper(cardExpKO);
        final CucoConditionsCIB instance = new CucoConditionsCIB();
        final cuco.ConditionsValidationErrors_Wrapper res = instance.validateInputConditionValues(inputWrapper);
        final List<cuco.ConditionsValidationErrors_Wrapper.Condition> errors = res.conditions;

        System.assertEquals(Label.cuco.cond_card_express_value_error, errors[0].messages[0], 'cardExpKOTest - error does not match');
    }

    // Test Card Express OK
    @IsTest
    static void cardExpOKTest() {

        final List<cuco__ps_catalog_condition__c> catCondCard = [SELECT Id FROM cuco__ps_catalog_condition__c WHERE cuco__gf_psc_condition_id__c = 'card.bbva.others.express'];

        String cardExpKO = cardExpInput;
        cardExpKO = cardExpKO.replace('#CONDITION_ID#',catCondCard[0].Id);
        cardExpKO = cardExpKO.replace('#VALUE_ID#','3');

        final cuco.ConditionsValidationInput_Wrapper inputWrapper = getInputWrapper(cardExpKO);
        final CucoConditionsCIB instance = new CucoConditionsCIB();
        final cuco.ConditionsValidationErrors_Wrapper res = instance.validateInputConditionValues(inputWrapper);
        final List<cuco.ConditionsValidationErrors_Wrapper.Condition> errors = res.conditions;

        System.assertEquals(null, errors, 'cardExpOKTest - error list not empty');
    }

    // Test Card Gift KO
    @IsTest
    static void cardGiftKOTest() {

        final List<cuco__ps_catalog_condition__c> catCondCard = [SELECT Id FROM cuco__ps_catalog_condition__c WHERE cuco__gf_psc_condition_id__c = 'card.bbva.others.gift'];

        String cardGiftKO = cardGiftInput;
        cardGiftKO = cardGiftKO.replace('#CONDITION_ID#',catCondCard[0].Id);
        cardGiftKO = cardGiftKO.replace('#VALUE_ID#','8');

        final cuco.ConditionsValidationInput_Wrapper inputWrapper = getInputWrapper(cardGiftKO);
        final CucoConditionsCIB instance = new CucoConditionsCIB();
        final cuco.ConditionsValidationErrors_Wrapper res = instance.validateInputConditionValues(inputWrapper);
        final List<cuco.ConditionsValidationErrors_Wrapper.Condition> errors = res.conditions;

        System.assertEquals(Label.cuco.cond_card_gift_value_error, errors[0].messages[0], 'cardGiftKOTest - error does not match');
    }

    // Test Card Gift OK
    @IsTest
    static void cardGiftOKTest() {

        final List<cuco__ps_catalog_condition__c> catCondCard = [SELECT Id FROM cuco__ps_catalog_condition__c WHERE cuco__gf_psc_condition_id__c = 'card.bbva.others.gift'];

        String cardGiftKO = cardGiftInput;
        cardGiftKO = cardGiftKO.replace('#CONDITION_ID#',catCondCard[0].Id);
        cardGiftKO = cardGiftKO.replace('#VALUE_ID#','0.5');

        final cuco.ConditionsValidationInput_Wrapper inputWrapper = getInputWrapper(cardGiftKO);
        final CucoConditionsCIB instance = new CucoConditionsCIB();
        final cuco.ConditionsValidationErrors_Wrapper res = instance.validateInputConditionValues(inputWrapper);
        final List<cuco.ConditionsValidationErrors_Wrapper.Condition> errors = res.conditions;

        System.assertEquals(null, errors, 'cardGiftOKTest - error list not empty');
    }

    // Test Full Range KO
    @IsTest
    static void fullRangeKOTest() {

        final List<cuco__ps_catalog_condition__c> catCondCard = [SELECT Id FROM cuco__ps_catalog_condition__c WHERE cuco__gf_psc_condition_id__c = 'card.bbva.business'];

        String cardBusKO = cardBusinessInput;
        cardBusKO = cardBusKO.replace('#CONDITION_ID#',catCondCard[0].Id);
        cardBusKO = cardBusKO.replace('#VALUE_ID#','25');

        final cuco.ConditionsValidationInput_Wrapper inputWrapper = getInputWrapper(cardBusKO);
        final CucoConditionsCIB instance = new CucoConditionsCIB();
        final cuco.ConditionsValidationErrors_Wrapper res = instance.validateInputConditionValues(inputWrapper);
        final List<cuco.ConditionsValidationErrors_Wrapper.Condition> errors = res.conditions;

        System.assertEquals(1, errors.size(), 'fullRangeKOTest - error list size');
    }

    // Test Max Range KO
    @IsTest
    static void maxRangeKOTest() {

        final List<cuco__ps_catalog_condition__c> catCondCard = [SELECT Id FROM cuco__ps_catalog_condition__c WHERE cuco__gf_psc_condition_id__c = 'card.bbva.corporate'];

        String cardKO = cardCorpInput;
        cardKO = cardKO.replace('#CONDITION_ID#',catCondCard[0].Id);
        cardKO = cardKO.replace('#VALUE_ID#','25');

        final cuco.ConditionsValidationInput_Wrapper inputWrapper = getInputWrapper(cardKO);
        final CucoConditionsCIB instance = new CucoConditionsCIB();
        final cuco.ConditionsValidationErrors_Wrapper res = instance.validateInputConditionValues(inputWrapper);
        final List<cuco.ConditionsValidationErrors_Wrapper.Condition> errors = res.conditions;

        System.assertEquals(1, errors.size(), 'maxRangeKOTest - error list size');
    }

    // Test Min Range KO
    @IsTest
    static void minRangeKOTest() {

        final List<cuco__ps_catalog_condition__c> catCondCard = [SELECT Id FROM cuco__ps_catalog_condition__c WHERE cuco__gf_psc_condition_id__c = 'card.bbva.others.express'];

        String cardKO = cardExpInput;
        cardKO = cardKO.replace('#CONDITION_ID#',catCondCard[0].Id);
        cardKO = cardKO.replace('#VALUE_ID#','0');

        final cuco.ConditionsValidationInput_Wrapper inputWrapper = getInputWrapper(cardKO);
        final CucoConditionsCIB instance = new CucoConditionsCIB();
        final cuco.ConditionsValidationErrors_Wrapper res = instance.validateInputConditionValues(inputWrapper);
        final List<cuco.ConditionsValidationErrors_Wrapper.Condition> errors = res.conditions;

        System.assertEquals(1, errors.size(), 'minRangeKOTest - error list size');
    }

    // Test No Range KO
    @IsTest
    static void noRangeKOTest() {

        final List<cuco__ps_catalog_condition__c> catCondCard = [SELECT Id FROM cuco__ps_catalog_condition__c WHERE cuco__gf_psc_condition_id__c = 'card.bbva.others.gift'];

        String cardKO = cardGiftInput;
        cardKO = cardKO.replace('#CONDITION_ID#',catCondCard[0].Id);
        cardKO = cardKO.replace('#VALUE_ID#','100');

        final cuco.ConditionsValidationInput_Wrapper inputWrapper = getInputWrapper(cardKO);
        final CucoConditionsCIB instance = new CucoConditionsCIB();
        final cuco.ConditionsValidationErrors_Wrapper res = instance.validateInputConditionValues(inputWrapper);
        final List<cuco.ConditionsValidationErrors_Wrapper.Condition> errors = res.conditions;

        System.assertEquals(1, errors.size(), 'noRangeKOTest - error list size');
    }

}