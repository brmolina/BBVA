@IsTest
private class DMT_FormLookupControllerTest {

    // ═══════════════════════════════════════════════════════════════════════
    // Setup — 3 Local_Client__c con datos variados.
    // Local_Client__c es un objeto custom simple, sin las validaciones
    // pesadas de Account/Opportunity. Es además el objeto que el JS usa
    // realmente para el lookup.
    // ═══════════════════════════════════════════════════════════════════════
    @TestSetup
    static void setupTestData() {
        // generateAccount() ya inserta 1 Account + 1 Local_Client__c (con
        // Alpha_code__c = 'TEST123'). Lo recuperamos y lo actualizamos.
        Account acc = DMT_Test_DataFactory.generateAccount();

        Local_Client__c lc1 = [SELECT Id, Name, Alpha_code__c, Cib_Client__c
                                FROM Local_Client__c
                                WHERE Cib_Client__c = :acc.Id
                                LIMIT 1];
        lc1.Name = 'LKTest LC Alpha';
        lc1.Alpha_code__c = 'ALPHA001';
        update lc1;

        // Otros 2 Local_Client__c apuntando al mismo Account
        Local_Client__c lc2 = new Local_Client__c(
            Name = 'LKTest LC Beta',
            Alpha_code__c = 'BETA002',
            Cib_Client__c = acc.Id
        );
        Local_Client__c lc3 = new Local_Client__c(
            Name = 'LKTest LC Gamma',
            Alpha_code__c = 'GAMMA003',
            Cib_Client__c = acc.Id
        );
        insert new List<Local_Client__c>{ lc2, lc3 };
    }

    // ─────────────────────────────────────────────────────────────────────
    // Helpers
    // ─────────────────────────────────────────────────────────────────────
    private static Local_Client__c getLc(String name) {
        return [SELECT Id, Name, Alpha_code__c
                FROM Local_Client__c WHERE Name = :name LIMIT 1];
    }

    private static List<Map<String, Object>> runSearch(
        String term, String filtersJson, List<String> returnFields
    ) {
        return DMT_FormLookupController.searchRecords(
            'Local_Client__c',
            term,
            new List<String>{'Name'},
            filtersJson,
            returnFields,
            'Name',
            20
        );
    }

    private static Boolean containsName(List<Map<String, Object>> rows, String name) {
        for (Map<String, Object> r : rows) {
            if (name.equals(r.get('Name'))) return true;
        }
        return false;
    }

    // ═══════════════════════════════════════════════════════════════════════
    // searchRecords — búsqueda básica
    // ═══════════════════════════════════════════════════════════════════════
    @IsTest
    static void testBasicSearch() {
        Test.startTest();
        List<Map<String, Object>> r = runSearch(
            'LKTest LC Alpha', null, new List<String>{'Id','Name'}
        );
        Test.stopTest();

        System.assert(containsName(r, 'LKTest LC Alpha'), 'Should find Alpha');
    }

    @IsTest
    static void testEmptySearchReturnsAll() {
        Test.startTest();
        List<Map<String, Object>> r = runSearch(
            '', null, new List<String>{'Id','Name'}
        );
        Test.stopTest();

        System.assert(r.size() >= 1, 'Empty search should return records');
    }

    @IsTest
    static void testWhitespaceSearchIsTrimmed() {
        Test.startTest();
        List<Map<String, Object>> r = runSearch(
            '  LKTest LC Alpha  ', null, new List<String>{'Id','Name'}
        );
        Test.stopTest();

        System.assert(containsName(r, 'LKTest LC Alpha'),
            'Trimmed search should match the record');
    }

    // ═══════════════════════════════════════════════════════════════════════
    // searchRecords — filtro plano AND con =
    // ═══════════════════════════════════════════════════════════════════════
    @IsTest
    static void testFlatArrayFilters() {
        String filtersJson = JSON.serialize(new List<Map<String,Object>>{
            new Map<String,Object>{
                'field'=>'Alpha_code__c','operator'=>'=','value'=>'BETA002'
            }
        });

        Test.startTest();
        List<Map<String, Object>> r = runSearch(
            'LKTest', filtersJson, new List<String>{'Id','Name','Alpha_code__c'}
        );
        Test.stopTest();

        System.assert(containsName(r, 'LKTest LC Beta'),
            'Should find Beta by Alpha_code');
    }

