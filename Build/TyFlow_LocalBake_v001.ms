global TFLB

struct TFLB_Struct 
(
	-- Top level variables
	ui_main 	= undefined,	-- the Main UI
	interfaces 	= undefined,	-- constructors for interfaces
	data 		= undefined,	-- data for operations and interfaces
	version 	= undefined,	-- version number 
	functions 	= undefined,	-- library of functions for use globally

	function data_Struct_init =
	(
		-- class for holding all relevant data for the program
		struct data_Struct
		(
			operand_local 				= undefined, 	-- the local object to globalize
			operand_localParent 		= undefined, 	-- the parent of the local object
			operand_localTransform 		= undefined, 	-- the transform of the local object
			operand_flows 				= undefined, 	-- tyflow objects to bake
			operand_caches 				= undefined, 	-- tyflow caches to bake
			user_selection 				= undefined,  	-- the object(s) selected by the user
			user_sliderTime 			= undefined, 	-- the current time of the slider
			cache_frameRange 			= undefined,	-- the framerange to bake
			output_pathBase 			= undefined, 	-- the root of the export
			output_animation 			= undefined, 	-- location of the .xaf file for the locals animation to be saved
			output_localName 			= undefined, 	-- name of the local that is to be 'parent' for the bake
			output_flows	 			= undefined, 	-- a path for each of the output flows
			output_incrementEnabled		= undefined, 	-- probably not needed anymore, but here nonetheless
			output_incrementVal			= undefined, 	-- the increment number of the export
			timestamp_start 			= undefined, 	-- epoch of start of operations
			timestamp_end 				= undefined, 	-- epoch of end of operations
			passChecks	 				= undefined, 	-- if valid export conditions met
			eventLog 					= undefined 	-- 

		)

		TFLB.data = data_Struct() 	-- Build an instance of the data
		TFLB.functions.init_data() 	-- Populate it with default data
	),

	function functions_Struct_init =
	(
		struct functions_Struct
		(

			-- prepare the local for baking
			function prepareLocal =
			(
				print " Preparing the Local "

				-- save the animation of the selected object
				LoadSaveAnimation.saveAnimation TFLB.data.output_animation TFLB.data.operand_local "" "" 	

				TFLB.data.user_selection = selection as array 									-- store the current selection to restore later
				TFLB.data.user_sliderTime = slidertime 											-- strore the current slidertime
				slidertime = TFLB.data.cache_frameRange[1] 										-- bring the timeslider to the beginning of the animation range
				select TFLB.data.operand_local  												-- Select the local
				macros.run "Animation Tools" "DeleteSelectedAnimation"  						-- delete the locals animation
				TFLB.data.operand_localParent =	TFLB.data.operand_local.parent   				-- store the locals parent if there is one
				TFLB.data.operand_local.parent = undefined 										-- unparent the local from any heirarchy
				TFLB.data.operand_localTransform = TFLB.data.operand_local.transform 			-- store the transform of the local
				TFLB.data.operand_local.transform = (matrix3 [1,0,0] [0,1,0] [0,0,1] [0,0,0]) 	-- align the transform to the origin
			),

			-- restore the local after baking 
			function restoreLocal = 
			(
				print " Restoring the Local "
				slidertime = TFLB.data.cache_frameRange[1] 										-- bring the timeslider to the beginning of the animation range
				TFLB.data.operand_local.transform  = TFLB.data.operand_localTransform 			-- restore the locals transform
				TFLB.data.operand_local.parent     = TFLB.data.operand_localParent 				-- reparent the local from its previous heirarchy
				slidertime = TFLB.data.user_sliderTime 											-- restore the slidertime
				select TFLB.data.user_selection 											-- restore selection

				-- load the animation of the selected object, absolute, replace
				LoadSaveAnimation.loadAnimation TFLB.data.output_animation TFLB.data.operand_local relative:false insert:false
			),

			-- set the framerange on open to the timeline
			function autoFrameRange = 
			(

				TFLB.data.cache_frameRange = [ AnimationRange.start, AnimationRange.end ]
			),

			-- attempt to create a valid output directory, if in the proper MAKE filestructure or not
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

			-- collect the tyflows that are valid for caching
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

			-- prepare the output filepaths
			function autoSubPaths = 
			(
				if ( doesDirectoryExist TFLB.data.output_pathBase )
				then 
				(
					-- The main folder other things will be exported from
					TFLB.data.output_localName = ( TFLB.data.output_pathBase + TFLB.data.operand_local.name + @"\v" + ( substring ( ( TFLB.data.output_incrementVal  + 1000 ) as string ) 2 4 ) )

					-- Animation output
					TFLB.data.output_animation = ( TFLB.data.output_localName + @"\" + TFLB.data.operand_local.name + "_animation.xaf" )

					-- Make an output for each of the child flows
					TFLB.data.output_flows = #()
					for curFlow in TFLB.data.operand_flows do 
					(
						--append TFLB.data.output_flows ( TFLB.data.output_localName + @"\" + curFlow.name + @"\" + "****.vrmesh" )
						append TFLB.data.output_flows ( TFLB.data.output_localName + @"\" + curFlow.name + @"\" )
					)
				)
			),

			-- make the folders for outputs
			function createSubPaths = 
			(
				makedir TFLB.data.output_localName
				makedir (getFilenamePath TFLB.data.output_animation )
				for flow in TFLB.data.output_flows do ( makedir ( getFilenamePath flow ) )
			),

			-- populate with startup data on initialization 
			function init_data =
			(
				TFLB.functions.autoFrameRange()
				TFLB.functions.autoPath()
			),

			function bake =
			(
				print "++++ starting bake ++++"

				-- get the export particles node in
				for curFlow in TFLB.data.operand_flows do 
				(
					-- store the transform of the flow, then align it to the local
					curFlowHoldTransform = curFlow.transform
					curFlow.transform = TFLB.data.operand_local.transform

					-- try to get the export particles node within the tyflow
					curExportParticles 	= curflow.export.export_particles
				
					-- set the properties to export
					curExportParticles.exportFrameStart = TFLB.data.cache_frameRange[1]
					curExportParticles.exportFrameEnd 	= TFLB.data.cache_frameRange[2]
					curExportParticles.exportType 		= 5
					
					curExportPath = ( TFLB.data.output_localName + @"\" + curFlow.name + @"\" + curFlow.name + ".vrmesh" )
					curExportParticles.vrmeshFilename 	= curExportPath

					-- do the export
					curflow.export.export_particles.exportVRay()

					-- Make a new proxy, and load the cache, set parent and material
					newProxy 				= VRayProxy()
					newProxy.filename 		= curExportPath
					newProxy.parent 		= TFLB.data.operand_local
					newProxy.material 		= curflow.material
					newProxy.display 		= 4
					newProxy.anim_type 		= 1
					newProxy.anim_offset 	= ( TFLB.data.cache_frameRange[1] * -1 )


					newProxy.name 		= ( curFlow.name + "_VrayProxy" )

					curFlow.transform = curFlowHoldTransform
				)
			),

			-- runs various checks, and if passed, call individual baking functions
			function bakeCheck =
			(
				TFLB.data.timestamp_start = timeStamp()
				passChecks = #true 

				clearlistener()
				print "------------"
				print "begin bake operation"
				print "------------"

				try( TFLB.functions.autoSubPaths()																) catch( passChecks = #false )
				try( print ("     -- local: " 				+ ( TFLB.data.operand_local ) as string ) 			) catch( passChecks = #false )
				try( print ("     -- flows: " 				+ ( TFLB.data.operand_flows ) as string ) 			) catch( passChecks = #false )
				try( print ("     -- framerange: " 			+ ( TFLB.data.cache_frameRange ) as string ) 		) catch( passChecks = #false )
				try( print ("     -- output base: " 		+ ( TFLB.data.output_pathBase ) as string ) 		) catch( passChecks = #false )
				try( print ("     -- output localName: " 	+ ( TFLB.data.output_localName ) as string ) 		) catch( passChecks = #false )
				try( print ("     -- output Increment: " 	+ ( TFLB.data.output_incrementVal ) as string ) 	) catch( passChecks = #false )	
				try( print ("     -- output animation: " 	+ ( TFLB.data.output_animation ) as string ) 		) catch( passChecks = #false )
				try( print ("     -- output flows: " 		+ ( TFLB.data.output_flows ) as string )	 		) catch( passChecks = #false )
				try( print ("     -- timestamp start: " 	+ ( TFLB.data.timestamp_start ) as string )			) catch( passChecks = #false ) 	

				-- If none of the checks failed pass to actual bake actions
				if passChecks == #true
				then
				(
					print "------------"
					print "PASSED BAKE CHECKS"
					print "------------"

					TFLB.functions.createSubPaths()
					TFLB.functions.prepareLocal()

					try ( TFLB.functions.bake() ) catch( print "big problem")

					TFLB.functions.restoreLocal()
				)
				else 
				(
					print "------------"
					print "UNABLE TO BAKE"
					print "------------"
				)

			),

			-- tester for displaying the current version of the program
			function showVersion =
			(	

				print ( " You are using TFLB version: " + ( TFLB.version as string ) )
			)
		)
		
		TFLB.functions = functions_Struct()
	),
	
	-- struct for holding all the interfaces, and the ability to construct or destroy them from this library
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
					TFLB.functions.bakeCheck()
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
	
	-- bootstrap the program
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

clearlistener()
print ( timestamp() )
try( destroyDialog TFLB.ui_main )catch() 	-- attempt to remove any previously existing interfaces before creating a new one
TFLB = TFLB_Struct()						-- instantiate the TyFlowLocalBake
TFLB.init()									-- initialize the instance of TyFlowLocalBake