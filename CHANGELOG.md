# Change Log

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](http://keepachangelog.com/) 
and this project adheres to [Semantic Versioning](http://semver.org/).

## [Unreleased]

### Added

### Changed

### Fixed

### Removed


## [1.0.3.400]

### Added

- Atea.Windows.Installer project Added
- Release folder created
- Automatic builds and MSI-packaging to /Release folder
- Powershell based installation/update scripts
- This changelog!
- File Age Monitor
- MonitoredEvent class, task and discovery
- MonitoredEvent dependency monitor on Microsoft.Windows.Computer
- [Missing Service monitor (@svantegraden)](https://github.com/stegenfeldt/Atea.Windows/pull/53)
- Basic file share monitoring
- [Registry Based event log monitoring](https://github.com/stegenfeldt/Atea.Windows/pull/37)

### Changed

- Updated documentation design
- Install Script no longer uses the MSI-file, works directly with mp-files
- [File Age Monitor has parameter for number of files](https://github.com/stegenfeldt/Atea.Windows/pull/48)


### Fixed

- [Svc Recovery alert has wrong eventlog name #6](https://github.com/stegenfeldt/Atea.Windows/issues/6)
- Reconfigured Auto Deploy after extension update
- Adv Service Recovery logging to task output
- Exclusions on AutoService discovery
- Standard Service Restart recovery task now supports services with spaces
- Service displaystring discovery
- [File Age monitor truncates description to avoid buffer overflow (@AndreasB-atea)](https://github.com/stegenfeldt/Atea.Windows/pull/49)
- [Fixed Azure Pipeline for build checking](https://github.com/stegenfeldt/Atea.Windows/pull/39)

### Removed

- Old Downloads folder

## [1.0.2] - 2016-10-25

### Added

- Atea.Windows.File.Monitoring MP from Atea.FileCreationTime, refactored for VSAE
- Documentation available at [https://stegenfeldt.github.io/Atea.Windows](https://stegenfeldt.github.io/Atea.Windows)
- List Running Services tasks
- Timed Powershell Probe module
- Automatic build-artefact copied to /Released
- MIT licensing
- Advanced Service Restart tasks

### Changed

- Bunch of spellchecks

### Fixed

- "undiscovery" of services when last service is gone

## [1.0.1] - 2016-01-12

### Added

- New class for Powershell enabled windows servers
- Discovery of "Automatic" services, disabled by default
- Service exclusion support in Automatic discovery
- Recovery Monitor on monitored services for automatic restart
- DiskUsedGB performance collection rule

### Changed

- Converted Atea.WinSvc to VSAE project in Atea.Windows solution
- Refactored Atea.WinSvc to Atea.Windows.Service
- Updated discovery scripts to Powershell
- Shared and Own process services are now using the correct base class


[Unreleased]: https://github.com/stegenfeldt/Atea.Windows/compare/v1.0.3.400...HEAD
[1.0.3.400]: https://github.com/stegenfeldt/Atea.Windows/compare/v1.0.2.0...v1.0.3.400
[1.0.2]: https://github.com/stegenfeldt/Atea.Windows/compare/1.0.1.0...v1.0.2.0
[1.0.1]: https://github.com/stegenfeldt/Atea.Windows/compare/881b4000996b2785529d79e09279262a390ba972...1.0.1.0
