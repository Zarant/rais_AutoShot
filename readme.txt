A few improvements were made over the original rais_AutoShot addon by raisnilt:
-Increased its reliability
-Fixed the expose weakness bug
-Weapon swap properly reset the swing timer
-Added a latency compensation mechanism
-Added a 1 button shot rotation macro
	
Lets say you have 100ms ping, You can type in-game /run autoshot_latency = 100 to show a 100ms compensation, a gray bar will give you a green light to start a special attack or to move around without clipping an auto shot.

By making a macro with /run ShotRotation(100) will automate your single target shot rotation with a 100ms latency compensation.

It requires some experimentation to figure out which value works best for you, but as a general rule, it should not be greater than your latency displayed on the game client.
	
