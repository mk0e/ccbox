# DIY AI News Collector Workshop

Welcome! This guide walks you through building your own AI news collector in 1.5 hours using Claude Code. The workshop materials have been seeded into your `/workspace/` — `initial-requirements.md` is for your bullet points, `example-requirements.md` is for inspiration, and `sample.env` shows the env vars you'll need.

---

## Expected outcome of this learning experience

- hands on experience using obra super powers
- hands on experience running parallel agents
- hands on experience of an agent not doing the full job and missing some pieces
- hands on experience of setting the agent up for end to end testing & trouble shooting

## Pre-Face (introductory talk):

- the goal is for you to build a DIY AI News Collector: the only must-have criteria are:
  - must have a WebPage / Frontend with a UI
  - must integrate an LLM
  - must have some kind of backend & use a database as storage
  - must be able to autonomously scrape websites & provide a weekly summary
- keep in mind: for the AI-Newscollector, we've spend in total around 3+ 40hr weeks
  - -> during this time, we learned a lot, it could be that now we are a bit faster
- FYI: you can find the full version [here](https://ai-news-collector.sandbox.starplatform.cloud/login), if you want to try it out afterwards
- Anyway: the goal we are using is that everyone of you has his own version of a DIY AI News Collector, but what I will try to show you, is how it feels using Claude Code for doing this:
  - how does working with claude code look like?
  - what Claude can or cannot do? Where are its limits at the moment?
  - what kind of patterns are beginning to emerge (e.g. skills, full-round-trip)
- The ambition of this document is to contain the minimal amount of instructions in order to be able to build your own DIY ai news collector in 1.5 hours. There are many things which one could improve in the prompts and workflows, they are minimal on purpose. If you think, some things could or should be improved, please do so. Experiment with it.

## Steps:

### 0. Introduction & Minimal Env-Setup (5min)

- Speaker giving an introduction to the DIY project
- open this project inside an isolated environment (devcontainer for macos is included)
  -> TODO: to be clarified with colleagues, but in vs code: open in devcontainer works on mac here
- this file is excluded via .claudeignore from the files claude is seeing to prevent any confusion during implementation
- start claude in the terminal of VS Code using the command `claude`
- make sure to use opus 4.6 with medium reasoning, you can check so with entering `/model` into claude
- set up claude.md
  - claude.md are the core agent instructions, if you want to change any processes or behavior of claude, pls put it in there.
  - E.g. Prompt: `Please add to the claude.md file to always note bugs you found or ideas for improvements which are not yet scoped to be implemented in the TODO.md file. This is your living backlog which is maintained in accordance with human input`
  - approve the things claude is asking to do, that is, how claude is normally working
  - -> if you have an idea, you can just ask claude to add it to the todo.md file and later when you finished a task, you can come back to this file and ask claude to implement items from it or to refine the backlog

### 1. brainstorm your personal requirements for an AI News Collector (5min)

- keep it very simple
- just note down the core features you want to have in any editor or word document(6 bullet points max)
- paste them into the `initial-requirements.md`file (you can also take a look at `example-requirements.md` for inspiration)

### 2. Ask obra superpowers with /brainstorming to create a set of detailed requirements out of the bullet points (5-10min)

- Prompt: `/superpowers:brainstorm Please create the detailed requirements based on the initial requirements in initial-requirements.md and write them into a requirements.md file. The requirements should should be on a functional and technical level, detailing what functionality the application should have and what technologies should be used for the implementation. The goal is to use them later for implementation. DO NOT START WITH THE IMPLEMENTATION NOW, JUST CREATE THE VERY DETAILED REQUIREMENTS YOU CAN USE LATER FOR IMPLEMENTATION`
- For the scope of this time-boxed session, pls opt for simple options in the questions you are getting asked - feel free later to make different choices
- if in doubt what to do, ask claude

### 3. Ask with obra super powers to create UI-Mockups for the website (5-10min)

- to make the working less cumbersome, as we are in an isolated environment stop claude now and restart it with `claude --dangerously-skip-permissions`
- you can exit a session with `/exit` and after starting, you can resume your session with `/resume`
- Prompt: `/superpowers:brainstorm Please create me UI wireframes based on the websites and show me them either inline in the terminal or with your live-server. The UI-Design should capture all main flows and application screens. You can find the requirements in requirements.md. Please adapt the UI design until I am happy and then write the UI-Design into a UI-Design.md file.`

### 4. Ask obra super powers to work out the API-Contract between frontend and backend based on the requirements (5min)

- -> keep it very simple, just make sure you have the endpoints and the way of communication (e.g. rest defined)
- -> Goal is to be able to have the frontend and backend implemented in parallel
- Prompt: `/superpowers:brainstorm Based on the requirements.md file, please create a full API-Contract for the communication between frontend and backend. The purpose of this API-Contract is to be able to implement frontend and backend separately from each other, therefore the API contract should provide all the necessary details for doing so, like data formats, auth, ... . Please write the API contract to an api-contract.md file`

### 5. Open two sessions and use obra super powers to let it implement the frontend and backend in parallel (20min)

- Frontend prompt: `/superpowers:brainstorm Based on the requirements.md file, the ui-design.md file and the api-contract.md file, pls implement the frontend in a folder <frontend> in the project root directory.`
- Backend prompt: `/superpowers:brainstorm Based on the requirements.md file and the api-contract.md file, pls implement the backend in a folder <backend> in the project root directory. Please use the sample.env file as a reference for the environment variables and the configuration of the LLM`
- in case prompted, which execution plan to choose, pls choose <subagent-driven>
- at the end of both session, make sure that the changes are on the main branch in git. In both sessions, please paste: `Please commit the changes you've done & merge the changes to main locally.`

### 6. Ask Claude to spin up the frontend and backend and play around with the UI (5min - does it work as designed?) (5-10min)

- Prompt: `Please now spin up frontend and backend so that I can test it.`
- Please open the corresponding frontend, play around with it and check whether everything works

### 7. Bug fixing (5-10min):

- Example Prompt: `/superpowers:brainstorm: I encountered bug x, z does not work when doing y, pls fix it` or
  `/superpowers:brainstorm: X does not work please fix it`
- The <secret ingredient> is to ask claude, whenever it is doing any changes to verify it works end2end, with that, you build up a feedbackloop for Claude against it can fix & implement things until it works. To test this out instead, you can try `/superpowers:brainstorm: X does not work please fix it`

### 7. Optional: Adversarial testing?

- Next evolution / step up in the automation chain: let the model itself find bugs in the application & verify its functionality.
- Prompt: `/ralph loop. Please perform adversarial testing end2end using the frontend. Please start the frontend and backend and then perform adversarial testing on the UI to make sure the app works. Look at the available documentation for how the application should work and perform the testing to make sure the application works as specified & fulfills the requirements. Please note the found bugs in the TODO.md file. Please perform up to 100 iterations or 25 bugs found. For each bug, please note a brief title, a description on why this is relevant, steps to reproduce the bug and the implications on a business level on the app. For UI-Testing, please use playwright. `

### 8. Optional: Fix the bugs found during adversarial testing

- Fix the bugs found through adversarial testing using claude & super powers
- after each fix, perform adversarial testing to make sure the app still works
- introduce end2end tests against regressions
- optimize the prompts and workflows ...

## Reflection:

- what when well what did not go well?

## Overview of patterns & best practices, which some of us have found useful in the past

(not all of them have been applied here due to the time constraints)

- Feedback loops: let the agent verify end2end that the implemented functionality works and work on it until it can verify it works, aka <closing the loop>
  -> this includes configuring an LLM key with a small budget, so that claude can test the entire functionality off the app including everything LLM related
- Use Obra Superpowers for brainstorming, implementation and bug fixing (or anything else involving more complex work)
- Add instructions to claude.md to note any learnings in an ai-learnings.md file for troubleshooting and in case of problems, please look it up whether a solution has already been found
- While working with claude, update the instructions for claude code (documentation, claude.md or skills) on the fly to continuously improve the process instructions along which claude code is working
- For repeatable tasks, like updating the documentation, create a skill with the specific flow, e.g. making sure that there is at the bottom of the documentation a small remark with the timestamp and the commit-sha so that claude code can just look at the diff between the last documentation update and the code change and update the docs with the changes
- Parallel work: working with multiple claude code sessions in parallel
- Verifying everything you do: either looking at the code directly or creating a sufficiently good testing framework with instructions for Claude Code, so that you can confidently state that the functionality works.
- Asking Claude regularly to do a clean code refactoring of the code in order to keep the code base in a maintainable state (makes things also easier for Claude Code to work with), this is something one would typically write a skill for & refine it on the go
- A living documentation in the repository: Include all relevant documentation you need in the repository and tell claude where to find it - this helps a lot. Later one also must think about how one wants to maintain this documentation / knowledgebase and how one collaborats with other people.
- Analyze the work Claude Code is doing on a meta level, ask Claude Code to give you documentation on the architecture diagrams, test coverage, testing approaches etc. so that you can work on a higher abstraction level, while still maintaining control
- Claude Code almost can do everything (end2end testing, deployment, ...), but will most often only do so, if you tell it to do so and define & refine the process claude code should follow while doing work.
- all of the content in this file applies to the current LLM generation around opus 4.6 and sonnet 4.6, new models might again push the boarder of what is possible and how you can best leverage them

## TODOs:

- get haiku key with limited budget for live end to end testing -> add to stage 7
- add install script or tooling for playwright
- reduce scope of project to accelerate it
- clean git history to not give the agent any hints
- add a sample.env with everything except the API-key for the haiku model

## Open Questions:

- what kind of technical knowledge and experience do the participants have? (this is pretty cool for someone who never used claude code before, but boring for someone who is using it already)
- what do we do if the APIs from Anthropic are overloaded / down? (use gemini cli / codex-cli?)

## Trouble-Shooting

- in case the brainstorming skill is not recognized, inside claude code, pls execute `/reload-plugins`, afterwards it should work again
- in case anything else does not work, just tell it to claude what the error is & fix it
