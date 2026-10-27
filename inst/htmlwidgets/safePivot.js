HTMLWidgets.widget({
    name: "safePivot",
    type: "output",

    factory: function (el, width, height) {
        /* ============================================================
        1. Small utilities
        ============================================================ */

        function asArray(x) {
            if (x === null || x === undefined)
                return [];
            if (Array.isArray(x))
                return x;
            if (x === "")
                return [];
            return [x];
        }

        function cleanNumber(x) {
            if (x === null || x === undefined || x === "")
                return null;

            var v = Number(x);
            return Number.isFinite(v) ? v : null;
        }

        function formatNumber(x, digits) {
            if (x === null || x === undefined || Number.isNaN(x))
                return "";
            if (!Number.isFinite(Number(x)))
                return "";

            return Number(x).toFixed(digits);
        }

        function formatPercentFraction(x) {
            if (x === null || x === undefined || Number.isNaN(x))
                return "";
            if (!Number.isFinite(Number(x)))
                return "";

            return (100 * Number(x)).toFixed(1) + "%";
        }

        function formatPercent100(x) {
            if (x === null || x === undefined || Number.isNaN(x))
                return "";
            if (!Number.isFinite(Number(x)))
                return "";

            return Number(x).toFixed(1) + "%";
        }

        function isBlankText(x) {
            if (x === null || x === undefined)
                return true;

            var z = String(x).trim();

            return (
                z === "" ||
                z === "NA" ||
                z === "NaN" ||
                z === "null" ||
                z === "undefined" ||
                z === "-");
        }

        function getNumberOption(x, defaultValue) {
            var v = Number(x);
            return Number.isFinite(v) ? v : defaultValue;
        }

        function safePivotLog() {
            if (
                typeof window !== "undefined" &&
                window.safePivotDebug === true &&
                window.console &&
                window.console.log) {
                window.console.log.apply(window.console, arguments);
            }
        }

        function safePivotWarn() {
            if (
                typeof window !== "undefined" &&
                window.console &&
                window.console.warn) {
                window.console.warn.apply(window.console, arguments);
            }
        }

        function objectKeys(x) {
            return x ? Object.keys(x) : [];
        }

        /* ============================================================
        2. Aggregators
        ============================================================ */

        /*
         * The aggregator list comes from R (safe_pivot_aggregator_registry()):
         * each entry has name, family, measure, scope, needs_value, format.
         * See R/aggregators.R for what each field means.
         */

        function percent100(num, den) {
            num = Number(num);
            den = Number(den);

            if (!Number.isFinite(num) || !Number.isFinite(den) || den === 0) {
                return null;
            }

            return 100 * num / den;
        }

        function isMissingDataValue(value, missingLabel) {
            if (value === null || value === undefined)
                return true;
            if (typeof value === "number" && !Number.isFinite(value))
                return true;

            var text = String(value).trim();

            if (text === "")
                return true;

            if (
                missingLabel !== null &&
                missingLabel !== undefined &&
                text === String(missingLabel)) {
                return true;
            }

            return isBlankText(text);
        }

        function quantile(sorted, p) {
            var pos = (sorted.length - 1) * p;
            var base = Math.floor(pos);
            var rest = pos - base;

            if (sorted[base + 1] !== undefined) {
                return sorted[base] + rest * (sorted[base + 1] - sorted[base]);
            }

            return sorted[base];
        }

        function sumOf(v) {
            return v.reduce(function (a, b) {
                return a + b;
            }, 0);
        }

        // Numeric summaries for family "stat".
        function statValue(name, v) {
            var n = v.length;

            if (n === 0)
                return null;

            if (name === "Sum")
                return sumOf(v);
            if (name === "Mean")
                return sumOf(v) / n;
            if (name === "Min")
                return Math.min.apply(null, v);
            if (name === "Max")
                return Math.max.apply(null, v);
            if (name === "Range")
                return Math.max.apply(null, v) - Math.min.apply(null, v);

            if (name === "Median" || name === "Q1" || name === "Q3" || name === "IQR") {
                var sorted = v.slice().sort(function (a, b) {
                    return a - b;
                });

                if (name === "Median")
                    return quantile(sorted, 0.5);
                if (name === "Q1")
                    return quantile(sorted, 0.25);
                if (name === "Q3")
                    return quantile(sorted, 0.75);
                return quantile(sorted, 0.75) - quantile(sorted, 0.25);
            }

            if (name === "Variance" || name === "SD" || name === "SE" || name === "CV %") {
                if (n < 2)
                    return null;

                var mean = sumOf(v) / n;
                var variance = v.reduce(function (a, b) {
                    return a + Math.pow(b - mean, 2);
                }, 0) / (n - 1);
                var sd = Math.sqrt(variance);

                if (name === "Variance")
                    return variance;
                if (name === "SD")
                    return sd;
                if (name === "SE")
                    return sd / Math.sqrt(n);
                return mean === 0 ? null : 100 * sd / mean;
            }

            return null;
        }

        function makeAggregator(spec, digits, missingLabel) {
            var nInputs = spec.needs_value ? 1 : 0;

            var generator = function (attrs) {
                attrs = attrs || [];
                var attr = attrs.length ? attrs[0] : null;

                var aggregator = function (data, rowKey, colKey) {
                    // The aggregator for the row, column or grand total.
                    function scopeAggregator(scope) {
                        if (scope === "row")
                            return data.getAggregator(rowKey, []);
                        if (scope === "col")
                            return data.getAggregator([], colKey);
                        if (scope === "total")
                            return data.getAggregator([], []);
                        return null;
                    }

                    return {
                        values: [],
                        rawValues: [],
                        counts: {
                            all: 0,
                            missing: 0,
                            non_missing: 0,
                            numeric: 0,
                            zero: 0,
                            non_zero: 0
                        },
                        numInputs: nInputs,

                        push: function (record) {
                            this.counts.all += 1;

                            if (!attr)
                                return;

                            var raw = record[attr];
                            this.rawValues.push(raw);

                            if (isMissingDataValue(raw, missingLabel)) {
                                this.counts.missing += 1;
                                return;
                            }

                            this.counts.non_missing += 1;

                            var v = cleanNumber(raw);

                            if (v !== null) {
                                this.values.push(v);
                                this.counts.numeric += 1;
                                this.counts[v === 0 ? "zero" : "non_zero"] += 1;
                            }
                        },

                        // Count used by n / percent aggregators.
                        measureN: function (measure) {
                            return this.counts[measure];
                        },

                        // Denominator for a percent: all records for
                        // (non-)missing, numeric values for (non-)zero.
                        measureDenominator: function (measure) {
                            return measure === "missing" || measure === "non_missing"
                                ? this.counts.all
                                : this.counts.numeric;
                        },

                        uniqueValues: function () {
                            var seen = {};

                            this.rawValues.forEach(function (x) {
                                if (!isMissingDataValue(x, missingLabel)) {
                                    seen[String(x)] = true;
                                }
                            });

                            return Object.keys(seen);
                        },

                        // Value for this cell alone (no row/column context).
                        baseValue: function () {
                            switch (spec.family) {
                            case "count":
                                return this.counts.all;
                            case "count_unique":
                                return this.uniqueValues().length;
                            case "list":
                                return this.uniqueValues().sort().join(", ");
                            case "n":
                                return this.measureN(spec.measure);
                            case "percent":
                                return percent100(
                                    this.measureN(spec.measure),
                                    this.measureDenominator(spec.measure));
                            case "fraction":
                                return spec.measure === "count"
                                    ? this.counts.all
                                    : statValue("Sum", this.values);
                            default:
                                return statValue(spec.name, this.values);
                            }
                        },

                        value: function () {
                            if (spec.family === "percent" && spec.scope !== "cell") {
                                var other = scopeAggregator(spec.scope);

                                if (!other || typeof other.measureDenominator !== "function")
                                    return null;

                                return percent100(
                                    this.measureN(spec.measure),
                                    other.measureDenominator(spec.measure));
                            }

                            if (spec.family === "fraction") {
                                var total = scopeAggregator(spec.scope);

                                if (!total || typeof total.baseValue !== "function")
                                    return null;

                                var denominator = total.baseValue();

                                if (
                                    denominator === null ||
                                    denominator === undefined ||
                                    Number(denominator) === 0) {
                                    return null;
                                }

                                return this.baseValue() / denominator;
                            }

                            return this.baseValue();
                        },

                        format: function (x) {
                            if (x === null || x === undefined)
                                return "";

                            if (spec.format === "text")
                                return String(x);
                            if (spec.format === "integer")
                                return String(x);
                            if (spec.family === "fraction")
                                return formatPercentFraction(x);
                            if (spec.format === "percent")
                                return formatPercent100(x);

                            return formatNumber(x, digits);
                        }
                    };
                };

                aggregator.numInputs = nInputs;
                aggregator.displayName = spec.name;

                return aggregator;
            };

            generator.numInputs = nInputs;
            return generator;
        }

        function resolveAggregatorName(requestedAggregator, aggregators) {
            var names = objectKeys(aggregators);

            requestedAggregator = requestedAggregator || "Median";

            if (aggregators && aggregators[requestedAggregator])
                return requestedAggregator;
            if (aggregators && aggregators.Median)
                return "Median";
            if (aggregators && aggregators.Count)
                return "Count";

            return names.length ? names[0] : requestedAggregator;
        }

        /* ============================================================
        3. Factor-order sorters
        ============================================================ */

        function makeSorter(levels) {
            var order = {};

            levels.forEach(function (x, i) {
                order[String(x)] = i;
            });

            return function (a, b) {
                var aa = Object.prototype.hasOwnProperty.call(order, String(a))
                     ? order[String(a)]
                     : Number.MAX_SAFE_INTEGER;

                var bb = Object.prototype.hasOwnProperty.call(order, String(b))
                     ? order[String(b)]
                     : Number.MAX_SAFE_INTEGER;

                if (aa !== bb)
                    return aa - bb;

                return String(a).localeCompare(String(b));
            };
        }

        /* ============================================================
        4. Variable type badges
        ============================================================ */

        function safePivotTypeBadgeClass(type) {
            var known = [
                "num",
                "int",
                "chr",
                "fct",
                "ord",
                "date",
                "time",
                "lgl",
                "list",
                "obj"
            ];

            if (known.indexOf(type) >= 0)
                return "safePivot-type-" + type;

            return "safePivot-type-obj";
        }

        function safePivotTypeBadgeText(type) {
            var labels = {
                num: "num",
                int: "int",
                chr: "chr",
                fct: "fct",
                ord: "ord",
                date: "date",
                time: "time",
                lgl: "lgl",
                list: "list",
                obj: "obj"
            };

            return labels[type] || "obj";
        }

        function safePivotTypeBadgeTitle(info) {
            if (!info)
                return "Data type: object";

            var label = info.label || info.type || "object";
            return "Data type: " + label;
        }

        function applySafePivotTypeBadgesNow(el, x) {
            if (!x || x.show_type_badges === false || !x.variable_types)
                return;

            var variableTypes = x.variable_types;

            $(el).find("table.pvtUi .pvtAxisContainer li span.pvtAttr").each(function () {
                var pill = $(this);
                var variableName = pill.data("attrName");

                pill.find(".safePivot-type-badge").remove();

                if (variableName === undefined || !variableTypes[variableName])
                    return;

                var info = variableTypes[variableName];
                var titleText = safePivotTypeBadgeTitle(info);

                var badge = $("<span/>")
                    .addClass("safePivot-type-badge")
                    .addClass(safePivotTypeBadgeClass(info.type || "obj"))
                    .attr("title", titleText)
                    .attr("aria-label", titleText)
                    .text(safePivotTypeBadgeText(info.type || "obj"));

                var triangle = pill.children(".pvtTriangle").first();

                if (triangle.length) {
                    badge.insertBefore(triangle);
                } else {
                    pill.append(badge);
                }
            });
        }

        function applySafePivotTypeBadges(el, x) {
            setTimeout(function () {
                applySafePivotTypeBadgesNow(el, x);
            }, 0);
        }

        /* ============================================================
        5. Shiny config cleaning
        ============================================================ */

        function cleanFilters(filters) {
            var out = {};

            if (!filters || typeof filters !== "object" || Array.isArray(filters))
                return out;

            Object.keys(filters).forEach(function (attr) {
                out[attr] = asArray(filters[attr]).map(function (v) {
                    return v === null || v === undefined ? "null" : String(v);
                });
            });

            return out;
        }

        function cleanConfig(config) {
            config = config || {};

            return {
                rows: asArray(config.rows),
                cols: asArray(config.cols),
                vals: asArray(config.vals),
                aggregatorName: config.aggregatorName || null,
                rendererName: config.rendererName || null,
                inclusions: cleanFilters(config.inclusions),
                exclusions: cleanFilters(config.exclusions)
            };
        }

        /* ============================================================
        6. Heatmap colour scales
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
            return "#" + [r, g, b].map(function (x) {
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
                a.b + (b.b - a.b) * t);
        }

        function makeSafePivotColorScale(palette) {
            return function (values) {
                var nums = [];

                values.forEach(function (x) {
                    var v = Number(x);
                    if (Number.isFinite(v))
                        nums.push(v);
                });

                if (nums.length === 0) {
                    return function () {
                        return "#ffffff";
                    };
                }

                var min = Math.min.apply(null, nums);
                var max = Math.max.apply(null, nums);

                return function (x) {
                    var v = Number(x);

                    if (!Number.isFinite(v) || min === max)
                        return "#ffffff";

                    var t = (v - min) / (max - min);
                    t = Math.max(0, Math.min(1, t));

                    if (palette === "blue") {
                        if (t <= 0.5)
                            return interpolateColor("#f7fbff", "#c6dbef", t * 2);
                        return interpolateColor("#c6dbef", "#6baed6", (t - 0.5) * 2);
                    }

                    if (palette === "yellow_orange") {
                        if (t <= 0.5)
                            return interpolateColor("#ffffe5", "#fee391", t * 2);
                        return interpolateColor("#fee391", "#fdae6b", (t - 0.5) * 2);
                    }

                    if (palette === "green") {
                        if (t <= 0.5)
                            return interpolateColor("#f7fcf5", "#c7e9c0", t * 2);
                        return interpolateColor("#c7e9c0", "#74c476", (t - 0.5) * 2);
                    }

                    if (palette === "green_red") {
                        if (t <= 0.5)
                            return interpolateColor("#d1fae5", "#fff7ed", t * 2);
                        return interpolateColor("#fff7ed", "#f87171", (t - 0.5) * 2);
                    }

                    if (t <= 0.5)
                        return interpolateColor("#7777ff", "#ffffff", t * 2);
                    return interpolateColor("#ffffff", "#ff7777", (t - 0.5) * 2);
                };
            };
        }

        /* ============================================================
        7. Conditional formatting and renderer helpers
        ============================================================ */

        function parseCellNumber(txt) {
            if (txt === null || txt === undefined)
                return null;

            var cleaned = String(txt)
                .replace(/,/g, "")
                .replace(/%/g, "")
                .trim();

            if (cleaned === "")
                return null;

            var v = Number(cleaned);
            return Number.isFinite(v) ? v : null;
        }

        function isEmptyRenderedCell(txt) {
            if (txt === null || txt === undefined)
                return true;

            var cleaned = String(txt).trim();

            return (
                cleaned === "" ||
                cleaned === "NA" ||
                cleaned === "NaN" ||
                cleaned === "null" ||
                cleaned === "undefined");
        }

        function safePivotPlotlyRendererNames() {
            return [
                "Horizontal Bar Chart",
                "Horizontal Stacked Bar Chart",
                "Bar Chart",
                "Stacked Bar Chart",
                "Line Chart",
                "Area Chart",
                "Scatter Chart",
                "Multiple Pie Chart"
            ];
        }

        function isSafePivotPlotlyRenderer(rendererName) {
            return safePivotPlotlyRendererNames().indexOf(rendererName) >= 0;
        }

        function isSafePivotHeatmapRenderer(rendererName) {
            return [
                "Heatmap",
                "Row Heatmap",
                "Col Heatmap"
            ].indexOf(rendererName) >= 0;
        }

        function applySafePivotRendererModeClass(el, rendererName) {
            var $el = $(el);

            $el.removeClass("safePivot-table-mode safePivot-plotly-mode safePivot-table-renderer");

            if (isSafePivotPlotlyRenderer(rendererName)) {
                $el.addClass("safePivot-plotly-mode");
            } else {
                $el.addClass("safePivot-table-mode");
            }

            // Plain table (not heatmap): hover and total shading are safe to apply.
            if (rendererName === "Table") {
                $el.addClass("safePivot-table-renderer");
            }
        }

        function applySafePivotSizingOptions(el, x) {
            x = x || {};

            var uiFontSize = getNumberOption(x.ui_font_size, 14);
            var pillFontSize = getNumberOption(x.pill_font_size, 14);
            var tableFontSize = getNumberOption(x.table_font_size, 15);
            var badgeFontSize = getNumberOption(x.badge_font_size, 11);

            $(el).css("--safePivot-ui-font-size", uiFontSize + "px");
            $(el).css("--safePivot-pill-font-size", pillFontSize + "px");
            $(el).css("--safePivot-table-font-size", tableFontSize + "px");
            $(el).css("--safePivot-badge-font-size", badgeFontSize + "px");
        }

        function clearSafePivotCellClasses(el) {
            $(el)
            .find("table.pvtTable tbody td")
            .removeClass(
                [
                    "safePivot-cell-high",
                    "safePivot-cell-low",
                    "safePivot-cell-empty",
                    "safePivot-cell-missing",
                    "safePivot-cell-zero"
                ].join(" "));
        }

        function applySafePivotConditionalFormatting(el, opts) {
            clearSafePivotCellClasses(el);

            if (!opts || opts.enabled === false)
                return;

            var mode = opts.mode || "value";
            if (mode === "none")
                return;

            // Data cells only: totals are on a different scale and would
            // otherwise always be the "high" values.
            var cells = $(el).find("table.pvtTable tbody td.pvtVal");
            var values = [];

            cells.each(function () {
                var v = parseCellNumber($(this).text());
                if (v !== null)
                    values.push(v);
            });

            var min = values.length ? Math.min.apply(null, values) : null;
            var max = values.length ? Math.max.apply(null, values) : null;

            cells.each(function () {
                var cell = $(this);
                var text = cell.text();
                var v = parseCellNumber(text);

                if (isEmptyRenderedCell(text)) {
                    cell.addClass("safePivot-cell-empty");
                    return;
                }

                if ((mode === "data_quality" || mode === "both") && v === 0) {
                    cell.addClass("safePivot-cell-zero");
                    return;
                }

                if (
                    (mode === "value" || mode === "both") &&
                    v !== null &&
                    min !== null &&
                    max !== null &&
                    min !== max) {
                    var t = (v - min) / (max - min);

                    if (t >= opts.highThreshold) {
                        cell.addClass("safePivot-cell-high");
                    } else if (t <= opts.lowThreshold) {
                        cell.addClass("safePivot-cell-low");
                    }
                }
            });
        }

        function applyFormattingSoon(el, x, rendererName) {
            setTimeout(function () {
                rendererName = rendererName || x.renderer || x.rendererName || "Table";

                if (
                    isSafePivotPlotlyRenderer(rendererName) ||
                    isSafePivotHeatmapRenderer(rendererName)
                ) {
                    applySafePivotConditionalFormatting(el, {
                        enabled: false
                    });
                    return;
                }

                applySafePivotConditionalFormatting(el, {
                    enabled: x.conditional_format !== false,
                    mode: x.conditional_format_mode || "value",
                    highThreshold: getNumberOption(x.high_threshold, 0.85),
                    lowThreshold: getNumberOption(x.low_threshold, 0.15)
                });
            }, 0);
        }

        /* ============================================================
        8. Plotly sizing
        ============================================================ */

        function safePivotGetPlotSize(x) {
            x = x || {};

            var $el = $(el);
            var explicitWidth = Number(x.plot_width);
            var explicitHeight = Number(x.plot_height);

            // The renderer cell grows to fit the chart, so measure the widget
            // and subtract the rows column next to it.
            var rowsWidth = $el.find("td.pvtRows").first().outerWidth() || 0;
            var availableWidth = ($el.innerWidth() || width || 900) - rowsWidth - 32;

            /*
            Important:
            Do not calculate Plotly height from the whole htmlwidget height.
            Use a stable default plot height, unless user explicitly gives plot_height.
             */
            var defaultPlotHeight = getNumberOption(x.plot_default_height, 620);
            var minPlotHeight = getNumberOption(x.plot_min_height, 520);
            var maxPlotWidth = getNumberOption(x.plot_max_width, 1150);

            var finalWidth =
                (Number.isFinite(explicitWidth) && explicitWidth > 0 ? explicitWidth : 0) ||
                Math.min(availableWidth, maxPlotWidth);

            var finalHeight =
                (Number.isFinite(explicitHeight) && explicitHeight > 0 ? explicitHeight : 0) ||
            defaultPlotHeight;

            return {
                width: Math.max(320, Math.floor(finalWidth)),
                height: Math.max(minPlotHeight, Math.floor(finalHeight))
            };
        }

        function safePivotMeasureLabel(x, config) {
            config = config || {};

            var aggregator =
                config.aggregatorName ||
                x.aggregator ||
                "Value";

            var vals = asArray(config.vals && config.vals.length ? config.vals : x.vals);
            var val = vals.length ? vals.join(" / ") : "value";

            if (aggregator === "Count") {
                return "Count";
            }

            return aggregator + "(" + val + ")";
        }

        function safePivotBuildPlotlyRelayout(x, config, rendererName) {
            x = x || {};
            config = config || {};

            var rows = asArray(config.rows && config.rows.length ? config.rows : x.rows);
            var cols = asArray(config.cols && config.cols.length ? config.cols : x.cols);
            var measure = safePivotMeasureLabel(x, config);
            var colLabel = cols.length ? cols.join(" / ") : "Category";
            var rowLabel = rows.length ? rows.join(" / ") : "Group";
            var isHorizontal = String(rendererName || "").indexOf("Horizontal") >= 0;
            var title = measure;

            if (cols.length) {
                title += " vs " + colLabel;
            }

            if (rows.length) {
                title += " by " + rowLabel;
            }

            var layout = {
                "title.text": title,
                "title.x": 0.5,
                "title.xanchor": "center",
                "title.font.size": getNumberOption(x.plot_title_size, 18),
                "font.size": getNumberOption(x.plot_font_size, 14),
                "showlegend": true,
                "legend.orientation": "v",
                "legend.x": 1.02,
                "legend.xanchor": "left",
                "legend.y": 1,
                "legend.yanchor": "top",
                "legend.font.size": getNumberOption(x.legend_font_size, 13),
                "xaxis.automargin": true,
                "yaxis.automargin": true,
                "xaxis.tickfont.size": getNumberOption(x.axis_tick_size, 13),
                "yaxis.tickfont.size": getNumberOption(x.axis_tick_size, 13),
                "xaxis.title.font.size": getNumberOption(x.axis_title_size, 14),
                "yaxis.title.font.size": getNumberOption(x.axis_title_size, 14)
            };

            if (isHorizontal) {
                layout["xaxis.title.text"] = measure;
                layout["yaxis.title.text"] = colLabel;
            } else {
                layout["xaxis.title.text"] = colLabel;
                layout["yaxis.title.text"] = measure;
            }

            return layout;
        }

        function safePivotRelayoutPlotly(el, x, config, rendererName) {
            if (!window.Plotly)
                return;

            x = x || {};
            config = config || el.safePivotLastConfig || {};
            rendererName = rendererName || el.safePivotLastRenderer || $(el).find(".pvtRenderer").val() || "Table";

            if (!isSafePivotPlotlyRenderer(rendererName)) {
                return;
            }

            var size = safePivotGetPlotSize(x);
            var layout = safePivotMakePlotlyLayout(x, size);
            var relayout = Object.assign(
                {
                    width: layout.width,
                    height: layout.height,
                    autosize: false,

                    "font.size": layout.font.size,
                    "font.color": layout.font.color,

                    "title.font.size": layout.title.font.size,
                    "title.font.color": layout.title.font.color,
                    "title.x": 0.5,
                    "title.xanchor": "center",

                    "xaxis.automargin": true,
                    "xaxis.title.standoff": 18,
                    "xaxis.title.font.size": layout.xaxis.title.font.size,
                    "xaxis.tickfont.size": layout.xaxis.tickfont.size,

                    "yaxis.automargin": true,
                    "yaxis.title.standoff": 18,
                    "yaxis.title.font.size": layout.yaxis.title.font.size,
                    "yaxis.tickfont.size": layout.yaxis.tickfont.size,

                    "showlegend": true,
                    "legend.orientation": "v",
                    "legend.x": 1.02,
                    "legend.y": 1,
                    "legend.xanchor": "left",
                    "legend.yanchor": "top",
                    "legend.font.size": layout.legend.font.size
                },
                safePivotBuildPlotlyRelayout(x, config, rendererName)
            );

            $(el)
            .find(".js-plotly-plot")
            .each(function () {
                try {
                    window.Plotly.relayout(this, relayout);

                    if (window.Plotly.Plots && window.Plotly.Plots.resize) {
                        window.Plotly.Plots.resize(this);
                    }
                } catch (e) {
                    safePivotWarn("safePivot Plotly relayout failed:", e);
                }
            });
        }

        function safePivotSetupResizeObserver(el, x) {
            if (!window.ResizeObserver)
                return;

            if (el.safePivotResizeObserver) {
                el.safePivotResizeObserver.disconnect();
                el.safePivotResizeObserver = null;
            }

            var resizeTimer = null;

            el.safePivotResizeObserver = new ResizeObserver(function () {
                clearTimeout(resizeTimer);

                resizeTimer = setTimeout(function () {
                    safePivotRelayoutPlotly(el, x, el.safePivotLastConfig, el.safePivotLastRenderer);
                }, 80);
            });

            el.safePivotResizeObserver.observe(el);
        }

        function safePivotResizePlotly(el, x) {
            if (!window.Plotly)
                return;
            safePivotRelayoutPlotly(el, x || {}, el.safePivotLastConfig, el.safePivotLastRenderer);
        }

        /* ============================================================
        9. Renderer registry
        ============================================================ */

        function safePivotBuildRenderers() {
            var util = $.pivotUtilities || {};
            var baseRenderers = util.renderers || {};
            var plotlyRenderers = util.plotly_renderers || {};
            var out = {};

            ["Table", "Heatmap", "Row Heatmap", "Col Heatmap"].forEach(function (name) {
                if (baseRenderers[name])
                    out[name] = baseRenderers[name];
            });

            safePivotPlotlyRendererNames().forEach(function (name) {
                if (plotlyRenderers[name])
                    out[name] = plotlyRenderers[name];
            });

            safePivotLog("safePivot available renderers:", Object.keys(out));
            return out;
        }

        function safePivotResolveRendererName(requestedRenderer, renderers) {
            requestedRenderer = requestedRenderer || "Table";

            if (renderers && renderers[requestedRenderer])
                return requestedRenderer;

            if (renderers && renderers.Table) {
                safePivotWarn(
                    "safePivot requested renderer is not available:",
                    requestedRenderer,
                    "Falling back to Table. Available renderers:",
                    Object.keys(renderers));

                return "Table";
            }

            var names = renderers ? Object.keys(renderers) : [];

            if (names.length > 0) {
                safePivotWarn(
                    "safePivot Table renderer is not available. Falling back to:",
                    names[0]);

                return names[0];
            }

            return requestedRenderer;
        }

        function safePivotShowDependencyError(message) {
            $(el)
            .empty()
            .addClass("safePivot-wrapper")
            .append(
                $("<div/>")
                .addClass("safePivot-error")
                .attr("role", "alert")
                .text(message));
        }

        function safePivotMakePlotlyLayout(x, size) {
            x = x || {};
            size = size || safePivotGetPlotSize(x);

            return Object.assign({
                autosize: false,
                width: size.width,
                height: size.height,

                margin: {
                    l: 90,
                    r: 120,
                    t: 70,
                    b: 90
                },

                paper_bgcolor: "white",
                plot_bgcolor: "white",

                font: {
                    family: 'system-ui, -apple-system, BlinkMacSystemFont, "Segoe UI", sans-serif',
                    size: getNumberOption(x.plot_font_size, 16),
                    color: "#374151"
                },

                title: {
                    font: {
                        size: getNumberOption(x.plot_title_size, 20),
                        color: "#374151"
                    },
                    x: 0.5,
                    xanchor: "center"
                },

                xaxis: {
                    automargin: true,
                    title: {
                        standoff: 18,
                        font: {
                            size: getNumberOption(x.axis_title_size, 16)
                        }
                    },
                    tickfont: {
                        size: getNumberOption(x.axis_tick_size, 14)
                    }
                },

                yaxis: {
                    automargin: true,
                    title: {
                        standoff: 18,
                        font: {
                            size: getNumberOption(x.axis_title_size, 16)
                        }
                    },
                    tickfont: {
                        size: getNumberOption(x.axis_tick_size, 14)
                    }
                },

                legend: {
                    orientation: "v",
                    x: 1.02,
                    y: 1,
                    xanchor: "left",
                    yanchor: "top",
                    font: {
                        size: getNumberOption(x.legend_font_size, 14)
                    }
                }
            },
                x.plotly_layout || {});
        }

        function makeRendererOptions(x) {
            var size = safePivotGetPlotSize(x);
            var plotlyLayout = safePivotMakePlotlyLayout(x, size);

            return {
                table: {
                    rowTotals: x.show_row_totals !== false,
                    colTotals: x.show_col_totals !== false
                },

                heatmap: {
                    colorScaleGenerator: makeSafePivotColorScale(x.heatmap_palette || "blue")
                },

                /*
                 * PivotTable.js Plotly renderers read rendererOptions.plotly.
                 * Some builds also inspect rendererOptions.plotlyLayout, so keep
                 * both references aligned.
                 */
                plotly: plotlyLayout,
                plotlyLayout: plotlyLayout,

                plotlyConfig: Object.assign({
                    responsive: false,
                    displaylogo: false,
                    displayModeBar: true,
                    scrollZoom: false,
                    toImageButtonOptions: {
                        format: "png",
                        filename: "safePivot_chart",
                        height: size.height,
                        width: size.width,
                        scale: 2
                    }
                },
                    x.plotly_config || {})
            };
        }

        /* ============================================================
        10. htmlwidgets binding
        ============================================================ */

        return {
            renderValue: function (x) {
                x = x || {};
                el.safePivotX = x;

                $(el).addClass("safePivot-wrapper");
                applySafePivotSizingOptions(el, x);

                if (!window.jQuery || !$.pivotUtilities || !$.fn || !$.fn.pivotUI) {
                    safePivotShowDependencyError(
                        "safePivot dependency error: PivotTable.js or jQuery UI is not loaded.");
                    return;
                }

                var data = HTMLWidgets.dataframeToD3(x.data || []);
                var renderers = safePivotBuildRenderers();

                if (!renderers || Object.keys(renderers).length === 0) {
                    safePivotShowDependencyError(
                        "safePivot dependency error: no PivotTable.js renderers are available.");
                    return;
                }

                var resolvedRendererName = safePivotResolveRendererName(
                        x.renderer || "Table",
                        renderers);

                var aggregators = {};
                var aggregatorInfo = asArray(x.aggregator_info);

                if (aggregatorInfo.length === 0) {
                    safePivotShowDependencyError(
                        "safePivot error: no aggregator list was sent from R.");
                    return;
                }

                aggregatorInfo.forEach(function (spec) {
                    aggregators[spec.name] = makeAggregator(
                            spec,
                            getNumberOption(x.numeric_digits, 3),
                            x.missing_label);
                });

                var resolvedAggregatorName = resolveAggregatorName(
                        x.aggregator || "Median",
                        aggregators);

                var sorters = {};

                if (x.respect_factor_order && x.factor_levels) {
                    Object.keys(x.factor_levels).forEach(function (col) {
                        sorters[col] = makeSorter(x.factor_levels[col]);
                    });
                }

                var pivotOptions = {
                    rows: asArray(x.rows),
                    cols: asArray(x.cols),
                    vals: asArray(x.vals),
                    aggregatorName: resolvedAggregatorName,
                    rendererName: resolvedRendererName,
                    aggregators: aggregators,
                    renderers: renderers,
                    sorters: sorters,
                    rendererOptions: makeRendererOptions(x),
                    inclusions: cleanFilters(x.inclusions),
                    exclusions: cleanFilters(x.exclusions),

                    unusedAttrsVertical: x.unused_attrs_vertical === true,

                    onRefresh: function (config) {
                        var currentRendererName =
                            config && config.rendererName ? config.rendererName : resolvedRendererName;

                        el.safePivotLastConfig = cleanConfig(config);
                        el.safePivotLastRenderer = currentRendererName;

                        applySafePivotRendererModeClass(el, currentRendererName);
                        applyFormattingSoon(el, x, currentRendererName);
                        applySafePivotTypeBadges(el, x);

                        setTimeout(function () {
                            safePivotResizePlotly(el, x);
                        }, 50);

                        if (HTMLWidgets.shinyMode && window.Shiny && el.id) {
                            Shiny.setInputValue(el.id + "_config", cleanConfig(config), {
                                priority: "event"
                            });
                        }
                    }
                };

                try {
                    $(el).empty().pivotUI(data, pivotOptions, true);
                } catch (e) {
                    safePivotShowDependencyError(
                        "safePivot rendering failed: " + (e && e.message ? e.message : e));
                    safePivotWarn("safePivot rendering failed:", e);
                    return;
                }

                el.safePivotLastConfig = cleanConfig({
                    rows: asArray(x.rows),
                    cols: asArray(x.cols),
                    vals: asArray(x.vals),
                    aggregatorName: resolvedAggregatorName,
                    rendererName: resolvedRendererName,
                    inclusions: x.inclusions,
                    exclusions: x.exclusions
                });
                el.safePivotLastRenderer = resolvedRendererName;

                applySafePivotRendererModeClass(el, resolvedRendererName);
                applyFormattingSoon(el, x, resolvedRendererName);
                applySafePivotTypeBadges(el, x);
                safePivotSetupResizeObserver(el, x);

                setTimeout(function () {
                    safePivotResizePlotly(el, x);
                }, 80);
            },

            resize: function () {
                /*
                The Shiny output height is the whole widget, not the chart, so it
                is not used for the Plotly height.
                 */
                // Re-measure with the user's own options (fonts, plot sizes,
                // plotly_layout) rather than a bare object.
                safePivotResizePlotly(el, el.safePivotX || {});
            }
        };
    }
});