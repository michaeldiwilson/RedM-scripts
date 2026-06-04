# RedM RP Scripts

A collection of roleplay scripts for RedM servers running RSGCore.

## Scripts

| Script | Description | SQL Required |
|--------|-------------|:---:|
| mike-adminmenu | Admin panel with teleport, player management, bans, inventory tools | Yes |
| mike-crafting | Placeable crafting bench with NUI, blueprint-gated recipes | No |
| mike-exchange | Item exchange/trading system | No |
| mike-farming | Plant-anywhere crop farming with growth stages | Yes |
| mike-hunting | Hunting, skinning, carcass loading and butcher selling | No |
| mike-lumber | Tree chopping and sawmill processing | No |
| mike-mining | Rock mining and ore smelting | No |
| mike-moonshine | Build-your-own still moonshine production and selling | Yes |
| mike-property | Property building and ownership | No |
| mike-wagons | Wagon spawning, ownership and storage | No |

## Dependencies

All scripts require these base dependencies:

- [rsg-core](https://github.com/Suspended-Suspended/rsg-core) - Core framework
- [rsg-inventory](https://github.com/Suspended-Suspended/rsg-inventory) - Inventory system
- [ox_lib](https://github.com/overextended/ox_lib) - Progress bars, notifications, dialogs
- [ox_target](https://github.com/overextended/ox_target) - Interaction zones
- [oxmysql](https://github.com/overextended/oxmysql) - Database (required by scripts with SQL)

### Optional Cross-Resource Integration

- **mike-hunting** can optionally load carcasses onto **mike-wagons** (hunting wagons). Both scripts work independently without each other.
- **mike-adminmenu** references **rsg-medic** for the player revive function.

## Installation

1. Ensure you have all base dependencies installed and running.

2. Copy the script folders you want into your server's `resources/` directory.

3. Run any required SQL files from the `sql/` folder against your database:
   - `02-mike-adminmenu.sql` - Required for mike-adminmenu
   - `03-mike-adminzones.sql` - Required for mike-adminmenu
   - `04-mike-farming.sql` - Required for mike-farming
   - `05-mike-moonshine.sql` - Required for mike-moonshine

4. Add the scripts to your `server.cfg`:
   ```
   ensure mike-adminmenu
   ensure mike-crafting
   ensure mike-exchange
   ensure mike-farming
   ensure mike-hunting
   ensure mike-lumber
   ensure mike-mining
   ensure mike-moonshine
   ensure mike-property
   ensure mike-wagons
   ```

5. Restart your server.

## Configuration

Each script has a `config.lua` file where you can adjust settings like locations, prices, timers, recipes, and more.

## License

MIT
