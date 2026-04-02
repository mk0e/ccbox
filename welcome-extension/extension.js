const vscode = require("vscode");

function activate(context) {
  const cmd = vscode.commands.registerCommand("ccbox.welcome", () => {
    showWelcome(context);
  });
  context.subscriptions.push(cmd);

  // Auto-show on startup
  showWelcome(context);

  // Open Claude Code sidebar after a short delay to let it activate
  setTimeout(() => {
    vscode.commands.executeCommand("claude-vscode.sidebar.open").then(
      () => {},
      () => {
        vscode.commands.executeCommand("claude-vscode.focus").catch(() => {});
      }
    );
  }, 2000);
}

function showWelcome(context) {
  const panel = vscode.window.createWebviewPanel(
    "ccboxWelcome",
    "Welcome to ccbox",
    vscode.ViewColumn.One,
    { enableScripts: true }
  );

  panel.webview.html = getHtml();

  panel.webview.onDidReceiveMessage((msg) => {
    if (msg.type === "start") {
      vscode.commands.executeCommand("claude-vscode.sidebar.open").then(
        () => {},
        () => {
          vscode.commands.executeCommand("claude-vscode.focus").catch(() => {});
        }
      );
      panel.dispose();
    } else if (msg.type === "copy") {
      vscode.env.clipboard.writeText(msg.text).then(() => {
        vscode.window.showInformationMessage("Copied to clipboard — paste it in the Claude Code chat");
      });
    }
  });
}

