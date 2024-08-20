// app/javascript/controllers/import_subscribers_controller.js
import { Controller } from "@hotwired/stimulus";

const activeClass = ["bg-blue-100", "border-blue-200", "text-blue-500"];
const inactiveClass = ["bg-stone-100", "border-stone-200", "text-stone-500"];

const toggleClasses = (element, isActive) => {
  element.classList.add(...(isActive ? activeClass : inactiveClass));
  element.classList.remove(...(isActive ? inactiveClass : activeClass));
};

export default class extends Controller {
  static targets = [
    "dropzone",
    "fileInput",
    "fileInfo",
    "fileName",
    "dropzoneContent",
  ];

  dragover(event) {
    event.preventDefault();
    toggleClasses(this.dropzoneTarget, true);
  }

  dragenter(event) {
    event.preventDefault();
    toggleClasses(this.dropzoneTarget, true);
  }

  dragleave(event) {
    event.preventDefault();
    toggleClasses(this.dropzoneTarget, false);
  }

  drop(event) {
    event.preventDefault();
    toggleClasses(this.dropzoneTarget, false);
    this.handleFiles(event.dataTransfer.files);
  }

  click(event) {
    this.fileInputTarget.click();
  }

  handleChange(event) {
    event.preventDefault();
    event.stopPropagation();
    this.handleFiles(event.target.files);
  }

  handleFiles(files) {
    if (files.length > 0) {
      const file = files[0];
      if (file.type === "text/csv") {
        console.log("CSV file selected:", file.name);
        this.showFileInfo(file.name);
      } else {
        alert("Please select a CSV file.");
      }
    }
  }

  showFileInfo(fileName) {
    this.fileNameTarget.textContent = fileName;
    this.dropzoneContentTarget.classList.add("hidden");
    this.fileInfoTarget.classList.remove("hidden");
  }

  removeFile(event) {
    event.preventDefault();
    event.stopPropagation();
    this.fileInputTarget.value = "";
    this.dropzoneContentTarget.classList.remove("hidden");
    this.fileInfoTarget.classList.add("hidden");
  }
}
