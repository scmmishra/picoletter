import { Controller } from "@hotwired/stimulus";

export default class extends Controller {
  static targets = ["localInput", "epochInput"];
  static values = {
    epochMs: Number,
    format: { type: String, default: "datetime" },
    options: { type: String, default: "" },
    locale: String
  };

  connect() {
    if (this.hasLocalInputTarget && this.hasEpochInputTarget) {
      this.syncEpoch();
      return;
    }

    this.renderLocalTime();
  }

  syncEpoch() {
    const localValue = this.localInputTarget.value;
    if (!localValue) {
      this.epochInputTarget.value = "";
      return;
    }

    const localDate = new Date(localValue);
    if (Number.isNaN(localDate.getTime())) {
      this.epochInputTarget.value = "";
      return;
    }

    this.epochInputTarget.value = String(localDate.getTime());
  }

  renderLocalTime() {
    if (!this.hasEpochMsValue) return;

    const date = new Date(this.epochMsValue);
    if (Number.isNaN(date.getTime())) return;

    const customOptions = this.parsedCustomOptions();
    const formatOptions = this.defaultFormatOptions();
    if (this.hasGranularDateTimeOptions(customOptions)) {
      delete formatOptions.dateStyle;
      delete formatOptions.timeStyle;
    }

    const options = {
      ...formatOptions,
      ...customOptions
    };

    this.element.textContent = this.formatWithFallback(date, options);
  }

  defaultFormatOptions() {
    switch (this.formatValue) {
      case "month":
        return { month: "short" };
      case "day":
        return { day: "numeric" };
      case "date":
        return { dateStyle: "long" };
      case "time":
        return { hour: "numeric", minute: "2-digit", hour12: true };
      case "datetime":
      default:
        return { year: "numeric", month: "short", day: "numeric", hour: "numeric", minute: "2-digit", hour12: true };
    }
  }

  parsedCustomOptions() {
    if (!this.optionsValue) return {};

    try {
      return JSON.parse(this.optionsValue);
    } catch (error) {
      return {};
    }
  }

  localeOrUndefined() {
    return this.hasLocaleValue ? this.localeValue : undefined;
  }

  hasGranularDateTimeOptions(options) {
    return [
      "weekday",
      "era",
      "year",
      "month",
      "day",
      "dayPeriod",
      "hour",
      "minute",
      "second",
      "fractionalSecondDigits",
      "timeZoneName"
    ].some((key) => Object.prototype.hasOwnProperty.call(options, key));
  }

  formatWithFallback(date, options) {
    try {
      return new Intl.DateTimeFormat(this.localeOrUndefined(), options).format(date);
    } catch (error) {
      if (!Object.prototype.hasOwnProperty.call(options, "timeZoneName")) {
        return date.toISOString();
      }

      const fallbackOptions = { ...options };
      delete fallbackOptions.timeZoneName;
      return new Intl.DateTimeFormat(this.localeOrUndefined(), fallbackOptions).format(date);
    }
  }
}
