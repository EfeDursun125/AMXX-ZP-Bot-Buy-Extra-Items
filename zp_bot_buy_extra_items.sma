#include <amxmodx>
#include <amxmisc>
#include <zombieplague>

// define is not registered as *variable*
// so it does not use ram, so use define instead of const
#define PLUGIN_VERSION "0.4"
#define EXTRA_ITEM_NAME_LENGTH 64
#define EXTRA_ITEM_NAME_LENGTH_DOUBLE EXTRA_ITEM_NAME_LENGTH * 2
#define EXTRA_TASK_ID 532

new Array:ListOfExtraItems

#define EXTRA_FREE "zp_bot_buy_extra_item_for_free"
// https://github.com/EfeDursun125/AMXX-ZP-Bot-Buy-Extra-Items
// use this to save bots ammo packs

// not using cvar pointer because of the ram limit
// also these are called less, not every time so don't worry
#define EXTRA_TIME_MIN "zp_bot_buy_extra_item_time_min"
#define EXTRA_TIME_MAX "zp_bot_buy_extra_item_time_max"
public plugin_init()
{
	register_plugin("[ZP] Bot Buy Extra Items", PLUGIN_VERSION, "EfeDursun125")
	register_cvar("zp_bot_buy_extra_item_version", PLUGIN_VERSION)
	register_cvar(EXTRA_FREE, "0")
	register_cvar(EXTRA_TIME_MIN, "10.0")
	register_cvar(EXTRA_TIME_MAX, "60.0")
	register_concmd("zp_bot_buy_extra_item_list", "cmd_list_extra", _, "Lists the all detected extra items bots can buy", 0)
}

public plugin_cfg()
{
	load_data()
}

public plugin_end()
{
	ArrayDestroy(ListOfExtraItems)
}

public zp_round_started(gamemode, id)
{
	new i
	new maxPlayers = get_maxplayers() + 1
	new Float:min = get_cvar_float(EXTRA_TIME_MIN)
	new Float:max = get_cvar_float(EXTRA_TIME_MAX)
	for (i = 1; i < maxPlayers; i++)
	{
		if (!is_user_connected(i))
			continue

		if (!is_user_bot(i))
			continue

		set_task(random_float(min, max), "bot_buy_extra_item", i + EXTRA_TASK_ID)
	}
}

public bot_buy_extra_item(id)
{
	id -= EXTRA_TASK_ID
	if (!is_user_alive(id))
		return

	if (!is_user_bot(id))
		return

	if (!zp_has_round_started())
	{
		set_task(random_float(get_cvar_float(EXTRA_TIME_MIN), get_cvar_float(EXTRA_TIME_MAX)), "bot_buy_extra_item", id + EXTRA_TASK_ID)
		return
	}

	if (zp_force_buy_extra_item(id, ArrayGetCell(ListOfExtraItems, random_num(0, ArraySize(ListOfExtraItems) - 1)), get_cvar_num(EXTRA_FREE)))
	{
		// rarely get one more %33.333
		if (random_num(1, 3) == 1)
			set_task(random_float(get_cvar_float(EXTRA_TIME_MIN), get_cvar_float(EXTRA_TIME_MAX)), "bot_buy_extra_item", id + EXTRA_TASK_ID)
	}
	else
	{
		// try to buy something else %67.777
		if (random_num(1, 3) != 1)
			set_task(random_float(get_cvar_float(EXTRA_TIME_MIN), get_cvar_float(EXTRA_TIME_MAX)), "bot_buy_extra_item", id + EXTRA_TASK_ID)
	}
}

public load_data()
{
	ListOfExtraItems = ArrayCreate(1, 1)

	new path[256]
	get_configsdir(path, charsmax(path))
	formatex(path, charsmax(path), "%s/zp_extraitems.ini", path)
	new file = fopen(path, "rt")
	if (!file)
	{
		// are we using zpsp?
		get_configsdir(path, charsmax(path))
		formatex(path, charsmax(path), "%s/zpsp_extraitems.ini", path)
		file = fopen(path, "rt")
		if (!file)
		{
			// latest version?
			get_configsdir(path, charsmax(path))
			formatex(path, charsmax(path), "%s/zpsp_configs/zpsp_extraitems.ini", path)
			file = fopen(path, "rt")
			if (!file)
				return
		}
	}

	new id
	new lineText[EXTRA_ITEM_NAME_LENGTH_DOUBLE], left[EXTRA_ITEM_NAME_LENGTH], right[EXTRA_ITEM_NAME_LENGTH]
	while (!feof(file))
	{
		fgets(file, lineText, EXTRA_ITEM_NAME_LENGTH_DOUBLE)
		replace(lineText, EXTRA_ITEM_NAME_LENGTH_DOUBLE, "^n", "")

		if (!lineText[0] || lineText[0] == ';')
			continue

		trim(lineText)
		strtok(lineText, left, EXTRA_ITEM_NAME_LENGTH_DOUBLE, right, EXTRA_ITEM_NAME_LENGTH, '=')
		trim(left)

		if (!equal(left, "NAME"))
			continue

		trim(right)
		id = zp_get_extra_item_id(right)
		if (id != -1)
			ArrayPushCell(ListOfExtraItems, id)
	}

	fclose(file)
}

public cmd_list_extra(id, level, cid)
{
	if (!cmd_access(id, ADMIN_KICK, cid, 1))
		return PLUGIN_HANDLED

	// if extra item id list is 0, we cannot write the extra item names
	if (ArraySize(ListOfExtraItems) <= 0)
	{
		console_print(id, "ERROR: NO EXTRA ITEMS FOUND!")
		return PLUGIN_HANDLED
	}

	new path[256]
	get_configsdir(path, charsmax(path))
	formatex(path, charsmax(path), "%s/zp_extraitems.ini", path)
	new file = fopen(path, "rt")
	if (!file)
	{
		// are we using zpsp?
		get_configsdir(path, charsmax(path))
		formatex(path, charsmax(path), "%s/zpsp_extraitems.ini", path)
		file = fopen(path, "rt")
		if (!file)
		{
			// latest version?
			get_configsdir(path, charsmax(path))
			formatex(path, charsmax(path), "%s/zpsp_configs/zpsp_extraitems.ini", path)
			file = fopen(path, "rt")
			if (!file)
			{
				console_print(id, "ERROR: NO EXTRA ITEMS FOUND!")
				return PLUGIN_HANDLED
			}
		}
	}

	new id
	new lineText[EXTRA_ITEM_NAME_LENGTH_DOUBLE], left[EXTRA_ITEM_NAME_LENGTH], right[EXTRA_ITEM_NAME_LENGTH]
	while (!feof(file))
	{
		fgets(file, lineText, EXTRA_ITEM_NAME_LENGTH_DOUBLE)
		replace(lineText, EXTRA_ITEM_NAME_LENGTH_DOUBLE, "^n", "")

		if (!lineText[0] || lineText[0] == ';')
			continue

		trim(lineText)
		strtok(lineText, left, EXTRA_ITEM_NAME_LENGTH_DOUBLE, right, EXTRA_ITEM_NAME_LENGTH, '=')
		trim(left)

		if (!equal(left, "NAME"))
			continue

		trim(right)
		console_print(id, "--> %s", right)
	}

	fclose(file)
	return PLUGIN_HANDLED
}
