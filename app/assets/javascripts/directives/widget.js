app.directive("widget", ["$compile", function($compile) {

  var linkFn = function(scope, element, attrs, gridsterController) {
    gridsterController.add(element, scope.widget);

    var elm = element.find(".widget-content");
    elm.attr(scope.widget.kind.replace("_", "-"), "");

    $compile(elm)(scope);

    element.bind("$destroy", function() {
      gridsterController.remove(element);
    });

    scope.$watch("widget.size_x", function(newValue, oldValue) {
      if (newValue === oldValue) return;
      gridsterController.resize(element, newValue, scope.widget.size_y);
    }, true);

    scope.$watch("widget.size_y", function(newValue, oldValue) {
      if (newValue === oldValue) return;
      gridsterController.resize(element, scope.widget.size_x, newValue);
    }, true);
  };

  return {
    require: "^gridster",
    controller: "WidgetCtrl",
    link: linkFn
  };
}]);