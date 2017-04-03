# Atea.Windows.Service.Monitoring

The Atea Windows Service Monitoring pack contains a few tasks, discoveries and monitors to make it easier from the regular console to add monitoring to a new Windows Service.
Although it contains its own classes, it does discover objects based on the normal Windows Service classes and all discovered services will be monitored the same way as if they were added using the Windows Service Monitoring Template.
Main difference being that the objects are contained in a sealed MP and can be added to Distributed Applications, Groups et.c.

## Instructions

### Monitoring a new Service

* Navigate to the Windows Computer view under the Monitoring workspace.
* Find the computer that has the service running
* Execute the task "Add Monitored Service"
* **Override** the parameters and replace CHANGEME with the ServiceName (NOT it's display name)

The discovery has two stages.

1. Find the seed classes, runs every four hours
2. Targeted to the seed objects, find services configured for monitoring, runs every four hours

To if you're in a rush, you can speed up the discovery by restarting the agent twice with about five minutes in between to be on the safe side.

Monitored services will be found under "Windows Service and Process Monitoring" as with all other monitored services.

## References

* Health Library
* System Library
* Windows Core Library
* Windows Service Library

## Classes

### Atea.Windows.Service.Service

### Atea.Windows.Service.Seed

### Atea.Windows.Service.SharedService

## Monitors

## Rules

## Discoveries
