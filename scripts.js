$(function() {
  registerToggle("sleep");
  registerToggle("bottle");
  registerToggle("diaper");
  registerToggle("nurse");
});

function registerToggle(cssClass) {
  var idSelector = "#" + cssClass + "Toggle";
  var classSelector = "." + cssClass + ".event";

  $(idSelector).click(function() {
    $(classSelector).fadeToggle();
  });
}
