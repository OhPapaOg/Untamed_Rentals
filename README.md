
# Untamed Rentals

Untamed Rentals is a script that allows players to rent wagons in the game. Players can access a menu to rent different types of wagons, store and retrieve items, and return the wagons to specific locations for a refund.

## Features

- **Rent Wagons**: Players can rent various types of wagons, each with its own price and properties.
- **Store and Retrieve Items**: For wood and ore wagons, players can store and retrieve items from the wagons using in-game prompts.
- **Configurable Locations**: Set up multiple rental and return locations with configurable prompts and wagon spawn points.
- **Dynamic Prop Sets**: Visual indication of stored items using prop sets for specific wagon types.
- **Refund System**: Players receive a refund when returning rented wagons to designated locations.

## Installation

1. **Download and Extract**: Download the script and extract it into your resources folder.
2. **Rename the Folder**: Ensure the folder is named `untamed_rentals`.
3. **Add to Server Config**: Add `ensure untamed_rentals` to your `resources.cfg`.
4. **Configuration**: Customize the script by editing the `config.lua` file to fit your server's needs.

## Configuration

Edit the `config.lua` file to configure rental and return locations, wagon types, prices, allowed items, and localization strings.

## Usage

### Renting a Wagon

Players can approach a rental location and press the configured prompt key to open the wagon rental menu. They can choose a wagon to rent and it will spawn at the designated location.

### Storing and Retrieving Items

For wood and ore wagons, players can store and retrieve items by approaching the wagon and using the corresponding prompts.

### Returning a Wagon

Players can return a rented wagon to a designated return location to receive a refund. The return prompt will only appear when the player is at the return location with the rented wagon.

## Contributing

If you wish to contribute to this project, feel free to fork the repository and make modifications. Pull requests are welcome!

## License

This project is licensed under the GNU General Public License. See the LICENSE file for details.
