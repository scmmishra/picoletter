import { Controller } from "@hotwired/stimulus";

export default class extends Controller {
  static targets = ["localInput", "epochInput"];
  static values = {
    epochMs: Number,
    format: { type: String, default: "datetime" }
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

    const options = this.defaultFormatOptions();

    if (options.timeZoneName) {
      this.renderWithParts(date, options);
      return;
    }

    this.element.textContent = this.formatDate(date, options);
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
        return { hour: "numeric", minute: "2-digit", hour12: true, timeZoneName: "shortOffset" };
      case "datetime":
      default:
        return { year: "numeric", month: "short", day: "numeric", hour: "numeric", minute: "2-digit", hour12: true };
    }
  }

  renderWithParts(date, options) {
    const formattedParts = this.formatParts(date, options);

    if (!formattedParts) {
      this.element.textContent = this.formatDate(date, options);
      return;
    }

    this.element.replaceChildren();

    formattedParts.forEach((part) => {
      if (part.type === "timeZoneName") {
        const zoneNode = document.createElement("span");
        zoneNode.className = "text-stone-500";
        zoneNode.textContent = part.value;
        this.element.appendChild(zoneNode);
      } else {
        this.element.appendChild(document.createTextNode(part.value));
      }
    });
  }

  formatDate(date, options) {
    try {
      return new Intl.DateTimeFormat(undefined, options).format(date);
    } catch (error) {
      if (!options.timeZoneName) {
        return date.toISOString();
      }

      const fallbackOptions = { ...options };
      delete fallbackOptions.timeZoneName;
      return new Intl.DateTimeFormat(undefined, fallbackOptions).format(date);
    }
  }

  formatParts(date, options) {
    try {
      return new Intl.DateTimeFormat(undefined, options).formatToParts(date);
    } catch (error) {
      if (!options.timeZoneName) return null;

      const fallbackOptions = { ...options };
      delete fallbackOptions.timeZoneName;
      return new Intl.DateTimeFormat(undefined, fallbackOptions).formatToParts(date);
    }
  }
}
