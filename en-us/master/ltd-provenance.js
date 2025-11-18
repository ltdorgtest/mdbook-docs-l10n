"use strict";

/**
 * Creates and injects a dropdown-style provenance dropdown box into the page.
 * The dropdown box is collapsed by default and can be expanded by clicking on it.
 */
function createProvenanceDropdown() {
  // 1. Define the HTML and CSS as template literals.
  const flyoutHTML = `
    <details class="provenance-dropdown">
      <summary class="provenance-summary"><strong>Provenance</strong></summary>
      <div class="provenance-content">
        The translation is community-driven. If you find any inaccuracies, always refer to the <a href="https://rust-lang.github.io/mdBook">official documentation</a> or the <a href="https://github.com/rust-lang/mdBook">source repository</a> of the upstream project for the most reliable information.
      </div>
    </details>
  `;

  const flyoutCSS = `
    /* Styles for the main dropdown container */
    details.provenance-dropdown {
      color: #ffffff !important;
      background-color: #263238 !important;
      border: none !important;
      box-shadow: 0 4px 10px #000000;
      font-family: Arial, sans-serif;
      font-size: 15px;
      line-height: 20px;
      padding: 15px;
      margin-bottom: 20px;
      border-radius: 5px;
    }

    /* Styles for the summary (the clickable header) */
    .provenance-summary {
      color: #27ae60 !important;
      background-color: #263238 !important;
      cursor: pointer;
      list-style: none; /* Hide the default dropdown arrow */
      font-weight: bold;
    }

    /* Re-add a custom arrow/icon for the dropdown */
    .provenance-summary::before {
      content: "▼"; /* Downward arrow */
      color: #27ae60 !important;
      display: inline-block;
      margin-right: 10px;
      transition: transform 0.2s ease;
    }

    /* Rotate the arrow when the dropdown is open */
    .provenance-dropdown[open] .provenance-summary::before {
      transform: rotate(-180deg);
    }

    /* Styling for the content of the dropdown */
    .provenance-content {
      color: #ffffff !important;
      background-color: #263238 !important;
      line-height: 24px;
      padding-top: 10px; /* Add some space between the summary and content */
    }

    .provenance-content a {
      color: #27ae60 !important;
      background-color: #263238 !important;
      text-decoration: underline;
      transition: color 0.3s;
      display: inline-block;
    }

    .provenance-content a:hover {
      color: #ffffff !important;
      background-color: #263238 !important;
    }

    /* Remove padding and margin from summary */
    .provenance-summary::-webkit-details-marker,
    .provenance-summary::marker {
      display: none;
    }
  `;

  // 2. Create and append the <style> element to the document head.
  const styleTag = document.createElement('style');
  styleTag.innerHTML = flyoutCSS;
  document.head.appendChild(styleTag);

  // 3. Create the HTML element and insert it into the page.
  const tempDiv = document.createElement('div');
  tempDiv.innerHTML = flyoutHTML.trim();
  const dropdownBox = tempDiv.firstChild;

  const mainContent = document.querySelector('main');
  if (mainContent) {
    mainContent.prepend(dropdownBox);
  } else {
    document.body.prepend(dropdownBox);
  }
}

document.addEventListener("DOMContentLoaded", createProvenanceDropdown);
