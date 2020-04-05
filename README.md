
NoClocks
========

Demonstration of clocks in VRChat:

* SDK2 by use of `VRC_Panorama`
* SDK3 by use of Udon

Both solutions use a shader for turning the hands. With Udon
you no longer necessarily need to; I just feel it's a cooler
solution to the problem. Feel free to disagree.

It's something that has been done before but I feel like I had
the solution first and just got prevented from release due to
various badly-timed events.


Missing Dependencies
--------------------

This repository omits VRCSDK as it is not legal to redistribute.
Download the latest version from the [VRChat site][1] in order to
use this repository.

SDK2 project uses VRCSDK2. SDK3 project uses VRCSDK3.

[1]: https://vrchat.com/


Redistribution
--------------

Redistribution possible under MIT licence. See `COPYING.txt`.

Would appreciate credit being given, but not required.


Usage
-----

`NoClocks.unity` in each project contains a demo scene.
`Prefabs/` in the SDK2 project contains some sample prefabs
used by the demo scene.

Prefabs are pointing at a server hosted on Heroku at the moment.
Code for this will most likely be released if issues occur with
this server being hit too hard.

The URLs in the `VRC_Panorama` can be modified to suit. See the
time server API information below.


Time Server API
---------------

**`https://noclocks.herokuapp.com/api/1/local`**

Gives the current time in local time, defaulting to UTC, in a
4-pixel layout.

Supported parameters:

* `size=32`

    Changes the size of the pixels to 32x32.

* `tz=Asia/Tokyo`

    Sets the time zone to Japan Time.

    For a list of time zone IDs, see [Wikipedia][2].
    If you find one which is not supported (which could happen for
    very new time zones) contact me and I'll see how hard it is to
    get the list updated.

* `now=2020-03-20T20:05:00Z`

    Returns a given time zone. Mostly useful for testing.

Combining these is the same as normal URL queries, e.g.
`https://noclocks.herokuapp.com/api/1/local?tz=Asia/Tokyo&size=32`

[2]: https://en.wikipedia.org/wiki/List_of_tz_database_time_zones

**`https://noclocks.herokuapp.com/api/1/utc`**

Gives the current time in UTC, in a 1-pixel layout.

Currently this is not in use by this shader, but it's
mentioned here for completeness.

