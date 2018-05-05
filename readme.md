# What's this?

In short: GIS stands for Geographical Information System and enables manipulating sets of spatial points and objects.

This is summary of efforts required for my scientific research. This includes different operations on set of GIS points like filtering, measuring distances, filtering duplicates, and rendering the final maps overlayed over base map.

With hope that it will also might be useful for Castle Game Engine GIS - like applications. Yes, that's a game engine, it doesn't need to have fancy GIS features.

# What's the goal? (why)

First of all, I need such module for my scientific work to make some specific calculations on geographical statistics of some extreme natural phenomenon (earthquakes and tornadoes) and analyze the risk they pose to ecology, people and industry, create visual materials for scientific papers. This also means I'm officially allowed to do this during work hours :)

Second, I got a "request" from a good friend of mine to write a GPS-based quest game for children summer camp by July 2018. I still lack understanding on how to add GeoLocation service to Castle Game Engine (yeah, my knowledge of Android programming and Java is zero), but anyway I'll need GIS features to implement it once GeoLocation is available in the Engine.

The third and the most "ambitious" goal is to create a Universe generator for Decoherence game (and I believe it might also be useful in Castle Game Engine too, probably as an "asset"). To cut it short, it will generate galaxies, stellar systems and planetoids. To optimize performance it will render the result into a skybox and will provide natural climate models, topology and day-and-night cycle for planets. The final result will be ability to create relatively small locations (much smaller than planet radius) at different generated planets, experience dynamic weather, and geologically (astrophysically) justified topology generation. Finally we can look in the sky, see what's the weather at nearby planet, teleport there and enjoy the thunderstorm we saw 3 a.u. away. This is practically impossible without creating a planetary GIS system.

# Limitations

As far as I don't need vector or polygonal GIS data at the moment, I'm not sure if I'll implement those. Thou it might be useful, e.g. in case we want to add OpenStreetMap support.

No support for topology map yet. However, I might need those in nearest future.

I'm using only WGS84 coordinates system with no projections. This is enough for my applications and games, however, it might be needed some day to implement projection changing.

Scaling of the base map is linear. Some day other projections may be used, but this is enough for me at the moment.
