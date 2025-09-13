/**
 * Creates and injects a permanent provenance notification box into the mdbook page.
 * The notification box is a dropdown that expands to show more information.
 */
function createProvenanceNotification() {
  // Check if the element already exists to prevent duplication on hot-reload
  if (document.querySelector('.provenance-dropdown')) {
    return;
  }

  // 1. Define the HTML and CSS as template literals.
  const flyoutHTML = `
    <strong>
      <details class="provenance-dropdown" open>
        <summary class="provenance-summary">Provenance</summary>
        <div class="provenance-content">
          The translation is community-driven. If you find any inaccuracies, always refer to the <a href="https://docs.python.org/">official documentation</a> or the <a href="https://github.com/python/cpython">source repository</a> of the upstream project for the most reliable information.
        </div>
      </details>
    </strong>
  `;

  const flyoutCSS = `
    /* Styles for the main dropdown container */
    .provenance-dropdown {
      background-color: #d1ecf1; /* Light blue background */
      border: 1px solid #c8e5e8; /* Light blue border */
      color: #0c5460; /* Dark blue text */
      padding: 15px 20px;
      margin-bottom: 20px;
      border-radius: 4px;
      box-shadow: 0 2px 5px rgba(0, 0, 0, 0.1);
    }

    /* Styles for the summary (the clickable header) */
    .provenance-summary {
      font-size: 15px;
      line-height: 1.6;
      cursor: pointer;
      list-style: none; /* Hide the default dropdown arrow */
    }

    /* Re-add a custom arrow/icon for the dropdown */
    .provenance-summary::before {
      content: "▲"; /* Upward arrow */
      display: inline-block;
      margin-right: 10px;
      font-size: 0.8em;
      transition: transform 0.2s ease;
    }

    /* Rotate the arrow when the dropdown is open */
    .provenance-dropdown[open] .provenance-summary::before {
      transform: rotate(-180deg);
    }

    /* Styling for the content of the dropdown */
    .provenance-content {
      padding-top: 10px; /* Add some space between the summary and content */
    }

    /* Links inside the dropdown */
    .provenance-dropdown a {
      color: #007bff;
      text-decoration: none;
    }

    .provenance-dropdown a:hover {
      text-decoration: underline;
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
  const notificationBox = tempDiv.firstChild;

  // Find the first h1 or h2 on the page
  const pageTitle = document.querySelector('.content h1, .content h2');
  if (pageTitle) {
    pageTitle.after(notificationBox);
  } else {
    // Fallback to the top of the content area if no h1 or h2 is found
    const mainContent = document.getElementById('content');
    if (mainContent) {
      mainContent.prepend(notificationBox);
    } else {
      document.body.prepend(notificationBox);
    }
  }
}

// Wait for the DOM to be fully loaded before creating the notification box.
document.addEventListener("DOMContentLoaded", createProvenanceNotification);
