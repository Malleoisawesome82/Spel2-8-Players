/!\ /!\ /!\ ONLY DOWNLOAD THIS MOD FROM TRUSTED SOURCES /!\ /!\ /!\ 
           	 (Spelunky.fyi, Modlunky Menu, Github repository)
Disclaimer: The mod is considered "unsafe" due to the requirement of UdpServer methods. Hosting a server will require knowledge on how to port forward and assumes any risk that comes with hosting a server on the internet. Joining a server assumes any risk with giving your IP to someone, but do feel free to use a VPN. Ignore this warning if you are only doing LAN / Multi-Instance / Local sessions.

  v0.10.3.2b
I believe the mod is stable enough to upload to github and let random people download and try it out.
this is ABSOLUTELY NOT the first version, nor will it be the last. If the reception is positive then I may try my hand at adding rollback on top of the current input delay system. 
Any version starting with v0 is a pre-release version with no guarantees of stability. v1 versions are full release versions that assume everything is steady enough for a young child to be able to set up or join a server and start playing. v2 is not planned currently but if it were to release, it would include major change such as rollback, full 8 player compatibility with the base game, or maybe API function hijacking for other mods to recognize the extra players with functions like `get_player()` and the `players` table.

  What is this?
Spelunky 2 is an adventure game where you explore caves and supports up to 4 player simultaneous online co-op. I got bored one day and decided to entertain a what-if, and that was "What if there was 8 player online support, and what if i could join an online game with 2 people on the same client?" so i got to work. After almost a year of on and off work and dealing with API hauntings, this is the result of that effort. 

Spelunky.fyi is a website specifically for Spelunky mods and scripting thereof. The current version on there as of now is 0.10.2.5, a test version which is missing server hosting capabilities and contains a bug that only allows clients to spawn 7 players instead of 8, and is missing the `Network Profile` feature. On that website you can also download Modlunky, which is a program that lets you easily install and update Spelunky mods. Using the install code `8-players` in Modlunky will download this mod from the Spelunky.fyi website. 

  How to play?
First you need Spelunky 2. Second you need a way to run this mod, either through a modloader (Modlunky) or using Overlunky (Not recommended). Then if you're hosting a server and letting people on the open internet join, you either need to use a game hosting tunneler like Playit.gg, VPN hosting like LogMeInHamachi, or traditional port forwarding methods. If you're a little paranoid and don't want to expose your IP to random people then I'd recommend the first two methods. If you're instead joining a server and don't want to expose your IP you can use a VPN. See readme.txt for more details. Under no circumstance should you download this mod from unofficial sources because annoyingly, Spelunky 2's mod loader doesn't tell you *why* a mod is unsafe, it just tells you that it is. This means that a bad actor can take my mod, put malicious code in, then lie to people saying it is my mod to get them to download it, and nobody would be suspicious because this mod is already marked as "unsafe." 

If you want to replace your mod with the scripts in the github repository, simply download and place them in the folder, making sure to replace the originals. 

-------------------------------------------------------

   Some terminology
Manager - The mod is split into 2 parts. 1 part handles the 8 player adventure co-op, and the other part handles the networking functionality. I call them the `Local Manager` and `Online Manager` respectively.
Online Panel - A window that allows you to set your name and host/join a game. Extra options will appear for the Host.
Local - You're running the 8 player adventure mod with only 1 instance and NOT using the online panel to get extra players.
Instance - An open, running game window of Spelunky 2. 
Session - When an online game is created and people on different clients can join.
Multi-Instance Session - You're running 2 or more instances of Spelunky 2 on the same device and you're using the Online Panel to connect both of them together. 
Network Profile - There are 4 different profiles depending on your session type. Those being: `Wi-Fi (Good)`, `Wi-Fi (Poor)`, `LAN`, and `Multi-Instance`. These slightly adjust the behavior of both Managers for the smoothest experience for the end user. For example, setting the Network Profile to `Multi-Instance` will allow for unfocused gamepad input for any instance that enables it.


How To......

How to join a server:
1. Make sure the host unlocks the player list before joining
2. Type in the server IP and Port and click join
3. If successful, you will join the server. Wait for the host to start the game
4. Once started, you should be brought to the character select screen. Once everyone chooses their character, the game will start

How to make a public wi-fi server:
1. You must assume all risk associated with hosting a server on the internet
2. Set your IP address to your computer's IPv4 address
3. You don't need to change the port, unless you encounter a "Failed to bind to port" error.
4. Once the server is onlinle and you're ready for your friends to join, press the "Unlock player list" button so people are able to join.
5. Set the network profile to Wifi (Good). If you expect a lot of players or you're expecting long distance players, make sure everyone uses Wifi (Poor) instead.
6. Give your spelunking team your IPv6 address, or if you have setup a DNS link, give them that instead. 
7. Once everyone is in, set the seed if you'd like and press "Start Game!"

How to make a LAN server:
1. Portforwarding will not be necessary if all clients are on the same network. 
2. Set your IP address to your computer's IPv4 address
3. You don't need to change the port, unless you encounter a "Failed to bind to port" error.
4. Set the Network Profile to "LAN"
5. Give your spelunking team your IPv4 address.
6. Once everyone is in, set the seed if you'd like and press "Start Game!"

How to make a Hamachi/RadminVPN/Other server:
1. Get everyone into the same Hamachi Server or whatever relevant app is used
2. Use the IP provided by Hamachi as your "IPv4" adress to input into the menu. The port should only be changed if needed.
3. Set the Network Profile to Wifi (Good). Use Wifi (Poor) instead if you expect long distance connections or high player count.
3. Once the server is onlinle and you're ready for your friends to join, press the "Unlock player list" button so people are able to join.
4. Other users in the server will use your Hamachi IP to join your game

How to make a server for running 2 or more instances on 1 computer:
1. You may use either your IPv4 address or "127.0.0.1", just make sure each instance uses the same IP.
2. You don't need to change the port, unless you encounter a "Failed to bind to port" error.
3. Once the server is online, set Network Profile to "Multi-Instance Session"
4. Once both instances are in, set the seed if you'd like and press "Start Game."
Multi-Instance Limitations -
All players controlled with keyboard inputs must be on the same screen, 
  for if the game is not focused and there are keyboard players, it will pretend like 
  a controller was disconnected.
Music will be disabled on all but 1 client to prevent an annoying overlapping soun
Names are disabled on the ingame HUD because everyone's on the same computer.
The game window with keyboard players must always be focused
You can no longer change to Xbox controller inputs by pressing A during the session.

-------------------------------------------------------


if your version number is suffixed with a...
c - (ClientOnly) this is a test version where you can't host a server since the mod is still under heavy development
4 - (4Player) this is a test version that only supports players 1-4
p - (Private) this version is a private version and shouldn't be shared with others
r - (unReady) this version has issues and isn't ready for playing normally
d - (Debugging print Statements) this version has extra intrusive print statements
u - (Untested) this version isn't thoroughly tested and you may encounter nasty bugs
b - (Beta) this version isn't the release version found on spelunky.fyi
m - (Many) this version has many factors that make it unpresentable/unplayable because it's actively being worked on
