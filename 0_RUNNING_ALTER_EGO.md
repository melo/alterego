Format: complete
Title: How to use Alter Ego

Introduction
============

Alter Ego is a XMPP agent, a bot that runs using your own JID, but with a negative priority.

It allows you to deploy XMPP-based services that can be controlled using your roster and your buddies presence status.

Alter Ego is licensed under the Artistic License.


How to run
----------

Running Alter Ego is a three step process:

 * install dependencies;
 * configure Alter Ego;
 * start Alter Ego.


### Dependencies ###

Alter Ego is written in Perl, and requires some modules available at CPAN.

For now, you have to install those manually. Usually it should be as simple as:

    cpan module_name

The modules you need are:

 * `Net::XMPP2`;
 * `Carp::Clan`;
 * `Config::Any`;
 * `DateTime`;
 * `Module::Pluggable`;
 * `Scope::Guard`;
 * `Class::C3::Componentised`.


### Configure Alter Ego ###

Right now, Alter Ego is written to run directly from the unpacked directory.

First you need to copy the `etc/alter_ego_cfg.json` configuration file to the root of the project as `.alter_ego_cfg.json` and edit with your account information.


### Running Alter Ego ###

From the root of the unpacked directory run `./bin/alter_ego`.



Plugins
=======

Alter Ego is based on Plugins. Every functionality is a plugin.

Right now, the only Plugin available is a [User Location](http://www.xmpp.org/extensions/xep-0080.html "XEP-0080: User Location").

If you want to create your own plugins, see the `1_PLUGINS.md` file.


User Location
-------------

The User Location plugin does three things:

 * it discovers your current default gateway, and his mac address;
 * searches a set of local location databases that map mac address =>
   XEP-0080 attributes;
 * if found, update your XEP-0080 node.

To use this, you just have to copy the sample user location database in
`etc/sample_user_location_db.json` to the root project directory as
`.location_db.json` and update it with your own locations.

There is no need to restart the agent whenever you change this database. All modifications
will be picked up automatically.
