Product Discovery
-----------------

The Catalogue is a central element of the Teadal architecture, facilitating
data product discovery, contract management, and other essential functions.
It stores all the data needed for consumers to discover FDPs within
a Teadal federation and offers convenient means to query that information.

Each Teadal node in a federation may deploy its own Catalogue. In this
decentralised setup, all Catalogue instances share the same information
about the available FDPs across the entire federation. For example,
if Teadal node A offers FDP#1 and node B offers FDP#2, both Catalogue
instances—one in node A and one in node B—will contain data about both
FDPs. The Catalogues share FDP information by replicating FDP data
in their own Redis databases. For example, the Catalogue in node A
could be configured as a master whereas the Catalogue in node B would
be a replica, pulling data from the master. Note that this pull-based
replication is built into the Catalogue and, as such, more convenient
than Redis native replication, although Redis native replication may
be configured too. Regardless, in a decentralised Catalogue setup,
Teadal nodes exchange FDP information over the Redis protocol.

Another possibility is to have a centralised Catalogue serve a whole
Teadal federation. In this case the Catalogue runs in only one Teadal
node but it still holds information about the available FDPs across
the entire federation. For example, if Teadal node A offers FDP#1 and
Teadal node B FDP#2, a centralised Catalogue deployed in node A will
reference both FDP#1 and FDP#2.

![Catalogue federation between two Teadal nodes.][discovery.dia]




[discovery.dia]: ./product-discovery.png
