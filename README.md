# mtg-meld
Generates a sheet of Magic: the Gathering proxies with 2 cards melded together to allow for deck variance.

## Use Case

I have two main use cases behind developing this script. The first is that Magic: the Gathering cards are expensive! I'm not made of fetch lands. So this part of the plan is to have one copy of expensive cards sleeved in a psuedo-sideboard where I can grab the copy of, let's say, Mana Crypt, that I need without having to resleeve it depending upon which deck I decided to play any given day.

While we're talking about Mana Crypt, it's important to note this is a pretty powerful card. Commander, one of my favorite formats, is all about the social experience, and it's important to get a good idea the relative power level of the decks at your table before choosing which deck to play. Sometimes, though, you REALLY want to play a certain commander. I've recently wanted to play around with having a transformable deck, which led me to design the melded proxies you can generate with this tool. Here's a great example for this use case: I have an Ezuri, Claw of Progress deck based around the morph mechanic. Ezuri, once you have 5 experience counters, goes infinite with Sage of Hours. Some playgroups may not want to play with infinite combos. But rather than have to resleeve my deck after replacing a card, I can simply say that for the game, I am using only the bottom half of my proxy cards, which replaces the card in the deck with a less powerful one. This allows me to change my deck's power level on the fly depending upon my group.

![sample proxy](https://raw.githubusercontent.com/ThePieBandit/mtg-meld/main/docs/Sage_Of_Hours%23Illusionary_Mask.png)


## How to use

There are two main ways to use the script. First, you can pass a `-t` flag with a card name to generate a proxy for that card. Optionally passing a `-b` flag with a card name will meld a proxy for you. If you pass the optional `-o` flag, it will generate the current oracle text onto the melded proxy.

```./meld.sh -t "Thornwood Falls" -b "Tropical Island" ```

The second way is to pass a list of cards in a file using the `-f` parameter. This looks like a properties file, with the left side of the equals sign the top of the card and the right, if provided, the bottom of a melded proxy. *Note:* you must pass the `=` either way. Similar to the first option, passing `-o` will generate the current oracle text onto all melded proxies.

```./meld.sh -f SampleList.txt -o```

## Dependencies

- curl
- imagemagick
- That's it!

## Data

All data is pulled from scryfall.com in accordance with their API usage.

## Future

At some future point, I hope to provide some sort of cross-platform/hosted version.
