MODULE_NAME='Analog Way VIO 4K' (DEV dvAnalogWay, DEV vdvAnalogWay, CHAR IPAddress[], INTEGER Preset, CHAR View[], INTEGER Layer, INTEGER QuickView)
(***********************************************************)
(*          DEVICE NUMBER DEFINITIONS GO BELOW             *)
(***********************************************************)
DEFINE_DEVICE

AMXMaster = 0:0:0

(***********************************************************)
(*               CONSTANT DEFINITIONS GO BELOW             *)
(***********************************************************)
DEFINE_CONSTANT

ControlPort = 10600

//Feedback variables
long FEEDBACK_TIMES[1]	= {250}
integer FEEDBACK_TIMELINE = 1


(***********************************************************)
(*              DATA TYPE DEFINITIONS GO BELOW             *)
(***********************************************************)
DEFINE_TYPE

(***********************************************************)
(*               VARIABLE DEFINITIONS GO BELOW             *)
(***********************************************************)
DEFINE_VARIABLE

CHAR LineFeed[] = {$0A}
CHAR CrLf[] = {$0D,$0A}

CHAR ConnectionFeed[] = 'TPCon'
INTEGER ClientConnected

//General note the end of the format is Line Feed, indicated with (LF)
//the parameters are between <>, they start from 0 means taht screen is fro 0 to 63
//Format: <bank>,1PKrcr(LF)
CHAR LoadPreset[] = ',1PKrcr'
CHAR QueryPreset[] = 'PKrcr'
CHAR LoadPresetCommand[] = 'PRESET-'

//Format: <bank>,<screen>,1PBirr(LF)
CHAR LoadView[] = ',1PBirr'
CHAR QueryView[] = 'PBirr'
CHAR LoadViewCommand[] = 'VIEW-'

//Format: <source>PRinp,LF
//This format is an exception from the previous one because the command doesn't need multiple parameter and/or special character
CHAR ChangeLayerSource[] = 'PRinp'
CHAR ChangeLayerSourceCommand[] = 'LAYERSOURCE-'


//Format: <On/Off>QFfor(LF)
//Note ON is 1 Off is 0
CHAR QuickFrameControl[] = 'QFfor'
CHAR QuickFrameCommand[] = 'QUICKFRAME-'  
INTEGER QueryCommandNumber = 0

(***********************************************************)
(*       MUTUALLY EXCLUSIVE DEFINITIONS GO BELOW           *)
(***********************************************************)
DEFINE_MUTUALLY_EXCLUSIVE


(***********************************************************)
(*        SUBROUTINE/FUNCTION DEFINITIONS GO BELOW         *)
(***********************************************************)
(* EXAMPLE: DEFINE_FUNCTION <RETURN_TYPE> <NAME> (<PARAMETERS>) *)
(* EXAMPLE: DEFINE_CALL '<NAME>' (<PARAMETERS>) *)

(***********************************************************)
(*                STARTUP CODE GOES BELOW                  *)
(***********************************************************)
DEFINE_START

IP_CLIENT_OPEN(dvAnalogWay.PORT,IPAddress,ControlPort,IP_TCP)

timeline_create(FEEDBACK_TIMELINE, FEEDBACK_TIMES, 1, TIMELINE_RELATIVE, TIMELINE_REPEAT)


(***********************************************************)
(*                THE EVENTS GO BELOW                      *)
(***********************************************************)
DEFINE_EVENT

DATA_EVENT[dvAnalogWay]
{
    ONLINE:
    {
        SEND_COMMAND AMXMaster,"'Analog Way Online'"
    }
    OFFLINE: 
    {
        SEND_COMMAND AMXMaster,"'Reconnecting...'"
        IP_CLIENT_OPEN(dvAnalogWay.PORT,IPAddress,ControlPort,IP_TCP)
    }
    STRING:
    {
        LOCAL_VAR char Buffer[250]
        WHILE (FIND_STRING (data.text, CrLf, 1))
        {
            Buffer = REMOVE_STRING(data.text,CrLf,1)
        }

        if(FIND_STRING(Buffer,ConnectionFeed,1))
        {
            REMOVE_STRING(Buffer, ConnectionFeed, 1)
            ClientConnected = ATOI(Buffer)
        }

        if(FIND_STRING(Buffer,QueryView,1))
        {
            REMOVE_STRING(Buffer,QueryView,1)
            View = Buffer
        }

        if(FIND_STRING(Buffer,ChangeLayerSource,1))
        {
            REMOVE_STRING(Buffer,ChangeLayerSource,1)
            Layer = atoi(Buffer)
        }
	
	if(FIND_STRING(Buffer,QuickFrameControl,1))
        {
            REMOVE_STRING(Buffer,QuickFrameControl,1)
            QuickView = atoi(Buffer)
        }
    }
}

