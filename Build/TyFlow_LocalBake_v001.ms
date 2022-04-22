clearlistener()

global TFLB

struct TFLB_Struct 
(
	ui_main 	= undefined,	-- the Main UI
	interfaces 	= undefined,	-- constructors for interfaces
	data 		= undefined,	-- data for operations and interfaces
	version 	= undefined,	-- version number 
	functions 	= undefined,	-- library of functions for use globally

	function data_Struct_init =
	(
		struct data_Struct
		(
			operand_local 				= undefined, 	-- the local object to globalize
			operand_flows 				= undefined, 	-- tyflow objects to bake
			operand_caches 				= undefined, 	-- tyflow caches to bake
			cache_frameRange 			= undefined,	-- the framerange to bake
			output_pathBase 			= undefined, 	-- the root of the export
			output_animation 			= undefined, 	-- Animation
			output_localName 			= undefined, 	-- LocalName
			output_incrementEnabled		= undefined, 	-- 
			output_incrementVal			= undefined, 	-- 
			timestamp_start 			= undefined, 	-- epoch of start of operations
			timestamp_end 				= undefined, 	-- epoch of end of operations
			eventLog 					= undefined 	-- 

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

			function autoPath = 
			(
				curPath = maxFilePath 
				splitPath = FilterString curPath @"\"
				blindCacheDir = ""

				for i in 1 to (splitPath.count - 2 ) do
				(
					blindCacheDir += splitPath[i] + @"\"
				)
				
				blindCacheDir += @"Caches\"
											
				if ( doesDirectoryExist blindCacheDir )
				then ( TFLB.data.output_pathBase = blindCacheDir )
				else ( TFLB.data.output_pathBase = maxFilePath )
			),

			function autoTyflows =
			(
				validTyflows = #()
				allTyflows = getClassInstances tyflow asTrackViewPick:true

				for curTyFlow in allTyflows do 
				(

				-- Client is picked because the tyflow is a system with multiple nodes and tracks
				if curTyFlow.client.parent == TFLB.data.operand_local
				then ( append validTyflows curTyFlow.client )
				)

				TFLB.data.operand_flows = validTyflows
			),

			function autoSubPaths = 
			(
				if ( doesDirectoryExist TFLB.data.output_pathBase )
				then 
				(
					TFLB.data.output_incrementVal

					TFLB.data.output_localName = ( TFLB.data.output_pathBase + TFLB.data.operand_local.name + ( TFLB.data.output_incrementVal as string ) )
					TFLB.data.output_animation = ( TFLB.data.output_localName + @"\" + TFLB.data.operand_local.name + "animation.xml" )

					-- TODO: Parse and Make the various flow outputs as well
				)


			),

			function init_data =
			(
				TFLB.functions.autoFrameRange()
				TFLB.functions.autoPath()
			),

			function bake =
			(
				TFLB.data.timestamp_start = timeStamp()
				TFLB.functions.autoSubPaths()

				clearlistener()
				print "------------"
				print "begin bake operation"
				print "------------"
				print ("     -- local: " 				+ ( TFLB.data.operand_local ) as string )
				print ("     -- flows: " 				+ ( TFLB.data.operand_flows ) as string )
				print ("     -- framerange: " 			+ ( TFLB.data.cache_frameRange ) as string )
				print ("     -- output base: " 			+ ( TFLB.data.output_pathBase ) as string )
				print ("     -- output localName: " 	+ ( TFLB.data.output_localName ) as string )
				print ("     -- output Increment: " 	+ ( TFLB.data.output_incrementVal ) as string )
				print ("     -- output animation: " 	+ ( TFLB.data.output_animation ) as string )
				print ("     -- timestamp start: " 		+ ( TFLB.data.timestamp_start ) as string )


				-- TODO: make the directories and cache!
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

				rollout mainUi_rollout rolloutName width:600 height:370
				(
					groupbox grp_objects "Objects" height:195
						button btn_selectLocal "Pick selected as Local" 	width:(mainUi_rollout.width - 40 ) offset:[0, ( ( grp_objects.height * -1 ) + 20 )]
						multilistbox mbl_flows ""				width:(mainUi_rollout.width - 40 ) offset:[7,0]

					groupbox grp_output "Output" height:110 offset:[0,10] 
						label lab_frameRange "FrameRange:" align:#left offset:[10, ( ( grp_output.height * -1 ) + 15 )]
						spinner spn_frameStart 	"" 			range:[-10000,99999,0] 	align:#left width:50 type:#integer offset:[100,-20]
						spinner spn_frameend 	"  to  " 	range:[-10000,99999,0] 	align:#left width:50 type:#integer offset:[155,-21]
						label lab_versionNumber "Version number:" align:#left offset:[10,0]
						spinner spn_versionNumber "" range:[0,999,1] align:#left width:50 type:#integer offset:[100,-20]
						editText edtt_outputPath "Path:"  	offset:[ 10,0] width:(mainUi_rollout.width - 50 ) 
						button btn_outputPathSet 	"set" 	width:50 align:#right offset:[-65,0]
						button btn_outputPathOpen 	"open"	width:50 align:#right offset:[-12,-26]

					button btn_bake "Bake" height:30 width:(mainUi_rollout.width - 25 ) offset:[-2,10]

				on btn_outputPathOpen pressed do 
				(
					try( shelllaunch TFLB.data.output_pathBase "explorer.exe" )
					catch( messagebox ( TFLB.data.output_pathBase + "\n Does not yet exist") )
				)

				on btn_selectLocal pressed do 
				(
					if selection.count == 1 
					then
					(
						TFLB.data.operand_local = selection[1]
						btn_selectLocal.text = ( "\" " + TFLB.data.operand_local.name + " \"  Selected" )

						TFLB.functions.autoTyflows()
						tyflowNames = #()
						curFlows 	= TFLB.data.operand_flows

						for curFlow in curFlows do 
						(
							append tyflowNames curflow.name
						)

						mbl_flows.items = tyflowNames
					)
					else 
					(
						TFLB.data.operand_local = undefined
						TFLB.data.operand_flows = #()
						btn_selectLocal.text 	= "Pick selected as Local"
						mbl_flows.items 		= #()
					)
				)

				on btn_outputPathSet pressed do 
				(
					outputPath = getSaveFileName caption:"Open A Test File:" \
					filename:( TFLB.data.output_pathBase + @"\here")

					if outputPath != undefined
					then 
					(
						outputPathParts = ( FilterString outputPath @"\" )
						outputPath = ""
						for i in 1 to ( outputPathParts.count - 1 ) do
						outputPath += ( outputPathParts[i] + @"\" )

						if doesDirectoryExist outputPath
						then
						(
							TFLB.data.output_pathBase = outputPath
							edtt_outputPath.text = TFLB.data.output_pathBase
						)
					)
				)

				on spn_versionNumber changed state do
				(
					TFLB.data.output_incrementVal = state
				)

				on btn_bake pressed do 
				(
					TFLB.functions.bake()
				)

 				on mainUi_rollout open do 
 					(
						spn_frameStart.value 	= TFLB.data.cache_frameRange[1]
						spn_frameEnd.value 		= TFLB.data.cache_frameRange[2]

						-- TODO: Handle this a different way?
						TFLB.data.output_incrementVal = 1
						spn_versionNumber.value = TFLB.data.output_incrementVal

						edtt_outputPath.text 	= TFLB.data.output_pathBase
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