    // ═══════════════════════════════════════════════════════════════════════
    // searchRecords — filtros anidados AND/OR
    // ═══════════════════════════════════════════════════════════════════════
    @IsTest
    static void testNestedAndOrFilters() {
        Map<String,Object> filtersMap = new Map<String,Object>{
            'AND' => new List<Object>{
                new Map<String,Object>{
                    'field'=>'Name','operator'=>'LIKE','value'=>'LKTest%'
                },
                new Map<String,Object>{
                    'OR' => new List<Object>{
                        new Map<String,Object>{
                            'field'=>'Alpha_code__c','operator'=>'=','value'=>'BETA002'
                        },
                        new Map<String,Object>{
                            'field'=>'Alpha_code__c','operator'=>'=','value'=>'GAMMA003'
                        }
                    }
                }
            }
        };

        Test.startTest();
        List<Map<String, Object>> r = runSearch(
            'LKTest',
            JSON.serialize(filtersMap),
            new List<String>{'Id','Name','Alpha_code__c'}
        );
        Test.stopTest();

        System.assert(containsName(r, 'LKTest LC Beta'), 'Should contain Beta');
        System.assert(containsName(r, 'LKTest LC Gamma'), 'Should contain Gamma');
    }

    // ═══════════════════════════════════════════════════════════════════════
    // searchRecords — operadores < <= > >= sobre el Name (orden alfabético)
    // ═══════════════════════════════════════════════════════════════════════
    @IsTest
    static void testGreaterThanOperator() {
        String filtersJson = JSON.serialize(new List<Map<String,Object>>{
            new Map<String,Object>{
                'field'=>'Alpha_code__c','operator'=>'>','value'=>'BETA999'
            }
        });

        Test.startTest();
        List<Map<String, Object>> r = runSearch(
            'LKTest', filtersJson, new List<String>{'Id','Name'}
        );
        Test.stopTest();

        System.assert(containsName(r, 'LKTest LC Gamma'),
            '> BETA999 should include Gamma (GAMMA003)');
    }

    @IsTest
    static void testGreaterOrEqualOperator() {
        String filtersJson = JSON.serialize(new List<Map<String,Object>>{
            new Map<String,Object>{
                'field'=>'Alpha_code__c','operator'=>'>=','value'=>'ALPHA001'
            }
        });

        Test.startTest();
        List<Map<String, Object>> r = runSearch(
            'LKTest', filtersJson, new List<String>{'Id','Name'}
        );
        Test.stopTest();

        System.assert(r.size() >= 3, '>= ALPHA001 should match all 3');
    }

    @IsTest
    static void testLessThanOperator() {
        String filtersJson = JSON.serialize(new List<Map<String,Object>>{
            new Map<String,Object>{
                'field'=>'Alpha_code__c','operator'=>'<','value'=>'BETA999'
            }
        });

        Test.startTest();
        List<Map<String, Object>> r = runSearch(
            'LKTest', filtersJson, new List<String>{'Id','Name'}
        );
        Test.stopTest();

        System.assert(containsName(r, 'LKTest LC Alpha'),
            '< BETA999 should include Alpha');
    }

    @IsTest
    static void testLessOrEqualOperator() {
        String filtersJson = JSON.serialize(new List<Map<String,Object>>{
            new Map<String,Object>{
                'field'=>'Alpha_code__c','operator'=>'<=','value'=>'BETA002'
            }
        });

        Test.startTest();
        List<Map<String, Object>> r = runSearch(
            'LKTest', filtersJson, new List<String>{'Id','Name'}
        );
        Test.stopTest();

        System.assert(containsName(r, 'LKTest LC Alpha'), 'Should contain Alpha');
        System.assert(containsName(r, 'LKTest LC Beta'), 'Should contain Beta');
    }

