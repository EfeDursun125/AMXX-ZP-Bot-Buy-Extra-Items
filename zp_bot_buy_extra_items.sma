#include <amxmodx>
#include <amxmisc>
#include <zombieplague>

// define is not registered as *variable*
// so it does not use ram, so use define instead of const
#define PLUGIN_VERSION "0.2"
#define EXTRA_ITEM_NAME_LENGTH 32
#define EXTRA_ITEM_NAME_LENGTH_DOUBLE EXTRA_ITEM_NAME_LENGTH * 2
#define EXTRA_TASK_ID 532

new Array:ListOfExtraItemNames

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
	load_data()
}

public plugin_end()
{
	ArrayDestroy(ListOfExtraItemNames)
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

		if (!is_user_alive(i))
			continue

		set_task(random_float(min, max), "bot_buy_extra_item", i + EXTRA_TASK_ID)
	}
}

public bot_buy_extra_item(id)
{
	id -= EXTRA_TASK_ID
	if (!is_user_connected(id))
		return

	if (!is_user_bot(id))
		return

	if (!is_user_alive(id))
		return

	new name[EXTRA_ITEM_NAME_LENGTH]
	ArrayGetString(ListOfExtraItemNames, random_num(0, ArraySize(ListOfExtraItemNames) - 1), name, EXTRA_ITEM_NAME_LENGTH)
	//zp_force_buy_extra_item(id, zp_get_extra_item_id(name), get_cvar_num(EXTRA_FREE))

	// sometimes bots are happier now
	if (random_num(1, 11) == 1)
		client_cmd(id, "say i am happy with my %s", name)

	// rarely get one more
	if (random_num(1, 3) == 1)
		set_task(random_float(get_cvar_float(EXTRA_TIME_MIN), get_cvar_float(EXTRA_TIME_MAX)), "bot_buy_extra_item", id + EXTRA_TASK_ID)
}

public load_data()
{
	ListOfExtraItemNames = ArrayCreate(EXTRA_ITEM_NAME_LENGTH, 1)

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
		ArrayPushString(ListOfExtraItemNames, right)
	}

	fclose(file)
}

public cmd_list_extra(id, level, cid)
{
	if (!cmd_access(id, ADMIN_KICK, cid, 1))
		return PLUGIN_HANDLED
	
	new size = ArraySize(ListOfExtraItemNames)
	if (size <= 0)
	{
		console_print(id, "ERROR: NO EXTRA ITEMS FOUND!")
		return PLUGIN_HANDLED
	}

	console_print(id, "^n^n---> Bot Buy Extra Items V%s^n-->", PLUGIN_VERSION)
	
	new i, temp[EXTRA_ITEM_NAME_LENGTH]
	for (i = 0; i < size; i++)
	{
		ArrayGetString(ListOfExtraItemNames, i, temp, EXTRA_ITEM_NAME_LENGTH)
		console_print(id, "--> %s", temp)
	}

	console_print(id, "-->^n---> Made by EfeDursun125^n^n")
	return PLUGIN_HANDLED
}