function getHtml() {
  return `<!DOCTYPE html>
<html lang="en">
<head>
<meta charset="UTF-8">
<meta name="viewport" content="width=device-width, initial-scale=1.0">
<style>
  * { margin: 0; padding: 0; box-sizing: border-box; }
  body {
    font-family: -apple-system, BlinkMacSystemFont, 'Segoe UI', Roboto, sans-serif;
    display: flex;
    align-items: center;
    justify-content: center;
    min-height: 100vh;
    background: var(--vscode-editor-background);
    color: var(--vscode-editor-foreground);
  }
  .container {
    max-width: 640px;
    padding: 2rem;
  }
  .header {
    text-align: center;
    margin-bottom: 2.5rem;
  }
  .logo {
    font-size: 3rem;
    font-weight: 700;
    letter-spacing: -0.02em;
  }
  .logo span {
    color: var(--vscode-textLink-foreground);
  }
  .subtitle {
    font-size: 1.1rem;
    color: var(--vscode-descriptionForeground);
    margin-top: 0.25rem;
  }
  .intro {
    font-size: 0.9rem;
    line-height: 1.6;
    color: var(--vscode-descriptionForeground);
    text-align: center;
    margin-bottom: 2rem;
  }
  .section-label {
    font-size: 0.8rem;
    text-transform: uppercase;
    letter-spacing: 0.08em;
    color: var(--vscode-descriptionForeground);
    margin-bottom: 0.75rem;
    font-weight: 600;
  }
  .examples {
    display: flex;
    flex-direction: column;
    gap: 0.5rem;
    margin-bottom: 2rem;
  }
  .example {
    display: flex;
    align-items: center;
    gap: 0.75rem;
    background: var(--vscode-input-background);
    border: 1px solid var(--vscode-input-border, transparent);
    border-radius: 8px;
    padding: 0.75rem 1rem;
    cursor: pointer;
    transition: border-color 0.15s, background 0.15s;
  }
  .example:hover {
    border-color: var(--vscode-textLink-foreground);
    background: var(--vscode-list-hoverBackground);
  }
  .example-icon {
    font-size: 1.25rem;
    flex-shrink: 0;
    width: 2rem;
    text-align: center;
  }
  .example-text {
    font-size: 0.85rem;
    flex-grow: 1;
  }
  .example-copy {
    font-size: 0.7rem;
    color: var(--vscode-descriptionForeground);
    opacity: 0;
    transition: opacity 0.15s;
    flex-shrink: 0;
  }
  .example:hover .example-copy {
    opacity: 1;
  }
  .start-btn {
    display: block;
    width: 100%;
    padding: 0.85rem;
    font-size: 0.95rem;
    font-weight: 600;
    border: none;
    border-radius: 8px;
    cursor: pointer;
    background: var(--vscode-button-background);
    color: var(--vscode-button-foreground);
    transition: background 0.15s;
    margin-bottom: 1.5rem;
  }
  .start-btn:hover {
    background: var(--vscode-button-hoverBackground);
  }
  .capabilities {
    display: grid;
    grid-template-columns: 1fr 1fr;
    gap: 0.5rem 1.5rem;
    margin-bottom: 1.5rem;
  }
  .capability {
    font-size: 0.8rem;
    color: var(--vscode-descriptionForeground);
    padding: 0.25rem 0;
  }
  .capability-icon {
    margin-right: 0.5rem;
  }
  .footer {
    text-align: center;
    font-size: 0.75rem;
    color: var(--vscode-descriptionForeground);
    opacity: 0.7;
  }
</style>
</head>
<body>
  <div class="container">
    <div class="header">
      <div class="logo">cc<span>box</span></div>
      <div class="subtitle">Your document workstation</div>
    </div>

    <p class="intro">
      Describe what you need in plain language. Claude will create
      professional documents for you — PDFs, presentations, spreadsheets,
      and Word documents.
    </p>

    <div class="section-label">Try something — click to copy, then paste in chat</div>
    <div class="examples">
      <div class="example" onclick="copy('Create a PDF report summarizing Q1 sales with charts and executive summary')">
        <div class="example-icon">\u{1F4C4}</div>
        <div class="example-text">Create a PDF report summarizing Q1 sales with charts and executive summary</div>
        <div class="example-copy">click to copy</div>
      </div>
      <div class="example" onclick="copy('Create a 10-slide pitch deck for a startup called Acme AI')">
        <div class="example-icon">\u{1F4CA}</div>
        <div class="example-text">Create a 10-slide pitch deck for a startup called Acme AI</div>
        <div class="example-copy">click to copy</div>
      </div>
      <div class="example" onclick="copy('Create an Excel budget tracker with monthly columns, formulas, and conditional formatting')">
        <div class="example-icon">\u{1F4CB}</div>
        <div class="example-text">Create an Excel budget tracker with monthly columns, formulas, and conditional formatting</div>
        <div class="example-copy">click to copy</div>
      </div>
      <div class="example" onclick="copy('Create a Word document for a project proposal with cover page and table of contents')">
        <div class="example-icon">\u{1F4DD}</div>
        <div class="example-text">Create a Word document for a project proposal with cover page and table of contents</div>
        <div class="example-copy">click to copy</div>
      </div>
    </div>

    <button class="start-btn" onclick="start()">Start creating</button>

    <div class="section-label">Built-in tools</div>
    <div class="capabilities">
      <div class="capability"><span class="capability-icon">\u{1F4C4}</span> PDF &mdash; create, edit, merge, OCR</div>
      <div class="capability"><span class="capability-icon">\u{1F4CA}</span> PPTX &mdash; slides & presentations</div>
      <div class="capability"><span class="capability-icon">\u{1F4CB}</span> XLSX &mdash; spreadsheets & formulas</div>
      <div class="capability"><span class="capability-icon">\u{1F4DD}</span> DOCX &mdash; documents & letters</div>
      <div class="capability"><span class="capability-icon">\u{1F3A8}</span> Design &mdash; posters & infographics</div>
      <div class="capability"><span class="capability-icon">\u{1F3AF}</span> Brand &mdash; consistent identity</div>
    </div>

    <div class="footer">
      Your files appear in the Explorer panel on the left. Use the Claude Code chat on the right to create and refine documents.
    </div>
  </div>
  <script>
    const vscode = acquireVsCodeApi();
    function copy(text) {
      vscode.postMessage({ type: 'copy', text });
    }
    function start() {
      vscode.postMessage({ type: 'start' });
    }
  </script>
</body>
</html>`;
}

function deactivate() {}

module.exports = { activate, deactivate };