    // ═══════════════════════════════════════════════════════════════════════
    // searchRecords — operador IN
    // ═══════════════════════════════════════════════════════════════════════
    @IsTest
    static void testInOperator() {
        String filtersJson = JSON.serialize(new List<Map<String,Object>>{
            new Map<String,Object>{
                'field' => 'Alpha_code__c',
                'operator' => 'IN',
                'value' => new List<String>{'ALPHA001','BETA002','GAMMA003'}
            }
        });

        Test.startTest();
        List<Map<String, Object>> r = runSearch(
            'LKTest', filtersJson, new List<String>{'Id','Name','Alpha_code__c'}
        );
        Test.stopTest();

        System.assert(r.size() >= 3, 'IN should match all 3');
    }

    // ═══════════════════════════════════════════════════════════════════════
    // searchRecords — LIKE por defecto (sin operator)
    // ═══════════════════════════════════════════════════════════════════════
    @IsTest
    static void testLikeOperatorDefault() {
        String filtersJson = JSON.serialize(new List<Map<String,Object>>{
            new Map<String,Object>{
                'field'=>'Alpha_code__c','value'=>'GAMMA%'
            }
        });

        Test.startTest();
        List<Map<String, Object>> r = runSearch(
            'LKTest', filtersJson, new List<String>{'Id','Name','Alpha_code__c'}
        );
        Test.stopTest();

        System.assert(containsName(r, 'LKTest LC Gamma'),
            'LIKE GAMMA% should match Gamma');
    }

    // ═══════════════════════════════════════════════════════════════════════
    // searchRecords — límite
    // ═══════════════════════════════════════════════════════════════════════
    @IsTest
    static void testLimitCappedAt20() {
        Test.startTest();
        List<Map<String, Object>> r = DMT_FormLookupController.searchRecords(
            'Local_Client__c', '', new List<String>{'Name'}, null,
            new List<String>{'Id','Name'}, 'Name', 99
        );
        Test.stopTest();

        System.assert(r.size() <= 20, 'Result should be capped at 20');
    }

    @IsTest
    static void testNullLimitUsesDefault() {
        Test.startTest();
        List<Map<String, Object>> r = DMT_FormLookupController.searchRecords(
            'Local_Client__c', 'LKTest', new List<String>{'Name'}, null,
            new List<String>{'Id','Name'}, 'Name', null
        );
        Test.stopTest();

        System.assert(r.size() <= 20);
    }

    @IsTest
    static void testZeroLimitUsesDefault() {
        Test.startTest();
        List<Map<String, Object>> r = DMT_FormLookupController.searchRecords(
            'Local_Client__c', 'LKTest', new List<String>{'Name'}, null,
            new List<String>{'Id','Name'}, 'Name', 0
        );
        Test.stopTest();

        System.assert(r.size() <= 20);
    }

    @IsTest
    static void testNegativeLimitUsesDefault() {
        Test.startTest();
        List<Map<String, Object>> r = DMT_FormLookupController.searchRecords(
            'Local_Client__c', 'LKTest', new List<String>{'Name'}, null,
            new List<String>{'Id','Name'}, 'Name', -5
        );
        Test.stopTest();

        System.assert(r.size() <= 20, 'Negative limit should fall back to default');
    }

    @IsTest
    static void testCustomLimitUnderMax() {
        Test.startTest();
        List<Map<String, Object>> r = DMT_FormLookupController.searchRecords(
            'Local_Client__c', 'LKTest', new List<String>{'Name'}, null,
            new List<String>{'Id','Name'}, 'Name', 2
        );
        Test.stopTest();

        System.assert(r.size() <= 2, 'Should respect custom limit of 2');
    }

    // ═══════════════════════════════════════════════════════════════════════
    // searchRecords — operador !=
    // ═══════════════════════════════════════════════════════════════════════
    @IsTest
    static void testNotEqualsOperator() {
        String filtersJson = JSON.serialize(new List<Map<String,Object>>{
            new Map<String,Object>{
                'field'=>'Alpha_code__c','operator'=>'!=','value'=>'BETA002'
            }
        });

        Test.startTest();
        List<Map<String, Object>> r = runSearch(
            'LKTest', filtersJson, new List<String>{'Id','Name','Alpha_code__c'}
        );
        Test.stopTest();

        System.assert(containsName(r, 'LKTest LC Alpha'), 'Should contain Alpha');
        System.assert(!containsName(r, 'LKTest LC Beta'), 'Should NOT contain Beta');
    }

