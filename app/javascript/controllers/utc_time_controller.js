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

    const formatter = new Intl.DateTimeFormat(this.localeOrUndefined(), {
      ...formatOptions,
      ...customOptions
    });

    this.element.textContent = formatter.format(date);
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
        return { hour: "numeric", minute: "2-digit" };
      case "datetime":
      default:
        return { year: "numeric", month: "short", day: "numeric", hour: "numeric", minute: "2-digit" };
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
}
