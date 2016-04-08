// https://github.com/ilioNaglo/SecretWord

// Version 1.5 - 2016-04-03
// fix: particles on win to WinnerId
// add: what the Secret Word was in floatie text
// change: win floatie text color from red to yellow

// Version 1.4
// fix: store paid into game to description field and resetting it after a win
// added sound and particles on win
// cleaned up code

// Version 1.3
// added pay into pot while not active.  uses Object Description Field to store PrizeAmount
// added default texture & game over texture
// separated permissions grant from Active Game

// Version 1.2
//  added listen to object to accomdate people that talk via script

//*** Modify these values as needed ***
string SecretWord = "usb";

integer DefaultPrizeAmount = 50;  // Default Prize Amount

string DefaultTexture = "groucho_duck";
string GameOverTexture = "groucho_marx-secret_word-duck";


//*** DO NOT MODIFY BELOW THIS LINE ***
integer StoredPrizeAmount = 0;  // Stored in Object Description Field
integer PrizeAmount = 0;  // will be (re)set to DefaultPrizeAmount when activated
integer Active = FALSE;
integer GameOver = FALSE;
integer ListenCallback = 0;
key TransactionResult = NULL_KEY;
string OwnerName = "";
key WinnerId = NULL_KEY;
string WinnerName = "";
string SoundName = "";


// Mask Flags - set to TRUE to enable
integer glow = TRUE;            // Make the particles glow
integer bounce = FALSE;          // Make particles bounce on Z plan of object
integer interpColor = FALSE;     // Go from start to end color
integer interpSize = TRUE;      // Go from start to end size
integer wind = FALSE;           // Particles effected by wind
integer followSource = TRUE;    // Particles follow the source
integer followVel = FALSE;       // Particles turn to velocity direction

// Choose a pattern from the following:
// PSYS_SRC_PATTERN_EXPLODE
// PSYS_SRC_PATTERN_DROP
// PSYS_SRC_PATTERN_ANGLE_CONE_EMPTY
// PSYS_SRC_PATTERN_ANGLE_CONE
// PSYS_SRC_PATTERN_ANGLE
integer pattern = PSYS_SRC_PATTERN_ANGLE_CONE_EMPTY;

// Select a target for particles to go towards
// "" for no target, "owner" will follow object owner 
//    and "self" will target this object
//    or put the key of an object for particles to go to
key target = WinnerId;

// Particle paramaters
float age = 5.0;                  // Life of each particle
float maxSpeed = 1.0;            // Max speed each particle is spit out at
float minSpeed = 1.0;            // Min speed each particle is spit out at
string texture = "061ce43b-1471-4520-2e39-a07e68b62b1b";                 // Texture used for particles, default used if blank
float startAlpha = 1.0;           // Start alpha (transparency) value
float endAlpha = 1.0;           // End alpha (transparency) value
vector startColor = <1.0,1.0,1.0>;    // Start color of particles <R,G,B>
vector endColor = <1.0,1.0,1.0>;      // End color of particles <R,G,B> (if interpColor == TRUE)
vector startSize = <0.01,0.01,0.01>;     // Start size of particles 
vector endSize = <1.0,1.0,1.0>;       // End size of particles (if interpSize == TRUE)
vector push = <0,0,0>;          // Force pushed on particles

// System paramaters
float rate = 1.0;            // How fast (rate) to emit particles
float radius = 20.0;          // Radius to emit particles for BURST pattern
integer count = 1;        // How many particles to emit per BURST 
float outerAngle = PI_BY_TWO;    // Outer angle for all ANGLE patterns
float innerAngle = PI_BY_TWO;    // Inner angle for all ANGLE patterns
vector omega = <0, 0, 0>;    // Rotation of ANGLE patterns around the source
float life = 15.0;             // Life in seconds for the system to make particles

// Script variables
integer flags;

updateParticles()
{
    flags = 0;
    if (target == NULL_KEY || target == "") target = llGetKey();
    if (target == "owner") target = llGetOwner();
    if (target == "self") target = llGetKey();
    if (glow) flags = flags | PSYS_PART_EMISSIVE_MASK;
    if (bounce) flags = flags | PSYS_PART_BOUNCE_MASK;
    if (interpColor) flags = flags | PSYS_PART_INTERP_COLOR_MASK;
    if (interpSize) flags = flags | PSYS_PART_INTERP_SCALE_MASK;
    if (wind) flags = flags | PSYS_PART_WIND_MASK;
    if (followSource) flags = flags | PSYS_PART_FOLLOW_SRC_MASK;
    if (followVel) flags = flags | PSYS_PART_FOLLOW_VELOCITY_MASK;
    if (target != "") flags = flags | PSYS_PART_TARGET_POS_MASK;

    llParticleSystem([  PSYS_PART_MAX_AGE,age,
                        PSYS_PART_FLAGS,flags,
                        PSYS_PART_START_COLOR, startColor,
                        PSYS_PART_END_COLOR, endColor,
                        PSYS_PART_START_SCALE,startSize,
                        PSYS_PART_END_SCALE,endSize, 
                        PSYS_SRC_PATTERN, pattern,
                        PSYS_SRC_BURST_RATE,rate,
                        PSYS_SRC_ACCEL, push,
                        PSYS_SRC_BURST_PART_COUNT,count,
                        PSYS_SRC_BURST_RADIUS,radius,
                        PSYS_SRC_BURST_SPEED_MIN,minSpeed,
                        PSYS_SRC_BURST_SPEED_MAX,maxSpeed,
                        PSYS_SRC_TARGET_KEY,target,
                        PSYS_SRC_INNERANGLE,innerAngle, 
                        PSYS_SRC_OUTERANGLE,outerAngle,
                        PSYS_SRC_OMEGA, omega,
                        PSYS_SRC_MAX_AGE, life,
                        PSYS_SRC_TEXTURE, texture,
                        PSYS_PART_START_ALPHA, startAlpha,
                        PSYS_PART_END_ALPHA, endAlpha
                     ]);
}


