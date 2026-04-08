const vscode = require("vscode");

function activate(context) {
  const cmd = vscode.commands.registerCommand("ccbox.welcome", () => {
    showWelcome(context);
  });
  context.subscriptions.push(cmd);

  showWelcome(context);

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
    "ccbox",
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
        vscode.window.showInformationMessage(
          "Copied! Paste it in the Claude Code chat on the right."
        );
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
    background: var(--vscode-editor-background);
    color: var(--vscode-editor-foreground);
    overflow-y: auto;
  }
  .page {
    max-width: 720px;
    margin: 0 auto;
    padding: 3rem 2rem 4rem;
  }

  /* Header */
  .header {
    text-align: center;
    margin-bottom: 2.5rem;
  }
  .logo {
    font-size: 2.5rem;
    font-weight: 700;
    letter-spacing: -0.02em;
  }
  .logo span { color: var(--vscode-textLink-foreground); }
  .tagline {
    font-size: 1rem;
    color: var(--vscode-descriptionForeground);
    margin-top: 0.35rem;
    line-height: 1.5;
  }

  /* Sections */
  .section {
    margin-bottom: 2rem;
  }
  .section-title {
    font-size: 0.75rem;
    text-transform: uppercase;
    letter-spacing: 0.1em;
    color: var(--vscode-descriptionForeground);
    margin-bottom: 0.75rem;
    font-weight: 600;
  }

  /* How it works */
  .steps {
    display: flex;
    gap: 1rem;
    margin-bottom: 0.5rem;
  }
  .step {
    flex: 1;
    background: var(--vscode-input-background);
    border: 1px solid var(--vscode-input-border, transparent);
    border-radius: 10px;
    padding: 1.1rem 1rem;
    text-align: center;
  }
  .step-num {
    display: inline-flex;
    align-items: center;
    justify-content: center;
    width: 1.6rem;
    height: 1.6rem;
    border-radius: 50%;
    background: var(--vscode-textLink-foreground);
    color: var(--vscode-editor-background);
    font-size: 0.75rem;
    font-weight: 700;
    margin-bottom: 0.5rem;
  }
  .step-text {
    font-size: 0.82rem;
    line-height: 1.4;
    color: var(--vscode-editor-foreground);
  }

  /* Prompt cards */
  .prompts {
    display: flex;
    flex-direction: column;
    gap: 0.4rem;
  }
  .prompt {
    display: flex;
    align-items: center;
    gap: 0.75rem;
    background: var(--vscode-input-background);
    border: 1px solid var(--vscode-input-border, transparent);
    border-radius: 8px;
    padding: 0.7rem 1rem;
    cursor: pointer;
    transition: border-color 0.15s, background 0.15s;
  }
  .prompt:hover {
    border-color: var(--vscode-textLink-foreground);
    background: var(--vscode-list-hoverBackground);
  }
  .prompt-icon {
    font-size: 1.1rem;
    flex-shrink: 0;
    width: 1.8rem;
    text-align: center;
  }
  .prompt-text {
    font-size: 0.82rem;
    flex-grow: 1;
    line-height: 1.3;
  }
  .prompt-hint {
    font-size: 0.65rem;
    color: var(--vscode-descriptionForeground);
    opacity: 0;
    transition: opacity 0.15s;
    flex-shrink: 0;
  }
  .prompt:hover .prompt-hint { opacity: 1; }

  /* CTA */
  .cta-btn {
    display: block;
    width: 100%;
    padding: 0.8rem;
    font-size: 0.9rem;
    font-weight: 600;
    border: none;
    border-radius: 8px;
    cursor: pointer;
    background: var(--vscode-button-background);
    color: var(--vscode-button-foreground);
    transition: background 0.15s;
    margin-top: 0.25rem;
  }
  .cta-btn:hover { background: var(--vscode-button-hoverBackground); }

  /* Capabilities */
  .caps {
    display: grid;
    grid-template-columns: 1fr 1fr;
    gap: 0.35rem 1.5rem;
  }
  .cap {
    font-size: 0.78rem;
    color: var(--vscode-descriptionForeground);
    padding: 0.2rem 0;
  }

  /* Custom skills callout */
  .callout {
    background: var(--vscode-input-background);
    border: 1px solid var(--vscode-input-border, transparent);
    border-radius: 10px;
    padding: 1rem 1.2rem;
  }
  .callout-title {
    font-size: 0.82rem;
    font-weight: 600;
    margin-bottom: 0.35rem;
  }
  .callout-text {
    font-size: 0.78rem;
    color: var(--vscode-descriptionForeground);
    line-height: 1.5;
  }
  .callout-code {
    display: inline;
    font-family: var(--vscode-editor-font-family, monospace);
    font-size: 0.72rem;
    background: var(--vscode-textCodeBlock-background, rgba(127,127,127,0.15));
    padding: 0.15rem 0.4rem;
    border-radius: 3px;
  }

  /* Footer */
  .footer {
    text-align: center;
    font-size: 0.72rem;
    color: var(--vscode-descriptionForeground);
    opacity: 0.6;
    margin-top: 1rem;
  }