    // ═══════════════════════════════════════════════════════════════════════
    // searchRecords — LIKE con valor vacío/wildcards se ignora
    // ═══════════════════════════════════════════════════════════════════════
    @IsTest
    static void testEmptyLikeFilterSkipped() {
        String filtersJson = JSON.serialize(new List<Map<String,Object>>{
            new Map<String,Object>{
                'field'=>'Alpha_code__c','operator'=>'LIKE','value'=>'%%'
            }
        });

        Test.startTest();
        List<Map<String, Object>> r = runSearch(
            'LKTest', filtersJson, new List<String>{'Id','Name'}
        );
        Test.stopTest();

        System.assert(r.size() >= 3, 'Empty LIKE filter should be skipped');
    }

    @IsTest
    static void testLikeFilterOnlyUnderscoresSkipped() {
        String filtersJson = JSON.serialize(new List<Map<String,Object>>{
            new Map<String,Object>{
                'field'=>'Alpha_code__c','operator'=>'LIKE','value'=>'___'
            }
        });

        Test.startTest();
        List<Map<String, Object>> r = runSearch(
            'LKTest', filtersJson, new List<String>{'Id','Name'}
        );
        Test.stopTest();

        System.assert(r.size() >= 3, 'LIKE only-underscores should be skipped');
    }

    @IsTest
    static void testLikeFilterWithValueAndWildcards() {
        String filtersJson = JSON.serialize(new List<Map<String,Object>>{
            new Map<String,Object>{
                'field'=>'Alpha_code__c','operator'=>'LIKE','value'=>'BETA%'
            }
        });

        Test.startTest();
        List<Map<String, Object>> r = runSearch(
            'LKTest', filtersJson, new List<String>{'Id','Name'}
        );
        Test.stopTest();

        System.assert(containsName(r, 'LKTest LC Beta'),
            'LIKE BETA% should match Beta');
    }

    // ═══════════════════════════════════════════════════════════════════════
    // searchRecords — estructuras de filtro
    // ═══════════════════════════════════════════════════════════════════════
    @IsTest
    static void testEmptyFilterGroupSkipped() {
        Map<String,Object> filtersMap = new Map<String,Object>{
            'AND' => new List<Object>()
        };

        Test.startTest();
        List<Map<String, Object>> r = runSearch(
            'LKTest',
            JSON.serialize(filtersMap),
            new List<String>{'Id','Name'}
        );
        Test.stopTest();

        System.assert(r.size() >= 3, 'Empty filter group should not crash');
    }

    @IsTest
    static void testEmptyOrGroupSkipped() {
        Map<String,Object> filtersMap = new Map<String,Object>{
            'OR' => new List<Object>()
        };

        Test.startTest();
        List<Map<String, Object>> r = runSearch(
            'LKTest',
            JSON.serialize(filtersMap),
            new List<String>{'Id','Name'}
        );
        Test.stopTest();

        System.assert(r.size() >= 3, 'Empty OR group should not crash');
    }

    @IsTest
    static void testSingleChildGroup() {
        Map<String,Object> filtersMap = new Map<String,Object>{
            'AND' => new List<Object>{
                new Map<String,Object>{
                    'field'=>'Alpha_code__c','operator'=>'=','value'=>'ALPHA001'
                }
            }
        };

        Test.startTest();
        List<Map<String, Object>> r = runSearch(
            'LKTest',
            JSON.serialize(filtersMap),
            new List<String>{'Id','Name','Alpha_code__c'}
        );
        Test.stopTest();

        System.assert(containsName(r, 'LKTest LC Alpha'),
            'Single child group should return Alpha');
    }