DATA_EVENT[vdvAnalogWay]
{
    ONLINE:
    {
        IP_CLIENT_OPEN(dvAnalogWay.PORT,IPAddress,ControlPort,IP_TCP)
    }
    COMMAND: 
    {
        LOCAL_VAR CHAR CommandBuffer[250]
        CommandBuffer = DATA.TEXT
        //Load preset command format:
        //PRESET-1
        //Example above load preset 1
        IF(FIND_STRING(CommandBuffer,LoadPresetCommand,1))
        {
            REMOVE_STRING(CommandBuffer,LoadPresetCommand,1)
            SEND_STRING dvAnalogWay,"CommandBuffer,LoadPreset,LineFeed"
        }
        //Load preset command format:
        //VIEW-1,1,1
        //Example above load view from bank 1, screen 1
        IF(FIND_STRING(CommandBuffer,LoadViewCommand,1))
        {
            REMOVE_STRING(CommandBuffer,LoadViewCommand,1)
            SEND_STRING dvAnalogWay,"CommandBuffer,LoadView,LineFeed"
        }
        //Load preset command format:
        //LAYERSOURCE-1
        //Example above change the layer source to 1
        IF(FIND_STRING(CommandBuffer,ChangeLayerSourceCommand,1))
        {
            REMOVE_STRING(CommandBuffer,ChangeLayerSourceCommand,1)
            SEND_STRING dvAnalogWay,"CommandBuffer,ChangeLayerSource,LineFeed"
        }
	
	//Show the QuickFrame to the output:
        //QUICKFRAME-1
        //Example above show the quickframe
        IF(FIND_STRING(CommandBuffer,QuickFrameCommand,1))
        {
            REMOVE_STRING(CommandBuffer,QuickFrameCommand,1)
            SEND_STRING dvAnalogWay,"CommandBuffer,QuickFrameControl,LineFeed"
        }

    }
    
}

TIMELINE_EVENT[FEEDBACK_TIMELINE]
{
    SWITCH (QueryCommandNumber)
    {
        CASE 1:
        {
            SEND_STRING dvAnalogWay,"QueryPreset,LineFeed"
        }
        case 2:
        {
            SEND_STRING dvAnalogWay,"QueryView,LineFeed"
        }
        case 3:
        {
            SEND_STRING dvAnalogWay,"ChangeLayerSource,LineFeed"
        }
	case 4:
	{
	    SEND_STRING dvAnalogWay,"QuickFrameControl,LineFeed"
	    QueryCommandNumber = 0
	}
    }
    QueryCommandNumber++
}

(*****************************************************************)
(*                                                               *)
(*                      !!!! WARNING !!!!                        *)
(*                                                               *)
(* Due to differences in the underlying architecture of the      *)
(* X-Series masters, changing variables in the DEFINE_PROGRAM    *)
(* section of code can negatively impact program performance.    *)
(*                                                               *)
(* See Ã¯Â¿Â½Differences in DEFINE_PROGRAM Program ExecutionÃ¯Â¿Â½ section *)
(* of the NX-Series Controllers WebConsole & Programming Guide   *)
(* for additional and alternate coding methodologies.            *)
(*****************************************************************)

DEFINE_PROGRAM

(*****************************************************************)
(*                       END OF PROGRAM                          *)
(*                                                               *)
(*         !!!  DO NOT PUT ANY CODE BELOW THIS COMMENT  !!!      *)
(*                                                               *)
(*****************************************************************)