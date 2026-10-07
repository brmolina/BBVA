@IsTest
private class DMT_FormLookupControllerTest {

    // ═══════════════════════════════════════════════════════════════════════
    // Setup — 3 Account con datos variados.
    // Se reutiliza generateAccount() para satisfacer los campos requeridos.
    // pesadas de Account/Opportunity. Es además el objeto que el JS usa
    // realmente para el lookup.
    // ═══════════════════════════════════════════════════════════════════════
    @TestSetup
    static void setupTestData() {
        Account acc = DMT_Test_DataFactory.generateAccount();
        acc.Name = 'LKTest LC Alpha';
        acc.g_customer_id__c = 'ALPHA001';
        acc.BillingCity = 'ALPHA001';
        update acc;

         Account acc2 = new Account(
            Name = 'LKTest LC Beta',
            account_client__c = 'N',
            Advising__c = false,
            BBVA_Entity__c = 'BBVA SA',
            BillingCity = 'BETA002',
            BillingCountry = 'ES',
            BillingPostalCode = '28033',
            BillingState = 'MADRID',
            BillingStreet = 'AV GRAN Test DE HORTALEZA 0321',
            CurrencyIsoCode = 'EUR',
            DES_Activity__c = 'NDA',
            g_customer_id__c = 'BETA002'
        );
        Account acc3 = new Account(
            Name = 'LKTest LC Gamma',
            account_client__c = 'N',
            Advising__c = false,
            BBVA_Entity__c = 'BBVA SA',
            BillingCity = 'GAMMA003',
            BillingCountry = 'ES',
            BillingPostalCode = '28033',
            BillingState = 'MADRID',
            BillingStreet = 'AV GRAN Test DE HORTALEZA 0321',
            CurrencyIsoCode = 'EUR',
            DES_Activity__c = 'NDA',
            g_customer_id__c = 'GAMMA003'
        );
        insert new List<Account>{ acc2, acc3 };
    }

    // ─────────────────────────────────────────────────────────────────────
    // Helpers
    // ─────────────────────────────────────────────────────────────────────
    private static Account getAcc(String name) {
        return [SELECT Id, Name, g_customer_id__c
                FROM Account WHERE Name = :name LIMIT 1];
    }

    private static void setAccountSearchResults() {
        List<Account> accounts = [
            SELECT Id
            FROM Account
            WHERE Name = 'LKTest LC Alpha'
                OR Name = 'LKTest LC Beta'
                OR Name = 'LKTest LC Gamma'
        ];
        List<Id> accountIds = new List<Id>();
        for (Account account : accounts) {
            accountIds.add(account.Id);
        }
        Test.setFixedSearchResults(accountIds);
    }