    @IsTest
    static void testOrGroupWithMultipleChildren() {
        Map<String,Object> filtersMap = new Map<String,Object>{
            'OR' => new List<Object>{
                new Map<String,Object>{
                    'field'=>'Alpha_code__c','operator'=>'=','value'=>'ALPHA001'
                },
                new Map<String,Object>{
                    'field'=>'Alpha_code__c','operator'=>'=','value'=>'GAMMA003'
                }
            }
        };

        Test.startTest();
        List<Map<String, Object>> r = runSearch(
            'LKTest',
            JSON.serialize(filtersMap),
            new List<String>{'Id','Name'}
        );
        Test.stopTest();

        System.assert(containsName(r, 'LKTest LC Alpha'), 'Should contain Alpha');
        System.assert(containsName(r, 'LKTest LC Gamma'), 'Should contain Gamma');
    }

    @IsTest
    static void testLeafWithNullValueSkipped() {
        String filtersJson = '[{"field":"Alpha_code__c","operator":"=","value":null}]';

        Test.startTest();
        List<Map<String, Object>> r = runSearch(
            'LKTest', filtersJson, new List<String>{'Id','Name'}
        );
        Test.stopTest();

        System.assert(r.size() >= 3, 'Null value leaf should be skipped');
    }

    @IsTest
    static void testLeafWithBlankFieldSkipped() {
        String filtersJson = '[{"field":"","operator":"=","value":"x"}]';

        Test.startTest();
        List<Map<String, Object>> r = runSearch(
            'LKTest', filtersJson, new List<String>{'Id','Name'}
        );
        Test.stopTest();

        System.assert(r.size() >= 3, 'Blank field leaf should be skipped');
    }

    @IsTest
    static void testFilterJsonAsPrimitiveReturnsEmpty() {
        // JSON que deserializa a string → buildNode devuelve '' (rama final)
        String filtersJson = '"justAString"';

        Test.startTest();
        List<Map<String, Object>> r = runSearch(
            'LKTest', filtersJson, new List<String>{'Id','Name'}
        );
        Test.stopTest();

        System.assert(r.size() >= 3, 'Non-list non-map JSON should be ignored');
    }

    @IsTest
    static void testAllInvalidLeavesInGroupSkipped() {
        String filtersJson = '[{"field":"","value":"x"},{"field":"Name","value":null}]';

        Test.startTest();
        List<Map<String, Object>> r = runSearch(
            'LKTest', filtersJson, new List<String>{'Id','Name'}
        );
        Test.stopTest();

        System.assert(r.size() >= 3, 'Group with all-invalid leaves should be ignored');
    }

    // ═══════════════════════════════════════════════════════════════════════
    // searchRecords — campos cross-object en returnFields
    // ═══════════════════════════════════════════════════════════════════════
    @IsTest
    static void testCrossObjectReturnField() {
        Test.startTest();
        List<Map<String, Object>> r = DMT_FormLookupController.searchRecords(
            'Local_Client__c',
            'LKTest LC Alpha',
            new List<String>{'Name'},
            null,
            new List<String>{'Id','Name','Cib_Client__r.Name','Cib_Client__r.Id'},
            'Name',
            20
        );
        Test.stopTest();

        System.assert(r.size() >= 1);
        // El campo cross-object debe estar presente en el row (puede ser null
        // si el Account no se resuelve, pero la key tiene que existir)
        System.assert(r[0].containsKey('Cib_Client__r.Name'),
            'Cross-object key should be present in row');
    }

    // ═══════════════════════════════════════════════════════════════════════
    // searchRecords — error de query SOQL (objeto válido por regex pero inexistente)
    // ═══════════════════════════════════════════════════════════════════════
    @IsTest
    static void testQueryErrorThrows() {
        Boolean threw = false;
        try {
            DMT_FormLookupController.searchRecords(
                'NonExistentObject__c',
                'test',
                new List<String>{'Name'},
                null,
                new List<String>{'Id','Name'},
                'Name',
                20
            );
        } catch (AuraHandledException e) {
            threw = true;
        }
        System.assert(threw, 'Should throw when SOQL query fails');
    }

