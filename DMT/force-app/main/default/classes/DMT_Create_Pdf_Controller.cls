public with sharing class DMT_Create_Pdf_Controller {

    public static Map<String, Object> createListText(List<String> name, List<String> value, String column ){
        Map<String, Object> textData = new Map<String, Object>();
        List<Map<String, Object>> textListOne = new List<Map<String, Object>>();
        List<Map<String, Object>> textListTwo = new List<Map<String, Object>>();
        List<List<Map<String, Object>>> liststextList = new List<List<Map<String, Object>>>();

        if(column == 'ONE'){
            for (Integer i = 0; i < name.size(); i++) {
                Map<String, Object> textItemOne = new Map<String, Object>();
                    textItemOne.put('name', name[i]);
                    textItemOne.put('value', value[i]);
                    textListOne .add(textItemOne);
            }
            Map<String, Object> margin = new Map<String, Object>();
            margin.put('bottom',10);
            margin.put('top',10);
            liststextList.add(textListOne);
            textData.put('margin', margin);
        }else{
            Integer half = Math.MOD(name.size(),2) == 0 ? name.size()/2 : (name.size()/2) + 1;
            for (Integer i = 0; i < name.size(); i++) {
                Map<String, Object> textItemOne = new Map<String, Object>();
                if(i<half){
                    textItemOne.put('name', name[i]);
                    textItemOne.put('value', value[i]);
                    textListOne .add(textItemOne);
                }else{
                    Map<String, Object> textItemTwo = new Map<String, Object>();
                    textItemTwo.put('name', name[i]);
                    textItemTwo.put('value', value[i]);
                    textListTwo.add(textItemTwo);
                }
            }
            Map<String, Object> margin = new Map<String, Object>();
            margin.put('bottom',5);
            margin.put('top',0);
            liststextList.add(textListOne);
            liststextList.add(textListTwo);
            textData.put('margin', margin);
        }

        Map<String, Object> style = new Map<String, Object>();
        style.put('fontSize', 10);
        textData.put('style', style);

        textData.put('body', liststextList);
        textData.put('type', 'values2');

        return textData;
    }
    public static List<Object> createTitleSection(String title){
        //Create Seccion Title
        List<Object> contentListTableSection = new List<Object>();
        Map<String, Object> componentTableSection = new Map<String, Object>();

        Map<String, Object> itemSection = new Map<String, Object>();
        Map<String, Object> stylesSection  = new Map<String, Object>();
            stylesSection .put('nobreak', true);
            stylesSection .put('fillColor', '#F2F2F2');
            stylesSection .put('drawColor', 'F2F2F2');
            Map<String, Object> marginSection = new Map<String, Object>();
            marginSection.put('bottom',1);
            marginSection.put('top',1);
            itemSection.put('margin', marginSection);
            itemSection.put('style', stylesSection);
            itemSection.put('height', 8);
            itemSection.put('width', 'content');
            itemSection.put('type', 'rect');

        Map<String, Object> tableSection = new Map<String, Object>();
            tableSection.put('align', 'center');
        Map<String, Object> marginTitleSection = new Map<String, Object>();
            marginTitleSection.put('bottom',3);
            marginTitleSection.put('top',3);
            tableSection.put('margin',marginTitleSection);
            tableSection.put('text', title);
            tableSection.put('type', 'title');

        contentListTableSection.add(itemSection);
        contentListTableSection.add(tableSection);
        return contentListTableSection;
    }
    public static Map<String, Object> createTitle(String title){
        // CREATE TITLE
        Map<String, Object> titleComponent = new Map<String, Object>();
        Map<String, Object> margin = new Map<String, Object>();
            margin.put('bottom',3);
            margin.put('top', 5);
        Map<String, Object> styleText = new Map<String, Object>();
            styleText.put('fontSize', 13);
            styleText.put('nobreak', false);
            titleComponent.put('style', styleText);
            titleComponent.put('margin', margin);
            titleComponent.put('text', title);
            titleComponent.put('type', 'title');

        return titleComponent;
    }

    public static Map<String, Object> createTable(List<List<String>> head, List<List<String>> body) {
        Map<String, Object> table = new Map<String, Object>();
        Map<String, Object> stylesTable = new Map<String, Object>{'fontSize' => 8};
        Map<String, Object> marginTable = new Map<String, Object>{'top' => 0, 'bottom' => 1};
        Map<String, Object> lineWidthItem = new Map<String, Object>{'bottom' => 0.1};
        stylesTable.put('lineWidth', lineWidthItem);
        Map<String, Object> headStyles = new Map<String, Object>{'fontSize' => 8};
        table.put('headStyles', headStyles);
        table.put('style', stylesTable);
        table.put('margin', marginTable);
        table.put('body', body);
        table.put('head', head);
        table.put('type', 'table');
        return table;
    }

    public static Map<String, Object> createStyledTableObj(List<List<Object>> head, List<List<Object>> body, List<String> values, List<String> totals, List<String> totalsDarker) {
        return createStyledTableObj(head, body, values, totals, totalsDarker, new List<Integer>(), new List<Integer>());
    }

    public static Map<String, Object> createStyledTableObj(List<List<Object>> head, List<List<Object>> body, List<String> values, List<String> totals, List<String> totalsDarker, List<Integer> totalsColors, List<Integer> totalsDarkerColors) {
        // Header styling: dark blue, white, bold, font size 10
        List<List<Object>> styledHead = new List<List<Object>>();
        for (List<Object> row : head) {
            List<Object> styledRow = new List<Object>();
            for (Object cell : row) {
                if (cell instanceof Map<String, Object>) {
                    // Use the provided content and styles
                    Map<String, Object> cellMap = (Map<String, Object>)cell;
                    styledRow.add(
                        new Map<String, Object>{
                            'content' => cellMap.get('content'),
                            'styles' => (Map<String, Object>)cellMap.get('styles')
                        }
                    );
                } else {
                    // Use default header style
                    styledRow.add(
                        new Map<String, Object>{
                            'content' => cell,
                            'styles' => new Map<String, Object>{
                                'fillColor' => new List<Integer>{0,68,119}, // #004477
                                'textColor' => new List<Integer>{255,255,255},
                                'fontStyle' => 'bold',
                                'fontSize' => 9
                            }
                        }
                    );
                }
            }
            styledHead.add(styledRow);
        }

        // Body styling
        List<List<Object>> styledBody = new List<List<Object>>();
        for (Integer i = 0; i < body.size(); i++) {
            List<Object> row = body[i];
            String apiName = values[i];
            Map<String, Object> styles;
            List<Integer> totalsColorsAssigned = (totalsColors.isEmpty()? new List<Integer>{91,190,255} : totalsColors); // #5BBEFF
            List<Integer> totalsDarkerColorsAssigned = (totalsDarkerColors.isEmpty()? new List<Integer>{20,100,165} : totalsDarkerColors); // #1464A5
            if (totals != null && totals.contains(apiName)) {
                styles = new Map<String, Object>{
                    'fillColor' => totalsColorsAssigned,
                    'textColor' => new List<Integer>{255,255,255},
                    'fontStyle' => 'bold',
                    'fontSize' => 10
                };
            } else if (totalsDarker != null && totalsDarker.contains(apiName)) {
                styles = new Map<String, Object>{
                    'fillColor' => totalsDarkerColorsAssigned,
                    'textColor' => new List<Integer>{255,255,255},
                    'fontStyle' => 'bold',
                    'fontSize' => 10
                };
            } else {
                styles = new Map<String, Object>{
                    'fillColor' => new List<Integer>{255,255,255},
                    'textColor' => new List<Integer>{0,0,0},
                    'fontStyle' => 'normal',
                    'fontSize' => 9
                };
            }
            List<Object> styledRow = new List<Object>();
            for (Object cell : row) {
                styledRow.add(
                    new Map<String, Object>{
                        'content' => cell,
                        'styles' => styles
                    }
                );
            }
            styledBody.add(styledRow);
        }

        return createTableObj(styledHead, styledBody);
    }

    public static Map<String, Object> createTableObj(List<List<Object>> head, List<List<Object>> body) {
        Map<String, Object> table = new Map<String, Object>();
        Map<String, Object> stylesTable = new Map<String, Object>{'fontSize'=>8};
        Map<String, Object> marginTable = new Map<String, Object>{'top'=>0,'bottom'=>1};
        Map<String, Object> headStyles = new Map<String, Object>{'fontSize'=>8,'fontStyle'=>'bold'};
        // set border widths to 0 (no visible lines)
        stylesTable.put('lineWidth', new Map<String,Object>{'top'=>0,'bottom'=>0,'left'=>0,'right'=>0});
        stylesTable.put('tableLineWidth', 0);
        table.put('headStyles', headStyles);
        table.put('style', stylesTable);
        table.put('margin', marginTable);
        table.put('body', body);
        table.put('head', head);
        table.put('type','table');
        return table;
    }
}