BASIC_ROBOT: lightweight robot mod for multiplayer
minetest 0.4.14
(c) 2016 rnd

MANUAL:
	1. ingame help: right click spawner (basic_robot:spawner) and click help button

---------------------------------------------------------------------
This program is free software: you can redistribute it and/or modify
it under the terms of the GNU General Public License as published by
the Free Software Foundation, either version 3 of the License, or
(at your option) any later version.

This program is distributed in the hope that it will be useful,
but WITHOUT ANY WARRANTY; without even the implied warranty of
MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
GNU General Public License for more details.

You should have received a copy of the GNU General Public License
along with this program.  If not, see <http://www.gnu.org/licenses/>.
----------------------------------------------------------------------


GAMEPLAY:

- robot has limited operations available every run ( 1 run per 1 second).
- while using for loops, while loops or function calls it is limited to default 48 such code executions per run
- while using 'physical' operations like move/dig robot has (default) 10 operations available per run. Default costs are
  move=2, dig = 6, insert = 2, place = 2, machine.generate = 6, machine.smelt = 6, machine.grind = 6,