    // ═══════════════════════════════════════════════════════════════════════
    // searchRecords — validaciones de parámetros requeridos
    // ═══════════════════════════════════════════════════════════════════════
    @IsTest
    static void testNullObjectNameThrows() {
        Boolean threw = false;
        try {
            DMT_FormLookupController.searchRecords(
                null, 'test', new List<String>{'Name'}, null,
                new List<String>{'Name'}, 'Name', 20
            );
        } catch (AuraHandledException e) { threw = true; }
        System.assert(threw);
    }

    @IsTest
    static void testBlankObjectNameThrows() {
        Boolean threw = false;
        try {
            DMT_FormLookupController.searchRecords(
                '   ', 'test', new List<String>{'Name'}, null,
                new List<String>{'Name'}, 'Name', 20
            );
        } catch (AuraHandledException e) { threw = true; }
        System.assert(threw);
    }

    @IsTest
    static void testNullSearchFieldsThrows() {
        Boolean threw = false;
        try {
            DMT_FormLookupController.searchRecords(
                'Local_Client__c', 'test', null, null,
                new List<String>{'Name'}, 'Name', 20
            );
        } catch (AuraHandledException e) { threw = true; }
        System.assert(threw);
    }

    @IsTest
    static void testEmptySearchFieldsThrows() {
        Boolean threw = false;
        try {
            DMT_FormLookupController.searchRecords(
                'Local_Client__c', 'test', new List<String>(), null,
                new List<String>{'Name'}, 'Name', 20
            );
        } catch (AuraHandledException e) { threw = true; }
        System.assert(threw);
    }

    @IsTest
    static void testNullReturnFieldsThrows() {
        Boolean threw = false;
        try {
            DMT_FormLookupController.searchRecords(
                'Local_Client__c', 'test', new List<String>{'Name'}, null,
                null, 'Name', 20
            );
        } catch (AuraHandledException e) { threw = true; }
        System.assert(threw);
    }

    @IsTest
    static void testEmptyReturnFieldsThrows() {
        Boolean threw = false;
        try {
            DMT_FormLookupController.searchRecords(
                'Local_Client__c', 'test', new List<String>{'Name'}, null,
                new List<String>(), 'Name', 20
            );
        } catch (AuraHandledException e) { threw = true; }
        System.assert(threw);
    }

    @IsTest
    static void testNullPrimaryFieldThrows() {
        Boolean threw = false;
        try {
            DMT_FormLookupController.searchRecords(
                'Local_Client__c', 'test', new List<String>{'Name'}, null,
                new List<String>{'Name'}, null, 20
            );
        } catch (AuraHandledException e) { threw = true; }
        System.assert(threw);
    }

    @IsTest
    static void testBlankPrimaryFieldThrows() {
        Boolean threw = false;
        try {
            DMT_FormLookupController.searchRecords(
                'Local_Client__c', 'test', new List<String>{'Name'}, null,
                new List<String>{'Name'}, '  ', 20
            );
        } catch (AuraHandledException e) { threw = true; }
        System.assert(threw);
    }

    // ═══════════════════════════════════════════════════════════════════════
    // searchRecords — validaciones contra inyección
    // ═══════════════════════════════════════════════════════════════════════
    @IsTest
    static void testInvalidObjectNameThrows() {
        Boolean threw = false;
        try {
            DMT_FormLookupController.searchRecords(
                'DROP TABLE--', '', new List<String>{'Name'}, null,
                new List<String>{'Id','Name'}, 'Name', 20
            );
        } catch (AuraHandledException e) { threw = true; }
        System.assert(threw);
    }

    @IsTest
    static void testInvalidSearchFieldThrows() {
        Boolean threw = false;
        try {
            DMT_FormLookupController.searchRecords(
                'Local_Client__c', 'test', new List<String>{'Name; DROP TABLE'},
                null, new List<String>{'Name'}, 'Name', 20
            );
        } catch (AuraHandledException e) { threw = true; }
        System.assert(threw);
    }

    @IsTest
    static void testInvalidReturnFieldThrows() {
        Boolean threw = false;
        try {
            DMT_FormLookupController.searchRecords(
                'Local_Client__c', 'test', new List<String>{'Name'}, null,
                new List<String>{'Name; DROP'}, 'Name', 20
            );
        } catch (AuraHandledException e) { threw = true; }
        System.assert(threw);
    }

