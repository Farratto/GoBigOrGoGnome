## Go Big or Go Gnome
**Current Version**: ~v-dev~ \
**Updated**: ~date~

Adds support for effects that change creature size, space, and reach.

Go Big or Go Gnome is a rebranding of Size Matters by MeAndUnique, now maintained by Farratto.

### Installation

It is recommended that you disable and hide Size Matters on your Forge account.  And if you have downloaded any releases from github, you should also delete any copies of SizeMatters.ext in your extensions folder. \
Install from the [Fantasy Grounds Forge](https://forge.fantasygrounds.com/shop/items/2170/view). \
You can find the source code at Farratto's [GitHub](https://github.com/Farratto/GoBigOrGoGnome). \
You can ask questions at the [Fantasy Grounds Forum](https://www.fantasygrounds.com/forums/showthread.php?84666).

### Details

Go Big or Go Gnome is intended to work with any ruleset based on CoreRPG. The SPACE and REACH based effects below are system agnostic, applying specifically to the token. Support is verified for D&D 5E to account for SIZE changes with encumbrance and IF: SIZE() conditional effects. Mileage for other rulesets may vary. \
There is also a slight aesthetic change that makes small creature tokens slightly smaller than medium creature tokens.  This is nonfunctional and can be turned off with an option.

The following effects have been added:
* **SIZE: n** - Increments the bearer's size category by n. E.g. "SIZE: 2" will turn a small creature into a large creature; and "SIZE: -2" will turn a large creature into a small creature.
* **SIZE: size** - Makes the bearer the given size. You may use full name or official abbreviation.
* **SPACE: n** - Sets the bearer's space to n, using the ruleset's unit of distance.
* **ADDSPACE: n** - Adds n to the bearer's reach, using the ruleset's unit of distance.
* **REACH: n** - Sets the bearer's reach to n, using the ruleset's unit of distance. (use none for 0)
* **ADDREACH: n** - Adds n to the bearer's reach, using the ruleset's unit of distance.

New size category added to the 4E and 5E rulesets.
* colossal (c) (6x6) (reach of 4 for 4E ruleset)

### Custom Sizes

Using slash commands you can add additional size categories, that will then work seamlessly with the rest of FG as if they had always been there.  Once you've added new categories, you'll be able to change those new categories or remove them with more slash commands.  This can only be done on the host.  This data is stored in the db.xml under "GoBigOrGoGnome.customsizes".

Usage:

| Command | Description |
| :--- | :--- |
| /listsize | lists current size categories |
| /addsize [name] ([n]) [space] and [reach] | e.g. /addsize colossal (c) 6 and 4 |
| /removesize [size name] OR [size abbreviation] OR [space number] | e.g. /removesize colosal |

Notes: \
The default for 5E ruleset is that all size categories have a reach of 1.  For any custom sizes you add (regardless of ruleset), if you do not specify a reach length, it will default to 1.  You can add custom sizes to a 5E ruleset campaign that has a non-1 reach. \
I've added some responses for incorrect syntax so hopefully it should be intuitive enough you can figure it out.  If you have trouble, ask on the [forum](https://www.fantasygrounds.com/forums/showthread.php?84666).  I usually respond with a day or two. \
Soon, I'll have an export/import function but for now if you want to use your custom sizes on multiple campaigns.  Either write them down and do them again manually or you can copy/paste the "GoBigOrGoGnome" section of your db.xml.

Limitations: You cannot remove or change the ruleset sizes.  You can only add larger size categories, not smaller ones.

## Attribution
MeAndUnique is the original author of Size Matters.  Go Big or Go Gnome is a fork that is maintained by Farratto, under the MIT license. \
Icon made by Cathelineau from [Game-icons.net](https://game-icons.net/1x1/cathelineau/bad-gnome.html). \
SmiteWorks owns rights to code sections copied from their rulesets by permission for Fantasy Grounds community development. \
'Fantasy Grounds' is a trademark of SmiteWorks USA, LLC. \
'Fantasy Grounds' is Copyright 2004-2021 SmiteWorks USA LLC.

### Change Log

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