</style>
</head>
<body>
<div class="page">

  <div class="header">
    <div class="logo">cc<span>box</span></div>
    <div class="tagline">
      Your workspace is mounted and ready. Describe what you need in the
      chat&nbsp;\u2192 and Claude will create, edit, or transform your documents.
    </div>
  </div>

  <div class="section">
    <div class="section-title">How it works</div>
    <div class="steps">
      <div class="step">
        <div class="step-num">1</div>
        <div class="step-text">Describe what you want in plain language</div>
      </div>
      <div class="step">
        <div class="step-num">2</div>
        <div class="step-text">Claude creates or edits the document for you</div>
      </div>
      <div class="step">
        <div class="step-num">3</div>
        <div class="step-text">Review, refine, and download from the file explorer</div>
      </div>
    </div>
  </div>

  <div class="section">
    <div class="section-title">Try something \u2014 click to copy, then paste in chat</div>
    <div class="prompts">
      <div class="prompt" onclick="copy('Create a PDF report summarizing Q1 sales with charts and an executive summary')">
        <div class="prompt-icon">\u{1F4C4}</div>
        <div class="prompt-text">Create a PDF report with charts and executive summary</div>
        <div class="prompt-hint">copy</div>
      </div>
      <div class="prompt" onclick="copy('Create a 10-slide pitch deck for a startup called Acme AI')">
        <div class="prompt-icon">\u{1F4CA}</div>
        <div class="prompt-text">Create a pitch deck presentation</div>
        <div class="prompt-hint">copy</div>
      </div>
      <div class="prompt" onclick="copy('Create an Excel budget tracker with monthly columns, formulas, and conditional formatting')">
        <div class="prompt-icon">\u{1F4CB}</div>
        <div class="prompt-text">Create a spreadsheet with formulas and formatting</div>
        <div class="prompt-hint">copy</div>
      </div>
      <div class="prompt" onclick="copy('Summarize all documents in this folder and create a one-page overview as a Word document')">
        <div class="prompt-icon">\u{1F4C1}</div>
        <div class="prompt-text">Summarize existing files into a new document</div>
        <div class="prompt-hint">copy</div>
      </div>
      <div class="prompt" onclick="copy('Convert the Word document in this folder to a clean PDF with proper formatting')">
        <div class="prompt-icon">\u{1F504}</div>
        <div class="prompt-text">Convert or transform existing documents</div>
        <div class="prompt-hint">copy</div>
      </div>
    </div>
  </div>

  <div class="section">
    <button class="cta-btn" onclick="start()">Open chat and start creating</button>
  </div>

  <div class="section">
    <div class="section-title">What Claude can do here</div>
    <div class="caps">
      <div class="cap">\u{1F4C4} PDF \u2014 create, edit, merge, OCR</div>
      <div class="cap">\u{1F4CA} PPTX \u2014 slides & presentations</div>
      <div class="cap">\u{1F4CB} XLSX \u2014 spreadsheets & formulas</div>
      <div class="cap">\u{1F4DD} DOCX \u2014 documents & letters</div>
      <div class="cap">\u{1F3A8} Design \u2014 posters & infographics</div>
      <div class="cap">\u{1F3AF} Brand \u2014 consistent identity</div>
      <div class="cap">\u{1F504} Convert \u2014 between formats</div>
      <div class="cap">\u{1F50D} OCR \u2014 extract text from scans</div>
    </div>
  </div>

  <div class="section">
    <div class="callout">
      <div class="callout-title">\u{1F3E2} Custom skills for your team</div>
      <div class="callout-text">
        Your organization can add custom skills — templates, workflows, and
        formatting rules — so Claude follows your company standards automatically.
        <br><br>
        Place skills in <span class="callout-code">~/.ccbox/skills/</span> for all
        sessions, or in your project's
        <span class="callout-code">.claude/skills/</span> folder.
        Templates go in <span class="callout-code">~/.ccbox/templates/</span> or
        your project's <span class="callout-code">templates/</span> folder.
      </div>
    </div>
  </div>

  <div class="footer">
    Files appear in the Explorer panel on the left. Chat with Claude on the right.
  </div>

</div>
<script>
  const vscode = acquireVsCodeApi();
  function copy(text) { vscode.postMessage({ type: 'copy', text }); }
  function start() { vscode.postMessage({ type: 'start' }); }
</script>
</body>
</html>`;
}

function deactivate() {}

module.exports = { activate, deactivate };
