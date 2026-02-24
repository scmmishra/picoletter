import { Controller } from "@hotwired/stimulus";

let shikiPromise = null;

function loadShiki() {
  if (!shikiPromise) {
    shikiPromise = import("https://esm.sh/shiki@3.22.0");
  }
  return shikiPromise;
}

export default class extends Controller {
  static targets = ["tab", "container", "copy"]
  static values = {
    samples: Array,
    active: { type: Number, default: 0 },
  }

  connect() {
    this.highlight(this.samplesValue[this.activeValue]);
  }

  switchTab(event) {
    const index = this.tabTargets.indexOf(event.currentTarget);
    this.select(index);
  }

  select(index) {
    this.activeValue = index;
    const sample = this.samplesValue[index];

    this.tabTargets.forEach((tab, i) => {
      tab.classList.toggle("bg-stone-200", i === index);
      tab.classList.toggle("text-stone-800", i === index);
      tab.classList.toggle("text-stone-400", i !== index);
    });

    if (this.hasCopyTarget) {
      const copyBtn = this.copyTarget.querySelector("[data-copy-to-clipboard-content-value]");
      if (copyBtn) copyBtn.dataset.copyToClipboardContentValue = sample.code;
    }

    this.showFallback(sample.code);
    this.highlight(sample);
  }

  showFallback(code) {
    const pre = document.createElement("pre");
    pre.className = "px-3 py-2 text-xs fallback-code overflow-hidden font-mono";
    pre.textContent = code;
    this.containerTarget.replaceChildren(pre);
  }

  async highlight(sample) {
    try {
      const { codeToHtml } = await loadShiki();
      // NOTE: innerHTML usage is intentional for Shiki syntax highlighting of trusted, server-rendered content
      this.containerTarget.innerHTML = await codeToHtml(sample.code, {
        lang: sample.lang,
        theme: "github-light",
      });
    } catch (error) {
      // fallback pre is already showing
    }
  }
}
