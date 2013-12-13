app.directive("minavemax", ["MinavemaxModel", "SuffixFormatter", function(MinavemaxModel, SuffixFormatter) {

  var linkFn = function(scope, element, attrs) {
    // console.log(element.html(), attrs)

    function calculatePercentage(value, previousValue) {
      console.log("previous", previousValue, "value", value);
      return ((value - previousValue) / value) * 100;
    }

    function massageValue(value, scope) {
      if(value > 10) { value = Math.round(value); } // We want to see fractions for small numbers
      stringValue = scope.widget.use_metric_suffix ? SuffixFormatter.format(value, 1) : value.toString();
      return stringValue
    }

    function onSuccess(data) {
      scope.data = data;
      scope.data.label = scope.data.label || scope.widget.label;

      scope.data.totValue = massageValue(scope.data.total, scope);
      scope.data.minValue = massageValue(scope.data.min, scope);
      scope.data.aveValue = massageValue(scope.data.ave, scope);
      scope.data.maxValue = massageValue(scope.data.max, scope);
    }

    function update() {
      return MinavemaxModel.getData(scope.widget).success(onSuccess);
    }

    scope.init(update);
  };

  return {
    templateUrl: "templates/widgets/minavemax/show.html",
    link: linkFn
  };
}]);
