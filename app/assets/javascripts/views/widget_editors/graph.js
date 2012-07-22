(function ($, _, Backbone, views, models, collections) {
  "use strict";

  views.WidgetEditors.Graph = Backbone.View.extend({

    events: {
      "change #source"     : "sourceChanged"
    },

    initialize: function() {
      _.bindAll(this, "render", "sourceChanged");

      // TODO: why is graph.js setting the source of metrics collection?
      collections.metrics.source = this.model.get('source') || $.Sources.getDefaultTarget();
    },

    render: function() {
      this.form = new Backbone.Form({
        data  : this.model.toJSON(),
        schema: this.getSchema()
      });
      this.$el.html(this.form.render().el);

      this.$targetInput = this.$('input#targets');
      this.$targetInputField = this.$('.field-targets');
      this.$sourceSelect = this.$('select#source');
      this.$httpProxyUrlField = this.$(".field-http_proxy_url");

      this.sourceChanged();

      return this;
    },

    validate: function() {
      return this.form.validate();
    },

    getValue: function() {
      return this.form.getValue();
    },

    getSources: function() {
      var sources = $.Sources.getDatapoints();
      sources.unshift("");
      return sources;
    },

    getUpdateIntervalOptions: function() {
      return [
        { val: 10, label: '10 sec' },
        { val: 600, label: '1 min' },
        { val: 6000, label: '10 min' },
        { val: 36000, label: '1 hour' }
      ];
    },

    getPeriodOptions: function() {
      return [
        { val: "30-minutes", label: "Last 30 minutes" },
        { val: "60-minutes", label: "Last 60 minutes" },
        { val: "3-hours", label: "Last 3 hours" },
        { val: "12-hours", label: "Last 12 hours" },
        { val: "24-hours", label: "Last 24 hours" },
        { val: "3-days", label: "Last 3 days" },
        { val: "7-days", label: "Last 7 days" },
        { val: "4-weeks", label: "Last 4 weeks" }
      ];
    },

    getAggregateOptions: function() {
      return [
        { val: "sum", label: 'Sum' },
        { val: "average", label: 'Average' },
        { val: "delta", label: 'Delta' }
      ];
    },

    getSizeOptions: function() {
      return [
        { val: 1, label: '1 Column' },
        { val: 2, label: '2 Columns' },
        { val: 3, label: '3 Columns' }
      ];
    },

    getGraphTypeOptions: function() {
      return [
        { val: 'line', label: 'Line Graph' },
        { val: 'stack', label: 'Stacked Graph' }
      ];
    },

    getSchema: function() {
      var err = { type: 'required', message: 'Required' };
      return {
        name: { title: "Text", validators: ["required"] },
        update_interval:  {
          title: 'Update Interval',
          type: 'Select',
          options: this.getUpdateIntervalOptions()
        },
        range: {
          title: 'Period',
          type: 'Select',
          options: this.getPeriodOptions()
        },
        size: { title: "Size", type: 'Select', options: this.getSizeOptions() },
        graph_type: { title: "Graph Type", type: "Select", options: this.getGraphTypeOptions() },
        source: { title: "Source", type: 'Select', options: this.getSources() },
        http_proxy_url: {
          title: "Proxy URL",
          type: "Text",
          validators: [ function checkHttpProxyUrl(value, formValues) {
            if (formValues.source === "http_proxy" && value.length === 0) { return err; }
          }]
        },
        targets: { title: "Targets", type: 'Text', validators: ["required"] }
      };
    },

    sourceChanged: function(event) {
      var that = this;
      var source = this.$sourceSelect.val();
      if (source === "demo" || source === "graphite") {
        this.$httpProxyUrlField.hide();
        this.$targetInputField.show();
        if (collections.metrics.source !== source) {
          this.$targetInput.val("");
        }

        collections.metrics.source = source;
        collections.metrics.fetch().done(function() {
          that.$targetInput.select2({ tags: collections.metrics.autocomplete_names(), width: "17em" });
        });
      } else if (source === "http_proxy") {
        this.$targetInputField.hide();
        this.$httpProxyUrlField.show();
      }
    }

  });

})($, _, Backbone, app.views, app.models, app.collections);