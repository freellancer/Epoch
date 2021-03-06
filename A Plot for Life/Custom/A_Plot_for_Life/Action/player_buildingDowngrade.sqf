/*
	DayZ Base Building Upgrades
	Made for DayZ Epoch please ask permission to use/edit/distrubute email vbawol@veteranbastards.com.
*/
private ["_location","_dir","_classname","_text","_object","_objectID","_objectUID","_newclassname","_refund","_obj","_upgrade","_objectCharacterID","_canBuildOnPlot","_friendlies","_nearestPole","_ownerID","_distance","_needText","_findNearestPoles","_findNearestPole","_IsNearPlot","_i","_invResult","_itemOut","_countOut","_abortInvAdd","_addedItems","_playerUID","_plotcheck"];

if(DZE_ActionInProgress) exitWith { cutText [(localize "str_epoch_player_48") , "PLAIN DOWN"]; };
DZE_ActionInProgress = true;

player removeAction s_player_downgrade_build;
s_player_downgrade_build = 1;

_distance = 30;
_needText = localize "str_epoch_player_246";

_playerUID = [false] call FNC_GetPlayerUID;

// check for near plot
_plotcheck = [player, false] call FNC_find_plots;
_distance = _plotcheck select 0;
_IsNearPlot = _plotcheck select 1;
_nearestPole = _plotcheck select 2;

_canBuildOnPlot = false;

if(_IsNearPlot == 0) then {
	_canBuildOnPlot = true;
} else {

	// check nearby plots ownership && then for friend status

	_buildcheck = [player, _nearestPole] call FNC_check_owner;
	_isowner = _buildcheck select 0;
	_isfriendly = _buildcheck select 1;
	if ((_isowner) || (_isfriendly)) then {
		_canBuildOnPlot = true;
	};
};

// exit if not allowed due to plot pole
if(!_canBuildOnPlot) exitWith {  DZE_ActionInProgress = false; cutText [format[(localize "str_epoch_player_141"),_needText,_distance] , "PLAIN DOWN"]; };

// get cursortarget from addaction
_obj = _this select 3;

// Current charID
_objectCharacterID 	= _obj getVariable ["CharacterID","0"];
_ownerID = _obj getVariable["ownerPUID","0"];

if(DZE_Lock_Door != _objectCharacterID) exitWith {  DZE_ActionInProgress = false; cutText [(localize "str_epoch_player_49") , "PLAIN DOWN"]; };

// Find objectID
_objectID 	= _obj getVariable ["ObjectID","0"];

// Find objectUID
_objectUID	= _obj getVariable ["ObjectUID","0"];

if(_objectID == "0" && _objectUID == "0") exitWith {DZE_ActionInProgress = false; s_player_upgrade_build = -1; cutText [(localize "str_epoch_player_50"), "PLAIN DOWN"];};

// Get classname
_classname = typeOf _obj;

// Find display name
_text = getText (configFile >> "CfgVehicles" >> _classname >> "displayName");

// Find next upgrade
_upgrade = getArray (configFile >> "CfgVehicles" >> _classname >> "downgradeBuilding");

if ((count _upgrade) > 0) then {

	_newclassname = _upgrade select 0;

	_refund = _upgrade select 1;
	[1,1] call dayz_HungerThirst;
	player playActionNow "Medic";
	[player,20,true,(getPosATL player)] spawn player_alertZombies;

	_invResult = false;
	_abortInvAdd = false;
	_i = 0;
	_addedItems = [];

	{
		_itemOut = _x select 0;
		_countOut = _x select 1;

		for "_x" from 1 to _countOut do {
			_invResult = [player,_itemOut] call BIS_fnc_invAdd;
			if(!_invResult) exitWith {
				_abortInvAdd = true;
			};
			if(_invResult) then {
				_i = _i + 1;
				_addedItems set [(count _addedItems),[_itemOut,1]];
			};
		};

		if (_abortInvAdd) exitWith {};

	} count _refund;

	// all parts added proceed
	if(_i != 0) then {

		// Get position
		_location	= _obj getVariable["OEMPos",(getposATL _obj)];

		// Get direction
		_dir = getDir _obj;

		// Reset the character ID on locked doors before they inherit the newclassname
		if (_classname in DZE_DoorsLocked) then {
			_obj setVariable ["CharacterID",dayz_characterID,true];
			_objectCharacterID = dayz_characterID;
		};

		_classname = _newclassname;

		// Create new object
		_object = createVehicle [_classname, [0,0,0], [], 0, "CAN_COLLIDE"];

		// Set direction
		_object setDir _dir;

		// Set location
		_object setPosATL _location;

		// Set Owner.
		_object setVariable ["ownerPUID",_ownerID,true];

		//diag_log format["Player_buildingdowngrade: [newclassname: %1] [_ownerID: %2] [_objectCharacterID: %2]",_newclassname, _ownerID, _objectCharacterID];

		cutText [format[(localize "str_epoch_player_142"),_text], "PLAIN DOWN", 5];

		_playerUID = [true] call FNC_GetPlayerUID;
		PVDZE_obj_Swap = [_objectCharacterID,_object,[_dir,_location,_playerUID],_classname,_obj,player];
		publicVariableServer "PVDZE_obj_Swap";

		player reveal _object;

	} else {
		cutText [format[(localize "str_epoch_player_143"), _i,(getText(configFile >> "CfgMagazines" >> _itemOut >> "displayName"))], "PLAIN DOWN"];
		{
			[player,(_x select 0),(_x select 1)] call BIS_fnc_invRemove;
		} count _addedItems;

	};

} else {
	cutText [(localize "str_epoch_player_51"), "PLAIN DOWN"];
};

DZE_ActionInProgress = false;
s_player_downgrade_build = -1;
