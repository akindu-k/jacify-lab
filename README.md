# jacify-lab: rebuilding json-server in Jac

This project tests a new programming toolkit on real-world code. I took a popular
program, **json-server**, rebuilt it in the **Jac** language using the **neojac**
toolkit (version 0.3.3), proved the new version behaves exactly like the original, and
wrote down every problem I found in neojac along the way.

> **Read the report:** [neojac 0.3.3 Port Findings](https://claude.ai/artifact/MPi9YEbbVtCvm1Rbn1gPCj),
> a plain-English web page explaining what was done, why, how it was proven, and all 20
> problems found. No background in json-server, Jac or neojac needed.

## The short version

- **json-server** is a small tool that turns a data file into a working web service.
- **Jac** is a newer programming language that looks like Python. **neojac** is the
  software that turns Jac code into runnable programs.
- neojac's automatic tools couldn't convert any of json-server, so I rewrote it by hand
  in Jac (about 5,300 lines).
- The rebuilt version gave the same answer as the original in **417 out of 417** tests.
- I found **20 problems** in neojac: bugs, missing features, limits and out-of-date
  documentation. They're explained on the [report page](https://claude.ai/artifact/MPi9YEbbVtCvm1Rbn1gPCj),
  with step-by-step reproductions in [FINDINGS.md](FINDINGS.md).

## What json-server is

[json-server](https://github.com/typicode/json-server) is an open-source tool, popular
with developers who build apps. You give it a file of data, for example:

```json
{
  "posts":    [ { "id": "1", "title": "Hello" } ],
  "comments": [ { "id": "1", "text": "Nice post", "postId": "1" } ]
}
```

and it immediately starts a **web service**: a program that other programs can talk to
over the internet by sending requests to web addresses.

```
GET    /posts                  → list every post
GET    /posts/1                → just post number 1
GET    /posts?views:gt=100     → posts with more than 100 views
GET    /posts?_sort=-views     → posts, most viewed first
POST   /posts                  → add a new post
DELETE /posts/1                → delete post 1 (its comments are updated too)
```

Every change is saved straight back into the data file, and if someone edits the file
by hand, the service notices and reloads it. Developers use it to stand in for a real
back-end while they build the front of an app.

The original is written in TypeScript (a version of JavaScript) and runs on Node.js.

## Why rebuild it

A language and its tools are easiest to judge on real code, not toy examples.
json-server is small enough to finish, but it does many different things: it answers
web requests, reads and writes files, filters and sorts data, and watches for changes.

To keep the test fair:

- I used only the newest official neojac release (0.3.3).
- I learned Jac only from what neojac ships: its built-in help pages, its helper guides
  ("skills") and its error messages. No outside tutorials, and no reading neojac's own
  source code.
- I wrote down every problem the moment it appeared, instead of quietly working
  around it.

## What we did

1. **Brought in the list of packages.** neojac's `absorb` tool copies a JavaScript
   project's list of outside packages into a Jac project. It worked, but only after I
   created a settings file by hand, and it silently lost the record of exact package
   versions.
2. **Tried the automatic translator.** neojac's `port` tool tries to translate code
   from another language into Jac. It translated **none** of json-server's 16 files:
   it only understands a small part of TypeScript, and two bugs blocked it even before
   that.
3. **Rebuilt it by hand, the Jac way.** In Jac, data can be stored as a **graph**: items
   connected to each other, starting from a built-in item called `root`. Each list of
   things (posts, comments) is one item, connected to one item per entry. Cleanup work,
   such as updating a post's comments when the post is deleted, is done by **walkers**,
   small pieces of code that travel through the graph. The data file is still saved
   after every change, just like the original.

To behave *exactly* like the original, the rebuild also had to copy JavaScript's own
rules in places where they differ from Python-style rules: how text is sorted, how
numbers are printed, and the exact wording of error messages. Each of those was checked
against the real JavaScript behavior.

neojac also has a built-in web server that can save a graph permanently. It couldn't
be used here: it only allows fixed web addresses, and it can't accept or store data of
no fixed shape, which is all json-server deals in (findings F04, F17 and F18).

## How we proved it works

**Differential testing:** run the original and the rebuilt version side by side, send
them exactly the same requests, and compare every answer. Each side got its own fresh
copy of the same data.

| What was compared | Result |
|---|---|
| Web requests (status, headers and content of each answer) | 417 of 417 identical |
| The data file each one saved afterwards | 8 of 8 identical |
| Command-line uses (output and exit code) | 23 of 23 the same |
| Live hand-edits of the data file while running | 10 of 10 the same |
| 200 changes sent at the same moment | all saved by both |

The tests cover json-server's own test cases, every kind of search, filter, sort and
paging request, adding, changing and deleting data, broken input, plain web files, the
JSON5 file format, and production mode.

A few small differences are intentional and listed in
[json-server-jac/README.md](json-server-jac/README.md). Most requests run at about the
same speed as the original, but sorting large lists is about ten times slower.

## What we found

All 20 problems are in neojac, not in json-server. The most important ones:

- **The built-in web server can't host an ordinary web service** like this one (F04,
  F17, F18).
- **The automatic translator** handled none of the code, ignores the project's own
  settings file, and breaks if the package tool runs first (F07 to F10).
- **The package tool** needs a settings file nothing creates, and silently loses the
  exact package versions (F05, F06).
- **Language and library differences:** some type names are rejected depending on how
  they're written (F14), sorting doesn't follow Python's steps (F16), and very large
  whole numbers can't be read (F11).
- **Help pages** that are out of date or contradict the tools (F01 to F03, F12, F20,
  F21).

Each one is explained in plain English on the
[report page](https://claude.ai/artifact/MPi9YEbbVtCvm1Rbn1gPCj), and
[FINDINGS.md](FINDINGS.md) has a step-by-step way to reproduce every one.

## What's in this repository

| Folder or file | What it is |
|---|---|
| [`FINDINGS.md`](FINDINGS.md) | Every problem found in neojac 0.3.3, with reproductions |
| [`json-server-jac/`](json-server-jac/) | The rebuilt json-server in Jac (the main result) |
| [`difftest/`](difftest/) | The side-by-side tests against the original |
| `absorb-trial/` | Step 1: the package tool's output |
| `port-check.txt`, `port-check-plain.txt`, `port-control/` | Step 2: the automatic translator's output, plus a small file it could translate |
| `spikes/` | Small experiments behind individual findings |

## Glossary

| Term | Meaning |
|---|---|
| Web service (API) | A program other programs talk to over the internet |
| Request | One message to a web service: read (GET), add (POST), change (PUT/PATCH) or delete (DELETE) |
| JSON, JSON5 | Common text formats for data; JSON5 is a looser version that allows comments |
| Compiler | A tool that turns code written by people into a runnable program |
| Porting | Rewriting a program in another language so it does the same job |
| Package | Ready-made code written by someone else that a project uses |
| Graph, node, root | Data stored as items (nodes) joined by connections; `root` is Jac's built-in starting item |
| Walker | Jac code that moves through a graph doing work |
| Differential testing | Checking a new version against the original with the same inputs |

## Running it yourself

The two copies of the original json-server aren't stored in this repository. To
recreate them and rerun everything (needs [neojac](https://github.com/jaseci-labs/neojac-releases)):

```sh
git clone https://github.com/typicode/json-server.git upstream-json-server
git -C upstream-json-server checkout 89a34a4
cp -r upstream-json-server port-plain && rm -rf port-plain/.git
(cd port-plain && neojac npm install --ignore-scripts)
(cd json-server-jac && neojac build main.jac --release -o dist/json-server-jac)
(cd difftest && neojac build difftest.jac -o difftest && ./run-all.sh)
```
