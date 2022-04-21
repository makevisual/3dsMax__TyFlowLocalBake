clearlistener()

global TFLB

struct TFLB_Struct 
(
	ui_main 	= undefined,
	interfaces 	= undefined,
	data 		= undefined,
	version 	= undefined,
	functions 	= undefined,

	function data_Struct_init =
	(
		struct data_Struct
		(
			operand_local 			= undefined, 	-- the local object to globalize
			operand_flows 			= undefined, 	-- tyflow objects to bake
			cache_frameRange 		= undefined,	-- the framerange to bake
			output_pathBase 		= undefined, 	-- the root of the export
			output_animation 		= undefined, 	-- Animation
			output_cacheBase 		= undefined, 	-- Caches
			timestamp_start 		= undefined, 	-- epoch of start of operations
			timestamp_end 			= undefined, 	-- epoch of end of operations
			eventLog 				= undefined 	-- 

		)

		TFLB.data = data_Struct() 	-- Build an instance of the data
		TFLB.functions.init_data() 	-- Populate it with default data
	),

	function functions_Struct_init =
	(
		struct functions_Struct
		(

			-- save out the animation of the designated local 
			function saveLocalAnimation =
			(
				curLocal = TFLB.data.operandLocal
				if curLocal == undefined then ( exit )
			),

			function autoFrameRange = 
			(
				TFLB.data.cache_frameRange = [ AnimationRange.start, AnimationRange.end ]
			),

			function init_data =
			(
				TFLB.functions.autoFrameRange()
			),

			function showVersion =
			(	
				print ( " You are using TFLB version: " + ( TFLB.version as string ) )
			)
		)
		
		TFLB.functions = functions_Struct()
	),
	
	function interfaces_Struct_init =
	(
		struct interfaces_Struct
		(
			function mainUi_construct =
			(
				rolloutName = ( "TFLB " + ( TFLB.version as string ) )

				rollout mainUi_rollout rolloutName width:300 height:20
				(
					groupbox grp_objects "Objects" height:195
						button btn_selectLocal "Select Local" 	width:(mainUi_rollout.width - 40 ) offset:[0, ( ( grp_objects.height * -1 ) + 20 )]
						multilistbox mbl_flows ""				width:(mainUi_rollout.width - 40 ) offset:[7,0]

					groupbox grp_output "Output" height:90 offset:[0,10] 
						label lab_frameRange "FrameRange:" align:#left offset:[10, ( ( grp_output.height * -1 ) + 15 )]
						spinner spn_frameStart 	"" 			range:[-10000,0,99999] 	align:#left width:80 type:#integer offset:[80,-20]
						spinner spn_frameend 	"  to  " 	range:[-10000,0,99999] 	align:#left width:85 type:#integer offset:[165,-21]
						editText edtt_outputPath "Path:"  offset:[ 10,0] width:(mainUi_rollout.width - 50 ) 
						button btn_outputPathSet 	"set" 	width:50 align:#right offset:[-65,0]
						button btn_outputPathOpen 	"open"	width:50 align:#right offset:[-12,-26]

					button bake "Bake" height:30 width:(mainUi_rollout.width - 25 ) offset:[-2,10]
				)

				on mainUi_rollout open do 
					(
						
					)

				)
			
				createdialog mainUi_rollout lockHeight:true lockWidth:true style:#(#style_titlebar,#style_border, #style_sysmenu,#style_resizing, #style_minimizebox)
				TFLB.ui_main = mainUi_rollout 
			)
		)

		TFLB.interfaces = interfaces_Struct()
	),
	
	function init =
	(
		-- set Version
		TFLB.version = "0.0.1"

		-- init structs
		TFLB.functions_Struct_init()
		TFLB.data_Struct_init()
		TFLB.interfaces_Struct_init()

		TFLB.functions.showVersion()

		-- build UI
		TFLB.interfaces.mainUi_construct()
	)
)

print ( timestamp() )
try( destroyDialog TFLB.ui_main )catch()
TFLB = TFLB_Struct()
TFLB.init()