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

        function normalizeAggregatorName(type) {
            if (type === "Missing %")
                return "Missing % within Cell";
            if (type === "Non-missing %")
                return "Non-missing % within Cell";
            return type;
        }

        function defaultAggregatorNames() {
            return [
                "Count",
                "Count unique",
                "List unique values",
                "N missing",
                "N non-missing",
                "Missing % within Cell",
                "Non-missing % within Cell",
                "Missing % of Row",
                "Missing % of Column",
                "Missing % of Total",
                "Non-missing % of Row",
                "Non-missing % of Column",
                "Non-missing % of Total",
                "N zero",
                "N non-zero",
                "Zero % within Cell",
                "Non-zero % within Cell",
                "Zero % of Row",
                "Zero % of Column",
                "Zero % of Total",
                "Non-zero % of Row",
                "Non-zero % of Column",
                "Non-zero % of Total",
                "Sum",
                "Mean",
                "Median",
                "Min",
                "Max",
                "Range",
                "Q1",
                "Q3",
                "IQR",
                "Variance",
                "SD",
                "SE",
                "CV %",
                "Sum as Fraction of Total",
                "Sum as Fraction of Rows",
                "Sum as Fraction of Columns",
                "Count as Fraction of Total",
                "Count as Fraction of Rows",
                "Count as Fraction of Columns"
            ];
        }

        function needsValue(type) {
            type = normalizeAggregatorName(type);

            return ![
                "Count",
                "Count as Fraction of Total",
                "Count as Fraction of Rows",
                "Count as Fraction of Columns"
            ].includes(type);
        }

        function isFractionAggregator(type) {
            type = normalizeAggregatorName(type);

            return [
                "Sum as Fraction of Total",
                "Sum as Fraction of Rows",
                "Sum as Fraction of Columns",
                "Count as Fraction of Total",
                "Count as Fraction of Rows",
                "Count as Fraction of Columns"
            ].includes(type);
        }

        function isContextPercentAggregator(type) {
            type = normalizeAggregatorName(type);

            return [
                "Missing % of Row",
                "Missing % of Column",
                "Missing % of Total",
                "Non-missing % of Row",
                "Non-missing % of Column",
                "Non-missing % of Total",
                "Zero % of Row",
                "Zero % of Column",
                "Zero % of Total",
                "Non-zero % of Row",
                "Non-zero % of Column",
                "Non-zero % of Total"
            ].includes(type);
        }

        function isWithinCellPercentAggregator(type) {
            type = normalizeAggregatorName(type);

            return [
                "Missing % within Cell",
                "Non-missing % within Cell",
                "Zero % within Cell",
                "Non-zero % within Cell"
            ].includes(type);
        }

        function isIntegerLikeAggregator(type) {
            type = normalizeAggregatorName(type);

            return [
                "Count",
                "Count unique",
                "N non-missing",
                "N missing",
                "N zero",
                "N non-zero"
            ].includes(type);
        }

        function isPercent100Aggregator(type) {
            type = normalizeAggregatorName(type);

            return (
                type === "CV %" ||
                isWithinCellPercentAggregator(type) ||
                isContextPercentAggregator(type));
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

        function percent100(num, den) {
            num = Number(num);
            den = Number(den);

            if (!Number.isFinite(num) || !Number.isFinite(den) || den === 0) {
                return null;
            }

            return 100 * num / den;
        }

        function getSafeCountMethod(agg, methodName) {
            if (!agg || typeof agg[methodName] !== "function")
                return null;

            var value = agg[methodName]();
            return Number.isFinite(Number(value)) ? Number(value) : null;
        }

        function numericAggregator(type, digits, missingLabel) {
            var displayType = type;
            type = normalizeAggregatorName(type);

            var nInputs = needsValue(type) ? 1 : 0;

            var generator = function (attrs) {
                attrs = attrs || [];
                var attr = attrs.length ? attrs[0] : null;

                var aggregator = function (data, rowKey, colKey) {
                    return {
                        values: [],
                        rawValues: [],
                        countAll: 0,
                        countMissing: 0,
                        countNonMissing: 0,
                        countNumeric: 0,
                        countZero: 0,
                        countNonZero: 0,
                        numInputs: nInputs,

                        push: function (record) {
                            this.countAll += 1;

                            if (!attr)
                                return;

                            var raw = record[attr];
                            this.rawValues.push(raw);

                            if (isMissingDataValue(raw, missingLabel)) {
                                this.countMissing += 1;
                                return;
                            }

                            this.countNonMissing += 1;

                            var v = cleanNumber(raw);

                            if (v !== null) {
                                this.values.push(v);
                                this.countNumeric += 1;

                                if (v === 0) {
                                    this.countZero += 1;
                                } else {
                                    this.countNonZero += 1;
                                }
                            }
                        },

                        allN: function () {
                            return this.countAll;
                        },

                        missingN: function () {
                            return this.countMissing;
                        },

                        nonMissingN: function () {
                            return this.countNonMissing;
                        },

                        numericN: function () {
                            return this.countNumeric;
                        },

                        zeroN: function () {
                            return this.countZero;
                        },

                        nonZeroN: function () {
                            return this.countNonZero;
                        },

                        baseValue: function () {
                            var v = this.values;
                            var n = v.length;

                            if (
                                type === "Count" ||
                                type === "Count as Fraction of Total" ||
                                type === "Count as Fraction of Rows" ||
                                type === "Count as Fraction of Columns") {
                                return this.countAll;
                            }

                            if (type === "Count unique") {
                                var seen = {};

                                this.rawValues.forEach(function (x) {
                                    if (!isMissingDataValue(x, missingLabel)) {
                                        seen[String(x)] = true;
                                    }
                                });

                                return Object.keys(seen).length;
                            }

                            if (type === "List unique values") {
                                var seenList = {};

                                this.rawValues.forEach(function (x) {
                                    if (!isMissingDataValue(x, missingLabel)) {
                                        seenList[String(x)] = true;
                                    }
                                });

                                return Object.keys(seenList).sort().join(", ");
                            }

                            if (type === "N non-missing")
                                return this.countNonMissing;
                            if (type === "N missing")
                                return this.countMissing;

                            if (type === "Non-missing % within Cell") {
                                return percent100(this.countNonMissing, this.countAll);
                            }

                            if (type === "Missing % within Cell") {
                                return percent100(this.countMissing, this.countAll);
                            }

                            if (type === "N zero")
                                return this.countZero;
                            if (type === "N non-zero")
                                return this.countNonZero;

                            if (type === "Zero % within Cell") {
                                return percent100(this.countZero, this.countNumeric);
                            }

                            if (type === "Non-zero % within Cell") {
                                return percent100(this.countNonZero, this.countNumeric);
                            }

                            if (n === 0)
                                return null;

                            if (
                                type === "Sum" ||
                                type === "Sum as Fraction of Total" ||
                                type === "Sum as Fraction of Rows" ||
                                type === "Sum as Fraction of Columns") {
                                return v.reduce(function (a, b) {
                                    return a + b;
                                }, 0);
                            }

                            if (type === "Mean") {
                                return v.reduce(function (a, b) {
                                    return a + b;
                                }, 0) / n;
                            }

                            if (
                                type === "Median" ||
                                type === "Q1" ||
                                type === "Q3" ||
                                type === "IQR") {
                                var sorted = v.slice().sort(function (a, b) {
                                    return a - b;
                                });

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
                                var q2 = quantile(sorted, 0.5);
                                var q3 = quantile(sorted, 0.75);

                                if (type === "Median")
                                    return q2;
                                if (type === "Q1")
                                    return q1;
                                if (type === "Q3")
                                    return q3;
                                if (type === "IQR")
                                    return q3 - q1;
                            }

                            if (type === "Min")
                                return Math.min.apply(null, v);
                            if (type === "Max")
                                return Math.max.apply(null, v);
                            if (type === "Range")
                                return Math.max.apply(null, v) - Math.min.apply(null, v);

                            if (
                                type === "Variance" ||
                                type === "SD" ||
                                type === "SE" ||
                                type === "CV %") {
                                if (n < 2)
                                    return null;

                                var mean = v.reduce(function (a, b) {
                                    return a + b;
                                }, 0) / n;

                                var ss = v.reduce(function (a, b) {
                                    return a + Math.pow(b - mean, 2);
                                }, 0);

                                var variance = ss / (n - 1);
                                var sd = Math.sqrt(variance);

                                if (type === "Variance")
                                    return variance;
                                if (type === "SD")
                                    return sd;
                                if (type === "SE")
                                    return sd / Math.sqrt(n);
                                if (type === "CV %")
                                    return mean === 0 ? null : 100 * sd / mean;
                            }

                            return null;
                        },

                        contextNumerator: function () {
                            if (
                                type === "Missing % of Row" ||
                                type === "Missing % of Column" ||
                                type === "Missing % of Total") {
                                return this.countMissing;
                            }

                            if (
                                type === "Non-missing % of Row" ||
                                type === "Non-missing % of Column" ||
                                type === "Non-missing % of Total") {
                                return this.countNonMissing;
                            }

                            if (
                                type === "Zero % of Row" ||
                                type === "Zero % of Column" ||
                                type === "Zero % of Total") {
                                return this.countZero;
                            }

                            if (
                                type === "Non-zero % of Row" ||
                                type === "Non-zero % of Column" ||
                                type === "Non-zero % of Total") {
                                return this.countNonZero;
                            }

                            return null;
                        },

                        contextDenominator: function () {
                            var denomAgg = null;

                            if (
                                type === "Missing % of Row" ||
                                type === "Non-missing % of Row" ||
                                type === "Zero % of Row" ||
                                type === "Non-zero % of Row") {
                                denomAgg = data.getAggregator(rowKey, []);
                            }

                            if (
                                type === "Missing % of Column" ||
                                type === "Non-missing % of Column" ||
                                type === "Zero % of Column" ||
                                type === "Non-zero % of Column") {
                                denomAgg = data.getAggregator([], colKey);
                            }

                            if (
                                type === "Missing % of Total" ||
                                type === "Non-missing % of Total" ||
                                type === "Zero % of Total" ||
                                type === "Non-zero % of Total") {
                                denomAgg = data.getAggregator([], []);
                            }

                            if (!denomAgg)
                                return null;

                            if (
                                type === "Missing % of Row" ||
                                type === "Missing % of Column" ||
                                type === "Missing % of Total" ||
                                type === "Non-missing % of Row" ||
                                type === "Non-missing % of Column" ||
                                type === "Non-missing % of Total") {
                                return getSafeCountMethod(denomAgg, "allN");
                            }

                            if (
                                type === "Zero % of Row" ||
                                type === "Zero % of Column" ||
                                type === "Zero % of Total" ||
                                type === "Non-zero % of Row" ||
                                type === "Non-zero % of Column" ||
                                type === "Non-zero % of Total") {
                                return getSafeCountMethod(denomAgg, "numericN");
                            }

                            return null;
                        },

                        value: function () {
                            if (isContextPercentAggregator(type)) {
                                return percent100(this.contextNumerator(), this.contextDenominator());
                            }

                            if (!isFractionAggregator(type)) {
                                return this.baseValue();
                            }

                            var numerator = this.baseValue();
                            var denomAgg = null;

                            if (
                                type === "Sum as Fraction of Total" ||
                                type === "Count as Fraction of Total") {
                                denomAgg = data.getAggregator([], []);
                            }

                            if (
                                type === "Sum as Fraction of Rows" ||
                                type === "Count as Fraction of Rows") {
                                denomAgg = data.getAggregator(rowKey, []);
                            }

                            if (
                                type === "Sum as Fraction of Columns" ||
                                type === "Count as Fraction of Columns") {
                                denomAgg = data.getAggregator([], colKey);
                            }

                            if (!denomAgg || typeof denomAgg.baseValue !== "function")
                                return null;

                            var denominator = denomAgg.baseValue();

                            if (
                                denominator === null ||
                                denominator === undefined ||
                                Number(denominator) === 0) {
                                return null;
                            }

                            return numerator / denominator;
                        },

                        format: function (x) {
                            if (x === null || x === undefined)
                                return "";

                            if (type === "List unique values")
                                return String(x);
                            if (isFractionAggregator(type))
                                return formatPercentFraction(x);
                            if (isPercent100Aggregator(type))
                                return formatPercent100(x);
                            if (isIntegerLikeAggregator(type))
                                return String(x);

                            return formatNumber(x, digits);
                        }
                    };
                };

                aggregator.numInputs = nInputs;
                aggregator.displayName = displayType;

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

        function safePivotCleanAttrText(text) {
            if (text === null || text === undefined)
                return "";

            return String(text)
            .replace(/[\u25BE\u25B4\u25BC\u25B2\u2195\u2194\u2191\u2193]/g, " ")
            .replace(/\s+/g, " ")
            .trim();
        }

        function safePivotVariableNames(variableTypes) {
            if (!variableTypes)
                return [];

            return Object.keys(variableTypes).sort(function (a, b) {
                return b.length - a.length;
            });
        }

        function safePivotResolveVariableName(pill, variableTypes) {
            var names = safePivotVariableNames(variableTypes);

            if (names.length === 0)
                return null;

            var text = pill
                .clone()
                .find(".safePivot-type-badge")
                .remove()
                .end()
                .text();

            text = safePivotCleanAttrText(text);

            if (!text)
                return null;

            for (var i = 0; i < names.length; i++) {
                if (text === names[i])
                    return names[i];
            }

            for (var j = 0; j < names.length; j++) {
                if (text.indexOf(names[j]) >= 0)
                    return names[j];
            }

            return null;
        }

        function applySafePivotTypeBadgesNow(el, x) {
            if (!x || x.show_type_badges === false || !x.variable_types)
                return;

            var variableTypes = x.variable_types;

            $(el)
            .find(
                [
                    "table.pvtUi li.pvtAttr",
                    "table.pvtUi td.pvtAxisContainer li",
                    "table.pvtUi td.pvtUnused li"
                ].join(", "))
            .each(function () {
                var pill = $(this);

                pill.find(".safePivot-type-badge").remove();

                var variableName = safePivotResolveVariableName(pill, variableTypes);

                if (!variableName || !variableTypes[variableName])
                    return;

                var info = variableTypes[variableName];
                var type = info.type || "obj";
                var badgeText = safePivotTypeBadgeText(type);
                var badgeClass = safePivotTypeBadgeClass(type);
                var titleText = safePivotTypeBadgeTitle(info);

                var badge = $("<span/>")
                    .addClass("safePivot-type-badge")
                    .addClass(badgeClass)
                    .attr("title", titleText)
                    .attr("aria-label", titleText)
                    .text(badgeText);

                pill.append(badge);
            });
        }

        function applySafePivotTypeBadges(el, x) {
            setTimeout(function () {
                applySafePivotTypeBadgesNow(el, x);
            }, 0);

            setTimeout(function () {
                applySafePivotTypeBadgesNow(el, x);
            }, 80);
        }

        /* ============================================================
        5. Shiny config cleaning
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

            $el.removeClass("safePivot-table-mode safePivot-plotly-mode");

            if (isSafePivotPlotlyRenderer(rendererName)) {
                $el.addClass("safePivot-plotly-mode");
            } else {
                $el.addClass("safePivot-table-mode");
            }
        }

        function applySafePivotSizingOptions(el, x) {
            x = x || {};

            var uiFontSize = getNumberOption(x.ui_font_size, 16);
            var pillFontSize = getNumberOption(x.pill_font_size, 17);
            var tableFontSize = getNumberOption(x.table_font_size, 18);
            var badgeFontSize = getNumberOption(x.badge_font_size, 12);

            $(el).css("--safePivot-ui-font-size", uiFontSize + "px");
            $(el).css("--safePivot-pill-font-size", pillFontSize + "px");
            $(el).css("--safePivot-table-font-size", tableFontSize + "px");
            $(el).css("--safePivot-badge-font-size", badgeFontSize + "px");
        }

        function safePivotResetPanelHeights(el) {
            var $el = $(el);

            $el.find("td.pvtRows, td.pvtCols, td.pvtVals, td.pvtUnused").css({
                minHeight: "",
                height: ""
            });
        }

        function safePivotSyncPanelHeights(el, rendererName) {
            var $el = $(el);

            safePivotResetPanelHeights(el);

            /*
             * Do not force the left blue row panel to match Plotly height.
             * In chart mode the chart size should control the display, otherwise
             * the pivot panels become unnecessarily tall and the page scrolls.
             */
            if (isSafePivotPlotlyRenderer(rendererName)) {
                return;
            }

            var $rowsPanel = $el.find("td.pvtRows");
            var $colsPanel = $el.find("td.pvtCols");
            var $valsPanel = $el.find("td.pvtVals");
            var $unusedPanel = $el.find("td.pvtUnused");
            var $rendererArea = $el.find("td.pvtRendererArea, .pvtRendererArea").first();
            var $table = $el.find("table.pvtTable").first();
            var $plot = $el.find(".js-plotly-plot").first();

            var targetHeight = 0;

            if (isSafePivotPlotlyRenderer(rendererName) && $plot.length) {
                targetHeight = $plot.outerHeight() || 0;
            } else if ($table.length) {
                targetHeight = $table.outerHeight() || 0;
            } else if ($rendererArea.length) {
                targetHeight = $rendererArea.outerHeight() || 0;
            }

            if (targetHeight <= 0)
                return;

            /* left row panel should match result area height */
            if ($rowsPanel.length) {
                $rowsPanel.css("min-height", targetHeight + "px");
            }

            /* top panels should at least look balanced */
            var topTarget = Math.max(
                    $unusedPanel.outerHeight() || 0,
                    $colsPanel.outerHeight() || 0,
                    $valsPanel.outerHeight() || 0);

            if (topTarget > 0) {
                $colsPanel.css("min-height", topTarget + "px");
                $valsPanel.css("min-height", topTarget + "px");
                $unusedPanel.css("min-height", topTarget + "px");
            }
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

            var cells = $(el).find("table.pvtTable tbody td");
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
                    cell.addClass("safePivot-cell-empty safePivot-cell-missing");
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
            var $rendererTd = $el.find("td.pvtRendererArea").first();
            var $rendererArea = $el.find(".pvtRendererArea").first();

            var explicitWidth = Number(x.plot_width);
            var explicitHeight = Number(x.plot_height);

            var availableWidth =
                $rendererTd.innerWidth() ||
                $rendererArea.innerWidth() ||
                $el.innerWidth() ||
                width ||
                900;

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
            Math.min(availableWidth - 24, maxPlotWidth);

            var finalHeight =
                (Number.isFinite(explicitHeight) && explicitHeight > 0 ? explicitHeight : 0) ||
            defaultPlotHeight;

            return {
                width: Math.max(500, Math.floor(finalWidth)),
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
                .css({
                    padding: "1rem",
                    border: "1px solid #ddd",
                    borderRadius: "8px",
                    background: "#fff7f7",
                    color: "#7f1d1d",
                    fontFamily: "sans-serif"
                })
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
                var allowedAggregators = asArray(x.allowed_aggregators);

                if (allowedAggregators.length === 0) {
                    allowedAggregators = defaultAggregatorNames();
                }

                allowedAggregators.forEach(function (name) {
                    aggregators[name] = numericAggregator(
                            name,
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

                    onRefresh: function (config) {
                        var currentRendererName =
                            config && config.rendererName ? config.rendererName : resolvedRendererName;

                        el.safePivotLastConfig = cleanConfig(config);
                        el.safePivotLastRenderer = currentRendererName;

                        applySafePivotRendererModeClass(el, currentRendererName);
                        applyFormattingSoon(el, x, currentRendererName);
                        applySafePivotTypeBadges(el, x);

                        setTimeout(function () {
                            safePivotSyncPanelHeights(el, currentRendererName);
                        }, 20);

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
                    rendererName: resolvedRendererName
                });
                el.safePivotLastRenderer = resolvedRendererName;

                applySafePivotRendererModeClass(el, resolvedRendererName);
                applyFormattingSoon(el, x, resolvedRendererName);
                applySafePivotTypeBadges(el, x);
                safePivotSetupResizeObserver(el, x);

                setTimeout(function () {
                    safePivotSyncPanelHeights(el, resolvedRendererName);
                }, 20);

                setTimeout(function () {
                    safePivotResizePlotly(el, x);
                }, 80);
            },

            resize: function (outputWidth, outputHeight) {
                /*
                Important:
                Do not pass outputHeight into plot_height.
                Shiny output height is the whole widget height, not the desired Plotly
                inner chart height.
                 */
                safePivotResizePlotly(el, {
                    plot_width: outputWidth
                });

                var rendererName = $(el).find(".pvtRenderer").val() || "Table";

                if (!isSafePivotPlotlyRenderer(rendererName)) {
                    setTimeout(function () {
                        safePivotSyncPanelHeights(el, rendererName);
                    }, 30);
                }
            }
        };
    }
});