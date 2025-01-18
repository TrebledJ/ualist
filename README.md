# ualist
Find and retrieve lists of user agents.

### What is this?

This tool is used to **generate and browse random user agents**. This is useful for web developers, (ethical) hackers, and security researchers.

Servers may respond differently depending on the user agent. A mobile device may be served smaller assets. An unsupported browser may be given an error. A scripting tool may be flagged as a bot and served status code 418. Fishing out such responses is useful during penetration tests.

Due to the nature of the generation algorithm, synthesised agents may not necessarily reflect actual agents, mostly mimicing in appearance. This means this tool may generate non-existent version numbers, build numbers, etc.

### Why?

Quite simply, I wanted a down-to-earth, feature-first, no-ads tool for generating and browsing user agents. During my pentesting engagements, I've encountered websites which offer no response to a regular HTTP request, but return a full web page when provided a user agent. Most other online solutions didn't work for me, were too simplistic, or full of ads. I also wanted a randomisation factor for better opsec, to avoid limiting myself to 3 hard-coded user agents which could be easily blocked (assuming IP rotation is used). Hence, I decided to build this.

But truthfully, I also wanted to scratch my early 2025 programming itch by picking up technologies such as the [Elm Programming Language](https://elm-lang.org/) and [TailwindCSS](https://tailwindcss.com/).

### Credits

Big thanks to [UAParser.js](https://github.com/faisalman/ua-parser-js) for their awesome library and tests.

## Roadmap

- [fix] [ui] thead sticky top rem
- [feat] [func] randomise UAs
- [feat] [func] Case insensitive search
- [feat] [ui] tooltips for buttons and toolbar
- [feat] [func] better search filters, and search by column
- [feat] [ui] indicator for copied row (animate row? tooltip? (slow, with many OnMouseEnter events))
- [feat] [ui] sidebar (drawer) for info, credits
- [feat] [ui] sidebar (drawer) for menu to homepage, blog, other apps, and about
- [code] refactor button component + css
- [ui] Fancy (switchable?) theme
- [fix] [ui] better sorting icons and switch the arrows for asc/desc
- [code] [perf] Elm optimisations
- [perf] efficient table rendering and scrolling for large datasets
- [code] sync README sections by copying sections between README.md and about.md