default
{
    on_rez ( integer sp )
    {
        llResetScript();
    }
    
    state_entry()
    {
        llSetColor ( <0.0, 0.0, 0.0>, ALL_SIDES );
        OwnerName = llKey2Name ( llGetOwner() );
        SecretWord = llToLower ( SecretWord );

        if ( !(llGetPermissions() & PERMISSION_DEBIT) ) {
            llRequestPermissions ( llGetOwner(), PERMISSION_DEBIT );
            SecretWord = llToLower ( SecretWord );
            llSetText ( "WAITING FOR OWNER PERMISSION", <1.0, 0.0, 0.0>, 1.0 );
            llOwnerSay ( "You must Accept DEBIT Permission" );
        } else {
           	state waiting;
        }
    }

    touch_start(integer total_number)
    {
        if ( llDetectedKey(0) == llGetOwner() ) {
			llResetScript();
        }
    }

    run_time_permissions ( integer flags )
    {
        if ( !(flags & PERMISSION_DEBIT) ) {  // DEBIT perms not accepted
            llOwnerSay ( "Permission for DEBIT MUST BE GIVEN" );
            llResetScript();
        } else {
            llOwnerSay ( "DEBIT Permission Granted" );
            state waiting;
        }
    }
}


state waiting
{
    on_rez ( integer sp )
    {
        llResetScript();
    }
    
    state_entry()
    {
        llSetColor ( <0.0, 0.0, 0.0>, ALL_SIDES );
        llSetText ( "Todays Secret Word not activated", <1.0, 1.0, 0.0>, 1.0 );

		if ( llGetInventoryNumber ( INVENTORY_SOUND ) ) {
			SoundName = llGetInventoryName ( INVENTORY_SOUND, 0 );
		}

        llOwnerSay ( "Todays Secret Word not activated\nTouch to activate" );
    }

    touch_start(integer total_number)
    {
        if ( llDetectedKey(0) == llGetOwner() ) {
			state active;
        }
    }
}


state active
{
    on_rez ( integer sp )
    {
        llResetScript();
    }
    
    state_entry()
    {
        llSetColor ( <0.0, 0.0, 0.0>, ALL_SIDES );
		StoredPrizeAmount = (integer)llGetObjectDesc();
		if ( StoredPrizeAmount > 0 ) {
			PrizeAmount = StoredPrizeAmount;
		} else {
			PrizeAmount = DefaultPrizeAmount;
			llSetObjectDesc ( (string)PrizeAmount );
		}
		llSetTexture ( DefaultTexture, ALL_SIDES );
		llSetColor ( <1.0, 1.0, 1.0>, ALL_SIDES );

       	llOwnerSay ( "Todays Secret Word is: "+ SecretWord +"\nPrize Amount is $L"+ (string)PrizeAmount );
        llSetText ( "Todays Secret Word Prize is $L"+ (string)PrizeAmount, <1.0, 1.0, 1.0>, 1.0 );
				
		GameOver = FALSE;
        Active = TRUE;
        ListenCallback = llListen ( PUBLIC_CHANNEL, "", NULL_KEY, "" );
    }

    touch_start(integer total_number)
    {
        if ( llDetectedKey(0) == llGetOwner() ) {
	        llListenRemove ( ListenCallback );
			state waiting;
        } else {
            llSay ( 0, "Anyone may Pay into Secret Word to add to the Secret Word Pot." );
        }
    }
    
    listen ( integer channel, string name, key id, string text )
    {
        if ( id == llGetOwner() ) return;  // don't respond to owner
        list words = llParseString2List ( llToLower(text), [" ", ",", ".", "!", "@", "$", "%", "*"], [] );
        if ( llListFindList (words, [SecretWord]) != -1 ) {
            if ( llGetAgentSize(id) == ZERO_VECTOR ) { // heard from an object
                key objectOwnerKey = llGetOwnerKey(id);
                if ( objectOwnerKey != id ) { // object owner is in sim
                    id = objectOwnerKey;
                    name = llKey2Name(id);
                } else { // object owner is NOT in sim 
                    return;
                }
            }
            
            // we have a winner!
            llListenRemove ( ListenCallback );
			GameOver = TRUE;
			WinnerId = id;
			WinnerName = name;
			state winner;
        }
    }
    
    money ( key id, integer amount )
    {
       	string doner_name = llKey2Name(id);
        PrizeAmount += amount;
		llSetObjectDesc ( (string)PrizeAmount );
        llSay ( PUBLIC_CHANNEL, doner_name +" added $L"+ (string)amount +" to Todays Secret Word Prize!\nTodays Secret Word Prize is now $L"+ (string)PrizeAmount +"\nThank You, "+ doner_name +"!" );
        llSetText ( "Todays Secret Word Prize is $L"+ (string)PrizeAmount, <1.0, 1.0, 1.0>, 1.0 );
        llInstantMessage ( id, "Thank You for your $L"+ (string)amount +" donation!\nTodays Secret Word Prize is now $L"+ (string)PrizeAmount );
        llInstantMessage ( llGetOwner(), doner_name +" added $L"+ (string)amount +" to Todays Secret Word Prize!\nTodays Secret Word Prize is now $L"+ (string)PrizeAmount );
    }
}

