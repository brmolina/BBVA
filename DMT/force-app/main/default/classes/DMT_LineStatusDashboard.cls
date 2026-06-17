public with sharing class DMT_LineStatusDashboard {

    private static final List<String> ORDERED_STATES = new List<String>{
        'Draft', 'Proposal', 'Approval', 'Ready to close', 'Closed'
    };

    public class FilterRequest {
        @AuraEnabled public Date startDate;
        @AuraEnabled public Date endDate;
        @AuraEnabled public String lineTemplate;
        @AuraEnabled public String bookingGeography;
    }

    public class FilterOptionResponse {
        @AuraEnabled public List<String> lineTemplates;
        @AuraEnabled public List<String> bookingGeographies;
    }

    public class StateMetric {
        @AuraEnabled public String state;
        @AuraEnabled public Decimal totalHours;
        @AuraEnabled public Decimal avgHours;
        @AuraEnabled public Integer recordCount;

        public StateMetric(String state) {
            this.state = state;
            this.totalHours = 0;
            this.avgHours = 0;
            this.recordCount = 0;
        }
    }

    public class DashboardResponse {
        @AuraEnabled public Integer totalRecords;
        @AuraEnabled public Decimal avgLifecycleHours;
        @AuraEnabled public String longestState;
        @AuraEnabled public List<String> labels;
        @AuraEnabled public List<Decimal> avgHoursPerState;
        @AuraEnabled public List<StateMetric> metrics;
    }

    public class HistoryTransition {
        public Id parentId;
        public Datetime changedAt;
        public String oldValue;
        public String newValue;

        public HistoryTransition(Id parentId, Datetime changedAt, String oldValue, String newValue) {
            this.parentId = parentId;
            this.changedAt = changedAt;
            this.oldValue = oldValue;
            this.newValue = newValue;
        }
    }

    public class LineSnapshot {
        public Id lineId;
        public Datetime createdDate;
        public String currentStatus;

        public LineSnapshot(Id lineId, Datetime createdDate, String currentStatus) {
            this.lineId = lineId;
            this.createdDate = createdDate;
            this.currentStatus = currentStatus;
        }
    }

    @AuraEnabled(cacheable=false)
    public static FilterOptionResponse getFilterOptions() {
        FilterOptionResponse res = new FilterOptionResponse();
        res.lineTemplates = new List<String>();
        res.bookingGeographies = new List<String>();

        for (AggregateResult ar : [
            SELECT RecordType.Name valueField
            FROM DMT_Line__c
            WHERE RecordType.Name != null
            GROUP BY RecordType.Name
            ORDER BY RecordType.Name
        ]) {
            res.lineTemplates.add((String) ar.get('valueField'));
        }

        for (AggregateResult ar : [
            SELECT Booking_Geography__c valueField
            FROM DMT_Line__c
            WHERE Booking_Geography__c != null
            GROUP BY Booking_Geography__c
            ORDER BY Booking_Geography__c
        ]) {
            res.bookingGeographies.add((String) ar.get('valueField'));
        }

        return res;
    }

    @AuraEnabled(cacheable=true)
    public static DashboardResponse getDashboardData(FilterRequest filters) {
        if (filters == null) {
            filters = new FilterRequest();
        }

        List<String> whereClauses = new List<String>();
        whereClauses.add('Id != null');

        if (filters.startDate != null) {
            whereClauses.add('CreatedDate >= :DateTime.newInstance(filters.startDate, Time.newInstance(0, 0, 0, 0))');
        }
        if (filters.endDate != null) {
            whereClauses.add('CreatedDate <= :DateTime.newInstance(filters.endDate, Time.newInstance(23, 59, 59, 999))');
        }
        if (String.isNotBlank(filters.lineTemplate)) {
            whereClauses.add('RecordType.Name = :filters.lineTemplate');
        }
        if (String.isNotBlank(filters.bookingGeography)) {
            whereClauses.add('Booking_Geography__c = :filters.bookingGeography');
        }

        String soql =
            'SELECT Id, CreatedDate, Status__c ' +
            'FROM DMT_Line__c ' +
            'WHERE ' + String.join(whereClauses, ' AND ');

        List<DMT_Line__c> lines = Database.query(soql);

        Map<Id, LineSnapshot> snapshotsById = new Map<Id, LineSnapshot>();
        Set<Id> lineIds = new Set<Id>();

        for (DMT_Line__c line : lines) {
            lineIds.add(line.Id);
            snapshotsById.put(
                line.Id,
                new LineSnapshot(
                    line.Id,
                    line.CreatedDate,
                    (String) line.get('Status__c')
                )
            );
        }

        Map<Id, List<HistoryTransition>> historyByParentId = new Map<Id, List<HistoryTransition>>();

        if (!lineIds.isEmpty()) {
            for (DMT_Line__History hist : [
                SELECT ParentId, CreatedDate, Field, OldValue, NewValue
                FROM DMT_Line__History
                WHERE ParentId IN :lineIds
                  AND Field = 'Status__c'
                ORDER BY ParentId, CreatedDate
            ]) {
                if (!historyByParentId.containsKey(hist.ParentId)) {
                    historyByParentId.put(hist.ParentId, new List<HistoryTransition>());
                }

                historyByParentId.get(hist.ParentId).add(
                    new HistoryTransition(
                        hist.ParentId,
                        hist.CreatedDate,
                        hist.OldValue == null ? null : String.valueOf(hist.OldValue),
                        hist.NewValue == null ? null : String.valueOf(hist.NewValue)
                    )
                );
            }
        }

        return buildDashboardResponse(snapshotsById, historyByParentId);
    }

    @TestVisible
    private static DashboardResponse buildDashboardResponse(
        Map<Id, LineSnapshot> snapshotsById,
        Map<Id, List<HistoryTransition>> historyByParentId
    ) {
        Map<String, Decimal> totalHoursByState = new Map<String, Decimal>();
        Map<String, Integer> countByState = new Map<String, Integer>();
        Decimal totalLifecycleHours = 0;

        for (String stateName : ORDERED_STATES) {
            totalHoursByState.put(stateName, 0);
            countByState.put(stateName, 0);
        }

        for (Id lineId : snapshotsById.keySet()) {
            LineSnapshot snap = snapshotsById.get(lineId);
            List<HistoryTransition> transitions = historyByParentId.containsKey(lineId)
                ? historyByParentId.get(lineId)
                : new List<HistoryTransition>();

            Map<String, Decimal> durations = calculateDurationsForLine(snap, transitions);

            Decimal lineTotal = 0;

            for (String stateName : ORDERED_STATES) {
                Decimal hours = durations.containsKey(stateName) ? durations.get(stateName) : 0;
                totalHoursByState.put(stateName, totalHoursByState.get(stateName) + hours);
                lineTotal += hours;

                if (hours > 0) {
                    countByState.put(stateName, countByState.get(stateName) + 1);
                }
            }

            totalLifecycleHours += lineTotal;
        }

        DashboardResponse response = new DashboardResponse();
        response.totalRecords = snapshotsById.size();
        response.avgLifecycleHours = response.totalRecords > 0
            ? (totalLifecycleHours / response.totalRecords).setScale(2)
            : 0;
        response.labels = new List<String>();
        response.avgHoursPerState = new List<Decimal>();
        response.metrics = new List<StateMetric>();

        Decimal maxAvg = -1;
        String longestStateName = null;

        for (String stateName : ORDERED_STATES) {
            Decimal total = totalHoursByState.get(stateName);
            Integer count = countByState.get(stateName);
            Decimal avg = count > 0 ? (total / count).setScale(2) : 0;

            StateMetric metric = new StateMetric(stateName);
            metric.totalHours = total.setScale(2);
            metric.avgHours = avg;
            metric.recordCount = count;

            response.labels.add(stateName);
            response.avgHoursPerState.add(avg);
            response.metrics.add(metric);

            if (avg > maxAvg) {
                maxAvg = avg;
                longestStateName = stateName;
            }
        }

        response.longestState = longestStateName;
        return response;
    }

    @TestVisible
    private static Map<String, Decimal> calculateDurationsForLine(
        LineSnapshot snap,
        List<HistoryTransition> transitions
    ) {
        Map<String, Decimal> durations = new Map<String, Decimal>();
        for (String stateName : ORDERED_STATES) {
            durations.put(stateName, 0);
        }

        if (snap == null || snap.createdDate == null) {
            return durations;
        }

        if (transitions == null || transitions.isEmpty()) {
            if (snap.currentStatus == 'Closed') {
                durations.put('Closed', hoursBetween(snap.createdDate, System.now()));
            }
            return durations;
        }

        String currentState = transitions[0].oldValue;
        if (String.isBlank(currentState)) {
            currentState = transitions[0].newValue;
        }

        Datetime segmentStart = snap.createdDate;

        for (HistoryTransition transition : transitions) {
            if (!String.isBlank(currentState)
                && ORDERED_STATES.contains(currentState)
                && transition.changedAt.getTime() > segmentStart.getTime()) {
                durations.put(
                    currentState,
                    durations.get(currentState) + hoursBetween(segmentStart, transition.changedAt)
                );
            }

            currentState = transition.newValue;
            segmentStart = transition.changedAt;
        }

        if (currentState == 'Closed' && System.now().getTime() > segmentStart.getTime()) {
            durations.put(
                'Closed',
                durations.get('Closed') + hoursBetween(segmentStart, System.now())
            );
        }

        return durations;
    }

    @TestVisible
    private static Decimal hoursBetween(Datetime startDt, Datetime endDt) {
        Long ms = endDt.getTime() - startDt.getTime();
        if (ms <= 0) {
            return 0;
        }
        return ((Decimal) ms) / 3600000;
    }
}