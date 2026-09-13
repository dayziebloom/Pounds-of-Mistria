# Pounds-of-Mistria
A framework for NPC &amp; player weight gain within the game Fields of Mistria

# Requirements
- ModsOfMistriaInstaller (MOMI)
  - Available as the latest release on Github https://github.com/Garethp/Mods-of-Mistria-Installer/releases
  - or is usually available on Nexus Mods, but that version is not always up-to-date

# Recommended
- Daily Gift Perks by MayZ (placeholder for link)
  - This is a side mod which will add new perks to buy on the cooking skill tree, which will each let you gift 1 additional item
    per day to NPCs, up to a maximum of 3 per day.
- HOWEVER
  - There is no clean way to remove custom perks from save files as of yet, so any save you make with this mod installed WILL lock
    you into using that save with that mod. Trying to load the save without the perks mod will fail.
  - To edit your save, you will have to use https://www.saveeditonline.com/
    - upload your .sav file here, view the file as raw JSON, and delete all lines of code that include 'elevenses' or 'second_breakfast'
 
# How to Install
- Download the latest version from the 'Releases' section on the right (bottom if you're viewing on mobile for some reason)
- Unzip the folder, and place the 'Food to Weight' folder inside a 'mods' folder within your Fields of Mistria directory
  - (The folder you end up in if you use Steam's "browse local files" button)
- Launch MOMI, and first uninstall all currently installed mods if any, then select the 'Food to Weight' mod alongside any other mods
  you'd like installed, and hit Install.
- Once MOMI says the mods are installed, you can launch Fields of Mistria

# What the framework does
- Tracks each adult NPC's weight on their page in the relationship menu.
- Each food item is given a weight value that is added onto any NPC that is gifted that food.
- The weight a gift gives is multiplied by 1.4 for Liked gifts, and by 2 for Loved gifts (this includes infused dishes).
  - In the special case you give someone a disliked food. They will not eat it, and their weight will not go up.
- Salads and crops that are leafy greens will subtract weight, multipliers included.
- Crops are practically worthless in terms of adding weight, each is set to add .1 pounds. So, if you want to have
  someone gain weight give them actual prepared food.
- On average, dishes give weight at about 1 pound per star, plus or minus based on the ingredients used.
  - i.e., fried dishes, dairy-heavy dishes, festival foods, and desserts all lean a bit heavier than their star count.
- You cannot make a weight stat go lower than its starting amount, effectively their weight gain total gets reset to 0 if it goes negative