    @IsTest
    static void testInvalidPrimaryFieldThrows() {
        Boolean threw = false;
        try {
            DMT_FormLookupController.searchRecords(
                'Local_Client__c', 'test', new List<String>{'Name'}, null,
                new List<String>{'Name'}, 'Name; DROP', 20
            );
        } catch (AuraHandledException e) { threw = true; }
        System.assert(threw);
    }

    @IsTest
    static void testFieldStartingWithDigitThrows() {
        Boolean threw = false;
        try {
            DMT_FormLookupController.searchRecords(
                'Local_Client__c', 'test', new List<String>{'1Field'},
                null, new List<String>{'Name'}, 'Name', 20
            );
        } catch (AuraHandledException e) { threw = true; }
        System.assert(threw, 'Field starting with digit should be rejected');
    }

    @IsTest
    static void testInvalidOperatorThrows() {
        Boolean threw = false;
        String filtersJson = JSON.serialize(new List<Map<String,Object>>{
            new Map<String,Object>{'field'=>'Name','operator'=>'DROP','value'=>'x'}
        });
        try {
            DMT_FormLookupController.searchRecords(
                'Local_Client__c', '', new List<String>{'Name'}, filtersJson,
                new List<String>{'Id','Name'}, 'Name', 20
            );
        } catch (AuraHandledException e) { threw = true; }
        System.assert(threw);
    }

    @IsTest
    static void testInvalidFieldInLeafThrows() {
        Boolean threw = false;
        String filtersJson = JSON.serialize(new List<Map<String,Object>>{
            new Map<String,Object>{'field'=>'Bad Field; DROP','operator'=>'=','value'=>'x'}
        });
        try {
            DMT_FormLookupController.searchRecords(
                'Local_Client__c', '', new List<String>{'Name'}, filtersJson,
                new List<String>{'Id','Name'}, 'Name', 20
            );
        } catch (AuraHandledException e) { threw = true; }
        System.assert(threw, 'Invalid field name in leaf should throw');
    }

    // ═══════════════════════════════════════════════════════════════════════
    // searchRecords — escape de comillas simples
    // ═══════════════════════════════════════════════════════════════════════
    @IsTest
    static void testSingleQuoteInSearchTermEscaped() {
        Test.startTest();
        List<Map<String, Object>> r = runSearch(
            'O\'Brien', null, new List<String>{'Id','Name'}
        );
        Test.stopTest();

        System.assertNotEquals(null, r);
    }

    @IsTest
    static void testSingleQuoteInFilterValueEscaped() {
        String filtersJson = JSON.serialize(new List<Map<String,Object>>{
            new Map<String,Object>{
                'field'=>'Name','operator'=>'=','value'=>'O\'Brien'
            }
        });

        Test.startTest();
        List<Map<String, Object>> r = runSearch(
            '', filtersJson, new List<String>{'Id','Name'}
        );
        Test.stopTest();

        System.assertNotEquals(null, r);
    }

    @IsTest
    static void testInOperatorWithSingleQuotes() {
        String filtersJson = JSON.serialize(new List<Map<String,Object>>{
            new Map<String,Object>{
                'field'=>'Name',
                'operator'=>'IN',
                'value'=>new List<String>{'O\'Brien','Test'}
            }
        });

        Test.startTest();
        List<Map<String, Object>> r = runSearch(
            '', filtersJson, new List<String>{'Id','Name'}
        );
        Test.stopTest();

        System.assertNotEquals(null, r);
    }

    // ═══════════════════════════════════════════════════════════════════════
    // getRecordLabel — éxito
    // ═══════════════════════════════════════════════════════════════════════
    @IsTest
    static void testGetRecordLabel_Success() {
        Local_Client__c lc = getLc('LKTest LC Alpha');

        Test.startTest();
        String label = DMT_FormLookupController.getRecordLabel(
            'Local_Client__c', lc.Id, 'Name'
        );
        Test.stopTest();

        System.assertEquals('LKTest LC Alpha', label);
    }

