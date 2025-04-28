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

Go Big or Go Gnome is intended to work with any ruleset based on CoreRPG. The SPACE and REACH based effects below are system agnostic, applying specifically to the token. The SIZE effects below make certain assumptions about how the ruleset handles size categories. Support is verified for D&D 5E to account for SIZE changes with encumbrance and IF: SIZE() conditional effects. Mileage for other rulesets may vary. \
There is also a slight aesthetic change that makes small creature tokens slightly smaller than medium creature tokens.  This is nonfunctional and cannot be turned off with an option.

The following effects have been added:
* **SIZE: n** - Adjusts the bearer n number of size increments. E.g. "SIZE: 2" will turn a small creature into a large creature.
* **SIZE: size** - Makes the bearer the given size. The allowed values for size are determined by the ruleset (for any ruleset that uses "DataCommon.creaturesize").
* **SPACE: n** - Sets the bearer's space to n, using the ruleset's unit of distance.
* **ADDSPACE: n** - Adds n to the bearer's reach, using the ruleset's unit of distance.
* **REACH: n** - Sets the bearer's reach to n, using the ruleset's unit of distance. (use none for 0)
* **ADDREACH: n** - Adds n to the bearer's reach, using the ruleset's unit of distance.

New size cateogries added to the 5E ruleset (let me know if you want additional sizes for other rulesets).
* colossal (c) (5x5)
* giga (i) (6x6)
* enormous (n) (8x8)
* epic (e) (10x10)
* monumental (o) (16x16)
* cosmic (k) (20x20)

## Attribution
MeAndUnique is the original author of Size Matters.  Go Big or Go Gnome is a fork that is maintained by Farratto, under the MIT license. \
Icon made by Cathelineau from [Game-icons.net](https://game-icons.net/1x1/cathelineau/bad-gnome.html). \
SmiteWorks owns rights to code sections copied from their rulesets by permission for Fantasy Grounds community development. \
'Fantasy Grounds' is a trademark of SmiteWorks USA, LLC. \
'Fantasy Grounds' is Copyright 2004-2021 SmiteWorks USA LLC.

### Change Log

* v1.3.0: FEATURE: new size categories of colossal (5x5), giga (6x6), enormous (8x8), epic (10x10), monumental (16x16), cosmic (20x20) for 5E ruleset
* v1.2.2: FIXED: typo
* v1.2.1: FIX: nil error. Now allows setting reach to none
* v1.2.0: REBRANDING of Size Matters. FEATURE: hold ctrl and mouse-wheel up/down to rapidly change size-category of creatures. FIXED: not setting token size correctly for creatures smaller than 1 grid square. FIXED: when adding new token to map that has a size change, that size change was not respected. NEW option to make small creture tokens slightly smaller than medium (aesthetic only).