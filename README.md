# turn scripts into self-contained systemd services

## Motivation

Using systemd services and timers to run scheduled maintenances jobs, I usually create dedicated scripts that I call from `ExecStart` since it's not suitable to put non-trivial tasks in there. That in turn makes the systemd service depend on and external file that I have to place and maintain separately from it. But most of the time I'd prefer to have self-contained services without the need for external files...

## Solution

...so one day I attached a script to a service, disguised as comment block ("payload"). The service would then extract that payload from itself, put it into a script and execute that - et voilà!

To compensate for the loss of maintainability - e.g. a shellscript is developed and tested best as a shellscript, not as a comment block in a foreign file - I am creating little helpers named `<something>2service.sh` to assist with turning a script into a systemd service and the other way around.

## Requirements

You need bash.

## Usage

> TBD

## License

[MIT](LICENSE) © 2020 Generali Deutschland Informatik Services GmbH