    private static List<Map<String, Object>> runSearch(
        String term, String filtersJson, List<String> returnFields
    ) {
        setAccountSearchResults();

        return DMT_FormLookupController.searchRecords(
            'Account',
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
                'field'=>'BillingCity','operator'=>'=','value'=>'BETA002'
            }
        });

        Test.startTest();
        List<Map<String, Object>> r = runSearch(
            'LKTest', filtersJson, new List<String>{'Id','Name','g_customer_id__c'}
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
                    'field'=>'BillingCity','operator'=>'LIKE','value'=>'%A%'
                },
                new Map<String,Object>{
                    'OR' => new List<Object>{
                        new Map<String,Object>{
                            'field'=>'BillingCity','operator'=>'=','value'=>'BETA002'
                        },
                        new Map<String,Object>{
                            'field'=>'BillingCity','operator'=>'=','value'=>'GAMMA003'
                        }
                    }
                }
            }
        };

        Test.startTest();
        List<Map<String, Object>> r = runSearch(
            'LKTest',
            JSON.serialize(filtersMap),
            new List<String>{'Id','Name','g_customer_id__c'}
        );
        Test.stopTest();

        System.assert(containsName(r, 'LKTest LC Beta'), 'Should contain Beta');
        System.assert(containsName(r, 'LKTest LC Gamma'), 'Should contain Gamma');
    }

    // ═══════════════════════════════════════════════════════════════════════
    // searchRecords — operadores < <= > >= sobre un campo no cifrado
    // ═══════════════════════════════════════════════════════════════════════
    @IsTest
    static void testGreaterThanOperator() {
        String filtersJson = JSON.serialize(new List<Map<String,Object>>{
            new Map<String,Object>{
                'field'=>'BillingCity','operator'=>'>','value'=>'BETA999'
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
                'field'=>'BillingCity','operator'=>'>=','value'=>'ALPHA001'
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
                'field'=>'BillingCity','operator'=>'<','value'=>'BETA999'
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
                'field'=>'BillingCity','operator'=>'<=','value'=>'BETA002'
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
                'field' => 'BillingCity',
                'operator' => 'IN',
                'value' => new List<String>{'ALPHA001','BETA002','GAMMA003'}
            }
        });

        Test.startTest();
        List<Map<String, Object>> r = runSearch(
            'LKTest', filtersJson, new List<String>{'Id','Name','g_customer_id__c'}
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
                'field'=>'BillingCity','value'=>'GAMMA%'
            }
        });

        Test.startTest();
        List<Map<String, Object>> r = runSearch(
            'LKTest', filtersJson, new List<String>{'Id','Name','g_customer_id__c'}
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
            'Account', '', new List<String>{'Name'}, null,
            new List<String>{'Id','Name'}, 'Name', 99
        );
        Test.stopTest();

        System.assert(r.size() <= 20, 'Result should be capped at 20');
    }

    @IsTest
    static void testNullLimitUsesDefault() {
        Test.startTest();
        List<Map<String, Object>> r = DMT_FormLookupController.searchRecords(
            'Account', 'LKTest', new List<String>{'Name'}, null,
            new List<String>{'Id','Name'}, 'Name', null
        );
        Test.stopTest();

        System.assert(r.size() <= 20);
    }

    @IsTest
    static void testZeroLimitUsesDefault() {
        Test.startTest();
        List<Map<String, Object>> r = DMT_FormLookupController.searchRecords(
            'Account', 'LKTest', new List<String>{'Name'}, null,
            new List<String>{'Id','Name'}, 'Name', 0
        );
        Test.stopTest();

        System.assert(r.size() <= 20);
    }

    @IsTest
    static void testNegativeLimitUsesDefault() {
        Test.startTest();
        List<Map<String, Object>> r = DMT_FormLookupController.searchRecords(
            'Account', 'LKTest', new List<String>{'Name'}, null,
            new List<String>{'Id','Name'}, 'Name', -5
        );
        Test.stopTest();

        System.assert(r.size() <= 20, 'Negative limit should fall back to default');
    }

    @IsTest
    static void testCustomLimitUnderMax() {
        Test.startTest();
        List<Map<String, Object>> r = DMT_FormLookupController.searchRecords(
            'Account', 'LKTest', new List<String>{'Name'}, null,
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
                'field'=>'BillingCity','operator'=>'!=','value'=>'BETA002'
            }
        });

        Test.startTest();
        List<Map<String, Object>> r = runSearch(
            'LKTest', filtersJson, new List<String>{'Id','Name','g_customer_id__c'}
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
                'field'=>'BillingCity','operator'=>'LIKE','value'=>'%%'
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
                'field'=>'BillingCity','operator'=>'LIKE','value'=>'___'
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
                'field'=>'BillingCity','operator'=>'LIKE','value'=>'BETA%'
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
                    'field'=>'BillingCity','operator'=>'=','value'=>'ALPHA001'
                }
            }
        };

        Test.startTest();
        List<Map<String, Object>> r = runSearch(
            'LKTest',
            JSON.serialize(filtersMap),
            new List<String>{'Id','Name','g_customer_id__c'}
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
                    'field'=>'BillingCity','operator'=>'=','value'=>'ALPHA001'
                },
                new Map<String,Object>{
                    'field'=>'BillingCity','operator'=>'=','value'=>'GAMMA003'
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
        String filtersJson = '[{"field":"g_customer_id__c","operator":"=","value":null}]';

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
        setAccountSearchResults();

        Test.startTest();
        List<Map<String, Object>> r = DMT_FormLookupController.searchRecords(
            'Account',
            'LKTest LC Alpha',
            new List<String>{'Name'},
            null,
           new List<String>{'Id','Name','Owner.Name','Owner.Id'},
            'Name',
            20
        );
        Test.stopTest();

        System.assert(r.size() >= 1);
        // El campo cross-object debe estar presente en el row (puede ser null
        // si el Owner no se resuelve, pero la key tiene que existir)
        System.assert(r[0].containsKey('Owner.Name'),
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
                'Account', 'test', null, null,
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
                'Account', 'test', new List<String>(), null,
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
                'Account', 'test', new List<String>{'Name'}, null,
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
                'Account', 'test', new List<String>{'Name'}, null,
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
                'Account', 'test', new List<String>{'Name'}, null,
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
                'Account', 'test', new List<String>{'Name'}, null,
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
                'Account', 'test', new List<String>{'Name; DROP TABLE'},
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
                'Account', 'test', new List<String>{'Name'}, null,
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
                'Account', 'test', new List<String>{'Name'}, null,
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
                'Account', 'test', new List<String>{'1Field'},
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
                'Account', '', new List<String>{'Name'}, filtersJson,
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
                'Account', '', new List<String>{'Name'}, filtersJson,
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
        Account acc = getAcc('LKTest LC Alpha');

        Test.startTest();
        String label = DMT_FormLookupController.getRecordLabel(
            'Account', acc.Id, 'Name'
        );
        Test.stopTest();

        System.assertEquals('LKTest LC Alpha', label);
    }

    @IsTest
    static void testGetRecordLabel_OtherField() {
        Account acc = getAcc('LKTest LC Alpha');

        Test.startTest();
        String label = DMT_FormLookupController.getRecordLabel(
            'Account', acc.Id, 'g_customer_id__c'
        );
        Test.stopTest();

        System.assertEquals('ALPHA001', label);
    }

    // ═══════════════════════════════════════════════════════════════════════
    // getRecordLabel — record no encontrado
    // ═══════════════════════════════════════════════════════════════════════
    @IsTest
    static void testGetRecordLabel_RecordNotFound() {
        Account acc = getAcc('LKTest LC Alpha');

        // Buscamos el Id del Account en Opportunity → no existe
        Test.startTest();
        String label = DMT_FormLookupController.getRecordLabel(
            'Opportunity', acc.Id, 'Id'
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
            DMT_FormLookupController.getRecordLabel('Account', null, 'Name');
        } catch (AuraHandledException e) { threw = true; }
        System.assert(threw);
    }

    @IsTest
    static void testGetRecordLabel_BlankRecordIdThrows() {
        Boolean threw = false;
        try {
            DMT_FormLookupController.getRecordLabel('Account', '  ', 'Name');
        } catch (AuraHandledException e) { threw = true; }
        System.assert(threw);
    }

    @IsTest
    static void testGetRecordLabel_NullLabelFieldThrows() {
        Boolean threw = false;
        try {
            DMT_FormLookupController.getRecordLabel('Account', 'someId', null);
        } catch (AuraHandledException e) { threw = true; }
        System.assert(threw);
    }

    @IsTest
    static void testGetRecordLabel_BlankLabelFieldThrows() {
        Boolean threw = false;
        try {
            DMT_FormLookupController.getRecordLabel('Account', 'someId', '  ');
        } catch (AuraHandledException e) { threw = true; }
        System.assert(threw);
    }

     @IsTest
    static void testGetRecordLabel_InvalidObjectThrows() {
        Boolean threw = false;
        Account acc = getAcc('LKTest LC Alpha');
        try {
            DMT_FormLookupController.getRecordLabel(
                'DROP--TABLE', acc.Id, 'Name'
            );
        } catch (AuraHandledException e) { threw = true; }
        System.assert(threw);
    }

    @IsTest
    static void testGetRecordLabel_InvalidFieldThrows() {
        Boolean threw = false;
        Account acc = getAcc('LKTest LC Alpha');
        try {
            DMT_FormLookupController.getRecordLabel(
                'Account', acc.Id, 'DROP--TABLE'
            );
        } catch (AuraHandledException e) { threw = true; }
        System.assert(threw);
    }

    @IsTest
    static void testGetRecordLabel_QueryErrorThrows() {
        Boolean threw = false;
        Account acc = getAcc('LKTest LC Alpha');
        try {
            DMT_FormLookupController.getRecordLabel(
                'NonExistentObject__c', acc.Id, 'Name'
            );
        } catch (AuraHandledException e) { threw = true; }
        System.assert(threw, 'Should throw when SOQL fails in getRecordLabel');
    }
}