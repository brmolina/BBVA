global with sharing class DES_sch_RunAllTestsScheduler implements Schedulable {
    // Configura tus emails destino aquí o léelos de Custom Metadata
    public static final List<String> RECIPIENTS = new List<String>{ Label.EmailService_LogAnalizer_ToAddress };
    public static final Boolean SKIP_COVERAGE = true; // más rápido; pon false si quieres cobertura

    global void execute(SchedulableContext sc) {
        // 1) Lanzar la ejecución de tests
        System.enqueueJob(new DES_cls_ToolingApiCalloutQueueable(SKIP_COVERAGE));
    }

    public static void scheduleOneTimePoll(String runId, Datetime cr, Integer attempt) {
        String cron = cronAt(cr);
        String jobName = 'PollApexRun_' + runId + '_' + attempt;
        System.schedule(jobName, cron, new DES_cls_ApexRunPoller(runId, attempt));
    }

    private static String cronAt(Datetime dt) {
        // sec min hour day month ? year
        return String.format('{0} {1} {2} {3} {4} ? {5}',
            new List<String>{
                String.valueOf(dt.second()),
                String.valueOf(dt.minute()),
                String.valueOf(dt.hour()),
                String.valueOf(dt.day()),
                String.valueOf(dt.month()),
                String.valueOf(dt.year())
            }
        );
    }

    // Llama a esto una vez para programar la hora diaria/semana que quieras
    public static void scheduleDaily(Integer hour24, Integer minute) {
        String cron = '0 ' + minute + ' ' + hour24 + ' * * ?';
        System.schedule('RunAllTestsDaily', cron, new DES_sch_RunAllTestsScheduler());
    }
}