    @IsTest
    static void testGetRecordLabel_OtherField() {
        Local_Client__c lc = getLc('LKTest LC Alpha');

        Test.startTest();
        String label = DMT_FormLookupController.getRecordLabel(
            'Local_Client__c', lc.Id, 'Alpha_code__c'
        );
        Test.stopTest();

        System.assertEquals('ALPHA001', label);
    }

    // ═══════════════════════════════════════════════════════════════════════
    // getRecordLabel — record no encontrado
    // ═══════════════════════════════════════════════════════════════════════
    @IsTest
    static void testGetRecordLabel_RecordNotFound() {
        Local_Client__c lc = getLc('LKTest LC Alpha');

        // Buscamos el Id de Local_Client__c en Account → no existe
        Test.startTest();
        String label = DMT_FormLookupController.getRecordLabel(
            'Account', lc.Id, 'Id'
        );
        Test.stopTest();

        System.assertEquals(null, label, 'Should return null when record not found');
    }

    // ═══════════════════════════════════════════════════════════════════════
    // getRecordLabel — errores de validación
    // ═══════════════════════════════════════════════════════════════════════
    @IsTest
    static void testGetRecordLabel_NullObjectNameThrows() {
        Boolean threw = false;
        try {
            DMT_FormLookupController.getRecordLabel(null, 'someId', 'Name');
        } catch (AuraHandledException e) { threw = true; }
        System.assert(threw);
    }

    @IsTest
    static void testGetRecordLabel_BlankObjectNameThrows() {
        Boolean threw = false;
        try {
            DMT_FormLookupController.getRecordLabel('   ', 'someId', 'Name');
        } catch (AuraHandledException e) { threw = true; }
        System.assert(threw);
    }

    @IsTest
    static void testGetRecordLabel_NullRecordIdThrows() {
        Boolean threw = false;
        try {
            DMT_FormLookupController.getRecordLabel('Local_Client__c', null, 'Name');
        } catch (AuraHandledException e) { threw = true; }
        System.assert(threw);
    }

    @IsTest
    static void testGetRecordLabel_BlankRecordIdThrows() {
        Boolean threw = false;
        try {
            DMT_FormLookupController.getRecordLabel('Local_Client__c', '  ', 'Name');
        } catch (AuraHandledException e) { threw = true; }
        System.assert(threw);
    }

    @IsTest
    static void testGetRecordLabel_NullLabelFieldThrows() {
        Boolean threw = false;
        try {
            DMT_FormLookupController.getRecordLabel('Local_Client__c', 'someId', null);
        } catch (AuraHandledException e) { threw = true; }
        System.assert(threw);
    }

    @IsTest
    static void testGetRecordLabel_BlankLabelFieldThrows() {
        Boolean threw = false;
        try {
            DMT_FormLookupController.getRecordLabel('Local_Client__c', 'someId', '  ');
        } catch (AuraHandledException e) { threw = true; }
        System.assert(threw);
    }

    @IsTest
    static void testGetRecordLabel_InvalidObjectThrows() {
        Boolean threw = false;
        Local_Client__c lc = getLc('LKTest LC Alpha');
        try {
            DMT_FormLookupController.getRecordLabel(
                'DROP--TABLE', lc.Id, 'Name'
            );
        } catch (AuraHandledException e) { threw = true; }
        System.assert(threw);
    }

    @IsTest
    static void testGetRecordLabel_InvalidFieldThrows() {
        Boolean threw = false;
        Local_Client__c lc = getLc('LKTest LC Alpha');
        try {
            DMT_FormLookupController.getRecordLabel(
                'Local_Client__c', lc.Id, 'DROP--TABLE'
            );
        } catch (AuraHandledException e) { threw = true; }
        System.assert(threw);
    }

    @IsTest
    static void testGetRecordLabel_QueryErrorThrows() {
        Boolean threw = false;
        Local_Client__c lc = getLc('LKTest LC Alpha');
        try {
            DMT_FormLookupController.getRecordLabel(
                'NonExistentObject__c', lc.Id, 'Name'
            );
        } catch (AuraHandledException e) { threw = true; }
        System.assert(threw, 'Should throw when SOQL fails in getRecordLabel');
    }
}