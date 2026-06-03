# HARDCORE Debug Commands

Debug commands require **Debug mode** to be enabled in the addon settings.

All commands use the `/hc debug` prefix.

## General

| Command | Effect |
| --- | --- |
| `/hc debug help` | Prints the debug command list in chat. |
| `/hc debug status` | Prints the main challenge status and available feat debug statuses. |
| `/hc debug revive` | Resets a failed challenge state so the run can be started again. |
| `/hc debug resetdeath` | Alias for `/hc debug revive`. |
| `/hc debug failui` | Opens a preview-safe version of the failed challenge panel. |
| `/hc debug deathui` | Alias for `/hc debug failui`. |
| `/hc debug victoryui` | Opens a preview-safe version of the victory panel. |
| `/hc debug winui` | Alias for `/hc debug victoryui`. |
| `/hc debug feats abandon` | Disables all selected feat rules. |

## Trail Rations

| Command | Effect |
| --- | --- |
| `/hc debug rations full` | Sets hunger and thirst to full. |
| `/hc debug rations empty` | Sets hunger and thirst to empty. |
| `/hc debug rations set <hunger> <thirst>` | Sets hunger and thirst values. |
| `/hc debug rations decay <minutes>` | Applies the configured meter decay for the given number of minutes. |
| `/hc debug rations hud` | Forces the Trail Rations HUD visible until the next scene or update refresh. |

## Road Weariness

| Command | Effect |
| --- | --- |
| `/hc debug weariness full` | Sets fatigue to full. |
| `/hc debug weariness empty` | Sets fatigue to empty and runs fatigue enforcement. |
| `/hc debug weariness set <fatigue>` | Sets fatigue to the given value and runs fatigue enforcement. |
| `/hc debug weariness rest` | Starts forced rest. |
| `/hc debug weariness stop` | Stops forced rest. |
| `/hc debug weariness hud` | Forces the Road Weariness HUD visible until the next scene or update refresh. |

## Mandatory Bath Time

`swim` is accepted as an alias for `bath`.

| Command | Effect |
| --- | --- |
| `/hc debug bath status` | Prints Mandatory Bath Time status. |
| `/hc debug bath due` | Starts the bath grace countdown immediately. |
| `/hc debug bath progress <seconds>` | Sets current bath progress in seconds. |
| `/hc debug bath reset` | Resets the bath timer and bath progress. |
| `/hc debug bath hud` | Forces the Mandatory Bath Time HUD visible until the next scene or update refresh. |

## Need of Blood

`needblood` is accepted as an alias for `blood`.

| Command | Effect |
| --- | --- |
| `/hc debug blood status` | Prints Need of Blood status. |
| `/hc debug blood due` | Starts the 20-second blood demand immediately. |
| `/hc debug blood satisfy` | Satisfies the active blood demand and restarts the ten-minute timer. |
| `/hc debug blood reset` | Restarts the ten-minute timer and clears the active demand. |
| `/hc debug blood hud` | Forces the Need of Blood HUD visible until the next scene or update refresh. |

## Lockpick Nerves

| Command | Effect |
| --- | --- |
| `/hc debug lockpick status` | Prints Lockpick Nerves status. |
| `/hc debug lockpick fail` | Adds a failed-lockpick strike. |
| `/hc debug lockpick break` | Adds a broken-lockpick strike. |
| `/hc debug lockpick success` | Removes a strike as if a lockpick succeeded. |
| `/hc debug lockpick reset` | Clears current lockpick strikes. |
| `/hc debug lockpick hud` | Forces the Lockpick Nerves HUD visible until the next scene or update refresh. |

## Barbarian

| Command | Effect |
| --- | --- |
| `/hc debug barbarian status` | Prints Barbarian status. |
| `/hc debug barbarian enforce` | Runs Barbarian enforcement immediately. |

## Hands Free

`hands` is accepted as an alias for `handsfree`.

| Command | Effect |
| --- | --- |
| `/hc debug handsfree status` | Prints Hands Free status. |
| `/hc debug handsfree enforce` | Runs Hands Free enforcement immediately. |

## Self Made

`self` is accepted as an alias for `selfmade`.

| Command | Effect |
| --- | --- |
| `/hc debug selfmade status` | Prints Self Made status. |
| `/hc debug selfmade enforce` | Runs Self Made enforcement immediately. |

## Current Gaps

No slash debug handlers currently exist for:

- No Swimming
- Nudist
- No Potions
