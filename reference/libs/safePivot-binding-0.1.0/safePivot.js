HTMLWidgets.widget({
  name: "safePivot",
  type: "output",

  factory: function(el, width, height) {

    /* ============================================================
       1. Small utilities
       ============================================================ */

    function asArray(x) {
      if (x === null || x === undefined) return [];
      if (Array.isArray(x)) return x;
      if (x === "") return [];
      return [x];
    }

    function cleanNumber(x) {
      if (x === null || x === undefined || x === "") return null;

      var v = Number(x);
      return Number.isFinite(v) ? v : null;
    }

    function formatNumber(x, digits) {
      if (x === null || x === undefined || Number.isNaN(x)) return "";
      if (!Number.isFinite(Number(x))) return "";

      return Number(x).toFixed(digits);
    }

    function formatPercentFraction(x) {
      if (x === null || x === undefined || Number.isNaN(x)) return "";
      if (!Number.isFinite(Number(x))) return "";

      return (100 * Number(x)).toFixed(1) + "%";
    }

    function formatPercent100(x) {
      if (x === null || x === undefined || Number.isNaN(x)) return "";
      if (!Number.isFinite(Number(x))) return "";

      return Number(x).toFixed(1) + "%";
    }

    function isBlankText(x) {
      if (x === null || x === undefined) return true;

      var z = String(x).trim();

      return (
        z === "" ||
        z === "NA" ||
        z === "NaN" ||
        z === "null" ||
        z === "undefined" ||
        z === "-"
      );
    }

    function getNumberOption(x, defaultValue) {
      var v = Number(x);
      return Number.isFinite(v) ? v : defaultValue;
    }


    /* ============================================================
       2. Aggregators
       ============================================================ */

    function needsValue(type) {
      return ![
        "Count",
        "Count as Fraction of Total",
        "Count as Fraction of Rows",
        "Count as Fraction of Columns"
      ].includes(type);
    }

    function isFractionAggregator(type) {
      return [
        "Sum as Fraction of Total",
        "Sum as Fraction of Rows",
        "Sum as Fraction of Columns",
        "Count as Fraction of Total",
        "Count as Fraction of Rows",
        "Count as Fraction of Columns"
      ].includes(type);
    }

    function isIntegerLikeAggregator(type) {
      return [
        "Count",
        "Count unique",
        "N non-missing",
        "N missing"
      ].includes(type);
    }

    function isPercent100Aggregator(type) {
      return [
        "Non-missing %",
        "Missing %",
        "CV %"
      ].includes(type);
    }

    function numericAggregator(type, digits) {
      var nInputs = needsValue(type) ? 1 : 0;

      var generator = function(attrs) {
        attrs = attrs || [];
        var attr = attrs.length ? attrs[0] : null;

        var aggregator = function(data, rowKey, colKey) {
          return {
            values: [],
            rawValues: [],
            countAll: 0,
            numInputs: nInputs,

            push: function(record) {
              this.countAll += 1;

              if (!attr) return;

              var raw = record[attr];
              this.rawValues.push(raw);

              var v = cleanNumber(raw);
              if (v !== null) {
                this.values.push(v);
              }
            },

            baseValue: function() {
              var v = this.values;
              var n = v.length;

              if (
                type === "Count" ||
                type === "Count as Fraction of Total" ||
                type === "Count as Fraction of Rows" ||
                type === "Count as Fraction of Columns"
              ) {
                return this.countAll;
              }

              if (type === "Count unique") {
                var seen = {};

                this.rawValues.forEach(function(x) {
                  if (!isBlankText(x)) {
                    seen[String(x)] = true;
                  }
                });

                return Object.keys(seen).length;
              }

              if (type === "List unique values") {
                var seenList = {};

                this.rawValues.forEach(function(x) {
                  if (!isBlankText(x)) {
                    seenList[String(x)] = true;
                  }
                });

                return Object.keys(seenList).sort().join(", ");
              }

              if (type === "N non-missing") return n;
              if (type === "N missing") return this.countAll - n;

              if (type === "Non-missing %") {
                return this.countAll === 0 ? null : 100 * n / this.countAll;
              }

              if (type === "Missing %") {
                return this.countAll === 0 ? null : 100 * (this.countAll - n) / this.countAll;
              }

              if (n === 0) return null;

              if (
                type === "Sum" ||
                type === "Sum as Fraction of Total" ||
                type === "Sum as Fraction of Rows" ||
                type === "Sum as Fraction of Columns"
              ) {
                return v.reduce(function(a, b) { return a + b; }, 0);
              }

              if (type === "Mean") {
                return v.reduce(function(a, b) { return a + b; }, 0) / n;
              }

              if (
                type === "Median" ||
                type === "Q1" ||
                type === "Q3" ||
                type === "IQR"
              ) {
                var sorted = v.slice().sort(function(a, b) { return a - b; });

                function quantile(arr, p) {
                  var pos = (arr.length - 1) * p;
                  var base = Math.floor(pos);
                  var rest = pos - base;

                  if (arr[base + 1] !== undefined) {
                    return arr[base] + rest * (arr[base + 1] - arr[base]);
                  }

                  return arr[base];
                }

                var q1 = quantile(sorted, 0.25);
                var q2 = quantile(sorted, 0.50);
                var q3 = quantile(sorted, 0.75);

                if (type === "Median") return q2;
                if (type === "Q1") return q1;
                if (type === "Q3") return q3;
                if (type === "IQR") return q3 - q1;
              }

              if (type === "Min") {
                return Math.min.apply(null, v);
              }

              if (type === "Max") {
                return Math.max.apply(null, v);
              }

              if (type === "Range") {
                return Math.max.apply(null, v) - Math.min.apply(null, v);
              }

              if (
                type === "Variance" ||
                type === "SD" ||
                type === "SE" ||
                type === "CV %"
              ) {
                if (n < 2) return null;

                var mean = v.reduce(function(a, b) { return a + b; }, 0) / n;
                var ss = v.reduce(function(a, b) {
                  return a + Math.pow(b - mean, 2);
                }, 0);

                var variance = ss / (n - 1);
                var sd = Math.sqrt(variance);

                if (type === "Variance") return variance;
                if (type === "SD") return sd;
                if (type === "SE") return sd / Math.sqrt(n);
                if (type === "CV %") {
                  return mean === 0 ? null : 100 * sd / mean;
                }
              }

              return null;
            },

            value: function() {
              if (!isFractionAggregator(type)) {
                return this.baseValue();
              }

              var numerator = this.baseValue();
              var denomAgg = null;

              if (
                type === "Sum as Fraction of Total" ||
                type === "Count as Fraction of Total"
              ) {
                denomAgg = data.getAggregator([], []);
              }

              if (
                type === "Sum as Fraction of Rows" ||
                type === "Count as Fraction of Rows"
              ) {
                denomAgg = data.getAggregator(rowKey, []);
              }

              if (
                type === "Sum as Fraction of Columns" ||
                type === "Count as Fraction of Columns"
              ) {
                denomAgg = data.getAggregator([], colKey);
              }

              if (!denomAgg || typeof denomAgg.baseValue !== "function") {
                return null;
              }

              var denominator = denomAgg.baseValue();

              if (
                denominator === null ||
                denominator === undefined ||
                Number(denominator) === 0
              ) {
                return null;
              }

              return numerator / denominator;
            },

            format: function(x) {
              if (x === null || x === undefined) return "";

              if (type === "List unique values") {
                return String(x);
              }

              if (isFractionAggregator(type)) {
                return formatPercentFraction(x);
              }

              if (isPercent100Aggregator(type)) {
                return formatPercent100(x);
              }

              if (isIntegerLikeAggregator(type)) {
                return String(x);
              }

              return formatNumber(x, digits);
            }
          };
        };

        aggregator.numInputs = nInputs;
        return aggregator;
      };

      generator.numInputs = nInputs;
      return generator;
    }


    /* ============================================================
       3. Factor-order sorters
       ============================================================ */

    function makeSorter(levels) {
      var order = {};

      levels.forEach(function(x, i) {
        order[String(x)] = i;
      });

      return function(a, b) {
        var aa = Object.prototype.hasOwnProperty.call(order, String(a))
          ? order[String(a)]
          : Number.MAX_SAFE_INTEGER;

        var bb = Object.prototype.hasOwnProperty.call(order, String(b))
          ? order[String(b)]
          : Number.MAX_SAFE_INTEGER;

        if (aa !== bb) return aa - bb;

        return String(a).localeCompare(String(b));
      };
    }


    /* ============================================================
       4. Shiny config cleaning
       ============================================================ */

    function cleanConfig(config) {
      config = config || {};

      return {
        rows: asArray(config.rows),
        cols: asArray(config.cols),
        vals: asArray(config.vals),
        aggregatorName: config.aggregatorName || null,
        rendererName: config.rendererName || null,
        inclusions: config.inclusions || {},
        exclusions: config.exclusions || {}
      };
    }


    /* ============================================================
       5. Heatmap colour scales
       ============================================================ */

    function hexToRgb(hex) {
      hex = String(hex).replace("#", "");

      return {
        r: parseInt(hex.substring(0, 2), 16),
        g: parseInt(hex.substring(2, 4), 16),
        b: parseInt(hex.substring(4, 6), 16)
      };
    }

    function rgbToHex(r, g, b) {
      return "#" + [r, g, b].map(function(x) {
        var h = Math.round(x).toString(16);
        return h.length === 1 ? "0" + h : h;
      }).join("");
    }

    function interpolateColor(c1, c2, t) {
      var a = hexToRgb(c1);
      var b = hexToRgb(c2);

      return rgbToHex(
        a.r + (b.r - a.r) * t,
        a.g + (b.g - a.g) * t,
        a.b + (b.b - a.b) * t
      );
    }

    function makeSafePivotColorScale(palette) {
      return function(values) {
        var nums = [];

        values.forEach(function(x) {
          var v = Number(x);
          if (Number.isFinite(v)) nums.push(v);
        });

        if (nums.length === 0) {
          return function() {
            return "#ffffff";
          };
        }

        var min = Math.min.apply(null, nums);
        var max = Math.max.apply(null, nums);

        return function(x) {
          var v = Number(x);

          if (!Number.isFinite(v) || min === max) {
            return "#ffffff";
          }

          var t = (v - min) / (max - min);
          t = Math.max(0, Math.min(1, t));

          if (palette === "blue") {
            if (t <= 0.5) {
              return interpolateColor("#f7fbff", "#c6dbef", t * 2);
            }

            return interpolateColor("#c6dbef", "#6baed6", (t - 0.5) * 2);
          }

          if (palette === "yellow_orange") {
            if (t <= 0.5) {
              return interpolateColor("#ffffe5", "#fee391", t * 2);
            }

            return interpolateColor("#fee391", "#fdae6b", (t - 0.5) * 2);
          }

          if (palette === "green") {
            if (t <= 0.5) {
              return interpolateColor("#f7fcf5", "#c7e9c0", t * 2);
            }

            return interpolateColor("#c7e9c0", "#74c476", (t - 0.5) * 2);
          }

          if (palette === "green_red") {
            if (t <= 0.5) {
              return interpolateColor("#d1fae5", "#fff7ed", t * 2);
            }

            return interpolateColor("#fff7ed", "#f87171", (t - 0.5) * 2);
          }

          /* Default: screenshot-like blue -> white -> red */
          if (t <= 0.5) {
            return interpolateColor("#7777ff", "#ffffff", t * 2);
          }

          return interpolateColor("#ffffff", "#ff7777", (t - 0.5) * 2);
        };
      };
    }


    /* ============================================================
       6. Conditional formatting
       ============================================================ */

    function parseCellNumber(txt) {
      if (txt === null || txt === undefined) return null;

      var cleaned = String(txt)
        .replace(/,/g, "")
        .replace(/%/g, "")
        .trim();

      if (cleaned === "") return null;

      var v = Number(cleaned);
      return Number.isFinite(v) ? v : null;
    }

    function applySafePivotConditionalFormatting(el, opts) {
      if (!opts || opts.enabled === false) return;

      var cells = $(el).find("table.pvtTable tbody td");
      var values = [];

      cells.each(function() {
        var v = parseCellNumber($(this).text());
        if (v !== null) values.push(v);
      });

      if (values.length === 0) return;

      var min = Math.min.apply(null, values);
      var max = Math.max.apply(null, values);

      cells.each(function() {
        var cell = $(this);
        var text = cell.text();
        var v = parseCellNumber(text);

        cell.removeClass(
          "safePivot-cell-high safePivot-cell-low safePivot-cell-missing"
        );

        if (isBlankText(text)) {
          cell.addClass("safePivot-cell-missing");
          return;
        }

        if (v === null || min === max) return;

        var t = (v - min) / (max - min);

        if (t >= opts.highThreshold) {
          cell.addClass("safePivot-cell-high");
        } else if (t <= opts.lowThreshold) {
          cell.addClass("safePivot-cell-low");
        }
      });
    }

    function applyFormattingSoon(el, x) {
      setTimeout(function() {
        applySafePivotConditionalFormatting(el, {
          enabled: x.conditional_format !== false,
          highThreshold: getNumberOption(x.high_threshold, 0.85),
          lowThreshold: getNumberOption(x.low_threshold, 0.15)
        });
      }, 0);
    }


    /* ============================================================
       7. htmlwidgets binding
       ============================================================ */

    return {
      renderValue: function(x) {
        $(el).addClass("safePivot-wrapper");

        var data = HTMLWidgets.dataframeToD3(x.data);
        var util = $.pivotUtilities;

        var renderers = {
          "Table": util.renderers["Table"],
          "Heatmap": util.renderers["Heatmap"],
          "Row Heatmap": util.renderers["Row Heatmap"],
          "Col Heatmap": util.renderers["Col Heatmap"]
        };

        var aggregators = {};
        var allowedAggregators = x.allowed_aggregators || [];

        allowedAggregators.forEach(function(name) {
          aggregators[name] = numericAggregator(
            name,
            getNumberOption(x.numeric_digits, 3)
          );
        });

        var sorters = {};

        if (x.respect_factor_order && x.factor_levels) {
          Object.keys(x.factor_levels).forEach(function(col) {
            sorters[col] = makeSorter(x.factor_levels[col]);
          });
        }

        var pivotOptions = {
          rows: asArray(x.rows),
          cols: asArray(x.cols),
          vals: asArray(x.vals),
          aggregatorName: x.aggregator || "Median",
          rendererName: x.renderer || "Table",
          aggregators: aggregators,
          renderers: renderers,
          sorters: sorters,

          rendererOptions: {
            table: {
              rowTotals: x.show_row_totals !== false,
              colTotals: x.show_col_totals !== false
            },
            heatmap: {
              colorScaleGenerator: makeSafePivotColorScale(
                x.heatmap_palette || "blue"
              )
            }
          },

          onRefresh: function(config) {
            applyFormattingSoon(el, x);

            if (HTMLWidgets.shinyMode && el.id) {
              Shiny.setInputValue(
                el.id + "_config",
                cleanConfig(config),
                { priority: "event" }
              );
            }
          }
        };

        $(el).empty().pivotUI(data, pivotOptions, true);

        applyFormattingSoon(el, x);
      },

      resize: function(width, height) {}
    };
  }
});

