public interface DMT_ViewRenderer {
    String renderHtml(DMT_ViewController.LineDataWrapper data);
    Map<String, Object> renderPdfJson(DMT_ViewController.LineDataWrapper data);
}