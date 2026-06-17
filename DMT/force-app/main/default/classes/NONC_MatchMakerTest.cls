@IsTest
private class NONC_MatchMakerTest {

    @IsTest
    static void testCompareStrings_identicalStrings() {
        Double result = NONC_MatchMaker.compareStrings('Hello', 'Hello');
        System.assertEquals(100.0, result, 'Cadenas idénticas deberían dar 100% de similitud');
    }

    @IsTest
    static void testCompareStrings_noMatch() {
        Double result = NONC_MatchMaker.compareStrings('Hello', 'World');
        System.assertEquals(0.0, result, 'Cadenas sin letras comunes deberían dar 0%');
    }

    @IsTest
    static void testCoincidentString_trueCase() {
        Boolean result = NONC_MatchMaker.coincidentString('Hello', 'Hello', 90);
        System.assertEquals(true, result, 'Cadenas idénticas superan el porcentaje requerido');
    }

    @IsTest
    static void testCoincidentString_falseCase() {
        Boolean result = NONC_MatchMaker.coincidentString('Hello', 'World', 10);
        System.assertEquals(false, result, 'Cadenas sin coincidencia no cumplen el porcentaje');
    }

    @IsTest
    static void testCoincidentNumber_equal() {
        Boolean result = NONC_MatchMaker.coincidentNumber(123L, 123L);
        System.assertEquals(true, result, 'Números iguales deben coincidir');
    }

    @IsTest
    static void testCoincidentNumber_different() {
        Boolean result = NONC_MatchMaker.coincidentNumber(123L, 456L);
        System.assertEquals(false, result, 'Números distintos no deben coincidir');
    }

    @IsTest
    static void testCompareStrings_withSpacesAndCase() {
        Double result = NONC_MatchMaker.compareStrings('Test Case', 'test case');
        System.assertEquals(100.0, result, 'Similitud debería ser 100% ignorando mayúsculas y espacios');
    }
}