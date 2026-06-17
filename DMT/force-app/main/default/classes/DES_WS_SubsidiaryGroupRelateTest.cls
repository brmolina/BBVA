@IsTest
private class DES_WS_SubsidiaryGroupRelateTest {

    @IsTest
    static void testRun_ReturnsDone() {
        Test.startTest();
        String result = DES_WS_SubsidiaryGroupRelate.run();
        Test.stopTest();

        System.assertEquals('Done', result, 'run() should return Done');
    }

}