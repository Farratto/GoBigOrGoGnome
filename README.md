## Go Big or Go Gnome
**Current Version**: ~v-dev~ \
**Updated**: ~date~

Adds larger custom sizes to ruleset.

### Installation

Install from the [Fantasy Grounds Forge](https://forge.fantasygrounds.com/shop/items/2170/view). \
You can find the source code at Farratto's [GitHub](https://github.com/Farratto/GoBigOrGoGnome). \
You can ask questions at the [Fantasy Grounds Forum](https://www.fantasygrounds.com/forums/showthread.php?84666).

### Details

By using slash commands you can add additional size categories, that will then work seamlessly with the rest of FG as if they had always been there.  Once you've added new categories, you'll be able to change those new categories or remove them with more slash commands.  This can only be done on the host.  This data is stored in the db.xml under "GoBigOrGoGnome.customsizes".

Usage:

| Command | Description |
| :--- | :--- |
| /listsize | lists current size categories |
| /addsize [name] ([n]) [space] and [reach] | e.g. /addsize colossal (c) 6 and 4 |
| /removesize [size name] OR [size abbreviation] OR [space number] | e.g. /removesize colosal |

Notes: \
The default for 5E ruleset is that all size categories have a reach of 1.  For any custom sizes you add (regardless of ruleset), if you do not specify a reach length, it will default to 1.  You can add custom sizes to a 5E ruleset campaign that has a non-1 reach. \
I've added some responses for incorrect syntax so hopefully it should be intuitive enough you can figure it out.  If you have trouble, ask on the [forum](https://www.fantasygrounds.com/forums/showthread.php?84666).  I usually respond within a day or two. \
Soon, I'll have an export/import function but for now if you want to use your custom sizes on multiple campaigns,  either write them down and do them again manually or you can copy/paste the "GoBigOrGoGnome" section of your db.xml.

### Limitations

You cannot remove or change the ruleset sizes.  You can only add larger size categories, not smaller ones.

## Attribution
The bulk of Go Big or Go Gnome and the last remaining vestiges of Size Matters has been absorbed into the ruleset.  What remains is only the slash commands that were wholey written by Farratto. \
Icon made by Cathelineau from [Game-icons.net](https://game-icons.net/1x1/cathelineau/bad-gnome.html). \
SmiteWorks owns rights to code sections copied from their rulesets by permission for Fantasy Grounds community development. \
'Fantasy Grounds' is a trademark of SmiteWorks USA, LLC. \
'Fantasy Grounds' is Copyright 2004-2021 SmiteWorks USA LLC.

### Change Log

* v1.6.0: Most of GBoGG was absorbed into ruleset.  Removed redundant/interfering code. FIXED: PFRPG2 and 2E rulesets weren't working.
* v1.5.2: FIXED: Slash commands were not working.
* v1.5.1: FIXED: Errors introduced with last update. Apologies. Expanded other ruleset support.
* v1.5.0: FIXED: PFRPG2 ruleset ignoring base size on PCs. Added Ctrl-MouseWheel speed size adjustments and slash commands to some other rulesets. Added protections for erroneous syntax in slash commands.
* v1.4.2: FIXED: rare error report misrepresentation.
* v1.4.1: FIXED: error in application of new size-system to some rulesets.
* v1.4.0: Cosmetic small size option now available to all rulesets. Colossus size added to 4E ruleset. FIXED: Colossus size was erroneously set to 5x5. Now corrected to 6x6. Dot health indicator was not resizing with size changes. Effect tag SIZE: # was adding/removing one grid space instead adding/removing one size category. FEATURE: slash commands to add custom large sizes. Removed previously built-in custom sizes for 5E (other than colossus). Accomodations for ruleset 2026-05-05
* v1.3.3: Compatibility update for 2026-05 Ruleset Update
* v1.3.2: Compatibility update for FG v4.8.0
* v1.3.1: FIXED: some widgets were not using modified sizes
* v1.3.0: FEATURE: new size categories of colossal (5x5), giga (6x6), enormous (8x8), epic (10x10), monumental (16x16), cosmic (20x20) for 5E ruleset
* v1.2.2: FIXED: typo
* v1.2.1: FIX: nil error. Now allows setting reach to none
* v1.2.0: REBRANDING of Size Matters. FEATURE: hold ctrl and mouse-wheel up/down to rapidly change size-category of creatures. FIXED: not setting token size correctly for creatures smaller than 1 grid square. FIXED: when adding new token to map that has a size change, that size change was not respected. NEW option to make small creture tokens slightly smaller than medium (aesthetic only).