state winner
{
	on_rez ( integer sp )
	{
		llResetScript();
	}

	state_entry()
	{
		if ( SoundName != "" ) {
			llPlaySound ( SoundName, 1.0 );
		}
		llSetTexture ( GameOverTexture, ALL_SIDES );
        updateParticles();
		
	    string displayName = llGetDisplayName(WinnerId);
	    if ( displayName != "" ) {
	    	WinnerName = displayName +" ("+ WinnerName +")";
	    }
	    
	    llSay ( PUBLIC_CHANNEL, WinnerName +" said Todays Secret Word: \""+ SecretWord +"\" and won Todays Secret Word Prize of $L"+ (string)PrizeAmount +"!" );
	    llSetText ( WinnerName +"\n is Todays Secret Word Winner!\nthe Secret word was: \""+ SecretWord +"\"\nPrize was $L"+ (string)PrizeAmount, <1.0, 1.0, 0.0>, 1.0 );
	    llInstantMessage ( WinnerId, "Congratulations!  You are Todays Secret Word Prize Winner!\nYou have won Todays Secret Word Prize of $L"+ (string)PrizeAmount );
	    llInstantMessage ( llGetOwner(), WinnerName +" is Todays Secret Word Winner and won $L"+ (string)PrizeAmount );
	    //llGiveMoney ( id, PrizeAmount );
	    TransactionResult = llTransferLindenDollars ( WinnerId, PrizeAmount );
	}

    transaction_result (key requestid, integer success, string msg )
    {
        if ( requestid == TransactionResult ) {
            list info = llParseStringKeepNulls ( msg, [","], [] );
            key winnerkey = llList2Key ( info, 0 );
            integer paid_amount = llList2Integer ( info, 1 );
            if ( success ) {
                llInstantMessage ( llGetOwner(), "Todays Secret Word Prize of $L"+ (string)PrizeAmount +" succesfully delivered with Transaction Key "+ (string)TransactionResult );
                //llInstantMessage ( winnerkey, "Todays Secret Word Prize of $L"+ (string)PrizeAmount +" succesfully delivered $L"+ (string)paid_amount +" to you");
            } else {
                llInstantMessage ( llGetOwner(), "Todays Secret Word Prize of $L"+ (string)PrizeAmount +" FAILED delivery with Transaction Key "+ (string)TransactionResult +"\n"+ msg);
                llInstantMessage ( winnerkey, "Sorry, Todays Secret Word Prize of $L"+ (string)PrizeAmount +" FAILED delivery with Transaction Key "+ (string)TransactionResult +"\nPlease contact "+ OwnerName +" to resolve this issue" );
            }
			state gameover;
        }
    }
}

state gameover
{
    on_rez ( integer sp )
    {
        llResetScript();
    }

	state_entry()
	{
		llSetObjectDesc ( (string)DefaultPrizeAmount );
        llInstantMessage ( llGetOwner(), "Todays Secret Word Game is over.\nThe Prize for the next game is reset to $L"+ (string)DefaultPrizeAmount );
		PrizeAmount = DefaultPrizeAmount;
 	}

    money ( key id, integer amount )
    {
        PrizeAmount += amount;
       	string doner_name = llKey2Name(id);

		llSetObjectDesc ( (string)PrizeAmount );
        llSay ( PUBLIC_CHANNEL, doner_name +" added $L"+ (string)amount +" for the next Secret Word Prize!\nThe next Secret Word Prize is now $L"+ (string)PrizeAmount +"\nThank You, "+ doner_name +"!" );
        llInstantMessage ( id, "Thank You for your $L"+ (string)amount +" donation!\nThe next Secret Word Prize is now $L"+ (string)PrizeAmount );
		llInstantMessage ( llGetOwner(), doner_name +" added $L"+ (string)amount +" for the next Secret Word Prize!\nThe next Secret Word Prize is now $L"+ (string)PrizeAmount );
    }
}

